import 'package:flutter/material.dart';

/// 랜덤픽이 지원하는 3가지 모드 (v1.0).
enum GameMode { roulette, ladder, team }

extension GameModeX on GameMode {
  String get title {
    switch (this) {
      case GameMode.roulette:
        return '룰렛';
      case GameMode.ladder:
        return '사다리타기';
      case GameMode.team:
        return '팀나누기';
    }
  }

  String get description {
    switch (this) {
      case GameMode.roulette:
        return '항목을 돌려서 하나만 뽑기';
      case GameMode.ladder:
        return '줄을 타고 결과 정하기';
      case GameMode.team:
        return '인원을 팀으로 나누기';
    }
  }

  IconData get icon {
    switch (this) {
      case GameMode.roulette:
        return Icons.pie_chart_rounded;
      case GameMode.ladder:
        return Icons.stairs_rounded;
      case GameMode.team:
        return Icons.groups_rounded;
    }
  }
}
