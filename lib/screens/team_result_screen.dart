import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/team_split.dart';
import '../services/ad_service.dart';
import '../services/recent_use_service.dart';

const _teamPalette = <Color>[
  Color(0xFF7555D9),
  Color(0xFFE86F8D),
  Color(0xFFE6A13A),
  Color(0xFF43A886),
  Color(0xFF4E91D9),
  Color(0xFF9168D9),
  Color(0xFFE98252),
  Color(0xFF2C9FA5),
];

/// 참가자를 팀으로 나눈 결과를 한 명씩 공개하는 화면.
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
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _shuffle();
    SharedPreferences.getInstance()
        .then((prefs) => RecentUseService(prefs)
            .saveTeam(widget.participants, widget.teamCount))
        .catchError((Object _) => false);
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

  /// 기존 라운드로빈 공개 순서를 유지하면서 공개 간격만 조정한다.
  Future<void> _runReveal() async {
    var maxSize = 0;
    for (final team in _teams) {
      if (team.length > maxSize) maxSize = team.length;
    }
    for (var round = 0; round < maxSize; round++) {
      for (var teamIndex = 0; teamIndex < _teams.length; teamIndex++) {
        if (round >= _teams[teamIndex].length) continue;
        await Future.delayed(const Duration(milliseconds: 560));
        if (!mounted) return;
        setState(() => _revealedCounts[teamIndex]++);
      }
    }
    if (mounted) setState(() => _revealing = false);
  }

  void _leave(VoidCallback action) {
    if (_leaving) return;
    _leaving = true;
    AdService.showThenProceed(() {
      if (!mounted) return;
      action();
    });
  }

  @override
  Widget build(BuildContext context) {
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
          SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 24, 4),
                child: SizedBox(
                  height: 52,
                  child: Row(children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: '뒤로가기',
                      color: const Color(0xFF34256C),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text('팀나누기 결과',
                          style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF34256C))),
                    ),
                  ]),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  _revealing ? '두근두근, 팀을 공개할게요!' : '팀 나누기 완료! 🎉',
                  key: ValueKey(_revealing),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4C358D)),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 2, 24, 12),
                  itemCount: _teams.length + (_revealing ? 0 : 1),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == _teams.length) {
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) => Opacity(
                          opacity: value,
                          child: Transform.scale(
                              scale: 0.94 + value * 0.06, child: child),
                        ),
                        child: SizedBox(
                          height: 116,
                          child: Image.asset(
                            'assets/images/team/team_result_mascot.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    }
                    return _TeamCard(
                      key: ValueKey('team-card-$index'),
                      teamName: '${index + 1}팀',
                      members: _teams[index],
                      revealedCount: _revealedCounts[index],
                      color: _teamPalette[index % _teamPalette.length],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: SizedBox(
                  height: 56,
                  child: Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _leave(() => Navigator.of(context)
                            .popUntil((route) => route.isFirst)),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.92),
                          foregroundColor: const Color(0xFF5C43B5),
                          side: const BorderSide(color: Color(0xFFCFC2F5)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17)),
                        ),
                        child: const Text('홈으로',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _revealing ? null : _shuffle,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6750E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17)),
                        ),
                        child: const Text('다시 나누기',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({
    super.key,
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
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Color.alphaBlend(color.withValues(alpha: 0.11),
              Colors.white.withValues(alpha: 0.92)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.38), width: 1.2),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.13),
                blurRadius: 14,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(teamName,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) => ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: _reservedPillAreaHeight(
                    context, members, constraints.maxWidth),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var memberIndex = 0;
                      memberIndex < members.length;
                      memberIndex++)
                    _MemberChip(
                      key: ValueKey('${teamName}_member_$memberIndex'),
                      label: members[memberIndex],
                      color: color,
                      revealed: memberIndex < revealedCount,
                    ),
                ],
              ),
            ),
          ),
        ]),
      );

  double _reservedPillAreaHeight(
      BuildContext context, List<String> labels, double availableWidth) {
    const spacing = 8.0;
    const pillHeight = 38.0;
    final maxLabelWidth =
        (MediaQuery.sizeOf(context).width - 112).clamp(96.0, 240.0);
    var lines = 1;
    var usedWidth = 0.0;
    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        maxLines: 1,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: maxLabelWidth);
      final pillWidth = painter.width + 26;
      final nextWidth =
          usedWidth == 0 ? pillWidth : usedWidth + spacing + pillWidth;
      if (usedWidth > 0 && nextWidth > availableWidth) {
        lines++;
        usedWidth = pillWidth;
      } else {
        usedWidth = nextWidth;
      }
    }
    return lines * pillHeight + (lines - 1) * spacing;
  }
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({
    super.key,
    required this.label,
    required this.color,
    required this.revealed,
  });
  final String label;
  final Color color;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    final maxLabelWidth =
        (MediaQuery.sizeOf(context).width - 112).clamp(96.0, 240.0);
    final labelText = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
          color: Color(0xFF34256C), fontWeight: FontWeight.w700),
    );
    if (!revealed) {
      return Container(
        width: 48,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 7)
          ],
        ),
        child: Text('?',
            style: TextStyle(
                color: color.withValues(alpha: 0.58),
                fontWeight: FontWeight.w800)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxLabelWidth),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            final opacity = value.clamp(0.0, 1.0);
            final sparkleOpacity =
                (4 * opacity * (1 - opacity)).clamp(0.0, 1.0);
            return Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: value,
                child: Stack(alignment: Alignment.center, children: [
                  child!,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: sparkleOpacity,
                        child: Image.asset(
                          'assets/images/team/team_reveal_sparkle.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            );
          },
          child: labelText,
        ),
      ),
    );
  }
}
