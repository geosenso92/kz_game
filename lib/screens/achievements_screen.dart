import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/hunt_game_state.dart';
import '../widgets/game_top_bar.dart';
import '../widgets/subtle_logo.dart';
import 'navigation_helpers.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<HuntGameState>();
    final items = game.achievements;

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
                currentTab: GameTopTab.achievements,
                onTabSelected: (tab) => openTopTab(context, tab),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: Icon(
                          item.behaald ? Icons.emoji_events : Icons.lock_outline,
                          color: item.behaald ? const Color(0xFFFFB800) : Colors.grey,
                        ),
                        title: Text(item.titel),
                        subtitle: Text(item.beschrijving),
                        trailing: Text(
                          item.behaald ? 'Behaald' : 'Open',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: item.behaald ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SubtleLogo(),
        ],
      ),
      ),
    );
  }
}
