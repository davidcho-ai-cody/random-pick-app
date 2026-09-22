import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_pick/screens/ladder_result_screen.dart';
import 'package:random_pick/widgets/ladder_painter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final count in [2, 3, 4, 5, 10]) {
    testWidgets('$count ladder columns align with labels', (tester) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final names = List.generate(count, (i) => '참가자$i');
      final results = List.generate(count, (i) => '결과$i');
      await tester.pumpWidget(MaterialApp(
          home: LadderResultScreen(participants: names, results: results)));
      await tester.pumpAndSettle();
      final painterFinder = find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is LadderPainter,
      );
      final paintRect = tester.getRect(painterFinder);
      expect(paintRect.width, greaterThan(0));
      final participantCenters =
          names.map((name) => tester.getCenter(find.text(name)).dx).toList();
      final resultCenters = results
          .map((result) => tester.getCenter(find.text(result)).dx)
          .toList();
      final railCenters = List.generate(
          count, (i) => paintRect.left + (i + 0.5) * paintRect.width / count);
      for (var i = 0; i < count; i++) {
        final railX = railCenters[i];
        expect(railX, greaterThan(paintRect.left));
        expect(railX, lessThan(paintRect.right));
        expect((participantCenters[i] - railX).abs(), lessThan(2));
        expect((resultCenters[i] - railX).abs(), lessThan(2));
      }
      final leftGap = railCenters.first - paintRect.left;
      final rightGap = paintRect.right - railCenters.last;
      expect((leftGap - rightGap).abs(), lessThan(0.01));
      final gaps =
          List.generate(count - 1, (i) => railCenters[i + 1] - railCenters[i]);
      for (final gap in gaps.skip(1)) {
        expect((gap - gaps.first).abs(), lessThan(0.01));
      }
    });
  }
}
