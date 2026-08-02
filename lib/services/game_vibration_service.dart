import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import 'web_vibration.dart' as web_vibration;

class GameVibrationService {
  static bool get _isAndroidDevice =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get _isAndroidWeb => kIsWeb && web_vibration.isAndroidBrowser;

  static bool get isSupportedPlatform => _isAndroidDevice || _isAndroidWeb;

  static Future<void> vibrateDuration(
    int durationMs, {
    int amplitude = 210,
  }) async {
    if (!isSupportedPlatform) return;

    if (kIsWeb) {
      final didVibrate = await web_vibration.vibrateDuration(durationMs);
      if (!didVibrate) {
        await HapticFeedback.mediumImpact();
      }
      return;
    }

    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (!hasVibrator) {
        await HapticFeedback.mediumImpact();
        return;
      }
      await Vibration.vibrate(duration: durationMs, amplitude: amplitude);
    } catch (_) {
      await HapticFeedback.mediumImpact();
    }
  }

  static Future<void> vibratePattern({
    required List<int> pattern,
    required List<int> intensities,
  }) async {
    if (!isSupportedPlatform) return;

    if (kIsWeb) {
      final didVibrate = await web_vibration.vibratePattern(pattern);
      if (!didVibrate) {
        await HapticFeedback.mediumImpact();
      }
      return;
    }

    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (!hasVibrator) {
        await HapticFeedback.mediumImpact();
        return;
      }
      await Vibration.vibrate(pattern: pattern, intensities: intensities);
    } catch (_) {
      await HapticFeedback.mediumImpact();
    }
  }
}
