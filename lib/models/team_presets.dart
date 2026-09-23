import 'dart:math';

const teamPresets = <List<String>>[
  ['철수', '영희', '민수', '지수'],
  ['서준', '서연', '도윤', '하윤', '시우', '지우'],
  ['민준', '서아', '예준', '수아', '주원', '하은', '지호', '윤서'],
];

List<String> chooseTeamPreset(Random random) =>
    List.of(teamPresets[random.nextInt(teamPresets.length)]);
