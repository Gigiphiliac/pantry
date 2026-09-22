enum UnitFamily { weight, volume, count }

enum UnitPreference { metric, imperial }

class Unit {
  final String id;
  final String displayName;
  final String abbreviation;
  final UnitFamily family;
  // Multiply qty by this to get canonical unit (g for weight, ml for volume, piece for count)
  final double toCanonical;

  const Unit({
    required this.id,
    required this.displayName,
    required this.abbreviation,
    required this.family,
    required this.toCanonical,
  });
}

class UnitRegistry {
  // ── Weight (canonical: g) ──────────────────────────────────────────────────
  static const Unit g = Unit(
    id: 'g',
    displayName: 'grams',
    abbreviation: 'g',
    family: UnitFamily.weight,
    toCanonical: 1.0,
  );
  static const Unit kg = Unit(
    id: 'kg',
    displayName: 'kilograms',
    abbreviation: 'kg',
    family: UnitFamily.weight,
    toCanonical: 1000.0,
  );
  static const Unit mg = Unit(
    id: 'mg',
    displayName: 'milligrams',
    abbreviation: 'mg',
    family: UnitFamily.weight,
    toCanonical: 0.001,
  );
  static const Unit oz = Unit(
    id: 'oz',
    displayName: 'ounces',
    abbreviation: 'oz',
    family: UnitFamily.weight,
    toCanonical: 28.3495,
  );
  static const Unit lb = Unit(
    id: 'lb',
    displayName: 'pounds',
    abbreviation: 'lb',
    family: UnitFamily.weight,
    toCanonical: 453.592,
  );

  // ── Volume (canonical: ml) ─────────────────────────────────────────────────
  static const Unit ml = Unit(
    id: 'ml',
    displayName: 'millilitres',
    abbreviation: 'ml',
    family: UnitFamily.volume,
    toCanonical: 1.0,
  );
  static const Unit l = Unit(
    id: 'l',
    displayName: 'litres',
    abbreviation: 'L',
    family: UnitFamily.volume,
    toCanonical: 1000.0,
  );
  static const Unit tsp = Unit(
    id: 'tsp',
    displayName: 'teaspoon',
    abbreviation: 'tsp',
    family: UnitFamily.volume,
    toCanonical: 4.929,
  );
  static const Unit tbsp = Unit(
    id: 'tbsp',
    displayName: 'tablespoon',
    abbreviation: 'tbsp',
    family: UnitFamily.volume,
    toCanonical: 14.787,
  );
  // AU standard cup = 250 ml
  static const Unit cup = Unit(
    id: 'cup',
    displayName: 'cup',
    abbreviation: 'cup',
    family: UnitFamily.volume,
    toCanonical: 250.0,
  );
  static const Unit floz = Unit(
    id: 'floz',
    displayName: 'fluid ounce',
    abbreviation: 'fl oz',
    family: UnitFamily.volume,
    toCanonical: 29.574,
  );
  static const Unit pint = Unit(
    id: 'pint',
    displayName: 'pint',
    abbreviation: 'pt',
    family: UnitFamily.volume,
    toCanonical: 473.176,
  );

