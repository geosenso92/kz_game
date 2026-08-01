import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../services/audio_service.dart';
import 'map_screen.dart';

class InstructionIntroScreen extends StatefulWidget {
  const InstructionIntroScreen({super.key});

  @override
  State<InstructionIntroScreen> createState() => _InstructionIntroScreenState();
}

class _InstructionIntroScreenState extends State<InstructionIntroScreen> {
  static const double _narrationSpeed = 1.0;
  static const Duration _firstSlideDuration = Duration(seconds: 3);
  static final Duration _rulesDuration = _speedAdjusted(const Duration(seconds: 22));
  static final Duration _tipsDuration = _speedAdjusted(const Duration(seconds: 22));
  static final Duration _rulesStart = _firstSlideDuration;
  static final Duration _tipsStart = _rulesStart + _rulesDuration;
  static final Duration _buttonsStart = _tipsStart + _tipsDuration;
  List<String> _slidesForLanguage(LanguageProvider language) {
    return language.isEnglish
        ? const <String>[
            'assets/loadscreen_portrait.png',
            'assets/spelregels_EN.png',
            'assets/tips_EN.png',
          ]
        : const <String>[
            'assets/loadscreen_portrait.png',
            'assets/spelregels.png',
            'assets/tips.png',
          ];
  }

  Timer? _ticker;
  DateTime? _loopStartedAt;
  int _currentIndex = -1;
  bool _buttonsUnlocked = false;
  bool _skipRequested = false;
  int _manualInfoSlideIndex = 1;

  static Duration _speedAdjusted(Duration original) {
    return Duration(
      milliseconds: (original.inMilliseconds / _narrationSpeed).round(),
    );
  }

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (mounted) {
        _startExplanationLoop();
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    AudioService.instance.stopInstructionNarration();
    AudioService.instance.unduckBackgroundAfterInstruction();
    super.dispose();
  }

  Future<void> _startExplanationLoop() async {
    _ticker?.cancel();
    try {
      await AudioService.instance.startInstructionNarration(restart: true);
    } catch (e) {
      print('Error starting instruction narration: $e');
    }
    _loopStartedAt = DateTime.now();
    if (!mounted) return;
    setState(() {
      _currentIndex = 0;
      _buttonsUnlocked = false;
      _skipRequested = false;
      _manualInfoSlideIndex = 1;
    });
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final started = _loopStartedAt;
      if (started == null) return;
      final elapsed = DateTime.now().difference(started);
      final index = _indexForElapsed(elapsed);
      final shouldUnlockButtons = index == 2 && elapsed >= _buttonsStart;
      if (!mounted) return;
      setState(() {
        _currentIndex = index;
        if (shouldUnlockButtons) {
          _buttonsUnlocked = true;
          _manualInfoSlideIndex = 2;
        }
      });
    });
  }

  int _indexForElapsed(Duration elapsed) {
    if (elapsed < _firstSlideDuration) return 0;
    if (elapsed < _tipsStart) return 1;
    return 2;
  }

  Future<void> _continueToMap() async {
    try {
      await AudioService.instance.stopInstructionNarration();
      await AudioService.instance.unduckBackgroundAfterInstruction();
    } catch (e) {
      print('Error stopping instruction narration: $e');
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MapScreen()),
    );
  }

  void _skipInstruction() {
    AudioService.instance.stopInstructionNarration();
    _ticker?.cancel();
    setState(() {
      _skipRequested = true;
      _buttonsUnlocked = true;
      _currentIndex = 2;
      _manualInfoSlideIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
    final slides = _slidesForLanguage(language);
    final showButtons = _buttonsUnlocked;
    final showSkip = !_skipRequested && !_buttonsUnlocked;
    final shownIndex = _buttonsUnlocked ? _manualInfoSlideIndex : _currentIndex;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: shownIndex < 0
                ? Container(key: const ValueKey<String>('pre_black'), color: Colors.black)
                : Image.asset(
                    slides[shownIndex],
                    key: ValueKey<int>(shownIndex),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        key: ValueKey<int>(shownIndex),
                        color: Colors.black,
                        child: Center(
                          child: Text(
                            language.t('instruction_asset_error', values: {'asset': slides[shownIndex]}),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_buttonsUnlocked)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragEnd: (details) {
                  final v = details.primaryVelocity ?? 0;
                  if (v.abs() < 60) return;
                  setState(() {
                    if (v < 0) {
                      _manualInfoSlideIndex = 2;
                    } else {
                      _manualInfoSlideIndex = 1;
                    }
                  });
                },
              ),
            ),
          Container(color: Colors.black.withValues(alpha: 0.18)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: Column(
                children: [
                  const Spacer(),
                  if (showSkip)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _skipInstruction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6D4C41),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          language.t('instruction_skip'),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  if (showSkip) const SizedBox(height: 10),
                  AnimatedOpacity(
                    opacity: showButtons ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: IgnorePointer(
                      ignoring: !showButtons,
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _startExplanationLoop,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1565C0),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                language.t('instruction_repeat'),
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _continueToMap,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                language.t('instruction_start'),
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
