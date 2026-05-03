import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/hunt_game_state.dart';
import '../services/audio_service.dart';
import '../widgets/game_top_bar.dart';
import '../widgets/subtle_logo.dart';
import 'navigation_helpers.dart';
import 'speluitleg_screen.dart';
import 'theme_login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _shareViaWhatsApp(BuildContext context) async {
    const message = 'Doe mee met onze KZ Speurtocht!';
    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(message)}',
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp kon niet worden geopend.')),
      );
    }
  }

  Future<void> _shareViaEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      queryParameters: {
        'subject': 'Uitnodiging voor KZ Speurtocht',
        'body': 'Doe mee met onze speurtocht!'
      },
    );
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mailapp kon niet worden geopend.')),
      );
    }
  }

  void _openShareSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFF7E8C8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Deel speurtocht via',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.chat, color: Color(0xFF1EA35A)),
                  title: const Text('WhatsApp'),
                  onTap: () {
                    AudioService.instance.playClickButton();
                    Navigator.of(context).pop();
                    _shareViaWhatsApp(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.email, color: Color(0xFF2A63BF)),
                  title: const Text('E-mail'),
                  onTap: () {
                    AudioService.instance.playClickButton();
                    Navigator.of(context).pop();
                    _shareViaEmail(context);
                  },
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
    final showContinue =
        game.hasStartedSpeurtocht && game.remainingSeconds < 4500 && !game.isMapLocked;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
            color: Color(0xFFF3E5C8),
          ),
          child: SafeArea(
            child: Column(
              children: [
                GameTopBar(
                  currentTab: GameTopTab.home,
                  onTabSelected: (tab) => openTopTab(context, tab),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/logo.png',
                            width: 224,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 18),
                          _homeButton(
                            context,
                            label: 'Start nu de Speurtocht!',
                            icon: Icons.play_arrow_rounded,
                            color: const Color(0xFF2E7D32),
                            verticalPadding: 28,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ThemeLoginScreen()),
                              );
                            },
                          ),
                          if (showContinue) ...[
                            const SizedBox(height: 12),
                            _homeButton(
                              context,
                              label: 'Vervolg speurtocht',
                              icon: Icons.route,
                              color: const Color(0xFF0B5D1E),
                              onTap: () => openTopTab(context, GameTopTab.map),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _homeButton(
                            context,
                            label: 'Speluitleg',
                            icon: Icons.menu_book_rounded,
                            color: const Color(0xFF1565C0),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SpeluitlegScreen()),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _homeButton(
                            context,
                            label: 'Deel speurtocht',
                            icon: Icons.share,
                            color: const Color(0xFF8E24AA),
                            onTap: () => _openShareSheet(context),
                          ),
                          const SizedBox(height: 12),
                          _homeButton(
                            context,
                            label: 'Afsluiten',
                            icon: Icons.close,
                            color: const Color(0xFFC62828),
                            onTap: () => SystemNavigator.pop(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
          const SubtleLogo(opacity: 0.08, width: 82),
        ],
      ),
    );
  }

  Widget _homeButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double verticalPadding = 14,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          AudioService.instance.playClickButton();
          onTap();
        },
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 1.5,
        ).copyWith(
          animationDuration: const Duration(milliseconds: 150),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.white.withValues(alpha: 0.40);
            }
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withValues(alpha: 0.18);
            }
            return null;
          }),
        ),
      ),
    );
  }
}
