/// Splits a raw ingredient name string into a canonical name and optional
/// prep/cooking notes (e.g. "whisked eggs" → name="eggs", notes="whisked").
///
/// Uses a pure heuristic
class IngredientNameParser {
  static const _prepWords = {
    'whisked',
    'beaten',
    'chopped',
    'diced',
    'minced',
    'sliced',
    'grated',
    'shredded',
    'melted',
    'softened',
    'cooled',
    'cooked',
    'boiled',
    'fried',
    'roasted',
    'toasted',
    'crushed',
    'crumbled',
    'halved',
    'quartered',
    'peeled',
    'seeded',
    'pitted',
    'deveined',
    'thawed',
    'frozen',
    'dried',
    'canned',
    'sifted',
    'packed',
    'heaped',
    'heaping',
    'levelled',
    'leveled',
    'warmed',
    'chilled',
    'ground',
    'mashed',
    'pureed',
    'puréed',
    'blanched',
    'steamed',
    'poached',
    'grilled',
    'baked',
    'raw',
  };

  /// Synchronous heuristic split. Returns immediately — safe to call on blur.
  /// Returns null for [notes] if no prep content was detected.
  static ({String name, String? notes}) splitHeuristic(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return (name: trimmed, notes: null);

    // 1. Comma split: "eggs, whisked" → name="eggs", notes="whisked"
    final commaIdx = trimmed.indexOf(',');
    if (commaIdx > 0) {
      final beforeComma = trimmed.substring(0, commaIdx).trim();
      final afterComma = trimmed.substring(commaIdx + 1).trim();
      if (afterComma.isNotEmpty && beforeComma.isNotEmpty) {
        return (name: beforeComma, notes: afterComma);
      }
    }

    // 2. Prep word prefix: "whisked eggs" → notes="whisked", name="eggs"
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length >= 2) {
      final first = words.first.toLowerCase().replaceAll('-', '');
      if (_prepWords.contains(first)) {
        final rest = words.sublist(1).join(' ');
        return (name: rest, notes: words.first);
      }
    }

    return (name: trimmed, notes: null);
  }
}
