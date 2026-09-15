import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:random_pick/models/ladder_board.dart';

void main() {
  test('모든 시작 열은 서로 다른 도착 열로 매핑된다 (1:1 매핑)', () {
    final board = LadderBoard(columns: 6, rows: 10, random: Random(1));

    final finals =
        List.generate(board.columns, (i) => board.finalColumnFrom(i));

    expect(finals.toSet().length, board.columns);
    for (final f in finals) {
      expect(f, inInclusiveRange(0, board.columns - 1));
    }
  });

  test('경로의 첫 좌표는 항상 시작 열이다', () {
    final board = LadderBoard(columns: 4, rows: 3, random: Random(2));
    for (var i = 0; i < board.columns; i++) {
      expect(board.pathFrom(i).first, i);
    }
  });
}
