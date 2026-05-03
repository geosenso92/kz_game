import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/hunt_game_state.dart';
import 'home_screen.dart';
import 'theme_login_screen.dart';

class RootRouterScreen extends StatefulWidget {
  const RootRouterScreen({super.key});

  @override
  State<RootRouterScreen> createState() => _RootRouterScreenState();
}

class _RootRouterScreenState extends State<RootRouterScreen> {
  bool _minSplashDone = false;

  @override
  void initState() {
    super.initState();
    print('[RootRouter] initState - startup screen showing for 5 seconds');
    Future<void>.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      print('[RootRouter] 5 seconds elapsed, hiding startup screen');
      setState(() => _minSplashDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HuntGameState>(
      builder: (context, game, _) {
        if (!_minSplashDone || !game.isHydrated) {
          return const _StartupLoadScreen();
        }

        if (!game.hasProfiel) {
          return const ThemeLoginScreen();
        }

        return const HomeScreen();
      },
    );
  }
}

class _StartupLoadScreen extends StatelessWidget {
  const _StartupLoadScreen();

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final asset = isLandscape
        ? 'assets/loadscreen_landscape.png'
        : 'assets/loadscreen_portrait.png';

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: const Color(0xFF0B0F24),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.1,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Laden...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
