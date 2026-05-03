import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dier_spawn.dart';
import '../models/hunt_quest.dart';
import '../models/speler_profiel.dart';
import '../services/audio_service.dart';
import '../services/area_service.dart';
import '../services/hunt_spawn_service.dart';

class AchievementState {
  final String titel;
  final String beschrijving;
  final bool behaald;

  const AchievementState({
    required this.titel,
    required this.beschrijving,
    required this.behaald,
  });
}

enum QuestSolveResult { success, alreadySolved, failedLocked, notFound, outOfOrder }

class HuntGameState extends ChangeNotifier {
  static const String _prefsKey = 'kz_hunt_snapshot_v1';
  static const String finalWord = 'NACHTJAGER';
  static const int questStopCount = finalWord.length + 1;
  static const int faunaTotalCount = 22;
  static const int floraTotalCount = 12;
  static const int _huntDurationSeconds = 75 * 60;
  static const double _autoCatchRadiusMeters = 20.0;
  static const double _questRadiusMeters = 20.0;
  static const int _proximityDwellSeconds = 10;
  static const double _minSpawnDistanceToQuestMeters = 25.0;

  final HuntSpawnService _spawnService = HuntSpawnService();
  final AreaService _areaService = AreaService();
  final math.Random _random = math.Random();

  bool _isHydrated = false;
  SpelerProfiel? _profiel;
  List<DierSpawn> _spawns = [];
  List<HuntQuest> _quests = [];
  final Set<String> _unlockedLetters = <String>{};
  final Set<String> _collectedFloraIds = <String>{};
  bool _hasNewFaunaUnlock = false;
  bool _hasNewFloraUnlock = false;
  bool _hasNewFinalWordUnlock = false;
  int _points = 0;
  bool _finalWordSolved = false;
  bool _timeoutFinalWordShown = false;
  bool _allStopsCompletedShown = false;
  DateTime? _huntStartedAtUtc;
  DateTime? _pausedAtUtc;
  int _pausedSeconds = 0;
  bool _timerPausedOutsideArea = false;
  int _remainingSeconds = _huntDurationSeconds;
  Timer? _countdownTicker;
  Timer? _gpsRefreshTicker;

  List<({double x, double y})> _searchPolygon = [];
  ({double x, double y})? _kzLocatie;
  double _mapCenterLat = 52.060;
  double _mapCenterLon = 5.310;

  Position? _currentPosition;
  StreamSubscription<Position>? _positionSub;
  String? _locationStatus;
  final Map<String, DateTime> _spawnProximitySinceUtc = <String, DateTime>{};
  final Map<String, DateTime> _questProximitySinceUtc = <String, DateTime>{};
  String? _pendingQuestTriggerId;
  final List<String> _pendingFaunaUnlockIds = <String>[];

