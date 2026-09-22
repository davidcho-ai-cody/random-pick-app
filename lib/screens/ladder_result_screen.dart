import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ladder_board.dart';
import '../services/ad_service.dart';
import '../services/recent_use_service.dart';
import '../widgets/ladder_painter.dart';

/// 사다리를 생성하고, 참가자를 선택하면 해당 경로를 강조해서 보여주는 화면.
class LadderResultScreen extends StatefulWidget {
  const LadderResultScreen({
    super.key,
    required this.participants,
    required this.results,
    this.showAdThenProceed,
  });

  final List<String> participants;
  final List<String> results;

  /// Allows the exit advertisement call to be observed in widget tests.
  final void Function(VoidCallback proceed)? showAdThenProceed;

  @override
  State<LadderResultScreen> createState() => _LadderResultScreenState();
}

class _LadderResultScreenState extends State<LadderResultScreen>
    with SingleTickerProviderStateMixin {
  late LadderBoard _board;
  int? _selected;
  bool _hasUsedLadder = false;
  bool _leaving = false;
  bool _celebrating = false;
  Timer? _celebrationTimer;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _controller.addStatusListener((status) {
      if (!mounted || status != AnimationStatus.completed) return;
      setState(() => _celebrating = true);
      HapticFeedback.lightImpact();
      _celebrationTimer?.cancel();
      _celebrationTimer = Timer(const Duration(milliseconds: 750), () {
        if (mounted) setState(() => _celebrating = false);
      });
    });
    _generateBoard();
  }

  @override
  void dispose() {
    _celebrationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _generateBoard() {
    final columns = widget.participants.length;
    final rows = (columns * 4).clamp(12, 20);
    setState(() {
      _board = LadderBoard(columns: columns, rows: rows);
      _selected = null;
      _celebrating = false;
    });
    _celebrationTimer?.cancel();
  }

  void _select(int index) {
    _celebrationTimer?.cancel();
    if (!_hasUsedLadder) {
      _hasUsedLadder = true;
      // 첫 경로 실행만 기록한다. 저장은 애니메이션을 기다리게 하지 않는다.
      SharedPreferences.getInstance()
          .then((prefs) => RecentUseService(prefs)
              .saveLadder(widget.participants, widget.results))
          .catchError((Object _) => false);
    }
    setState(() {
      _selected = index;
      _celebrating = false;
    });
    _controller.forward(from: 0);
  }

  void _leave(VoidCallback proceed) {
    if (_leaving) return;
    _leaving = true;
    if (!_hasUsedLadder) {
      proceed();
      return;
    }
    void safeProceed() {
      if (mounted) proceed();
    }

    final handler = widget.showAdThenProceed;
    if (handler != null) {
      handler(safeProceed);
    } else {
      AdService.showThenProceed(safeProceed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = _selected != null ? _board.pathFrom(_selected!) : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _leave(() => Navigator.of(context).pop());
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Stack(children: [
          const Positioned.fill(
            child: Image(
              image: AssetImage('assets/images/home_background.png'),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          SafeArea(child: LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxHeight < 650;
            final edge = compact ? 16.0 : 24.0;
            final gap = compact ? 7.0 : 12.0;
            final mascotHeight =
                (constraints.maxHeight * 0.105).clamp(48.0, 78.0);
            final count = widget.participants.length;
            return Padding(
              padding: EdgeInsets.fromLTRB(edge, 4, edge, compact ? 8 : 12),
              child: Column(children: [
                SizedBox(
                  height: compact ? 48 : 56,
                  child: Row(children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: '뒤로가기',
                      color: const Color(0xFF34256C),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                        child: Text('사다리타기 결과',
                            style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF34256C)))),
                  ]),
                ),
                SizedBox(height: gap),
                SizedBox(
                    height: compact ? 84 : 100,
                    child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          final revealed =
                              _selected != null && _controller.value >= 1;
                          if (_selected == null) {
                            return const _StatusText(
                              title: '누가 어디로 갈까요?',
                              subtitle: '참가자를 눌러 결과를 확인해보세요',
                            );
                          }
                          if (!revealed) {
                            return _StatusText(
                              title:
                                  '✨ ${widget.participants[_selected!]}의 길을 따라가는 중...',
                            );
                          }
                          final result = widget
                              .results[_board.finalColumnFrom(_selected!)];
                          return TweenAnimationBuilder<double>(
                            key: ValueKey(_selected),
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            builder: (context, appear, child) => Opacity(
                              opacity: appear,
                              child: Transform.scale(
                                  scale: 0.94 + 0.06 * appear, child: child),
                            ),
                            child: Stack(clipBehavior: Clip.none, children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.93),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                      color: const Color(0xFFDCD0FF)),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Color(0x296750E5),
                                        blurRadius: 18,
                                        offset: Offset(0, 5))
                                  ],
                                ),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                          '${widget.participants[_selected!]} → $result',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: Color(0xFF432A95),
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 3),
                                      const Text('결과가 나왔어요! ✨',
                                          style: TextStyle(
                                              color: Color(0xFF615981),
                                              fontSize: 13)),
                                    ]),
                              ),
                              if (_celebrating)
                                Positioned(
                                    right: -6,
                                    top: -18,
                                    child: IgnorePointer(
                                        child: Image.asset(
                                            'assets/images/ladder/ladder_result_sparkle.png',
                                            width: 52,
                                            height: 52,
                                            fit: BoxFit.contain))),
                            ]),
                          );
                        })),
                SizedBox(height: gap),
                _LabelRow(
                    labels: widget.participants,
                    selected: _selected,
                    onTap: _select,
                    count: count),
                SizedBox(height: gap),
                Expanded(
                    child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.70),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0x80DDD4F7)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        return CustomPaint(
                            size: Size.infinite,
                            painter: LadderPainter(
                              board: _board,
                              highlightPath: path,
                              highlightProgress: path == null
                                  ? null
                                  : _controller.value * (path.length - 1),
                              lineColor: const Color(0xFF9B8BC7),
                              highlightColor: const Color(0xFF6943DC),
                            ));
                      }),
                )),
                SizedBox(height: gap),
                AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final revealed =
                          _selected != null && _controller.value >= 1;
                      return _LabelRow(
                          labels: widget.results,
                          selected: revealed
                              ? _board.finalColumnFrom(_selected!)
                              : null,
                          onTap: null,
                          count: count);
                    }),
                SizedBox(height: compact ? 4 : 6),
                SizedBox(
                    height: mascotHeight,
                    child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          final revealed =
                              _selected != null && _controller.value >= 1;
                          return revealed
                              ? Image.asset(
                                  'assets/images/ladder/ladder_result_mascot.png',
                                  height: mascotHeight,
                                  fit: BoxFit.contain,
                                )
                              : const SizedBox.shrink();
                        })),
                SizedBox(height: compact ? 4 : 8),
                SizedBox(
                    height: compact ? 50 : 56,
                    child: Row(children: [
                      Expanded(
                          child: OutlinedButton(
                        onPressed: () => _leave(() =>
                            Navigator.of(context).popUntil((r) => r.isFirst)),
                        style: OutlinedButton.styleFrom(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.92),
                            foregroundColor: const Color(0xFF5C43B5),
                            side: const BorderSide(color: Color(0xFFCFC2F5)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(17))),
                        child: const Text('홈으로',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                      )),
                      const SizedBox(width: 10),
                      Expanded(
                          child: FilledButton(
                        onPressed: _generateBoard,
                        style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF6750E5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(17))),
                        child: const Text('다시 섞기',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                      )),
                    ])),
              ]),
            );
          })),
        ]),
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  const _StatusText({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFF34256C),
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF615981), fontSize: 13)),
          ],
        ],
      );
}

class _LabelRow extends StatelessWidget {
  const _LabelRow({
    required this.labels,
    required this.selected,
    required this.onTap,
    required this.count,
  });

  final List<String> labels;
  final int? selected;
  final ValueChanged<int>? onTap;
  final int count;

  @override
  Widget build(BuildContext context) {
    final fontSize = count >= 8
        ? 11.0
        : count >= 5
            ? 12.0
            : 14.0;
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: onTap != null ? () => onTap!(i) : null,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: count >= 8 ? 38 : 44,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
                decoration: BoxDecoration(
                  color: selected == i
                      ? const Color(0xFFE1D5FF)
                      : Colors.white.withValues(alpha: 0.9),
                  border: Border.all(
                      color: selected == i
                          ? const Color(0xFF7755DA)
                          : const Color(0xFFDCD5EE),
                      width: selected == i ? 1.8 : 1),
                  boxShadow: selected == i
                      ? const [
                          BoxShadow(
                              color: Color(0x406750E5),
                              blurRadius: 10,
                              offset: Offset(0, 3))
                        ]
                      : null,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: const Color(0xFF34256C),
                    fontWeight:
                        selected == i ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
