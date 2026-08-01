import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/hunt_game_state.dart';
import '../providers/language_provider.dart';
import '../services/audio_service.dart';
import '../widgets/game_top_bar.dart';
import '../widgets/subtle_logo.dart';
import 'navigation_helpers.dart';

enum _AnimalRarity { common, rare, mystic }

class _AnimalEntry {
  final String id;
  final String name;
  final _AnimalRarity rarity;
  final String lifeSpanNl;
  final String lifeSpanEn;
  final String typeNl;
  final String typeEn;
  final String habitatNl;
  final String habitatEn;
  final String offspringNl;
  final String offspringEn;
  final String funFactNl;
  final String funFactEn;

  const _AnimalEntry({
    required this.id,
    required this.name,
    required this.rarity,
    required this.lifeSpanNl,
    required this.lifeSpanEn,
    required this.typeNl,
    required this.typeEn,
    required this.habitatNl,
    required this.habitatEn,
    required this.offspringNl,
    required this.offspringEn,
    required this.funFactNl,
    required this.funFactEn,
  });

    String lifeSpan(AppLanguage language) =>
      language == AppLanguage.english ? lifeSpanEn : lifeSpanNl;
    String type(AppLanguage language) =>
      language == AppLanguage.english ? typeEn : typeNl;
    String habitat(AppLanguage language) =>
      language == AppLanguage.english ? habitatEn : habitatNl;
    String offspring(AppLanguage language) =>
      language == AppLanguage.english ? offspringEn : offspringNl;
    String funFact(AppLanguage language) =>
      language == AppLanguage.english ? funFactEn : funFactNl;
}

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  static const List<_AnimalEntry> _animals = [
    _AnimalEntry(id: 'Specht', name: 'Specht', rarity: _AnimalRarity.common, lifeSpanNl: '4-11 jaar', lifeSpanEn: '4-11 years', typeNl: 'Vogel', typeEn: 'Bird', habitatNl: 'Loof- en gemengde bossen', habitatEn: 'Deciduous and mixed forests', offspringNl: '4-6 eieren per broedsel', offspringEn: '4-6 eggs per brood', funFactNl: 'Spechten kunnen razendsnel tegen hout tikken.', funFactEn: 'Woodpeckers can drum on wood at very high speed.'),
    _AnimalEntry(id: 'Egel', name: 'Egel', rarity: _AnimalRarity.common, lifeSpanNl: '3-7 jaar', lifeSpanEn: '3-7 years', typeNl: 'Zoogdier', typeEn: 'Mammal', habitatNl: 'Tuinen en heggen', habitatEn: 'Gardens and hedgerows', offspringNl: '4-5 jongen per nest', offspringEn: '4-5 young per litter', funFactNl: 'Een egel heeft duizenden beschermende stekels.', funFactEn: 'A hedgehog has thousands of protective spines.'),
    _AnimalEntry(id: 'Eekhoorn', name: 'Eekhoorn', rarity: _AnimalRarity.common, lifeSpanNl: '3-7 jaar', lifeSpanEn: '3-7 years', typeNl: 'Zoogdier', typeEn: 'Mammal', habitatNl: 'Bossen en parken', habitatEn: 'Forests and parks', offspringNl: '2-4 jongen per nest', offspringEn: '2-4 young per litter', funFactNl: 'Eekhoorns verstoppen nootjes als voedselvoorraad.', funFactEn: 'Squirrels hide nuts as a food supply.'),
    _AnimalEntry(id: 'Salamander', name: 'Salamander', rarity: _AnimalRarity.common, lifeSpanNl: '10-20 jaar', lifeSpanEn: '10-20 years', typeNl: 'Amfibie', typeEn: 'Amphibian', habitatNl: 'Vochtige bossen', habitatEn: 'Moist forests', offspringNl: 'Tientallen larven per seizoen', offspringEn: 'Dozens of larvae per season', funFactNl: 'Sommige salamanders kunnen lichaamsdelen herstellen.', funFactEn: 'Some salamanders can regenerate body parts.'),
    _AnimalEntry(id: 'Havik', name: 'Havik', rarity: _AnimalRarity.common, lifeSpanNl: '10-17 jaar', lifeSpanEn: '10-17 years', typeNl: 'Vogel', typeEn: 'Bird', habitatNl: 'Bosrijke gebieden', habitatEn: 'Wooded areas', offspringNl: '2-4 eieren per broedsel', offspringEn: '2-4 eggs per brood', funFactNl: 'Haviken zijn heel wendbaar tussen bomen.', funFactEn: 'Hawks are very agile between trees.'),
    _AnimalEntry(id: 'Muis', name: 'Muis', rarity: _AnimalRarity.common, lifeSpanNl: '1-3 jaar', lifeSpanEn: '1-3 years', typeNl: 'Zoogdier', typeEn: 'Mammal', habitatNl: 'Velden en bebouwing', habitatEn: 'Fields and built-up areas', offspringNl: '5-8 jongen per worp', offspringEn: '5-8 young per litter', funFactNl: 'Muizen communiceren ook met ultrasoon geluid.', funFactEn: 'Mice also communicate with ultrasonic sounds.'),
    _AnimalEntry(id: 'Vleermuis', name: 'Vleermuis', rarity: _AnimalRarity.common, lifeSpanNl: '5-20 jaar', lifeSpanEn: '5-20 years', typeNl: 'Zoogdier', typeEn: 'Mammal', habitatNl: 'Bossen en zolders', habitatEn: 'Forests and attics', offspringNl: '1 jong per jaar', offspringEn: '1 young per year', funFactNl: 'Vleermuizen orienteren zich via echolocatie.', funFactEn: 'Bats navigate using echolocation.'),
    _AnimalEntry(id: 'Pad', name: 'Pad', rarity: _AnimalRarity.common, lifeSpanNl: '10-12 jaar', lifeSpanEn: '10-12 years', typeNl: 'Amfibie', typeEn: 'Amphibian', habitatNl: 'Bossen en poelen', habitatEn: 'Forests and ponds', offspringNl: 'Duizenden eitjes per seizoen', offspringEn: 'Thousands of eggs per season', funFactNl: 'Padden keren vaak terug naar dezelfde poel.', funFactEn: 'Toads often return to the same pond.'),
    _AnimalEntry(id: 'Valk', name: 'Valk', rarity: _AnimalRarity.rare, lifeSpanNl: '10-15 jaar', lifeSpanEn: '10-15 years', typeNl: 'Vogel', typeEn: 'Bird', habitatNl: 'Open terrein en kliffen', habitatEn: 'Open terrain and cliffs', offspringNl: '2-4 eieren per legsel', offspringEn: '2-4 eggs per clutch', funFactNl: 'Valken behoren tot de snelste jagers ter wereld.', funFactEn: 'Falcons are among the fastest hunters in the world.'),
    _AnimalEntry(id: 'Boommarter', name: 'Boommarter', rarity: _AnimalRarity.rare, lifeSpanNl: '8-12 jaar', lifeSpanEn: '8-12 years', typeNl: 'Zoogdier', typeEn: 'Mammal', habitatNl: 'Structuurrijke bossen', habitatEn: 'Structurally rich forests', offspringNl: '2-4 jongen per nest', offspringEn: '2-4 young per litter', funFactNl: 'Boommarters klimmen behendig van tak naar tak.', funFactEn: 'Pine martens climb skillfully from branch to branch.'),
    _AnimalEntry(id: 'Das', name: 'Das', rarity: _AnimalRarity.rare, lifeSpanNl: '6-14 jaar', lifeSpanEn: '6-14 years', typeNl: 'Zoogdier', typeEn: 'Mammal', habitatNl: 'Bosranden en akkerland', habitatEn: 'Forest edges and farmland', offspringNl: '2-3 jongen per worp', offspringEn: '2-3 young per litter', funFactNl: 'Dassen wonen in uitgebreide ondergrondse burchten.', funFactEn: 'Badgers live in extensive underground setts.'),
    _AnimalEntry(id: 'Hazelworm', name: 'Hazelworm', rarity: _AnimalRarity.rare, lifeSpanNl: '15-30 jaar', lifeSpanEn: '15-30 years', typeNl: 'Reptiel', typeEn: 'Reptile', habitatNl: 'Heide en ruige graslanden', habitatEn: 'Heathland and rough grasslands', offspringNl: '6-12 jongen per worp', offspringEn: '6-12 young per litter', funFactNl: 'De hazelworm is een pootloze hagedis.', funFactEn: 'The slow worm is a legless lizard.'),
    _AnimalEntry(id: 'Vos', name: 'Vos', rarity: _AnimalRarity.rare, lifeSpanNl: '3-10 jaar', lifeSpanEn: '3-10 years', typeNl: 'Zoogdier', typeEn: 'Mammal', habitatNl: 'Bos, duin en stadsrand', habitatEn: 'Forest, dunes and city edges', offspringNl: '4-6 welpen per worp', offspringEn: '4-6 cubs per litter', funFactNl: 'Vossen gebruiken hun staart als warme deken.', funFactEn: 'Foxes use their tail as a warm blanket.'),
    _AnimalEntry(id: 'Ree', name: 'Ree', rarity: _AnimalRarity.rare, lifeSpanNl: '8-16 jaar', lifeSpanEn: '8-16 years', typeNl: 'Zoogdier', typeEn: 'Mammal', habitatNl: 'Bosrand en struweel', habitatEn: 'Forest edges and scrub', offspringNl: '1-2 kalveren per jaar', offspringEn: '1-2 fawns per year', funFactNl: 'Reeën kunnen snel dekking zoeken met grote sprongen.', funFactEn: 'Roe deer can quickly find cover with big leaps.'),
    _AnimalEntry(id: 'Bosuil', name: 'Bosuil', rarity: _AnimalRarity.rare, lifeSpanNl: '10-18 jaar', lifeSpanEn: '10-18 years', typeNl: 'Vogel', typeEn: 'Bird', habitatNl: 'Oud bos en parken', habitatEn: 'Old forests and parks', offspringNl: '2-4 eieren per nest', offspringEn: '2-4 eggs per nest', funFactNl: 'Bosuilen jagen vooral op gehoor in het donker.', funFactEn: 'Tawny owls hunt mainly by hearing in the dark.'),
    _AnimalEntry(id: 'Ringslang', name: 'Ringslang', rarity: _AnimalRarity.rare, lifeSpanNl: '10-20 jaar', lifeSpanEn: '10-20 years', typeNl: 'Reptiel', typeEn: 'Reptile', habitatNl: 'Natte gebieden en waterkanten', habitatEn: 'Wet areas and watersides', offspringNl: '10-30 eieren per legsel', offspringEn: '10-30 eggs per clutch', funFactNl: 'Ringslangen kunnen uitstekend zwemmen.', funFactEn: 'Grass snakes are excellent swimmers.'),
    _AnimalEntry(id: 'Wolf', name: 'Wolf', rarity: _AnimalRarity.mystic, lifeSpanNl: '8-13 jaar', lifeSpanEn: '8-13 years', typeNl: 'Zoogdier', typeEn: 'Mammal', habitatNl: 'Grote natuurgebieden', habitatEn: 'Large natural areas', offspringNl: '4-6 welpen per worp', offspringEn: '4-6 pups per litter', funFactNl: 'Wolven leven in sociale roedels.', funFactEn: 'Wolves live in social packs.'),
    _AnimalEntry(id: 'Edelhert', name: 'Edelhert', rarity: _AnimalRarity.mystic, lifeSpanNl: '12-18 jaar', lifeSpanEn: '12-18 years', typeNl: 'Zoogdier', typeEn: 'Mammal', habitatNl: 'Bossen en heide', habitatEn: 'Forests and heathland', offspringNl: '1 kalf per jaar', offspringEn: '1 calf per year', funFactNl: 'Mannetjes burlen luid tijdens de bronsttijd.', funFactEn: 'Males roar loudly during the rutting season.'),
    _AnimalEntry(id: 'Adder', name: 'Adder', rarity: _AnimalRarity.mystic, lifeSpanNl: '10-20 jaar', lifeSpanEn: '10-20 years', typeNl: 'Reptiel', typeEn: 'Reptile', habitatNl: 'Heide en bosranden', habitatEn: 'Heathland and forest edges', offspringNl: '5-15 levende jongen per worp', offspringEn: '5-15 live young per litter', funFactNl: 'De adder is de enige inheemse giftige slang in NL.', funFactEn: 'The adder is the only native venomous snake in the Netherlands.'),
    _AnimalEntry(id: 'Oehoe', name: 'Oehoe', rarity: _AnimalRarity.mystic, lifeSpanNl: '15-25 jaar', lifeSpanEn: '15-25 years', typeNl: 'Vogel', typeEn: 'Bird', habitatNl: 'Rotsen en rustige bossen', habitatEn: 'Rocks and quiet forests', offspringNl: '2-4 eieren per broedsel', offspringEn: '2-4 eggs per brood', funFactNl: 'De oehoe is een van de grootste uilen van Europa.', funFactEn: 'The eagle owl is one of the largest owls in Europe.'),
  ];

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape) {
      return Scaffold(
        backgroundColor: const Color(0xFFF3E5C8),
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
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/rotate.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              language.t('rotate_screen'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF4D331D),
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
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

    final game = context.watch<HuntGameState>();
    final captured = game.gevangenPerDier;
    final discovered = _animals.where((a) => _capturedCount(captured, a.id) > 0).length;

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
                Text(
                  language.t('collection_title'),
                  style: const TextStyle(
                    color: Color(0xFF4D331D),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${language.t('collection_discovered')}: $discovered/${_animals.length}',
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
                      childAspectRatio: 1.1,
                    ),
                    itemBuilder: (context, index) {
                      final animal = _animals[index];
                        final displayName = language.animalName(animal.id);
                      final count = _capturedCount(captured, animal.id);
                      final unlocked = count > 0;
                      final escaped = !unlocked &&
                          !game.isMapLocked &&
                          game.animalIsEscaped(animal.id);
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            AudioService.instance.playClickButton();
                            if (!unlocked) return;
                            AudioService.instance.playAnimalCueByName(animal.id);
                            _openAnimalDetails(context, language, animal, unlocked, count);
                          },
                          child: _animalCard(
                            language,
                            animal,
                            displayName,
                            unlocked,
                            count,
                            expanded: false,
                            escaped: escaped,
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
    LanguageProvider language,
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
                      child: OrientationBuilder(
                        builder: (context, orientation) {
                          if (orientation == Orientation.landscape) {
                            return Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F0DF).withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFF4D331D).withValues(alpha: 0.35),
                                  width: 1.4,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/rotate.png',
                                    width: 92,
                                    height: 92,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    language.t('rotate_to_view_info'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF4D331D),
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return _animalCard(
                            language,
                            animal,
                            language.animalName(animal.id),
                            unlocked,
                            count,
                            expanded: true,
                          );
                        },
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
    LanguageProvider language,
    _AnimalEntry animal,
    String displayName,
    bool unlocked,
    int count, {
    required bool expanded,
    bool escaped = false,
  }) {
    final rarityColor = _rarityColor(animal.rarity);
    return Container(
      padding: expanded
          ? const EdgeInsets.fromLTRB(14, 14, 14, 14)
          : const EdgeInsets.fromLTRB(6, 4, 6, 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F0DF).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(expanded ? 18 : 12),
        border: Border.all(color: rarityColor, width: animal.rarity == _AnimalRarity.mystic ? 2.0 : 1.4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _rarityLabel(language, animal.rarity),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: rarityColor,
              fontWeight: FontWeight.w900,
              fontSize: expanded ? 13 : 9,
            ),
          ),
          SizedBox(height: expanded ? 6 : 3),
          SizedBox(
            height: expanded ? 170 : 86,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _framedImage(
                  animal.id,
                  unlocked,
                  scale: expanded ? 1.9 : 1.5,
                  size: expanded ? 120 : 86,
                ),
                if (escaped && !unlocked)
                  Positioned.fill(
                    child: Center(
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.red.withValues(alpha: 0.92),
                        size: expanded ? 84 : 56,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: expanded ? 0 : 0),
          _maybeBlurred(
            blurred: !unlocked,
            child: Text(
              unlocked ? displayName : '?????',
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
                    _fact(language.t('species'), unlocked ? animal.lifeSpan(language.language) : language.t('details_unknown'), fontSize: 14),
                    _fact(language.t('type'), unlocked ? animal.type(language.language) : language.t('details_unknown'), fontSize: 14),
                    _fact(language.t('habitat'), unlocked ? animal.habitat(language.language) : language.t('details_unknown'), fontSize: 14),
                    _fact(language.t('offspring'), unlocked ? animal.offspring(language.language) : language.t('details_unknown'), fontSize: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _maybeBlurred(
              blurred: !unlocked,
              child: Column(
                children: [
                  Text(
                    language.t('did_you_know'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF5D412C),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    unlocked ? animal.funFact(language.language) : '"..."',
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
                ],
              ),
            ),
            if (unlocked) ...[
              const SizedBox(height: 12),
              Text(
                language.t('world_map_habitat'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4E3A28),
                ),
              ),
              const SizedBox(height: 6),
              _HabitatMiniMap(animalId: animal.id),
            ],
          ] else ...[
            const SizedBox(height: 0),
            Text(
              unlocked
                  ? language.t('tap_for_info')
                  : (escaped ? language.t('escaped_animal') : language.t('unlock_for_info')),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                height: 1.0,
                fontWeight: FontWeight.w700,
                color: unlocked ? const Color(0xFF5D412C) : const Color(0xFF8A775F),
              ),
            ),
            const SizedBox(height: 1),
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
    final effectiveScale = id == 'Edelhert' ? (scale * 0.94) : scale;
    return Center(
      child: Transform.scale(
        scale: effectiveScale,
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

  String _rarityLabel(LanguageProvider language, _AnimalRarity rarity) {
    switch (rarity) {
      case _AnimalRarity.common:
        return language.t('rarity_common');
      case _AnimalRarity.rare:
        return language.t('rarity_rare');
      case _AnimalRarity.mystic:
        return language.t('rarity_super_rare');
    }
  }
}

class _HabitatMiniMap extends StatelessWidget {
  final String animalId;

  const _HabitatMiniMap({required this.animalId});

  static const double _worldAspectRatio = 1536 / 1024;
  static const String _worldImageAsset = 'assets/habitat/world.png';
  static const Offset _worldImageNudge = Offset(0.004, -0.003);
  static const String _defaultHabitatGeoJsonAsset =
      'assets/habitat/redlist_species_data_2f85c862-6c4f-42e8-b0de-4a19902299bb.geojson';
  static Future<List<List<Offset>>>? _cachedProjectedRings;

  static Future<List<List<Offset>>> _loadProjectedRings() {
    return _cachedProjectedRings ??= _readAndSimplifyProjectedRings();
  }

  static Future<List<List<Offset>>> _readAndSimplifyProjectedRings() async {
    final raw = await rootBundle.loadString(_defaultHabitatGeoJsonAsset);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return const <List<Offset>>[];

    final features = decoded['features'];
    if (features is! List) return const <List<Offset>>[];

    final rings = <List<Offset>>[];
    var totalVertices = 0;
    const int maxTotalVertices = 240000;
    const int maxRings = 5000;

    for (final feature in features) {
      if (feature is! Map<String, dynamic>) continue;
      final geometry = feature['geometry'];
      if (geometry is! Map<String, dynamic>) continue;

      final type = geometry['type'];
      final coordinates = geometry['coordinates'];

      if (type == 'Polygon') {
        if (coordinates is! List) continue;
        if (coordinates.isEmpty) continue;
        final exterior = _parseRing(coordinates.first);
        if (exterior == null) continue;
        final simplified = _simplifyRing(exterior);
        if (_normalizedArea(simplified) > 0.0000018) {
          rings.add(simplified);
          totalVertices += simplified.length;
        }
      } else if (type == 'MultiPolygon') {
        if (coordinates is! List) continue;
        for (final polygon in coordinates) {
          if (polygon is! List || polygon.isEmpty) continue;
          final exterior = _parseRing(polygon.first);
          if (exterior == null) continue;
          final simplified = _simplifyRing(exterior);
          if (_normalizedArea(simplified) > 0.0000018) {
            rings.add(simplified);
            totalVertices += simplified.length;
          }
          if (totalVertices >= maxTotalVertices || rings.length >= maxRings) break;
        }
      }

      if (totalVertices >= maxTotalVertices || rings.length >= maxRings) {
        break;
      }
    }

    return rings;
  }

  static List<Offset>? _parseRing(dynamic ringData) {
    if (ringData is! List || ringData.length < 3) return null;

    final points = <Offset>[];
    for (final coordinate in ringData) {
      if (coordinate is! List || coordinate.length < 2) continue;
      final lon = coordinate[0];
      final lat = coordinate[1];
      if (lon is! num || lat is! num) continue;

      final x = ((lon.toDouble() + 180.0) / 360.0).clamp(0.0, 1.0);
      final y = ((90.0 - lat.toDouble()) / 180.0).clamp(0.0, 1.0);
      points.add(Offset(x, y));
    }

    if (points.length < 3) return null;

    final first = points.first;
    final last = points.last;
    if ((first.dx - last.dx).abs() < 1e-9 && (first.dy - last.dy).abs() < 1e-9) {
      points.removeLast();
    }

    return points.length >= 3 ? points : null;
  }

  static List<Offset> _simplifyRing(List<Offset> points) {
    if (points.length <= 220) return points;

    final tolerance = points.length > 2500
        ? 0.0016
        : points.length > 1200
            ? 0.0012
            : 0.0009;

    final simplified = _douglasPeucker(points, tolerance);
    return simplified.length >= 3 ? simplified : points;
  }

  static double _normalizedArea(List<Offset> points) {
    if (points.length < 3) return 0;
    var sum = 0.0;
    for (var i = 0, j = points.length - 1; i < points.length; j = i++) {
      sum += (points[j].dx * points[i].dy) - (points[i].dx * points[j].dy);
    }
    return sum.abs() * 0.5;
  }

  static List<Offset> _douglasPeucker(List<Offset> points, double tolerance) {
    if (points.length < 3) return points;

    final keep = List<bool>.filled(points.length, false);
    keep[0] = true;
    keep[points.length - 1] = true;

    void simplifySegment(int start, int end) {
      if (end <= start + 1) return;

      var maxDistance = 0.0;
      var index = -1;
      final a = points[start];
      final b = points[end];

      for (var i = start + 1; i < end; i++) {
        final d = _distanceToSegment(points[i], a, b);
        if (d > maxDistance) {
          maxDistance = d;
          index = i;
        }
      }

      if (index != -1 && maxDistance > tolerance) {
        keep[index] = true;
        simplifySegment(start, index);
        simplifySegment(index, end);
      }
    }

    simplifySegment(0, points.length - 1);

    final simplified = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      if (keep[i]) simplified.add(points[i]);
    }
    return simplified;
  }

  static double _distanceToSegment(Offset p, Offset a, Offset b) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    if (dx == 0 && dy == 0) {
      return (p - a).distance;
    }

    final t = (((p.dx - a.dx) * dx) + ((p.dy - a.dy) * dy)) / ((dx * dx) + (dy * dy));
    final clampedT = t.clamp(0.0, 1.0);
    final proj = Offset(a.dx + clampedT * dx, a.dy + clampedT * dy);
    return (p - proj).distance;
  }

  @override
  Widget build(BuildContext context) {
    // Animal-specific filtering can be added later; for now all 20 species share the same map file.
    final _ = animalId;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: AspectRatio(
        aspectRatio: _worldAspectRatio,
        child: FutureBuilder<List<List<Offset>>>(
          future: _loadProjectedRings(),
          builder: (context, snapshot) {
            final rings = snapshot.data ?? const <List<Offset>>[];
            return Stack(
              fit: StackFit.expand,
              children: [
                FractionalTranslation(
                  translation: _worldImageNudge,
                  child: Image.asset(
                    _worldImageAsset,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                if (rings.isNotEmpty)
                  CustomPaint(
                    painter: _HabitatOverlayPainter(rings: rings),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HabitatOverlayPainter extends CustomPainter {
  final List<List<Offset>> rings;

  const _HabitatOverlayPainter({required this.rings});

  static const Color _habitat = Color(0xFF2E9E4D);
  static const Offset _overlayNudgePixels = Offset(-12, 12);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (final ring in rings) {
      if (ring.length < 3) continue;
      Offset transformPoint(Offset point) {
        return Offset(point.dx * size.width, point.dy * size.height);
      }

      final first = transformPoint(ring.first);
      path.moveTo(first.dx, first.dy);
      for (var i = 1; i < ring.length; i++) {
        final p = transformPoint(ring[i]);
        path.lineTo(p.dx, p.dy);
      }
      path.close();
    }

    canvas.save();
    canvas.translate(_overlayNudgePixels.dx, _overlayNudgePixels.dy);

    final fill = Paint()
      ..color = _habitat.withValues(alpha: 0.62)
      ..isAntiAlias = true
      ..blendMode = BlendMode.srcOver;
    canvas.drawPath(path, fill);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..isAntiAlias = true
      ..color = const Color(0xFF1B5E20).withValues(alpha: 0.5);
    canvas.drawPath(path, stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HabitatOverlayPainter oldDelegate) {
    return oldDelegate.rings != rings;
  }
}


