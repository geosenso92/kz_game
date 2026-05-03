import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/hunt_game_state.dart';
import '../screens/navigation_helpers.dart';

class GameTopBar extends StatelessWidget {
  final GameTopTab currentTab;
  final ValueChanged<GameTopTab> onTabSelected;

  const GameTopBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final game = context.watch<HuntGameState>();
    if (game.shouldAutoOpenFinalWord && currentTab != GameTopTab.finalWord) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.read<HuntGameState>().markFinalWordAutoOpened();
        onTabSelected(GameTopTab.finalWord);
      });
    }
    if (currentTab == GameTopTab.collection && game.hasNewFaunaUnlock) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.read<HuntGameState>().clearFaunaUnlockBadge();
      });
    }
    if (currentTab == GameTopTab.finalWord && game.hasNewFinalWordUnlock) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.read<HuntGameState>().clearFinalWordUnlockBadge();
      });
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFF8EED8).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD7C29A), width: 1.0),
      ),
      child: Row(
        children: [
          _item(icon: Icons.home, tab: GameTopTab.home),
          const SizedBox(width: 8),
          _item(icon: Icons.public, tab: GameTopTab.map),
          const SizedBox(width: 8),
          _item(
            icon: Icons.pets,
            tab: GameTopTab.collection,
            showBadge: game.hasNewFaunaUnlock,
          ),
          const SizedBox(width: 8),
          _item(
            icon: Icons.emoji_events,
            tab: GameTopTab.finalWord,
            showBadge: game.hasNewFinalWordUnlock,
          ),
          const Spacer(),
          _timerPill(game),
        ],
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required GameTopTab tab,
    bool showBadge = false,
  }) {
    final selected = currentTab == tab;
    return IconButton(
      onPressed: () {
        onTabSelected(tab);
      },
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            icon,
            color: selected ? const Color(0xFF4D331D) : const Color(0xFF8D6A4A),
            size: 28,
          ),
          if (showBadge)
            const Positioned(
              right: -2,
              top: -3,
              child: _TopBarBadge(),
            ),
        ],
      ),
    );
  }

  Widget _timerPill(HuntGameState game) {
    final color = game.remainingSeconds <= 600
        ? const Color(0xFFC62828)
        : game.remainingSeconds <= 1800
            ? const Color(0xFFEF6C00)
            : const Color(0xFF0B5D1E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white70, width: 0.8),
      ),
      child: Text(
        game.remainingTimeLabel,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _TopBarBadge extends StatelessWidget {
  const _TopBarBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFC62828),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: const Text(
        '!',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

