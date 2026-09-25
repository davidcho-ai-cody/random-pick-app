import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/recent_use_service.dart';
import '../services/ad_service.dart';
import '../widgets/roulette_wheel.dart';

/// 휠의 12시 방향에 고정된 포인터. 끝의 위치는 당첨 계산과 일치해야 한다.
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

    canvas.drawShadow(path, const Color(0xFF442687), 4, false);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF6744C9)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFE8DFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(
      Offset(size.width / 2, 10),
      5,
      Paint()..color = const Color(0xFFFFD75E),
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
  bool _celebrating = false;
  bool _leaving = false;
  bool _adActionInProgress = false;
  Timer? _celebrationTimer;

  @override
  void initState() {
    super.initState();
    // 결과 화면에 실제 진입한 목록만 한 번 저장한다. 회전은 저장을 기다리지 않는다.
    SharedPreferences.getInstance()
        .then((prefs) => RecentUseService(prefs).saveRoulette(widget.items))
        .catchError((Object _) => false);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(() {
        if (mounted) setState(() => _currentAngle = _rotation.value);
      });
    _controller.addStatusListener((status) {
      if (mounted && status == AnimationStatus.completed) {
        setState(() => _spinning = false);
      }
    });
    // 화면 진입 직후 자동으로 한 번 돌린다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _spin();
    });
  }

  @override
  void dispose() {
    _celebrationTimer?.cancel();
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
      _celebrating = false;
    });
    _celebrationTimer?.cancel();
    _controller
      ..reset()
      ..forward().whenComplete(() {
        if (!mounted || _controller.status != AnimationStatus.completed) return;
        setState(() {
          _winnerIndex = winner;
          _celebrating = true;
        });
        HapticFeedback.lightImpact();
        _celebrationTimer = Timer(const Duration(milliseconds: 750), () {
          if (mounted) setState(() => _celebrating = false);
        });
      });
  }

  void _leave(VoidCallback proceed) {
    if (_leaving) return;
    _leaving = true;
    AdService.showThenProceed(() {
      if (mounted) proceed();
    });
  }

  void _repeatAfterAd() {
    if (_adActionInProgress || _spinning) return;
    _adActionInProgress = true;
    AdService.showThenProceed(() {
      if (!mounted) return;
      _adActionInProgress = false;
      _spin();
    });
  }

  double _normalize(double angle) {
    const twoPi = 2 * pi;
    return ((angle % twoPi) + twoPi) % twoPi;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _leave(() => Navigator.of(context).pop());
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Stack(
          children: [
            const Positioned.fill(
              child: Image(
                image: AssetImage('assets/images/home_background.png'),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () =>
                              _leave(() => Navigator.of(context).pop()),
                          icon: const Icon(Icons.arrow_back_rounded),
                          tooltip: '뒤로가기',
                        ),
                        Expanded(
                          child: Text(
                            '룰렛 결과',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: const Color(0xFF34256C),
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final baseWheelSize = min(
                            min(constraints.maxWidth - 24,
                                constraints.maxHeight * 0.55),
                            320.0,
                          );
                          // 결과 전후에 같은 크기와 위치를 사용해 휠이 튀지 않게 한다.
                          final wheelSize = baseWheelSize;
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight),
                              child: Column(
                                children: [
                                  const SizedBox(height: 12),
                                  Text(
                                    '두근두근 어떤 결과가 나왔을까요?',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: const Color(0xFF615981),
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 22),
                                  Stack(
                                    key: const ValueKey('roulette-wheel-stage'),
                                    clipBehavior: Clip.none,
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: wheelSize,
                                        height: wheelSize,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                                color: Color(0x486750E5),
                                                blurRadius: 26,
                                                spreadRadius: 3,
                                                offset: Offset(0, 10)),
                                          ],
                                        ),
                                        child: Transform.rotate(
                                          angle: _currentAngle,
                                          child: RouletteWheel(
                                              items: items, size: wheelSize),
                                        ),
                                      ),
                                      IgnorePointer(
                                        child: Container(
                                          width: wheelSize,
                                          height: wheelSize,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: const Color(0xFFD7C7FF),
                                                width: 5),
                                          ),
                                        ),
                                      ),
                                      const IgnorePointer(child: _WheelHub()),
                                      const Positioned(
                                          top: -14, child: _WheelPointer()),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  SizedBox(
                                    height: 118,
                                    child: Center(
                                      child: _winnerIndex == null
                                          ? Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 12),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withValues(alpha: 0.9),
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                border: Border.all(
                                                    color: const Color(
                                                        0xFFE2D7FA)),
                                              ),
                                              child: const Text('✨ 두근두근...',
                                                  style: TextStyle(
                                                      color: Color(0xFF5C43B5),
                                                      fontWeight:
                                                          FontWeight.w700)),
                                            )
                                          : Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                TweenAnimationBuilder<double>(
                                                  key: ValueKey(_winnerIndex),
                                                  tween:
                                                      Tween(begin: 0, end: 1),
                                                  duration: const Duration(
                                                      milliseconds: 350),
                                                  curve: Curves.easeOutBack,
                                                  builder:
                                                      (context, value, child) =>
                                                          Opacity(
                                                    opacity:
                                                        value.clamp(0.0, 1.0),
                                                    child: Transform.scale(
                                                        scale:
                                                            0.92 + 0.08 * value,
                                                        child: child),
                                                  ),
                                                  child: _ResultCard(
                                                      winner:
                                                          items[_winnerIndex!]),
                                                ),
                                                Positioned.fill(
                                                  child: IgnorePointer(
                                                    child: AnimatedOpacity(
                                                      opacity: _celebrating
                                                          ? 0.4
                                                          : 0,
                                                      duration: const Duration(
                                                          milliseconds: 300),
                                                      child: Image.asset(
                                                        'assets/images/roulette/result_celebration.png',
                                                        fit: BoxFit.contain,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _leave(() => Navigator.of(context)
                                .popUntil((r) => r.isFirst)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF5C43B5),
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.9),
                              side: const BorderSide(color: Color(0xFFD8C9F4)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18)),
                              minimumSize: const Size(0, 54),
                            ),
                            child: const Text('홈으로',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _spinning || _adActionInProgress
                                ? null
                                : _repeatAfterAd,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF6750E5),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18)),
                              minimumSize: const Size(0, 54),
                            ),
                            child: const Text('다시 돌리기',
                                style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WheelHub extends StatelessWidget {
  const _WheelHub();

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF9F6FF),
          border: Border.all(color: const Color(0xFFD6C7F4), width: 2),
          boxShadow: const [BoxShadow(color: Color(0x446750E5), blurRadius: 8)],
        ),
        child:
            const Icon(Icons.star_rounded, color: Color(0xFFFFC83D), size: 24),
      );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.winner});
  final String winner;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 12, 10, 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD8C9F4)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x246750E5), blurRadius: 18, offset: Offset(0, 8))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('오늘의 선택은',
                      style: TextStyle(
                          color: Color(0xFF615981),
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('🎉 $winner',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF34256C),
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('좋은 하루가 시작될 거예요! 💜',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF615981), fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Image.asset(
              'assets/images/roulette/result_mascot.png',
              width: 76,
              height: 76,
              fit: BoxFit.contain,
            ),
          ],
        ),
      );
}
