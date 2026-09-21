import 'package:flutter/material.dart';

import '../models/game_mode.dart';

/// 홈 화면에서 모드를 선택하는 카드형 버튼.
class ModeButton extends StatelessWidget {
  const ModeButton({
    super.key,
    required this.mode,
    required this.onTap,
  });

  final GameMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (image, start, end, ink) = switch (mode) {
      GameMode.roulette => (
          'assets/images/roulette_icon.png',
          const Color(0xFFF0E9FF),
          const Color(0xFFFAF7FF),
          const Color(0xFF6846B8),
        ),
      GameMode.ladder => (
          'assets/images/ladder_icon.png',
          const Color(0xFFFFE9ED),
          const Color(0xFFFFF8F6),
          const Color(0xFFB74F72),
        ),
      GameMode.team => (
          'assets/images/team_icon.png',
          const Color(0xFFE5F3FF),
          const Color(0xFFF6FBFF),
          const Color(0xFF366FAD),
        ),
    };

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [start, end],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Image.asset(image, fit: BoxFit.contain),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: ink,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mode.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF5D5870),
                              height: 1.3,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios_rounded, color: ink, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
