import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/speler_profiel.dart';
import '../providers/hunt_game_state.dart';
import '../providers/language_provider.dart';
import '../services/audio_service.dart';
import 'success_intro_screen.dart';

class NicknameScreen extends StatefulWidget {
  final Leeftijdsgroep leeftijdsgroep;
  final SpelerType spelerType;

  const NicknameScreen({
    super.key,
    required this.leeftijdsgroep,
    required this.spelerType,
  });

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_saving) return;
    AudioService.instance.playClickButton();

    final nickname = _controller.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<LanguageProvider>().t('nickname_error'))),
      );
      return;
    }
    setState(() => _saving = true);
    await context.read<HuntGameState>().selectThema(
          leeftijdsgroep: widget.leeftijdsgroep,
          spelerType: widget.spelerType,
          nickname: nickname,
        );

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => SuccessIntroScreen(nickname: nickname),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
    final isGirlsTheme = widget.spelerType == SpelerType.meisje;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final backgroundAsset = isLandscape
        ? 'assets/loadscreen_landscape.png'
        : 'assets/loadscreen_portrait.png';

    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            backgroundAsset,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Container(color: Colors.black.withValues(alpha: 0.33)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        height: 86,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        language.t('nickname_prompt'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          color: isGirlsTheme ? const Color(0xFFA2356D) : const Color(0xFF1C4C9D),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: language.t('nickname_hint'),
                          filled: true,
                          fillColor: const Color(0xFFF7F3E9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isGirlsTheme ? const Color(0xFFE790B9) : const Color(0xFF7DA4E0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isGirlsTheme ? const Color(0xFFE790B9) : const Color(0xFF7DA4E0),
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _confirm(),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _confirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isGirlsTheme ? const Color(0xFFC44D8A) : const Color(0xFF2A63BF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  language.t('confirm'),
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
