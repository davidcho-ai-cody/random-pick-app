import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_mode.dart';
import '../models/ladder_presets.dart';
import '../models/recent_use.dart';
import '../services/recent_use_service.dart';
import '../widgets/input_banner_ad.dart';
import 'ladder_result_screen.dart';

/// 참가자와 결과를 1:1로 입력받는다.
class LadderInputScreen extends StatefulWidget {
  const LadderInputScreen({super.key});

  @override
  State<LadderInputScreen> createState() => _LadderInputScreenState();
}

class _LadderInputScreenState extends State<LadderInputScreen> {
  static const _maxParticipants = 10;
  final _random = Random();
  List<TextEditingController> _nameControllers =
      List.generate(2, (_) => TextEditingController());
  List<TextEditingController> _resultControllers =
      List.generate(2, (_) => TextEditingController());

  @override
  void dispose() {
    for (final controller in [..._nameControllers, ..._resultControllers]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _hasInput => [..._nameControllers, ..._resultControllers]
      .any((controller) => controller.text.trim().isNotEmpty);

  void _replacePairs(List<String> names, List<String> results) {
    FocusScope.of(context).unfocus();
    final previous = [..._nameControllers, ..._resultControllers];
    setState(() {
      _nameControllers =
          names.map((name) => TextEditingController(text: name)).toList();
      _resultControllers =
          results.map((result) => TextEditingController(text: result)).toList();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final controller in previous) {
        controller.dispose();
      }
    });
  }

  Future<bool> _confirmReplace(String message, String action) async {
    if (!_hasInput) return true;
    if (!mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('입력 내용 교체'),
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
  }

  Future<void> _randomFill() async {
    if (!await _confirmReplace('현재 입력 내용을 랜덤 항목으로 바꿀까요?', '바꾸기')) return;
    if (!mounted) return;
    final preset = chooseLadderPreset(_random);
    _replacePairs(preset.participants, preset.results);
  }

  Future<void> _showRecent() async {
    List<RecentUse> entries;
    try {
      final preferences = await SharedPreferences.getInstance();
      entries = RecentUseService(preferences).read(GameMode.ladder);
    } catch (_) {
      entries = [];
    }
    if (!mounted) return;
    final selected = await showModalBottomSheet<RecentUse>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.65,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('최근 사용',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: '닫기',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (entries.isEmpty)
                  const Expanded(
                      child: Center(
                          child: Text('아직 사용한 사다리가 없어요.\n사다리를 한 번 타보세요!',
                              textAlign: TextAlign.center)))
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final date = entry.createdAt.toLocal();
                        final stamp =
                            '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                        return Card(
                          color: Colors.white,
                          elevation: 2,
                          shadowColor: const Color(0x336750E5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(
                                color: Color(0xFFD8D0F2), width: 1.2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('참가자: ${entry.participants.join(' · ')}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text('결과: ${entry.results.join(' · ')}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
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
                                      backgroundColor: const Color(0xFFF0EAFE),
                                      foregroundColor: const Color(0xFF5C43B5),
                                      minimumSize: const Size(72, 40),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      shape: const StadiumBorder(),
                                    ),
                                    child: const Text('불러오기'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    if (!await _confirmReplace('현재 입력 내용을 최근 항목으로 바꿀까요?', '불러오기')) return;
    if (!mounted) return;
    _replacePairs(selected.participants, selected.results);
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
    FocusScope.of(context).unfocus();
    final removed = <TextEditingController>[
      _nameControllers[index],
      _resultControllers[index]
    ];
    setState(() {
      _nameControllers.removeAt(index);
      _resultControllers.removeAt(index);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final controller in removed) {
        controller.dispose();
      }
    });
  }

  void _startLadder() {
    final names =
        _nameControllers.map((controller) => controller.text.trim()).toList();
    final results =
        _resultControllers.map((controller) => controller.text.trim()).toList();
    if (names.any((value) => value.isEmpty) ||
        results.any((value) => value.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('참가자와 결과를 모두 입력해주세요.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LadderResultScreen(participants: names, results: results),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          const Positioned.fill(
              child: Image(
                  image: AssetImage('assets/images/home_background.png'),
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter)),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    children: [
                      Row(
                        children: [
                          IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_rounded),
                              tooltip: '뒤로가기'),
                          Expanded(
                              child: Text('사다리타기',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                          color: const Color(0xFF34256C),
                                          fontWeight: FontWeight.w800))),
                          Image.asset('assets/images/ladder/ladder_header.png',
                              width: 72, height: 72, fit: BoxFit.contain),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('누가 어떤 결과를 만나게 될까요?',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                  color: const Color(0xFF34256C),
                                  fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text('참가자와 결과를 입력해주세요',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: const Color(0xFF615981))),
                      const SizedBox(height: 24),
                      Row(children: [
                        Expanded(
                            child: _QuickAction(
                                label: '랜덤 채우기',
                                image:
                                    'assets/images/roulette/random_fill_icon.png',
                                onTap: _randomFill)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _QuickAction(
                                label: '최근 사용',
                                image:
                                    'assets/images/roulette/recent_history_icon.png',
                                onTap: _showRecent)),
                      ]),
                      const SizedBox(height: 24),
                      const Row(children: [
                        Expanded(
                            child: Text('참가자',
                                style: TextStyle(
                                    color: Color(0xFF615981),
                                    fontWeight: FontWeight.w700))),
                        SizedBox(width: 20),
                        Expanded(
                            child: Text('결과',
                                style: TextStyle(
                                    color: Color(0xFF615981),
                                    fontWeight: FontWeight.w700))),
                        SizedBox(width: 42),
                      ]),
                      const SizedBox(height: 8),
                      for (var index = 0;
                          index < _nameControllers.length;
                          index++) ...[
                        _PairRow(
                          key: ValueKey(_nameControllers[index]),
                          nameController: _nameControllers[index],
                          resultController: _resultControllers[index],
                          index: index,
                          canRemove: _nameControllers.length > 2,
                          onRemove: () => _removeRow(index),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Center(
                          child: TextButton.icon(
                        onPressed: _nameControllers.length < _maxParticipants
                            ? _addRow
                            : null,
                        icon: const Icon(Icons.add_rounded),
                        label: Text(_nameControllers.length < _maxParticipants
                            ? '참가자 추가'
                            : '최대 10명까지 추가할 수 있어요'),
                      )),
                      const SizedBox(height: 16),
                      Center(
                          child: Image.asset(
                              'assets/images/ladder/ladder_cosmic_mascot.png',
                              width: 120,
                              height: 82,
                              fit: BoxFit.contain)),
                    ],
                  ),
                ),
                const InputBannerAd(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _startLadder,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6750E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text('사다리 타기',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Image.asset(image, width: 28, height: 28, fit: BoxFit.contain),
              const SizedBox(width: 6),
              Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF34256C)))),
            ]),
          ),
        ),
      );
}

class _PairRow extends StatelessWidget {
  const _PairRow(
      {super.key,
      required this.nameController,
      required this.resultController,
      required this.index,
      required this.canRemove,
      required this.onRemove});
  final TextEditingController nameController;
  final TextEditingController resultController;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE7DFFF)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x156750E5), blurRadius: 12, offset: Offset(0, 4))
          ],
        ),
        child: Row(children: [
          Expanded(
              child: _PairField(
                  controller: nameController, hint: '참가자 ${index + 1}')),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Icon(Icons.arrow_forward_rounded,
                  size: 18, color: Color(0xFF8066CA))),
          Expanded(
              child: _PairField(
                  controller: resultController, hint: '결과 ${index + 1}')),
          IconButton(
              onPressed: canRemove ? onRemove : null,
              icon: const Icon(Icons.remove_circle_outline_rounded),
              tooltip: '행 삭제'),
        ]),
      );
}

class _PairField extends StatelessWidget {
  const _PairField({required this.controller, required this.hint});
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        textInputAction: TextInputAction.next,
        style: const TextStyle(
            color: Color(0xFF342F45), fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: Color(0xFF9B98A6), fontWeight: FontWeight.w400),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF6750E5), width: 2)),
        ),
      );
}
