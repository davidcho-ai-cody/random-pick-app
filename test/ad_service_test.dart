import 'package:flutter_test/flutter_test.dart';
import 'package:random_pick/services/ad_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InterstitialCooldown', () {
    late DateTime now;
    late SharedPreferences preferences;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      preferences = await SharedPreferences.getInstance();
      now = DateTime.utc(2026, 9, 25, 12);
    });

    InterstitialCooldown cooldown() =>
        InterstitialCooldown(preferences, now: () => now);

    test('allows the first actual display at zero seconds', () {
      expect(cooldown().canShow, isTrue);
    });

    test('blocks 30 and 89 seconds, then allows exactly 90 seconds', () async {
      await cooldown().markShown();
      now = now.add(const Duration(seconds: 30));
      expect(cooldown().canShow, isFalse);
      now = now.add(const Duration(seconds: 59));
      expect(cooldown().canShow, isFalse);
      now = now.add(const Duration(seconds: 1));
      expect(cooldown().canShow, isTrue);
    });

    test('restores the timestamp from persisted preferences', () async {
      await cooldown().markShown();
      final restored = InterstitialCooldown(preferences,
          now: () => now.add(const Duration(seconds: 45)));
      expect(restored.canShow, isFalse);
    });

    test('missing ad proceeds immediately without recording a display',
        () async {
      var proceeded = false;
      await AdService.showThenProceed(() => proceeded = true);
      expect(proceeded, isTrue);
      expect(preferences.getString(InterstitialCooldown.storageKey), isNull);
    });
  });
}
