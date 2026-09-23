import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_pick/models/game_mode.dart';
import 'package:random_pick/screens/team_input_screen.dart';
import 'package:random_pick/screens/team_result_screen.dart';
import 'package:random_pick/services/recent_use_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> open(WidgetTester tester, {double height = 1600}) async {
    tester.view.physicalSize = Size(800, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const MaterialApp(home: TeamInputScreen()));
  }

  testWidgets('starts with four participants and keeps a minimum of two',
      (tester) async {
    await open(tester);
    expect(find.byType(TextField), findsNWidgets(4));
    await tester.tap(find.byTooltip('참가자 삭제').first);
    await tester.pump();
    await tester.tap(find.byTooltip('참가자 삭제').first);
    await tester.pump();
    expect(find.byType(TextField), findsNWidgets(2));
    final remove = tester.widget<IconButton>(find.ancestor(
        of: find.byTooltip('참가자 삭제').first, matching: find.byType(IconButton)));
    expect(remove.onPressed, isNull);
  });

  testWidgets('add supports twenty participants and then disables',
      (tester) async {
    await open(tester, height: 4000);
    for (var i = 4; i < 20; i++) {
      final add = find.text('참가자 추가');
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pump();
    }
    expect(find.byType(TextField), findsNWidgets(20));
    expect(find.text('최대 20명까지 추가할 수 있어요'), findsOneWidget);
  });

  testWidgets('team count has two to eight bounds and validation',
      (tester) async {
    await open(tester);
    expect(
        tester
            .widget<IconButton>(find.ancestor(
                of: find.byTooltip('팀 수 줄이기'),
                matching: find.byType(IconButton)))
            .onPressed,
        isNull);
    for (var i = 0; i < 8; i++) {
      await tester.tap(find.byTooltip('팀 수 늘리기'));
      await tester.pump();
    }
    expect(find.text('8'), findsOneWidget);
    expect(
        tester
            .widget<IconButton>(find.ancestor(
                of: find.byTooltip('팀 수 늘리기'),
                matching: find.byType(IconButton)))
            .onPressed,
        isNull);
    await tester.tap(find.text('팀 나누기'));
    await tester.pump();
    expect(find.text('참가자가 최소 8명 이상이어야 합니다.'), findsOneWidget);
  });

  testWidgets('random fill preserves valid count and asks before replacement',
      (tester) async {
    await open(tester);
    await tester.tap(find.text('랜덤 채우기'));
    await tester.pump();
    final filled = tester
        .widgetList<TextField>(find.byType(TextField))
        .map((field) => field.controller!.text)
        .toList();
    expect(filled.length, anyOf(4, 6, 8));
    expect(filled.every((name) => name.isNotEmpty), isTrue);
    await tester.tap(find.text('랜덤 채우기'));
    await tester.pumpAndSettle();
    expect(find.text('현재 입력 내용을 랜덤 참가자로 바꿀까요?'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
  });

  testWidgets('recent team restores participants and team count',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await RecentUseService(prefs).saveTeam(['철수', '영희', '민수'], 3);
    await open(tester);
    await tester.tap(find.text('최근 사용'));
    await tester.pumpAndSettle();
    expect(find.text('참가자: 철수 · 영희 · 민수'), findsOneWidget);
    expect(find.text('팀 개수: 3팀'), findsOneWidget);
    await tester.tap(find.text('불러오기'));
    await tester.pumpAndSettle();
    final values = tester
        .widgetList<TextField>(find.byType(TextField))
        .map((field) => field.controller!.text)
        .toList();
    expect(values, ['철수', '영희', '민수']);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is Text &&
            widget.data == '3' &&
            widget.style?.fontSize == 20),
        findsOneWidget);
  });

  testWidgets('trimmed non-empty participants navigate to result',
      (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField).at(0), ' 철수 ');
    await tester.enterText(find.byType(TextField).at(1), '영희');
    final prefs = await SharedPreferences.getInstance();
    expect(RecentUseService(prefs).read(GameMode.team), isEmpty);
    tester.testTextInput.hide();
    await tester.pump();
    await tester.ensureVisible(find.text('팀 나누기'));
    await tester.tap(find.ancestor(
        of: find.text('팀 나누기'), matching: find.byType(FilledButton)));
    await tester.pumpAndSettle();
    final screen =
        tester.widget<TeamResultScreen>(find.byType(TeamResultScreen));
    expect(screen.participants, ['철수', '영희']);
    expect(screen.teamCount, 2);
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump(const Duration(milliseconds: 250));
  });

  testWidgets('result saves once and keeps round-robin reveal and reshuffle',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: TeamResultScreen(
            participants: ['A', 'B', 'C', 'D'], teamCount: 2)));
    final prefs = await SharedPreferences.getInstance();
    final service = RecentUseService(prefs);
    await tester.pump();
    expect(
        service.read(GameMode.team).single.participants, ['A', 'B', 'C', 'D']);
    expect(find.text('두근두근, 팀을 공개할게요!'), findsOneWidget);
    expect(find.text('팀 나누기 완료! 🎉'), findsNothing);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage)
                .assetName
                .endsWith('team_result_mascot.png')),
        findsNothing);
    expect(
        tester
            .widget<FilledButton>(find.ancestor(
                of: find.text('다시 나누기'), matching: find.byType(FilledButton)))
            .onPressed,
        isNull);
    expect(find.text('?'), findsNWidgets(4));
    await tester.pump(const Duration(milliseconds: 449));
    expect(find.text('?'), findsNWidgets(4));
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('?'), findsNWidgets(3));
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 450));
    }
    await tester.pump(const Duration(milliseconds: 250));
    final firstId = service.read(GameMode.team).single.id;
    expect(find.text('?'), findsNothing);
    expect(find.text('팀 나누기 완료! 🎉'), findsOneWidget);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage)
                .assetName
                .endsWith('team_result_mascot.png')),
        findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(find.ancestor(
                of: find.text('다시 나누기'), matching: find.byType(FilledButton)))
            .onPressed,
        isNotNull);
    await tester.tap(find.text('다시 나누기'));
    await tester.pump();
    expect(find.text('?'), findsNWidgets(4));
    expect(find.text('두근두근, 팀을 공개할게요!'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('팀 나누기 완료! 🎉'), findsNothing);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 450));
    }
    await tester.pump(const Duration(milliseconds: 250));
    expect(service.read(GameMode.team).single.id, firstId);
  });

  testWidgets('eight participants in three teams scroll without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final participants = List.generate(8, (i) => '아주긴참가자이름$i');
    await tester.pumpWidget(MaterialApp(
      home: TeamResultScreen(participants: participants, teamCount: 3),
    ));
    expect(find.text('?'), findsNWidgets(8));
    expect(tester.takeException(), isNull);
    for (var i = 0; i < participants.length; i++) {
      await tester.pump(const Duration(milliseconds: 450));
    }
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('팀 나누기 완료! 🎉'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving during reveal does not update disposed result',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: TeamResultScreen(participants: ['A', 'B', 'C', 'D'], teamCount: 2),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump(const Duration(milliseconds: 450));
    expect(tester.takeException(), isNull);
  });
}
