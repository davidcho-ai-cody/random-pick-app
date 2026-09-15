import 'package:flutter_test/flutter_test.dart';

import 'package:random_pick/main.dart';

void main() {
  testWidgets('홈 화면에 3가지 모드 버튼이 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(const RandomPickApp());

    expect(find.text('랜덤픽'), findsOneWidget);
    expect(find.text('룰렛'), findsOneWidget);
    expect(find.text('사다리타기'), findsOneWidget);
    expect(find.text('팀나누기'), findsOneWidget);
  });

  testWidgets('룰렛 버튼을 누르면 룰렛 입력 화면으로 이동한다', (WidgetTester tester) async {
    await tester.pumpWidget(const RandomPickApp());

    await tester.tap(find.text('룰렛'));
    await tester.pumpAndSettle();

    expect(find.text('룰렛 돌리기'), findsOneWidget);
  });

  testWidgets('사다리타기 버튼을 누르면 사다리타기 입력 화면으로 이동한다', (WidgetTester tester) async {
    await tester.pumpWidget(const RandomPickApp());

    await tester.tap(find.text('사다리타기'));
    await tester.pumpAndSettle();

    expect(find.text('사다리 타기'), findsOneWidget);
  });

  testWidgets('팀나누기 버튼을 누르면 팀나누기 입력 화면으로 이동한다', (WidgetTester tester) async {
    await tester.pumpWidget(const RandomPickApp());

    await tester.tap(find.text('팀나누기'));
    await tester.pumpAndSettle();

    expect(find.text('팀 나누기'), findsOneWidget);
  });
}
