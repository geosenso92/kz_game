import 'package:flutter/material.dart';

class SubtleLogo extends StatelessWidget {
  final Alignment alignment;
  final double opacity;
  final double width;
  final EdgeInsets margin;

  const SubtleLogo({
    super.key,
    this.alignment = Alignment.topRight,
    this.opacity = 0.12,
    this.width = 74,
    this.margin = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Container(
          margin: margin,
          child: Opacity(
            opacity: opacity,
            child: Image.asset(
              'assets/logo.png',
              width: width,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