  bool get isHydrated => _isHydrated;
  bool get hasProfiel => _profiel != null;
  SpelerProfiel? get profiel => _profiel;
  List<DierSpawn> get spawns => List.unmodifiable(_spawns);
  List<HuntQuest> get quests => List.unmodifiable(_quests);
  Set<String> get unlockedLetters => Set.unmodifiable(_unlockedLetters);
  int get unlockedLetterCount => solvedQuestCount;
  int get solvedQuestCount => _letterQuests.where((q) => q.opgelost).length;
  int get totalPlayableQuestCount => finalWord.length;
  int get completedQuestCount => _letterQuests.where((q) => q.opgelost || q.mislukt).length;
  int get collectedFloraCount => _collectedFloraIds.length;
  bool get hasNewFaunaUnlock => _hasNewFaunaUnlock;
  bool get hasNewFloraUnlock => _hasNewFloraUnlock;
  bool get hasNewFinalWordUnlock => _hasNewFinalWordUnlock;
  List<String?> get finalWordSlots {
    final sorted = _sortedLetterQuests;
    final slots = List<String?>.filled(finalWord.length, null);
    for (var i = 0; i < sorted.length && i < slots.length; i++) {
      if (sorted[i].opgelost) slots[i] = sorted[i].letter.toUpperCase();
    }
    return slots;
  }
  List<bool> get finalWordFailedSlots {
    final sorted = _sortedLetterQuests;
    final slots = List<bool>.filled(finalWord.length, false);
    for (var i = 0; i < sorted.length && i < slots.length; i++) {
      slots[i] = sorted[i].mislukt;
    }
    return slots;
  }
  int get points => _points;
  bool get finalWordSolved => _finalWordSolved;
  bool get shouldAutoOpenFinalWord =>
      hasStartedSpeurtocht && _remainingSeconds <= 0 && !_timeoutFinalWordShown;
  bool get isTimerPausedOutsideArea => _timerPausedOutsideArea;
  int? get nextRequiredQuestNumber {
    if (!hasConfirmedStartStop) return 1;
    for (final q in _sortedLetterQuests) {
      if (!q.opgelost && !q.mislukt) return _stopNumber(q);
    }
    return null;
  }
  int get remainingSeconds => _remainingSeconds;
  bool get hasStartedSpeurtocht => _huntStartedAtUtc != null;
  bool get isMapLocked => hasStartedSpeurtocht && _remainingSeconds <= 0;
  bool get hasConfirmedStartStop => _startQuest?.opgelost ?? false;
  bool get shouldShowAllStopsCompletedDialog =>
      completedQuestCount >= totalPlayableQuestCount && !_allStopsCompletedShown;
  String get remainingTimeLabel {
    final safe = _remainingSeconds.clamp(0, _huntDurationSeconds);
    final mm = (safe ~/ 60).toString().padLeft(2, '0');
    final ss = (safe % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  bool get hasLiveLocation => _currentPosition != null;
  double? get liveLat => _currentPosition?.latitude;
  double? get liveLon => _currentPosition?.longitude;
  double? get liveHeading => _currentPosition?.heading;
  String? get locationStatus => _locationStatus;
  String? get pendingQuestTriggerId => _pendingQuestTriggerId;
  double get currentLat => _currentPosition?.latitude ?? _mapCenterLat;
  double get currentLon => _currentPosition?.longitude ?? _mapCenterLon;
  double get mapCenterLat => _mapCenterLat;
  double get mapCenterLon => _mapCenterLon;
  List<({double lat, double lon})> get searchPolygonLatLng =>
      _searchPolygon.map((p) => (lat: p.y, lon: p.x)).toList(growable: false);
  ({double lat, double lon})? get kzLocatieLatLng {
    final p = _kzLocatie;
    if (p == null) return null;
    return (lat: p.y, lon: p.x);
  }

  HuntQuest? questById(String questId) {
    for (final q in _quests) {
      if (q.id == questId) return q;
    }
    return null;
  }

  DierSpawn? spawnById(String spawnId) {
    for (final s in _spawns) {
      if (s.id == spawnId) return s;
    }
    return null;
  }

  int get gevangenAantal => _spawns.where((d) => d.gevangen).length;
  int get totaalSpawns => _spawns.length;

  List<DierSpawn> get gevangenDieren =>
      _spawns.where((d) => d.gevangen).toList(growable: false);

  Map<String, int> get gevangenPerDier {
    final result = <String, int>{};
    for (final dier in gevangenDieren) {
      result[dier.naam] = (result[dier.naam] ?? 0) + 1;
    }
    return result;
  }

  ThemeData get themeData {
    final basis = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF2F6FF),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F80ED)),
    );

    final profiel = _profiel;
    if (profiel == null) return basis;

    final isJongen = profiel.spelerType == SpelerType.jongen;
    final isBegeleid = profiel.leeftijdsgroep == Leeftijdsgroep.begeleid_5_9;

    final primary = isJongen
        ? (isBegeleid ? const Color(0xFF3F8CFF) : const Color(0xFF1F5FD1))
        : (isBegeleid ? const Color(0xFFE96AA8) : const Color(0xFFC04386));

    final secondary = isJongen
        ? (isBegeleid ? const Color(0xFF6BCBFF) : const Color(0xFF3A83F1))
        : (isBegeleid ? const Color(0xFFFF9BC7) : const Color(0xFFE46AA8));

    return basis.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Future<void> hydrate() async {
    _kzLocatie = await _areaService.loadKzLocatiePoint();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);

    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final profielMap = map['profiel'];
        if (profielMap is Map<String, dynamic>) {
          _profiel = SpelerProfiel.fromMap(profielMap);
        }

        _points = map['points'] as int? ?? 0;
        _finalWordSolved = map['finalWordSolved'] as bool? ?? false;
        _timeoutFinalWordShown = map['timeoutFinalWordShown'] as bool? ?? false;
        _allStopsCompletedShown = map['allStopsCompletedShown'] as bool? ?? false;
        final rawHuntStartedAt = map['huntStartedAtUtc'] as String?;
        if (rawHuntStartedAt != null && rawHuntStartedAt.isNotEmpty) {
          _huntStartedAtUtc = DateTime.tryParse(rawHuntStartedAt)?.toUtc();
          final rawPausedAt = map['pausedAtUtc'] as String?;
          if (rawPausedAt != null && rawPausedAt.isNotEmpty) {
            _pausedAtUtc = DateTime.tryParse(rawPausedAt)?.toUtc();
          }
          _pausedSeconds = map['pausedSeconds'] as int? ?? 0;
          _timerPausedOutsideArea = map['timerPausedOutsideArea'] as bool? ?? false;
          _remainingSeconds = _computeRemainingSeconds();
        }

        final lat = (map['lastLat'] as num?)?.toDouble();
        final lon = (map['lastLon'] as num?)?.toDouble();
        if (lat != null && lon != null) {
          _mapCenterLat = lat;
          _mapCenterLon = lon;
        }

        final letters = map['letters'];
        if (letters is List) {
          _unlockedLetters
            ..clear()
            ..addAll(letters.whereType<String>());
        }

        _collectedFloraIds.clear();
        final flora = map['flora'];
        if (flora is List) {
          _collectedFloraIds.addAll(
            flora.whereType<String>().map((id) => id.trim()).where((id) => id.isNotEmpty),
          );
        }

        final rawSpawns = map['spawns'];
        if (rawSpawns is List) {
          _spawns = rawSpawns
              .whereType<Map<String, dynamic>>()
              .map(_spawnFromMap)
              .toList(growable: true);
        }

        final rawQuests = map['quests'];
        if (rawQuests is List) {
          _quests = rawQuests
              .whereType<Map<String, dynamic>>()
              .map(HuntQuest.fromMap)
              .toList(growable: true);
        }
      } catch (_) {
        _resetState();
      }
    }

    _isHydrated = true;
    _startOrRefreshCountdownTicker();
    notifyListeners();

    if (_profiel != null &&
        (_spawns.isEmpty ||
            _quests.isEmpty ||
            _spawnsNeedMigration(_spawns) ||
            _questsNeedMigration(_quests))) {
      await startNieuweSpeurtocht();
    }
  }

  Future<void> selectThema({
    required Leeftijdsgroep leeftijdsgroep,
    required SpelerType spelerType,
    required String nickname,
    String? photoPath,
  }) async {
    final trimmedNickname = nickname.trim();
    final normalizedPhoto = photoPath?.trim();
    _profiel = SpelerProfiel(
      nickname: trimmedNickname.isEmpty
          ? (spelerType == SpelerType.jongen ? 'Avonturier' : 'Ontdekker')
          : trimmedNickname,
      leeftijdsgroep: leeftijdsgroep,
      spelerType: spelerType,
      photoPath: (normalizedPhoto == null || normalizedPhoto.isEmpty)
          ? null
          : normalizedPhoto,
    );

    _resetProgress();
    await startNieuweSpeurtocht();
    await _saveSnapshot();
    notifyListeners();
  }

  Future<void> logoutAndReset() async {
    await stopGpsTracking();
    _countdownTicker?.cancel();
    _resetState();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  Future<void> startNieuweSpeurtocht() async {
    final rawPolygon = await _areaService.loadPolygon();
    final faunaPoints = await _areaService.loadFaunaPoints();
    _kzLocatie = await _areaService.loadKzLocatiePoint();
    _searchPolygon = rawPolygon;
    _updateMapCenterFromPolygon(rawPolygon);

    final questStops = await _areaService.loadQuestStops();
    _quests = _buildQuests(rawPolygon, questStops);
    final questPoints = _quests.map((q) => (x: q.x, y: q.y)).toList(growable: false);
    if (faunaPoints.length >= faunaTotalCount) {
      _spawns = _spawnService.genereerSpawnsOpVasteLocaties(
        points: faunaPoints,
        totaal: faunaTotalCount,
      );
    } else {
      _spawns = _spawnService.genereerSpawns(
        polygon: rawPolygon,
        avoidPoints: questPoints,
        minDistanceToAvoidPointsMeters: _minSpawnDistanceToQuestMeters,
        totaal: faunaTotalCount,
      );
    }
    _unlockedLetters.clear();
    _hasNewFaunaUnlock = false;
    _hasNewFloraUnlock = false;
    _hasNewFinalWordUnlock = false;
    _finalWordSolved = false;
    _autoCatchNearbySpawns();
    _timeoutFinalWordShown = false;
    _allStopsCompletedShown = false;
    await _saveSnapshot();
    notifyListeners();
  }

  Future<void> ensureSearchPolygonLoaded() async {
    if (_searchPolygon.isNotEmpty) return;
    final rawPolygon = await _areaService.loadPolygon();
    _searchPolygon = rawPolygon;
    _updateMapCenterFromPolygon(rawPolygon);
    notifyListeners();
  }

  Future<void> startGpsTracking() async {
    if (_positionSub != null) return;

    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      _locationStatus = 'Locatie staat uit op dit toestel.';
      notifyListeners();
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _locationStatus = 'Locatie toestemming ontbreekt.';
      notifyListeners();
      return;
    }

    _locationStatus = null;

    try {
      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _currentPosition = current;
      _mapCenterLat = current.latitude;
      _mapCenterLon = current.longitude;
      _syncTimerPauseForPosition(current.latitude, current.longitude);
      _processProximityTriggers();
      notifyListeners();
    } catch (_) {
      _locationStatus = 'Kon huidige locatie niet ophalen.';
      notifyListeners();
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).listen((position) {
      _currentPosition = position;
      _mapCenterLat = position.latitude;
      _mapCenterLon = position.longitude;
      _syncTimerPauseForPosition(position.latitude, position.longitude);
      final proximityChanged = _processProximityTriggers();
      if (proximityChanged) {
        _saveSnapshot();
      }
      notifyListeners();
    });

    _startGpsRefreshTicker();
  }

  Future<void> stopGpsTracking() async {
    await _positionSub?.cancel();
    _positionSub = null;
    _gpsRefreshTicker?.cancel();
    _gpsRefreshTicker = null;
  }

  int movePlayer(double dx, double dy) {
    return 0;
  }

  bool losQuestOp({
    required String questId,
    required String antwoord,
  }) {
    if (_currentPosition == null) return false;
    final index = _quests.indexWhere((q) => q.id == questId);
    if (index == -1) return false;

    final quest = _quests[index];
    if (quest.opgelost || quest.mislukt) return false;
    if (!_isNextQuestInOrder(quest.id)) return false;

    final dichtbij = _distanceMeters(
          currentLat,
          currentLon,
          quest.y,
          quest.x,
        ) <=
        _questRadiusMeters;
    if (!dichtbij) return false;

    final correct =
        antwoord.trim().toLowerCase() == quest.antwoord.trim().toLowerCase();
    if (!correct) return false;

    quest.opgelost = true;
    _unlockedLetters.add(quest.letter.toUpperCase());
    _hasNewFinalWordUnlock = true;
    _points += 30;
    notifyListeners();
    _saveSnapshot();
    return true;
  }

  QuestSolveResult losQuestOpViaMapKlik({required String questId}) {
    final index = _quests.indexWhere((q) => q.id == questId);
    if (index == -1) return QuestSolveResult.notFound;
    final quest = _quests[index];
    if (quest.opgelost) return QuestSolveResult.alreadySolved;
    if (quest.mislukt) return QuestSolveResult.failedLocked;
    if (!_isNextQuestInOrder(quest.id)) return QuestSolveResult.outOfOrder;

    quest.opgelost = true;
    if (_pendingQuestTriggerId == questId) {
      _pendingQuestTriggerId = null;
    }
    _unlockedLetters.add(quest.letter.toUpperCase());
    _hasNewFinalWordUnlock = true;
    _points += 30;
    notifyListeners();
    _saveSnapshot();
    return QuestSolveResult.success;
  }

  bool markQuestMisluktViaMapKlik({required String questId}) {
    final index = _quests.indexWhere((q) => q.id == questId);
    if (index == -1) return false;
    final quest = _quests[index];
    if (_stopNumber(quest) == 1) return false;
    if (quest.opgelost || quest.mislukt) return false;

    quest.mislukt = true;
    if (_pendingQuestTriggerId == questId) {
      _pendingQuestTriggerId = null;
    }
    notifyListeners();
    _saveSnapshot();
    return true;
  }

  DierSpawn? vangDierViaMapKlik(String spawnId) {
    final index = _spawns.indexWhere((s) => s.id == spawnId);
    if (index == -1) return null;
    final spawn = _spawns[index];
    if (spawn.gevangen) return spawn;
    final hadSpeciesBefore = _hasCapturedSpecies(spawn.naam);

    spawn.gevangen = true;
    if (!hadSpeciesBefore) {
      _hasNewFaunaUnlock = true;
    }
    _points += _puntenVoorZeldzaamheid(spawn.zeldzaamheid);
    notifyListeners();
    _saveSnapshot();
    return spawn;
  }

  bool checkFinalWord(String candidate) {
    final isCorrect = candidate.trim().toUpperCase() == finalWord;
    if (!isCorrect) return false;

    _finalWordSolved = true;
    _points += 100;
    notifyListeners();
    _saveSnapshot();
    return true;
  }

  bool markFloraCollected(String floraId) {
    final id = floraId.trim();
    if (id.isEmpty) return false;
    final added = _collectedFloraIds.add(id);
    if (!added) return false;
    _hasNewFloraUnlock = true;
    notifyListeners();
    _saveSnapshot();
    return true;
  }

  void clearFaunaUnlockBadge() {
    if (!_hasNewFaunaUnlock) return;
    _hasNewFaunaUnlock = false;
    notifyListeners();
  }

  void clearFloraUnlockBadge() {
    if (!_hasNewFloraUnlock) return;
    _hasNewFloraUnlock = false;
    notifyListeners();
  }

  void clearFinalWordUnlockBadge() {
    if (!_hasNewFinalWordUnlock) return;
    _hasNewFinalWordUnlock = false;
    notifyListeners();
  }

  void markFinalWordAutoOpened() {
    if (_timeoutFinalWordShown) return;
    _timeoutFinalWordShown = true;
    _saveSnapshot();
  }

  bool get _canSolveFinalWord {
    return solvedQuestCount >= finalWord.length;
  }

  bool canActivateStartStop({required String questId}) {
    if (_huntStartedAtUtc != null) return true;
    if (questId != 'stop_1') return false;
    if (_currentPosition == null) return false;
    final startQuest = _startQuest;
    if (startQuest == null) return false;
    final afstand = _distanceMeters(
      currentLat,
      currentLon,
      startQuest.y,
      startQuest.x,
    );
    return afstand <= _questRadiusMeters;
  }

  Future<bool> activateStartStop({required String questId}) async {
    if (questId != 'stop_1') return false;
    final startQuest = _startQuest;
    if (startQuest == null) return false;
    if (!canActivateStartStop(questId: questId)) return false;

    if (!startQuest.opgelost) {
      startQuest.opgelost = true;
    }
    if (_pendingQuestTriggerId == questId) {
      _pendingQuestTriggerId = null;
    }
    if (_huntStartedAtUtc == null) {
      _startHuntCountdown();
    }
    notifyListeners();
    await _saveSnapshot();
    return true;
  }

  List<HuntQuest> get nearbyQuests {
    if (_currentPosition == null) return const [];
    return _quests
        .where((q) =>
            !q.opgelost &&
            _distanceMeters(currentLat, currentLon, q.y, q.x) <=
                _questRadiusMeters)
        .toList(growable: false);
  }

  void consumePendingQuestTrigger(String questId) {
    if (_pendingQuestTriggerId != questId) return;
    _pendingQuestTriggerId = null;
    notifyListeners();
  }

  List<String> consumePendingFaunaUnlockIds() {
    if (_pendingFaunaUnlockIds.isEmpty) return const <String>[];
    final ids = List<String>.from(_pendingFaunaUnlockIds);
    _pendingFaunaUnlockIds.clear();
    notifyListeners();
    return ids;
  }

  void markAllStopsCompletedDialogShown() {
    if (_allStopsCompletedShown) return;
    _allStopsCompletedShown = true;
    _saveSnapshot();
  }

  List<AchievementState> get achievements {
    final hasFirstCatch = gevangenAantal >= 1;
    final hasFiveCatches = gevangenAantal >= 5;
    final hasTenCatches = gevangenAantal >= 10;
    final hasThreeLetters = _unlockedLetters.length >= 3;
    final hasAllLetters = _canSolveFinalWord;

    return [
      AchievementState(
        titel: 'Eerste Vangst',
        beschrijving: 'Vang je eerste dier.',
        behaald: hasFirstCatch,
      ),
      AchievementState(
        titel: 'Mini Verzamelaar',
        beschrijving: 'Vang 5 dieren.',
        behaald: hasFiveCatches,
      ),
      AchievementState(
        titel: 'Top Tracker',
        beschrijving: 'Vang 10 dieren.',
        behaald: hasTenCatches,
      ),
      AchievementState(
        titel: 'Letterjager',
        beschrijving: 'Speel 3 quests vrij.',
        behaald: hasThreeLetters,
      ),
      AchievementState(
        titel: 'Woord Klaar',
        beschrijving: 'Verzamel alle letters van $finalWord.',
        behaald: hasAllLetters,
      ),
      AchievementState(
        titel: 'Kampioen',
        beschrijving: 'Los het finale woord op.',
        behaald: _finalWordSolved,
      ),
    ];
  }

  List<HuntQuest> _buildQuests(
    List<({double x, double y})> polygon,
    List<({int featureNumber, double x, double y})> questStops,
  ) {
    if (questStops.length >= questStopCount) {
      return _buildQuestsFromGeoJson(questStops);
    }

    final rawPoints = List.generate(
      questStopCount,
      (_) => _randomPoint(polygon),
      growable: false,
    );
    final orderedPoints = _orderPointsForShortestRoute(rawPoints);
    final letters = finalWord.split('');

    return List.generate(questStopCount, (i) {
      final p = orderedPoints[i];
      final stopNumber = i + 1;
      final isStart = stopNumber == 1;
      final letterIndex = stopNumber - 2;
      return HuntQuest(
        id: 'stop_$stopNumber',
        titel: 'Stop $stopNumber',
        vraag: isStart
            ? 'Klaar voor de Start?'
            : 'Beantwoord de bosvraag bij deze stop.',
        antwoord: isStart ? '' : letters[letterIndex].toLowerCase(),
        letter: isStart ? '' : letters[letterIndex],
        x: p.$1,
        y: p.$2,
      );
    }, growable: true);
  }

  List<HuntQuest> _buildQuestsFromGeoJson(
    List<({int featureNumber, double x, double y})> questStops,
  ) {
    final letters = finalWord.split('');
    return questStops.take(questStopCount).map((stop) {
      final stopNumber = stop.featureNumber;
      final isStart = stopNumber == 1;
      final letterIndex = stopNumber - 2;
      final hasLetter = letterIndex >= 0 && letterIndex < letters.length;
      return HuntQuest(
        id: 'stop_$stopNumber',
        titel: 'Stop $stopNumber',
        vraag: isStart
            ? 'Klaar voor de Start?'
            : 'Beantwoord de bosvraag bij deze stop.',
        antwoord: hasLetter ? letters[letterIndex].toLowerCase() : '',
        letter: hasLetter ? letters[letterIndex] : '',
        x: stop.x,
        y: stop.y,
      );
    }).toList(growable: true);
  }

  List<(double, double)> _orderPointsForShortestRoute(List<(double, double)> points) {
    if (points.length <= 2) return List<(double, double)>.from(points);
    final remaining = List<(double, double)>.from(points);
    final route = <(double, double)>[];
    (double, double) current = (_mapCenterLon, _mapCenterLat);

    while (remaining.isNotEmpty) {
      remaining.sort((a, b) {
        final da = _distanceMeters(current.$2, current.$1, a.$2, a.$1);
        final db = _distanceMeters(current.$2, current.$1, b.$2, b.$1);
        return da.compareTo(db);
      });
      final next = remaining.removeAt(0);
      route.add(next);
      current = next;
    }

    return route;
  }

  (double, double) _randomPoint(List<({double x, double y})> polygon) {
    if (polygon.isEmpty) return (_mapCenterLon, _mapCenterLat);
    final xs = polygon.map((p) => p.x).toList(growable: false);
    final ys = polygon.map((p) => p.y).toList(growable: false);
    final minX = xs.reduce(math.min);
    final maxX = xs.reduce(math.max);
    final minY = ys.reduce(math.min);
    final maxY = ys.reduce(math.max);

    for (var i = 0; i < 600; i++) {
      final x = minX + _random.nextDouble() * (maxX - minX);
      final y = minY + _random.nextDouble() * (maxY - minY);
      if (_pointInPolygon(x, y, polygon)) return (x, y);
    }

    final fallback = polygon[_random.nextInt(polygon.length)];
    return (fallback.x, fallback.y);
  }

  bool _pointInPolygon(double x, double y, List<({double x, double y})> polygon) {
    var inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].x;
      final yi = polygon[i].y;
      final xj = polygon[j].x;
      final yj = polygon[j].y;
      final intersect = ((yi > y) != (yj > y)) &&
          (x <
              (xj - xi) * (y - yi) /
                      ((yj - yi).abs() < 1e-9 ? 1e-9 : (yj - yi)) +
                  xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  int _puntenVoorZeldzaamheid(DierZeldzaamheid z) {
    switch (z) {
      case DierZeldzaamheid.normaal:
        return 5;
      case DierZeldzaamheid.zeldzaam:
        return 12;
      case DierZeldzaamheid.legendarisch:
        return 20;
    }
  }

  int _autoCatchNearbySpawns() {
    if (_currentPosition == null) return 0;
    final nowUtc = DateTime.now().toUtc();
    var count = 0;
    final lat = currentLat;
    final lon = currentLon;

    for (final spawn in _spawns) {
      if (spawn.gevangen) {
        _spawnProximitySinceUtc.remove(spawn.id);
        continue;
      }
      final d = _distanceMeters(lat, lon, spawn.y, spawn.x);
      if (d > _autoCatchRadiusMeters) {
        _spawnProximitySinceUtc.remove(spawn.id);
        continue;
      }

      final since = _spawnProximitySinceUtc.putIfAbsent(spawn.id, () => nowUtc);
      final dwell = nowUtc.difference(since).inSeconds;
      if (dwell < _proximityDwellSeconds) continue;

      final hadSpeciesBefore = _hasCapturedSpecies(spawn.naam);
      spawn.gevangen = true;
      _spawnProximitySinceUtc.remove(spawn.id);
      if (!_pendingFaunaUnlockIds.contains(spawn.id)) {
        _pendingFaunaUnlockIds.add(spawn.id);
      }
      if (!hadSpeciesBefore) {
        _hasNewFaunaUnlock = true;
      }
      _points += _puntenVoorZeldzaamheid(spawn.zeldzaamheid);
      count++;
    }
    return count;
  }

  bool _processProximityTriggers() {
    final caught = _autoCatchNearbySpawns();
    final questChanged = _updateQuestProximityTrigger();
    return caught > 0 || questChanged;
  }

  bool _updateQuestProximityTrigger() {
    if (_currentPosition == null) return false;
    final requiredStop = nextRequiredQuestNumber;
    final targetId = requiredStop == null ? null : 'stop_$requiredStop';
    var changed = false;

    if (targetId == null) {
      _questProximitySinceUtc.clear();
      if (_pendingQuestTriggerId != null) {
        _pendingQuestTriggerId = null;
        changed = true;
      }
      return changed;
    }

    final targetQuest = questById(targetId);
    if (targetQuest == null || targetQuest.opgelost || targetQuest.mislukt) {
      _questProximitySinceUtc.clear();
      if (_pendingQuestTriggerId != null) {
        _pendingQuestTriggerId = null;
        changed = true;
      }
      return changed;
    }

    _questProximitySinceUtc.removeWhere((id, _) => id != targetId);
    final nowUtc = DateTime.now().toUtc();
    final distance = _distanceMeters(
      currentLat,
      currentLon,
      targetQuest.y,
      targetQuest.x,
    );

    if (distance > _questRadiusMeters) {
      if (_questProximitySinceUtc.remove(targetId) != null) changed = true;
      if (_pendingQuestTriggerId == targetId) {
        _pendingQuestTriggerId = null;
        changed = true;
      }
      return changed;
    }

    final since = _questProximitySinceUtc.putIfAbsent(targetId, () => nowUtc);
    final dwell = nowUtc.difference(since).inSeconds;
    if (dwell >= _proximityDwellSeconds && _pendingQuestTriggerId != targetId) {
      _pendingQuestTriggerId = targetId;
      changed = true;
    }
    return changed;
  }

  double _distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _toRad(double deg) => deg * (math.pi / 180.0);

  bool _hasCapturedSpecies(String animalName) {
    for (final s in _spawns) {
      if (!s.gevangen) continue;
      if (s.naam == animalName) return true;
    }
    return false;
  }

  void _updateMapCenterFromPolygon(List<({double x, double y})> polygon) {
    if (polygon.isEmpty) return;
    double sumLon = 0;
    double sumLat = 0;
    for (final p in polygon) {
      sumLon += p.x;
      sumLat += p.y;
    }
    _mapCenterLon = sumLon / polygon.length;
    _mapCenterLat = sumLat / polygon.length;
  }

  Map<String, dynamic> _spawnToMap(DierSpawn d) {
    return {
      'id': d.id,
      'naam': d.naam,
      'zeldzaamheid': _zeldzaamheidToKey(d.zeldzaamheid),
      'x': d.x,
      'y': d.y,
      'gevangen': d.gevangen,
    };
  }

  DierSpawn _spawnFromMap(Map<String, dynamic> map) {
    final z = _zeldzaamheidFromKey(map['zeldzaamheid'] as String?);

    return DierSpawn(
      id: map['id'] as String,
      naam: map['naam'] as String,
      zeldzaamheid: z,
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      gevangen: map['gevangen'] as bool? ?? false,
    );
  }

  String _zeldzaamheidToKey(DierZeldzaamheid value) {
    switch (value) {
      case DierZeldzaamheid.normaal:
        return 'normaal';
      case DierZeldzaamheid.zeldzaam:
        return 'zeldzaam';
      case DierZeldzaamheid.legendarisch:
        return 'legendarisch';
    }
  }

  DierZeldzaamheid _zeldzaamheidFromKey(String? value) {
    switch (value) {
      case 'normaal':
        return DierZeldzaamheid.normaal;
      case 'zeldzaam':
        return DierZeldzaamheid.zeldzaam;
      case 'legendarisch':
        return DierZeldzaamheid.legendarisch;
      default:
        return DierZeldzaamheid.normaal;
    }
  }

  Future<void> _saveSnapshot() async {
    if (_profiel == null) return;

    final map = {
      'profiel': _profiel!.toMap(),
      'spawns': _spawns.map(_spawnToMap).toList(growable: false),
      'quests': _quests.map((q) => q.toMap()).toList(growable: false),
      'letters': _unlockedLetters.toList(growable: false),
      'flora': _collectedFloraIds.toList(growable: false),
      'points': _points,
      'finalWordSolved': _finalWordSolved,
      'timeoutFinalWordShown': _timeoutFinalWordShown,
      'allStopsCompletedShown': _allStopsCompletedShown,
      'huntStartedAtUtc': _huntStartedAtUtc?.toIso8601String(),
      'pausedAtUtc': _pausedAtUtc?.toIso8601String(),
      'pausedSeconds': _pausedSeconds,
      'timerPausedOutsideArea': _timerPausedOutsideArea,
      'lastLat': _currentPosition?.latitude ?? _mapCenterLat,
      'lastLon': _currentPosition?.longitude ?? _mapCenterLon,
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  void _resetProgress() {
    _points = 0;
    _spawns = [];
    _quests = [];
    _searchPolygon = [];
    _unlockedLetters.clear();
    _collectedFloraIds.clear();
    _hasNewFaunaUnlock = false;
    _hasNewFloraUnlock = false;
    _hasNewFinalWordUnlock = false;
    _finalWordSolved = false;
    _timeoutFinalWordShown = false;
    _allStopsCompletedShown = false;
    _huntStartedAtUtc = null;
    _pausedAtUtc = null;
    _pausedSeconds = 0;
    _timerPausedOutsideArea = false;
    _remainingSeconds = _huntDurationSeconds;
    _countdownTicker?.cancel();
    _countdownTicker = null;
    _gpsRefreshTicker?.cancel();
    _gpsRefreshTicker = null;
    _spawnProximitySinceUtc.clear();
    _questProximitySinceUtc.clear();
    _pendingQuestTriggerId = null;
    _pendingFaunaUnlockIds.clear();
    AudioService.instance.stopTimerWarningLoop();
  }

  void _resetState() {
    _profiel = null;
    _currentPosition = null;
    _locationStatus = null;
    _resetProgress();
  }

  void _startHuntCountdown() {
    _huntStartedAtUtc = DateTime.now().toUtc();
    _pausedAtUtc = null;
    _pausedSeconds = 0;
    _timerPausedOutsideArea = false;
    _remainingSeconds = _huntDurationSeconds;
    _syncTimerWarningAudio();
    _startOrRefreshCountdownTicker();
  }

  int _computeRemainingSeconds() {
    final startedAt = _huntStartedAtUtc;
    if (startedAt == null) return _huntDurationSeconds;
    final now = DateTime.now().toUtc();
    final elapsed = now.difference(startedAt).inSeconds;
    final activePauseSeconds =
        _pausedAtUtc == null ? 0 : now.difference(_pausedAtUtc!).inSeconds;
    final paused = _pausedSeconds + activePauseSeconds;
    final activeElapsed = (elapsed - paused).clamp(0, _huntDurationSeconds);
    return (_huntDurationSeconds - activeElapsed).clamp(0, _huntDurationSeconds);
  }

  void _startOrRefreshCountdownTicker() {
    _countdownTicker?.cancel();
    if (_huntStartedAtUtc == null) {
      _syncTimerWarningAudio();
      return;
    }

    _remainingSeconds = _computeRemainingSeconds();
    _syncTimerWarningAudio();
    if (_remainingSeconds <= 0) {
      _remainingSeconds = 0;
      _syncTimerWarningAudio();
      _saveSnapshot();
      return;
    }

    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = _computeRemainingSeconds();
      if (next == _remainingSeconds) return;
      _remainingSeconds = next;
      _syncTimerWarningAudio();

      if (_remainingSeconds <= 0) {
        _remainingSeconds = 0;
        _countdownTicker?.cancel();
        _syncTimerWarningAudio();
        stopGpsTracking();
        _saveSnapshot();
      }
      notifyListeners();
    });
  }

  void _syncTimerWarningAudio() {
    if (_huntStartedAtUtc == null || _remainingSeconds <= 0) {
      AudioService.instance.stopTimerWarningLoop();
      return;
    }
    if (_remainingSeconds <= 600) {
      AudioService.instance.startTimerWarningLoop();
      return;
    }
    AudioService.instance.stopTimerWarningLoop();
  }

  void _startGpsRefreshTicker() {
    _gpsRefreshTicker?.cancel();
    _gpsRefreshTicker = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_positionSub == null) return;
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        _currentPosition = position;
        _mapCenterLat = position.latitude;
        _mapCenterLon = position.longitude;
        _syncTimerPauseForPosition(position.latitude, position.longitude);
        final proximityChanged = _processProximityTriggers();
        if (proximityChanged) {
          _saveSnapshot();
        }
        notifyListeners();
      } catch (_) {
        // Keep last known location if this refresh tick fails.
      }
    });
  }

  List<HuntQuest> get _sortedLetterQuests {
    final sorted = List<HuntQuest>.from(_letterQuests);
    sorted.sort((a, b) => _stopNumber(a).compareTo(_stopNumber(b)));
    return sorted;
  }

  List<HuntQuest> get _letterQuests {
    return _quests.where((q) {
      final n = _stopNumber(q);
      return n >= 2 && n <= questStopCount;
    }).toList(growable: false);
  }

  HuntQuest? get _startQuest {
    for (final q in _quests) {
      if (_stopNumber(q) == 1) return q;
    }
    return null;
  }

  int _stopNumber(HuntQuest q) {
    final m = RegExp(r'(\d+)').firstMatch(q.id);
    if (m == null) return 9999;
    return int.tryParse(m.group(1) ?? '') ?? 9999;
  }

  bool _isNextQuestInOrder(String questId) {
    if (!hasConfirmedStartStop) return false;
    for (final q in _sortedLetterQuests) {
      if (q.opgelost || q.mislukt) continue;
      return q.id == questId;
    }
    return false;
  }

  bool _questsNeedMigration(List<HuntQuest> quests) {
    if (quests.length != questStopCount) return true;
    final ids = quests.map((q) => q.id).toSet();
    for (var i = 1; i <= questStopCount; i++) {
      if (!ids.contains('stop_$i')) return true;
    }
    return false;
  }

  bool _spawnsNeedMigration(List<DierSpawn> spawns) {
    if (spawns.length != faunaTotalCount) return true;
    for (final spawn in spawns) {
      final name = spawn.naam.trim().toLowerCase();
      if (name == 'duif' || name == 'kraai' || name == 'raaf') {
        return true;
      }
    }
    return false;
  }

  void _syncTimerPauseForPosition(double lat, double lon) {
    if (_huntStartedAtUtc == null || _remainingSeconds <= 0) return;
    if (!_timerPausedOutsideArea && _pausedAtUtc == null) return;
    _timerPausedOutsideArea = false;
    _pausedAtUtc = null;
    _remainingSeconds = _computeRemainingSeconds();
    _saveSnapshot();
  }
}
