import 'dart:js_interop';

@JS('navigator')
external _Navigator get _navigator;

@JS()
@staticInterop
class _Navigator {}

extension _NavigatorExtension on _Navigator {
  external String get userAgent;
  external JSBoolean vibrate(JSAny pattern);
}

bool get isAndroidBrowser =>
    _navigator.userAgent.toLowerCase().contains('android');

Future<bool> vibrateDuration(int durationMs) async {
  final clamped = durationMs.clamp(1, 10000);
  return _invokeVibrate(clamped.toJS);
}

Future<bool> vibratePattern(List<int> pattern) async {
  if (pattern.isEmpty) return false;
  final jsPattern = pattern.map((value) => value.toJS).toList().toJS;
  return _invokeVibrate(jsPattern);
}

Future<bool> _invokeVibrate(JSAny payload) async {
  try {
    return _navigator.vibrate(payload).toDart;
  } catch (_) {
    return false;
  }
}
