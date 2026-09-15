import 'package:flutter/material.dart';

import '../models/team_split.dart';
import '../widgets/roulette_wheel.dart' show kWheelColors;

/// 참가자를 팀으로 나눈 결과를 보여주는 화면.
class TeamResultScreen extends StatefulWidget {
  const TeamResultScreen({
    super.key,
    required this.participants,
    required this.teamCount,
  });

  final List<String> participants;
  final int teamCount;

  @override
  State<TeamResultScreen> createState() => _TeamResultScreenState();
}

class _TeamResultScreenState extends State<TeamResultScreen> {
  late List<List<String>> _teams;

  @override
  void initState() {
    super.initState();
    _shuffle();
  }

  void _shuffle() {
    setState(() {
      _teams = splitIntoTeams(widget.participants, widget.teamCount);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('팀나누기 결과')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: _teams.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final color = kWheelColors[index % kWheelColors.length];
                    return _TeamCard(
                      teamName: '${index + 1}팀',
                      members: _teams[index],
                      color: color,
                    );
                  },
                ),
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
                      onPressed: _shuffle,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('다시 나누기'),
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

class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.teamName,
    required this.members,
    required this.color,
  });

  final String teamName;
  final List<String> members;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            teamName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final member in members)
                Chip(
                  label: Text(member),
                  backgroundColor: color.withValues(alpha: 0.18),
                  side: BorderSide.none,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
