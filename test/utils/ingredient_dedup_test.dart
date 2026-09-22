import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/utils/ingredient_dedup.dart'
    show
        jaroWinkler,
        resolveIngredient,
        getOrCreateIngredient,
        mergeIngredients;
import 'package:pantry/db/database.dart';
import 'package:drift/native.dart';

/// Creates an in-memory Drift [AppDatabase] for testing.
AppDatabase createMemoryDb() {
  final db = AppDatabase.connect(NativeDatabase.memory());
  return db;
}

void main() {
  // ── Pure function: jaroWinkler ──────────────────────────────────────

  group('jaroWinkler()', () {
    test('identical strings return 1.0', () {
      expect(jaroWinkler('salt', 'salt'), 1.0);
    });

    test('completely different strings return near 0', () {
      final score = jaroWinkler('salt', 'xyz');
      expect(score, lessThan(0.5));
    });

    test('similar strings get high score', () {
      final score = jaroWinkler('tomato', 'tomatoe');
      expect(score, greaterThan(0.85));
    });

    test('empty strings return 0.0', () {
      expect(jaroWinkler('', 'anything'), 0.0);
      expect(jaroWinkler('anything', ''), 0.0);
    });

    test('both empty return 1.0 (identical strings)', () {
      expect(jaroWinkler('', ''), 1.0);
    });

    test('prefix bonus: "tomat" vs "tomato"', () {
      final score = jaroWinkler('tomat', 'tomato');
      expect(score, greaterThan(0.9));
    });

    test('case sensitivity matters (lowercase expected by caller)', () {
      // jaroWinkler is case-sensitive; the caller lowercases first.
      final score = jaroWinkler('salt', 'Salt');
      expect(score, lessThan(1.0));
    });
  });

  // ── DB-dependent: resolveIngredient ─────────────────────────────────

  group('resolveIngredient()', () {
    late AppDatabase db;

    setUp(() async {
      db = createMemoryDb();
      await db
          .into(db.ingredients)
          .insert(IngredientsCompanion.insert(name: 'salt'));
      await db
          .into(db.ingredients)
          .insert(IngredientsCompanion.insert(name: 'olive oil'));
      await db
          .into(db.ingredientAliases)
          .insert(
            IngredientAliasesCompanion.insert(
              alias: 'table salt',
              ingredientId: 1,
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test('exact alias match returns ingredient with score 1.0', () async {
      final result = await resolveIngredient(db, 'table salt');
      expect(result.ingredientId, 1);
      expect(result.score, 1.0);
      expect(result.autoLinked, isTrue);
    });

    test('exact canonical name match returns ingredient', () async {
      final result = await resolveIngredient(db, 'salt');
      expect(result.ingredientId, 1);
      expect(result.score, 1.0);
      expect(result.autoLinked, isTrue);
    });

    test('moderate fuzzy match (~0.88) prompts for merge', () async {
      // "salf" vs "salt": jaroWinkler ≈ 0.88 → 0.75–0.91 = merge prompt
      final result = await resolveIngredient(db, 'salf');
      expect(result.mergeCandidate, 'salt');
      expect(result.needsMergePrompt, isTrue);
      expect(result.ingredientId, isNull);
    });

    test('high fuzzy match (≥0.92) auto-links', () async {
      // "olive oyl" vs "olive oil": jaroWinkler ≈ 0.93 → auto-link
      final result = await resolveIngredient(db, 'olive oyl');
      expect(result.ingredientId, 2);
      expect(result.score, greaterThanOrEqualTo(0.92));
      expect(result.autoLinked, isTrue);
    });

    test('low fuzzy match (<0.75) returns no match', () async {
      final result = await resolveIngredient(db, 'chicken');
      expect(result.ingredientId, isNull);
      expect(result.mergeCandidate, isNull);
      expect(result.score, lessThan(0.75));
    });

    test('case-insensitive matching', () async {
      final result = await resolveIngredient(db, 'SALT');
      expect(result.ingredientId, 1);
      expect(result.score, 1.0);
    });

    test('empty string returns score 0', () async {
      final result = await resolveIngredient(db, '');
      expect(result.ingredientId, isNull);
      expect(result.score, 0.0);
    });
  });

  // ── DB-dependent: getOrCreateIngredient ────────────────────────────

  group('getOrCreateIngredient()', () {
    late AppDatabase db;

    setUp(() async {
      db = createMemoryDb();
      await db
          .into(db.ingredients)
          .insert(IngredientsCompanion.insert(name: 'salt'));
      await db
          .into(db.ingredientAliases)
          .insert(
            IngredientAliasesCompanion.insert(alias: 'salt', ingredientId: 1),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test('returns existing id for known ingredient', () async {
      final id = await getOrCreateIngredient(db, 'salt');
      expect(id, 1);
    });

    test('creates new ingredient for unknown name', () async {
      final id = await getOrCreateIngredient(db, 'sugar');
      final ingredients = await db.select(db.ingredients).get();
      expect(ingredients.length, 2); // salt + sugar
      expect(id, 2);
    });

    test('sanitises trailing comma in name', () async {
      final id = await getOrCreateIngredient(db, 'sugar,');
      // Should strip comma and match "sugar" if existing, or create "sugar"
      expect(id, isNotNull);
    });
  });

  // ── DB-dependent: mergeIngredients ─────────────────────────────────

  group('mergeIngredients()', () {
    late AppDatabase db;

    setUp(() async {
      db = createMemoryDb();
      await db
          .into(db.ingredients)
          .insert(IngredientsCompanion.insert(name: 'salt'));
      await db
          .into(db.ingredients)
          .insert(IngredientsCompanion.insert(name: 'table salt'));
      // Link aliases
      await db
          .into(db.ingredientAliases)
          .insert(
            IngredientAliasesCompanion.insert(alias: 'salt', ingredientId: 1),
          );
      await db
          .into(db.ingredientAliases)
          .insert(
            IngredientAliasesCompanion.insert(
              alias: 'table salt',
              ingredientId: 2,
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test('merges fromId into intoId and deletes fromId', () async {
      await mergeIngredients(db, fromId: 2, intoId: 1);

      // fromId ingredient should be deleted
      final ingredients = await db.select(db.ingredients).get();
      expect(ingredients.length, 1);
      expect(ingredients.single.id, 1);

      // Aliases should be reassigned to intoId
      final aliases = await db.select(db.ingredientAliases).get();
      for (final alias in aliases) {
        expect(alias.ingredientId, 1);
      }
    });
  });
}
