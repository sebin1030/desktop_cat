import 'dart:convert';

import 'package:flutter/services.dart';

class AppSettings {
  const AppSettings({
    required this.character,
    required this.spriteSize,
    required this.walkSpeed,
    required this.idleStretchAfter,
    required this.idleWalkAfter,
    required this.pauseMin,
    required this.pauseMax,
  });

  final String character;
  final double spriteSize;
  final double walkSpeed;
  final Duration idleStretchAfter;
  final Duration idleWalkAfter;
  final Duration pauseMin;
  final Duration pauseMax;

  static Future<AppSettings> load({String character = 'cat'}) async {
    final raw = await rootBundle.loadString('assets/characters/$character/manifest.json');
    final data = jsonDecode(raw) as Map<String, Object?>;
    final width = (data['spriteWidth'] as num? ?? 160).toDouble();
    final scale = (data['scale'] as num? ?? 1).toDouble();

    return AppSettings(
      character: character,
      spriteSize: width * scale,
      walkSpeed: (data['walkSpeedPixelsPerSecond'] as num? ?? 95).toDouble(),
      idleStretchAfter: Duration(seconds: (data['idleStretchSeconds'] as num? ?? 12).round()),
      idleWalkAfter: Duration(seconds: (data['idleWalkSeconds'] as num? ?? 22).round()),
      pauseMin: Duration(seconds: (data['pauseMinSeconds'] as num? ?? 2).round()),
      pauseMax: Duration(seconds: (data['pauseMaxSeconds'] as num? ?? 5).round()),
    );
  }
}