  // ── Count ─────────────────────────────────────────────────────────────────
  // Count units do NOT cross-convert — only exact same-unit stacking is allowed.
  static const Unit piece = Unit(
    id: 'piece',
    displayName: 'piece',
    abbreviation: 'pc',
    family: UnitFamily.count,
    toCanonical: 1.0,
  );
  static const Unit can = Unit(
    id: 'can',
    displayName: 'can',
    abbreviation: 'can',
    family: UnitFamily.count,
    toCanonical: 1.0,
  );
  static const Unit jar = Unit(
    id: 'jar',
    displayName: 'jar',
    abbreviation: 'jar',
    family: UnitFamily.count,
    toCanonical: 1.0,
  );
  static const Unit bottle = Unit(
    id: 'bottle',
    displayName: 'bottle',
    abbreviation: 'bottle',
    family: UnitFamily.count,
    toCanonical: 1.0,
  );
  static const Unit bag = Unit(
    id: 'bag',
    displayName: 'bag',
    abbreviation: 'bag',
    family: UnitFamily.count,
    toCanonical: 1.0,
  );
  static const Unit packet = Unit(
    id: 'packet',
    displayName: 'packet',
    abbreviation: 'packet',
    family: UnitFamily.count,
    toCanonical: 1.0,
  );
  static const Unit bunch = Unit(
    id: 'bunch',
    displayName: 'bunch',
    abbreviation: 'bunch',
    family: UnitFamily.count,
    toCanonical: 1.0,
  );
  static const Unit head = Unit(
    id: 'head',
    displayName: 'head',
    abbreviation: 'head',
    family: UnitFamily.count,
    toCanonical: 1.0,
  );
  static const Unit clove = Unit(
    id: 'clove',
    displayName: 'clove',
    abbreviation: 'clove',
    family: UnitFamily.count,
    toCanonical: 1.0,
  );
  static const Unit slice = Unit(
    id: 'slice',
    displayName: 'slice',
    abbreviation: 'slice',
    family: UnitFamily.count,
    toCanonical: 1.0,
  );
  static const Unit rasher = Unit(
    id: 'rasher',
    displayName: 'rasher',
    abbreviation: 'rasher',
    family: UnitFamily.count,
    toCanonical: 1.0,
  );
  static const Unit sprig = Unit(
    id: 'sprig',
    displayName: 'sprig',
    abbreviation: 'sprig',
    family: UnitFamily.count,
    toCanonical: 1.0,
  );
  static const Unit pinch = Unit(
    id: 'pinch',
    displayName: 'pinch',
    abbreviation: 'pinch',
    family: UnitFamily.count,
    toCanonical: 1.0,
  );
  static const Unit dash = Unit(
    id: 'dash',
    displayName: 'dash',
    abbreviation: 'dash',
    family: UnitFamily.count,
    toCanonical: 1.0,
  );
  static const Unit handful = Unit(
    id: 'handful',
    displayName: 'handful',
    abbreviation: 'handful',
    family: UnitFamily.count,
    toCanonical: 1.0,
  );
  static const Unit fillet = Unit(
    id: 'fillet',
    displayName: 'fillet',
    abbreviation: 'fillet',
    family: UnitFamily.count,
    toCanonical: 1.0,
  );

  // Ordered lists per family — controls bottom-sheet display order
  static const List<Unit> weightUnits = [g, kg, mg, oz, lb];
  static const List<Unit> volumeUnits = [ml, l, tsp, tbsp, cup, floz, pint];
  static const List<Unit> countUnits = [
    piece,
    can,
    jar,
    bottle,
    bag,
    packet,
    bunch,
    head,
    clove,
    slice,
    rasher,
    sprig,
    pinch,
    dash,
    handful,
    fillet,
  ];

  static const Map<String, Unit> _byId = {
    'g': g,
    'kg': kg,
    'mg': mg,
    'oz': oz,
    'lb': lb,
    'ml': ml,
    'l': l,
    'tsp': tsp,
    'tbsp': tbsp,
    'cup': cup,
    'floz': floz,
    'pint': pint,
    'piece': piece,
    'can': can,
    'jar': jar,
    'bottle': bottle,
    'bag': bag,
    'packet': packet,
    'bunch': bunch,
    'head': head,
    'clove': clove,
    'slice': slice,
    'rasher': rasher,
    'sprig': sprig,
    'pinch': pinch,
    'dash': dash,
    'handful': handful,
    'fillet': fillet,
  };

