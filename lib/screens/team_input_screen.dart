import 'package:flutter/material.dart';

import 'team_result_screen.dart';

/// 참가자 목록과 팀 개수를 입력받는 화면.
class TeamInputScreen extends StatefulWidget {
  const TeamInputScreen({super.key});

  @override
  State<TeamInputScreen> createState() => _TeamInputScreenState();
}

class _TeamInputScreenState extends State<TeamInputScreen> {
  static const _maxParticipants = 20;
  static const _minTeamCount = 2;
  static const _maxTeamCount = 8;

  final List<TextEditingController> _controllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  int _teamCount = 2;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addField() {
    if (_controllers.length >= _maxParticipants) return;
    setState(() => _controllers.add(TextEditingController()));
  }

  void _removeField(int index) {
    if (_controllers.length <= 2) return;
    setState(() => _controllers.removeAt(index).dispose());
  }

  void _changeTeamCount(int delta) {
    setState(() {
      _teamCount = (_teamCount + delta).clamp(_minTeamCount, _maxTeamCount);
    });
  }

  void _startTeamSplit() {
    final participants = _controllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (participants.length < _teamCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('참가자가 최소 $_teamCount명 이상이어야 합니다.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeamResultScreen(
          participants: participants,
          teamCount: _teamCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('팀나누기')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '참가자를 입력하세요',
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
                              hintText: '참가자 ${index + 1}',
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
                    _controllers.length < _maxParticipants ? _addField : null,
                icon: const Icon(Icons.add),
                label: const Text('참가자 추가'),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '팀 개수',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _teamCount > _minTeamCount
                            ? () => _changeTeamCount(-1)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$_teamCount',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        onPressed: _teamCount < _maxTeamCount
                            ? () => _changeTeamCount(1)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _startTeamSplit,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('팀 나누기'),
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
