import 'dart:io';

import 'package:flutter/material.dart';

import 'instruction_intro_screen.dart';

class SuccessIntroScreen extends StatefulWidget {
  final String nickname;
  final String? imagePath;

  const SuccessIntroScreen({
    super.key,
    required this.nickname,
    this.imagePath,
  });

  @override
  State<SuccessIntroScreen> createState() => _SuccessIntroScreenState();
}

class _SuccessIntroScreenState extends State<SuccessIntroScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _textOpacity;
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

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _controller.forward();
    Future<void>.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const InstructionIntroScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photoPath = widget.imagePath?.trim();
    final hasPhoto = photoPath != null && photoPath.isNotEmpty;
    final resolvedPhotoPath = hasPhoto ? photoPath! : null;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (hasPhoto)
            Image.file(
              File(resolvedPhotoPath!),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/Tinkerbell2.png',
                fit: BoxFit.cover,
              ),
            )
          else
            Image.asset(
              'assets/Tinkerbell2.png',
              fit: BoxFit.cover,
            ),
          Container(
            color: Colors.black.withValues(alpha: hasPhoto ? 0.24 : 0.35),
          ),
          Center(
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
                      Text(
                        _successLabel(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              blurRadius: 12,
                              color: Colors.black87,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _successLabel() {
    final name = widget.nickname.trim();
    final lower = name.toLowerCase();
    final isTeam = lower.startsWith('team ') ||
        lower.startsWith('groep ') ||
        lower.startsWith('klas ') ||
        lower.startsWith('familie ');
    return isTeam ? 'Succes $name!' : 'Succes, $name!';
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