  // Alias map: normalises strings from LLM/OCR/free-text to unit IDs
  static const Map<String, String> _aliases = {
    // Weight
    'gram': 'g', 'grams': 'g', 'g': 'g',
    'kilogram': 'kg', 'kilograms': 'kg', 'kg': 'kg',
    'milligram': 'mg', 'milligrams': 'mg', 'mg': 'mg',
    'ounce': 'oz', 'ounces': 'oz', 'oz': 'oz',
    'pound': 'lb', 'pounds': 'lb', 'lb': 'lb', 'lbs': 'lb',
    // Volume
    'millilitre': 'ml', 'millilitres': 'ml',
    'milliliter': 'ml', 'milliliters': 'ml', 'ml': 'ml',
    'litre': 'l', 'litres': 'l', 'liter': 'l', 'liters': 'l', 'l': 'l',
    'teaspoon': 'tsp', 'teaspoons': 'tsp', 'tsp': 'tsp', 't': 'tsp',
    'tablespoon': 'tbsp', 'tablespoons': 'tbsp',
    'tbsp': 'tbsp', 'tbs': 'tbsp', 'tbsp.': 'tbsp',
    'cup': 'cup', 'cups': 'cup',
    'fluid ounce': 'floz', 'fluid ounces': 'floz',
    'fl oz': 'floz', 'floz': 'floz', 'fl. oz.': 'floz', 'fl. oz': 'floz',
    'pint': 'pint', 'pints': 'pint', 'pt': 'pint',
    // Count
    'piece': 'piece', 'pieces': 'piece', 'pc': 'piece',
    'unit': 'piece', 'units': 'piece', 'whole': 'piece',
    'item': 'piece', 'items': 'piece',
    // Containers / package units
    'can': 'can', 'cans': 'can', 'tin': 'can', 'tins': 'can',
    'jar': 'jar', 'jars': 'jar',
    'bottle': 'bottle', 'bottles': 'bottle',
    'bag': 'bag', 'bags': 'bag',
    'packet': 'packet',
    'packets': 'packet',
    'pack': 'packet',
    'packs': 'packet',
    'bunch': 'bunch', 'bunches': 'bunch',
    'head': 'head', 'heads': 'head',
    'clove': 'clove', 'cloves': 'clove',
    'slice': 'slice', 'slices': 'slice',
    'rasher': 'rasher', 'rashers': 'rasher',
    'sprig': 'sprig', 'sprigs': 'sprig',
    'pinch': 'pinch', 'pinches': 'pinch',
    'dash': 'dash', 'dashes': 'dash',
    'handful': 'handful', 'handfuls': 'handful',
    'fillet': 'fillet', 'fillets': 'fillet',
  };

  /// Parse a unit string (from LLM output, free-text, or stored ID) to a Unit.
  /// Returns null for empty/unrecognised strings.
  static Unit? parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final key = raw.trim().toLowerCase();
    final id = _aliases[key] ?? key;
    return _byId[id];
  }

  /// Convert [qty] from [from] to canonical unit for that family.
  static double convertToCanonical(double qty, Unit from) =>
      qty * from.toCanonical;

  /// Convert [qty] from [from] to [to]. Both must be the same family.
  static double convert(double qty, Unit from, Unit to) =>
      qty * from.toCanonical / to.toCanonical;

  /// Canonical unit for a family (stored format after stacking).
  static Unit canonicalUnit(UnitFamily family) {
    switch (family) {
      case UnitFamily.weight:
        return g;
      case UnitFamily.volume:
        return ml;
      case UnitFamily.count:
        return piece;
    }
  }

  /// Preferred display unit for a family based on metric/imperial preference.
  static Unit preferredDisplayUnit(UnitFamily family, UnitPreference pref) {
    switch (family) {
      case UnitFamily.weight:
        return pref == UnitPreference.imperial ? oz : g;
      case UnitFamily.volume:
        return pref == UnitPreference.imperial ? floz : ml;
      case UnitFamily.count:
        return piece;
    }
  }

  static List<Unit> unitsForFamily(UnitFamily family) {
    switch (family) {
      case UnitFamily.weight:
        return weightUnits;
      case UnitFamily.volume:
        return volumeUnits;
      case UnitFamily.count:
        return countUnits;
    }
  }

  /// Format a quantity for display — no unnecessary trailing zeros.
  static String formatQty(double qty) {
    if (qty == qty.roundToDouble()) return qty.toInt().toString();
    return qty
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}
