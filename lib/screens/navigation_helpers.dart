import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'achievements_screen.dart';
import 'collection_screen.dart';
import 'final_word_screen.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'vegetation_collection_screen.dart';
import '../providers/hunt_game_state.dart';

void openTopTab(BuildContext context, GameTopTab tab) {
  final game = context.read<HuntGameState>();
  if ((tab == GameTopTab.map || tab == GameTopTab.home) && game.isMapLocked) {
    tab = GameTopTab.finalWord;
  }

  Widget page;
  switch (tab) {
    case GameTopTab.home:
      page = const HomeScreen();
      break;
    case GameTopTab.map:
      page = const MapScreen();
      break;
    case GameTopTab.collection:
      page = const CollectionScreen();
      break;
    case GameTopTab.vegetation:
      page = const VegetationCollectionScreen();
      break;
    case GameTopTab.achievements:
      page = const AchievementsScreen();
      break;
    case GameTopTab.finalWord:
      page = const FinalWordScreen();
      break;
  }

  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => page),
  );
}

enum GameTopTab { home, map, collection, vegetation, achievements, finalWord }
