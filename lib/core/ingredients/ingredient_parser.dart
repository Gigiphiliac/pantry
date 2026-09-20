import 'package:pantry/core/units/unit_system.dart';
import 'package:pantry/features/recipes/models/recipe_draft.dart';

/// Deterministic 4-stage ingredient line parser.
///
/// Stages:
///   1. Raw cleaning — extract qty, strip unit conversions and ranges
///   2. Parenthetical extraction — extract notes from (...), clean nesting
///   3. Alternative detection — split on " or " and "/" (non-digit right side)
///   4. Word-by-word classifier — classify each token (article/note/unit/name)
///
/// Extensible: add a word to one of the sets below to teach the parser a new
/// note keyword or count unit — no regex or logic changes needed.
class IngredientParser {
  // ── Word sets ──────────────────────────────────────────────────────────────

  /// Count/portion words promoted to the unit field when no unit was already
  /// detected. These overlap with [UnitRegistry.countUnits] but are duplicated
  /// here for forward reference — the classifier checks both sets.
  static const Set<String> _countUnits = {
    'clove', 'cloves', 'fillet', 'fillets', 'slice', 'slices',
    'rasher', 'rashers', 'piece', 'pieces',
    'bunch', 'bunches', 'head', 'heads', 'sprig', 'sprigs',
    'pinch', 'pinches', 'dash', 'dashes',
    'handful', 'handfuls', 'strip', 'strips',
    'stick', 'sticks', 'leaf', 'leaves', 'pod', 'pods',
    'thigh', 'thighs', 'breast', 'breasts', 'steak', 'steaks',
    'wing', 'wings', 'drumstick', 'drumsticks',
    'cup', 'cups', 'scoop', 'scoops', 'drop', 'drops',
    'square', 'squares', 'bar', 'bars', 'slab', 'slabs',
    'wedge', 'wedges', 'ring', 'rings', 'roll', 'rolls',
    'sheet', 'sheets', 'tube', 'tubes', 'loaf', 'loaves',
    'can', 'cans', 'jar', 'jars', 'bottle', 'bottles',
    'bag', 'bags', 'packet', 'packets',
  };

  /// Words that describe preparation, quality, or state — extracted from the
  /// canonical name and accumulated into the notes field.
  static const Set<String> _noteKeywords = {
    // Pre-cooking / trimming
    'skinless', 'boneless', 'seedless', 'halved', 'quartered', 'pitted',
    'shelled', 'husked', 'peeled', 'trimmed', 'deveined', 'scored',
    // Freshness / state
    'fresh', 'dried', 'frozen', 'canned', 'raw', 'smoked', 'cured',
    'pickled', 'aged',
    // Cut
    'chopped', 'diced', 'minced', 'sliced', 'grated', 'shredded',
    'crushed', 'crumbled', 'seeded', 'cubed', 'ground',
    'mashed', 'pureed', 'julienned', 'pounded', 'tenderised',
    // Cook
    'cooked', 'boiled', 'fried', 'roasted', 'toasted', 'baked',
    'grilled', 'broiled', 'steamed', 'poached', 'blanched',
    'parboiled', 'seared', 'charred', 'caramelised', 'candied',
    'glazed', 'marinated',
    // Temperature
    'warm', 'hot', 'cold', 'chilled', 'melted', 'softened', 'cooled',
    'iced',
    // Adverbs (merge with following prep word)
    'roughly', 'finely', 'thickly', 'thinly', 'coarsely',
    'lightly', 'heavily', 'generously', 'fully', 'partially',
  };

  /// Adverbs that form compound with the following word.
  static const Set<String> _adverbs = {
    'roughly', 'finely', 'thickly', 'thinly', 'coarsely',
    'lightly', 'heavily', 'generously', 'fully', 'partially', 'freshly',
  };

  /// Articles and filler words removed entirely.
  static const Set<String> _articles = {
    'a', 'an', 'the', 'of',
  };

  /// Unicode fraction characters and their numeric values.
  static const Map<String, double> _unicodeFractions = {
    '¼': 0.25,
    '½': 0.5,
    '¾': 0.75,
    '⅓': 1 / 3,
    '⅔': 2 / 3,
    '⅛': 0.125,
    '⅜': 0.375,
    '⅝': 0.625,
    '⅞': 0.875,
  };

  // ── Count-unit helper ──────────────────────────────────────────────────────

  static bool _isCountUnit(String word) =>
      _countUnits.contains(word.toLowerCase());

  static bool _isNoteKeyword(String word) =>
      _noteKeywords.contains(word.toLowerCase());

  static bool _isAdverb(String word) =>
      _adverbs.contains(word.toLowerCase());

  static bool _isArticle(String word) =>
      _articles.contains(word.toLowerCase());

  // ── Main public API ────────────────────────────────────────────────────────

