enum Leeftijdsgroep { begeleid_5_9, zelfstandig10Plus }

enum SpelerType { meisje, jongen, gemixt }

String leeftijdsgroepToKey(Leeftijdsgroep value) {
  switch (value) {
    case Leeftijdsgroep.begeleid_5_9:
      return 'begeleid_5_9';
    case Leeftijdsgroep.zelfstandig10Plus:
      return 'zelfstandig10Plus';
  }
}

Leeftijdsgroep leeftijdsgroepFromKey(String? value) {
  switch (value) {
    case 'begeleid_5_9':
      return Leeftijdsgroep.begeleid_5_9;
    case 'zelfstandig_10_plus':
    case 'zelfstandig10Plus':
      return Leeftijdsgroep.zelfstandig10Plus;
    default:
      return Leeftijdsgroep.begeleid_5_9;
  }
}

String spelerTypeToKey(SpelerType value) {
  switch (value) {
    case SpelerType.meisje:
      return 'meisje';
    case SpelerType.jongen:
      return 'jongen';
    case SpelerType.gemixt:
      return 'gemixt';
  }
}

SpelerType spelerTypeFromKey(String? value) {
  switch (value) {
    case 'meisje':
      return SpelerType.meisje;
    case 'jongen':
      return SpelerType.jongen;
    case 'gemixt':
      return SpelerType.gemixt;
    default:
      return SpelerType.gemixt;
  }
}

class SpelerProfiel {
  final String nickname;
  final Leeftijdsgroep leeftijdsgroep;
  final SpelerType spelerType;
  final String? photoPath;

  const SpelerProfiel({
    required this.nickname,
    required this.leeftijdsgroep,
    required this.spelerType,
    this.photoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'nickname': nickname,
      'leeftijdsgroep': leeftijdsgroepToKey(leeftijdsgroep),
      'spelerType': spelerTypeToKey(spelerType),
      'photoPath': photoPath,
    };
  }

  factory SpelerProfiel.fromMap(Map<String, dynamic> map) {
    return SpelerProfiel(
      nickname: (map['nickname'] as String? ?? '').trim(),
      leeftijdsgroep: leeftijdsgroepFromKey(map['leeftijdsgroep'] as String?),
      spelerType: spelerTypeFromKey(map['spelerType'] as String?),
      photoPath: (map['photoPath'] as String?)?.trim(),
    );
  }
}
