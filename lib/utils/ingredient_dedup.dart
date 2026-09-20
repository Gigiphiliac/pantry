import 'package:pantry/db/database.dart';
import 'package:drift/drift.dart';

// ── Jaro-Winkler ─────────────────────────────────────────────────────────────

double _jaro(String a, String b) {
  if (a == b) return 1.0;
  if (a.isEmpty || b.isEmpty) return 0.0;

  final matchDist = (a.length > b.length ? a.length : b.length) ~/ 2 - 1;
  final aMatched = List<bool>.filled(a.length, false);
  final bMatched = List<bool>.filled(b.length, false);

  int matches = 0;
  for (int i = 0; i < a.length; i++) {
    final start = (i - matchDist).clamp(0, b.length - 1);
    final end = (i + matchDist + 1).clamp(0, b.length);
    for (int j = start; j < end; j++) {
      if (!bMatched[j] && a[i] == b[j]) {
        aMatched[i] = true;
        bMatched[j] = true;
        matches++;
        break;
      }
    }
  }

  if (matches == 0) return 0.0;

  int transpositions = 0;
  int k = 0;
  for (int i = 0; i < a.length; i++) {
    if (!aMatched[i]) continue;
    while (!bMatched[k]) {
      k++;
    }
    if (a[i] != b[k]) transpositions++;
    k++;
  }

  return (matches / a.length +
          matches / b.length +
          (matches - transpositions / 2) / matches) /
      3;
}

double jaroWinkler(String a, String b) {
  final jaro = _jaro(a, b);
  int prefix = 0;
  for (int i = 0; i < a.length && i < b.length && i < 4; i++) {
    if (a[i] == b[i]) {
      prefix++;
    } else {
      break;
    }
  }
  return jaro + prefix * 0.1 * (1 - jaro);
}

// ── Name sanitisation ─────────────────────────────────────────────────────────

String _sanitiseIngredientName(String raw) {
  var s = raw.trim();
  // Strip trailing commas
  s = s.replaceAll(RegExp(r'\s*,+\s*$'), '').trim();
  // Strip trailing orphaned closing paren (no matching open paren present)
  if (s.endsWith(')') && !s.contains('(')) {
    s = s.substring(0, s.length - 1).trim();
  }
  // Collapse internal whitespace
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

// ── Dedup ─────────────────────────────────────────────────────────────────────

class DedupResult {
  final int? ingredientId;
  final String? mergeCandidate;
  final int? mergeCandidateId;
  final double score;

  const DedupResult({
    this.ingredientId,
    this.mergeCandidate,
    this.mergeCandidateId,
    required this.score,
  });

  bool get needsMergePrompt => mergeCandidate != null;
  bool get autoLinked => ingredientId != null && mergeCandidate == null;
}

Future<DedupResult> resolveIngredient(AppDatabase db, String rawText) async {
  final normalised = rawText.trim().toLowerCase();
  if (normalised.isEmpty) return const DedupResult(score: 0);

  // 1. Exact alias match
  final aliasMatch = await (db.select(
    db.ingredientAliases,
  )..where((t) => t.alias.equals(normalised))).getSingleOrNull();
  if (aliasMatch != null) {
    return DedupResult(ingredientId: aliasMatch.ingredientId, score: 1.0);
  }

  // 2. Fuzzy against all canonical names + aliases
  final allIngredients = await db.select(db.ingredients).get();
  final allAliases = await db.select(db.ingredientAliases).get();

  double bestScore = 0;
  Ingredient? bestIngredient;

  for (final ingredient in allIngredients) {
    double score = jaroWinkler(normalised, ingredient.name.toLowerCase());

    // Also check all aliases for this ingredient
    for (final alias in allAliases.where(
      (a) => a.ingredientId == ingredient.id,
    )) {
      final aliasScore = jaroWinkler(normalised, alias.alias.toLowerCase());
      if (aliasScore > score) score = aliasScore;
    }

    if (score > bestScore) {
      bestScore = score;
      bestIngredient = ingredient;
    }
  }

  if (bestIngredient == null || bestScore < 0.75) {
    return DedupResult(score: bestScore);
  }

  if (bestScore >= 0.92) {
    return DedupResult(ingredientId: bestIngredient.id, score: bestScore);
  }

  // 0.75–0.91: prompt user
  return DedupResult(
    mergeCandidate: bestIngredient.name,
    mergeCandidateId: bestIngredient.id,
    score: bestScore,
  );
}

Future<int> getOrCreateIngredient(AppDatabase db, String rawName) async {
  final normalised = _sanitiseIngredientName(rawName).toLowerCase();

  // Check alias first
  final existing = await (db.select(
    db.ingredientAliases,
  )..where((t) => t.alias.equals(normalised))).getSingleOrNull();
  if (existing != null) return existing.ingredientId;

  // Check canonical name
  final canonical = await (db.select(
    db.ingredients,
  )..where((t) => t.name.equals(normalised))).getSingleOrNull();
  if (canonical != null) return canonical.id;

  // Create new
  final id = await db
      .into(db.ingredients)
      .insert(IngredientsCompanion.insert(name: normalised));
  await db
      .into(db.ingredientAliases)
      .insert(
        IngredientAliasesCompanion.insert(alias: normalised, ingredientId: id),
      );
  return id;
}

// Merge an ingredient into another (used when user confirms merge prompt)
Future<void> mergeIngredients(
  AppDatabase db, {
  required int fromId,
  required int intoId,
}) async {
  await (db.update(db.ingredientAliases)
        ..where((t) => t.ingredientId.equals(fromId)))
      .write(IngredientAliasesCompanion(ingredientId: Value(intoId)));
  await (db.update(db.recipeIngredients)
        ..where((t) => t.ingredientId.equals(fromId)))
      .write(RecipeIngredientsCompanion(ingredientId: Value(intoId)));
  await (db.update(db.shoppingListItems)
        ..where((t) => t.ingredientId.equals(fromId)))
      .write(ShoppingListItemsCompanion(ingredientId: Value(intoId)));
  await (db.delete(db.ingredients)..where((t) => t.id.equals(fromId))).go();
}
