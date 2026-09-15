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
  late List<int> _revealedCounts;
  bool _revealing = false;

  @override
  void initState() {
    super.initState();
    _shuffle();
  }

  void _shuffle() {
    final teams = splitIntoTeams(widget.participants, widget.teamCount);
    setState(() {
      _teams = teams;
      _revealedCounts = List.filled(teams.length, 0);
      _revealing = true;
    });
    _runReveal();
  }

  /// 팀별로 한 명씩 번갈아(라운드로빈) 공개해서 긴장감을 준다.
  Future<void> _runReveal() async {
    var maxSize = 0;
    for (final team in _teams) {
      if (team.length > maxSize) maxSize = team.length;
    }

    for (var round = 0; round < maxSize; round++) {
      for (var i = 0; i < _teams.length; i++) {
        if (round >= _teams[i].length) continue;
        await Future.delayed(const Duration(milliseconds: 450));
        if (!mounted) return;
        setState(() => _revealedCounts[i]++);
      }
    }
    if (mounted) setState(() => _revealing = false);
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
                      revealedCount: _revealedCounts[index],
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
                      onPressed: _revealing ? null : _shuffle,
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
    required this.revealedCount,
    required this.color,
  });

  final String teamName;
  final List<String> members;
  final int revealedCount;
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
              for (var i = 0; i < members.length; i++)
                if (i < revealedCount)
                  _RevealedChip(
                    key: ValueKey(members[i]),
                    label: members[i],
                    color: color,
                  )
                else
                  _PlaceholderChip(color: color),
            ],
          ),
        ],
      ),
    );
  }
}

/// 새로 공개되는 멤버가 톡 튀어나오는 느낌을 주는 팝인 애니메이션.
class _RevealedChip extends StatelessWidget {
  const _RevealedChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.scale(scale: t, child: child),
        );
      },
      child: Chip(
        label: Text(label),
        backgroundColor: color.withValues(alpha: 0.18),
        side: BorderSide.none,
      ),
    );
  }
}

/// 아직 공개되지 않은 자리. 몇 명이 남았는지는 보이되 누군지는 숨긴다.
class _PlaceholderChip extends StatelessWidget {
  const _PlaceholderChip({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('?', style: TextStyle(color: color.withValues(alpha: 0.5))),
      backgroundColor: color.withValues(alpha: 0.06),
      side: BorderSide(color: color.withValues(alpha: 0.25)),
    );
  }
}
