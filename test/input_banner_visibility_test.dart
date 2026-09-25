import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_pick/screens/ladder_input_screen.dart';
import 'package:random_pick/screens/roulette_input_screen.dart';
import 'package:random_pick/screens/team_input_screen.dart';
import 'package:random_pick/widgets/input_banner_ad.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final entry in <String, Widget>{
    'roulette': const RouletteInputScreen(),
    'ladder': const LadderInputScreen(),
    'team': const TeamInputScreen(),
  }.entries) {
    testWidgets('${entry.key} input removes banner while keyboard is visible',
        (tester) async {
      Future<void> pumpWithInset(double bottom) => tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data:
                    MediaQueryData(viewInsets: EdgeInsets.only(bottom: bottom)),
                child: entry.value,
              ),
            ),
          );

      await pumpWithInset(0);
      expect(find.byType(InputBannerAd), findsOneWidget);

      await pumpWithInset(300);
      expect(find.byType(InputBannerAd), findsNothing);

      await pumpWithInset(0);
      expect(find.byType(InputBannerAd), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
