import 'package:flutter/material.dart';
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
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _generateBoard();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generateBoard() {
    final columns = widget.participants.length;
    final rows = (columns * 4).clamp(12, 20);
    setState(() {
      _board = LadderBoard(columns: columns, rows: rows);
      _selected = null;
    });
  }

  void _select(int index) {
    if (!_hasUsedLadder) {
      _hasUsedLadder = true;
      // 첫 경로 실행만 기록한다. 저장은 애니메이션을 기다리게 하지 않는다.
      SharedPreferences.getInstance()
          .then((prefs) => RecentUseService(prefs)
              .saveLadder(widget.participants, widget.results))
          .catchError((Object _) => false);
    }
    setState(() => _selected = index);
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
    final colorScheme = Theme.of(context).colorScheme;
    final path = _selected != null ? _board.pathFrom(_selected!) : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _leave(() => Navigator.of(context).pop());
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('사다리타기 결과')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final revealed =
                        _selected != null && _controller.value >= 1;
                    return SizedBox(
                      height: 28,
                      child: Text(
                        _selected == null
                            ? '참가자를 눌러 결과를 확인하세요'
                            : revealed
                                ? '${widget.participants[_selected!]} → '
                                    '${widget.results[_board.finalColumnFrom(_selected!)]}'
                                : '내려가는 중...',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _LabelRow(
                  labels: widget.participants,
                  selected: _selected,
                  onTap: _select,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
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
                            lineColor: colorScheme.outlineVariant,
                            highlightColor: colorScheme.primary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final revealed =
                        _selected != null && _controller.value >= 1;
                    return _LabelRow(
                      labels: widget.results,
                      selected:
                          revealed ? _board.finalColumnFrom(_selected!) : null,
                      onTap: null,
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _leave(
                          () =>
                              Navigator.of(context).popUntil((r) => r.isFirst),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text('홈으로'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _generateBoard,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text('다시 섞기'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LabelRow extends StatelessWidget {
  const _LabelRow({
    required this.labels,
    required this.selected,
    required this.onTap,
  });

  final List<String> labels;
  final int? selected;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: onTap != null ? () => onTap!(i) : null,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: selected == i ? colorScheme.primaryContainer : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
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
