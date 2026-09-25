import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/features/recipes/ocr/ocr_recipe_parser.dart';

void main() {
  group('OcrRecipeParser.parse()', () {
    test('empty string returns empty draft', () {
      final result = OcrRecipeParser.parse('');
      expect(result.name, isNull);
      expect(result.servings, isNull);
      expect(result.ingredients, isEmpty);
      expect(result.sections, isEmpty);
      expect(result.steps, isEmpty);
    });

    test('whitespace-only returns empty draft', () {
      final result = OcrRecipeParser.parse('   \n  \n  ');
      expect(result.name, isNull);
      expect(result.ingredients, isEmpty);
      expect(result.steps, isEmpty);
    });

    test('simple recipe with markers: title, ingredients, method', () {
      const text =
          'Garlic Pasta\n\nIngredients:\n400g spaghetti\n4 cloves garlic\n1 cup cream\n\nMethod:\n1. Boil pasta in salted water\n2. Sauté garlic in butter\n3. Add cream and simmer';
      final result = OcrRecipeParser.parse(text);

      expect(result.name, 'Garlic Pasta');
      expect(result.ingredients.length, 3);
      expect(result.ingredients[0].name, 'spaghetti');
      expect(result.ingredients[0].qty, 400);
      expect(result.ingredients[0].unit, 'g');
      expect(result.ingredients[1].name, 'garlic');
      expect(result.ingredients[2].name, 'cream');
      expect(result.ingredients[2].unit, 'cup');
      expect(result.steps.length, 3);
      expect(result.steps[0], 'Boil pasta in salted water');
      expect(result.steps[1], 'Sauté garlic in butter');
      expect(result.steps[2], 'Add cream and simmer');
    });

    test('recipe with subsections in ingredients', () {
      const text =
          'Pasta Bake\nIngredients:\n500g pasta\n\nFor the sauce:\n400g tomatoes\n2 garlic cloves\n\nMethod:\nLayer and bake at 180C for 30 min';
      final result = OcrRecipeParser.parse(text);

      expect(result.name, 'Pasta Bake');
      expect(result.ingredients.length, 1);
      expect(result.ingredients[0].name, 'pasta');
      expect(result.sections.length, 1);
      expect(result.sections[0].name, 'For the sauce');
      expect(result.sections[0].ingredients.length, 2);
      expect(result.sections[0].ingredients[0].name, 'tomatoes');
      expect(result.sections[0].ingredients[1].name, 'garlic');
    });

    test('no markers — falls back to heuristic', () {
      // Heuristic: first line = title, scan for first imperative verb
      // as ingredient/instruction boundary
      const text =
          'Quick Salad\nLettuce\nTomato\nCucumber\nChop all vegetables.\nToss with dressing.\nServe chilled.';
      final result = OcrRecipeParser.parse(text);

      expect(result.name, 'Quick Salad');
      expect(result.ingredients.length, 3);
      expect(result.ingredients[0].name, 'Lettuce');
      expect(result.ingredients[1].name, 'Tomato');
      expect(result.ingredients[2].name, 'Cucumber');
      expect(result.steps.length, 3);
    });

    test('detects non-digit ingredients like Salt to taste', () {
      const text =
          'Marinade\nIngredients:\n2 tbsp soy sauce\n1 tbsp honey\nSalt to taste\nPepper to taste\n\nMethod:\nMix all ingredients in a bowl.';
      final result = OcrRecipeParser.parse(text);

      expect(result.name, 'Marinade');
      expect(result.ingredients.length, 4);
      // Non-digit ingredients captured in the ingredients zone
      expect(result.ingredients.any((i) => i.name.contains('Salt')), true);
      expect(result.ingredients.any((i) => i.name.contains('Pepper')), true);
    });

    test('numberless lines in ingredients zone are still parsed', () {
      const text =
          'Ingredients:\nOlive oil\nFresh basil\n\nInstructions:\nDrizzle and serve';
      final result = OcrRecipeParser.parse(text);

      expect(result.ingredients.length, 2);
      expect(result.ingredients[0].name, 'Olive oil');
      expect(result.ingredients[1].name, 'basil');
    });

    test('title-only recipe with no method', () {
      const text = 'Just a Title\nIngredients:\nFlour\nEggs';
      final result = OcrRecipeParser.parse(text);

      expect(result.name, 'Just a Title');
      expect(result.ingredients.length, 2);
      expect(result.steps, isEmpty);
    });

    test('method-only with no ingredients', () {
      const text = 'Method:\n1. Open package\n2. Heat in microwave';
      final result = OcrRecipeParser.parse(text);

      expect(result.name, isNull);
      expect(result.ingredients, isEmpty);
      expect(result.steps.length, 2);
    });

    test('handles unicode fractions in OCR text', () {
      const text =
          'Pancakes\nIngredients:\n½ cup flour\n1 cup milk\n1 egg\n\nMethod:\nMix. Cook. Serve.';
      final result = OcrRecipeParser.parse(text);

      expect(result.ingredients[0].qty, closeTo(0.5, 0.001));
      expect(result.ingredients[0].unit, 'cup');
      expect(result.ingredients[0].name, 'flour');
    });

    test('handles OCR line-break artefacts', () {
      const text =
          'Creamy Sauce\nIngredients:\n1 cup cream\n2 tbsp butter\nSalt\n\nMethod:\n\nMelt butter in pan.\nAdd cream and stir.\nSeason with salt.';
      final result = OcrRecipeParser.parse(text);

      expect(result.name, 'Creamy Sauce');
      expect(result.ingredients.length, 3);
      expect(result.steps.length, 3);
    });
  });
}
