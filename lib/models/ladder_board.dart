import 'dart:math';

/// 사다리타기 판. rungs[row][i]는 i번째, (i+1)번째 세로줄을 잇는
/// 가로줄(사다리 다리)이 해당 행에 있는지를 나타낸다.
class LadderBoard {
  LadderBoard({required this.columns, required this.rows, Random? random})
      : assert(columns >= 2),
        assert(rows >= 1),
        rungs = List.generate(rows, (_) => List.filled(columns - 1, false)) {
    final rnd = random ?? Random();
    final pairCounts = _createPairCounts(rnd);
    _placeRungs(pairCounts, rnd);
  }

  final int columns;
  final int rows;
  final List<List<bool>> rungs;

  List<int> _createPairCounts(Random random) {
    final pairCount = columns - 1;
    final slots = rows * pairCount;
    final maxRungs = (columns ~/ 2) * rows;
    final minTotal = max(pairCount, (slots * 0.36).round());
    final maxTotal = min(maxRungs, (slots * 0.44).round());
    final total = minTotal + random.nextInt(maxTotal - minTotal + 1);

    // 전체 밀도는 매번 달라지게 두되, pair별 목표는 평균에서 1개 안팎으로
    // 흔들어 특정 pair만 고립되거나 과밀해지는 극단적인 모양을 막는다.
    final base = total ~/ pairCount;
    final counts = List.filled(pairCount, base);
    final pairOrder = List.generate(pairCount, (index) => index)
      ..shuffle(random);
    for (final pair in pairOrder.take(total % pairCount)) {
      counts[pair]++;
    }

    final minPerPair = max(1, base - 1);
    final maxPerPair = base + 1;
    final transfers = random.nextInt(max(1, pairCount ~/ 2) + 1);
    for (var i = 0; i < transfers; i++) {
      final donors = [
        for (var pair = 0; pair < pairCount; pair++)
          if (counts[pair] > minPerPair) pair,
      ];
      final receivers = [
        for (var pair = 0; pair < pairCount; pair++)
          if (counts[pair] < maxPerPair) pair,
      ];
      if (donors.isEmpty || receivers.isEmpty) break;
      final donor = donors[random.nextInt(donors.length)];
      final validReceivers = receivers.where((pair) => pair != donor).toList();
      if (validReceivers.isEmpty) break;
      final receiver =
          validReceivers[random.nextInt(validReceivers.length)];
      counts[donor]--;
      counts[receiver]++;
    }
    return counts;
  }

  void _placeRungs(List<int> pairCounts, Random random) {
    // 인접 pair가 같은 row를 쓰지 않게 왼쪽 pair부터 사용 row를 정한다.
    // 비인접 pair는 같은 row를 공유할 수 있으므로 기존 사다리 규칙과
    // 자연스러운 가로선 밀도를 모두 유지한다.
    for (var attempt = 0; attempt < 200; attempt++) {
      for (final row in rungs) {
        row.fillRange(0, row.length, false);
      }

      var previousRows = <int>{};
      var completed = true;
      for (var pair = 0; pair < pairCounts.length; pair++) {
        final availableRows = [
          for (var row = 0; row < rows; row++)
            if (!previousRows.contains(row)) row,
        ]..shuffle(random);
        final selectedRows = <int>[];

        // 3개 이상인 pair는 상·중·하 구간을 모두 사용한다.
        if (pairCounts[pair] >= 3) {
          for (var zone = 0; zone < 3; zone++) {
            final candidates = availableRows
                .where((row) => row * 3 ~/ rows == zone)
                .where((row) => !selectedRows.contains(row))
                .toList();
            if (candidates.isEmpty) {
              completed = false;
              break;
            }
            selectedRows.add(candidates[random.nextInt(candidates.length)]);
          }
        }
        if (!completed) break;

        final remainingRows = availableRows
            .where((row) => !selectedRows.contains(row))
            .toList()
          ..shuffle(random);
        final needed = pairCounts[pair] - selectedRows.length;
        if (remainingRows.length < needed) {
          completed = false;
          break;
        }
        selectedRows.addAll(remainingRows.take(needed));
        for (final row in selectedRows) {
          rungs[row][pair] = true;
        }
        previousRows = selectedRows.toSet();
      }
      if (completed) return;
    }

    throw StateError('Unable to generate a valid ladder board.');
  }

  /// [startColumn]에서 출발했을 때 각 행 경계에서 거쳐가는 열 위치 목록.
  List<int> pathFrom(int startColumn) {
    var pos = startColumn;
    final path = <int>[pos];
    for (var row = 0; row < rows; row++) {
      if (pos > 0 && rungs[row][pos - 1]) {
        pos -= 1;
      } else if (pos < columns - 1 && rungs[row][pos]) {
        pos += 1;
      }
      path.add(pos);
    }
    return path;
  }

  int finalColumnFrom(int startColumn) => pathFrom(startColumn).last;
}
