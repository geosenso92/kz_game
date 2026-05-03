import 'dart:convert';

import 'package:flutter/services.dart';

class AreaService {
  static const List<({double x, double y})> fallbackPolygon = [
    (x: 0.10, y: 0.10),
    (x: 0.92, y: 0.14),
    (x: 0.88, y: 0.86),
    (x: 0.15, y: 0.92),
  ];

  Future<List<({double x, double y})>> loadPolygon() async {
    const paths = [
      'assets/bosgebied.geojson',
      'assets/areas/search_area.geojson',
    ];

    for (final path in paths) {
      final polygon = await _tryLoadPolygon(path);
      if (polygon != null && polygon.length >= 3) {
        return polygon;
      }
    }

    return fallbackPolygon;
  }

  Future<({double x, double y})?> loadKzLocatiePoint() async {
    try {
      final raw = await rootBundle.loadString('assets/KZ_locatie.geojson');
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;

      final geometry = _extractGeometry(json);
      if (geometry == null) return null;
      final gType = geometry['type'];
      final coords = geometry['coordinates'];
      if (gType != 'Point' || coords is! List || coords.length < 2) {
        return null;
      }
      if (coords[0] is! num || coords[1] is! num) return null;
      return (x: (coords[0] as num).toDouble(), y: (coords[1] as num).toDouble());
    } catch (_) {
      return null;
    }
  }

  Future<List<({double x, double y})>> loadFaunaPoints() async {
    const path = 'assets/fauna.geojson';
    try {
      final raw = await rootBundle.loadString(path);
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return const [];
      return _extractPoints(json);
    } catch (_) {
      return const [];
    }
  }

  Future<List<({int featureNumber, double x, double y})>> loadQuestStops() async {
    const path = 'assets/quests/quests.geojson';
    try {
      final raw = await rootBundle.loadString(path);
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return const [];
      return _extractQuestPoints(json);
    } catch (_) {
      return const [];
    }
  }

  Future<List<({double x, double y})>?> _tryLoadPolygon(String assetPath) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      return _extractPolygon(json);
    } catch (_) {
      return null;
    }
  }

  List<({double x, double y})>? _extractPolygon(Map<String, dynamic> json) {
    final geometry = _extractGeometry(json);
    if (geometry == null) return null;
    return _extractFromGeometry(geometry);
  }

  Map<String, dynamic>? _extractGeometry(Map<String, dynamic> json) {
    final type = json['type'];
    if (type == 'FeatureCollection') {
      final features = json['features'];
      if (features is! List || features.isEmpty) return null;
      final feature = features.first;
      if (feature is! Map<String, dynamic>) return null;
      final geometry = feature['geometry'];
      if (geometry is! Map<String, dynamic>) return null;
      return geometry;
    }

    if (type == 'Feature') {
      final geometry = json['geometry'];
      if (geometry is! Map<String, dynamic>) return null;
      return geometry;
    }

    return json;
  }

  List<({double x, double y})>? _extractFromGeometry(Map<String, dynamic> geometry) {
    final gType = geometry['type'];
    final coords = geometry['coordinates'];

    if (coords is! List || coords.isEmpty) return null;

    if (gType == 'Polygon') {
      final ring = coords.first;
      return _parseRing(ring);
    }

    if (gType == 'MultiPolygon') {
      final polygon = coords.first;
      if (polygon is! List || polygon.isEmpty) return null;
      return _parseRing(polygon.first);
    }

    return null;
  }

  List<({double x, double y})>? _parseRing(dynamic ring) {
    if (ring is! List || ring.length < 3) return null;

    final points = <({double x, double y})>[];
    for (final p in ring) {
      if (p is List && p.length >= 2 && p[0] is num && p[1] is num) {
        points.add((x: (p[0] as num).toDouble(), y: (p[1] as num).toDouble()));
      }
    }

    return points.length >= 3 ? points : null;
  }

  List<({double x, double y})> _extractPoints(Map<String, dynamic> json) {
    final type = json['type'];
    if (type == 'FeatureCollection') {
      final features = json['features'];
      if (features is! List) return const [];
      final points = <({double x, double y})>[];
      for (final feature in features) {
        if (feature is! Map<String, dynamic>) continue;
        final geometry = feature['geometry'];
        if (geometry is! Map<String, dynamic>) continue;
        final point = _parsePointGeometry(geometry);
        if (point != null) points.add(point);
      }
      return points;
    }

    if (type == 'Feature') {
      final geometry = json['geometry'];
      if (geometry is! Map<String, dynamic>) return const [];
      final point = _parsePointGeometry(geometry);
      return point == null ? const [] : [point];
    }

    final point = _parsePointGeometry(json);
    return point == null ? const [] : [point];
  }

  ({double x, double y})? _parsePointGeometry(Map<String, dynamic> geometry) {
    final gType = geometry['type'];
    final coords = geometry['coordinates'];
    if (gType != 'Point' || coords is! List || coords.length < 2) return null;
    if (coords[0] is! num || coords[1] is! num) return null;
    return (x: (coords[0] as num).toDouble(), y: (coords[1] as num).toDouble());
  }

  List<({int featureNumber, double x, double y})> _extractQuestPoints(
    Map<String, dynamic> json,
  ) {
    final type = json['type'];
    if (type != 'FeatureCollection') return const [];

    final features = json['features'];
    if (features is! List) return const [];

    final points = <({int featureNumber, double x, double y})>[];
    for (final feature in features) {
      if (feature is! Map<String, dynamic>) continue;
      final properties = feature['properties'];
      final geometry = feature['geometry'];
      if (properties is! Map<String, dynamic> || geometry is! Map<String, dynamic>) {
        continue;
      }

      final numberRaw = properties['feature_number'];
      if (numberRaw is! num) continue;
      final point = _parsePointGeometry(geometry);
      if (point == null) continue;
      points.add((
        featureNumber: numberRaw.toInt(),
        x: point.x,
        y: point.y,
      ));
    }

    points.sort((a, b) => a.featureNumber.compareTo(b.featureNumber));
    return points;
  }
}
