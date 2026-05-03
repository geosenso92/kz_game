import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  static const double _backgroundVolume = 0.18;
  static const double _instructionBackgroundDuckedVolume = 0.015;
  static const String _collectObjectAsset = 'audio/collectobject.mp3';
  static const String _correctAnswerAsset = 'audio/correct.mp3';
  static const String _wrongAnswerAsset = 'audio/wrong.mp3';
  static const String _clickButtonAsset = 'audio/clickbutton.mp3';
  static const String _timerWarningAsset = 'audio/timer.mp3';
  static const String _congratsAsset = 'audio/congrats.mp3';
  static const String _instructionAsset = 'audio/instruction.mp3';
  static const double _instructionPlaybackRate = 1.1;
  static const Map<String, String> _animalCueByName = <String, String>{
    'edelhert': 'audio/deer.mp3',
    'wolf': 'audio/wolf.mp3',
    'adder': 'audio/snake.mp3',
    'ratelslang': 'audio/snake.mp3',
    'oehoe': 'audio/owl.mp3',
  };

  final AudioPlayer _backgroundPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _animalCuePlayer = AudioPlayer();
  final AudioPlayer _timerWarningPlayer = AudioPlayer();
  final AudioPlayer _instructionPlayer = AudioPlayer();
  bool _backgroundStarted = false;
  bool _audioContextConfigured = false;
  bool _timerWarningActive = false;
  bool _isFadingIn = false;
  bool _isBackgroundDuckedForInstruction = false;
  Duration? _backgroundDuration;
  double _lastAppliedBackgroundVolume = -1;

  Future<void> startBackgroundMusic() async {
    if (_backgroundStarted) return;
    _backgroundStarted = true;

    await _ensurePlayersCanMixAudio();
    await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
    await _backgroundPlayer.setVolume(0.0);
    _wireBackgroundFadeLoop();
    await _backgroundPlayer.play(AssetSource('audio/background.mp3'));
    _fadeInBackgroundMusic();
  }

  Future<void> _ensurePlayersCanMixAudio() async {
    if (_audioContextConfigured) return;
    final context = AudioContextConfig(
      focus: AudioContextConfigFocus.mixWithOthers,
    ).build();
    await _backgroundPlayer.setAudioContext(context);
    await _sfxPlayer.setAudioContext(context);
    await _animalCuePlayer.setAudioContext(context);
    await _timerWarningPlayer.setAudioContext(context);
    await _instructionPlayer.setAudioContext(context);
    await _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
    await _animalCuePlayer.setPlayerMode(PlayerMode.lowLatency);
    await _timerWarningPlayer.setReleaseMode(ReleaseMode.loop);
    await _timerWarningPlayer.setPlayerMode(PlayerMode.lowLatency);
    await _instructionPlayer.setReleaseMode(ReleaseMode.stop);
    _audioContextConfigured = true;
  }

  void _wireBackgroundFadeLoop() {
    _backgroundPlayer.onDurationChanged.listen((duration) {
      _backgroundDuration = duration;
    });

    _backgroundPlayer.onPositionChanged.listen((position) {
      _applyLoopEdgeFade(position);
    });
  }

  Future<void> _fadeInBackgroundMusic() async {
    if (_isFadingIn) return;
    _isFadingIn = true;
    const steps = 12;
    const stepDuration = Duration(milliseconds: 140);
    for (var i = 1; i <= steps; i++) {
      final v = (_backgroundVolume * i) / steps;
      await _backgroundPlayer.setVolume(v);
      await Future<void>.delayed(stepDuration);
    }
    await _backgroundPlayer.setVolume(_backgroundVolume);
    _isFadingIn = false;
  }

  void _applyLoopEdgeFade(Duration position) {
    if (_isFadingIn) return;
    if (_isBackgroundDuckedForInstruction) {
      final ducked = _instructionBackgroundDuckedVolume;
      if ((ducked - _lastAppliedBackgroundVolume).abs() < 0.015) return;
      _lastAppliedBackgroundVolume = ducked;
      _backgroundPlayer.setVolume(ducked);
      return;
    }
    final duration = _backgroundDuration;
    if (duration == null || duration <= Duration.zero) return;

    const fadeWindowSeconds = 3.0;
    final pos = position.inMilliseconds / 1000.0;
    final total = duration.inMilliseconds / 1000.0;
    final remaining = total - pos;

    double factor = 1.0;
    if (pos < fadeWindowSeconds) {
      factor = (pos / fadeWindowSeconds).clamp(0.0, 1.0);
    } else if (remaining < fadeWindowSeconds) {
      factor = (remaining / fadeWindowSeconds).clamp(0.0, 1.0);
    }

    final target = _backgroundVolume * factor;
    if ((target - _lastAppliedBackgroundVolume).abs() < 0.015) return;
    _lastAppliedBackgroundVolume = target;
    _backgroundPlayer.setVolume(target);
  }

  Future<void> playAnimalCueByName(String animalName) async {
    final key = animalName.trim().toLowerCase();
    final asset = _animalCueByName[key];
    if (asset == null || asset.isEmpty) return;

    await _playAnimalCue(asset);
  }

  Future<void> playCollectObject() async {
    await _playSfx(_collectObjectAsset);
  }

  Future<void> playCorrectAnswer() async {
    await _playSfx(_correctAnswerAsset);
  }

  Future<void> playWrongAnswer() async {
    await _playSfx(_wrongAnswerAsset);
  }

  Future<void> playClickButton() async {
    await _playSfx(_clickButtonAsset);
  }

  Future<void> playCongrats() async {
    await _playSfx(_congratsAsset);
  }

  Future<void> startInstructionNarration({bool restart = false}) async {
    await _ensurePlayersCanMixAudio();
    await duckBackgroundForInstruction();
    await _instructionPlayer.setPlaybackRate(_instructionPlaybackRate);
    if (restart) {
      await _instructionPlayer.stop();
      await _instructionPlayer.play(AssetSource(_instructionAsset));
      return;
    }
    final state = _instructionPlayer.state;
    if (state == PlayerState.playing) return;
    await _instructionPlayer.play(AssetSource(_instructionAsset));
  }

  Future<void> stopInstructionNarration() async {
    await _instructionPlayer.stop();
  }

  Future<void> duckBackgroundForInstruction() async {
    await _ensurePlayersCanMixAudio();
    _isBackgroundDuckedForInstruction = true;
    _lastAppliedBackgroundVolume = -1;
    await _backgroundPlayer.setVolume(_instructionBackgroundDuckedVolume);
  }

  Future<void> unduckBackgroundAfterInstruction() async {
    _isBackgroundDuckedForInstruction = false;
    _lastAppliedBackgroundVolume = -1;
    await _backgroundPlayer.setVolume(_backgroundVolume);
  }

  Future<void> startTimerWarningLoop() async {
    if (_timerWarningActive) return;
    await _ensurePlayersCanMixAudio();
    _timerWarningActive = true;
    await _timerWarningPlayer.stop();
    await _timerWarningPlayer.setVolume(1.0);
    await _timerWarningPlayer.play(AssetSource(_timerWarningAsset));
  }

  Future<void> stopTimerWarningLoop() async {
    if (!_timerWarningActive) return;
    _timerWarningActive = false;
    await _timerWarningPlayer.stop();
  }

  Future<void> _playSfx(String asset) async {
    await _ensurePlayersCanMixAudio();
    await _sfxPlayer.stop();
    await _sfxPlayer.setVolume(1.0);
    await _sfxPlayer.play(AssetSource(asset));
  }

  Future<void> _playAnimalCue(String asset) async {
    await _ensurePlayersCanMixAudio();
    await _animalCuePlayer.stop();
    await _animalCuePlayer.setVolume(1.0);
    await _animalCuePlayer.play(AssetSource(asset));
  }
}
