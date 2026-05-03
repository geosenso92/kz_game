import 'dart:math' as math;

import '../models/dier_spawn.dart';

class HuntSpawnService {
  final math.Random _random = math.Random();

  static const List<String> _normaal = [
    'Specht',
    'Mol',
    'Egel',
    'Eekhoorn',
    'Salamander',
    'Havik',
    'Muis',
    'Vleermuis',
    'Haas',
    'Pad',
  ];

  static const List<String> _zeldzaam = [
    'Valk',
    'Boommarter',
    'Das',
    'Hazelworm',
    'Vos',
    'Ree',
    'Bosuil',
    'Ringslang',
  ];

  static const List<String> _legendarisch = [
    'Wolf',
    'Edelhert',
    'Adder',
    'Oehoe',
  ];

  List<DierSpawn> genereerSpawnsOpVasteLocaties({
    required List<({double x, double y})> points,
    int totaal = 24,
  }) {
    if (points.isEmpty) return <DierSpawn>[];

    final animals = _allAnimals();
    animals.shuffle(_random);
    final shuffledPoints = List<({double x, double y})>.from(points)..shuffle(_random);

    final count = math.min(math.min(totaal, animals.length), shuffledPoints.length);
    final spawns = <DierSpawn>[];
    for (var i = 0; i < count; i++) {
      final a = animals[i];
      final p = shuffledPoints[i];
      spawns.add(
        DierSpawn(
          id: '${a.$3}_$i',
          naam: a.$1,
          zeldzaamheid: a.$2,
          x: p.x,
          y: p.y,
        ),
      );
    }
    return spawns;
  }

  List<(String, DierZeldzaamheid, String)> _allAnimals() {
    final all = <(String, DierZeldzaamheid, String)>[];
    for (final naam in _normaal) {
      all.add((naam, DierZeldzaamheid.normaal, 'n'));
    }
    for (final naam in _zeldzaam) {
      all.add((naam, DierZeldzaamheid.zeldzaam, 'r'));
    }
    for (final naam in _legendarisch) {
      all.add((naam, DierZeldzaamheid.legendarisch, 'l'));
    }
    return all;
  }

  List<DierSpawn> genereerSpawns({
    required List<({double x, double y})> polygon,
    List<({double x, double y})> avoidPoints = const [],
    double minDistanceToAvoidPointsMeters = 0,
    int totaal = 24,
  }) {
    final spawns = <DierSpawn>[];
    var idx = 0;

    for (final naam in _normaal) {
      final p = _randomPointInPolygon(
        polygon,
        avoidPoints: avoidPoints,
        minDistanceToAvoidPointsMeters: minDistanceToAvoidPointsMeters,
      );
      spawns.add(DierSpawn(
        id: 'n_$idx',
        naam: naam,
        zeldzaamheid: DierZeldzaamheid.normaal,
        x: p.$1,
        y: p.$2,
      ));
      idx++;
    }

    for (final naam in _zeldzaam) {
      final p = _randomPointInPolygon(
        polygon,
        avoidPoints: avoidPoints,
        minDistanceToAvoidPointsMeters: minDistanceToAvoidPointsMeters,
      );
      spawns.add(DierSpawn(
        id: 'r_$idx',
        naam: naam,
        zeldzaamheid: DierZeldzaamheid.zeldzaam,
        x: p.$1,
        y: p.$2,
      ));
      idx++;
    }

    for (final naam in _legendarisch) {
      final p = _randomPointInPolygon(
        polygon,
        avoidPoints: avoidPoints,
        minDistanceToAvoidPointsMeters: minDistanceToAvoidPointsMeters,
      );
      spawns.add(DierSpawn(
        id: 'l_$idx',
        naam: naam,
        zeldzaamheid: DierZeldzaamheid.legendarisch,
        x: p.$1,
        y: p.$2,
      ));
      idx++;
    }

    spawns.shuffle(_random);
    return spawns.take(totaal).toList(growable: true);
  }

  (double, double) _randomPointInPolygon(
    List<({double x, double y})> polygon, {
    required List<({double x, double y})> avoidPoints,
    required double minDistanceToAvoidPointsMeters,
  }) {
    final xs = polygon.map((p) => p.x).toList(growable: false);
    final ys = polygon.map((p) => p.y).toList(growable: false);
    final minX = xs.reduce(math.min);
    final maxX = xs.reduce(math.max);
    final minY = ys.reduce(math.min);
    final maxY = ys.reduce(math.max);

    for (var i = 0; i < 1200; i++) {
      final x = minX + _random.nextDouble() * (maxX - minX);
      final y = minY + _random.nextDouble() * (maxY - minY);
      if (!_pointInPolygon(x, y, polygon)) continue;
      if (_isTooCloseToAvoidPoints(
        candidateLon: x,
        candidateLat: y,
        avoidPoints: avoidPoints,
        minDistanceMeters: minDistanceToAvoidPointsMeters,
      )) {
        continue;
      }
      return (x, y);
    }

    final fallback = polygon[_random.nextInt(polygon.length)];
    return (fallback.x, fallback.y);
  }

  bool _isTooCloseToAvoidPoints({
    required double candidateLon,
    required double candidateLat,
    required List<({double x, double y})> avoidPoints,
    required double minDistanceMeters,
  }) {
    if (minDistanceMeters <= 0 || avoidPoints.isEmpty) return false;
    for (final p in avoidPoints) {
      if (_distanceMeters(candidateLat, candidateLon, p.y, p.x) < minDistanceMeters) {
        return true;
      }
    }
    return false;
  }

  double _distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _toRad(double deg) => deg * (math.pi / 180.0);

  bool _pointInPolygon(double x, double y, List<({double x, double y})> polygon) {
    var inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].x;
      final yi = polygon[i].y;
      final xj = polygon[j].x;
      final yj = polygon[j].y;

      final intersect = ((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / ((yj - yi).abs() < 1e-9 ? 1e-9 : (yj - yi)) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }
}
