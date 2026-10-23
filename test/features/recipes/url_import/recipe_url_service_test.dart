import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/features/recipes/url_import/recipe_url_service.dart';

/// Builds a minimal HTML document with the given [jsonLd] inside a
/// `<script type="application/ld+json">` tag.
String _html(String jsonLd) =>
    '''
<html>
<body>
<script type="application/ld+json">$jsonLd</script>
</body>
</html>
''';

/// Convenience shorthand for a full recipe JSON-LD map (as JSON string).
String _fullRecipe() => jsonEncode({
  '@context': 'https://schema.org',
  '@type': 'Recipe',
  'name': 'Garlic Pasta',
  'description': 'A quick and easy garlic pasta dish.',
  'recipeYield': '4 servings',
  'prepTime': 'PT10M',
  'cookTime': 'PT15M',
  'totalTime': 'PT25M',
  'recipeIngredient': [
    '400g spaghetti',
    '4 cloves garlic',
    '2 tbsp olive oil',
    'Salt to taste',
  ],
  'recipeInstructions': [
    'Boil pasta in salted water until al dente.',
    'Sauté garlic in olive oil until golden.',
    'Toss pasta with garlic oil and serve.',
  ],
  'nutrition': {
    '@type': 'NutritionInformation',
    'calories': '350 kcal',
    'proteinContent': '12 g',
    'fatContent': '15 g',
    'carbohydrateContent': '45 g',
  },
  'notes': 'Add chilli flakes for extra heat.',
});

