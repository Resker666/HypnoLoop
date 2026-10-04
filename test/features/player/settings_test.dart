import 'package:flutter_test/flutter_test.dart';
import 'package:hypnoloop/features/player/settings.dart';

void main() {
  test('heart preset selects the approved pink rings on white', () {
    final settings = AppSettings.defaults().preset(2);
    expect(settings.kind, AnimationKind.hearts);
    expect(settings.backgroundArgb, 0xFFFFFFFF);
    expect(settings.foregroundArgb, 0xFFF400DA);
    expect(settings.heartArgb, 0xFFF400DA);
    expect(settings.heartIntervalSeconds / settings.speed, 3);
  });
  test('legacy heart preset upgrades without replacing custom colors', () {
    final old = AppSettings.defaults().toJson()
      ..addAll({
        'kind': 'hearts',
        'backgroundArgb': 0xFF291638,
        'foregroundArgb': 0xFF291638,
        'heartArgb': 0xFFFF8EBD,
        'speed': .8,
        'heartIntervalSeconds': .6,
      });
    final restored = AppSettings.fromJson(old);
    expect(restored.backgroundArgb, 0xFFFFFFFF);
    expect(restored.foregroundArgb, 0xFFF400DA);
    expect(restored.heartArgb, 0xFFF400DA);
    expect(restored.speed, .8);
    expect(restored.heartIntervalSeconds, .6);
    old['heartArgb'] = 0xFF336699;
    expect(AppSettings.fromJson(old).heartArgb, 0xFF336699);
    expect(AppSettings.fromJson(old).backgroundArgb, 0xFF291638);
  });
  test('defaults and JSON round trip preserve the agreed parameters', () {
    final settings = AppSettings.defaults();
    expect(settings.kind, AnimationKind.spiral);
    expect(settings.speed, .5);
    expect(settings.stripes, 4);
    expect(settings.density, 3);
    expect(settings.heartIntervalSeconds, 1);
    expect(settings.centerHeartFraction, .1);
    expect(settings.showCenterHeart, false);
    expect(AppSettings.fromJson(settings.toJson()).toJson(), settings.toJson());
  });
  test('finite numbers clamp and invalid values recover field defaults', () {
    final json = AppSettings.defaults().toJson();
    json.addAll({
      'speed': 99,
      'stripes': -3,
      'density': double.nan,
      'heartIntervalSeconds': double.infinity,
      'centerHeartFraction': 'invalid',
      'backgroundArgb': -1,
      'clockwise': 'false',
      'kind': 'unknown',
    });
    final settings = AppSettings.fromJson(json);
    expect(settings.speed, 2);
    expect(settings.stripes, 2);
    expect(settings.density, 3);
    expect(settings.heartIntervalSeconds, 1);
    expect(settings.centerHeartFraction, .1);
    expect(settings.backgroundArgb, AppSettings.defaults().backgroundArgb);
    expect(settings.clockwise, true);
    expect(settings.kind, AnimationKind.spiral);
  });
  test('unknown schemas reset and copyWith validates interactive values', () {
    expect(AppSettings.fromJson({'schemaVersion': 99, 'speed': 2}).speed, .5);
    final settings = AppSettings.defaults().copyWith(
      speed: double.nan,
      stripes: 99,
      centerHeartFraction: 0,
      kind: AnimationKind.hearts,
    );
    expect(settings.speed, .5);
    expect(settings.stripes, 8);
    expect(settings.centerHeartFraction, .05);
    expect(settings.kind, AnimationKind.hearts);
  });
}
