import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_mode.dart';
import '../models/recent_use.dart';
import '../models/team_presets.dart';
import '../services/recent_use_service.dart';
import 'team_result_screen.dart';

class TeamInputScreen extends StatefulWidget {
  const TeamInputScreen({super.key});
  @override
  State<TeamInputScreen> createState() => _TeamInputScreenState();
}

class _TeamInputScreenState extends State<TeamInputScreen> {
  static const _maxNameLength = 8;
  static const _maxParticipants = 20;
  static const _minTeamCount = 2;
  static const _maxTeamCount = 8;
  final Random _random = Random();
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  int _teamCount = 2;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addField() {
    if (_controllers.length < _maxParticipants) {
      setState(() => _controllers.add(TextEditingController()));
    }
  }

  void _removeField(int index) {
    if (_controllers.length <= 2) return;
    FocusScope.of(context).unfocus();
    final removed = _controllers[index];
    setState(() {
      _controllers.removeAt(index);
      _teamCount = _teamCount.clamp(
          _minTeamCount, min(_maxTeamCount, _controllers.length));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  void _changeTeamCount(int delta) => setState(() {
        _teamCount = (_teamCount + delta).clamp(_minTeamCount, _maxTeamCount);
      });

  bool get _hasInput =>
      _controllers.any((controller) => controller.text.trim().isNotEmpty);

  Future<bool> _confirmReplace(String message, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('입력 내용 바꾸기'),
          content: Text(message),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(action)),
          ],
        ),
      ) ??
      false;

  void _replaceParticipants(List<String> participants, int teamCount) {
    FocusScope.of(context).unfocus();
    final old = List<TextEditingController>.of(_controllers);
    setState(() {
      _controllers
        ..clear()
        ..addAll(participants
            .map((name) => TextEditingController(text: _truncateName(name))));
      _teamCount = teamCount.clamp(
          _minTeamCount, min(_maxTeamCount, participants.length));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final controller in old) {
        controller.dispose();
      }
    });
  }

  String _truncateName(String name) =>
      name.characters.take(_maxNameLength).toString();

  Future<void> _randomFill() async {
    if (_hasInput && !await _confirmReplace('현재 입력 내용을 랜덤 참가자로 바꿀까요?', '바꾸기')) {
      return;
    }
    if (!mounted) return;
    _replaceParticipants(chooseTeamPreset(_random), _teamCount);
  }

  Future<void> _showRecent() async {
    List<RecentUse> entries;
    try {
      final prefs = await SharedPreferences.getInstance();
      entries = RecentUseService(prefs).read(GameMode.team);
    } catch (_) {
      entries = [];
    }
    if (!mounted) return;
    final selected = await showModalBottomSheet<RecentUse>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _RecentTeamSheet(entries: entries),
    );
    if (selected == null || !mounted) return;
    if (_hasInput &&
        !await _confirmReplace('현재 입력 내용을 최근 항목으로 바꿀까요?', '불러오기')) {
      return;
    }
    if (mounted) {
      _replaceParticipants(selected.participants, selected.teamCount!);
    }
  }

  void _startTeamSplit() {
    final participants = _controllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    if (participants.length < _teamCount) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('참가자가 최소 $_teamCount명 이상이어야 합니다.')));
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          TeamResultScreen(participants: participants, teamCount: _teamCount),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                children: [
                  Row(children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: '뒤로가기',
                      color: const Color(0xFF34256C),
                    ),
                    const Expanded(
                      child: Text('팀나누기',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF34256C))),
                    ),
                  ]),
                  Center(
                    child: Image.asset('assets/images/team/team_header.png',
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 10),
                  const Text('누구와 한 팀이 될까요?',
                      style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF34256C))),
                  const SizedBox(height: 6),
                  const Text('참가자와 팀 개수를 정해주세요',
                      style: TextStyle(fontSize: 16, color: Color(0xFF615981))),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(
                      child: _QuickAction(
                          label: '랜덤 채우기',
                          image: 'assets/images/roulette/random_fill_icon.png',
                          onTap: _randomFill),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                          label: '최근 사용',
                          image:
                              'assets/images/roulette/recent_history_icon.png',
                          onTap: _showRecent),
                    ),
                  ]),
                  const SizedBox(height: 22),
                  for (var index = 0; index < _controllers.length; index++) ...[
                    _ParticipantField(
                      key: ValueKey(_controllers[index]),
                      controller: _controllers[index],
                      index: index,
                      canRemove: _controllers.length > 2,
                      onRemove: () => _removeField(index),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Center(
                    child: TextButton.icon(
                      onPressed: _controllers.length < _maxParticipants
                          ? _addField
                          : null,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(_controllers.length < _maxParticipants
                          ? '참가자 추가'
                          : '최대 20명까지 추가할 수 있어요'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _TeamCountCard(
                    teamCount: _teamCount,
                    onDecrease: _teamCount > _minTeamCount
                        ? () => _changeTeamCount(-1)
                        : null,
                    onIncrease: _teamCount < _maxTeamCount
                        ? () => _changeTeamCount(1)
                        : null,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _startTeamSplit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6750E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text('팀 나누기',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.label, required this.image, required this.onTap});
  final String label;
  final String image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Image.asset(image, width: 28, height: 28),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: Color(0xFF34256C))),
              ),
            ]),
          ),
        ),
      );
}

