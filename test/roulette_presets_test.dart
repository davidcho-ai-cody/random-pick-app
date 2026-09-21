import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:random_pick/models/roulette_presets.dart';

void main() {
  test('presets fit roulette limits', () {
    expect(roulettePresets, isNotEmpty);
    for (final preset in roulettePresets) {
      expect(preset.length, inInclusiveRange(2, 12));
      expect(preset.every((item) => item.trim().isNotEmpty), isTrue);
    }
  });

  test('seeded selection is a defined preset', () {
    final chosen = chooseRoulettePreset(Random(7));
    expect(
        roulettePresets.any((preset) => preset.join('|') == chosen.join('|')),
        isTrue);
  });
}
