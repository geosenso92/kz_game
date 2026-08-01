import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/speler_profiel.dart';
import '../providers/language_provider.dart';
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

  void _showNotAvailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.read<LanguageProvider>().t('not_available'))),
    );
  }

  Future<void> _openLanguageSettingsDialog() async {
    final languageProvider = context.read<LanguageProvider>();
    var selected = languageProvider.language;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(languageProvider.t('language')),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SegmentedButton<AppLanguage>(
                segments: [
                  ButtonSegment(
                    value: AppLanguage.dutch,
                    label: Text(languageProvider.t('dutch')),
                    icon: const Icon(Icons.language),
                  ),
                  ButtonSegment(
                    value: AppLanguage.english,
                    label: Text(languageProvider.t('english')),
                    icon: const Icon(Icons.language),
                  ),
                ],
                selected: {selected},
                onSelectionChanged: (selection) async {
                  final value = selection.first;
                  setStateDialog(() => selected = value);
                  await languageProvider.setLanguage(value);
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(languageProvider.t('done')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: const Color(0xFFF3E5C8),
            child: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          Text(
                            language.t('theme_choose_target'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF4D331D),
                              fontSize: 33,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            language.t('theme_choose_description'),
                            style: const TextStyle(color: Color(0xFF6D4F32), fontSize: 16, fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          _themeButton(
                            label: language.t('family_adventure'),
                            subtitle: language.t('family_description'),
                            color: const Color(0xFF2E7D32),
                            onTap: () => _select(Leeftijdsgroep.begeleid_5_9, SpelerType.gemixt),
                          ),
                          _themeButton(
                            label: language.t('teams_adventure'),
                            subtitle: language.t('teams_description'),
                            color: const Color(0xFFB0BEC5),
                            onTap: _showNotAvailable,
                            inactive: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _openLanguageSettingsDialog,
                        child: Ink(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8EED8).withValues(alpha: 0.96),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFD7C29A), width: 1),
                          ),
                          child: const Icon(
                            Icons.settings,
                            color: Color(0xFF4D331D),
                            size: 22,
                          ),
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

  Widget _themeButton({
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool inactive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            splashColor: inactive ? Colors.transparent : Colors.white.withValues(alpha: 0.40),
            highlightColor: inactive ? Colors.transparent : Colors.white.withValues(alpha: 0.24),
            overlayColor: inactive
                ? null
                : WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.pressed)) {
                      return Colors.white.withValues(alpha: 0.34);
                    }
                    if (states.contains(WidgetState.hovered)) {
                      return Colors.white.withValues(alpha: 0.16);
                    }
                    return null;
                  }),
            onTap: inactive
                ? null
                : () {
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
      ),
    );
  }
}
