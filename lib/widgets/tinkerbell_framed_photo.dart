import 'dart:io';

import 'package:flutter/material.dart';

class TinkerbellFramedPhoto extends StatelessWidget {
  final String? photoPath;
  final double width;
  final double? height;
  final EdgeInsetsGeometry? contentInsets;
  final bool showFrame;

  const TinkerbellFramedPhoto({
    super.key,
    required this.photoPath,
    this.width = 250,
    this.height,
    this.contentInsets,
    this.showFrame = true,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedHeight = height ?? (width * 1.1);
    final hasPhoto = photoPath != null && photoPath!.trim().isNotEmpty;

    return SizedBox(
      width: width,
      height: resolvedHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          // Conservative safe area so photo always stays inside the new frame.
          final inset = contentInsets ??
              EdgeInsets.fromLTRB(
                w * 0.16,
                h * 0.21,
                w * 0.26,
                h * 0.22,
              );

          return Stack(
            fit: StackFit.expand,
            children: [
              if (hasPhoto)
                Positioned.fill(
                  child: Padding(
                    padding: inset,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(
                        File(photoPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _photoFallback(),
                      ),
                    ),
                  ),
                )
              else
                Positioned.fill(
                  child: Padding(
                    padding: inset,
                    child: _photoFallback(),
                  ),
                ),
              if (showFrame)
                Image.asset(
                  'assets/Tinkerbell_frame.png',
                  fit: BoxFit.contain,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _photoFallback() {
    return Container(
      color: const Color(0xFF2F2A24),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person,
        color: Colors.white70,
        size: 44,
      ),
    );
  }
}
