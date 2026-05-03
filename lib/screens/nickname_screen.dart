import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/speler_profiel.dart';
import '../providers/hunt_game_state.dart';
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
  final ImagePicker _picker = ImagePicker();
  bool _saving = false;
  File? _photo;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    AudioService.instance.playClickButton();
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1400,
      );
      if (file == null) return;
      setState(() => _photo = File(file.path));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera kon niet worden geopend op dit toestel.')),
      );
    }
  }

  Future<void> _confirm() async {
    if (_saving) return;
    AudioService.instance.playClickButton();

    final nickname = _controller.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vul een nickname of groepsnaam in.')),
      );
      return;
    }
    if (_photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maak eerst een foto voordat je bevestigt.')),
      );
      return;
    }

    setState(() => _saving = true);
    await context.read<HuntGameState>().selectThema(
          leeftijdsgroep: widget.leeftijdsgroep,
          spelerType: widget.spelerType,
          nickname: nickname,
          photoPath: _photo?.path,
        );

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => SuccessIntroScreen(
          nickname: nickname,
          imagePath: _photo?.path,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGirlsTheme = widget.spelerType == SpelerType.meisje;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/Tinkerbell2.png', fit: BoxFit.cover),
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
                      Text(
                        'Vul je nickname of groepsnaam in',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          color: isGirlsTheme ? const Color(0xFFA2356D) : const Color(0xFF1C4C9D),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          height: 180,
                          width: double.infinity,
                          child: _photo != null
                              ? Image.file(_photo!, fit: BoxFit.cover)
                              : Image.asset('assets/Tinkerbell2.png', fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _takePhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Maak foto'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: 'Bijv. Team Speurneus',
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
                              : const Text(
                                  'Bevestigen',
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
