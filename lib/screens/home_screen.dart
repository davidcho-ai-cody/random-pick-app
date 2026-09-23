import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_mode.dart';
import '../widgets/mode_button.dart';
import 'ladder_input_screen.dart';
import 'roulette_input_screen.dart';
import 'team_input_screen.dart';

/// 앱 진입 화면. 3가지 모드 중 하나를 선택하면 입력 화면으로 이동한다.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onExit,
  });

  final Future<void> Function()? onExit;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _exitDialogOpen = false;

  void _selectMode(BuildContext context, GameMode mode) {
    final screen = switch (mode) {
      GameMode.roulette => const RouletteInputScreen(),
      GameMode.ladder => const LadderInputScreen(),
      GameMode.team => const TeamInputScreen(),
    };
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<void> _requestExit() async {
    if (_exitDialogOpen) {
      return;
    }

    _exitDialogOpen = true;
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('랜덤픽을 종료할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('종료'),
          ),
        ],
      ),
    );
    _exitDialogOpen = false;

    if (shouldExit == true) {
      await (widget.onExit ?? SystemNavigator.pop)();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _requestExit();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(
              child: Image(
                image: AssetImage('assets/images/home_background.png'),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '랜덤픽',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  color: const Color(0xFF34256C),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: _requestExit,
                          tooltip: '앱 종료',
                          color: const Color(0xFF615981),
                          icon: const Icon(Icons.power_settings_new_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '오늘은 뭘로 정해볼까요?',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF615981),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 36),
                    for (final mode in GameMode.values) ...[
                      ModeButton(
                        mode: mode,
                        onTap: () => _selectMode(context, mode),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 8),
                    Center(
                      child: Image.asset(
                        'assets/images/home_mascot.png',
                        width: 112,
                        height: 116,
                        fit: BoxFit.contain,
                        semanticLabel: '랜덤픽 마스코트',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
