import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:random_pick/screens/ladder_input_screen.dart';
import 'package:random_pick/screens/ladder_result_screen.dart';
import 'package:random_pick/models/game_mode.dart';
import 'package:random_pick/services/recent_use_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LadderInputScreen()));
  }

  testWidgets('initial pairs, add, and minimum two rows', (tester) async {
    await open(tester);
    expect(find.byType(TextField), findsNWidgets(4));
    await tester.tap(find.text('참가자 추가'));
    await tester.pump();
    expect(find.byType(TextField), findsNWidgets(6));
    await tester.tap(find.byTooltip('행 삭제').first);
    await tester.pump();
    expect(find.byType(TextField), findsNWidgets(4));
    final removeButton = find.ancestor(
      of: find.byIcon(Icons.remove_circle_outline_rounded).first,
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(removeButton.first).onPressed, isNull);
  });

  testWidgets('all participant and result fields are required', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField).at(0), '철수');
    await tester.enterText(find.byType(TextField).at(1), '꽝');
    await tester.tap(find.text('사다리 타기'));
    await tester.pump();
    expect(find.text('참가자와 결과를 모두 입력해주세요.'), findsOneWidget);
  });

  testWidgets('random fill creates pairs and asks before overwrite',
      (tester) async {
    await open(tester);
    await tester.tap(find.text('랜덤 채우기'));
    await tester.pump();
    expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        isNotEmpty);
    await tester.tap(find.text('랜덤 채우기'));
    await tester.pumpAndSettle();
    expect(find.text('현재 입력 내용을 랜덤 항목으로 바꿀까요?'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
  });

  testWidgets('recent empty state and load pairs', (tester) async {
    await open(tester);
    await tester.tap(find.text('최근 사용'));
    await tester.pumpAndSettle();
    expect(find.textContaining('아직 사용한 사다리가 없어요.'), findsOneWidget);
    expect(find.byTooltip('닫기'), findsOneWidget);
    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('recent_uses_v1',
        '[{"id":"1","mode":"ladder","createdAt":"2026-01-01T00:00:00Z","payload":{"participants":["철수","영희"],"results":["꽝","당첨"]}}]');
    await tester.tap(find.text('최근 사용'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('닫기'), findsOneWidget);
    await tester.tap(find.text('불러오기'));
    await tester.pumpAndSettle();
    final values = tester
        .widgetList<TextField>(find.byType(TextField))
        .map((field) => field.controller!.text)
        .toList();
    expect(values, ['철수', '꽝', '영희', '당첨']);
  });

  testWidgets('valid pairs navigate to result', (tester) async {
    await open(tester);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), ' 철수 ');
    await tester.enterText(fields.at(1), '꽝');
    await tester.enterText(fields.at(2), '영희');
    await tester.enterText(fields.at(3), '당첨');
    await tester.tap(find.text('사다리 타기'));
    await tester.pumpAndSettle();
    final result =
        tester.widget<LadderResultScreen>(find.byType(LadderResultScreen));
    expect(result.participants, ['철수', '영희']);
    expect(result.results, ['꽝', '당첨']);
  });

  testWidgets('first path saves once across more selections and reshuffle',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home:
          LadderResultScreen(participants: ['철수', '영희'], results: ['꽝', '당첨']),
    ));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    final service = RecentUseService(prefs);
    expect(service.read(GameMode.ladder), isEmpty);
    expect(find.text('누가 어디로 갈까요?'), findsOneWidget);
    expect(find.text('참가자를 눌러 결과를 확인해보세요'), findsOneWidget);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage)
                .assetName
                .endsWith('ladder_result_mascot.png')),
        findsNothing);
    await tester.tap(find.text('철수'));
    await tester.pump();
    expect(find.text('✨ 철수의 길을 따라가는 중...'), findsOneWidget);
    expect(find.textContaining('철수 → '), findsNothing);
    await tester.pumpAndSettle();
    expect(find.textContaining('철수 → '), findsOneWidget);
    expect(find.text('결과가 나왔어요! ✨'), findsOneWidget);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage)
                .assetName
                .endsWith('ladder_result_mascot.png')),
        findsOneWidget);
    final first = service.read(GameMode.ladder).single;
    expect(first.results, ['꽝', '당첨']);
    await tester.tap(find.text('영희'));
    await tester.pumpAndSettle();
    expect(find.textContaining('영희 → '), findsOneWidget);
    expect(service.read(GameMode.ladder).single.id, first.id);
    await tester.tap(find.text('다시 섞기'));
    await tester.pump();
    expect(find.text('누가 어디로 갈까요?'), findsOneWidget);
    expect(find.textContaining('철수 → '), findsNothing);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage)
                .assetName
                .endsWith('ladder_result_mascot.png')),
        findsNothing);
    await tester.tap(find.text('철수'));
    await tester.pumpAndSettle();
    expect(service.read(GameMode.ladder).single.id, first.id);
  });

  testWidgets('ten long labels fit a compact portrait without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final names = List.generate(10, (i) => '긴참가자이름$i');
    final results = List.generate(10, (i) => '아주긴결과문자열$i');
    await tester.pumpWidget(MaterialApp(
        home: LadderResultScreen(participants: names, results: results)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text(names.first));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('${names.first} → '), findsOneWidget);
  });

  testWidgets('result celebration is enlarged and ignores pointer events',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home:
          LadderResultScreen(participants: ['철수', '영희'], results: ['꽝', '당첨']),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('철수'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pump();

    final sparkle = find.byWidgetPredicate((widget) =>
        widget is Image &&
        widget.image is AssetImage &&
        (widget.image as AssetImage)
            .assetName
            .endsWith('ladder_result_sparkle.png'));
    expect(sparkle, findsOneWidget);
    expect(tester.getSize(sparkle), const Size(72, 72));
    final pointerGuards = tester.widgetList<IgnorePointer>(
      find.ancestor(of: sparkle, matching: find.byType(IgnorePointer)),
    );
    expect(pointerGuards.any((guard) => guard.ignoring), isTrue);
  });

  for (final exit in ['back', 'home']) {
    for (final use in ['unused', 'selected', 'reshuffled']) {
      testWidgets('$exit exit after $use calls ads only after selection',
          (tester) async {
        var adCalls = 0;
        await tester.pumpWidget(MaterialApp(
          home: Builder(builder: (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => LadderResultScreen(
                    participants: const ['철수', '영희'],
                    results: const ['꽝', '당첨'],
                    showAdThenProceed: (proceed) {
                      adCalls++;
                      proceed();
                    },
                  ),
                )),
                child: const Text('열기'),
              ),
            );
          }),
        ));
        await tester.tap(find.text('열기'));
        await tester.pumpAndSettle();
        if (use != 'unused') {
          await tester.tap(find.text('철수'));
          await tester.pumpAndSettle();
        }
        if (use == 'reshuffled') {
          await tester.tap(find.text('다시 섞기'));
          await tester.pump();
        }
        if (exit == 'back') {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(find.text('홈으로'));
        }
        await tester.pumpAndSettle();
        expect(adCalls, use == 'unused' ? 0 : 1);
        expect(find.text('열기'), findsOneWidget);
      });
    }
  }
}
