import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/dier_spawn.dart';
import '../models/hunt_quest.dart';
import '../providers/hunt_game_state.dart';
import '../services/audio_service.dart';
import '../widgets/game_top_bar.dart';
import '../widgets/subtle_logo.dart';
import 'navigation_helpers.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  HuntGameState? _game;
  bool _autoCenteredOnGps = false;
  double _mapRotationDegrees = 0.0;
  bool _openingQuestFromGps = false;
  bool _processingFaunaUnlockDialogs = false;
  bool _showingAllStopsDialog = false;
  late final AnimationController _warningPulseController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _game ??= context.read<HuntGameState>();
  }

  @override
  void initState() {
    super.initState();
    _warningPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _game?.startGpsTracking();
    });
  }

  @override
  void dispose() {
    _warningPulseController.dispose();
    _game?.stopGpsTracking();
    super.dispose();
  }

  Future<void> _onSpawnTap(DierSpawn spawn) async {
    if (spawn.gevangen) {
      await _showAnimalDialog(spawn, isNewUnlock: false);
      return;
    }
    final game = context.read<HuntGameState>();
    final wasAlreadyUnlocked = (game.gevangenPerDier[spawn.naam] ?? 0) > 0;
    final captured = game.vangDierViaMapKlik(spawn.id);
    if (captured == null) return;
    if (!wasAlreadyUnlocked && captured.zeldzaamheid == DierZeldzaamheid.legendarisch) {
      await AudioService.instance.playAnimalCueByName(captured.naam);
    } else if (wasAlreadyUnlocked) {
      await AudioService.instance.playAnimalCueByName(captured.naam);
    } else {
      await AudioService.instance.playCollectObject();
    }

    await _showAnimalDialog(captured, isNewUnlock: true);
  }

  Future<void> _showAnimalDialog(
    DierSpawn spawn, {
    required bool isNewUnlock,
  }) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dier',
      transitionDuration: Duration(milliseconds: isNewUnlock ? 520 : 280),
      pageBuilder: (_, __, ___) {
        return Center(
          child: _caughtAnimalCard(spawn, isNewUnlock: isNewUnlock),
        );
      },
      transitionBuilder: (context, anim, _, child) {
        final fade = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        final scale = CurvedAnimation(
          parent: anim,
          curve: isNewUnlock ? Curves.elasticOut : Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: isNewUnlock ? 0.82 : 0.92,
              end: 1.0,
            ).animate(scale),
            child: child,
          ),
        );
      },
    );
  }

  Widget _caughtAnimalCard(DierSpawn spawn, {required bool isNewUnlock}) {
    final rarityColor = _rarityColor(spawn.zeldzaamheid);
    final rarityLabel = _rarityLabel(spawn.zeldzaamheid);

    return Container(
      width: 290,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7EEDC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: rarityColor, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isNewUnlock) ...[
            const Text(
              'Nieuw dier gevonden!',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontSize: 18,
                fontWeight: FontWeight.w900,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
          ],
          Text(
            spawn.naam,
            style: const TextStyle(
              color: Color(0xFF3B2818),
              fontSize: 24,
              fontWeight: FontWeight.w900,
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            rarityLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: rarityColor,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 92,
            child: Image.asset(
              'assets/animals/master/${spawn.naam}.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/animals/icons_300/${spawn.naam}.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _questNumber(HuntQuest q) {
    final m = RegExp(r'(\d+)').firstMatch(q.id);
    return int.tryParse(m?.group(1) ?? '') ?? 0;
  }

  int _displayQuestNumber(HuntQuest q) {
    final raw = _questNumber(q);
    if (raw <= 1) return 1;
    return raw - 1;
  }

  bool _isStartQuest(HuntQuest q) => _questNumber(q) == 1;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<HuntGameState>();
    final outsideSearchArea = game.hasLiveLocation &&
        !_isInsideSearchArea(
          game.liveLat!,
          game.liveLon!,
          game.searchPolygonLatLng,
        );
    final targetBearingToSearchArea = outsideSearchArea && game.hasLiveLocation
        ? _bearingToSearchAreaCenter(
            game.liveLat!,
            game.liveLon!,
            game.searchPolygonLatLng,
          )
        : null;
    final nearestFaunaMeters = _nearestFaunaMeters(game);
    final nearestQuestMeters = _nearestQuestMeters(game);
    final polygonPoints = game.searchPolygonLatLng
        .map((p) => LatLng(p.lat, p.lon))
        .toList(growable: false);

    if (game.isMapLocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<HuntGameState>().markFinalWordAutoOpened();
        openTopTab(context, GameTopTab.finalWord);
      });
    }

    if (!_processingFaunaUnlockDialogs) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || _processingFaunaUnlockDialogs) return;
        final gameState = context.read<HuntGameState>();
        final pendingIds = gameState.consumePendingFaunaUnlockIds();
        if (pendingIds.isEmpty) return;
        _processingFaunaUnlockDialogs = true;
        for (final spawnId in pendingIds) {
          if (!mounted) break;
          final spawn = gameState.spawnById(spawnId);
          if (spawn == null) continue;
          await AudioService.instance.playCollectObject();
          if (spawn.zeldzaamheid == DierZeldzaamheid.legendarisch) {
            await AudioService.instance.playAnimalCueByName(spawn.naam);
          }
          if (!mounted) break;
          await _showAnimalDialog(spawn, isNewUnlock: true);
        }
        _processingFaunaUnlockDialogs = false;
      });
    }

    final pendingQuestId = game.pendingQuestTriggerId;
    if (pendingQuestId != null && !_openingQuestFromGps) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || _openingQuestFromGps) return;
        final gameState = context.read<HuntGameState>();
        final quest = gameState.questById(pendingQuestId);
        if (quest == null || quest.opgelost || quest.mislukt) {
          gameState.consumePendingQuestTrigger(pendingQuestId);
          return;
        }
        _openingQuestFromGps = true;
        gameState.consumePendingQuestTrigger(pendingQuestId);
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _QuestQuizScreen(quest: quest),
          ),
        );
        _openingQuestFromGps = false;
      });
    }

    if (game.shouldShowAllStopsCompletedDialog && !_showingAllStopsDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || _showingAllStopsDialog) return;
        final gameState = context.read<HuntGameState>();
        if (!gameState.shouldShowAllStopsCompletedDialog) return;
        _showingAllStopsDialog = true;
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Alle stops gehad!'),
            content: const Text(
              'Raad het woord en ga terug naar Klein Zwitserland voor een verrassing!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        gameState.markAllStopsCompletedDialogShown();
        _showingAllStopsDialog = false;
      });
    }

    final spawnMarkers = game.spawns
        .map(
          (s) => Marker(
            point: LatLng(s.y, s.x),
            width: 34,
            height: 34,
            rotate: true,
            child: GestureDetector(
              onTap: s.gevangen ? () => _onSpawnTap(s) : null,
              child: s.gevangen
                  ? Icon(
                      Icons.pets,
                      color: _rarityColor(s.zeldzaamheid),
                      size: 24,
                    )
                  : Image.asset(
                      'assets/animals/icons_300_silhouette/${s.naam}.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.pets,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
            ),
          ),
        )
        .toList(growable: false);

    final questMarkers = game.quests.map((q) {
      return Marker(
        point: LatLng(q.y, q.x),
        width: 38,
        height: 38,
        rotate: true,
        child: GestureDetector(
          onTap: null,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: q.opgelost
                  ? const Color(0xFF2E7D32).withValues(alpha: 0.75)
                  : q.mislukt
                      ? const Color(0xFFC62828).withValues(alpha: 0.75)
                      : const Color(0xFFD84315).withValues(alpha: 0.75),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.75), width: 2),
            ),
             child: q.opgelost
                 ? Icon(Icons.check, color: Colors.white.withValues(alpha: 0.75), size: 20)
                 : q.mislukt
                     ? Icon(Icons.close, color: Colors.white.withValues(alpha: 0.75), size: 20)
                     : _isStartQuest(q)
                         ? Icon(
                             Icons.play_arrow_rounded,
                             color: Colors.white.withValues(alpha: 0.90),
                             size: 22,
                           )
                      : Text(
                          '${_displayQuestNumber(q)}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                           fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
          ),
        ),
      );
    }).toList(growable: false);

    final kz = game.kzLocatieLatLng;
    final kzMarkers = kz == null
        ? const <Marker>[]
        : [
            Marker(
              point: LatLng(kz.lat, kz.lon),
              width: 72,
              height: 72,
              rotate: true,
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ];

    if (game.hasLiveLocation && !_autoCenteredOnGps) {
      _autoCenteredOnGps = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !game.hasLiveLocation) return;
        _mapController.move(
          LatLng(game.liveLat!, game.liveLon!),
          17.5,
        );
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3E5C8),
      body: SafeArea(
        child: Stack(
        children: [
          Positioned.fill(
            child: Container(color: const Color(0xFFF3E5C8)),
          ),
          Column(
            children: [
              GameTopBar(
                currentTab: GameTopTab.map,
                onTabSelected: (tab) => openTopTab(context, tab),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    _pill('Letters', '${game.unlockedLetterCount}/10'),
                    const SizedBox(width: 6),
                    _pill('Bosdier', '${game.gevangenAantal}/${game.totaalSpawns}'),
                    const SizedBox(width: 6),
                    _pill('Quests', '${game.completedQuestCount}/${game.totalPlayableQuestCount}'),
                  ],
                ),
              ),
              if (game.locationStatus != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(
                    game.locationStatus!,
                    style: const TextStyle(
                      color: Color(0xFFB71C1C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(game.mapCenterLat, game.mapCenterLon),
                        initialZoom: 16,
                        initialRotation: 0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                        minZoom: 12,
                        maxZoom: 19,
                        onMapEvent: (event) {
                          final r = event.camera.rotation;
                          if ((r - _mapRotationDegrees).abs() < 0.01) return;
                          if (!mounted) return;
                          setState(() => _mapRotationDegrees = r);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'kz_game',
                        ),
                        if (polygonPoints.length >= 3)
                          PolygonLayer(
                            polygons: [
                              Polygon(
                                points: polygonPoints,
                                color: const Color(0xFF2E7D32).withValues(alpha: 0.20),
                                borderColor: const Color(0xFF0B5D1E),
                                borderStrokeWidth: 3.0,
                              ),
                            ],
                          ),
                        if (polygonPoints.length >= 3)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: [
                                  ...polygonPoints,
                                  polygonPoints.first,
                                ],
                                strokeWidth: 5.0,
                                color: const Color(0xFFB8FF5C).withValues(alpha: 0.75),
                              ),
                            ],
                          ),
                        MarkerLayer(markers: spawnMarkers),
                        MarkerLayer(markers: questMarkers),
                        MarkerLayer(markers: kzMarkers),
                        if (game.hasLiveLocation)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(game.liveLat!, game.liveLon!),
                                width: 78,
                                height: 78,
                                rotate: true,
                                child: _playerDirectionalMarker(
                                  targetBearingDegrees: targetBearingToSearchArea,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(0, 10, 0, 6),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        AudioService.instance.playClickButton();
                        await context.read<HuntGameState>().startGpsTracking();
                        if (!context.mounted) return;
                        if (game.hasLiveLocation) {
                          _mapController.move(
                            LatLng(game.liveLat!, game.liveLon!),
                            18.2,
                          );
                        }
                      },
                      icon: const Icon(Icons.my_location),
                      label: const Text('Volg Mijn Locatie'),
                      style: ElevatedButton.styleFrom(
                        animationDuration: const Duration(milliseconds: 150),
                      ).copyWith(
                        overlayColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.pressed)) {
                            return Colors.white.withValues(alpha: 0.36);
                          }
                          if (states.contains(WidgetState.hovered)) {
                            return Colors.white.withValues(alpha: 0.16);
                          }
                          return null;
                        }),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        AudioService.instance.playClickButton();
                        final gameState = context.read<HuntGameState>();
                        await gameState.ensureSearchPolygonLoaded();
                        final points = gameState.searchPolygonLatLng
                            .map((p) => LatLng(p.lat, p.lon))
                            .toList(growable: false);
                        if (points.length < 3) return;
                        _mapController.fitCamera(
                          CameraFit.bounds(
                            bounds: LatLngBounds.fromPoints(points),
                            padding: const EdgeInsets.all(28),
                          ),
                        );
                      },
                      icon: const Icon(Icons.travel_explore),
                      label: const Text('Zoekgebied'),
                      style: ElevatedButton.styleFrom(
                        animationDuration: const Duration(milliseconds: 150),
                      ).copyWith(
                        overlayColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.pressed)) {
                            return Colors.white.withValues(alpha: 0.36);
                          }
                          if (states.contains(WidgetState.hovered)) {
                            return Colors.white.withValues(alpha: 0.16);
                          }
                          return null;
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (outsideSearchArea)
            Positioned(
              bottom: 122,
              left: 14,
              right: 14,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _warningPulseController,
                  builder: (context, child) {
                    final t = _warningPulseController.value;
                    final scale = 1.0 + (0.03 * t);
                    final alpha = 0.82 - (0.24 * t);
                    return Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: alpha,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC62828),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 1.1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ga naar het zoekgebied!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Pas op bij het oversteken',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 140,
            right: 22,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  AudioService.instance.playClickButton();
                  _mapController.rotate(0);
                },
                child: Ink(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20).withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.2),
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: -_mapRotationDegrees * math.pi / 180.0,
                      child: const Icon(
                        Icons.navigation,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            bottom: 72,
            child: IgnorePointer(
              child: Row(
                children: [
                  Expanded(
                    child: _nearestChip(
                      icon: Icons.pets,
                      iconColor: _distanceToneColor(nearestFaunaMeters),
                      label: nearestFaunaMeters == null
                          ? 'Bosdier: --'
                          : 'Bosdier: ${nearestFaunaMeters} meter',
                      labelColor: _distanceToneColor(nearestFaunaMeters),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _NearestChipStatic(
                      icon: Icons.flag_rounded,
                      label: nearestQuestMeters == null
                          ? 'Quest: --'
                          : 'Quest: ${nearestQuestMeters} meter',
                      color: _distanceToneColor(nearestQuestMeters),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SubtleLogo(),
        ],
      ),
      ),
    );
  }

  bool _isInsideSearchArea(
    double lat,
    double lon,
    List<({double lat, double lon})> polygon,
  ) {
    if (polygon.length < 3) return true;

    var inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].lon;
      final yi = polygon[i].lat;
      final xj = polygon[j].lon;
      final yj = polygon[j].lat;

      final intersects = ((yi > lat) != (yj > lat)) &&
          (lon <
              (xj - xi) * (lat - yi) /
                      ((yj - yi).abs() < 1e-9 ? 1e-9 : (yj - yi)) +
                  xi);
      if (intersects) inside = !inside;
    }
    return inside;
  }

  Color _rarityColor(DierZeldzaamheid rarity) {
    switch (rarity) {
      case DierZeldzaamheid.normaal:
        return const Color(0xFF2E7D32);
      case DierZeldzaamheid.zeldzaam:
        return const Color(0xFF1E88E5);
      case DierZeldzaamheid.legendarisch:
        return const Color(0xFFF57C00);
    }
  }

  String _rarityLabel(DierZeldzaamheid rarity) {
    switch (rarity) {
      case DierZeldzaamheid.normaal:
        return 'Veelvoorkomend';
      case DierZeldzaamheid.zeldzaam:
        return 'Zeldzaam';
      case DierZeldzaamheid.legendarisch:
        return 'Mystiek';
    }
  }

  Widget _pill(String title, String value, {VoidCallback? onTap}) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: onTap == null ? Colors.transparent : Colors.white.withValues(alpha: 0.24),
          highlightColor: onTap == null ? Colors.transparent : Colors.white.withValues(alpha: 0.12),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: onTap == null
                  ? null
                  : Border.all(color: const Color(0xFF4D331D).withValues(alpha: 0.22), width: 1),
            ),
            child: Column(
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int? _nearestFaunaMeters(HuntGameState game) {
    if (!game.hasLiveLocation) return null;
    final lat = game.liveLat!;
    final lon = game.liveLon!;
    double? nearest;
    for (final spawn in game.spawns) {
      if (spawn.gevangen) continue;
      final d = _distanceMeters(lat, lon, spawn.y, spawn.x);
      if (nearest == null || d < nearest) nearest = d;
    }
    if (nearest == null) return null;
    return nearest.round();
  }

  int? _nearestQuestMeters(HuntGameState game) {
    if (!game.hasLiveLocation) return null;
    final lat = game.liveLat!;
    final lon = game.liveLon!;
    double? nearest;
    for (final quest in game.quests) {
      if (quest.opgelost || quest.mislukt) continue;
      final d = _distanceMeters(lat, lon, quest.y, quest.x);
      if (nearest == null || d < nearest) nearest = d;
    }
    if (nearest == null) return null;
    return nearest.round();
  }

  Color _distanceToneColor(int? meters) {
    if (meters == null) return const Color(0xFF4D331D);
    final t = ((meters.clamp(0, 100) as num).toDouble()) / 100.0;
    return Color.lerp(const Color(0xFF2E7D32), const Color(0xFFC62828), t) ??
        const Color(0xFF4D331D);
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

  double? _bearingToSearchAreaCenter(
    double fromLat,
    double fromLon,
    List<({double lat, double lon})> polygon,
  ) {
    if (polygon.isEmpty) return null;
    double sumLat = 0;
    double sumLon = 0;
    for (final p in polygon) {
      sumLat += p.lat;
      sumLon += p.lon;
    }
    final centerLat = sumLat / polygon.length;
    final centerLon = sumLon / polygon.length;
    final phi1 = _toRad(fromLat);
    final phi2 = _toRad(centerLat);
    final dLon = _toRad(centerLon - fromLon);
    final y = math.sin(dLon) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(dLon);
    final bearing = math.atan2(y, x) * 180.0 / math.pi;
    return (bearing + 360.0) % 360.0;
  }

  Widget _nearestChip({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color labelColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8EED8).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD7C29A), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: labelColor,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _playerDirectionalMarker({
    double? targetBearingDegrees,
  }) {
    final hasTargetBearing = targetBearingDegrees != null && targetBearingDegrees >= 0;
    final targetAngleRad =
        hasTargetBearing ? (targetBearingDegrees! * math.pi / 180.0) : 0.0;

    return IgnorePointer(
      child: Center(
        child: SizedBox(
          width: 78,
          height: 78,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (hasTargetBearing)
                Transform.rotate(
                  angle: targetAngleRad,
                  child: CustomPaint(
                    size: const Size(78, 78),
                    painter: const _SearchAreaConePainter(),
                  ),
                ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchAreaConePainter extends CustomPainter {
  const _SearchAreaConePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final path = ui.Path()
      ..moveTo(center.dx, center.dy - 35)
      ..lineTo(center.dx - 11, center.dy - 6)
      ..quadraticBezierTo(center.dx, center.dy - 11, center.dx + 11, center.dy - 6)
      ..close();

    final fill = Paint()
      ..color = const Color(0xFFE53935).withValues(alpha: 0.42)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = const Color(0xFFB71C1C).withValues(alpha: 0.62)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NearestChipStatic extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _NearestChipStatic({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8EED8).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD7C29A), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestQuizScreen extends StatefulWidget {
  final HuntQuest quest;

  const _QuestQuizScreen({required this.quest});

  @override
  State<_QuestQuizScreen> createState() => _QuestQuizScreenState();
}

class _QuestQuizScreenState extends State<_QuestQuizScreen> {
  bool _answered = false;
  int? _selectedIndex;
  bool _showCorrectOverlay = false;

  static const List<_QuizItem> _bank = [
    _QuizItem(
      question: 'Welk dier slaapt in de winter vaak in een hol?',
      options: ['Egel', 'Havik', 'Specht', 'Valk'],
      correctIndex: 0,
    ),
    _QuizItem(
      question: 'Welke boom heeft eikels?',
      options: ['Eik', 'Wilg', 'Populier', 'Den'],
      correctIndex: 0,
    ),
    _QuizItem(
      question: 'Welk dier kan vliegen?',
      options: ['Haas', 'Muis', 'Bosuil', 'Mol'],
      correctIndex: 2,
    ),
    _QuizItem(
      question: 'Waar woont een mol vooral?',
      options: ['Onder de grond', 'In een nest hoog', 'In het water', 'Op een rots'],
      correctIndex: 0,
    ),
    _QuizItem(
      question: 'Welke kleur hebben bladeren meestal in de lente?',
      options: ['Groen', 'Blauw', 'Paars', 'Zwart'],
      correctIndex: 0,
    ),
    _QuizItem(
      question: 'Welk dier heeft stekels?',
      options: ['Egel', 'Ree', 'Haas', 'Das'],
      correctIndex: 0,
    ),
    _QuizItem(
      question: 'Wat hoor je vaak in het bos?',
      options: ['Vogelgeluiden', 'Treinhoorn', 'Scheepshoorn', 'Sirene'],
      correctIndex: 0,
    ),
    _QuizItem(
      question: 'Welke vogel is een nachtjager?',
      options: ['Bosuil', 'Havik', 'Specht', 'Valk'],
      correctIndex: 0,
    ),
    _QuizItem(
      question: 'Welk dier heeft een grote pluimstaart?',
      options: ['Eekhoorn', 'Pad', 'Mol', 'Ringslang'],
      correctIndex: 0,
    ),
    _QuizItem(
      question: 'Wat neem je mee voor een boswandeling?',
      options: ['Stevige schoenen', 'Schaatsen', 'Zwembril', 'Parasol'],
      correctIndex: 0,
    ),
  ];

  int _stopNumber() {
    final m = RegExp(r'(\d+)').firstMatch(widget.quest.id);
    return int.tryParse(m?.group(1) ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final stopNumber = _stopNumber();
    if (stopNumber == 1) {
      return _buildStartScreen(context);
    }
    final idx =
        (((stopNumber - 2).clamp(0, _bank.length - 1) as int) % _bank.length);
    final q = _bank[idx];
    final questImageAsset = 'assets/quests/$stopNumber.jpeg';

    return Scaffold(
      backgroundColor: const Color(0xFFF3E5C8),
      appBar: AppBar(
        title: Text(widget.quest.titel),
        backgroundColor: const Color(0xFFF8EED8),
        foregroundColor: const Color(0xFF4D331D),
      ),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        questImageAsset,
                        fit: BoxFit.cover,
                        height: 180,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      q.question,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF4D331D),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: q.options.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.8,
                      ),
                      itemBuilder: (context, i) {
                    final isSelected = _selectedIndex == i;
                    final isCorrect = i == q.correctIndex;
                    final isGreen = _answered && isSelected && isCorrect;
                    final isWrong = _answered && isSelected && !isCorrect;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _answered
                            ? null
                            : () async {
                                final selectedIsCorrect = i == q.correctIndex;
                                setState(() {
                                  _answered = true;
                                  _selectedIndex = i;
                                  _showCorrectOverlay = selectedIsCorrect;
                                });

                                if (selectedIsCorrect) {
                                  await AudioService.instance.playCorrectAnswer();
                                  final game = context.read<HuntGameState>();
                                  final result = game.losQuestOpViaMapKlik(
                                    questId: widget.quest.id,
                                  );

                                  if (result == QuestSolveResult.outOfOrder) {
                                    final nextStop = game.nextRequiredQuestNumber;
                                    final nextQuestDisplay = nextStop == null
                                        ? null
                                        : (nextStop <= 1 ? 1 : nextStop - 1);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          nextQuestDisplay == null
                                              ? 'Deze quest is nog niet beschikbaar.'
                                              : 'Doe eerst quest $nextQuestDisplay voor je een nieuwe letter krijgt.',
                                        ),
                                      ),
                                    );
                                    await Future<void>.delayed(
                                      const Duration(milliseconds: 1100),
                                    );
                                    if (!context.mounted) return;
                                    Navigator.of(context).pop();
                                    return;
                                  }

                                  if (result != QuestSolveResult.success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Deze stop is al afgerond.'),
                                      ),
                                    );
                                    await Future<void>.delayed(
                                      const Duration(milliseconds: 600),
                                    );
                                    if (!context.mounted) return;
                                    Navigator.of(context).pop();
                                    return;
                                  }

                                  await Future<void>.delayed(
                                    const Duration(seconds: 3),
                                  );
                                  if (!context.mounted) return;
                                  Navigator.of(context).pop();
                                  return;
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Niet goed, probeer een andere stop.'),
                                  ),
                                );
                                await AudioService.instance.playWrongAnswer();
                                context.read<HuntGameState>().markQuestMisluktViaMapKlik(
                                      questId: widget.quest.id,
                                    );
                                await Future<void>.delayed(
                                  const Duration(milliseconds: 900),
                                );
                                if (!context.mounted) return;
                                Navigator.of(context).pop();
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isGreen
                                ? const Color(0xFF2E7D32)
                                : isWrong
                                    ? const Color(0xFFC62828)
                                    : const Color(0xFFF8EED8),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              width: 1.5,
                              color: isGreen
                                  ? const Color(0xFF1B5E20)
                                  : isWrong
                                      ? const Color(0xFF8E0000)
                                      : const Color(0xFFD8C49D),
                            ),
                          ),
                          child: Text(
                            q.options[i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isGreen || isWrong
                                  ? Colors.white
                                  : const Color(0xFF4D331D),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_showCorrectOverlay) ...[
            const _ConfettiBurst(),
            const Positioned(
              top: 34,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Correct!',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: Colors.white,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStartScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E5C8),
      appBar: AppBar(
        title: Text(widget.quest.titel),
        backgroundColor: const Color(0xFFF8EED8),
        foregroundColor: const Color(0xFF4D331D),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8EED8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD8C49D), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Klaar voor de Start?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF4D331D),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Druk op OK om de timer te starten.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6A4A2B),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final game = context.read<HuntGameState>();
                        final started = await game.activateStartStop(
                          questId: widget.quest.id,
                        );
                        if (!context.mounted) return;
                        if (!started) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Ga eerst naar de startlocatie en probeer opnieuw.',
                              ),
                            ),
                          );
                          return;
                        }
                        await AudioService.instance.playClickButton();
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                      },
                      child: const Text('OK'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfettiBurst extends StatelessWidget {
  const _ConfettiBurst();

  static const List<Color> _colors = <Color>[
    Color(0xFFFFD54F),
    Color(0xFF66BB6A),
    Color(0xFF42A5F5),
    Color(0xFFEF5350),
    Color(0xFFAB47BC),
    Color(0xFFFF8A65),
  ];

  @override
  Widget build(BuildContext context) {
    final random = math.Random(42);
    final pieces = List<_ConfettiPiece>.generate(28, (index) {
      return _ConfettiPiece(
        angle: random.nextDouble() * math.pi * 2,
        distance: 80 + random.nextDouble() * 180,
        size: 6 + random.nextDouble() * 7,
        delayFactor: random.nextDouble() * 0.45,
        color: _colors[random.nextInt(_colors.length)],
      );
    });

    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(seconds: 3),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: 1 - value,
            child: Stack(
              children: pieces.map((piece) {
                final t = ((value - piece.delayFactor) / (1 - piece.delayFactor)).clamp(0.0, 1.0);
                final x = math.cos(piece.angle) * piece.distance * t;
                final y = -math.sin(piece.angle) * piece.distance * t + (240 * t);
                return Positioned.fill(
                  child: Align(
                    alignment: const Alignment(0, -0.15),
                    child: Transform.translate(
                      offset: Offset(x, y),
                      child: Transform.rotate(
                        angle: piece.angle + (t * 6.0),
                        child: Container(
                          width: piece.size,
                          height: piece.size * 1.5,
                          decoration: BoxDecoration(
                            color: piece.color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
          );
        },
      ),
    );
  }
}

class _ConfettiPiece {
  final double angle;
  final double distance;
  final double size;
  final double delayFactor;
  final Color color;

  const _ConfettiPiece({
    required this.angle,
    required this.distance,
    required this.size,
    required this.delayFactor,
    required this.color,
  });
}
class _QuizItem {
  final String question;
  final List<String> options;
  final int correctIndex;

  const _QuizItem({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}
