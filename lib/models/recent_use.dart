import 'game_mode.dart';

class RecentUse {
  const RecentUse({
    required this.id,
    required this.mode,
    required this.items,
    required this.createdAt,
  });

  final String id;
  final GameMode mode;
  final List<String> items;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'mode': mode.name,
        'items': items,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  static RecentUse? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }
    final id = value['id'];
    final modeName = value['mode'];
    final rawItems = value['items'];
    final rawDate = value['createdAt'];
    if (id is! String ||
        id.isEmpty ||
        modeName is! String ||
        rawItems is! List ||
        rawDate is! String) {
      return null;
    }
    final mode = GameMode.values.where((m) => m.name == modeName).firstOrNull;
    final date = DateTime.tryParse(rawDate);
    if (mode == null ||
        date == null ||
        rawItems.any((item) => item is! String)) {
      return null;
    }
    final items = rawItems.cast<String>();
    if (mode == GameMode.roulette &&
        (items.length < 2 ||
            items.length > 12 ||
            items.any((item) => item.isEmpty || item != item.trim()))) {
      return null;
    }
    return RecentUse(
        id: id, mode: mode, items: List.unmodifiable(items), createdAt: date);
  }
}
