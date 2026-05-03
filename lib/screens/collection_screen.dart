import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/hunt_game_state.dart';
import '../services/audio_service.dart';
import '../widgets/game_top_bar.dart';
import '../widgets/subtle_logo.dart';
import 'navigation_helpers.dart';

enum _AnimalRarity { common, rare, mystic }

class _AnimalEntry {
  final String id;
  final String name;
  final _AnimalRarity rarity;
  final String lifeSpan;
  final String type;
  final String habitat;
  final String offspring;
  final String funFact;

  const _AnimalEntry({
    required this.id,
    required this.name,
    required this.rarity,
    required this.lifeSpan,
    required this.type,
    required this.habitat,
    required this.offspring,
    required this.funFact,
  });
}

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  static const List<_AnimalEntry> _animals = [
    _AnimalEntry(id: 'Specht', name: 'Specht', rarity: _AnimalRarity.common, lifeSpan: '4-11 jaar', type: 'Vogel', habitat: 'Loof- en gemengde bossen', offspring: '4-6 eieren per broedsel', funFact: 'Spechten kunnen razendsnel tegen hout tikken.'),
    _AnimalEntry(id: 'Mol', name: 'Mol', rarity: _AnimalRarity.common, lifeSpan: '2-6 jaar', type: 'Zoogdier', habitat: 'Vochtige graslanden en tuinen', offspring: '3-5 jongen per worp', funFact: 'Mollen graven tunnels met hun sterke voorpoten.'),
    _AnimalEntry(id: 'Egel', name: 'Egel', rarity: _AnimalRarity.common, lifeSpan: '3-7 jaar', type: 'Zoogdier', habitat: 'Tuinen en heggen', offspring: '4-5 jongen per nest', funFact: 'Een egel heeft duizenden beschermende stekels.'),
    _AnimalEntry(id: 'Eekhoorn', name: 'Eekhoorn', rarity: _AnimalRarity.common, lifeSpan: '3-7 jaar', type: 'Zoogdier', habitat: 'Bossen en parken', offspring: '2-4 jongen per nest', funFact: 'Eekhoorns verstoppen nootjes als voedselvoorraad.'),
    _AnimalEntry(id: 'Salamander', name: 'Salamander', rarity: _AnimalRarity.common, lifeSpan: '10-20 jaar', type: 'Amfibie', habitat: 'Vochtige bossen', offspring: 'Tientallen larven per seizoen', funFact: 'Sommige salamanders kunnen lichaamsdelen herstellen.'),
    _AnimalEntry(id: 'Havik', name: 'Havik', rarity: _AnimalRarity.common, lifeSpan: '10-17 jaar', type: 'Vogel', habitat: 'Bosrijke gebieden', offspring: '2-4 eieren per broedsel', funFact: 'Haviken zijn heel wendbaar tussen bomen.'),
    _AnimalEntry(id: 'Muis', name: 'Muis', rarity: _AnimalRarity.common, lifeSpan: '1-3 jaar', type: 'Zoogdier', habitat: 'Velden en bebouwing', offspring: '5-8 jongen per worp', funFact: 'Muizen communiceren ook met ultrasoon geluid.'),
    _AnimalEntry(id: 'Vleermuis', name: 'Vleermuis', rarity: _AnimalRarity.common, lifeSpan: '5-20 jaar', type: 'Zoogdier', habitat: 'Bossen en zolders', offspring: '1 jong per jaar', funFact: 'Vleermuizen orienteren zich via echolocatie.'),
    _AnimalEntry(id: 'Haas', name: 'Haas', rarity: _AnimalRarity.common, lifeSpan: '4-8 jaar', type: 'Zoogdier', habitat: 'Open velden en akkers', offspring: '2-4 jongen per worp', funFact: 'Een haas kan zeer hoge snelheden halen.'),
    _AnimalEntry(id: 'Pad', name: 'Pad', rarity: _AnimalRarity.common, lifeSpan: '10-12 jaar', type: 'Amfibie', habitat: 'Bossen en poelen', offspring: 'Duizenden eitjes per seizoen', funFact: 'Padden keren vaak terug naar dezelfde poel.'),
    _AnimalEntry(id: 'Valk', name: 'Valk', rarity: _AnimalRarity.rare, lifeSpan: '10-15 jaar', type: 'Vogel', habitat: 'Open terrein en kliffen', offspring: '2-4 eieren per legsel', funFact: 'Valken behoren tot de snelste jagers ter wereld.'),
    _AnimalEntry(id: 'Boommarter', name: 'Boommarter', rarity: _AnimalRarity.rare, lifeSpan: '8-12 jaar', type: 'Zoogdier', habitat: 'Structuurrijke bossen', offspring: '2-4 jongen per nest', funFact: 'Boommarters klimmen behendig van tak naar tak.'),
    _AnimalEntry(id: 'Das', name: 'Das', rarity: _AnimalRarity.rare, lifeSpan: '6-14 jaar', type: 'Zoogdier', habitat: 'Bosranden en akkerland', offspring: '2-3 jongen per worp', funFact: 'Dassen wonen in uitgebreide ondergrondse burchten.'),
    _AnimalEntry(id: 'Hazelworm', name: 'Hazelworm', rarity: _AnimalRarity.rare, lifeSpan: '15-30 jaar', type: 'Reptiel', habitat: 'Heide en ruige graslanden', offspring: '6-12 jongen per worp', funFact: 'De hazelworm is een pootloze hagedis.'),
    _AnimalEntry(id: 'Vos', name: 'Vos', rarity: _AnimalRarity.rare, lifeSpan: '3-10 jaar', type: 'Zoogdier', habitat: 'Bos, duin en stadsrand', offspring: '4-6 welpen per worp', funFact: 'Vossen gebruiken hun staart als warme deken.'),
    _AnimalEntry(id: 'Ree', name: 'Ree', rarity: _AnimalRarity.rare, lifeSpan: '8-16 jaar', type: 'Zoogdier', habitat: 'Bosrand en struweel', offspring: '1-2 kalveren per jaar', funFact: 'Reeën kunnen snel dekking zoeken met grote sprongen.'),
    _AnimalEntry(id: 'Bosuil', name: 'Bosuil', rarity: _AnimalRarity.rare, lifeSpan: '10-18 jaar', type: 'Vogel', habitat: 'Oud bos en parken', offspring: '2-4 eieren per nest', funFact: 'Bosuilen jagen vooral op gehoor in het donker.'),
    _AnimalEntry(id: 'Ringslang', name: 'Ringslang', rarity: _AnimalRarity.rare, lifeSpan: '10-20 jaar', type: 'Reptiel', habitat: 'Natte gebieden en waterkanten', offspring: '10-30 eieren per legsel', funFact: 'Ringslangen kunnen uitstekend zwemmen.'),
    _AnimalEntry(id: 'Wolf', name: 'Wolf', rarity: _AnimalRarity.mystic, lifeSpan: '8-13 jaar', type: 'Zoogdier', habitat: 'Grote natuurgebieden', offspring: '4-6 welpen per worp', funFact: 'Wolven leven in sociale roedels.'),
    _AnimalEntry(id: 'Edelhert', name: 'Edelhert', rarity: _AnimalRarity.mystic, lifeSpan: '12-18 jaar', type: 'Zoogdier', habitat: 'Bossen en heide', offspring: '1 kalf per jaar', funFact: 'Mannetjes burlen luid tijdens de bronsttijd.'),
    _AnimalEntry(id: 'Adder', name: 'Adder', rarity: _AnimalRarity.mystic, lifeSpan: '10-20 jaar', type: 'Reptiel', habitat: 'Heide en bosranden', offspring: '5-15 levende jongen per worp', funFact: 'De adder is de enige inheemse giftige slang in NL.'),
    _AnimalEntry(id: 'Oehoe', name: 'Oehoe', rarity: _AnimalRarity.mystic, lifeSpan: '15-25 jaar', type: 'Vogel', habitat: 'Rotsen en rustige bossen', offspring: '2-4 eieren per broedsel', funFact: 'De oehoe is een van de grootste uilen van Europa.'),
  ];

  @override
  Widget build(BuildContext context) {
    final game = context.watch<HuntGameState>();
    final captured = game.gevangenPerDier;
    final discovered = _animals.where((a) => _capturedCount(captured, a.id) > 0).length;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

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
                  currentTab: GameTopTab.collection,
                  onTabSelected: (tab) => openTopTab(context, tab),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bosdier',
                  style: TextStyle(
                    color: Color(0xFF4D331D),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Ontdekt: $discovered/${_animals.length}',
                  style: const TextStyle(color: Color(0xFF6B4B2A), fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 18),
                    itemCount: _animals.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: isLandscape ? 1.12 : 0.9,
                    ),
                    itemBuilder: (context, index) {
                      final animal = _animals[index];
                      final count = _capturedCount(captured, animal.id);
                      final unlocked = count > 0;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            AudioService.instance.playClickButton();
                            if (!unlocked) return;
                            AudioService.instance.playAnimalCueByName(animal.name);
                            _openAnimalDetails(context, animal, unlocked, count);
                          },
                          child: _animalCard(
                            animal,
                            unlocked,
                            count,
                            expanded: false,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SubtleLogo(opacity: 0.09, width: 74),
          ],
        ),
      ),
    );
  }

  Future<void> _openAnimalDetails(
    BuildContext context,
    _AnimalEntry animal,
    bool unlocked,
    int count,
  ) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'animal_detail',
      barrierColor: Colors.black.withValues(alpha: 0.42),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, _, __) {
        return Material(
          color: Colors.transparent,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Center(
                child: Stack(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 28,
                      height: MediaQuery.of(context).size.height - 28,
                      child: _animalCard(
                        animal,
                        unlocked,
                        count,
                        expanded: true,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC62828),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 1.2),
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim, _, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Widget _animalCard(
    _AnimalEntry animal,
    bool unlocked,
    int count, {
    required bool expanded,
  }) {
    final rarityColor = _rarityColor(animal.rarity);
    return Container(
      padding: expanded
          ? const EdgeInsets.fromLTRB(14, 14, 14, 14)
          : const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F0DF).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(expanded ? 18 : 12),
        border: Border.all(color: rarityColor, width: animal.rarity == _AnimalRarity.mystic ? 2.0 : 1.4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            _rarityLabel(animal.rarity),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: rarityColor,
              fontWeight: FontWeight.w900,
              fontSize: expanded ? 12 : 8,
            ),
          ),
          SizedBox(height: expanded ? 6 : 3),
          SizedBox(
            height: expanded ? 170 : 104,
            child: _framedImage(
              animal.id,
              unlocked,
              scale: expanded ? 1.9 : 1.5,
              size: expanded ? 120 : 86,
            ),
          ),
          SizedBox(height: expanded ? 0 : 1),
          _maybeBlurred(
            blurred: !unlocked,
            child: Text(
              unlocked ? animal.name : '?????',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: expanded ? 24 : 14,
                fontWeight: FontWeight.w900,
                color: unlocked ? const Color(0xFF3B2818) : const Color(0xFF8A775F),
              ),
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 8),
            _maybeBlurred(
              blurred: !unlocked,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fact(
                      'Levensverwachting',
                      unlocked ? animal.lifeSpan : '???',
                      fontSize: 14,
                    ),
                    _fact(
                      'Type',
                      unlocked ? animal.type : '???',
                      fontSize: 14,
                    ),
                    _fact(
                      'Habitat',
                      unlocked ? animal.habitat : '???',
                      fontSize: 14,
                    ),
                    _fact(
                      'Nakomelingen',
                      unlocked ? animal.offspring : '???',
                      fontSize: 14,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _maybeBlurred(
              blurred: !unlocked,
              child: Text(
                unlocked ? 'Wist je dat? ${animal.funFact}' : 'Wist je dat? "..."',
                textAlign: TextAlign.center,
                maxLines: 7,
                overflow: TextOverflow.visible,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5D412C),
                ),
              ),
            ),
          ] else ...[
            const Spacer(),
            Text(
              unlocked ? 'Tik voor info' : 'Ontgrendel voor info',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: unlocked ? const Color(0xFF5D412C) : const Color(0xFF8A775F),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _framedImage(
    String id,
    bool unlocked, {
    required double scale,
    required double size,
  }) {
    return Center(
      child: Transform.scale(
        scale: scale,
        child: SizedBox(
          width: size,
          height: size,
          child: unlocked ? _unlockedImage(id) : _lockedImage(id),
        ),
      ),
    );
  }

  Widget _fact(
    String label,
    String value, {
    required double fontSize,
  }) {
    return Text(
      '$label: $value',
      textAlign: TextAlign.start,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: fontSize,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF4E3A28),
      ),
    );
  }

  Widget _unlockedImage(String id) {
    return Image.asset(
      'assets/animals/master/$id.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) {
        return Image.asset(
          'assets/animals/icons_300/$id.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _missingImagePlaceholder(),
        );
      },
    );
  }

  Widget _lockedImage(String id) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 1.6, sigmaY: 1.6),
      child: Image.asset(
        'assets/animals/icons_300_silhouette/$id.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          return Image.asset(
            'assets/animals/icons_300/$id.png',
            fit: BoxFit.contain,
            color: Colors.black,
            colorBlendMode: BlendMode.srcATop,
            errorBuilder: (_, __, ___) => _missingImagePlaceholder(),
          );
        },
      ),
    );
  }

  Widget _maybeBlurred({required bool blurred, required Widget child}) {
    if (!blurred) return child;
    return Opacity(
      opacity: 0.78,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 1.3, sigmaY: 1.3),
        child: child,
      ),
    );
  }

  Widget _missingImagePlaceholder() {
    return const Center(
      child: Icon(Icons.image_not_supported, color: Colors.black38, size: 26),
    );
  }

  int _capturedCount(Map<String, int> captured, String id) {
    final direct = captured[id];
    if (direct != null) return direct;
    final target = id.toLowerCase();
    for (final entry in captured.entries) {
      if (entry.key.toLowerCase() == target) return entry.value;
    }
    return 0;
  }

  Color _rarityColor(_AnimalRarity rarity) {
    switch (rarity) {
      case _AnimalRarity.common:
        return const Color(0xFF2E7D32);
      case _AnimalRarity.rare:
        return const Color(0xFF1E88E5);
      case _AnimalRarity.mystic:
        return const Color(0xFFF57C00);
    }
  }

  String _rarityLabel(_AnimalRarity rarity) {
    switch (rarity) {
      case _AnimalRarity.common:
        return 'Veelvoorkomend';
      case _AnimalRarity.rare:
        return 'Zeldzaam';
      case _AnimalRarity.mystic:
        return 'Mystiek';
    }
  }
}


