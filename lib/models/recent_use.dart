import 'game_mode.dart';

/// 모드별 입력을 하나의 최근 사용 목록에 저장한다.
/// 룰렛의 기존 top-level items JSON도 계속 읽고 쓴다.
class RecentUse {
  const RecentUse({
    required this.id,
    required this.mode,
    required this.createdAt,
    this.items = const [],
    this.participants = const [],
    this.results = const [],
    this.teamCount,
  });

  final String id;
  final GameMode mode;
  final DateTime createdAt;
  final List<String> items;
  final List<String> participants;
  final List<String> results;
  final int? teamCount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'mode': mode.name,
        'createdAt': createdAt.toUtc().toIso8601String(),
        if (mode == GameMode.roulette) 'items': items,
        if (mode == GameMode.ladder)
          'payload': {'participants': participants, 'results': results},
        if (mode == GameMode.team)
          'payload': {'participants': participants, 'teamCount': teamCount},
      };

  static RecentUse? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final id = value['id'];
    final modeName = value['mode'];
    final rawDate = value['createdAt'];
    if (id is! String ||
        id.isEmpty ||
        modeName is! String ||
        rawDate is! String) {
      return null;
    }
    final mode = GameMode.values.where((m) => m.name == modeName).firstOrNull;
    final date = DateTime.tryParse(rawDate);
    if (mode == null || date == null) return null;

    final payload = value['payload'];
    if (mode == GameMode.roulette) {
      // Older app versions stored items at the top level.
      final items = _strings(
          value['items'] ?? (payload is Map ? payload['items'] : null));
      if (items == null || !_validStrings(items, 2, 12)) return null;
      return RecentUse(id: id, mode: mode, createdAt: date, items: items);
    }
    if (payload is! Map) return null;
    final participants = _strings(payload['participants']);
    if (participants == null) return null;
    if (mode == GameMode.ladder) {
      final results = _strings(payload['results']);
      if (results == null ||
          !_validStrings(participants, 2, 10) ||
          !_validStrings(results, 2, 10) ||
          participants.length != results.length) {
        return null;
      }
      return RecentUse(
          id: id,
          mode: mode,
          createdAt: date,
          participants: participants,
          results: results);
    }
    final teamCount = payload['teamCount'];
    if (teamCount is! int ||
        teamCount < 2 ||
        teamCount > 8 ||
        !_validStrings(participants, teamCount, 20)) {
      return null;
    }
    return RecentUse(
        id: id,
        mode: mode,
        createdAt: date,
        participants: participants,
        teamCount: teamCount);
  }

  static List<String>? _strings(Object? value) {
    if (value is! List || value.any((item) => item is! String)) return null;
    return List.unmodifiable(value.cast<String>());
  }

  static bool _validStrings(List<String> values, int min, int max) =>
      values.length >= min &&
      values.length <= max &&
      values.every((value) => value.isNotEmpty && value == value.trim());
}
