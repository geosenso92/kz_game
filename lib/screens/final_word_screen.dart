import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/hunt_game_state.dart';
import '../services/audio_service.dart';
import '../widgets/game_top_bar.dart';
import '../widgets/subtle_logo.dart';
import '../widgets/tinkerbell_framed_photo.dart';
import 'navigation_helpers.dart';

class FinalWordScreen extends StatefulWidget {
  const FinalWordScreen({super.key});

  @override
  State<FinalWordScreen> createState() => _FinalWordScreenState();
}

class _FinalWordScreenState extends State<FinalWordScreen> {
  static const int _slotCount = 10;
  final List<String> _manualSlots = List<String>.filled(_slotCount, '');
  int _attempts = 0;
  bool _showingSuccessDialog = false;

  Future<void> _pickLetter(BuildContext context, int index) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFF8EED8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        final alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...alphabet.map(
                  (letter) => InkWell(
                    onTap: () {
                      setState(() => _manualSlots[index] = letter);
                      Navigator.of(context).pop();
                    },
                    child: CircleAvatar(
                      radius: 19,
                      backgroundColor: const Color(0xFF2A63BF),
                      child: Text(
                        letter,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() => _manualSlots[index] = '');
                    Navigator.of(context).pop();
                  },
                  child: const CircleAvatar(
                    radius: 19,
                    backgroundColor: Color(0xFFC62828),
                    child: Icon(Icons.backspace, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<HuntGameState>();
    final autoSlots = game.finalWordSlots;
    final failedSlots = game.finalWordFailedSlots;
    final profilePhoto = game.profiel?.photoPath;

    final slots = List<String>.generate(_slotCount, (i) {
      final auto = (i < autoSlots.length ? autoSlots[i] : null) ?? '';
      if (auto.isNotEmpty) return auto;
      return _manualSlots[i];
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF3E5C8),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(color: const Color(0xFFF3E5C8)),
            ),
            Positioned(
              top: 84,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: 0.94,
                child: Center(
                  child: TinkerbellFramedPhoto(
                    photoPath: profilePhoto,
                    width: 235,
                    showFrame: false,
                  ),
                ),
              ),
            ),
            Column(
              children: [
                GameTopBar(
                  currentTab: GameTopTab.finalWord,
                  onTabSelected: (tab) => openTopTab(context, tab),
                ),
                Expanded(
                  child: Align(
                    alignment: const Alignment(0, 0.56),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8EED8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD7C29A), width: 1.2),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Raad het woord!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF4D331D),
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: List.generate(_slotCount, (index) {
                              final val = slots[index];
                              final isLockedAuto =
                                  (index < autoSlots.length && (autoSlots[index] ?? '').isNotEmpty);
                              final isFailedSlot =
                                  index < failedSlots.length && failedSlots[index] && val.isEmpty;
                              return InkWell(
                                onTap: isLockedAuto ? null : () => _pickLetter(context, index),
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: val.isNotEmpty
                                        ? (isLockedAuto
                                            ? const Color(0xFF2E7D32)
                                            : const Color(0xFF2A63BF))
                                        : isFailedSlot
                                            ? const Color(0xFFC62828)
                                        : const Color(0xFFFFF4DC),
                                    border: Border.all(color: Colors.white, width: 1.1),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    val.isNotEmpty ? val : '•',
                                    style: TextStyle(
                                      fontSize: val.isNotEmpty ? 21 : 20,
                                      color: val.isNotEmpty
                                          ? Colors.white
                                          : isFailedSlot
                                              ? Colors.white
                                          : const Color(0xFF7A5A3A),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton(
                            onPressed: _attempts >= 3 && !game.finalWordSolved
                                ? null
                                : () async {
                                    final candidate = slots.join();
                                    final ok = context.read<HuntGameState>().checkFinalWord(candidate);
                                    if (ok) {
                                      if (_showingSuccessDialog) return;
                                      _showingSuccessDialog = true;
                                      try {
                                        await AudioService.instance.playCongrats();
                                        if (!context.mounted) return;
                                        await showDialog<void>(
                                          context: context,
                                          barrierDismissible: true,
                                          builder: (_) => const _FinalWordSuccessDialog(),
                                        );
                                      } finally {
                                        _showingSuccessDialog = false;
                                      }
                                      return;
                                    }
                                    setState(() => _attempts += 1);
                                    final left = (3 - _attempts).clamp(0, 3);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Niet goed. Pogingen over: $left',
                                        ),
                                      ),
                                    );
                                  },
                            child: const Text('Check woord (max. 3 pogingen)'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SubtleLogo(opacity: 0.08),
          ],
        ),
      ),
    );
  }
}

class _FinalWordSuccessDialog extends StatefulWidget {
  const _FinalWordSuccessDialog();

  @override
  State<_FinalWordSuccessDialog> createState() => _FinalWordSuccessDialogState();
}

class _FinalWordSuccessDialogState extends State<_FinalWordSuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    Future<void>.delayed(const Duration(seconds: 20), () {
      if (!mounted) return;
      Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8EED8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD54F), width: 2.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Gefeliciteerd!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Het goede woord geraden!\nLaat het resultaat zien en haal je verrassing op bij Klein Zwitserland!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF4D331D),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Deze melding sluit automatisch na 20 seconden.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B4B2A),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _LoopConfettiPainter(_confettiController.value),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoopConfettiPainter extends CustomPainter {
  final double progress;

  _LoopConfettiPainter(this.progress);

  static const List<Color> _colors = <Color>[
    Color(0xFFFFD54F),
    Color(0xFF66BB6A),
    Color(0xFF42A5F5),
    Color(0xFFEF5350),
    Color(0xFFFF8A65),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const pieces = 52;
    for (var i = 0; i < pieces; i++) {
      final lane = (i * 31) % 1000 / 1000.0;
      final local = (progress + (i * 0.017)) % 1.0;
      final x = lane * size.width;
      final y = local * size.height;
      final paint = Paint()..color = _colors[i % _colors.length].withValues(alpha: 0.9);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((i % 7) * 0.26 + local * 3.14);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-3.5, -6.5, 7, 13),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LoopConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

