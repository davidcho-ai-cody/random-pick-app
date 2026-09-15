import 'dart:math';

/// 사다리타기 판. rungs[row][i]는 i번째, (i+1)번째 세로줄을 잇는
/// 가로줄(사다리 다리)이 해당 행에 있는지를 나타낸다.
class LadderBoard {
  LadderBoard({required this.columns, required this.rows, Random? random})
      : assert(columns >= 2),
        assert(rows >= 1),
        rungs = List.generate(rows, (_) => List.filled(columns - 1, false)) {
    final rnd = random ?? Random();
    for (var row = 0; row < rows; row++) {
      var col = 0;
      while (col < columns - 1) {
        if (rnd.nextBool()) {
          rungs[row][col] = true;
          col += 2; // 인접 다리가 겹치지 않도록 한 칸 건너뛴다.
        } else {
          col += 1;
        }
      }
    }
  }

  final int columns;
  final int rows;
  final List<List<bool>> rungs;

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