void main() {
  late RecipeUrlService service;

  setUp(() {
    service = RecipeUrlService();
  });

  group('parseHtml()', () {
    test('parses a full recipe with all fields', () {
      final draft = service.parseHtml(_html(_fullRecipe()));

      expect(draft.name, 'Garlic Pasta');
      expect(draft.servings, 4);
      expect(draft.description, 'A quick and easy garlic pasta dish.');
      expect(draft.prepTime, 10);
      expect(draft.cookTime, 15);
      expect(draft.totalTime, 25);
      expect(draft.notes, 'Add chilli flakes for extra heat.');

      // Ingredients — quantity split from name
      expect(draft.ingredients, hasLength(4));
      expect(draft.ingredients[0].name, 'spaghetti');
      expect(draft.ingredients[0].qty, 400.0);
      expect(draft.ingredients[0].unit, 'g');
      expect(draft.ingredients[1].name, 'garlic');
      expect(draft.ingredients[2].name, 'olive oil');

      // Steps
      expect(draft.steps, hasLength(3));
      expect(draft.steps[0], 'Boil pasta in salted water until al dente.');
      expect(draft.steps[1], 'Sauté garlic in olive oil until golden.');

      // Nutrition
      expect(draft.nutrition, hasLength(4));
      expect(draft.nutrition![0].label, 'calories');
      expect(draft.nutrition![0].value, '350 kcal');
      expect(draft.nutrition![1].label, 'proteinContent');
      expect(draft.nutrition![3].label, 'carbohydrateContent');

      // No sections (ingredients weren't sectioned)
      expect(draft.sections, isEmpty);
    });

    test('parses recipe with @type as an array', () {
      final jsonLd = jsonEncode({
        '@context': 'https://schema.org',
        '@type': ['Recipe', 'Article'],
        'name': 'Array Type Recipe',
        'recipeIngredient': ['2 cups flour'],
        'recipeInstructions': ['Mix and bake.'],
      });
      final draft = service.parseHtml(_html(jsonLd));
      expect(draft.name, 'Array Type Recipe');
      expect(draft.ingredients, hasLength(1));
    });

    test('parses recipe with schema.org URI-type', () {
      final jsonLd = jsonEncode({
        '@context': 'https://schema.org',
        '@type': 'https://schema.org/Recipe',
        'name': 'URI Type',
        'recipeIngredient': ['1 egg'],
        'recipeInstructions': ['Cook.'],
      });
      final draft = service.parseHtml(_html(jsonLd));
      expect(draft.name, 'URI Type');
    });

    test('finds recipe nested in a @graph node', () {
      final jsonLd = jsonEncode({
        '@context': 'https://schema.org',
        '@graph': [
          {'@type': 'WebPage', 'name': 'My Recipe Page'},
          {
            '@type': 'Recipe',
            'name': 'Graph Recipe',
            'recipeIngredient': ['1 cup sugar'],
            'recipeInstructions': ['Mix.'],
          },
        ],
      });
      final draft = service.parseHtml(_html(jsonLd));
      expect(draft.name, 'Graph Recipe');
    });

    test('finds recipe in a top-level list', () {
      final jsonLd = jsonEncode([
        {'@type': 'WebSite', 'name': 'Recipe Site'},
        {
          '@type': 'Recipe',
          'name': 'List Recipe',
          'recipeIngredient': ['1 cup milk'],
          'recipeInstructions': ['Drink.'],
        },
      ]);
      final draft = service.parseHtml(_html(jsonLd));
      expect(draft.name, 'List Recipe');
    });

    test('throws when no JSON-LD is present', () {
      final html = '<html><body><p>No recipe here.</p></body></html>';
      expect(() => service.parseHtml(html), throwsA(isA<UrlImportException>()));
    });

    test('throws when JSON-LD exists but has no recipe type', () {
      final html = _html(
        jsonEncode({'@type': 'WebPage', 'name': 'Not a Recipe'}),
      );
      expect(() => service.parseHtml(html), throwsA(isA<UrlImportException>()));
    });

    test('skips malformed JSON-LD and uses next script', () {
      final html =
          '<html><body>'
          '<script type="application/ld+json">{invalid}</script>'
          '<script type="application/ld+json">${jsonEncode({
            '@type': 'Recipe',
            'name': 'Second Script',
            'recipeIngredient': ['1 cup water'],
            'recipeInstructions': ['Boil.'],
          })}</script>'
          '</body></html>';
      final draft = service.parseHtml(html);
      expect(draft.name, 'Second Script');
    });

    test('skips empty script tags', () {
      final html =
          '<html><body>'
          '<script type="application/ld+json">   </script>'
          '<script type="application/ld+json">${jsonEncode({
            '@type': 'Recipe',
            'name': 'After Empty',
            'recipeIngredient': ['1 tsp salt'],
            'recipeInstructions': ['Season.'],
          })}</script>'
          '</body></html>';
      final draft = service.parseHtml(html);
      expect(draft.name, 'After Empty');
    });

    group('instructions parsing', () {
      test('instructions as plain string', () {
        final jsonLd = jsonEncode({
          '@type': 'Recipe',
          'name': 'String Steps',
          'recipeIngredient': ['1 onion'],
          'recipeInstructions': 'Chop onion.\nSauté in pan.\nServe hot.',
        });
        final draft = service.parseHtml(_html(jsonLd));
        expect(draft.steps, ['Chop onion.', 'Sauté in pan.', 'Serve hot.']);
      });

      test('instructions as list of strings', () {
        final jsonLd = jsonEncode({
          '@type': 'Recipe',
          'name': 'List Steps',
          'recipeIngredient': ['1 apple'],
          'recipeInstructions': ['Wash apple.', 'Slice and serve.'],
        });
        final draft = service.parseHtml(_html(jsonLd));
        expect(draft.steps, ['Wash apple.', 'Slice and serve.']);
      });

      test('instructions as HowToStep objects', () {
        final jsonLd = jsonEncode({
          '@type': 'Recipe',
          'name': 'HowToSteps',
          'recipeIngredient': ['1 cup rice'],
          'recipeInstructions': [
            {'@type': 'HowToStep', 'text': 'Rinse rice.'},
            {'@type': 'HowToStep', 'text': 'Boil 2 cups water.'},
          ],
        });
        final draft = service.parseHtml(_html(jsonLd));
        expect(draft.steps, ['Rinse rice.', 'Boil 2 cups water.']);
      });

      test('instructions as HowToSections with nested itemListElement', () {
        final jsonLd = jsonEncode({
          '@type': 'Recipe',
          'name': 'Sectioned Steps',
          'recipeIngredient': ['1 cake mix'],
          'recipeInstructions': [
            {
              '@type': 'HowToSection',
              'name': 'Preparation',
              'itemListElement': [
                {'@type': 'HowToStep', 'text': 'Preheat oven.'},
                {'@type': 'HowToStep', 'text': 'Grease pan.'},
              ],
            },
          ],
        });
        final draft = service.parseHtml(_html(jsonLd));
        expect(draft.steps, ['Preheat oven.', 'Grease pan.']);
      });

      test('null instructions → empty steps', () {
        final jsonLd = jsonEncode({
          '@type': 'Recipe',
          'name': 'No Steps',
          'recipeIngredient': ['1 egg'],
        });
        final draft = service.parseHtml(_html(jsonLd));
        expect(draft.steps, isEmpty);
      });

      test('empty string instructions → empty steps', () {
        final jsonLd = jsonEncode({
          '@type': 'Recipe',
          'name': 'Empty Steps',
          'recipeIngredient': ['1 egg'],
          'recipeInstructions': '',
        });
        final draft = service.parseHtml(_html(jsonLd));
        expect(draft.steps, isEmpty);
      });
    });

    group('servings parsing', () {
      test('recipeYield as a string', () {
        final jsonLd = jsonEncode({
          '@type': 'Recipe',
          'name': 'Servings String',
          'recipeYield': '6 servings',
          'recipeIngredient': ['1 cup flour'],
          'recipeInstructions': ['Bake.'],
        });
        expect(service.parseHtml(_html(jsonLd)).servings, 6);
      });

      test('recipeYield as an array', () {
        final jsonLd = jsonEncode({
          '@type': 'Recipe',
          'name': 'Servings Array',
          'recipeYield': ['4', '6'],
          'recipeIngredient': ['1 cup flour'],
          'recipeInstructions': ['Bake.'],
        });
        // parseServings picks the first numeric value
        expect(service.parseHtml(_html(jsonLd)).servings, 4);
      });

      test('missing recipeYield → null servings', () {
        final jsonLd = jsonEncode({
          '@type': 'Recipe',
          'name': 'No Yield',
          'recipeIngredient': ['1 cup flour'],
          'recipeInstructions': ['Bake.'],
        });
        expect(service.parseHtml(_html(jsonLd)).servings, isNull);
      });
    });

    group('nutrition parsing', () {
      test('nutrition with standard and extra fields', () {
        final jsonLd = jsonEncode({
          '@type': 'Recipe',
          'name': 'Nutrition Test',
          'recipeIngredient': ['1 apple'],
          'recipeInstructions': ['Eat.'],
          'nutrition': {
            '@type': 'NutritionInformation',
            'calories': '200',
            'proteinContent': '5',
            'extraField': 'some value',
          },
        });
        final draft = service.parseHtml(_html(jsonLd));
        // Standard fields + extra, minus @type
        expect(draft.nutrition, hasLength(3));
        expect(draft.nutrition![0].label, 'calories');
        expect(draft.nutrition![2].label, 'extraField');
      });

      test('nutrition as null → null', () {
        final jsonLd = jsonEncode({
          '@type': 'Recipe',
          'name': 'No Nutrition',
          'recipeIngredient': ['1 apple'],
          'recipeInstructions': ['Eat.'],
        });
        expect(service.parseHtml(_html(jsonLd)).nutrition, isNull);
      });

      test('nutrition ignores @-prefixed keys', () {
        final jsonLd = jsonEncode({
          '@type': 'Recipe',
          'name': 'No Meta',
          'recipeIngredient': ['1 carrot'],
          'recipeInstructions': ['Chop.'],
          'nutrition': {
            '@type': 'NutritionInformation',
            '@context': 'https://schema.org',
            'calories': '100',
          },
        });
        final draft = service.parseHtml(_html(jsonLd));
        expect(draft.nutrition, hasLength(1));
        expect(draft.nutrition!.single.label, 'calories');
      });
    });

    group('edge cases', () {
      test('no recipeIngredient → empty ingredients', () {
        final jsonLd = jsonEncode({
          '@type': 'Recipe',
          'name': 'No Ingredients',
          'recipeInstructions': ['Just do it.'],
        });
        final draft = service.parseHtml(_html(jsonLd));
        expect(draft.ingredients, isEmpty);
      });

      test('empty name → empty string (preserved as-is)', () {
        final jsonLd = jsonEncode({
          '@type': 'Recipe',
          'name': '',
          'recipeIngredient': [],
          'recipeInstructions': [],
        });
        final draft = service.parseHtml(_html(jsonLd));
        expect(draft.name, '');
        expect(draft.ingredients, isEmpty);
      });

      test('empty HTML → throws UrlImportException', () {
        expect(() => service.parseHtml(''), throwsA(isA<UrlImportException>()));
      });
    });
  });
}
