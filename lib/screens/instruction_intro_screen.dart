import 'dart:async';

import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import 'map_screen.dart';

class InstructionIntroScreen extends StatefulWidget {
  const InstructionIntroScreen({super.key});

  @override
  State<InstructionIntroScreen> createState() => _InstructionIntroScreenState();
}

class _InstructionIntroScreenState extends State<InstructionIntroScreen> {
  static const double _narrationSpeed = 1.1;
  static final Duration _firstSlideDuration = _speedAdjusted(const Duration(seconds: 22));
  static final Duration _nextSlideDuration = _speedAdjusted(const Duration(seconds: 10));
  static final Duration _roadsStart = _firstSlideDuration;
  static final Duration _animalsStart = _roadsStart + _nextSlideDuration;
  static final Duration _wordStart = _animalsStart + _nextSlideDuration;
  static final Duration _ticksStart = _wordStart + _nextSlideDuration;
  static const List<String> _slides = <String>[
    'assets/loadscreen_portrait.png',
    'assets/roads.png',
    'assets/animals.png',
    'assets/word.png',
    'assets/ticks.png',
  ];

  Timer? _ticker;
  DateTime? _loopStartedAt;
  int _currentIndex = -1;

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
    setState(() => _currentIndex = 0);
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final started = _loopStartedAt;
      if (started == null) return;
      final elapsed = DateTime.now().difference(started);
      final index = _indexForElapsed(elapsed);
      if (!mounted || index == _currentIndex) return;
      setState(() => _currentIndex = index);
    });
  }

  int _indexForElapsed(Duration elapsed) {
    if (elapsed < _firstSlideDuration) return 0;
    if (elapsed < _animalsStart) return 1;
    if (elapsed < _wordStart) return 2;
    if (elapsed < _ticksStart) return 3;
    return 4;
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

  @override
  Widget build(BuildContext context) {
    final showButtons = _currentIndex == 4;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: _currentIndex < 0
                ? Container(key: const ValueKey<String>('pre_black'), color: Colors.black)
                : Image.asset(
                    _slides[_currentIndex],
                    key: ValueKey<int>(_currentIndex),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        key: ValueKey<int>(_currentIndex),
                        color: Colors.black,
                        child: Center(
                          child: Text(
                            'Asset laden mislukt: ${_slides[_currentIndex]}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
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
                              child: const Text(
                                'Herhaal uitleg',
                                style: TextStyle(fontWeight: FontWeight.w800),
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
                              child: const Text(
                                'Ik heb het begrepen',
                                style: TextStyle(fontWeight: FontWeight.w800),
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