  /// Parse a single ingredient line into an [IngredientDraft].
  static IngredientDraft parse(String raw) {
    String s = raw.trim();
    if (s.isEmpty) {
      return const IngredientDraft(name: '', notes: null);
    }

    // ── Stage 1: Raw cleaning ──────────────────────────────────────────

    // 1a. Extract leading quantity
    double? qty;
    String remaining = s;

    // Unicode fraction prefix: "½ tsp salt"
    if (remaining.isNotEmpty && _unicodeFractions.containsKey(remaining[0])) {
      qty = _unicodeFractions[remaining[0]];
      remaining = remaining.substring(1).trim();
    }

    // Leading number including fractions: "1 1/2", "1/2", "2.5"
    if (qty == null) {
      final numMatch = _leadingNumber.firstMatch(remaining);
      if (numMatch != null) {
        if (numMatch.group(1) != null) {
          final whole = double.parse(numMatch.group(1)!);
          final n = double.parse(numMatch.group(2)!);
          final d = double.parse(numMatch.group(3)!);
          qty = whole + n / d;
        } else if (numMatch.group(4) != null) {
          qty = double.parse(numMatch.group(4)!) /
              double.parse(numMatch.group(5)!);
        } else {
          qty = double.tryParse(numMatch.group(6)!);
        }
        remaining = remaining.substring(numMatch.end).trim();
      }
    }

    // 1b. Strip range upper bound: "1 - 1.5" → "1"
    remaining = remaining
        .replaceFirst(
            RegExp(r'^[-–—]\s*\d+(?:\.\d+)?(?:\s+\d+/\d+)?\s*'), '')
        .trim();

    // 1c. Strip unit-conversion slashes: "120g / 4oz" → "120g"
    // Right side must start with a digit/fraction.
    remaining = remaining
        .replaceAll(
          _unitConversionSlash,
          '',
        )
        .trim();

    if (remaining.isEmpty) {
      return IngredientDraft(qty: qty, name: '', notes: null);
    }

    // ── Stage 2: Parenthetical extraction ──────────────────────────────

    final notesParts = <String>[];
    var iterName = remaining;

    while (true) {
      final m = _innermostParen.firstMatch(iterName);
      if (m == null) break;
      // group(2) = the content inside the matched (...)
      final content = m.group(2)!.trim();
      // Clean leading comma and spaces: "(, finely minced" → "finely minced"
      final cleaned = content.replaceFirst(RegExp(r'^,\s*'), '').trim();
      if (cleaned.isNotEmpty) {
        // Prepend so outer notes come first in the final list.
        notesParts.insert(0, cleaned);
      }
      // Reconstruct remaining: group(1) = before paren, group(3) = after paren
      iterName = [m.group(1)!.trim(), m.group(3)!.trim()]
          .where((p) => p.isNotEmpty)
          .join(' ');
    }

    // Clean trailing unmatched closing parens: "garlic cloves )" → "garlic cloves"
    while (iterName.endsWith(')') && !iterName.contains('(')) {
      iterName = iterName.substring(0, iterName.length - 1).trim();
    }
    // Clean trailing unmatched opening parens: "garlic cloves (" → "garlic cloves"
    while (iterName.endsWith('(') && !iterName.contains(')')) {
      iterName = iterName.substring(0, iterName.length - 1).trim();
    }

    String? existingNotes =
        notesParts.isNotEmpty ? notesParts.join(', ') : null;

    // ── Stage 3: Alternative detection ─────────────────────────────────

    // Extract a unit from the primary side BEFORE splitting, so alternatives
    // can inherit it (Stage 4 runs after Stage 3).
    String? detectPrefixUnit(String s) {
      final ws = s.trim().split(RegExp(r'\s+'));
      if (ws.isEmpty) return null;
      if (ws.length >= 2) {
        final two = UnitRegistry.parse('${ws[0]} ${ws[1]}');
        if (two != null) return two.id;
      }
      final one = UnitRegistry.parse(ws[0]);
      if (one != null) return one.id;
      return null;
    }

    final alternatives = <IngredientDraft>[];

    if (iterName.contains(' or ')) {
      final parts =
          iterName.split(' or ').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      if (parts.length > 1) {
        iterName = parts.first;
        final pu = detectPrefixUnit(parts.first);
        for (final alt in parts.skip(1)) {
          alternatives.add(_parsePartial(alt, qty, pu, existingNotes));
        }
      }
    } else {
      final slashIdx = iterName.indexOf('/');
      if (slashIdx > 0) {
        final left = iterName.substring(0, slashIdx).trim();
        final right = iterName.substring(slashIdx + 1).trim();
        // Word/word slash = alternative (digit-starting right was already stripped).
        if (right.isNotEmpty && left.isNotEmpty &&
            !RegExp(r'^[\d¼½¾⅓⅔⅛⅜⅝⅞]').hasMatch(right)) {
          iterName = left;
          final pu = detectPrefixUnit(left);
          alternatives.add(_parsePartial(right, qty, pu, existingNotes));
        }
      }
    }

    // ── Stage 4: Word-by-word classifier ───────────────────────────────

    final tokens = iterName.split(RegExp(r'\s+'));
    final nameWords = <String>[];
    String? detectedUnit;
    final noteWords = <String>[];
    var i = 0;

    while (i < tokens.length) {
      final token = tokens[i];

      // Skip articles
      if (_isArticle(token)) {
        i++;
        continue;
      }

      // Unit detection — prefix position only (end-of-name scan is post-loop).
      if (detectedUnit == null) {
        final unitWord = _tryReadUnitAt(i, tokens);
        if (unitWord != null) {
          detectedUnit = unitWord;
          i++;
          continue;
        }
      }

      // Compound adverb + note word → single note entry
      if (_isAdverb(token) && i + 1 < tokens.length &&
          _isNoteKeyword(tokens[i + 1])) {
        noteWords.add('$token ${tokens[i + 1]}');
        i += 2;
        continue;
      }

      // Single note keyword
      if (_isNoteKeyword(token)) {
        noteWords.add(token);
        i++;
        continue;
      }

      // Default: keep in name
      nameWords.add(token);
      i++;
    }

    // Post-loop: check if the last collected name word is a count unit
    // (e.g. "cloves" in "garlic cloves" → promoted to unit field).
    if (detectedUnit == null && nameWords.length >= 2) {
      final last = nameWords.last.toLowerCase();
      if (_isCountUnit(last) || UnitRegistry.parse(last) != null) {
        detectedUnit = nameWords.removeLast();
      }
    }

    final canonicalName = nameWords.join(' ');

    // Merge Stage 2 notes (from parentheticals) with Stage 4 note keywords.
    final joinedNoteWords = noteWords.join(', ');
    final allNotes = [
      if (joinedNoteWords.isNotEmpty) joinedNoteWords,
      ?existingNotes,
    ].join(', ');

    return IngredientDraft(
      qty: qty,
      unit: detectedUnit,
      name: canonicalName.isEmpty ? iterName : canonicalName,
      notes: allNotes.isEmpty ? null : allNotes,
      alternatives: alternatives,
    );
  }

