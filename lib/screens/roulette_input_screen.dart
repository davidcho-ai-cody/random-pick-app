import 'package:flutter/material.dart';

import 'roulette_result_screen.dart';

/// 룰렛에 넣을 항목을 입력받는 화면. 최소 2개 이상 입력해야 진행할 수 있다.
class RouletteInputScreen extends StatefulWidget {
  const RouletteInputScreen({super.key});

  @override
  State<RouletteInputScreen> createState() => _RouletteInputScreenState();
}

class _RouletteInputScreenState extends State<RouletteInputScreen> {
  static const _maxItems = 12;

  final List<TextEditingController> _controllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addField() {
    if (_controllers.length >= _maxItems) return;
    setState(() => _controllers.add(TextEditingController()));
  }

  void _removeField(int index) {
    if (_controllers.length <= 2) return;
    setState(() => _controllers.removeAt(index).dispose());
  }

  void _startRoulette() {
    final items = _controllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (items.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 2개 이상 항목을 입력해주세요.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RouletteResultScreen(items: items)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('룰렛')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '룰렛에 넣을 항목을 입력하세요',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _controllers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controllers[index],
                            decoration: InputDecoration(
                              hintText: '항목 ${index + 1}',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _controllers.length > 2
                              ? () => _removeField(index)
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
                    _controllers.length < _maxItems ? _addField : null,
                icon: const Icon(Icons.add),
                label: const Text('항목 추가'),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _startRoulette,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('룰렛 돌리기'),
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
