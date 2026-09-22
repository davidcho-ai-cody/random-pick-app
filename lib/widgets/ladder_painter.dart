import 'package:flutter/material.dart';

import '../models/ladder_board.dart';

/// 사다리 전체(세로줄+가로줄)를 그리고, 선택된 경로가 있으면 강조해서 그린다.
class LadderPainter extends CustomPainter {
  LadderPainter({
    required this.board,
    required this.lineColor,
    required this.highlightColor,
    this.highlightPath,
    this.highlightProgress,
  });

  final LadderBoard board;
  final Color lineColor;
  final Color highlightColor;
  final List<int>? highlightPath;

  /// 하이라이트를 몇 번째 구간까지 그릴지 (0~`highlightPath.length - 1`).
  /// null이면 [highlightPath] 전체를 즉시 그린다.
  final double? highlightProgress;

  double _colX(int index, double width) =>
      (index + 0.5) * width / board.columns;

  @override
  void paint(Canvas canvas, Size size) {
    final rowHeight = size.height / board.rows;
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < board.columns; i++) {
      final x = _colX(i, size.width);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    for (var row = 0; row < board.rows; row++) {
      final y = (row + 0.5) * rowHeight;
      for (var i = 0; i < board.columns - 1; i++) {
        if (board.rungs[row][i]) {
          canvas.drawLine(
            Offset(_colX(i, size.width), y),
            Offset(_colX(i + 1, size.width), y),
            linePaint,
          );
        }
      }
    }

    final path = highlightPath;
    if (path != null) {
      final highlightPaint = Paint()
        ..color = highlightColor
        ..strokeWidth = 4.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final glowPaint = Paint()
        ..color = highlightColor.withValues(alpha: 0.34)
        ..strokeWidth = 11
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      Offset? tip;
      void drawHighlight(Offset start, Offset end) {
        canvas.drawLine(start, end, glowPaint);
        canvas.drawLine(start, end, highlightPaint);
        tip = end;
      }

      // 실제 사다리 격자(세로줄 + 다리)를 그대로 따라가도록, 다리를 타는
      // 지점(row 중간)에서만 옆 칸으로 꺾이게 그린다.
      final progress = highlightProgress;
      for (var row = 0; row < path.length - 1; row++) {
        // progress가 있으면 이 구간(row)까지 얼마나 그려졌는지(0~1)를 구해서,
        // 아직 도달하지 않은 구간은 건너뛰고 현재 구간은 절반만 그린다.
        double segmentT = 1;
        if (progress != null) {
          final local = progress - row;
          if (local <= 0) break;
          segmentT = local.clamp(0.0, 1.0);
        }

        final from = path[row];
        final to = path[row + 1];
        final rowTop = row * rowHeight;
        final rowMid = (row + 0.5) * rowHeight;
        final rowBottom = (row + 1) * rowHeight;
        final fromX = _colX(from, size.width);

        if (from == to) {
          final currentY = rowTop + (rowBottom - rowTop) * segmentT;
          drawHighlight(
            Offset(fromX, rowTop),
            Offset(fromX, currentY),
          );
        } else {
          final toX = _colX(to, size.width);
          if (segmentT <= 1 / 3) {
            final t = segmentT / (1 / 3);
            final currentY = rowTop + (rowMid - rowTop) * t;
            drawHighlight(Offset(fromX, rowTop), Offset(fromX, currentY));
          } else if (segmentT <= 2 / 3) {
            drawHighlight(Offset(fromX, rowTop), Offset(fromX, rowMid));
            final t = (segmentT - 1 / 3) / (1 / 3);
            final currentX = fromX + (toX - fromX) * t;
            drawHighlight(Offset(fromX, rowMid), Offset(currentX, rowMid));
          } else {
            drawHighlight(Offset(fromX, rowTop), Offset(fromX, rowMid));
            drawHighlight(Offset(fromX, rowMid), Offset(toX, rowMid));
            final t = (segmentT - 2 / 3) / (1 / 3);
            final currentY = rowMid + (rowBottom - rowMid) * t;
            drawHighlight(Offset(toX, rowMid), Offset(toX, currentY));
          }
        }
      }
      if (tip != null && progress != null && progress < path.length - 1) {
        canvas.drawCircle(
            tip!, 8, Paint()..color = Colors.white.withValues(alpha: 0.75));
        canvas.drawCircle(tip!, 4.5, Paint()..color = highlightColor);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LadderPainter oldDelegate) {
    return oldDelegate.board != board ||
        oldDelegate.highlightPath != highlightPath ||
        oldDelegate.highlightProgress != highlightProgress ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.highlightColor != highlightColor;
  }
}
