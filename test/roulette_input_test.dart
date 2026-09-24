import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:random_pick/screens/roulette_input_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: RouletteInputScreen()));
  }

  testWidgets('initial fields, add, and minimum two fields', (tester) async {
    await open(tester);
    expect(find.byType(TextField), findsNWidgets(3));
    await tester.tap(find.text('항목 추가'));
    await tester.pump();
    expect(find.byType(TextField), findsNWidgets(4));
    await tester.tap(find.byTooltip('항목 삭제').first);
    await tester.pump();
    await tester.tap(find.byTooltip('항목 삭제').first);
    await tester.pump();
    expect(find.byType(TextField), findsNWidgets(2));
    final removeButton = find.ancestor(
      of: find.byIcon(Icons.remove_circle_outline_rounded).first,
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(removeButton.first).onPressed, isNull);
  });

  testWidgets('placeholder and entered item use distinct text styles',
      (tester) async {
    await open(tester);
    final finder = find.byType(TextField).first;
    final initial = tester.widget<TextField>(finder);

    expect(initial.controller!.text, isEmpty);
    expect(initial.decoration!.hintText, '항목 1');
    expect(initial.decoration!.hintStyle!.color, const Color(0xFF9B98A6));
    expect(initial.decoration!.hintStyle!.fontWeight, FontWeight.w400);
    expect(initial.style!.color, const Color(0xFF342F45));
    expect(initial.style!.fontWeight, FontWeight.w500);

    await tester.enterText(finder, '치킨');
    expect(tester.widget<TextField>(finder).controller!.text, '치킨');
  });

  testWidgets('requires two nonempty trimmed items', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField).first, '  치킨  ');
    await tester.tap(find.text('룰렛 돌리기'));
    await tester.pump();
    expect(find.text('최소 2개 이상 항목을 입력해주세요.'), findsOneWidget);
  });

  testWidgets('random fill replaces empty fields and asks before overwrite',
      (tester) async {
    await open(tester);
    await tester.tap(find.text('랜덤 채우기'));
    await tester.pump();
    expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        isNotEmpty);
    await tester.tap(find.text('랜덤 채우기'));
    await tester.pumpAndSettle();
    expect(find.text('현재 입력한 항목을 랜덤 항목으로 바꿀까요?'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
  });

  testWidgets('recent history has empty state', (tester) async {
    await open(tester);
    await tester.tap(find.text('최근 사용'));
    await tester.pumpAndSettle();
    expect(find.textContaining('아직 최근 사용이 없어요'), findsOneWidget);
    expect(find.byTooltip('닫기'), findsOneWidget);
    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();
    expect(find.text('최근 사용'), findsOneWidget);
  });

  testWidgets('recent history loads saved fields', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('recent_uses_v1',
        '[{"id":"1","mode":"roulette","items":["치킨","피자"],"createdAt":"2026-01-01T00:00:00Z"}]');
    await open(tester);
    await tester.tap(find.text('최근 사용'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('닫기'), findsOneWidget);
    await tester.tap(find.text('불러오기'));
    await tester.pumpAndSettle();
    final fields =
        tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields.length, 2);
    expect(fields.map((field) => field.controller!.text), ['치킨', '피자']);
  });

  testWidgets('valid input navigates to roulette result', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField).at(0), '  A  ');
    await tester.enterText(find.byType(TextField).at(1), 'B');
    await tester.tap(find.text('룰렛 돌리기'));
    await tester.pumpAndSettle();
    expect(find.text('룰렛 결과'), findsOneWidget);
  });
}
