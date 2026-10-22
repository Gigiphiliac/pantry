import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/features/shopping/shopping_item_tile.dart';

/// Covers every branch of the subtitle-tap decision rule, including the
/// unhappy paths: unlinked items and tier 1 (always available) must be inert,
/// and items with no stored qty must open the editor rather than toggle.
void main() {
  group('resolveSubtitleTap()', () {
    test('unlinked items (no pantry tier) are inert', () {
      expect(
        resolveSubtitleTap(pantryTier: null, hasStoredQty: false),
        SubtitleTapAction.none,
      );
      expect(
        resolveSubtitleTap(pantryTier: null, hasStoredQty: true),
        SubtitleTapAction.none,
      );
    });

    test(
      'tier 1 (always available) is inert — managed in the library only',
      () {
        expect(
          resolveSubtitleTap(pantryTier: 1, hasStoredQty: false),
          SubtitleTapAction.none,
        );
        expect(
          resolveSubtitleTap(pantryTier: 1, hasStoredQty: true),
          SubtitleTapAction.none,
        );
      },
    );

    test('no stored qty opens the quantity editor (either tier)', () {
      expect(
        resolveSubtitleTap(pantryTier: 2, hasStoredQty: false),
        SubtitleTapAction.editQty,
      );
      expect(
        resolveSubtitleTap(pantryTier: 3, hasStoredQty: false),
        SubtitleTapAction.editQty,
      );
    });

    test('stored qty + per-recipe (tier 3) → hide it (toggle to bulk)', () {
      expect(
        resolveSubtitleTap(pantryTier: 3, hasStoredQty: true),
        SubtitleTapAction.toggleToBulk,
      );
    });

    test('stored qty + bulk (tier 2) → show it (toggle to per-recipe)', () {
      expect(
        resolveSubtitleTap(pantryTier: 2, hasStoredQty: true),
        SubtitleTapAction.toggleToPerRecipe,
      );
    });
  });
}
