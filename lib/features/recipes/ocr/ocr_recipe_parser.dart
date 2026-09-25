import 'package:pantry/core/recipes/recipe_text_parser.dart';
import 'package:pantry/features/recipes/models/recipe_draft.dart';

/// Deterministic parser that converts raw OCR recipe text into a [RecipeDraft].
///
/// Uses a dual-pass approach:
///   1. Scan for zone marker words ("Ingredients", "Method", etc.) and split
///      the text into title, ingredients zone, and method zone.
///   2. Parse each zone with the appropriate shared utility from
///      [RecipeTextParser].
///
/// If no markers are found, falls back to a line-by-line heuristic.
///
/// This class is the deterministic (offline) fallback for the OCR pipeline.
/// When an LLM is configured, the raw text and hints from this parser are sent
/// to the LLM for a more accurate structure. Without LLM, the result of this
/// parser is used directly.
class OcrRecipeParser {
  /// Parse raw OCR text into a structured [RecipeDraft].
  ///
  /// Returns a best-effort structure even for noisy input. Sparse or missing
  /// fields (null title, empty steps, etc.) are expected and handled gracefully
  /// by the caller.
  static RecipeDraft parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return const RecipeDraft();
    }

    // Step 1: Dual-pass zone segmentation
    final zones = RecipeTextParser.splitZones(rawText);

    // Step 2: Parse ingredient lines into sections + unsectioned ingredients
    final (sections, unsectioned) =
        RecipeTextParser.parseIngredientLines(zones.ingredientLines);

    // Step 3: Parse method lines into steps
    final steps = RecipeTextParser.parseInstructions(zones.methodLines);

    // Note: servings cannot be reliably determined from raw OCR text without
    // an LLM. The field is left null for the user to fill in the form.

    return RecipeDraft(
      name: zones.title,
      ingredients: unsectioned,
      sections: sections,
      steps: steps,
    );
  }
}