  // ── Unit detection helpers ────────────────────────────────────────────────

  /// Tries to read a unit from the token at [i] (prefix position).
  static String? _tryReadUnitAt(int i, List<String> tokens) {
    // Try two-word unit first
    if (i + 1 < tokens.length) {
      final twoWord = UnitRegistry.parse('${tokens[i]} ${tokens[i + 1]}');
      if (twoWord != null) return twoWord.id;
    }
    // Try one-word unit
    final oneWord = UnitRegistry.parse(tokens[i]);
    if (oneWord != null) return oneWord.id;
    return null;
  }

  // ── Partial parsing for alternatives ────────────────────────────────────

  /// Parses an alternative fragment. Inherits qty and unit from the primary
  /// if the fragment doesn't supply its own.
  static IngredientDraft _parsePartial(
    String raw,
    double? inheritedQty,
    String? inheritedUnit,
    String? inheritedNotes,
  ) {
    // Only run Stage 4 on the fragment (no qty extraction, no parens, no alt detection).
    final tokens = raw.trim().split(RegExp(r'\s+'));
    if (tokens.isEmpty) return const IngredientDraft(name: '');

    final nameWords = <String>[];
    String? detectedUnit;
    var j = 0;

    while (j < tokens.length) {
      final token = tokens[j];
      if (_isArticle(token)) { j++; continue; }
      if (_isNoteKeyword(token)) { j++; continue; }
      // Detect a unit at prefix position if none inherited.
      if (detectedUnit == null && inheritedUnit == null) {
        final u = _tryReadUnitAt(j, tokens);
        if (u != null) {
          detectedUnit = u;
          j++;
          continue;
        }
      }
      nameWords.add(token);
      j++;
    }

    return IngredientDraft(
      qty: inheritedQty,
      unit: detectedUnit ?? inheritedUnit,
      name: nameWords.join(' '),
      notes: inheritedNotes,
    );
  }

  // ── Registers ────────────────────────────────────────────────────────────

  /// Matches innermost parenthetical content: `(...)` with no nested parens.
  static final RegExp _innermostParen = RegExp(
    r'^(.*?)\s*\(([^()]*)\)\s*(.*)$',
  );

  /// Matches unit-conversion slashes: "/ 4oz" or "/4oz" (digit-starting right).
  /// Only captures the slash, number, and immediate unit suffix — stops before
  /// any following word that isn't part of the quantity (e.g. "/ 7oz  spaghetti"
  /// strips only "/ 7oz", leaving " spaghetti" intact).
  static final RegExp _unitConversionSlash = RegExp(
    r'\s*/\s*(?=[¼½¾⅓⅔⅛⅜⅝⅞\d])[\d¼½¾⅓⅔⅛⅜⅝⅞][^\s,()]*',
  );

  /// Matches a leading number: whole+fraction, simple fraction, or decimal/int.
  static final RegExp _leadingNumber = RegExp(
    r'^(\d+(?:\.\d+)?)\s+(\d+)/(\d+)|'
    r'^(\d+)/(\d+)|'
    r'^(\d+(?:\.\d+)?)',
  );
}