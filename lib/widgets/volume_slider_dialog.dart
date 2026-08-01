import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../providers/volume_provider.dart';
import '../services/audio_service.dart';

class VolumeSliderDialog extends StatefulWidget {
  const VolumeSliderDialog({super.key});

  @override
  State<VolumeSliderDialog> createState() => _VolumeSliderDialogState();
}

class _VolumeSliderDialogState extends State<VolumeSliderDialog> {
  late double _tempVolume;
  late bool _backgroundEnabled;
  late AppLanguage _language;

  @override
  void initState() {
    super.initState();
    final volumeProvider = context.read<VolumeProvider>();
    final languageProvider = context.read<LanguageProvider>();
    _tempVolume = volumeProvider.volume;
    _backgroundEnabled = volumeProvider.backgroundEnabled;
    _language = languageProvider.language;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF7E8C8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: Color(0xFF4D331D), size: 28),
                const SizedBox(width: 12),
                Text(
                  context.watch<LanguageProvider>().t('settings_title'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4D331D),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF4D331D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.watch<LanguageProvider>().t('language'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4D331D),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SegmentedButton<AppLanguage>(
              segments: [
                ButtonSegment(
                  value: AppLanguage.dutch,
                  label: const Text('NL'),
                  icon: const Icon(Icons.language),
                ),
                ButtonSegment(
                  value: AppLanguage.english,
                  label: const Text('ENG'),
                  icon: const Icon(Icons.language),
                ),
              ],
              selected: {_language},
              onSelectionChanged: (selection) async {
                final chosen = selection.first;
                setState(() => _language = chosen);
                await context.read<LanguageProvider>().setLanguage(chosen);
              },
            ),
            const SizedBox(height: 14),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _backgroundEnabled,
              onChanged: (value) async {
                final enabled = value ?? false;
                setState(() => _backgroundEnabled = enabled);
                await context.read<VolumeProvider>().setBackgroundEnabled(enabled);
                if (enabled) {
                  await AudioService.instance.startBackgroundMusic();
                } else {
                  await AudioService.instance.stopBackgroundMusic();
                }
              },
              title: Text(
                context.watch<LanguageProvider>().t('background_sound'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4D331D),
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: const Color(0xFF2E7D32),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.volume_mute, color: Color(0xFF8D6A4A)),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _tempVolume,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    activeColor: const Color(0xFF2E7D32),
                    inactiveColor: const Color(0xFFD7C29A),
                    onChanged: (value) {
                      setState(() => _tempVolume = value);
                      context.read<VolumeProvider>().setVolume(value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.volume_up, color: Color(0xFF8D6A4A)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  context.watch<LanguageProvider>().t('done'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
