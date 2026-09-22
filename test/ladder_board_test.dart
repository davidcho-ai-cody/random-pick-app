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

  test('2/3/4/5/10명에서 다리는 인접 열만 잇고 같은 행에서 충돌하지 않는다', () {
    for (final columns in [2, 3, 4, 5, 10]) {
      for (var seed = 0; seed < 30; seed++) {
        final board =
            LadderBoard(columns: columns, rows: 20, random: Random(seed));
        for (final row in board.rungs) {
          expect(row.length, columns - 1);
          for (var col = 0; col < row.length - 1; col++) {
            expect(row[col] && row[col + 1], isFalse);
          }
        }
        for (var start = 0; start < columns; start++) {
          final path = board.pathFrom(start);
          expect(path.length, board.rows + 1);
          expect(path.first, start);
          for (var row = 0; row < board.rows; row++) {
            final from = path[row];
            final to = path[row + 1];
            final expected = from > 0 && board.rungs[row][from - 1]
                ? from - 1
                : from < columns - 1 && board.rungs[row][from]
                    ? from + 1
                    : from;
            expect(to, expected);
            expect(to, inInclusiveRange(0, columns - 1));
            expect((to - from).abs(), lessThanOrEqualTo(1));
            if (to != from) {
              expect(board.rungs[row][from < to ? from : to], isTrue);
            }
          }
          expect(board.finalColumnFrom(start), path.last);
        }
      }
    }
  });

  test('seeded boards have no structural left/right rung bias', () {
    for (final columns in [3, 4, 5, 10]) {
      final counts = List.filled(columns - 1, 0);
      for (var seed = 0; seed < 250; seed++) {
        final board =
            LadderBoard(columns: columns, rows: 20, random: Random(seed));
        for (final row in board.rungs) {
          for (var col = 0; col < counts.length; col++) {
            if (row[col]) counts[col]++;
          }
        }
      }
      for (var col = 0; col < counts.length ~/ 2; col++) {
        final opposite = counts[counts.length - 1 - col];
        final average = (counts[col] + opposite) / 2;
        expect((counts[col] - opposite).abs() / average, lessThan(0.08),
            reason: '$columns columns, mirrored rung $col');
      }
    }
  });
}
