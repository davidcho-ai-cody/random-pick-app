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

  test('pair counts stay varied without isolated or overcrowded pairs', () {
    for (final columns in [4, 5, 6, 8, 10]) {
      final rows = (columns * 4).clamp(12, 20);
      var sawVariation = false;
      for (var seed = 0; seed < 10000; seed++) {
        final board =
            LadderBoard(columns: columns, rows: rows, random: Random(seed));
        final counts = [
          for (var pair = 0; pair < columns - 1; pair++)
            board.rungs.where((row) => row[pair]).length,
        ];
        final lowest = counts.reduce(min);
        final highest = counts.reduce(max);
        expect(lowest, greaterThan(0), reason: '$columns columns, seed $seed');
        expect(highest - lowest, lessThanOrEqualTo(2),
            reason: '$columns columns, seed $seed: $counts');
        if (highest != lowest) sawVariation = true;

        for (var pair = 0; pair < counts.length; pair++) {
          if (counts[pair] < 3) continue;
          final zones = <int>{};
          for (var row = 0; row < rows; row++) {
            if (board.rungs[row][pair]) zones.add(row * 3 ~/ rows);
          }
          expect(zones, {0, 1, 2},
              reason: '$columns columns, seed $seed, pair $pair');
        }
      }
      expect(sawVariation, isTrue, reason: '$columns columns');
    }
  });

  test('10000 seeded boards preserve valid paths and symmetric mappings', () {
    for (final columns in [4, 5, 6, 8]) {
      final rows = (columns * 4).clamp(12, 20);
      final mappingCounts =
          List.generate(columns, (_) => List.filled(columns, 0));
      for (var seed = 0; seed < 10000; seed++) {
        final board =
            LadderBoard(columns: columns, rows: rows, random: Random(seed));
        final destinations = <int>[];
        for (var start = 0; start < columns; start++) {
          final path = board.pathFrom(start);
          expect(path.length, rows + 1);
          expect(path.every((column) => column >= 0 && column < columns),
              isTrue);
          destinations.add(path.last);
          mappingCounts[start][path.last]++;
        }
        expect(destinations.toSet().length, columns,
            reason: '$columns columns, seed $seed');
      }

      for (var start = 0; start < columns; start++) {
        for (var destination = 0; destination < columns; destination++) {
          final count = mappingCounts[start][destination];
          final mirrored = mappingCounts[columns - 1 - start]
              [columns - 1 - destination];
          final average = (count + mirrored) / 2;
          expect(count, greaterThan(0));
          expect((count - mirrored).abs() / average, lessThan(0.20),
              reason:
                  '$columns columns, $start->$destination: $count/$mirrored');
        }
      }
    }
  });

  test('2/3/7/9명은 대량 seed에서도 고립 없이 유효한 사다리를 생성한다', () {
    for (final columns in [2, 3, 7, 9]) {
      final rows = (columns * 4).clamp(12, 20);
      for (var seed = 0; seed < 3000; seed++) {
        final board =
            LadderBoard(columns: columns, rows: rows, random: Random(seed));

        final destinations = <int>[];
        for (var start = 0; start < columns; start++) {
          final path = board.pathFrom(start);
          expect(path.length, rows + 1);
          expect(
              path.every((column) => column >= 0 && column < columns), isTrue);
          destinations.add(path.last);
        }
        expect(destinations.toSet().length, columns,
            reason: '$columns columns, seed $seed');

        final counts = [
          for (var pair = 0; pair < columns - 1; pair++)
            board.rungs.where((row) => row[pair]).length,
        ];
        expect(counts.reduce(min), greaterThan(0),
            reason: '$columns columns, seed $seed: $counts');
      }
    }
  });
}
