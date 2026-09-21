import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:random_pick/models/game_mode.dart';
import 'package:random_pick/services/recent_use_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('empty history and save/read', () async {
    final prefs = await SharedPreferences.getInstance();
    final service = RecentUseService(prefs);
    expect(service.read(GameMode.roulette), isEmpty);
    expect(await service.saveRoulette(['치킨', '피자']), isTrue);
    expect(service.read(GameMode.roulette).single.items, ['치킨', '피자']);
  });

  test('newest first and repeated list moves to top without duplication',
      () async {
    final prefs = await SharedPreferences.getInstance();
    var tick = 0;
    final service = RecentUseService(prefs,
        clock: () => DateTime.utc(2026, 1, 1).add(Duration(minutes: tick++)));
    await service.saveRoulette(['A', 'B']);
    await service.saveRoulette(['C', 'D']);
    await service.saveRoulette(['A', 'B']);
    expect(
        service.read(GameMode.roulette).map((e) => e.items.first), ['A', 'C']);
    expect(service.read(GameMode.roulette).length, 2);
  });

  test('keeps at most ten per mode', () async {
    final prefs = await SharedPreferences.getInstance();
    var tick = 0;
    final service = RecentUseService(prefs,
        clock: () => DateTime.utc(2026, 1, 1).add(Duration(minutes: tick++)));
    for (var i = 0; i < 12; i++) {
      await service.saveRoulette(['A$i', 'B$i']);
    }
    expect(service.read(GameMode.roulette).length, 10);
    expect(service.read(GameMode.roulette).first.items.first, 'A11');
    expect(service.read(GameMode.roulette).last.items.first, 'A2');
  });

  test('corrupt storage and unknown modes are ignored', () async {
    final prefs = await SharedPreferences.getInstance();
    final service = RecentUseService(prefs);
    await prefs.setString(RecentUseService.storageKey, 'not json');
    expect(service.read(GameMode.roulette), isEmpty);
    await prefs.setString(
        RecentUseService.storageKey,
        jsonEncode([
          {
            'id': '1',
            'mode': 'unknown',
            'items': ['A', 'B'],
            'createdAt': '2026-01-01T00:00:00Z'
          },
          {
            'id': '2',
            'mode': 'roulette',
            'items': ['A'],
            'createdAt': '2026-01-01T00:00:00Z'
          },
          {
            'id': '3',
            'mode': 'roulette',
            'items': ['A', 'B'],
            'createdAt': '2026-01-01T00:00:00Z'
          },
        ]));
    expect(service.read(GameMode.roulette).map((e) => e.id), ['3']);
  });
}
