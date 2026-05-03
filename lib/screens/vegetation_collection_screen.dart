import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/hunt_game_state.dart';
import '../widgets/game_top_bar.dart';
import '../widgets/subtle_logo.dart';
import 'navigation_helpers.dart';

class VegetationCollectionScreen extends StatelessWidget {
  const VegetationCollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<HuntGameState>();
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(color: const Color(0xFFF3E5C8)),
            ),
            Column(
              children: [
                GameTopBar(
                  currentTab: GameTopTab.vegetation,
                  onTabSelected: (tab) => openTopTab(context, tab),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Flora',
                  style: TextStyle(
                    color: Color(0xFF4D331D),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ontdekt: ${game.collectedFloraCount.clamp(0, HuntGameState.floraTotalCount)}/${HuntGameState.floraTotalCount}',
                  style: const TextStyle(
                    color: Color(0xFF6B4B2A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F0DF).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD7C29A), width: 1.2),
                      ),
                      child: const Text(
                        'Nog geen florakaarten beschikbaar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF6B4B2A),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SubtleLogo(opacity: 0.09, width: 74),
          ],
        ),
      ),
    );
  }
}
