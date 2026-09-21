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
                  Text(
                    '랜덤픽',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: const Color(0xFF34256C),
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
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
    );
  }
}
