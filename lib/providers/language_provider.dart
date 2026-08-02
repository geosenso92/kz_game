import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { dutch, english }

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'game_language_code';

  AppLanguage _language = AppLanguage.dutch;

  AppLanguage get language => _language;
  bool get isEnglish => _language == AppLanguage.english;
  Locale get locale => Locale(isEnglish ? 'en' : 'nl');

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_languageKey);
      _language = stored == 'en' ? AppLanguage.english : AppLanguage.dutch;
    } catch (_) {
      _language = AppLanguage.dutch;
    }
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) return;
    _language = language;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language == AppLanguage.english ? 'en' : 'nl');
    } catch (_) {
      // Ignore persistence failures.
    }
  }

  String t(String key, {Map<String, String> values = const {}}) {
    final template = _translations[key]?[_language] ?? key;
    return values.entries.fold(template, (current, entry) {
      return current.replaceAll('{${entry.key}}', entry.value);
    });
  }

  String animalName(String id) {
    return _animalNames[id]?[_language] ?? id;
  }

  static const Map<String, Map<AppLanguage, String>> _translations = {
    'app_title': {
      AppLanguage.dutch: 'KZ Speurtocht',
      AppLanguage.english: 'KZ Adventure',
    },
    'settings_title': {
      AppLanguage.dutch: 'Instellingen',
      AppLanguage.english: 'Settings',
    },
    'volume': {
      AppLanguage.dutch: 'Volume',
      AppLanguage.english: 'Volume',
    },
    'background_sound': {
      AppLanguage.dutch: 'Achtergrondgeluid aan/uit',
      AppLanguage.english: 'Background sound on/off',
    },
    'done': {
      AppLanguage.dutch: 'Klaar',
      AppLanguage.english: 'Done',
    },
    'language': {
      AppLanguage.dutch: 'Taal',
      AppLanguage.english: 'Language',
    },
    'dutch': {
      AppLanguage.dutch: 'NL',
      AppLanguage.english: 'NL',
    },
    'english': {
      AppLanguage.dutch: 'ENG',
      AppLanguage.english: 'ENG',
    },
    'home_start': {
      AppLanguage.dutch: 'Start nu de Speurtocht!',
      AppLanguage.english: 'Start the Adventure now!',
    },
    'home_continue': {
      AppLanguage.dutch: 'Vervolg speurtocht!',
      AppLanguage.english: 'Continue Adventure!',
    },
    'home_restart': {
      AppLanguage.dutch: 'Start de speurtocht opnieuw!',
      AppLanguage.english: 'Start the adventure again!',
    },
    'instructions': {
      AppLanguage.dutch: 'Speluitleg',
      AppLanguage.english: 'Instructions',
    },
    'share_adventure': {
      AppLanguage.dutch: 'Deel speurtocht',
      AppLanguage.english: 'Share adventure',
    },
    'exit': {
      AppLanguage.dutch: 'Afsluiten',
      AppLanguage.english: 'Exit',
    },
    'share_title': {
      AppLanguage.dutch: 'Deel speurtocht via',
      AppLanguage.english: 'Share the adventure via',
    },
    'share_email_subject': {
      AppLanguage.dutch: 'KZ Speurtocht',
      AppLanguage.english: 'KZ Adventure',
    },
    'share_whatsapp': {
      AppLanguage.dutch: 'WhatsApp',
      AppLanguage.english: 'WhatsApp',
    },
    'share_email': {
      AppLanguage.dutch: 'E-mail',
      AppLanguage.english: 'Email',
    },
    'share_whatsapp_fail': {
      AppLanguage.dutch: 'WhatsApp kon niet worden geopend.',
      AppLanguage.english: 'WhatsApp could not be opened.',
    },
    'share_email_fail': {
      AppLanguage.dutch: 'E-mailapp kon niet worden geopend.',
      AppLanguage.english: 'The email app could not be opened.',
    },
    'theme_choose_target': {
      AppLanguage.dutch: 'Kies doelgroep',
      AppLanguage.english: 'Choose your audience',
    },
    'theme_choose_description': {
      AppLanguage.dutch: 'Kies één van de twee speurtochten om te starten.',
      AppLanguage.english: 'Choose one of the two adventures to start.',
    },
    'family_adventure': {
      AppLanguage.dutch: 'Familie Speurtocht',
      AppLanguage.english: 'Family Adventure',
    },
    'family_description': {
      AppLanguage.dutch: 'Voor het hele gezin',
      AppLanguage.english: 'For the whole family',
    },
    'teams_adventure': {
      AppLanguage.dutch: 'Teams Speurtocht',
      AppLanguage.english: 'Team Adventure',
    },
    'teams_description': {
      AppLanguage.dutch: 'Vanaf 12 jaar',
      AppLanguage.english: 'From 12 years and up',
    },
    'not_available': {
      AppLanguage.dutch: 'Nog niet beschikbaar',
      AppLanguage.english: 'Not available yet',
    },
    'nickname_prompt': {
      AppLanguage.dutch: 'Vul je nickname of groepsnaam in',
      AppLanguage.english: 'Enter your nickname or group name',
    },
    'take_photo': {
      AppLanguage.dutch: 'Maak foto',
      AppLanguage.english: 'Take photo',
    },
    'nickname_hint': {
      AppLanguage.dutch: 'Bijv. Team Speurneus',
      AppLanguage.english: 'E.g. Team Explorer',
    },
    'confirm': {
      AppLanguage.dutch: 'Bevestigen',
      AppLanguage.english: 'Confirm',
    },
    'camera_error': {
      AppLanguage.dutch: 'Camera kon niet worden geopend op dit toestel.',
      AppLanguage.english: 'The camera could not be opened on this device.',
    },
    'nickname_error': {
      AppLanguage.dutch: 'Vul een nickname of groepsnaam in.',
      AppLanguage.english: 'Enter a nickname or group name.',
    },
    'photo_error': {
      AppLanguage.dutch: 'Maak eerst een foto voordat je bevestigt.',
      AppLanguage.english: 'Take a photo before confirming.',
    },
    'success_label': {
      AppLanguage.dutch: 'Succes met de speurtocht {name}!',
      AppLanguage.english: 'Good luck with the adventure, {name}!',
    },
    'instruction_skip': {
      AppLanguage.dutch: 'Sla instructie over',
      AppLanguage.english: 'Skip instructions',
    },
    'instruction_repeat': {
      AppLanguage.dutch: 'Herhaal uitleg',
      AppLanguage.english: 'Repeat instructions',
    },
    'instruction_start': {
      AppLanguage.dutch: 'Start speurtocht',
      AppLanguage.english: 'Start adventure',
    },
    'instruction_asset_error': {
      AppLanguage.dutch: 'Asset laden mislukt: {asset}',
      AppLanguage.english: 'Failed to load asset: {asset}',
    },
    'all_stops_done_title': {
      AppLanguage.dutch: 'Alle stops gehad!',
      AppLanguage.english: 'All stops completed!',
    },
    'all_stops_done_body': {
      AppLanguage.dutch: 'Raad het woord en ga terug naar Klein Zwitserland voor een verrassing!',
      AppLanguage.english: 'Guess the word and return to Klein Zwitserland for a surprise!',
    },
    'ok': {
      AppLanguage.dutch: 'OK',
      AppLanguage.english: 'OK',
    },
    'follow_location': {
      AppLanguage.dutch: 'Volg mijn locatie',
      AppLanguage.english: 'Follow my location',
    },
    'search_area': {
      AppLanguage.dutch: 'Zoekgebied',
      AppLanguage.english: 'Search area',
    },
    'map_letters': {
      AppLanguage.dutch: 'Letters',
      AppLanguage.english: 'Letters',
    },
    'map_quests': {
      AppLanguage.dutch: 'Quests',
      AppLanguage.english: 'Quests',
    },
    'map_animals': {
      AppLanguage.dutch: 'Bosdieren',
      AppLanguage.english: 'Animals',
    },
    'go_to_area': {
      AppLanguage.dutch: 'Ga naar het zoekgebied!',
      AppLanguage.english: 'Go to the search area!',
    },
    'caution_crossing': {
      AppLanguage.dutch: 'Pas op bij het oversteken',
      AppLanguage.english: 'Be careful when crossing',
    },
    'closer_to_catch': {
      AppLanguage.dutch: 'Kom dichterbij',
      AppLanguage.english: 'Get closer',
    },
    'closer_to_catch_subtitle': {
      AppLanguage.dutch: 'om het dier te vangen',
      AppLanguage.english: 'to catch the animal',
    },
    'tap_faster': {
      AppLanguage.dutch: 'Tik sneller',
      AppLanguage.english: 'Tap faster',
    },
    'too_far_stop': {
      AppLanguage.dutch: 'Kom dichterbij',
      AppLanguage.english: 'Get closer',
    },
    'too_far_stop_subtitle': {
      AppLanguage.dutch: 'om het dier te vangen',
      AppLanguage.english: 'to catch the animal',
    },
      'tap_faster_to_catch': {
        AppLanguage.dutch: 'Tik sneller om het dier te vangen',
        AppLanguage.english: 'Tap faster to catch the animal',
      },
      'capture_success': {
        AppLanguage.dutch: 'Je hebt \'m!',
        AppLanguage.english: 'You got it!',
      },
    'test_route': {
      AppLanguage.dutch: 'Test route',
      AppLanguage.english: 'Test route',
    },
    'stop_test_route': {
      AppLanguage.dutch: 'Stop test route',
      AppLanguage.english: 'Stop test route',
    },
    'quest_already_done': {
      AppLanguage.dutch: 'Deze stop is al afgerond.',
      AppLanguage.english: 'This stop has already been completed.',
    },
    'quest_wrong_stop': {
      AppLanguage.dutch: 'Niet goed, probeer een andere stop.',
      AppLanguage.english: 'Not correct, try another stop.',
    },
    'quest_start_hint': {
      AppLanguage.dutch: 'Ga eerst naar de startlocatie en probeer opnieuw.',
      AppLanguage.english: 'Go to the start location first and try again.',
    },
    'guess_word': {
      AppLanguage.dutch: 'Raad het woord!',
      AppLanguage.english: 'Guess the word!',
    },
    'unlocked_letters': {
      AppLanguage.dutch: 'Vrijgespeelde letters',
      AppLanguage.english: 'Unlocked letters',
    },
    'check_word': {
      AppLanguage.dutch: 'Check woord (max. 3 pogingen)',
      AppLanguage.english: 'Check word (max. 3 attempts)',
    },
    'wrong_attempts': {
      AppLanguage.dutch: 'Niet goed. Pogingen over: {left}',
      AppLanguage.english: 'Wrong. Attempts left: {left}',
    },
    'congrats': {
      AppLanguage.dutch: 'Gefeliciteerd!',
      AppLanguage.english: 'Congratulations!',
    },
    'word_found': {
      AppLanguage.dutch: 'Het goede woord is gevonden!',
      AppLanguage.english: 'The correct word has been found!',
    },
    'quest_finished': {
      AppLanguage.dutch: 'Je speurtocht is afgerond.',
      AppLanguage.english: 'Your adventure is complete.',
    },
    'view_stats': {
      AppLanguage.dutch: 'Bekijk My Stats',
      AppLanguage.english: 'View My Stats',
    },
    'stats_title': {
      AppLanguage.dutch: 'My Stats',
      AppLanguage.english: 'My Stats',
    },
    'walking_distance': {
      AppLanguage.dutch: 'Walking distance',
      AppLanguage.english: 'Walking distance',
    },
    'total_duration': {
      AppLanguage.dutch: 'Totale duur speurtocht',
      AppLanguage.english: 'Total adventure time',
    },
    'bosdieren_found': {
      AppLanguage.dutch: 'Bosdieren vrijgespeeld',
      AppLanguage.english: 'Wild animals unlocked',
    },
    'tasks_correct': {
      AppLanguage.dutch: 'Opdrachten correct',
      AppLanguage.english: 'Tasks solved correctly',
    },
    'collection_title': {
      AppLanguage.dutch: 'Bosdier',
      AppLanguage.english: 'Wildlife',
    },
    'collection_discovered': {
      AppLanguage.dutch: 'Ontdekt',
      AppLanguage.english: 'Discovered',
    },
    'rotate_screen': {
      AppLanguage.dutch: 'Roteer scherm voor weergave',
      AppLanguage.english: 'Rotate the screen to view this page',
    },
    'rotate_to_view_info': {
      AppLanguage.dutch: 'Roteer om info te zien',
      AppLanguage.english: 'Rotate to view info',
    },
    'species': {
      AppLanguage.dutch: 'Levensverwachting',
      AppLanguage.english: 'Life span',
    },
    'type': {
      AppLanguage.dutch: 'Type',
      AppLanguage.english: 'Type',
    },
    'habitat': {
      AppLanguage.dutch: 'Habitat',
      AppLanguage.english: 'Habitat',
    },
    'offspring': {
      AppLanguage.dutch: 'Nakomelingen',
      AppLanguage.english: 'Offspring',
    },
    'did_you_know': {
      AppLanguage.dutch: 'Wist je dat?',
      AppLanguage.english: 'Did you know?',
    },
    'world_map_habitat': {
      AppLanguage.dutch: 'Natuurlijke habitat op wereldkaart',
      AppLanguage.english: 'Natural habitat on the world map',
    },
    'tap_for_info': {
      AppLanguage.dutch: 'Tik voor info',
      AppLanguage.english: 'Tap for info',
    },
    'escaped_animal': {
      AppLanguage.dutch: 'Helaas, dit dier is ontsnapt',
      AppLanguage.english: 'Unfortunately, this animal escaped',
    },
    'unlock_for_info': {
      AppLanguage.dutch: 'Ontgrendel voor info',
      AppLanguage.english: 'Unlock for info',
    },
    'item_name_missing': {
      AppLanguage.dutch: '?????',
      AppLanguage.english: '?????',
    },
    'details_unknown': {
      AppLanguage.dutch: '???',
      AppLanguage.english: '???',
    },
    'stats_distance_unit': {
      AppLanguage.dutch: 'meter',
      AppLanguage.english: 'meters',
    },
    'start_route': {
      AppLanguage.dutch: 'Start route',
      AppLanguage.english: 'Start route',
    },
    'stop_route': {
      AppLanguage.dutch: 'Stop route',
      AppLanguage.english: 'Stop route',
    },
    'quest_start_title': {
      AppLanguage.dutch: 'Start speurtocht',
      AppLanguage.english: 'Start adventure',
    },
    'quest_start_question': {
      AppLanguage.dutch: 'Klaar voor de Start?',
      AppLanguage.english: 'Ready for the Start?',
    },
    'quest_stop_question': {
      AppLanguage.dutch: 'Beantwoord de bosvraag bij deze stop.',
      AppLanguage.english: 'Answer the forest question at this stop.',
    },
    'achievement_first_catch': {
      AppLanguage.dutch: 'Eerste Vangst',
      AppLanguage.english: 'First Catch',
    },
    'achievement_first_catch_desc': {
      AppLanguage.dutch: 'Vang je eerste dier.',
      AppLanguage.english: 'Catch your first animal.',
    },
    'achievement_mini_collector': {
      AppLanguage.dutch: 'Mini Verzamelaar',
      AppLanguage.english: 'Mini Collector',
    },
    'achievement_mini_collector_desc': {
      AppLanguage.dutch: 'Vang 5 dieren.',
      AppLanguage.english: 'Catch 5 animals.',
    },
    'achievement_top_tracker': {
      AppLanguage.dutch: 'Top Tracker',
      AppLanguage.english: 'Top Tracker',
    },
    'achievement_top_tracker_desc': {
      AppLanguage.dutch: 'Vang 10 dieren.',
      AppLanguage.english: 'Catch 10 animals.',
    },
    'achievement_letter_hunter': {
      AppLanguage.dutch: 'Letterjager',
      AppLanguage.english: 'Letter Hunter',
    },
    'achievement_letter_hunter_desc': {
      AppLanguage.dutch: 'Speel 3 quests vrij.',
      AppLanguage.english: 'Unlock 3 quests.',
    },
    'achievement_word_ready': {
      AppLanguage.dutch: 'Woord Klaar',
      AppLanguage.english: 'Word Ready',
    },
    'achievement_word_ready_desc': {
      AppLanguage.dutch: 'Verzamel alle letters van {word}.',
      AppLanguage.english: 'Collect all letters of {word}.',
    },
    'achievement_champion': {
      AppLanguage.dutch: 'Kampioen',
      AppLanguage.english: 'Champion',
    },
    'achievement_champion_desc': {
      AppLanguage.dutch: 'Los het finale woord op.',
      AppLanguage.english: 'Solve the final word.',
    },
    'achieved': {
      AppLanguage.dutch: 'Behaald',
      AppLanguage.english: 'Achieved',
    },
    'open': {
      AppLanguage.dutch: 'Open',
      AppLanguage.english: 'Open',
    },
    'rarity_common': {
      AppLanguage.dutch: 'Veelvoorkomend',
      AppLanguage.english: 'Common',
    },
    'rarity_rare': {
      AppLanguage.dutch: 'Zeldzaam',
      AppLanguage.english: 'Rare',
    },
    'rarity_super_rare': {
      AppLanguage.dutch: 'Super zeldzaam',
      AppLanguage.english: 'Super rare',
    },
    'new_animal_found': {
      AppLanguage.dutch: 'Nieuw dier gevonden!',
      AppLanguage.english: 'New animal found!',
    },
    'quest_not_available': {
      AppLanguage.dutch: 'Deze quest is nog niet beschikbaar.',
      AppLanguage.english: 'This quest is not available yet.',
    },
    'quest_next_letter_hint': {
      AppLanguage.dutch: 'Doe eerst quest {number} voor je een nieuwe letter krijgt.',
      AppLanguage.english: 'Complete quest {number} first to get a new letter.',
    },
    'correct': {
      AppLanguage.dutch: 'Correct!',
      AppLanguage.english: 'Correct!',
    },
  };

  String questTitle(String questId) {
    final stopNumber = _questNumber(questId);
    if (stopNumber <= 1) {
      return t('quest_start_title');
    }
    return 'Stop ${stopNumber - 1}';
  }

  String questQuestion(String questId) {
    final stopNumber = _questNumber(questId);
    return stopNumber <= 1 ? t('quest_start_question') : t('quest_stop_question');
  }

  String achievementTitle(String title) {
    return switch (title) {
      'Eerste Vangst' => t('achievement_first_catch'),
      'Mini Verzamelaar' => t('achievement_mini_collector'),
      'Top Tracker' => t('achievement_top_tracker'),
      'Letterjager' => t('achievement_letter_hunter'),
      'Woord Klaar' => t('achievement_word_ready'),
      'Kampioen' => t('achievement_champion'),
      _ => title,
    };
  }

  String achievementDescription(String description, {String? word}) {
    if (description == 'Vang je eerste dier.') {
      return t('achievement_first_catch_desc');
    }
    if (description == 'Vang 5 dieren.') {
      return t('achievement_mini_collector_desc');
    }
    if (description == 'Vang 10 dieren.') {
      return t('achievement_top_tracker_desc');
    }
    if (description == 'Speel 3 quests vrij.') {
      return t('achievement_letter_hunter_desc');
    }
    if (description.startsWith('Verzamel alle letters van ')) {
      return t(
        'achievement_word_ready_desc',
        values: {'word': word ?? ''},
      );
    }
    if (description == 'Los het finale woord op.') {
      return t('achievement_champion_desc');
    }
    return description;
  }

  int _questNumber(String questId) {
    final match = RegExp(r'(\d+)').firstMatch(questId);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  static const Map<String, Map<AppLanguage, String>> _animalNames = {
    'Specht': {
      AppLanguage.dutch: 'Specht',
      AppLanguage.english: 'Woodpecker',
    },
    'Egel': {
      AppLanguage.dutch: 'Egel',
      AppLanguage.english: 'Hedgehog',
    },
    'Eekhoorn': {
      AppLanguage.dutch: 'Eekhoorn',
      AppLanguage.english: 'Squirrel',
    },
    'Salamander': {
      AppLanguage.dutch: 'Salamander',
      AppLanguage.english: 'Salamander',
    },
    'Havik': {
      AppLanguage.dutch: 'Havik',
      AppLanguage.english: 'Hawk',
    },
    'Muis': {
      AppLanguage.dutch: 'Muis',
      AppLanguage.english: 'Mouse',
    },
    'Vleermuis': {
      AppLanguage.dutch: 'Vleermuis',
      AppLanguage.english: 'Bat',
    },
    'Pad': {
      AppLanguage.dutch: 'Pad',
      AppLanguage.english: 'Toad',
    },
    'Valk': {
      AppLanguage.dutch: 'Valk',
      AppLanguage.english: 'Falcon',
    },
    'Boommarter': {
      AppLanguage.dutch: 'Boommarter',
      AppLanguage.english: 'Pine marten',
    },
    'Das': {
      AppLanguage.dutch: 'Das',
      AppLanguage.english: 'Badger',
    },
    'Hazelworm': {
      AppLanguage.dutch: 'Hazelworm',
      AppLanguage.english: 'Slow worm',
    },
    'Vos': {
      AppLanguage.dutch: 'Vos',
      AppLanguage.english: 'Fox',
    },
    'Ree': {
      AppLanguage.dutch: 'Ree',
      AppLanguage.english: 'Roe deer',
    },
    'Bosuil': {
      AppLanguage.dutch: 'Bosuil',
      AppLanguage.english: 'Tawny owl',
    },
    'Ringslang': {
      AppLanguage.dutch: 'Ringslang',
      AppLanguage.english: 'Grass snake',
    },
    'Wolf': {
      AppLanguage.dutch: 'Wolf',
      AppLanguage.english: 'Wolf',
    },
    'Edelhert': {
      AppLanguage.dutch: 'Edelhert',
      AppLanguage.english: 'Red deer',
    },
    'Adder': {
      AppLanguage.dutch: 'Adder',
      AppLanguage.english: 'Adder',
    },
    'Oehoe': {
      AppLanguage.dutch: 'Oehoe',
      AppLanguage.english: 'Eurasian eagle-owl',
    },
  };
}
