import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VolumeProvider extends ChangeNotifier {
  static final VolumeProvider _instance = VolumeProvider._();
  static const String _volumeKey = 'game_master_volume';
  static const String _backgroundEnabledKey = 'game_background_enabled';
  static const double _defaultVolume = 100.0;
  static const bool _defaultBackgroundEnabled = true;

  double _volume = _defaultVolume;
  bool _backgroundEnabled = _defaultBackgroundEnabled;

  VolumeProvider._();

  factory VolumeProvider() {
    return _instance;
  }

  double get volume => _volume;
  bool get backgroundEnabled => _backgroundEnabled;

  /// Sets volume (0-100%)
  Future<void> setVolume(double newVolume) async {
    final clamped = newVolume.clamp(0.0, 100.0);
    if ((clamped - _volume).abs() < 0.1) return; // Avoid micro-changes

    _volume = clamped;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_volumeKey, clamped);
    } catch (_) {
      // Silently fail if preference save doesn't work
    }
  }

  /// Gets volume multiplier (0.0 - 1.0)
  double get volumeMultiplier => _volume / 100.0;

  Future<void> setBackgroundEnabled(bool enabled) async {
    if (_backgroundEnabled == enabled) return;
    _backgroundEnabled = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_backgroundEnabledKey, enabled);
    } catch (_) {
      // Ignore persistence failures.
    }
  }

  /// Initialize from SharedPreferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getDouble(_volumeKey);
      _volume = (stored == null || stored <= 0.0) ? _defaultVolume : stored;
      _backgroundEnabled =
          prefs.getBool(_backgroundEnabledKey) ?? _defaultBackgroundEnabled;
      notifyListeners();
    } catch (_) {
      _volume = _defaultVolume;
      _backgroundEnabled = _defaultBackgroundEnabled;
    }
  }

  /// Mute (set to 0)
  Future<void> mute() => setVolume(0.0);

  /// Unmute (set to 100)
  Future<void> unmute() => setVolume(100.0);
}