class _ParticipantField extends StatelessWidget {
  const _ParticipantField(
      {super.key,
      required this.controller,
      required this.index,
      required this.canRemove,
      required this.onRemove});
  final TextEditingController controller;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.only(left: 14, right: 4),
        decoration: _cardDecoration(),
        child: Row(children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: Color(0xFFF0EAFE), shape: BoxShape.circle),
            child: Text('${index + 1}',
                style: const TextStyle(
                    color: Color(0xFF6750E5), fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              inputFormatters: [LengthLimitingTextInputFormatter(8)],
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: '참가자 ${index + 1}',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 17),
                border: InputBorder.none,
                focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6750E5), width: 2)),
              ),
            ),
          ),
          IconButton(
              onPressed: canRemove ? onRemove : null,
              icon: const Icon(Icons.remove_circle_outline_rounded),
              tooltip: '참가자 삭제'),
        ]),
      );
}

class _TeamCountCard extends StatelessWidget {
  const _TeamCountCard(
      {required this.teamCount,
      required this.onDecrease,
      required this.onIncrease});
  final int teamCount;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 8, 10),
        decoration: _cardDecoration(),
        child: Row(children: [
          const Expanded(
            child: Text('팀 개수',
                style: TextStyle(
                    color: Color(0xFF34256C), fontWeight: FontWeight.w800)),
          ),
          IconButton(
              onPressed: onDecrease,
              icon: const Icon(Icons.remove_circle_outline_rounded),
              tooltip: '팀 수 줄이기'),
          SizedBox(
            width: 32,
            child: Text('$teamCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4C358D))),
          ),
          IconButton(
              onPressed: onIncrease,
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: '팀 수 늘리기'),
        ]),
      );
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white.withValues(alpha: 0.91),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE1D8F8)),
      boxShadow: const [
        BoxShadow(
            color: Color(0x146750E5), blurRadius: 12, offset: Offset(0, 4))
      ],
    );

class _RecentTeamSheet extends StatelessWidget {
  const _RecentTeamSheet({required this.entries});
  final List<RecentUse> entries;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.65,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text('최근 사용',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF34256C))),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: '닫기',
                ),
              ]),
              const SizedBox(height: 16),
              if (entries.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('아직 사용한 팀 구성이 없어요.\n팀을 한 번 나눠보세요!',
                        textAlign: TextAlign.center),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final date = entry.createdAt.toLocal();
                      final stamp =
                          '${date.year}.${date.month.toString().padLeft(2, '0')}.'
                          '${date.day.toString().padLeft(2, '0')} '
                          '${date.hour.toString().padLeft(2, '0')}:'
                          '${date.minute.toString().padLeft(2, '0')}';
                      return Card(
                        color: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: Color(0xFFD8D0F2))),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('참가자: ${entry.participants.join(' · ')}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text('팀 개수: ${entry.teamCount}팀'),
                                const SizedBox(height: 4),
                                Text(stamp,
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, entry),
                                    style: TextButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFF0EAFE),
                                        foregroundColor:
                                            const Color(0xFF5C43B5),
                                        shape: const StadiumBorder()),
                                    child: const Text('불러오기'),
                                  ),
                                ),
                              ]),
                        ),
                      );
                    },
                  ),
                ),
            ]),
          ),
        ),
      );
}
