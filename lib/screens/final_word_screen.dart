import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/hunt_game_state.dart';
import '../providers/language_provider.dart';
import '../services/audio_service.dart';
import '../widgets/game_top_bar.dart';
import '../widgets/subtle_logo.dart';
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

  Widget _unlockedLetterBadge(String letter) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFA5D6A7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E7D32), width: 1.2),
      ),
      child: Text(
        letter.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF1B5E20),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _failedLetterBadge() {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFC62828),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF8E0000), width: 1.2),
      ),
      child: const Icon(
        Icons.close,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape) {
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
                    currentTab: GameTopTab.finalWord,
                    onTabSelected: (tab) => openTopTab(context, tab),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/rotate.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              language.t('rotate_screen'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF4D331D),
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
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

    final game = context.watch<HuntGameState>();
    final failedQuestCount = game.failedQuestCount;
    final unlockedLetters = game.unlockedLetters;
    final slots = List<String>.from(_manualSlots);

    return Scaffold(
      backgroundColor: const Color(0xFFF3E5C8),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: const Color(0xFFF3E5C8))),
            Positioned(
              top: 92,
              left: 16,
              right: 16,
              child: Opacity(
                opacity: 0.94,
                child: _logoPanel(),
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
                    alignment: const Alignment(0, 0.70),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8EED8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFD7C29A),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            language.t('guess_word'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF4D331D),
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (unlockedLetters.isNotEmpty ||
                              failedQuestCount > 0) ...[
                            Text(
                              language.t('unlocked_letters'),
                              style: const TextStyle(
                                color: Color(0xFF6A4A2B),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                ...unlockedLetters.map(
                                  _unlockedLetterBadge,
                                ),
                                ...List.generate(
                                  failedQuestCount,
                                  (_) => _failedLetterBadge(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: List.generate(_slotCount, (index) {
                              final val = slots[index];
                              // Always render empty slots as circles with a dot placeholder;
                              // failed guesses are shown separately next to unlocked letters.
                              return InkWell(
                                onTap: () => _pickLetter(context, index),
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: val.isNotEmpty
                                        ? const Color(0xFF2A63BF)
                                        : const Color(0xFFFFF4DC),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.1,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    val.isNotEmpty ? val : '•',
                                    style: TextStyle(
                                      fontSize: val.isNotEmpty ? 21 : 20,
                                      color: val.isNotEmpty
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
                                    final ok = context
                                        .read<HuntGameState>()
                                        .checkFinalWord(candidate);
                                    if (ok) {
                                      if (_showingSuccessDialog) return;
                                      _showingSuccessDialog = true;
                                      try {
                                        await AudioService.instance
                                            .playCongrats();
                                        if (!context.mounted) return;
                                        await showDialog<void>(
                                          context: context,
                                          barrierDismissible: true,
                                          builder: (_) =>
                                              _FinalWordSuccessDialog(),
                                        );
                                        if (!context.mounted) return;
                                        await showDialog<void>(
                                          context: context,
                                          barrierDismissible: true,
                                          builder: (_) =>
                                              const _MyStatsDialog(),
                                        );
                                        if (!context.mounted) return;
                                        openTopTab(context, GameTopTab.map);
                                      } finally {
                                        _showingSuccessDialog = false;
                                      }
                                      return;
                                    }
                                    setState(() {
                                      _attempts += 1;
                                    });
                                    final left = (3 - _attempts).clamp(0, 3);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          language.t('wrong_attempts', values: {'left': '$left'}),
                                        ),
                                      ),
                                    );
                                  },
                            child: Text(language.t('check_word')),
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

  Widget _logoPanel() {
    return Container(
      width: double.infinity,
      height: 264,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1B5E20), width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        color: const Color(0xFFF7EEDC),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Image.asset(
            'assets/logo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _FinalWordSuccessDialog extends StatefulWidget {
  const _FinalWordSuccessDialog();

  @override
  State<_FinalWordSuccessDialog> createState() =>
      _FinalWordSuccessDialogState();
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
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
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
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD54F), width: 2.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  language.t('congrats'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  language.t('word_found'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF4D331D),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  language.t('quest_finished'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF6A4A2B),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(language.t('view_stats')),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFC62828),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
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

class _MyStatsDialog extends StatelessWidget {
  const _MyStatsDialog();

  @override
  Widget build(BuildContext context) {
    final game = context.watch<HuntGameState>();
    final language = context.watch<LanguageProvider>();
    final distanceLabel = _distanceLabel(game.distanceTravelledMeters);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
            decoration: BoxDecoration(
              color: const Color(0xFFF8EED8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2E7D32), width: 2.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  language.t('stats_title'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                _summaryRow(language.t('walking_distance'), distanceLabel),
                const SizedBox(height: 9),
                _summaryRow(language.t('total_duration'), game.elapsedTimeLabel),
                const SizedBox(height: 9),
                _summaryRow(language.t('bosdieren_found'), '${game.gevangenAantal}'),
                const SizedBox(height: 9),
                _summaryRow(language.t('tasks_correct'), '${game.solvedQuestCount}'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(language.t('ok')),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFC62828),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _distanceLabel(double distance) {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
    return '${distance.round()} meter';
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4D331D),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
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
      final paint = Paint()
        ..color = _colors[i % _colors.length].withValues(alpha: 0.9);
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
