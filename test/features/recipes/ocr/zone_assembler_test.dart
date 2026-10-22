import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/core/ocr/onnx_classifier.dart';
import 'package:pantry/features/recipes/ocr/zone_assembler.dart';

/// Build a classification with the given [label].
OcrLineClassification _cls(OcrLineLabel label, {double confidence = 0.9}) =>
    OcrLineClassification(
      label: label,
      confidence: confidence,
      labelName: label.name,
    );

void main() {
  group('ZoneAssembler.assemble()', () {
    test('groups labels into a full assembled recipe', () {
      final result = ZoneAssembler.assemble(
        [
          'Fluffy Pancakes',
          'Serves 4',
          'Light and fluffy pancakes perfect for weekends.',
          '2 cups flour',
          '1 cup milk',
          'For the topping:',
          'maple syrup',
          'Mix dry ingredients.',
          'Whisk in milk.',
          'Per serve: 200 calories',
        ],
        [
          _cls(OcrLineLabel.title),
          _cls(OcrLineLabel.servings),
          _cls(OcrLineLabel.description),
          _cls(OcrLineLabel.ingredient),
          _cls(OcrLineLabel.ingredient),
          _cls(OcrLineLabel.sectionHeader),
          _cls(OcrLineLabel.ingredient),
          _cls(OcrLineLabel.methodStep),
          _cls(OcrLineLabel.methodStep),
          _cls(OcrLineLabel.nutrition),
        ],
      );

      expect(result.title, 'Fluffy Pancakes');
      expect(result.servings, 4);
      expect(
        result.description,
        'Light and fluffy pancakes perfect for weekends.',
      );
      expect(result.ingredientLines, [
        '2 cups flour',
        '1 cup milk',
        'For the topping:',
        'maple syrup',
      ]);
      expect(result.methodLines, ['Mix dry ingredients.', 'Whisk in milk.']);
      expect(result.nutritionLines, ['Per serve: 200 calories']);
      expect(result.notesLines, isEmpty);
    });

    test('returns empty fields for all-ignore lines', () {
      final result = ZoneAssembler.assemble(
        ['some ad', 'another ad'],
        [_cls(OcrLineLabel.ignore), _cls(OcrLineLabel.ignore)],
      );
      expect(result.title, isNull);
      expect(result.servings, isNull);
      expect(result.description, isNull);
      expect(result.ingredientLines, isEmpty);
      expect(result.methodLines, isEmpty);
    });

    test('empty input → defaults', () {
      final result = ZoneAssembler.assemble([], []);
      expect(result.title, isNull);
      expect(result.servings, isNull);
      expect(result.description, isNull);
      expect(result.ingredientLines, isEmpty);
      expect(result.methodLines, isEmpty);
    });

    test('single title line', () {
      final result = ZoneAssembler.assemble(
        ['Pancakes'],
        [_cls(OcrLineLabel.title)],
      );
      expect(result.title, 'Pancakes');
    });

    test('first title wins (subsequent titles ignored)', () {
      final result = ZoneAssembler.assemble(
        ['Pancakes', 'Also Pancakes'],
        [_cls(OcrLineLabel.title), _cls(OcrLineLabel.title)],
      );
      expect(result.title, 'Pancakes');
    });

    test('method line flushes buffered section ingredients', () {
      // Ingredients after a section header are buffered; when method line
      // appears, the buffer is flushed into ingredientLines.
      final result = ZoneAssembler.assemble(
        ['For the sauce:', '2 tomatoes', 'Cook for 10 mins.'],
        [
          _cls(OcrLineLabel.sectionHeader),
          _cls(OcrLineLabel.ingredient),
          _cls(OcrLineLabel.methodStep),
        ],
      );
      expect(result.ingredientLines, ['For the sauce:', '2 tomatoes']);
      expect(result.methodLines, ['Cook for 10 mins.']);
    });

    test('notes and nutrition grouped separately', () {
      final result = ZoneAssembler.assemble(
        ['Some notes here', 'Per serve: 100 cal'],
        [_cls(OcrLineLabel.notes), _cls(OcrLineLabel.nutrition)],
      );
      expect(result.notesLines, ['Some notes here']);
      expect(result.nutritionLines, ['Per serve: 100 cal']);
      expect(result.ingredientLines, isEmpty);
      expect(result.methodLines, isEmpty);
    });

    test('description parts joined with space', () {
      final result = ZoneAssembler.assemble(
        ['A great', 'recipe'],
        [_cls(OcrLineLabel.description), _cls(OcrLineLabel.description)],
      );
      expect(result.description, 'A great recipe');
    });

    test('servings extracts first number from text', () {
      final result = ZoneAssembler.assemble(
        ['Serves 4 to 6'],
        [_cls(OcrLineLabel.servings)],
      );
      expect(result.servings, 4);
    });

    test('servings with no digits → null', () {
      final result = ZoneAssembler.assemble(
        ['Serves many'],
        [_cls(OcrLineLabel.servings)],
      );
      expect(result.servings, isNull);
    });
  });

  group('ZoneAssembler.parseNutritionLine()', () {
    test('colon-separated: "Calories: 250 per serving"', () {
      final draft = ZoneAssembler.parseNutritionLine(
        'Calories: 250 per serving',
      );
      expect(draft.label, 'Calories');
      expect(draft.value, '250 per serving');
    });

    test('space-separated: "Protein 10g"', () {
      final draft = ZoneAssembler.parseNutritionLine('Protein 10g');
      expect(draft.label, 'Protein');
      expect(draft.value, '10g');
    });

    test(
      'unparseable (no colon and only one word) → label = raw text, value = ""',
      () {
        final draft = ZoneAssembler.parseNutritionLine('abcdef');
        expect(draft.label, 'abcdef');
        expect(draft.value, '');
      },
    );

    test('empty line → label = "", value = ""', () {
      final draft = ZoneAssembler.parseNutritionLine('');
      expect(draft.label, '');
      expect(draft.value, '');
    });

    test('whitespace only → label = blank, value = ""', () {
      final draft = ZoneAssembler.parseNutritionLine('   ');
      expect(draft.label, '');
      expect(draft.value, '');
    });
  });

  group('ZoneAssembler.toRecipeDraft()', () {
    test('converts assembled recipe to RecipeDraft', () {
      final assembled = AssembledRecipe(
        title: 'Pancakes',
        servings: 4,
        description: 'Quick and easy.',
        ingredientLines: ['2 cups flour', '1 cup milk'],
        methodLines: ['Mix.', 'Cook.'],
        nutritionLines: ['Calories: 200', 'Protein: 5g'],
        notesLines: ['Serve with syrup.'],
      );
      final draft = ZoneAssembler.toRecipeDraft(assembled);
      expect(draft.name, 'Pancakes');
      expect(draft.servings, 4);
      expect(draft.description, 'Quick and easy.');
      expect(draft.ingredients.length, 2);
      expect(draft.ingredients[0].name, 'flour');
      expect(draft.steps, ['Mix.', 'Cook.']);
      expect(draft.nutrition!.length, 2);
      expect(draft.nutrition![0].label, 'Calories');
      expect(draft.notes, 'Serve with syrup.');
    });

    test('empty method lines → no steps', () {
      final draft = ZoneAssembler.toRecipeDraft(
        const AssembledRecipe(title: 'Test', ingredientLines: ['1 egg']),
      );
      expect(draft.steps, isEmpty);
    });

    test('empty nutrition → null', () {
      final draft = ZoneAssembler.toRecipeDraft(const AssembledRecipe());
      expect(draft.nutrition, isNull);
    });
  });
}
