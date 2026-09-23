import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:random_pick/main.dart';
import 'package:random_pick/screens/home_screen.dart';

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

  testWidgets('브랜드 시작 화면은 초기화 완료 후 Home으로 전환된다', (tester) async {
    final initialization = Completer<void>();

    await tester
        .pumpWidget(RandomPickApp(initialization: initialization.future));

    expect(find.bySemanticsLabel('랜덤픽 시작 화면'), findsOneWidget);
    expect(find.text('오늘은 뭘로 정해볼까요?'), findsNothing);

    initialization.complete();
    await tester.pump();

    expect(find.text('오늘은 뭘로 정해볼까요?'), findsOneWidget);
  });

  testWidgets('종료 아이콘에서 취소하면 Home을 유지한다', (tester) async {
    var exitCount = 0;
    await tester.pumpWidget(MaterialApp(
      home: HomeScreen(onExit: () async => exitCount++),
    ));

    await tester.tap(find.byTooltip('앱 종료'));
    await tester.pumpAndSettle();
    expect(find.text('랜덤픽을 종료할까요?'), findsOneWidget);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(find.text('랜덤픽을 종료할까요?'), findsNothing);
    expect(find.text('오늘은 뭘로 정해볼까요?'), findsOneWidget);
    expect(exitCount, 0);
  });

  testWidgets('종료 아이콘에서 종료하면 종료 callback을 한 번 호출한다', (tester) async {
    var exitCount = 0;
    await tester.pumpWidget(MaterialApp(
      home: HomeScreen(onExit: () async => exitCount++),
    ));

    await tester.tap(find.byTooltip('앱 종료'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('종료'));
    await tester.pumpAndSettle();

    expect(exitCount, 1);
  });

  testWidgets('종료 아이콘 연타는 종료 dialog를 중복 표시하지 않는다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: HomeScreen(onExit: () async {}),
    ));

    await tester.tap(find.byTooltip('앱 종료'));
    await tester.tap(find.byTooltip('앱 종료'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('랜덤픽을 종료할까요?'), findsOneWidget);
  });

  testWidgets('Home의 Android Back은 종료 dialog를 표시하고 dialog Back은 닫는다',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: HomeScreen(onExit: () async {}),
    ));

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('랜덤픽을 종료할까요?'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('랜덤픽을 종료할까요?'), findsNothing);
    expect(find.text('오늘은 뭘로 정해볼까요?'), findsOneWidget);
  });

  testWidgets('작은 portrait와 확대된 글자에서도 Home이 overflow되지 않는다', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1.3),
        ),
        child: child!,
      ),
      home: HomeScreen(onExit: () async {}),
    ));

    expect(tester.takeException(), isNull);
    expect(find.text('랜덤픽'), findsOneWidget);
    expect(find.byTooltip('앱 종료'), findsOneWidget);
  });
}
