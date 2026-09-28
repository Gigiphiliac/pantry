import 'package:pantry/core/ocr/onnx_classifier.dart';
import 'package:pantry/core/recipes/recipe_text_parser.dart';
import 'package:pantry/features/recipes/models/recipe_draft.dart';

/// Result of assembling classified lines into recipe zones.
class AssembledRecipe {
  final String? title;
  final int? servings;
  final List<String> ingredientLines;
  final List<String> methodLines;
  final List<String> nutritionLines;
  final List<String> notesLines;

  const AssembledRecipe({
    this.title,
    this.servings,
    this.ingredientLines = const [],
    this.methodLines = const [],
    this.nutritionLines = const [],
    this.notesLines = const [],
  });
}

/// Converts classifier labels into structured recipe zones.
///
/// Takes the per-line labels from [OnnxClassifier] and groups them into
/// the same intermediate structure that [OcrRecipeParser.splitZones] produces
/// (title, ingredientLines, methodLines), plus additional fields the classifier
/// can identify (servings, nutrition, notes).
///
/// This allows the downstream [IngredientParser] pipeline to remain unchanged.
class ZoneAssembler {
  /// Assemble labelled lines into recipe zones.
  ///
  /// [linesText] and [labels] must be parallel lists (same length, same order).
  /// Returns an [AssembledRecipe] with grouped content.
  static AssembledRecipe assemble(
    List<String> linesText,
    List<OcrLineClassification> labels,
  ) {
    String? title;
    int? servings;
    final ingredientLines = <String>[];
    final methodLines = <String>[];
    final nutritionLines = <String>[];
    final notesLines = <String>[];

    String? currentSectionHeader;
    final sectionBuffer = <String>[];

    for (var i = 0; i < linesText.length; i++) {
      final text = linesText[i];
      final label = labels[i].label;

      switch (label) {
        case OcrLineLabel.title:
          title ??= text;

        case OcrLineLabel.servings:
          final match = RegExp(r'\d+').firstMatch(text);
          if (match != null) {
            servings = int.tryParse(match.group(0)!);
          }

        case OcrLineLabel.sectionHeader:
          // Flush previous section if any
          if (currentSectionHeader != null && sectionBuffer.isNotEmpty) {
            ingredientLines.add(currentSectionHeader);
            ingredientLines.addAll(sectionBuffer);
            sectionBuffer.clear();
          }
          currentSectionHeader = text;

        case OcrLineLabel.ingredient:
          if (currentSectionHeader != null) {
            sectionBuffer.add(text);
          } else {
            ingredientLines.add(text);
          }

        case OcrLineLabel.methodStep:
        case OcrLineLabel.methodContinuation:
          // Flush any buffered section before switching to method
          if (currentSectionHeader != null && sectionBuffer.isNotEmpty) {
            ingredientLines.add(currentSectionHeader);
            ingredientLines.addAll(sectionBuffer);
            sectionBuffer.clear();
          }
          currentSectionHeader = null;
          methodLines.add(text);

        case OcrLineLabel.nutrition:
          nutritionLines.add(text);

        case OcrLineLabel.notes:
          notesLines.add(text);

        case OcrLineLabel.ignore:
        // Skip entirely
      }
    }

    // Flush any remaining buffered section
    if (currentSectionHeader != null && sectionBuffer.isNotEmpty) {
      ingredientLines.add(currentSectionHeader);
      ingredientLines.addAll(sectionBuffer);
    }

    return AssembledRecipe(
      title: title,
      servings: servings,
      ingredientLines: ingredientLines,
      methodLines: methodLines,
      nutritionLines: nutritionLines,
      notesLines: notesLines,
    );
  }

  /// Convert an [AssembledRecipe] into a [RecipeDraft] suitable for the
  /// recipe form.
  ///
  /// Ingredient lines are parsed through [IngredientParser] via
  /// [RecipeTextParser.parseIngredientLines], same as the existing
  /// [OcrRecipeParser].
  static RecipeDraft toRecipeDraft(AssembledRecipe assembled) {
    // Parse ingredients with section detection (colon headers create sections)
    final (sections, unsectioned) = RecipeTextParser.parseIngredientLines(
      assembled.ingredientLines,
    );

    // Parse method lines into individual steps
    final steps = RecipeTextParser.parseInstructions(assembled.methodLines);

    // Collate notes into a single string if any exist (stored separately;
    // RecipeDraft currently has no dedicated notes field — future enhancement).
    // final notesBlock = assembled.notesLines.isNotEmpty
    //     ? assembled.notesLines.join('\n')
    //     : null;

    return RecipeDraft(
      name: assembled.title,
      servings: assembled.servings,
      ingredients: unsectioned,
      sections: sections,
      steps: steps,
    );
  }
}
