import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/core/ingredients/ingredient_name_parser.dart';

void main() {
  group('IngredientNameParser.splitHeuristic()', () {
    test('empty string returns empty name, null notes', () {
      final result = IngredientNameParser.splitHeuristic('');
      expect(result.name, '');
      expect(result.notes, isNull);
    });

    test('whitespace returns trimmed name, null notes', () {
      final result = IngredientNameParser.splitHeuristic('  eggs  ');
      expect(result.name, 'eggs');
      expect(result.notes, isNull);
    });

    // ── Comma split ──────────────────────────────────────────────────

    test('comma split: "eggs, whisked" → name=eggs, notes=whisked', () {
      final result = IngredientNameParser.splitHeuristic('eggs, whisked');
      expect(result.name, 'eggs');
      expect(result.notes, 'whisked');
    });

    test('comma split: "onion, finely chopped"', () {
      final result = IngredientNameParser.splitHeuristic(
        'onion, finely chopped',
      );
      expect(result.name, 'onion');
      expect(result.notes, 'finely chopped');
    });

    test('comma before prep word signals notes', () {
      final result = IngredientNameParser.splitHeuristic('tomatoes, diced');
      expect(result.name, 'tomatoes');
      expect(result.notes, 'diced');
    });

    // ── Prep word prefix ─────────────────────────────────────────────

    test('prep word prefix: "whisked eggs" → name=eggs, notes=whisked', () {
      final result = IngredientNameParser.splitHeuristic('whisked eggs');
      expect(result.name, 'eggs');
      expect(result.notes, 'whisked');
    });

    test('prep word prefix: "diced onion"', () {
      final result = IngredientNameParser.splitHeuristic('diced onion');
      expect(result.name, 'onion');
      expect(result.notes, 'diced');
    });

    test('prep word prefix with hyphen variant: "deveined shrimp"', () {
      final result = IngredientNameParser.splitHeuristic('deveined shrimp');
      expect(result.name, 'shrimp');
      expect(result.notes, 'deveined');
    });

    test('prep word prefix: "minced garlic"', () {
      final result = IngredientNameParser.splitHeuristic('minced garlic');
      expect(result.name, 'garlic');
      expect(result.notes, 'minced');
    });

    // ── No-op cases ──────────────────────────────────────────────────

    test(
      'no prep word: "cherry tomatoes" → name=cherry tomatoes, notes=null',
      () {
        final result = IngredientNameParser.splitHeuristic('cherry tomatoes');
        expect(result.name, 'cherry tomatoes');
        expect(result.notes, isNull);
      },
    );

    test('single word returns name unchanged', () {
      final result = IngredientNameParser.splitHeuristic('eggs');
      expect(result.name, 'eggs');
      expect(result.notes, isNull);
    });

    test('non-prep first word returns name unchanged', () {
      final result = IngredientNameParser.splitHeuristic('green beans');
      expect(result.name, 'green beans');
      expect(result.notes, isNull);
    });

    test('comma wins over prep-word prefix when both present', () {
      // "whisked, eggs" → comma detected first → name=whisked, notes=eggs
      final result = IngredientNameParser.splitHeuristic('whisked, eggs');
      expect(result.name, 'whisked');
      expect(result.notes, 'eggs');
    });

    test('prep word with no following word stays as name', () {
      final result = IngredientNameParser.splitHeuristic('diced');
      expect(result.name, 'diced');
      expect(result.notes, isNull);
    });
  });
}
