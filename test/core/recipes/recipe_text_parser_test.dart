import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/core/recipes/recipe_text_parser.dart';

void main() {
  group('RecipeTextParser.splitZones()', () {
    test('returns empty zones for empty text', () {
      final result = RecipeTextParser.splitZones('');
      expect(result.title, isNull);
      expect(result.ingredientLines, isEmpty);
      expect(result.methodLines, isEmpty);
    });

    test('recognises "Ingredients:" and "Method:" markers', () {
      const text = 'Creamy Garlic Pasta\n\nIngredients:\n400g spaghetti\n4 cloves garlic\n\nMethod:\n1. Boil pasta\n2. Sauté garlic';
      final result = RecipeTextParser.splitZones(text);
      expect(result.title, 'Creamy Garlic Pasta');
      expect(result.ingredientLines, ['400g spaghetti', '4 cloves garlic']);
      expect(result.methodLines, ['1. Boil pasta', '2. Sauté garlic']);
    });

    test('recognises "Ingredients" and "Directions" markers', () {
      const text = 'Simple Salad\nIngredients\nLettuce\nTomato\n\nDirections\nChop and toss';
      final result = RecipeTextParser.splitZones(text);
      expect(result.title, 'Simple Salad');
      expect(result.ingredientLines, ['Lettuce', 'Tomato']);
      expect(result.methodLines, ['Chop and toss']);
    });

    test('recognises "Instructions" as method marker', () {
      const text = 'Ingredients:\nSalt\nPepper\n\nInstructions:\nMix well';
      final result = RecipeTextParser.splitZones(text);
      expect(result.ingredientLines, ['Salt', 'Pepper']);
      expect(result.methodLines, ['Mix well']);
    });

    test('recognises "Steps" as method marker', () {
      const text = 'Ingredients:\nFlour\nEggs\n\nSteps:\nCombine\nBake';
      final result = RecipeTextParser.splitZones(text);
      expect(result.ingredientLines, ['Flour', 'Eggs']);
      expect(result.methodLines, ['Combine', 'Bake']);
    });

    test('handles subsections in ingredients zone', () {
      const text = 'Pasta Bake\nIngredients:\n500g pasta\n\nFor the sauce:\n400g tomatoes\n2 cloves garlic\n\nMethod:\nBake at 180C';
      final result = RecipeTextParser.splitZones(text);
      expect(result.title, 'Pasta Bake');
      expect(result.ingredientLines, ['500g pasta', 'For the sauce:', '400g tomatoes', '2 cloves garlic']);
      expect(result.methodLines, ['Bake at 180C']);
    });

    test('no markers — falls back to heuristic', () {
      const text = 'Simple Recipe\n400g spaghetti\n4 cloves garlic\nBoil pasta.\nSauté garlic.';
      final result = RecipeTextParser.splitZones(text);
      expect(result.title, 'Simple Recipe');
      expect(result.ingredientLines, ['400g spaghetti', '4 cloves garlic']);
      expect(result.methodLines, contains('Boil pasta.'));
    });

    test('no ingredients marker — uses heuristic within method zone', () {
      const text = 'My Recipe\n1. Chop onions\n2. Fry\n3. Serve';
      final result = RecipeTextParser.splitZones(text);
      expect(result.title, 'My Recipe');
      expect(result.ingredientLines, isEmpty);
      expect(result.methodLines, ['1. Chop onions', '2. Fry', '3. Serve']);
    });

    test('strips marker lines from ingredient zone', () {
      const text = 'Ingredients:\nFlour\nEggs\nMethod:\nMix';
      final result = RecipeTextParser.splitZones(text);
      expect(result.title, isNull);
      expect(result.ingredientLines, ['Flour', 'Eggs']);
      expect(result.methodLines, ['Mix']);
    });
  });

  group('RecipeTextParser.parseIngredientLines()', () {
    test('empty list returns empty', () {
      final (sections, unsectioned) = RecipeTextParser.parseIngredientLines([]);
      expect(sections, isEmpty);
      expect(unsectioned, isEmpty);
    });

    test('plain ingredients produce unsectioned list', () {
      final (sections, unsectioned) = RecipeTextParser.parseIngredientLines(
        ['400g spaghetti', '4 cloves garlic', 'Salt to taste'],
      );
      expect(sections, isEmpty);
      expect(unsectioned.length, 3);
      expect(unsectioned[0].name, 'spaghetti');
      expect(unsectioned[1].name, 'garlic');
    });

    test('section headers create named sections', () {
      final (sections, unsectioned) = RecipeTextParser.parseIngredientLines(
        [
          '400g spaghetti',
          'For the sauce:',
          '400g tomatoes',
          '2 cloves garlic',
        ],
      );
      expect(sections.length, 1);
      expect(unsectioned.length, 1);
      expect(unsectioned[0].name, 'spaghetti');
      expect(sections[0].name, 'For the sauce');
      expect(sections[0].ingredients.length, 2);
      expect(sections[0].ingredients[0].name, 'tomatoes');
      expect(sections[0].ingredients[1].name, 'garlic');
    });

    test('multiple sections', () {
      final (sections, unsectioned) = RecipeTextParser.parseIngredientLines(
        [
          'For the base:',
          '200g flour',
          'For the topping:',
          '100g cheese',
        ],
      );
      expect(sections.length, 2);
      expect(unsectioned, isEmpty);
      expect(sections[0].name, 'For the base');
      expect(sections[1].name, 'For the topping');
    });

    test('non-ingredient lines without colon are parsed as ingredients', () {
      final (sections, unsectioned) = RecipeTextParser.parseIngredientLines(
        ['Salt to taste', 'Olive oil', 'Fresh basil'],
      );
      expect(sections, isEmpty);
      expect(unsectioned.length, 3);
    });
  });

  group('RecipeTextParser.parseInstructions()', () {
    test('empty list returns empty', () {
      expect(RecipeTextParser.parseInstructions([]), isEmpty);
    });

    test('numbered lines are stripped of numbers', () {
      final result = RecipeTextParser.parseInstructions([
        '1. Boil pasta',
        '2. Sauté garlic',
        '3. Combine and serve',
      ]);
      expect(result, ['Boil pasta', 'Sauté garlic', 'Combine and serve']);
    });

    test('numbered lines with ) separator', () {
      final result = RecipeTextParser.parseInstructions([
        '1) Boil pasta',
        '2) Sauté garlic',
      ]);
      expect(result, ['Boil pasta', 'Sauté garlic']);
    });

    test('unnumbered lines are split by sentence boundaries', () {
      final result = RecipeTextParser.parseInstructions([
        'Boil pasta in salted water.',
        'Sauté garlic in butter until golden.',
      ]);
      expect(result.length, 2);
    });

    test('mixed numbered/unnumbered — uses numbering if >30% numbered', () {
      final result = RecipeTextParser.parseInstructions([
        '1. Boil pasta',
        '2. Sauté garlic',
        'Combine and serve',
      ]);
      // 2 of 3 = 66% numbered → uses numbering
      expect(result, ['Boil pasta', 'Sauté garlic', 'Combine and serve']);
    });
  });

  group('RecipeTextParser.parseServings()', () {
    test('null returns null', () {
      expect(RecipeTextParser.parseServings(null), isNull);
    });

    test('integer returns as-is', () {
      expect(RecipeTextParser.parseServings(4), 4);
    });

    test('double rounds to int', () {
      expect(RecipeTextParser.parseServings(4.5), 5);
    });

    test('list returns first element parsed', () {
      expect(RecipeTextParser.parseServings([6, 8]), 6);
    });

    test('string with number extracts it', () {
      expect(RecipeTextParser.parseServings('Serves 4'), 4);
    });

    test('string without number returns null', () {
      expect(RecipeTextParser.parseServings('Serves many'), isNull);
    });
  });

  group('RecipeTextParser.parseIngredientString()', () {
    test('delegates to IngredientParser', () {
      final result = RecipeTextParser.parseIngredientString('2 cups flour');
      expect(result.qty, 2);
      expect(result.unit, 'cup');
      expect(result.name, 'flour');
    });
  });
}