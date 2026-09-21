import 'dart:math';

const roulettePresets = <List<String>>[
  ['치킨', '피자', '햄버거', '떡볶이', '족발'],
  ['돈까스', '국밥', '김치찌개', '제육볶음', '냉면'],
  ['커피', '아이스크림', '과자', '빵', '음료'],
  ['영화', '산책', '게임', '카페', '쇼핑'],
];

List<String> chooseRoulettePreset(Random random) =>
    List.of(roulettePresets[random.nextInt(roulettePresets.length)]);
