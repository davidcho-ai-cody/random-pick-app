import 'dart:math';

import 'package:flutter/material.dart';

const List<Color> kWheelColors = [
  Color(0xFF7656DD),
  Color(0xFFF07891),
  Color(0xFFF5B74E),
  Color(0xFF51C7AE),
  Color(0xFF589EEB),
  Color(0xFFAF78DF),
  Color(0xFFE8C75C),
  Color(0xFF68CEBE),
];

/// 회전각(라디안)을 받아 그리는 룰렛 휠. 실제 회전 애니메이션은
/// 바깥에서 [Transform.rotate]로 적용한다.
class RouletteWheel extends StatelessWidget {
  const RouletteWheel({
    super.key,
    required this.items,
    required this.size,
  });

  final List<String> items;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RouletteWheelPainter(items: items),
      ),
    );
  }
}

class _RouletteWheelPainter extends CustomPainter {
  _RouletteWheelPainter({required this.items});

  final List<String> items;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final segment = 2 * pi / items.length;

    final slicePaint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white;

    for (var i = 0; i < items.length; i++) {
      final start = i * segment;
      slicePaint.color = kWheelColors[i % kWheelColors.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        segment,
        true,
        slicePaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        segment,
        true,
        borderPaint,
      );

      final mid = start + segment / 2;
      final labelPoint = Offset(
        center.dx + radius * 0.62 * cos(mid),
        center.dy + radius * 0.62 * sin(mid),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: items[i],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: radius * 0.7);

      canvas.save();
      canvas.translate(labelPoint.dx, labelPoint.dy);
      canvas.rotate(mid + pi / 2);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _RouletteWheelPainter oldDelegate) {
    return oldDelegate.items != items;
  }
}
