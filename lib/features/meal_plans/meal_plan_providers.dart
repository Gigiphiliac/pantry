import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry/db/database.dart';
import 'package:pantry/main.dart';

// ── Slot data for drag-and-drop ──────────────────────────────────────────────

/// Lightweight value used for drag-and-drop payloads, avoiding Drift's
/// immutable DataClass so we can pass individual instances around.
class MealSlotData {
  final int id;
  final DateTime date;
  final String mealType;
  final String slotName;
  final int? recipeId;
  final String? notes;

  const MealSlotData({
    required this.id,
    required this.date,
    required this.mealType,
    required this.slotName,
    this.recipeId,
    this.notes,
  });

  factory MealSlotData.fromMealSlot(MealSlot s) => MealSlotData(
    id: s.id,
    date: s.date,
    mealType: s.mealType,
    slotName: s.slotName,
    recipeId: s.recipeId,
    notes: s.notes,
  );
}

// ── Queries ──────────────────────────────────────────────────────────────────

/// Watch all MealSlots for a 7-day range starting at [weekStart].
/// Returns a map keyed by `"${date}_${mealType}"` for quick lookup.
final mealSlotsForWeekProvider =
    StreamProvider.family<Map<String, MealSlotData>, DateTime>((
      ref,
      weekStart,
    ) {
      final db = ref.watch(dbProvider);
      final weekEnd = weekStart.add(const Duration(days: 6));

      return (db.select(
        db.mealSlots,
      )..where((t) => t.date.isBetweenValues(weekStart, weekEnd))).watch().map(
        (rows) => {
          for (final s in rows)
            '${dateKey(s.date)}_${s.mealType}': MealSlotData.fromMealSlot(s),
        },
      );
    });

/// All recipes for the recipe picker sheet.
final allRecipesForPickerProvider = StreamProvider<List<Recipe>>((ref) {
  final db = ref.watch(dbProvider);
  return (db.select(
    db.recipes,
  )..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
});

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Normalise a DateTime to its date-only representation (strips time).
DateTime normaliseDate(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

String dateKey(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

/// Compute Monday of the week containing [date].
DateTime weekStartFor(DateTime date) {
  final normalised = normaliseDate(date);
  final dow = normalised.weekday; // 1=Mon ... 7=Sun
  return normalised.subtract(Duration(days: dow - 1));
}

// ── Mutations ────────────────────────────────────────────────────────────────

class MealPlanOps {
  final AppDatabase _db;

  MealPlanOps(this._db);

  /// Upsert a slot: insert if no row for (date, mealType), otherwise update.
  Future<MealSlotData> upsertSlot({
    required DateTime date,
    required String mealType,
    required String slotName,
    int? recipeId,
    String? notes,
  }) async {
    final normalised = normaliseDate(date);
    // Check existing
    final existing =
        await (_db.select(_db.mealSlots)..where(
              (t) => t.date.equals(normalised) & t.mealType.equals(mealType),
            ))
            .get();

    if (existing.isNotEmpty) {
      final row = existing.first;
      await (_db.update(
        _db.mealSlots,
      )..where((t) => t.id.equals(row.id))).write(
        MealSlotsCompanion(
          slotName: Value(slotName),
          recipeId: Value(recipeId),
          notes: Value(notes),
        ),
      );
      return MealSlotData(
        id: row.id,
        date: normalised,
        mealType: mealType,
        slotName: slotName,
        recipeId: recipeId,
        notes: notes,
      );
    } else {
      final id = await _db
          .into(_db.mealSlots)
          .insert(
            MealSlotsCompanion.insert(
              date: normalised,
              mealType: mealType,
              slotName: slotName,
              recipeId: recipeId == null
                  ? const Value.absent()
                  : Value(recipeId),
              notes: notes == null ? const Value.absent() : Value(notes),
            ),
          );
      return MealSlotData(
        id: id,
        date: normalised,
        mealType: mealType,
        slotName: slotName,
        recipeId: recipeId,
        notes: notes,
      );
    }
  }

  /// Delete a slot by id.
  Future<void> clearSlot(int id) async {
    await (_db.delete(_db.mealSlots)..where((t) => t.id.equals(id))).go();
  }

  /// Swap the contents of two slots. If [targetDate] / [targetMealType] has
  /// no row, the source slot moves there (source becomes empty).
  Future<void> swapSlots({
    required int sourceId,
    required DateTime sourceDate,
    required String sourceMealType,
    required DateTime targetDate,
    required String targetMealType,
  }) async {
    final normalisedTarget = normaliseDate(targetDate);

    // Fetch source row
    final sourceRows = await (_db.select(
      _db.mealSlots,
    )..where((t) => t.id.equals(sourceId))).get();
    if (sourceRows.isEmpty) return;
    final source = sourceRows.first;

    // Fetch target row (may not exist)
    final targetRows =
        await (_db.select(_db.mealSlots)..where(
              (t) =>
                  t.date.equals(normalisedTarget) &
                  t.mealType.equals(targetMealType),
            ))
            .get();

    if (targetRows.isNotEmpty) {
      final target = targetRows.first;
      // Swap: exchange slotName, recipeId, notes
      await (_db.update(
        _db.mealSlots,
      )..where((t) => t.id.equals(source.id))).write(
        MealSlotsCompanion(
          slotName: Value(target.slotName),
          recipeId: Value(target.recipeId),
          notes: Value(target.notes),
        ),
      );
      await (_db.update(
        _db.mealSlots,
      )..where((t) => t.id.equals(target.id))).write(
        MealSlotsCompanion(
          slotName: Value(source.slotName),
          recipeId: Value(source.recipeId),
          notes: Value(source.notes),
        ),
      );
    } else {
      // Move source to target (no swap)
      await (_db.update(
        _db.mealSlots,
      )..where((t) => t.id.equals(source.id))).write(
        MealSlotsCompanion(
          date: Value(normalisedTarget),
          mealType: Value(targetMealType),
        ),
      );
    }
  }

  /// Update just the recipe link on an existing slot.
  Future<void> linkRecipe(int slotId, int? recipeId) async {
    await (_db.update(_db.mealSlots)..where((t) => t.id.equals(slotId))).write(
      MealSlotsCompanion(recipeId: Value(recipeId)),
    );
  }

  /// Update just the slot name.
  Future<void> updateSlotName(int slotId, String slotName) async {
    await (_db.update(_db.mealSlots)..where((t) => t.id.equals(slotId))).write(
      MealSlotsCompanion(slotName: Value(slotName)),
    );
  }
}

final mealPlanOpsProvider = Provider<MealPlanOps>((ref) {
  final db = ref.watch(dbProvider);
  return MealPlanOps(db);
});
