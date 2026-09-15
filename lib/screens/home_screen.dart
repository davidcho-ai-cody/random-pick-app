import 'package:flutter/material.dart';

import '../models/game_mode.dart';
import '../widgets/mode_button.dart';
import 'ladder_input_screen.dart';
import 'roulette_input_screen.dart';
import 'team_input_screen.dart';

/// 앱 진입 화면. 3가지 모드 중 하나를 선택하면 입력 화면으로 이동한다.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Text(
                '랜덤픽',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '오늘은 뭘로 정해볼까요?',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            ],
          ),
        ),
      ),
    );
  }
}
