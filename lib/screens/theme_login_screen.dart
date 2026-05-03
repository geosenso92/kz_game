import 'package:flutter/material.dart';

import '../models/speler_profiel.dart';
import '../services/audio_service.dart';
import '../widgets/subtle_logo.dart';
import 'nickname_screen.dart';

class ThemeLoginScreen extends StatefulWidget {
  const ThemeLoginScreen({super.key});

  @override
  State<ThemeLoginScreen> createState() => _ThemeLoginScreenState();
}

class _ThemeLoginScreenState extends State<ThemeLoginScreen> {
  void _select(Leeftijdsgroep leeftijd, SpelerType type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NicknameScreen(
          leeftijdsgroep: leeftijd,
          spelerType: type,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: const Color(0xFFF3E5C8),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Opacity(
                        opacity: 0.95,
                        child: Image.asset(
                          'assets/logo.png',
                          width: 224,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Kies jouw thema',
                        style: TextStyle(
                          color: Color(0xFF4D331D),
                          fontSize: 33,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Kies 1 van de 2 thema\'s om te starten.',
                        style: TextStyle(color: Color(0xFF6D4F32), fontSize: 16, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      _themeButton(
                        label: 'tot 12 jaar (met begeleiding) - Jongen',
                        subtitle: 'Rustige start, duidelijke hints',
                        color: const Color(0xFF3F8CFF),
                        onTap: () => _select(Leeftijdsgroep.begeleid_5_9, SpelerType.jongen),
                      ),
                      _themeButton(
                        label: 'tot 12 jaar (met begeleiding) - Meisje',
                        subtitle: 'Rustige start, duidelijke hints',
                        color: const Color(0xFFE96AA8),
                        onTap: () => _select(Leeftijdsgroep.begeleid_5_9, SpelerType.meisje),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SubtleLogo(opacity: 0.08, width: 82),
        ],
      ),
    );
  }

  Widget _themeButton({
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withValues(alpha: 0.40),
          highlightColor: Colors.white.withValues(alpha: 0.24),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.white.withValues(alpha: 0.34);
            }
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withValues(alpha: 0.16);
            }
            return null;
          }),
          onTap: () {
            AudioService.instance.playClickButton();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
