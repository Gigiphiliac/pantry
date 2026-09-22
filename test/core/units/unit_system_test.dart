import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/core/units/unit_system.dart';

void main() {
  group('UnitRegistry.parse()', () {
    test('parses standard unit IDs', () {
      expect(UnitRegistry.parse('g'), equals(UnitRegistry.g));
      expect(UnitRegistry.parse('kg'), equals(UnitRegistry.kg));
      expect(UnitRegistry.parse('ml'), equals(UnitRegistry.ml));
      expect(UnitRegistry.parse('cup'), equals(UnitRegistry.cup));
      expect(UnitRegistry.parse('tsp'), equals(UnitRegistry.tsp));
    });

    test('parses aliases: "grams" → g', () {
      expect(UnitRegistry.parse('grams'), equals(UnitRegistry.g));
      expect(UnitRegistry.parse('gram'), equals(UnitRegistry.g));
    });

    test('parses imperial aliases: "ounces" → oz', () {
      expect(UnitRegistry.parse('ounces'), equals(UnitRegistry.oz));
      expect(UnitRegistry.parse('ounce'), equals(UnitRegistry.oz));
    });

    test('parses US spelling: "milliliter" → ml', () {
      expect(UnitRegistry.parse('milliliter'), equals(UnitRegistry.ml));
    });

    test('parses count aliases: "cloves" → clove', () {
      expect(UnitRegistry.parse('cloves'), equals(UnitRegistry.clove));
    });

    test('parses "pounds" → lb', () {
      expect(UnitRegistry.parse('pounds'), equals(UnitRegistry.lb));
      expect(UnitRegistry.parse('lbs'), equals(UnitRegistry.lb));
    });

    test('parses "teaspoons" → tsp', () {
      expect(UnitRegistry.parse('teaspoons'), equals(UnitRegistry.tsp));
    });

    test('returns null for empty string', () {
      expect(UnitRegistry.parse(''), isNull);
    });

    test('returns null for null', () {
      expect(UnitRegistry.parse(null), isNull);
    });

    test('returns null for unknown unit', () {
      expect(UnitRegistry.parse('xyzzy'), isNull);
    });

    test('is case-insensitive', () {
      expect(UnitRegistry.parse('CUP'), equals(UnitRegistry.cup));
      expect(UnitRegistry.parse('Tablespoon'), equals(UnitRegistry.tbsp));
    });
  });

  group('UnitRegistry.convertToCanonical()', () {
    test('converts kg to g (canonical weight)', () {
      final converted = UnitRegistry.convertToCanonical(1.5, UnitRegistry.kg);
      expect(converted, closeTo(1500.0, 0.01));
    });

    test('converts oz to g', () {
      final converted = UnitRegistry.convertToCanonical(4, UnitRegistry.oz);
      // 4 * 28.3495
      expect(converted, closeTo(113.398, 0.01));
    });

    test('converts cup to ml (canonical volume)', () {
      final converted = UnitRegistry.convertToCanonical(2, UnitRegistry.cup);
      // 2 * 250 (AU cup)
      expect(converted, closeTo(500.0, 0.01));
    });

    test('piece to canonical (1.0 for count)', () {
      final converted = UnitRegistry.convertToCanonical(3, UnitRegistry.piece);
      expect(converted, 3.0);
    });
  });

  group('UnitRegistry.convert()', () {
    test('converts between weight units: kg → g', () {
      final converted = UnitRegistry.convert(
        1,
        UnitRegistry.kg,
        UnitRegistry.g,
      );
      expect(converted, closeTo(1000.0, 0.01));
    });

    test('converts between imperial and metric: oz → g', () {
      final converted = UnitRegistry.convert(
        16,
        UnitRegistry.oz,
        UnitRegistry.g,
      );
      // 16 * 28.3495 / 1.0
      expect(converted, closeTo(453.592, 0.01));
    });

    test('converts between volume: tbsp → ml', () {
      final converted = UnitRegistry.convert(
        1,
        UnitRegistry.tbsp,
        UnitRegistry.ml,
      );
      expect(converted, closeTo(14.787, 0.01));
    });

    test('same unit returns input', () {
      final converted = UnitRegistry.convert(
        5,
        UnitRegistry.cup,
        UnitRegistry.cup,
      );
      expect(converted, closeTo(5.0, 0.01));
    });
  });

  group('UnitRegistry.canonicalUnit()', () {
    test('weight canonical is g', () {
      expect(UnitRegistry.canonicalUnit(UnitFamily.weight), UnitRegistry.g);
    });

    test('volume canonical is ml', () {
      expect(UnitRegistry.canonicalUnit(UnitFamily.volume), UnitRegistry.ml);
    });

    test('count canonical is piece', () {
      expect(UnitRegistry.canonicalUnit(UnitFamily.count), UnitRegistry.piece);
    });
  });

  group('UnitRegistry.preferredDisplayUnit()', () {
    test('metric weight → g', () {
      expect(
        UnitRegistry.preferredDisplayUnit(
          UnitFamily.weight,
          UnitPreference.metric,
        ),
        UnitRegistry.g,
      );
    });

    test('imperial weight → oz', () {
      expect(
        UnitRegistry.preferredDisplayUnit(
          UnitFamily.weight,
          UnitPreference.imperial,
        ),
        UnitRegistry.oz,
      );
    });

    test('imperial volume → floz', () {
      expect(
        UnitRegistry.preferredDisplayUnit(
          UnitFamily.volume,
          UnitPreference.imperial,
        ),
        UnitRegistry.floz,
      );
    });

    test('count → piece regardless of preference', () {
      expect(
        UnitRegistry.preferredDisplayUnit(
          UnitFamily.count,
          UnitPreference.metric,
        ),
        UnitRegistry.piece,
      );
    });
  });

  group('UnitRegistry.formatQty()', () {
    test('integer drops decimals: 3.0 → "3"', () {
      expect(UnitRegistry.formatQty(3.0), '3');
    });

    test('0.5 → "0.5"', () {
      expect(UnitRegistry.formatQty(0.5), '0.5');
    });

    test('1.5 → "1.5"', () {
      expect(UnitRegistry.formatQty(1.5), '1.5');
    });

    test('1.3333 → "1.33"', () {
      expect(UnitRegistry.formatQty(1.3333), '1.33');
    });

    test('trims trailing zeros: 2.50 → "2.5"', () {
      expect(UnitRegistry.formatQty(2.50), '2.5');
    });
  });

  group('UnitRegistry.unitsForFamily()', () {
    test('weight units list is correct', () {
      expect(
        UnitRegistry.unitsForFamily(UnitFamily.weight),
        containsAll([UnitRegistry.g, UnitRegistry.kg, UnitRegistry.oz]),
      );
    });

    test('volume units list is correct', () {
      expect(
        UnitRegistry.unitsForFamily(UnitFamily.volume),
        containsAll([UnitRegistry.ml, UnitRegistry.tsp, UnitRegistry.cup]),
      );
    });

    test('count units list includes common count units', () {
      expect(
        UnitRegistry.unitsForFamily(UnitFamily.count),
        containsAll([
          UnitRegistry.piece,
          UnitRegistry.clove,
          UnitRegistry.slice,
          UnitRegistry.can,
        ]),
      );
    });
  });

  group('UnitFamily enum', () {
    test('three distinct families', () {
      expect(UnitFamily.values.length, 3);
      expect(
        UnitFamily.values,
        containsAll([UnitFamily.weight, UnitFamily.volume, UnitFamily.count]),
      );
    });
  });
}
