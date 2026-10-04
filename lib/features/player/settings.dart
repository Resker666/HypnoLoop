import 'package:flutter/foundation.dart';

enum AnimationKind { spiral, hearts }

@immutable
class AppSettings {
  const AppSettings._({
    required this.kind,
    required this.speed,
    required this.backgroundArgb,
    required this.foregroundArgb,
    required this.heartArgb,
    required this.clockwise,
    required this.stripes,
    required this.density,
    required this.heartIntervalSeconds,
    required this.showCenterHeart,
    required this.centerHeartFraction,
  });

  factory AppSettings.defaults() => const AppSettings._(
    kind: AnimationKind.spiral,
    speed: .5,
    backgroundArgb: 0xFF090914,
    foregroundArgb: 0xFFF5F0FF,
    heartArgb: 0xFFFF86BC,
    clockwise: true,
    stripes: 4,
    density: 3,
    heartIntervalSeconds: 1,
    showCenterHeart: false,
    centerHeartFraction: .1,
  );

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final fallback = AppSettings.defaults();
    if (json['schemaVersion'] != 1) return fallback;
    double number(String key, double defaultValue) =>
        json[key] is num ? (json[key] as num).toDouble() : defaultValue;
    int color(String key, int defaultValue) =>
        json[key] is int ? json[key] as int : defaultValue;
    final settings = fallback.copyWith(
      kind: AnimationKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => fallback.kind,
      ),
      speed: number('speed', fallback.speed),
      backgroundArgb: color('backgroundArgb', fallback.backgroundArgb),
      foregroundArgb: color('foregroundArgb', fallback.foregroundArgb),
      heartArgb: color('heartArgb', fallback.heartArgb),
      clockwise: json['clockwise'] is bool ? json['clockwise'] as bool : null,
      stripes: json['stripes'] is int ? json['stripes'] as int : null,
      density: number('density', fallback.density),
      heartIntervalSeconds: number(
        'heartIntervalSeconds',
        fallback.heartIntervalSeconds,
      ),
      showCenterHeart: json['showCenterHeart'] is bool
          ? json['showCenterHeart'] as bool
          : null,
      centerHeartFraction: number(
        'centerHeartFraction',
        fallback.centerHeartFraction,
      ),
    );
    if (settings.kind == AnimationKind.hearts &&
        settings.backgroundArgb == 0xFF291638 &&
        settings.foregroundArgb == 0xFF291638 &&
        settings.heartArgb == 0xFFFF8EBD) {
      return settings.copyWith(
        backgroundArgb: 0xFFFFFFFF,
        foregroundArgb: 0xFFF400DA,
        heartArgb: 0xFFF400DA,
      );
    }
    return settings;
  }

  final AnimationKind kind;
  final double speed;
  final int backgroundArgb, foregroundArgb, heartArgb;
  final bool clockwise, showCenterHeart;
  final int stripes;
  final double density, heartIntervalSeconds, centerHeartFraction;

  AppSettings copyWith({
    AnimationKind? kind,
    double? speed,
    int? backgroundArgb,
    int? foregroundArgb,
    int? heartArgb,
    bool? clockwise,
    int? stripes,
    double? density,
    double? heartIntervalSeconds,
    bool? showCenterHeart,
    double? centerHeartFraction,
  }) {
    final fallback = AppSettings.defaults();
    double checked(double value, double min, double max, double defaultValue) =>
        value.isFinite ? value.clamp(min, max) : defaultValue;
    int checkedColor(int value, int defaultValue) =>
        value >= 0 && value <= 0xFFFFFFFF ? value : defaultValue;
    return AppSettings._(
      kind: kind ?? this.kind,
      speed: checked(speed ?? this.speed, .1, 2, fallback.speed),
      backgroundArgb: checkedColor(
        backgroundArgb ?? this.backgroundArgb,
        fallback.backgroundArgb,
      ),
      foregroundArgb: checkedColor(
        foregroundArgb ?? this.foregroundArgb,
        fallback.foregroundArgb,
      ),
      heartArgb: checkedColor(heartArgb ?? this.heartArgb, fallback.heartArgb),
      clockwise: clockwise ?? this.clockwise,
      stripes: (stripes ?? this.stripes).clamp(2, 8),
      density: checked(density ?? this.density, 1, 5, fallback.density),
      heartIntervalSeconds: checked(
        heartIntervalSeconds ?? this.heartIntervalSeconds,
        .4,
        2,
        fallback.heartIntervalSeconds,
      ),
      showCenterHeart: showCenterHeart ?? this.showCenterHeart,
      centerHeartFraction: checked(
        centerHeartFraction ?? this.centerHeartFraction,
        .05,
        .2,
        fallback.centerHeartFraction,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'kind': kind.name,
    'speed': speed,
    'backgroundArgb': backgroundArgb,
    'foregroundArgb': foregroundArgb,
    'heartArgb': heartArgb,
    'clockwise': clockwise,
    'stripes': stripes,
    'density': density,
    'heartIntervalSeconds': heartIntervalSeconds,
    'showCenterHeart': showCenterHeart,
    'centerHeartFraction': centerHeartFraction,
  };

  AppSettings preset(int index) => switch (index) {
    0 => copyWith(
      kind: AnimationKind.spiral,
      backgroundArgb: 0xFF08080A,
      foregroundArgb: 0xFFF5F5F5,
    ),
    1 => copyWith(
      kind: AnimationKind.spiral,
      backgroundArgb: 0xFF130D24,
      foregroundArgb: 0xFFAE8BFA,
    ),
    _ => copyWith(
      kind: AnimationKind.hearts,
      backgroundArgb: 0xFFFFFFFF,
      foregroundArgb: 0xFFF400DA,
      heartArgb: 0xFFF400DA,
      heartIntervalSeconds: 1.5,
    ),
  };
}
