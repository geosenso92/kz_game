class HuntQuest {
  final String id;
  final String titel;
  final String vraag;
  final String antwoord;
  final String letter;
  final double x;
  final double y;
  bool opgelost;
  bool mislukt;

  HuntQuest({
    required this.id,
    required this.titel,
    required this.vraag,
    required this.antwoord,
    required this.letter,
    required this.x,
    required this.y,
    this.opgelost = false,
    this.mislukt = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titel': titel,
      'vraag': vraag,
      'antwoord': antwoord,
      'letter': letter,
      'x': x,
      'y': y,
      'opgelost': opgelost,
      'mislukt': mislukt,
    };
  }

  factory HuntQuest.fromMap(Map<String, dynamic> map) {
    return HuntQuest(
      id: map['id'] as String,
      titel: map['titel'] as String,
      vraag: map['vraag'] as String,
      antwoord: map['antwoord'] as String,
      letter: map['letter'] as String,
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      opgelost: map['opgelost'] as bool? ?? false,
      mislukt: map['mislukt'] as bool? ?? false,
    );
  }
}
