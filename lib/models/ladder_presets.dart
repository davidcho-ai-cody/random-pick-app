import 'dart:math';

class LadderPreset {
  const LadderPreset(this.participants, this.results);
  final List<String> participants;
  final List<String> results;
}

const ladderPresets = <LadderPreset>[
  LadderPreset(['민수', '지훈', '서준', '현우'], ['간식 사기', '꽝', '꽝', '꽝']),
  LadderPreset(['철수', '영희', '영수'], ['계산하기', '꽝', '꽝']),
  LadderPreset(['민수', '지훈', '서준', '현우'], ['청소', '설거지', '정리', '휴식']),
  LadderPreset(['민수', '지훈', '서준', '현우'], ['커피 사기', '꽝', '꽝', '꽝']),
];

LadderPreset chooseLadderPreset(Random random) =>
    ladderPresets[random.nextInt(ladderPresets.length)];
