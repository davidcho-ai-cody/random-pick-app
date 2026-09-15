import 'dart:math';

/// 참가자를 [teamCount]개의 팀으로 최대한 균등하게 무작위 배분한다.
/// 섞은 뒤 순서대로 나눠 담으므로 팀별 인원 차이는 최대 1명이다.
List<List<String>> splitIntoTeams(
  List<String> participants,
  int teamCount, {
  Random? random,
}) {
  assert(teamCount >= 2);
  assert(participants.length >= teamCount);

  final shuffled = [...participants]..shuffle(random ?? Random());
  final teams = List.generate(teamCount, (_) => <String>[]);
  for (var i = 0; i < shuffled.length; i++) {
    teams[i % teamCount].add(shuffled[i]);
  }
  return teams;
}
