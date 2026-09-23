import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/core/ingredients/ingredient_parser.dart';

void main() {
  group('IngredientParser.parse()', () {
    test('empty string returns empty name', () {
      final result = IngredientParser.parse('');
      expect(result.name, '');
      expect(result.qty, isNull);
      expect(result.notes, isNull);
      expect(result.alternatives, isEmpty);
    });

    test('whitespace-only string returns empty name', () {
      final result = IngredientParser.parse('   ');
      expect(result.name, '');
      expect(result.qty, isNull);
    });

    // ── Unicode fractions ─────────────────────────────────────────────

    test('unicode fraction prefix: ½ tsp salt', () {
      final result = IngredientParser.parse('½ tsp salt');
      expect(result.qty, closeTo(0.5, 0.001));
      expect(result.unit, 'tsp');
      expect(result.name, 'salt');
    });

    test('unicode fraction ¼ prefix', () {
      final result = IngredientParser.parse('¼ cup milk');
      expect(result.qty, closeTo(0.25, 0.001));
      expect(result.unit, 'cup');
      expect(result.name, 'milk');
    });

    test('unicode fraction ¾ prefix', () {
      final result = IngredientParser.parse('¾ cup flour');
      expect(result.qty, closeTo(0.75, 0.001));
      expect(result.unit, 'cup');
      expect(result.name, 'flour');
    });

    // ── Leading numbers with fractions ────────────────────────────────

    test('whole + fraction: 1 1/2 cups flour', () {
      final result = IngredientParser.parse('1 1/2 cups flour');
      expect(result.qty, closeTo(1.5, 0.001));
      expect(result.unit, 'cup');
      expect(result.name, 'flour');
    });

    test('simple fraction: 1/2 cup sugar', () {
      final result = IngredientParser.parse('1/2 cup sugar');
      expect(result.qty, closeTo(0.5, 0.001));
      expect(result.unit, 'cup');
      expect(result.name, 'sugar');
    });

    test('decimal number: 2.5 tbsp butter', () {
      final result = IngredientParser.parse('2.5 tbsp butter');
      expect(result.qty, closeTo(2.5, 0.001));
      expect(result.unit, 'tbsp');
      expect(result.name, 'butter');
    });

    test('integer: 3 eggs', () {
      final result = IngredientParser.parse('3 eggs');
      expect(result.qty, 3.0);
      expect(result.unit, isNull);
      expect(result.name, 'eggs');
    });

    // ── Range stripping ──────────────────────────────────────────────

    test('strips range: 1 - 1.5 cups rice', () {
      final result = IngredientParser.parse('1 - 1.5 cups rice');
      expect(result.qty, closeTo(1.0, 0.001));
      expect(result.unit, 'cup');
      expect(result.name, 'rice');
    });

    test('strips range with en-dash: 2–3 cloves garlic', () {
      final result = IngredientParser.parse('2–3 cloves garlic');
      expect(result.qty, 2.0);
      expect(result.unit, 'clove');
      expect(result.name, 'garlic');
    });

    test('strips range with em-dash: 1—2 tbsp oil', () {
      final result = IngredientParser.parse('1—2 tbsp oil');
      expect(result.qty, 1.0);
      expect(result.unit, 'tbsp');
      expect(result.name, 'oil');
    });

    // ── Unit conversion slashes ──────────────────────────────────────

    test('strips unit conversion: "120g / 4oz chicken" → "120g chicken"', () {
      final result = IngredientParser.parse('120g / 4oz chicken');
      expect(result.qty, 120.0);
      expect(result.unit, 'g');
      expect(result.name, 'chicken');
    });

    test('strips unit conversion: "100ml / 3.4fl oz water"', () {
      final result = IngredientParser.parse('100ml / 3.4fl oz water');
      expect(result.qty, 100.0);
      expect(result.unit, 'ml');
      // "oz" remains as part of the name after unit-conversion slash stripped
      expect(result.name, 'oz water');
    });

    // ── Parenthetical extraction ─────────────────────────────────────

    test('extracts parenthetical notes: "2 tbsp butter (melted)"', () {
      final result = IngredientParser.parse('2 tbsp butter (melted)');
      expect(result.qty, 2.0);
      expect(result.unit, 'tbsp');
      expect(result.name, 'butter');
      expect(result.notes, 'melted');
    });

    test('extracts innermost parens: "onion (finely diced)"', () {
      final result = IngredientParser.parse('1 onion (finely diced)');
      expect(result.qty, 1.0);
      expect(result.name, 'onion');
      expect(result.notes, 'finely diced');
    });

    test('handles trailing unmatched close paren: "garlic cloves )"', () {
      final result = IngredientParser.parse('2 garlic cloves )');
      expect(result.qty, 2.0);
      expect(result.unit, 'clove');
      expect(result.name, 'garlic');
    });

    test('handles trailing unmatched open paren: "garlic cloves ("', () {
      final result = IngredientParser.parse('2 garlic cloves (');
      expect(result.qty, 2.0);
      expect(result.unit, 'clove');
      expect(result.name, 'garlic');
    });

    // ── Alternative detection ────────────────────────────────────────

    test('detects "or" alternatives: "olive oil or vegetable oil"', () {
      final result = IngredientParser.parse(
        '2 tbsp olive oil or vegetable oil',
      );
      expect(result.qty, 2.0);
      expect(result.unit, 'tbsp');
      expect(result.name, 'olive oil');
      expect(result.alternatives.length, 1);
      expect(result.alternatives[0].name, 'vegetable oil');
      expect(result.alternatives[0].qty, 2.0);
      expect(result.alternatives[0].unit, 'tbsp');
    });

    test('detects "/" alternatives: "butter/margarine"', () {
      final result = IngredientParser.parse('1/2 cup butter/margarine');
      expect(result.qty, closeTo(0.5, 0.001));
      expect(result.unit, 'cup');
      expect(result.name, 'butter');
      expect(result.alternatives.length, 1);
      expect(result.alternatives[0].name, 'margarine');
    });

    // ── Count-unit end-of-name promotion ─────────────────────────────

    test('promotes "cloves" to unit: "2 garlic cloves"', () {
      final result = IngredientParser.parse('2 garlic cloves');
      expect(result.qty, 2.0);
      expect(result.unit, 'clove');
      expect(result.name, 'garlic');
    });

    test('promotes "slices" to unit: "3 bread slices"', () {
      final result = IngredientParser.parse('3 bread slices');
      expect(result.qty, 3.0);
      expect(result.unit, 'slice');
      expect(result.name, 'bread');
    });

    test('promotes "cups" to unit via UnitRegistry: "2 cups flour"', () {
      final result = IngredientParser.parse('2 cups flour');
      expect(result.qty, 2.0);
      expect(result.unit, 'cup');
      expect(result.name, 'flour');
    });

    // ── Note keywords ────────────────────────────────────────────────

    test('extracts note keywords: "1 onion (finely diced)" → name + notes', () {
      final result = IngredientParser.parse('1 onion (finely diced)');
      expect(result.qty, 1.0);
      expect(result.name, 'onion');
      expect(result.notes, 'finely diced');
    });

    test('detects prep note in-line: "2 skinless chicken breasts"', () {
      final result = IngredientParser.parse('2 skinless chicken breasts');
      expect(result.qty, 2.0);
      expect(result.name, 'chicken');
      expect(result.unit, 'breasts');
      expect(result.notes, 'skinless');
    });

    test('adverb+note compound: "finely chopped onion"', () {
      final result = IngredientParser.parse('1 finely chopped onion');
      expect(result.qty, 1.0);
      expect(result.name, 'onion');
      expect(result.notes, 'finely chopped');
    });

    test('multiple note keywords: "2 dried oregano leaves"', () {
      final result = IngredientParser.parse('2 dried oregano leaves');
      expect(result.qty, 2.0);
      expect(result.unit, 'leaves');
      expect(result.name, 'oregano');
      expect(result.notes, 'dried');
    });

    // ── Articles ─────────────────────────────────────────────────────

    test('strips articles: "a large onion"', () {
      final result = IngredientParser.parse('1 a large onion');
      expect(result.qty, 1.0);
      expect(result.name, 'large onion');
    });

    test('strips "of": "2 cups of flour"', () {
      final result = IngredientParser.parse('2 cups of flour');
      expect(result.qty, 2.0);
      expect(result.unit, 'cup');
      expect(result.name, 'flour');
    });

    // ── Complex / edge cases ─────────────────────────────────────────

    test('no quantity: "salt to taste"', () {
      final result = IngredientParser.parse('salt to taste');
      expect(result.qty, isNull);
      expect(result.unit, isNull);
      expect(result.name, 'salt to taste');
    });

    test('ingredient after quantity only: "500g"', () {
      final result = IngredientParser.parse('500g');
      expect(result.qty, 500.0);
      expect(result.unit, 'g');
    });

    test('only hyphen range stripped: "2-3"', () {
      final result = IngredientParser.parse('2-3');
      expect(result.qty, 2.0);
      expect(result.name, '');
    });

    test(
      'complex realistic: "1 1/2 cups (240g / 8.5oz) plain flour, sifted"',
      () {
        final result = IngredientParser.parse(
          '1 1/2 cups (240g / 8.5oz) plain flour, sifted',
        );
        expect(result.qty, closeTo(1.5, 0.001));
        expect(result.unit, 'cup');
        // Parenthetical "240g / 8.5oz" → unit-conversion slash strips "/ 8.5oz"
        // → notes extracts "240g". "sifted" stays inline (not in _noteKeywords).
        expect(result.name, 'plain flour, sifted');
      },
    );

    // ── Alternative inheritance ──────────────────────────────────────

    test('alternative inherits parent qty and unit', () {
      final result = IngredientParser.parse('1/2 cup cream or milk');
      expect(result.qty, closeTo(0.5, 0.001));
      expect(result.unit, 'cup');
      expect(result.name, 'cream');
      expect(result.alternatives.length, 1);
      expect(result.alternatives[0].qty, closeTo(0.5, 0.001));
      expect(result.alternatives[0].unit, 'cup');
      expect(result.alternatives[0].name, 'milk');
    });
  });
}
