import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_mode.dart';
import '../models/roulette_presets.dart';
import '../models/recent_use.dart';
import '../services/recent_use_service.dart';
import 'roulette_result_screen.dart';

class RouletteInputScreen extends StatefulWidget {
  const RouletteInputScreen({super.key});

  @override
  State<RouletteInputScreen> createState() => _RouletteInputScreenState();
}

class _RouletteInputScreenState extends State<RouletteInputScreen> {
  static const _maxItems = 12;
  final _random = Random();
  List<TextEditingController> _controllers =
      List.generate(3, (_) => TextEditingController());

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _hasInput =>
      _controllers.any((controller) => controller.text.trim().isNotEmpty);

  void _replaceItems(List<String> items) {
    final previous = _controllers;
    setState(() {
      _controllers =
          items.map((item) => TextEditingController(text: item)).toList();
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
            title: const Text('입력 항목 교체'),
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
    if (!await _confirmReplace('현재 입력한 항목을 랜덤 항목으로 바꿀까요?', '바꾸기')) return;
    if (!mounted) return;
    _replaceItems(chooseRoulettePreset(_random));
  }

  Future<void> _showRecent() async {
    List<RecentUse> entries;
    try {
      final preferences = await SharedPreferences.getInstance();
      entries = RecentUseService(preferences).read(GameMode.roulette);
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
                Text('최근 사용',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                if (entries.isEmpty)
                  const Expanded(
                      child: Center(
                          child: Text('아직 최근 사용이 없어요\n룰렛을 한 번 돌려보세요.',
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
                              color: Color(0xFFD8D0F2),
                              width: 1.2,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entry.items.join(' · '),
                                    maxLines: 2,
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
                                        backgroundColor:
                                            const Color(0xFFF0EAFE),
                                        foregroundColor:
                                            const Color(0xFF5C43B5),
                                        minimumSize: const Size(72, 40),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        shape: const StadiumBorder(),
                                      ),
                                      child: const Text('불러오기')),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (entries.isEmpty)
                  Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('닫기'))),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    if (!await _confirmReplace('현재 입력한 항목을 최근 항목으로 바꿀까요?', '불러오기')) return;
    if (!mounted) return;
    _replaceItems(selected.items);
  }

  void _addField() {
    if (_controllers.length >= _maxItems) return;
    setState(() => _controllers.add(TextEditingController()));
  }

  void _removeField(int index) {
    if (_controllers.length <= 2) return;
    final removed = _controllers[index];
    setState(() => _controllers.removeAt(index));
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  void _startRoulette() {
    final items = _controllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    if (items.length < 2) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('최소 2개 이상 항목을 입력해주세요.')));
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RouletteResultScreen(items: items)));
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
                              child: Text('룰렛',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                          color: const Color(0xFF34256C),
                                          fontWeight: FontWeight.w800))),
                          Image.asset(
                              'assets/images/roulette/roulette_header.png',
                              width: 72,
                              height: 72,
                              fit: BoxFit.contain),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('오늘은 뭘 뽑아볼까요?',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                  color: const Color(0xFF34256C),
                                  fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text('룰렛에 넣을 항목을 입력해주세요',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: const Color(0xFF615981))),
                      const SizedBox(height: 24),
                      Row(
                        children: [
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
                        ],
                      ),
                      const SizedBox(height: 24),
                      for (var index = 0;
                          index < _controllers.length;
                          index++) ...[
                        _InputRow(
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
                              onPressed: _controllers.length < _maxItems
                                  ? _addField
                                  : null,
                              icon: const Icon(Icons.add_rounded),
                              label: Text(_controllers.length < _maxItems
                                  ? '항목 추가'
                                  : '최대 12개까지 추가할 수 있어요'))),
                      const SizedBox(height: 16),
                      Center(
                          child: Image.asset(
                              'assets/images/roulette/roulette_mascot.png',
                              width: 120,
                              height: 80,
                              fit: BoxFit.contain)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _startRoulette,
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6750E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18))),
                      child: const Text('룰렛 돌리기',
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(image, width: 28, height: 28, fit: BoxFit.contain),
                const SizedBox(width: 6),
                Flexible(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF34256C)))),
              ],
            ),
          ),
        ),
      );
}

class _InputRow extends StatelessWidget {
  const _InputRow(
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
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE7DFFF)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x156750E5), blurRadius: 12, offset: Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: '항목 ${index + 1}',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide:
                          const BorderSide(color: Color(0xFF6750E5), width: 2)),
                ),
              ),
            ),
            IconButton(
                onPressed: canRemove ? onRemove : null,
                icon: const Icon(Icons.remove_circle_outline_rounded),
                tooltip: '항목 삭제'),
            const SizedBox(width: 6),
          ],
        ),
      );
}
