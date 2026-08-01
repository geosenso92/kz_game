import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/hunt_game_state.dart';
import 'providers/language_provider.dart';
import 'providers/volume_provider.dart';
import 'services/audio_service.dart';
import 'screens/root_router_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final volumeProvider = VolumeProvider();
  final languageProvider = LanguageProvider();
  await volumeProvider.initialize();
  await languageProvider.initialize();
  runApp(SpeurtochtApp(
    volumeProvider: volumeProvider,
    languageProvider: languageProvider,
  ));
  if (volumeProvider.backgroundEnabled) {
    AudioService.instance.startBackgroundMusic();
  }
}

class SpeurtochtApp extends StatelessWidget {
  final VolumeProvider volumeProvider;
  final LanguageProvider languageProvider;

  const SpeurtochtApp({
    super.key,
    required this.volumeProvider,
    required this.languageProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => HuntGameState()..hydrate(),
        ),
        ChangeNotifierProvider(
          create: (_) => volumeProvider,
        ),
        ChangeNotifierProvider(
          create: (_) => languageProvider,
        ),
      ],
      child: Consumer2<HuntGameState, LanguageProvider>(
        builder: (context, game, language, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: language.t('app_title'),
            theme: game.themeData,
            locale: language.locale,
            home: const RootRouterScreen(),
          );
        },
      ),
    );
  }
}
