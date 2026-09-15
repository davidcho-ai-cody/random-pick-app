import 'dart:math';

import 'package:flutter/material.dart';

import '../widgets/roulette_wheel.dart';

/// 휠 색상과 무관하게 항상 잘 보이도록 흰 채우기 + 진한 테두리로 그리는
/// 고정 포인터. 어떤 조각 색 위에 있어도 대비가 유지된다.
class _WheelPointer extends StatelessWidget {
  const _WheelPointer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 44,
      child: CustomPaint(painter: _WheelPointerPainter()),
    );
  }
}

class _WheelPointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawShadow(path, Colors.black, 3, false);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _WheelPointerPainter oldDelegate) => false;
}

/// 룰렛을 돌려 항목 중 하나를 무작위로 뽑는 결과 화면.
class RouletteResultScreen extends StatefulWidget {
  const RouletteResultScreen({super.key, required this.items});

  final List<String> items;

  @override
  State<RouletteResultScreen> createState() => _RouletteResultScreenState();
}

class _RouletteResultScreenState extends State<RouletteResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _rotation;
  final Random _random = Random();

  double _currentAngle = 0;
  int? _winnerIndex;
  bool _spinning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(() {
        setState(() => _currentAngle = _rotation.value);
      });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _spinning = false);
      }
    });
    // 화면 진입 직후 자동으로 한 번 돌린다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _spin());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spin() {
    final items = widget.items;
    final winner = _random.nextInt(items.length);
    final segment = 2 * pi / items.length;

    // 포인터는 12시 방향(3pi/2)에 고정, 당첨 조각의 중심이 그 위치로 오도록
    // 회전각을 계산한다. 현재 각도를 기준으로 "최소 필요 회전량 + 4~6바퀴"만큼
    // 항상 앞으로 더 돌려서, 두 번째 이후에도 매번 충분히 돌게 한다.
    final desiredMod = _normalize((3 * pi / 2) - (winner + 0.5) * segment);
    final currentMod = _normalize(_currentAngle);
    final minDelta = _normalize(desiredMod - currentMod);
    final extraSpins = 4 + _random.nextInt(3);
    final targetAngle = _currentAngle + minDelta + extraSpins * 2 * pi;

    _rotation = Tween<double>(begin: _currentAngle, end: targetAngle).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    setState(() {
      _winnerIndex = null;
      _spinning = true;
    });
    _controller
      ..reset()
      ..forward().whenComplete(() {
        setState(() => _winnerIndex = winner);
      });
  }

  double _normalize(double angle) {
    const twoPi = 2 * pi;
    return ((angle % twoPi) + twoPi) % twoPi;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final size = MediaQuery.of(context).size;
    final wheelSize = min(size.width - 64, 320.0);

    return Scaffold(
      appBar: AppBar(title: const Text('룰렛 결과')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: _currentAngle,
                    child: RouletteWheel(items: items, size: wheelSize),
                  ),
                  const Positioned(
                    top: -14,
                    child: _WheelPointer(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: _winnerIndex != null
                    ? Text(
                        '🎉 ${items[_winnerIndex!]}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      )
                    : Text(
                        _spinning ? '돌아가는 중...' : ' ',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
              ),
              const Spacer(),
              // TODO: 전면광고 Placeholder + SDK 연동 (다음 단계).
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('홈으로'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _spinning ? null : _spin,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('다시 돌리기'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
