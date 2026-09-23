import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_mode.dart';
import '../models/recent_use.dart';

class RecentUseService {
  RecentUseService(this._preferences, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  static const maxPerMode = 10;
  static const storageKey = 'recent_uses_v1';

  final SharedPreferences _preferences;
  final DateTime Function() _clock;

  List<RecentUse> read(GameMode mode) =>
      _readAll().where((entry) => entry.mode == mode).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<bool> saveRoulette(List<String> items) async {
    if (items.length < 2 ||
        items.length > 12 ||
        items.any((item) => item.isEmpty || item != item.trim())) {
      return false;
    }
    return _save(
      GameMode.roulette,
      (now) => RecentUse(
        id: '${now.microsecondsSinceEpoch}',
        mode: GameMode.roulette,
        items: List.unmodifiable(items),
        createdAt: now,
      ),
      (entry) => _sameItems(entry.items, items),
    );
  }

  Future<bool> saveLadder(
      List<String> participants, List<String> results) async {
    if (participants.length < 2 ||
        participants.length > 10 ||
        participants.length != results.length ||
        [...participants, ...results]
            .any((value) => value.isEmpty || value != value.trim())) {
      return false;
    }
    return _save(
      GameMode.ladder,
      (now) => RecentUse(
        id: '${now.microsecondsSinceEpoch}',
        mode: GameMode.ladder,
        participants: List.unmodifiable(participants),
        results: List.unmodifiable(results),
        createdAt: now,
      ),
      (entry) =>
          _sameItems(entry.participants, participants) &&
          _sameItems(entry.results, results),
    );
  }

  Future<bool> saveTeam(List<String> participants, int teamCount) async {
    if (teamCount < 2 ||
        teamCount > 8 ||
        participants.length < teamCount ||
        participants.length > 20 ||
        participants.any((value) => value.isEmpty || value != value.trim())) {
      return false;
    }
    return _save(
      GameMode.team,
      (now) => RecentUse(
        id: '${now.microsecondsSinceEpoch}',
        mode: GameMode.team,
        participants: List.unmodifiable(participants),
        teamCount: teamCount,
        createdAt: now,
      ),
      (entry) =>
          entry.teamCount == teamCount &&
          _sameItems(entry.participants, participants),
    );
  }

  Future<bool> _save(
    GameMode mode,
    RecentUse Function(DateTime now) create,
    bool Function(RecentUse entry) matches,
  ) async {
    final now = _clock().toUtc();
    final entries = _readAll()
      ..removeWhere((entry) => entry.mode == mode && matches(entry));
    entries.add(create(now));
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final counts = <GameMode, int>{};
    final kept = <RecentUse>[];
    for (final entry in entries) {
      final count = counts[entry.mode] ?? 0;
      if (count >= maxPerMode) continue;
      kept.add(entry);
      counts[entry.mode] = count + 1;
    }
    return _preferences.setString(
      storageKey,
      jsonEncode(kept.map((entry) => entry.toJson()).toList()),
    );
  }

  List<RecentUse> _readAll() {
    try {
      final raw = _preferences.getString(storageKey);
      if (raw == null) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.map(RecentUse.fromJson).whereType<RecentUse>().toList();
    } catch (_) {
      return [];
    }
  }

  bool _sameItems(List<String> a, List<String> b) =>
      a.length == b.length &&
      List.generate(a.length, (i) => a[i] == b[i]).every((same) => same);
}
