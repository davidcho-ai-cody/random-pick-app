import 'package:flutter/material.dart';

import 'ladder_result_screen.dart';

/// 참가자와 결과를 입력받는 화면. 참가자 수와 결과 수는 항상 1:1로 맞춘다.
class LadderInputScreen extends StatefulWidget {
  const LadderInputScreen({super.key});

  @override
  State<LadderInputScreen> createState() => _LadderInputScreenState();
}

class _LadderInputScreenState extends State<LadderInputScreen> {
  static const _maxParticipants = 10;

  final List<TextEditingController> _nameControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  final List<TextEditingController> _resultControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    for (final c in [..._nameControllers, ..._resultControllers]) {
      c.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    if (_nameControllers.length >= _maxParticipants) return;
    setState(() {
      _nameControllers.add(TextEditingController());
      _resultControllers.add(TextEditingController());
    });
  }

  void _removeRow(int index) {
    if (_nameControllers.length <= 2) return;
    setState(() {
      _nameControllers.removeAt(index).dispose();
      _resultControllers.removeAt(index).dispose();
    });
  }

  void _startLadder() {
    final names = _nameControllers.map((c) => c.text.trim()).toList();
    final results = _resultControllers.map((c) => c.text.trim()).toList();

    if (names.any((v) => v.isEmpty) || results.any((v) => v.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('참가자와 결과를 모두 입력해주세요.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            LadderResultScreen(participants: names, results: results),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('사다리타기')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '참가자와 결과를 입력하세요',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      '참가자',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '결과',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: _nameControllers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameControllers[index],
                            decoration: InputDecoration(
                              hintText: '참가자 ${index + 1}',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _resultControllers[index],
                            decoration: InputDecoration(
                              hintText: '결과 ${index + 1}',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _nameControllers.length > 2
                              ? () => _removeRow(index)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                      ],
                    );
                  },
                ),
              ),
              TextButton.icon(
                onPressed:
                    _nameControllers.length < _maxParticipants ? _addRow : null,
                icon: const Icon(Icons.add),
                label: const Text('참가자 추가'),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _startLadder,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('사다리 타기'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
