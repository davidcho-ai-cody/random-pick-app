import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:random_pick/models/ladder_presets.dart';

void main() {
  test('ladder presets are valid pairs', () {
    expect(ladderPresets.length, inInclusiveRange(4, 6));
    for (final preset in ladderPresets) {
      expect(preset.participants.length, inInclusiveRange(2, 10));
      expect(preset.results.length, preset.participants.length);
      expect(
          [...preset.participants, ...preset.results]
              .every((s) => s.trim().isNotEmpty),
          isTrue);
    }
  });

  test('seeded selection uses a defined preset', () {
    expect(ladderPresets.contains(chooseLadderPreset(Random(7))), isTrue);
  });
}
