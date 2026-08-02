import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../services/game_vibration_service.dart';
import 'instruction_intro_screen.dart';

class SuccessIntroScreen extends StatefulWidget {
  final String nickname;

  const SuccessIntroScreen({
    super.key,
    required this.nickname,
  });

  @override
  State<SuccessIntroScreen> createState() => _SuccessIntroScreenState();
}

class _SuccessIntroScreenState extends State<SuccessIntroScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _textOpacity;
  late final Animation<double> _textScale;
  late final AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _textOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 38,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1),
        weight: 24,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 38,
      ),
    ]).animate(_controller);

    _textScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.88, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 38,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.07)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 24,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.07, end: 1.24)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 38,
      ),
    ]).animate(_controller);

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _triggerSuccessVibration();
    _controller.forward();
    Future<void>.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const InstructionIntroScreen()),
      );
    });
  }

  Future<void> _triggerSuccessVibration() async {
    if (!GameVibrationService.isSupportedPlatform) return;
    await GameVibrationService.vibratePattern(
      pattern: const [0, 900, 260, 900],
      intensities: const [0, 220, 0, 220],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final backgroundAsset = isLandscape
        ? 'assets/loadscreen_landscape.png'
        : 'assets/loadscreen_portrait.png';

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            backgroundAsset,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Container(
            color: Colors.black.withValues(alpha: 0.35),
          ),
          Center(
            child: ScaleTransition(
              scale: _textScale,
              child: FadeTransition(
                opacity: _textOpacity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        _sparkle(top: -64, left: -120, size: 24, delay: 0.0),
                        _sparkle(top: -90, right: -18, size: 20, delay: 0.22),
                        _sparkle(bottom: -66, left: -92, size: 18, delay: 0.5),
                        _sparkle(bottom: -82, right: -116, size: 22, delay: 0.74),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 420),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF1B5E20).withValues(alpha: 0.86),
                                const Color(0xFF2E7D32).withValues(alpha: 0.80),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFFFFF7C0).withValues(alpha: 0.95),
                              width: 1.4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.38),
                                blurRadius: 22,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (rect) {
                              return const LinearGradient(
                                colors: [
                                  Color(0xFFFFFFFF),
                                  Color(0xFFFFF176),
                                  Color(0xFFFFFFFF),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ).createShader(rect);
                            },
                            child: Text(
                              _successLabel(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(
                                    blurRadius: 14,
                                    color: Colors.black87,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _successLabel() {
    final name = widget.nickname.trim();
    final language = context.read<LanguageProvider>();
    return language.t('success_label', values: {'name': name});
  }

  Widget _sparkle({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
    required double delay,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: AnimatedBuilder(
        animation: _sparkleController,
        builder: (context, child) {
          final t = (_sparkleController.value + delay) % 1.0;
          final opacity = 0.35 + (0.65 * (t < 0.5 ? t * 2 : (1 - t) * 2));
          final scale = 0.84 + (0.34 * (t < 0.5 ? t * 2 : (1 - t) * 2));
          return Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          );
        },
        child: Icon(
          Icons.auto_awesome,
          color: const Color(0xFFFFF3B2),
          size: size,
        ),
      ),
    );
  }
}
