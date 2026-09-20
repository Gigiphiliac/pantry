import 'dart:convert';

import 'package:pantry/core/llm/llm_client.dart';
import 'package:pantry/features/settings/settings_screen.dart';

/// Splits a raw ingredient name string into a canonical name and optional
/// prep/cooking notes (e.g. "whisked eggs" → name="eggs", notes="whisked").
///
/// Uses a heuristic first; falls back to LLM for uncertain cases when a config
/// is provided.
class IngredientNameParser {
  static const _prepWords = {
    'whisked', 'beaten', 'chopped', 'diced', 'minced', 'sliced', 'grated',
    'shredded', 'melted', 'softened', 'cooled', 'cooked', 'boiled', 'fried',
    'roasted', 'toasted', 'crushed', 'crumbled', 'halved', 'quartered',
    'peeled', 'seeded', 'pitted', 'deveined', 'thawed', 'frozen', 'dried', 'canned',
    'sifted', 'packed', 'heaped', 'heaping', 'levelled', 'leveled',
    'warmed', 'chilled', 'ground', 'mashed', 'pureed', 'puréed',
    'blanched', 'steamed', 'poached', 'grilled', 'baked', 'raw',
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

  /// Async version: tries heuristic first, then LLM for uncertain cases.
  /// [existingNotes] — if already populated, skip LLM (user or prior parse set it).
  static Future<({String name, String? notes})> split(
    String raw, {
    LlmConfig? llm,
    String? existingNotes,
  }) async {
    final heuristic = splitHeuristic(raw);

    // Heuristic fired — trust it.
    if (heuristic.notes != null) return heuristic;

    // Notes already populated externally — nothing to do.
    if (existingNotes != null && existingNotes.isNotEmpty) {
      return (name: raw.trim(), notes: existingNotes);
    }

    // No heuristic match and no LLM — return as-is.
    if (llm == null || !llm.isConfigured) {
      return (name: raw.trim(), notes: null);
    }

    // LLM attempt for uncertain cases (e.g. "cooked day old white rice").
    try {
      final response = await LlmClient.complete(
        'You split ingredient strings into a bare ingredient name and optional prep notes. '
        'Respond ONLY with valid JSON: {"name": "string", "notes": "string or null"}. '
        'No markdown, no explanation. '
        'If there are no prep notes, set notes to null. '
        'Examples: "cooked day old white rice" → {"name":"white rice","notes":"cooked, day old"}; '
        '"cherry tomatoes" → {"name":"cherry tomatoes","notes":null}.',
        raw.trim(),
        llm,
      ).timeout(const Duration(seconds: 15));

      final json = jsonDecode(response) as Map<String, dynamic>;
      final name = (json['name'] as String?)?.trim() ?? raw.trim();
      final notes = json['notes'] as String?;
      if (name.isNotEmpty) {
        return (name: name, notes: notes?.isEmpty == true ? null : notes);
      }
    } catch (_) {
      // LLM failed — fall through to returning raw.
    }

    return (name: raw.trim(), notes: null);
  }
}
