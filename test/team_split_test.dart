import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:random_pick/models/team_split.dart';

void main() {
  test('모든 참가자가 정확히 한 팀에 배정된다', () {
    final participants =
        List.generate(11, (i) => '참가자$i');
    final teams = splitIntoTeams(participants, 3, random: Random(7));

    expect(teams.length, 3);
    expect(teams.expand((t) => t).toSet(), participants.toSet());
    expect(teams.expand((t) => t).length, participants.length);
  });

  test('팀별 인원 차이는 최대 1명이다', () {
    final participants = List.generate(10, (i) => 'p$i');
    final teams = splitIntoTeams(participants, 3, random: Random(3));

    final sizes = teams.map((t) => t.length).toList();
    expect(sizes.reduce(max) - sizes.reduce(min), lessThanOrEqualTo(1));
  });
}
