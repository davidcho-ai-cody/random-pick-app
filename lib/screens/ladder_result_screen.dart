import 'package:flutter/material.dart';

import '../models/ladder_board.dart';
import '../widgets/ladder_painter.dart';

/// 사다리를 생성하고, 참가자를 선택하면 해당 경로를 강조해서 보여주는 화면.
class LadderResultScreen extends StatefulWidget {
  const LadderResultScreen({
    super.key,
    required this.participants,
    required this.results,
  });

  final List<String> participants;
  final List<String> results;

  @override
  State<LadderResultScreen> createState() => _LadderResultScreenState();
}

class _LadderResultScreenState extends State<LadderResultScreen> {
  late LadderBoard _board;
  int? _selected;

  @override
  void initState() {
    super.initState();
    _generateBoard();
  }

  void _generateBoard() {
    final columns = widget.participants.length;
    final rows = (columns * 2).clamp(6, 12);
    setState(() {
      _board = LadderBoard(columns: columns, rows: rows);
      _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final path = _selected != null ? _board.pathFrom(_selected!) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('사다리타기 결과')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              SizedBox(
                height: 28,
                child: Text(
                  _selected == null
                      ? '참가자를 눌러 결과를 확인하세요'
                      : '${widget.participants[_selected!]} → '
                          '${widget.results[_board.finalColumnFrom(_selected!)]}',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              _LabelRow(
                labels: widget.participants,
                selected: _selected,
                onTap: (i) => setState(() => _selected = i),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: LadderPainter(
                      board: _board,
                      highlightPath: path,
                      lineColor: colorScheme.outlineVariant,
                      highlightColor: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              _LabelRow(
                labels: widget.results,
                selected:
                    _selected != null ? _board.finalColumnFrom(_selected!) : null,
                onTap: null,
              ),
              const SizedBox(height: 16),
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
