import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:random_pick/models/game_mode.dart';
import 'package:random_pick/screens/roulette_result_screen.dart';
import 'package:random_pick/services/recent_use_service.dart';
import 'package:random_pick/widgets/roulette_wheel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
      'first spin, result, repeat with same items and one history entry',
      (tester) async {
    const items = ['치킨', '피자', '국밥'];
    await tester.pumpWidget(const MaterialApp(
      home: RouletteResultScreen(items: items),
    ));
    await tester.pump();
    expect(find.byType(RouletteWheel), findsOneWidget);
    expect(find.text('✨ 두근두근...'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '다시 돌리기'))
            .onPressed,
        isNull);

    await tester.pumpAndSettle();
    expect(find.text('오늘의 선택은'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '다시 돌리기'))
            .onPressed,
        isNotNull);
    final result = tester.widget<RouletteWheel>(find.byType(RouletteWheel));
    expect(result.items, items);
    expect(items.any((item) => find.text('🎉 $item').evaluate().isNotEmpty),
        isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(RecentUseService(prefs).read(GameMode.roulette).length, 1);
    await tester.tap(find.text('다시 돌리기'));
    await tester.pump();
    expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '다시 돌리기'))
            .onPressed,
        isNull);
    await tester.pumpAndSettle();
    expect(
        tester.widget<RouletteWheel>(find.byType(RouletteWheel)).items, items);
    expect(RecentUseService(prefs).read(GameMode.roulette).length, 1);
  });

  testWidgets('dispose while spinning does not update removed screen',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: RouletteResultScreen(items: ['A', 'B']),
    ));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('back and home return through the existing navigation path',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
          builder: (context) => Scaffold(
                body: Center(
                    child: FilledButton(
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) =>
                        const RouletteResultScreen(items: ['A', 'B']),
                  )),
                  child: const Text('origin'),
                )),
              )),
    ));
    await tester.tap(find.text('origin'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pumpAndSettle();
    expect(find.text('origin'), findsOneWidget);

    await tester.tap(find.text('origin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('홈으로'));
    await tester.pumpAndSettle();
    expect(find.text('origin'), findsOneWidget);
  });
}
