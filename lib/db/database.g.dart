// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $IngredientsTable extends Ingredients
    with TableInfo<$IngredientsTable, Ingredient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _preferredUnitMeta = const VerificationMeta(
    'preferredUnit',
  );
  @override
  late final GeneratedColumn<String> preferredUnit = GeneratedColumn<String>(
    'preferred_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nutritionRefMeta = const VerificationMeta(
    'nutritionRef',
  );
  @override
  late final GeneratedColumn<String> nutritionRef = GeneratedColumn<String>(
    'nutrition_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, preferredUnit, nutritionRef];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredients';
  @override
  VerificationContext validateIntegrity(
    Insertable<Ingredient> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('preferred_unit')) {
      context.handle(
        _preferredUnitMeta,
        preferredUnit.isAcceptableOrUnknown(
          data['preferred_unit']!,
          _preferredUnitMeta,
        ),
      );
    }
    if (data.containsKey('nutrition_ref')) {
      context.handle(
        _nutritionRefMeta,
        nutritionRef.isAcceptableOrUnknown(
          data['nutrition_ref']!,
          _nutritionRefMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ingredient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ingredient(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      preferredUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_unit'],
      ),
      nutritionRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nutrition_ref'],
      ),
    );
  }

  @override
  $IngredientsTable createAlias(String alias) {
    return $IngredientsTable(attachedDatabase, alias);
  }
}

class Ingredient extends DataClass implements Insertable<Ingredient> {
  final int id;
  final String name;
  final String? preferredUnit;
  final String? nutritionRef;
  const Ingredient({
    required this.id,
    required this.name,
    this.preferredUnit,
    this.nutritionRef,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || preferredUnit != null) {
      map['preferred_unit'] = Variable<String>(preferredUnit);
    }
    if (!nullToAbsent || nutritionRef != null) {
      map['nutrition_ref'] = Variable<String>(nutritionRef);
    }
    return map;
  }

  IngredientsCompanion toCompanion(bool nullToAbsent) {
    return IngredientsCompanion(
      id: Value(id),
      name: Value(name),
      preferredUnit: preferredUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(preferredUnit),
      nutritionRef: nutritionRef == null && nullToAbsent
          ? const Value.absent()
          : Value(nutritionRef),
    );
  }

  factory Ingredient.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ingredient(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      preferredUnit: serializer.fromJson<String?>(json['preferredUnit']),
      nutritionRef: serializer.fromJson<String?>(json['nutritionRef']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'preferredUnit': serializer.toJson<String?>(preferredUnit),
      'nutritionRef': serializer.toJson<String?>(nutritionRef),
    };
  }

  Ingredient copyWith({
    int? id,
    String? name,
    Value<String?> preferredUnit = const Value.absent(),
    Value<String?> nutritionRef = const Value.absent(),
  }) => Ingredient(
    id: id ?? this.id,
    name: name ?? this.name,
    preferredUnit: preferredUnit.present
        ? preferredUnit.value
        : this.preferredUnit,
    nutritionRef: nutritionRef.present ? nutritionRef.value : this.nutritionRef,
  );
  Ingredient copyWithCompanion(IngredientsCompanion data) {
    return Ingredient(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      preferredUnit: data.preferredUnit.present
          ? data.preferredUnit.value
          : this.preferredUnit,
      nutritionRef: data.nutritionRef.present
          ? data.nutritionRef.value
          : this.nutritionRef,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ingredient(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('preferredUnit: $preferredUnit, ')
          ..write('nutritionRef: $nutritionRef')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, preferredUnit, nutritionRef);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ingredient &&
          other.id == this.id &&
          other.name == this.name &&
          other.preferredUnit == this.preferredUnit &&
          other.nutritionRef == this.nutritionRef);
}

class IngredientsCompanion extends UpdateCompanion<Ingredient> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> preferredUnit;
  final Value<String?> nutritionRef;
  const IngredientsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.preferredUnit = const Value.absent(),
    this.nutritionRef = const Value.absent(),
  });
  IngredientsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.preferredUnit = const Value.absent(),
    this.nutritionRef = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Ingredient> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? preferredUnit,
    Expression<String>? nutritionRef,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (preferredUnit != null) 'preferred_unit': preferredUnit,
      if (nutritionRef != null) 'nutrition_ref': nutritionRef,
    });
  }

  IngredientsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? preferredUnit,
    Value<String?>? nutritionRef,
  }) {
    return IngredientsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      preferredUnit: preferredUnit ?? this.preferredUnit,
      nutritionRef: nutritionRef ?? this.nutritionRef,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (preferredUnit.present) {
      map['preferred_unit'] = Variable<String>(preferredUnit.value);
    }
    if (nutritionRef.present) {
      map['nutrition_ref'] = Variable<String>(nutritionRef.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('preferredUnit: $preferredUnit, ')
          ..write('nutritionRef: $nutritionRef')
          ..write(')'))
        .toString();
  }
}

class $IngredientAliasesTable extends IngredientAliases
    with TableInfo<$IngredientAliasesTable, IngredientAliase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientAliasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _aliasMeta = const VerificationMeta('alias');
  @override
  late final GeneratedColumn<String> alias = GeneratedColumn<String>(
    'alias',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _ingredientIdMeta = const VerificationMeta(
    'ingredientId',
  );
  @override
  late final GeneratedColumn<int> ingredientId = GeneratedColumn<int>(
    'ingredient_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, alias, ingredientId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredient_aliases';
  @override
  VerificationContext validateIntegrity(
    Insertable<IngredientAliase> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('alias')) {
      context.handle(
        _aliasMeta,
        alias.isAcceptableOrUnknown(data['alias']!, _aliasMeta),
      );
    } else if (isInserting) {
      context.missing(_aliasMeta);
    }
    if (data.containsKey('ingredient_id')) {
      context.handle(
        _ingredientIdMeta,
        ingredientId.isAcceptableOrUnknown(
          data['ingredient_id']!,
          _ingredientIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ingredientIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IngredientAliase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IngredientAliase(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      alias: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alias'],
      )!,
      ingredientId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ingredient_id'],
      )!,
    );
  }

  @override
  $IngredientAliasesTable createAlias(String alias) {
    return $IngredientAliasesTable(attachedDatabase, alias);
  }
}

class IngredientAliase extends DataClass
    implements Insertable<IngredientAliase> {
  final int id;
  final String alias;
  final int ingredientId;
  const IngredientAliase({
    required this.id,
    required this.alias,
    required this.ingredientId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['alias'] = Variable<String>(alias);
    map['ingredient_id'] = Variable<int>(ingredientId);
    return map;
  }

  IngredientAliasesCompanion toCompanion(bool nullToAbsent) {
    return IngredientAliasesCompanion(
      id: Value(id),
      alias: Value(alias),
      ingredientId: Value(ingredientId),
    );
  }

  factory IngredientAliase.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IngredientAliase(
      id: serializer.fromJson<int>(json['id']),
      alias: serializer.fromJson<String>(json['alias']),
      ingredientId: serializer.fromJson<int>(json['ingredientId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'alias': serializer.toJson<String>(alias),
      'ingredientId': serializer.toJson<int>(ingredientId),
    };
  }

  IngredientAliase copyWith({int? id, String? alias, int? ingredientId}) =>
      IngredientAliase(
        id: id ?? this.id,
        alias: alias ?? this.alias,
        ingredientId: ingredientId ?? this.ingredientId,
      );
  IngredientAliase copyWithCompanion(IngredientAliasesCompanion data) {
    return IngredientAliase(
      id: data.id.present ? data.id.value : this.id,
      alias: data.alias.present ? data.alias.value : this.alias,
      ingredientId: data.ingredientId.present
          ? data.ingredientId.value
          : this.ingredientId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IngredientAliase(')
          ..write('id: $id, ')
          ..write('alias: $alias, ')
          ..write('ingredientId: $ingredientId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, alias, ingredientId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IngredientAliase &&
          other.id == this.id &&
          other.alias == this.alias &&
          other.ingredientId == this.ingredientId);
}

class IngredientAliasesCompanion extends UpdateCompanion<IngredientAliase> {
  final Value<int> id;
  final Value<String> alias;
  final Value<int> ingredientId;
  const IngredientAliasesCompanion({
    this.id = const Value.absent(),
    this.alias = const Value.absent(),
    this.ingredientId = const Value.absent(),
  });
  IngredientAliasesCompanion.insert({
    this.id = const Value.absent(),
    required String alias,
    required int ingredientId,
  }) : alias = Value(alias),
       ingredientId = Value(ingredientId);
  static Insertable<IngredientAliase> custom({
    Expression<int>? id,
    Expression<String>? alias,
    Expression<int>? ingredientId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (alias != null) 'alias': alias,
      if (ingredientId != null) 'ingredient_id': ingredientId,
    });
  }

  IngredientAliasesCompanion copyWith({
    Value<int>? id,
    Value<String>? alias,
    Value<int>? ingredientId,
  }) {
    return IngredientAliasesCompanion(
      id: id ?? this.id,
      alias: alias ?? this.alias,
      ingredientId: ingredientId ?? this.ingredientId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (alias.present) {
      map['alias'] = Variable<String>(alias.value);
    }
    if (ingredientId.present) {
      map['ingredient_id'] = Variable<int>(ingredientId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientAliasesCompanion(')
          ..write('id: $id, ')
          ..write('alias: $alias, ')
          ..write('ingredientId: $ingredientId')
          ..write(')'))
        .toString();
  }
}

class $ShoppingListsTable extends ShoppingLists
    with TableInfo<$ShoppingListsTable, ShoppingList> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt, archivedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShoppingList> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShoppingList map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingList(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
    );
  }

  @override
  $ShoppingListsTable createAlias(String alias) {
    return $ShoppingListsTable(attachedDatabase, alias);
  }
}

class ShoppingList extends DataClass implements Insertable<ShoppingList> {
  final int id;
  final String name;
  final DateTime createdAt;
  final DateTime? archivedAt;
  const ShoppingList({
    required this.id,
    required this.name,
    required this.createdAt,
    this.archivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    return map;
  }

  ShoppingListsCompanion toCompanion(bool nullToAbsent) {
    return ShoppingListsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
    );
  }

  factory ShoppingList.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingList(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
    };
  }

  ShoppingList copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    Value<DateTime?> archivedAt = const Value.absent(),
  }) => ShoppingList(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
  );
  ShoppingList copyWithCompanion(ShoppingListsCompanion data) {
    return ShoppingList(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingList(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt, archivedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingList &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.archivedAt == this.archivedAt);
}

class ShoppingListsCompanion extends UpdateCompanion<ShoppingList> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<DateTime?> archivedAt;
  const ShoppingListsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
  });
  ShoppingListsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.createdAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<ShoppingList> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? archivedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (archivedAt != null) 'archived_at': archivedAt,
    });
  }

  ShoppingListsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<DateTime?>? archivedAt,
  }) {
    return ShoppingListsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingListsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }
}

class $ShoppingListStoresTable extends ShoppingListStores
    with TableInfo<$ShoppingListStoresTable, ShoppingListStore> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingListStoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<int> listId = GeneratedColumn<int>(
    'list_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeNameMeta = const VerificationMeta(
    'storeName',
  );
  @override
  late final GeneratedColumn<String> storeName = GeneratedColumn<String>(
    'store_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, listId, storeName, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_list_stores';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShoppingListStore> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('list_id')) {
      context.handle(
        _listIdMeta,
        listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta),
      );
    } else if (isInserting) {
      context.missing(_listIdMeta);
    }
    if (data.containsKey('store_name')) {
      context.handle(
        _storeNameMeta,
        storeName.isAcceptableOrUnknown(data['store_name']!, _storeNameMeta),
      );
    } else if (isInserting) {
      context.missing(_storeNameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShoppingListStore map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingListStore(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      listId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}list_id'],
      )!,
      storeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $ShoppingListStoresTable createAlias(String alias) {
    return $ShoppingListStoresTable(attachedDatabase, alias);
  }
}

class ShoppingListStore extends DataClass
    implements Insertable<ShoppingListStore> {
  final int id;
  final int listId;
  final String storeName;
  final int sortOrder;
  const ShoppingListStore({
    required this.id,
    required this.listId,
    required this.storeName,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['list_id'] = Variable<int>(listId);
    map['store_name'] = Variable<String>(storeName);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ShoppingListStoresCompanion toCompanion(bool nullToAbsent) {
    return ShoppingListStoresCompanion(
      id: Value(id),
      listId: Value(listId),
      storeName: Value(storeName),
      sortOrder: Value(sortOrder),
    );
  }

  factory ShoppingListStore.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingListStore(
      id: serializer.fromJson<int>(json['id']),
      listId: serializer.fromJson<int>(json['listId']),
      storeName: serializer.fromJson<String>(json['storeName']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'listId': serializer.toJson<int>(listId),
      'storeName': serializer.toJson<String>(storeName),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  ShoppingListStore copyWith({
    int? id,
    int? listId,
    String? storeName,
    int? sortOrder,
  }) => ShoppingListStore(
    id: id ?? this.id,
    listId: listId ?? this.listId,
    storeName: storeName ?? this.storeName,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  ShoppingListStore copyWithCompanion(ShoppingListStoresCompanion data) {
    return ShoppingListStore(
      id: data.id.present ? data.id.value : this.id,
      listId: data.listId.present ? data.listId.value : this.listId,
      storeName: data.storeName.present ? data.storeName.value : this.storeName,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingListStore(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('storeName: $storeName, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, listId, storeName, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingListStore &&
          other.id == this.id &&
          other.listId == this.listId &&
          other.storeName == this.storeName &&
          other.sortOrder == this.sortOrder);
}

class ShoppingListStoresCompanion extends UpdateCompanion<ShoppingListStore> {
  final Value<int> id;
  final Value<int> listId;
  final Value<String> storeName;
  final Value<int> sortOrder;
  const ShoppingListStoresCompanion({
    this.id = const Value.absent(),
    this.listId = const Value.absent(),
    this.storeName = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  ShoppingListStoresCompanion.insert({
    this.id = const Value.absent(),
    required int listId,
    required String storeName,
    this.sortOrder = const Value.absent(),
  }) : listId = Value(listId),
       storeName = Value(storeName);
  static Insertable<ShoppingListStore> custom({
    Expression<int>? id,
    Expression<int>? listId,
    Expression<String>? storeName,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (listId != null) 'list_id': listId,
      if (storeName != null) 'store_name': storeName,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  ShoppingListStoresCompanion copyWith({
    Value<int>? id,
    Value<int>? listId,
    Value<String>? storeName,
    Value<int>? sortOrder,
  }) {
    return ShoppingListStoresCompanion(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      storeName: storeName ?? this.storeName,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<int>(listId.value);
    }
    if (storeName.present) {
      map['store_name'] = Variable<String>(storeName.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingListStoresCompanion(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('storeName: $storeName, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $ShoppingListSectionsTable extends ShoppingListSections
    with TableInfo<$ShoppingListSectionsTable, ShoppingListSection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingListSectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<int> storeId = GeneratedColumn<int>(
    'store_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sectionNameMeta = const VerificationMeta(
    'sectionName',
  );
  @override
  late final GeneratedColumn<String> sectionName = GeneratedColumn<String>(
    'section_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, storeId, sectionName, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_list_sections';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShoppingListSection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('section_name')) {
      context.handle(
        _sectionNameMeta,
        sectionName.isAcceptableOrUnknown(
          data['section_name']!,
          _sectionNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sectionNameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShoppingListSection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingListSection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}store_id'],
      )!,
      sectionName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}section_name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $ShoppingListSectionsTable createAlias(String alias) {
    return $ShoppingListSectionsTable(attachedDatabase, alias);
  }
}

class ShoppingListSection extends DataClass
    implements Insertable<ShoppingListSection> {
  final int id;
  final int storeId;
  final String sectionName;
  final int sortOrder;
  const ShoppingListSection({
    required this.id,
    required this.storeId,
    required this.sectionName,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['store_id'] = Variable<int>(storeId);
    map['section_name'] = Variable<String>(sectionName);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ShoppingListSectionsCompanion toCompanion(bool nullToAbsent) {
    return ShoppingListSectionsCompanion(
      id: Value(id),
      storeId: Value(storeId),
      sectionName: Value(sectionName),
      sortOrder: Value(sortOrder),
    );
  }

  factory ShoppingListSection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingListSection(
      id: serializer.fromJson<int>(json['id']),
      storeId: serializer.fromJson<int>(json['storeId']),
      sectionName: serializer.fromJson<String>(json['sectionName']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'storeId': serializer.toJson<int>(storeId),
      'sectionName': serializer.toJson<String>(sectionName),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  ShoppingListSection copyWith({
    int? id,
    int? storeId,
    String? sectionName,
    int? sortOrder,
  }) => ShoppingListSection(
    id: id ?? this.id,
    storeId: storeId ?? this.storeId,
    sectionName: sectionName ?? this.sectionName,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  ShoppingListSection copyWithCompanion(ShoppingListSectionsCompanion data) {
    return ShoppingListSection(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      sectionName: data.sectionName.present
          ? data.sectionName.value
          : this.sectionName,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingListSection(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('sectionName: $sectionName, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, storeId, sectionName, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingListSection &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.sectionName == this.sectionName &&
          other.sortOrder == this.sortOrder);
}

class ShoppingListSectionsCompanion
    extends UpdateCompanion<ShoppingListSection> {
  final Value<int> id;
  final Value<int> storeId;
  final Value<String> sectionName;
  final Value<int> sortOrder;
  const ShoppingListSectionsCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.sectionName = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  ShoppingListSectionsCompanion.insert({
    this.id = const Value.absent(),
    required int storeId,
    required String sectionName,
    this.sortOrder = const Value.absent(),
  }) : storeId = Value(storeId),
       sectionName = Value(sectionName);
  static Insertable<ShoppingListSection> custom({
    Expression<int>? id,
    Expression<int>? storeId,
    Expression<String>? sectionName,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (sectionName != null) 'section_name': sectionName,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  ShoppingListSectionsCompanion copyWith({
    Value<int>? id,
    Value<int>? storeId,
    Value<String>? sectionName,
    Value<int>? sortOrder,
  }) {
    return ShoppingListSectionsCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      sectionName: sectionName ?? this.sectionName,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<int>(storeId.value);
    }
    if (sectionName.present) {
      map['section_name'] = Variable<String>(sectionName.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingListSectionsCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('sectionName: $sectionName, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $ShoppingListItemsTable extends ShoppingListItems
    with TableInfo<$ShoppingListItemsTable, ShoppingListItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingListItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sectionIdMeta = const VerificationMeta(
    'sectionId',
  );
  @override
  late final GeneratedColumn<int> sectionId = GeneratedColumn<int>(
    'section_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ingredientIdMeta = const VerificationMeta(
    'ingredientId',
  );
  @override
  late final GeneratedColumn<int> ingredientId = GeneratedColumn<int>(
    'ingredient_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawTextMeta = const VerificationMeta(
    'rawText',
  );
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
    'raw_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<double> qty = GeneratedColumn<double>(
    'qty',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _checkedMeta = const VerificationMeta(
    'checked',
  );
  @override
  late final GeneratedColumn<bool> checked = GeneratedColumn<bool>(
    'checked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("checked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sectionId,
    ingredientId,
    rawText,
    qty,
    unit,
    checked,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_list_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShoppingListItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('section_id')) {
      context.handle(
        _sectionIdMeta,
        sectionId.isAcceptableOrUnknown(data['section_id']!, _sectionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sectionIdMeta);
    }
    if (data.containsKey('ingredient_id')) {
      context.handle(
        _ingredientIdMeta,
        ingredientId.isAcceptableOrUnknown(
          data['ingredient_id']!,
          _ingredientIdMeta,
        ),
      );
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    } else if (isInserting) {
      context.missing(_rawTextMeta);
    }
    if (data.containsKey('qty')) {
      context.handle(
        _qtyMeta,
        qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('checked')) {
      context.handle(
        _checkedMeta,
        checked.isAcceptableOrUnknown(data['checked']!, _checkedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShoppingListItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingListItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}section_id'],
      )!,
      ingredientId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ingredient_id'],
      ),
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      )!,
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}qty'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      checked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}checked'],
      )!,
    );
  }

  @override
  $ShoppingListItemsTable createAlias(String alias) {
    return $ShoppingListItemsTable(attachedDatabase, alias);
  }
}

class ShoppingListItem extends DataClass
    implements Insertable<ShoppingListItem> {
  final int id;
  final int sectionId;
  final int? ingredientId;
  final String rawText;
  final double? qty;
  final String? unit;
  final bool checked;
  const ShoppingListItem({
    required this.id,
    required this.sectionId,
    this.ingredientId,
    required this.rawText,
    this.qty,
    this.unit,
    required this.checked,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['section_id'] = Variable<int>(sectionId);
    if (!nullToAbsent || ingredientId != null) {
      map['ingredient_id'] = Variable<int>(ingredientId);
    }
    map['raw_text'] = Variable<String>(rawText);
    if (!nullToAbsent || qty != null) {
      map['qty'] = Variable<double>(qty);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['checked'] = Variable<bool>(checked);
    return map;
  }

  ShoppingListItemsCompanion toCompanion(bool nullToAbsent) {
    return ShoppingListItemsCompanion(
      id: Value(id),
      sectionId: Value(sectionId),
      ingredientId: ingredientId == null && nullToAbsent
          ? const Value.absent()
          : Value(ingredientId),
      rawText: Value(rawText),
      qty: qty == null && nullToAbsent ? const Value.absent() : Value(qty),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      checked: Value(checked),
    );
  }

  factory ShoppingListItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingListItem(
      id: serializer.fromJson<int>(json['id']),
      sectionId: serializer.fromJson<int>(json['sectionId']),
      ingredientId: serializer.fromJson<int?>(json['ingredientId']),
      rawText: serializer.fromJson<String>(json['rawText']),
      qty: serializer.fromJson<double?>(json['qty']),
      unit: serializer.fromJson<String?>(json['unit']),
      checked: serializer.fromJson<bool>(json['checked']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sectionId': serializer.toJson<int>(sectionId),
      'ingredientId': serializer.toJson<int?>(ingredientId),
      'rawText': serializer.toJson<String>(rawText),
      'qty': serializer.toJson<double?>(qty),
      'unit': serializer.toJson<String?>(unit),
      'checked': serializer.toJson<bool>(checked),
    };
  }

  ShoppingListItem copyWith({
    int? id,
    int? sectionId,
    Value<int?> ingredientId = const Value.absent(),
    String? rawText,
    Value<double?> qty = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    bool? checked,
  }) => ShoppingListItem(
    id: id ?? this.id,
    sectionId: sectionId ?? this.sectionId,
    ingredientId: ingredientId.present ? ingredientId.value : this.ingredientId,
    rawText: rawText ?? this.rawText,
    qty: qty.present ? qty.value : this.qty,
    unit: unit.present ? unit.value : this.unit,
    checked: checked ?? this.checked,
  );
  ShoppingListItem copyWithCompanion(ShoppingListItemsCompanion data) {
    return ShoppingListItem(
      id: data.id.present ? data.id.value : this.id,
      sectionId: data.sectionId.present ? data.sectionId.value : this.sectionId,
      ingredientId: data.ingredientId.present
          ? data.ingredientId.value
          : this.ingredientId,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      qty: data.qty.present ? data.qty.value : this.qty,
      unit: data.unit.present ? data.unit.value : this.unit,
      checked: data.checked.present ? data.checked.value : this.checked,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingListItem(')
          ..write('id: $id, ')
          ..write('sectionId: $sectionId, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('rawText: $rawText, ')
          ..write('qty: $qty, ')
          ..write('unit: $unit, ')
          ..write('checked: $checked')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sectionId, ingredientId, rawText, qty, unit, checked);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingListItem &&
          other.id == this.id &&
          other.sectionId == this.sectionId &&
          other.ingredientId == this.ingredientId &&
          other.rawText == this.rawText &&
          other.qty == this.qty &&
          other.unit == this.unit &&
          other.checked == this.checked);
}

class ShoppingListItemsCompanion extends UpdateCompanion<ShoppingListItem> {
  final Value<int> id;
  final Value<int> sectionId;
  final Value<int?> ingredientId;
  final Value<String> rawText;
  final Value<double?> qty;
  final Value<String?> unit;
  final Value<bool> checked;
  const ShoppingListItemsCompanion({
    this.id = const Value.absent(),
    this.sectionId = const Value.absent(),
    this.ingredientId = const Value.absent(),
    this.rawText = const Value.absent(),
    this.qty = const Value.absent(),
    this.unit = const Value.absent(),
    this.checked = const Value.absent(),
  });
  ShoppingListItemsCompanion.insert({
    this.id = const Value.absent(),
    required int sectionId,
    this.ingredientId = const Value.absent(),
    required String rawText,
    this.qty = const Value.absent(),
    this.unit = const Value.absent(),
    this.checked = const Value.absent(),
  }) : sectionId = Value(sectionId),
       rawText = Value(rawText);
  static Insertable<ShoppingListItem> custom({
    Expression<int>? id,
    Expression<int>? sectionId,
    Expression<int>? ingredientId,
    Expression<String>? rawText,
    Expression<double>? qty,
    Expression<String>? unit,
    Expression<bool>? checked,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sectionId != null) 'section_id': sectionId,
      if (ingredientId != null) 'ingredient_id': ingredientId,
      if (rawText != null) 'raw_text': rawText,
      if (qty != null) 'qty': qty,
      if (unit != null) 'unit': unit,
      if (checked != null) 'checked': checked,
    });
  }

  ShoppingListItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? sectionId,
    Value<int?>? ingredientId,
    Value<String>? rawText,
    Value<double?>? qty,
    Value<String?>? unit,
    Value<bool>? checked,
  }) {
    return ShoppingListItemsCompanion(
      id: id ?? this.id,
      sectionId: sectionId ?? this.sectionId,
      ingredientId: ingredientId ?? this.ingredientId,
      rawText: rawText ?? this.rawText,
      qty: qty ?? this.qty,
      unit: unit ?? this.unit,
      checked: checked ?? this.checked,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sectionId.present) {
      map['section_id'] = Variable<int>(sectionId.value);
    }
    if (ingredientId.present) {
      map['ingredient_id'] = Variable<int>(ingredientId.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (qty.present) {
      map['qty'] = Variable<double>(qty.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (checked.present) {
      map['checked'] = Variable<bool>(checked.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingListItemsCompanion(')
          ..write('id: $id, ')
          ..write('sectionId: $sectionId, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('rawText: $rawText, ')
          ..write('qty: $qty, ')
          ..write('unit: $unit, ')
          ..write('checked: $checked')
          ..write(')'))
        .toString();
  }
}

class $RecipesTable extends Recipes with TableInfo<$RecipesTable, Recipe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _servingsMeta = const VerificationMeta(
    'servings',
  );
  @override
  late final GeneratedColumn<int> servings = GeneratedColumn<int>(
    'servings',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _instructionsMeta = const VerificationMeta(
    'instructions',
  );
  @override
  late final GeneratedColumn<String> instructions = GeneratedColumn<String>(
    'instructions',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nutritionJsonMeta = const VerificationMeta(
    'nutritionJson',
  );
  @override
  late final GeneratedColumn<String> nutritionJson = GeneratedColumn<String>(
    'nutrition_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    sourceUrl,
    sourceType,
    servings,
    instructions,
    nutritionJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Recipe> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    }
    if (data.containsKey('servings')) {
      context.handle(
        _servingsMeta,
        servings.isAcceptableOrUnknown(data['servings']!, _servingsMeta),
      );
    }
    if (data.containsKey('instructions')) {
      context.handle(
        _instructionsMeta,
        instructions.isAcceptableOrUnknown(
          data['instructions']!,
          _instructionsMeta,
        ),
      );
    }
    if (data.containsKey('nutrition_json')) {
      context.handle(
        _nutritionJsonMeta,
        nutritionJson.isAcceptableOrUnknown(
          data['nutrition_json']!,
          _nutritionJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Recipe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Recipe(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      ),
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      servings: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}servings'],
      ),
      instructions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instructions'],
      ),
      nutritionJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nutrition_json'],
      ),
    );
  }

  @override
  $RecipesTable createAlias(String alias) {
    return $RecipesTable(attachedDatabase, alias);
  }
}

class Recipe extends DataClass implements Insertable<Recipe> {
  final int id;
  final String name;
  final String? sourceUrl;
  final String sourceType;
  final int? servings;
  final String? instructions;
  final String? nutritionJson;
  const Recipe({
    required this.id,
    required this.name,
    this.sourceUrl,
    required this.sourceType,
    this.servings,
    this.instructions,
    this.nutritionJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || sourceUrl != null) {
      map['source_url'] = Variable<String>(sourceUrl);
    }
    map['source_type'] = Variable<String>(sourceType);
    if (!nullToAbsent || servings != null) {
      map['servings'] = Variable<int>(servings);
    }
    if (!nullToAbsent || instructions != null) {
      map['instructions'] = Variable<String>(instructions);
    }
    if (!nullToAbsent || nutritionJson != null) {
      map['nutrition_json'] = Variable<String>(nutritionJson);
    }
    return map;
  }

  RecipesCompanion toCompanion(bool nullToAbsent) {
    return RecipesCompanion(
      id: Value(id),
      name: Value(name),
      sourceUrl: sourceUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUrl),
      sourceType: Value(sourceType),
      servings: servings == null && nullToAbsent
          ? const Value.absent()
          : Value(servings),
      instructions: instructions == null && nullToAbsent
          ? const Value.absent()
          : Value(instructions),
      nutritionJson: nutritionJson == null && nullToAbsent
          ? const Value.absent()
          : Value(nutritionJson),
    );
  }

  factory Recipe.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Recipe(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sourceUrl: serializer.fromJson<String?>(json['sourceUrl']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      servings: serializer.fromJson<int?>(json['servings']),
      instructions: serializer.fromJson<String?>(json['instructions']),
      nutritionJson: serializer.fromJson<String?>(json['nutritionJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'sourceUrl': serializer.toJson<String?>(sourceUrl),
      'sourceType': serializer.toJson<String>(sourceType),
      'servings': serializer.toJson<int?>(servings),
      'instructions': serializer.toJson<String?>(instructions),
      'nutritionJson': serializer.toJson<String?>(nutritionJson),
    };
  }

  Recipe copyWith({
    int? id,
    String? name,
    Value<String?> sourceUrl = const Value.absent(),
    String? sourceType,
    Value<int?> servings = const Value.absent(),
    Value<String?> instructions = const Value.absent(),
    Value<String?> nutritionJson = const Value.absent(),
  }) => Recipe(
    id: id ?? this.id,
    name: name ?? this.name,
    sourceUrl: sourceUrl.present ? sourceUrl.value : this.sourceUrl,
    sourceType: sourceType ?? this.sourceType,
    servings: servings.present ? servings.value : this.servings,
    instructions: instructions.present ? instructions.value : this.instructions,
    nutritionJson: nutritionJson.present
        ? nutritionJson.value
        : this.nutritionJson,
  );
  Recipe copyWithCompanion(RecipesCompanion data) {
    return Recipe(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      servings: data.servings.present ? data.servings.value : this.servings,
      instructions: data.instructions.present
          ? data.instructions.value
          : this.instructions,
      nutritionJson: data.nutritionJson.present
          ? data.nutritionJson.value
          : this.nutritionJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Recipe(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('sourceType: $sourceType, ')
          ..write('servings: $servings, ')
          ..write('instructions: $instructions, ')
          ..write('nutritionJson: $nutritionJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    sourceUrl,
    sourceType,
    servings,
    instructions,
    nutritionJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Recipe &&
          other.id == this.id &&
          other.name == this.name &&
          other.sourceUrl == this.sourceUrl &&
          other.sourceType == this.sourceType &&
          other.servings == this.servings &&
          other.instructions == this.instructions &&
          other.nutritionJson == this.nutritionJson);
}

class RecipesCompanion extends UpdateCompanion<Recipe> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> sourceUrl;
  final Value<String> sourceType;
  final Value<int?> servings;
  final Value<String?> instructions;
  final Value<String?> nutritionJson;
  const RecipesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.servings = const Value.absent(),
    this.instructions = const Value.absent(),
    this.nutritionJson = const Value.absent(),
  });
  RecipesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.sourceUrl = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.servings = const Value.absent(),
    this.instructions = const Value.absent(),
    this.nutritionJson = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Recipe> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? sourceUrl,
    Expression<String>? sourceType,
    Expression<int>? servings,
    Expression<String>? instructions,
    Expression<String>? nutritionJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (sourceType != null) 'source_type': sourceType,
      if (servings != null) 'servings': servings,
      if (instructions != null) 'instructions': instructions,
      if (nutritionJson != null) 'nutrition_json': nutritionJson,
    });
  }

  RecipesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? sourceUrl,
    Value<String>? sourceType,
    Value<int?>? servings,
    Value<String?>? instructions,
    Value<String?>? nutritionJson,
  }) {
    return RecipesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceType: sourceType ?? this.sourceType,
      servings: servings ?? this.servings,
      instructions: instructions ?? this.instructions,
      nutritionJson: nutritionJson ?? this.nutritionJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (servings.present) {
      map['servings'] = Variable<int>(servings.value);
    }
    if (instructions.present) {
      map['instructions'] = Variable<String>(instructions.value);
    }
    if (nutritionJson.present) {
      map['nutrition_json'] = Variable<String>(nutritionJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('sourceType: $sourceType, ')
          ..write('servings: $servings, ')
          ..write('instructions: $instructions, ')
          ..write('nutritionJson: $nutritionJson')
          ..write(')'))
        .toString();
  }
}

class $RecipeStepsTable extends RecipeSteps
    with TableInfo<$RecipeStepsTable, RecipeStep> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeStepsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<int> recipeId = GeneratedColumn<int>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stepNumberMeta = const VerificationMeta(
    'stepNumber',
  );
  @override
  late final GeneratedColumn<int> stepNumber = GeneratedColumn<int>(
    'step_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, recipeId, stepNumber, content];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_steps';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeStep> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('step_number')) {
      context.handle(
        _stepNumberMeta,
        stepNumber.isAcceptableOrUnknown(data['step_number']!, _stepNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_stepNumberMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecipeStep map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeStep(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recipe_id'],
      )!,
      stepNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step_number'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
    );
  }

  @override
  $RecipeStepsTable createAlias(String alias) {
    return $RecipeStepsTable(attachedDatabase, alias);
  }
}

class RecipeStep extends DataClass implements Insertable<RecipeStep> {
  final int id;
  final int recipeId;
  final int stepNumber;
  final String content;
  const RecipeStep({
    required this.id,
    required this.recipeId,
    required this.stepNumber,
    required this.content,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['recipe_id'] = Variable<int>(recipeId);
    map['step_number'] = Variable<int>(stepNumber);
    map['content'] = Variable<String>(content);
    return map;
  }

  RecipeStepsCompanion toCompanion(bool nullToAbsent) {
    return RecipeStepsCompanion(
      id: Value(id),
      recipeId: Value(recipeId),
      stepNumber: Value(stepNumber),
      content: Value(content),
    );
  }

  factory RecipeStep.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeStep(
      id: serializer.fromJson<int>(json['id']),
      recipeId: serializer.fromJson<int>(json['recipeId']),
      stepNumber: serializer.fromJson<int>(json['stepNumber']),
      content: serializer.fromJson<String>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recipeId': serializer.toJson<int>(recipeId),
      'stepNumber': serializer.toJson<int>(stepNumber),
      'content': serializer.toJson<String>(content),
    };
  }

  RecipeStep copyWith({
    int? id,
    int? recipeId,
    int? stepNumber,
    String? content,
  }) => RecipeStep(
    id: id ?? this.id,
    recipeId: recipeId ?? this.recipeId,
    stepNumber: stepNumber ?? this.stepNumber,
    content: content ?? this.content,
  );
  RecipeStep copyWithCompanion(RecipeStepsCompanion data) {
    return RecipeStep(
      id: data.id.present ? data.id.value : this.id,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      stepNumber: data.stepNumber.present
          ? data.stepNumber.value
          : this.stepNumber,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeStep(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('stepNumber: $stepNumber, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, recipeId, stepNumber, content);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeStep &&
          other.id == this.id &&
          other.recipeId == this.recipeId &&
          other.stepNumber == this.stepNumber &&
          other.content == this.content);
}

class RecipeStepsCompanion extends UpdateCompanion<RecipeStep> {
  final Value<int> id;
  final Value<int> recipeId;
  final Value<int> stepNumber;
  final Value<String> content;
  const RecipeStepsCompanion({
    this.id = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.stepNumber = const Value.absent(),
    this.content = const Value.absent(),
  });
  RecipeStepsCompanion.insert({
    this.id = const Value.absent(),
    required int recipeId,
    required int stepNumber,
    required String content,
  }) : recipeId = Value(recipeId),
       stepNumber = Value(stepNumber),
       content = Value(content);
  static Insertable<RecipeStep> custom({
    Expression<int>? id,
    Expression<int>? recipeId,
    Expression<int>? stepNumber,
    Expression<String>? content,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipeId != null) 'recipe_id': recipeId,
      if (stepNumber != null) 'step_number': stepNumber,
      if (content != null) 'content': content,
    });
  }

  RecipeStepsCompanion copyWith({
    Value<int>? id,
    Value<int>? recipeId,
    Value<int>? stepNumber,
    Value<String>? content,
  }) {
    return RecipeStepsCompanion(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      stepNumber: stepNumber ?? this.stepNumber,
      content: content ?? this.content,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<int>(recipeId.value);
    }
    if (stepNumber.present) {
      map['step_number'] = Variable<int>(stepNumber.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeStepsCompanion(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('stepNumber: $stepNumber, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }
}

class $RecipeIngredientsTable extends RecipeIngredients
    with TableInfo<$RecipeIngredientsTable, RecipeIngredient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeIngredientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<int> recipeId = GeneratedColumn<int>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ingredientIdMeta = const VerificationMeta(
    'ingredientId',
  );
  @override
  late final GeneratedColumn<int> ingredientId = GeneratedColumn<int>(
    'ingredient_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<double> qty = GeneratedColumn<double>(
    'qty',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recipeId,
    ingredientId,
    qty,
    unit,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_ingredients';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeIngredient> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('ingredient_id')) {
      context.handle(
        _ingredientIdMeta,
        ingredientId.isAcceptableOrUnknown(
          data['ingredient_id']!,
          _ingredientIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ingredientIdMeta);
    }
    if (data.containsKey('qty')) {
      context.handle(
        _qtyMeta,
        qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecipeIngredient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeIngredient(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recipe_id'],
      )!,
      ingredientId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ingredient_id'],
      )!,
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}qty'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $RecipeIngredientsTable createAlias(String alias) {
    return $RecipeIngredientsTable(attachedDatabase, alias);
  }
}

class RecipeIngredient extends DataClass
    implements Insertable<RecipeIngredient> {
  final int id;
  final int recipeId;
  final int ingredientId;
  final double? qty;
  final String? unit;
  final String? notes;
  const RecipeIngredient({
    required this.id,
    required this.recipeId,
    required this.ingredientId,
    this.qty,
    this.unit,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['recipe_id'] = Variable<int>(recipeId);
    map['ingredient_id'] = Variable<int>(ingredientId);
    if (!nullToAbsent || qty != null) {
      map['qty'] = Variable<double>(qty);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  RecipeIngredientsCompanion toCompanion(bool nullToAbsent) {
    return RecipeIngredientsCompanion(
      id: Value(id),
      recipeId: Value(recipeId),
      ingredientId: Value(ingredientId),
      qty: qty == null && nullToAbsent ? const Value.absent() : Value(qty),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory RecipeIngredient.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeIngredient(
      id: serializer.fromJson<int>(json['id']),
      recipeId: serializer.fromJson<int>(json['recipeId']),
      ingredientId: serializer.fromJson<int>(json['ingredientId']),
      qty: serializer.fromJson<double?>(json['qty']),
      unit: serializer.fromJson<String?>(json['unit']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recipeId': serializer.toJson<int>(recipeId),
      'ingredientId': serializer.toJson<int>(ingredientId),
      'qty': serializer.toJson<double?>(qty),
      'unit': serializer.toJson<String?>(unit),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  RecipeIngredient copyWith({
    int? id,
    int? recipeId,
    int? ingredientId,
    Value<double?> qty = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => RecipeIngredient(
    id: id ?? this.id,
    recipeId: recipeId ?? this.recipeId,
    ingredientId: ingredientId ?? this.ingredientId,
    qty: qty.present ? qty.value : this.qty,
    unit: unit.present ? unit.value : this.unit,
    notes: notes.present ? notes.value : this.notes,
  );
  RecipeIngredient copyWithCompanion(RecipeIngredientsCompanion data) {
    return RecipeIngredient(
      id: data.id.present ? data.id.value : this.id,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      ingredientId: data.ingredientId.present
          ? data.ingredientId.value
          : this.ingredientId,
      qty: data.qty.present ? data.qty.value : this.qty,
      unit: data.unit.present ? data.unit.value : this.unit,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeIngredient(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('qty: $qty, ')
          ..write('unit: $unit, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, recipeId, ingredientId, qty, unit, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeIngredient &&
          other.id == this.id &&
          other.recipeId == this.recipeId &&
          other.ingredientId == this.ingredientId &&
          other.qty == this.qty &&
          other.unit == this.unit &&
          other.notes == this.notes);
}

class RecipeIngredientsCompanion extends UpdateCompanion<RecipeIngredient> {
  final Value<int> id;
  final Value<int> recipeId;
  final Value<int> ingredientId;
  final Value<double?> qty;
  final Value<String?> unit;
  final Value<String?> notes;
  const RecipeIngredientsCompanion({
    this.id = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.ingredientId = const Value.absent(),
    this.qty = const Value.absent(),
    this.unit = const Value.absent(),
    this.notes = const Value.absent(),
  });
  RecipeIngredientsCompanion.insert({
    this.id = const Value.absent(),
    required int recipeId,
    required int ingredientId,
    this.qty = const Value.absent(),
    this.unit = const Value.absent(),
    this.notes = const Value.absent(),
  }) : recipeId = Value(recipeId),
       ingredientId = Value(ingredientId);
  static Insertable<RecipeIngredient> custom({
    Expression<int>? id,
    Expression<int>? recipeId,
    Expression<int>? ingredientId,
    Expression<double>? qty,
    Expression<String>? unit,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipeId != null) 'recipe_id': recipeId,
      if (ingredientId != null) 'ingredient_id': ingredientId,
      if (qty != null) 'qty': qty,
      if (unit != null) 'unit': unit,
      if (notes != null) 'notes': notes,
    });
  }

  RecipeIngredientsCompanion copyWith({
    Value<int>? id,
    Value<int>? recipeId,
    Value<int>? ingredientId,
    Value<double?>? qty,
    Value<String?>? unit,
    Value<String?>? notes,
  }) {
    return RecipeIngredientsCompanion(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      ingredientId: ingredientId ?? this.ingredientId,
      qty: qty ?? this.qty,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<int>(recipeId.value);
    }
    if (ingredientId.present) {
      map['ingredient_id'] = Variable<int>(ingredientId.value);
    }
    if (qty.present) {
      map['qty'] = Variable<double>(qty.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeIngredientsCompanion(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('qty: $qty, ')
          ..write('unit: $unit, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $MealPlansTable extends MealPlans
    with TableInfo<$MealPlansTable, MealPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, startDate, endDate];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealPlan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealPlan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      )!,
    );
  }

  @override
  $MealPlansTable createAlias(String alias) {
    return $MealPlansTable(attachedDatabase, alias);
  }
}

class MealPlan extends DataClass implements Insertable<MealPlan> {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  const MealPlan({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['start_date'] = Variable<DateTime>(startDate);
    map['end_date'] = Variable<DateTime>(endDate);
    return map;
  }

  MealPlansCompanion toCompanion(bool nullToAbsent) {
    return MealPlansCompanion(
      id: Value(id),
      name: Value(name),
      startDate: Value(startDate),
      endDate: Value(endDate),
    );
  }

  factory MealPlan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealPlan(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime>(json['endDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime>(endDate),
    };
  }

  MealPlan copyWith({
    int? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
  }) => MealPlan(
    id: id ?? this.id,
    name: name ?? this.name,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
  );
  MealPlan copyWithCompanion(MealPlansCompanion data) {
    return MealPlan(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealPlan(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, startDate, endDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealPlan &&
          other.id == this.id &&
          other.name == this.name &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate);
}

class MealPlansCompanion extends UpdateCompanion<MealPlan> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> startDate;
  final Value<DateTime> endDate;
  const MealPlansCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
  });
  MealPlansCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) : name = Value(name),
       startDate = Value(startDate),
       endDate = Value(endDate);
  static Insertable<MealPlan> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    });
  }

  MealPlansCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<DateTime>? startDate,
    Value<DateTime>? endDate,
  }) {
    return MealPlansCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealPlansCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate')
          ..write(')'))
        .toString();
  }
}

class $MealPlanDaysTable extends MealPlanDays
    with TableInfo<$MealPlanDaysTable, MealPlanDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealPlanDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<int> planId = GeneratedColumn<int>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, planId, date];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_plan_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealPlanDay> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealPlanDay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealPlanDay(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
    );
  }

  @override
  $MealPlanDaysTable createAlias(String alias) {
    return $MealPlanDaysTable(attachedDatabase, alias);
  }
}

class MealPlanDay extends DataClass implements Insertable<MealPlanDay> {
  final int id;
  final int planId;
  final DateTime date;
  const MealPlanDay({
    required this.id,
    required this.planId,
    required this.date,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plan_id'] = Variable<int>(planId);
    map['date'] = Variable<DateTime>(date);
    return map;
  }

  MealPlanDaysCompanion toCompanion(bool nullToAbsent) {
    return MealPlanDaysCompanion(
      id: Value(id),
      planId: Value(planId),
      date: Value(date),
    );
  }

  factory MealPlanDay.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealPlanDay(
      id: serializer.fromJson<int>(json['id']),
      planId: serializer.fromJson<int>(json['planId']),
      date: serializer.fromJson<DateTime>(json['date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'planId': serializer.toJson<int>(planId),
      'date': serializer.toJson<DateTime>(date),
    };
  }

  MealPlanDay copyWith({int? id, int? planId, DateTime? date}) => MealPlanDay(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    date: date ?? this.date,
  );
  MealPlanDay copyWithCompanion(MealPlanDaysCompanion data) {
    return MealPlanDay(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      date: data.date.present ? data.date.value : this.date,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealPlanDay(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, planId, date);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealPlanDay &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.date == this.date);
}

class MealPlanDaysCompanion extends UpdateCompanion<MealPlanDay> {
  final Value<int> id;
  final Value<int> planId;
  final Value<DateTime> date;
  const MealPlanDaysCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.date = const Value.absent(),
  });
  MealPlanDaysCompanion.insert({
    this.id = const Value.absent(),
    required int planId,
    required DateTime date,
  }) : planId = Value(planId),
       date = Value(date);
  static Insertable<MealPlanDay> custom({
    Expression<int>? id,
    Expression<int>? planId,
    Expression<DateTime>? date,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (date != null) 'date': date,
    });
  }

  MealPlanDaysCompanion copyWith({
    Value<int>? id,
    Value<int>? planId,
    Value<DateTime>? date,
  }) {
    return MealPlanDaysCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      date: date ?? this.date,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<int>(planId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealPlanDaysCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }
}

class $MealSlotsTable extends MealSlots
    with TableInfo<$MealSlotsTable, MealSlot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealSlotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dayIdMeta = const VerificationMeta('dayId');
  @override
  late final GeneratedColumn<int> dayId = GeneratedColumn<int>(
    'day_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slotNameMeta = const VerificationMeta(
    'slotName',
  );
  @override
  late final GeneratedColumn<String> slotName = GeneratedColumn<String>(
    'slot_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<int> recipeId = GeneratedColumn<int>(
    'recipe_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, dayId, slotName, recipeId, notes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_slots';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealSlot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day_id')) {
      context.handle(
        _dayIdMeta,
        dayId.isAcceptableOrUnknown(data['day_id']!, _dayIdMeta),
      );
    } else if (isInserting) {
      context.missing(_dayIdMeta);
    }
    if (data.containsKey('slot_name')) {
      context.handle(
        _slotNameMeta,
        slotName.isAcceptableOrUnknown(data['slot_name']!, _slotNameMeta),
      );
    } else if (isInserting) {
      context.missing(_slotNameMeta);
    }
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealSlot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealSlot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dayId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_id'],
      )!,
      slotName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot_name'],
      )!,
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recipe_id'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $MealSlotsTable createAlias(String alias) {
    return $MealSlotsTable(attachedDatabase, alias);
  }
}

class MealSlot extends DataClass implements Insertable<MealSlot> {
  final int id;
  final int dayId;
  final String slotName;
  final int? recipeId;
  final String? notes;
  const MealSlot({
    required this.id,
    required this.dayId,
    required this.slotName,
    this.recipeId,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day_id'] = Variable<int>(dayId);
    map['slot_name'] = Variable<String>(slotName);
    if (!nullToAbsent || recipeId != null) {
      map['recipe_id'] = Variable<int>(recipeId);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  MealSlotsCompanion toCompanion(bool nullToAbsent) {
    return MealSlotsCompanion(
      id: Value(id),
      dayId: Value(dayId),
      slotName: Value(slotName),
      recipeId: recipeId == null && nullToAbsent
          ? const Value.absent()
          : Value(recipeId),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory MealSlot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealSlot(
      id: serializer.fromJson<int>(json['id']),
      dayId: serializer.fromJson<int>(json['dayId']),
      slotName: serializer.fromJson<String>(json['slotName']),
      recipeId: serializer.fromJson<int?>(json['recipeId']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dayId': serializer.toJson<int>(dayId),
      'slotName': serializer.toJson<String>(slotName),
      'recipeId': serializer.toJson<int?>(recipeId),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  MealSlot copyWith({
    int? id,
    int? dayId,
    String? slotName,
    Value<int?> recipeId = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => MealSlot(
    id: id ?? this.id,
    dayId: dayId ?? this.dayId,
    slotName: slotName ?? this.slotName,
    recipeId: recipeId.present ? recipeId.value : this.recipeId,
    notes: notes.present ? notes.value : this.notes,
  );
  MealSlot copyWithCompanion(MealSlotsCompanion data) {
    return MealSlot(
      id: data.id.present ? data.id.value : this.id,
      dayId: data.dayId.present ? data.dayId.value : this.dayId,
      slotName: data.slotName.present ? data.slotName.value : this.slotName,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealSlot(')
          ..write('id: $id, ')
          ..write('dayId: $dayId, ')
          ..write('slotName: $slotName, ')
          ..write('recipeId: $recipeId, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, dayId, slotName, recipeId, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealSlot &&
          other.id == this.id &&
          other.dayId == this.dayId &&
          other.slotName == this.slotName &&
          other.recipeId == this.recipeId &&
          other.notes == this.notes);
}

class MealSlotsCompanion extends UpdateCompanion<MealSlot> {
  final Value<int> id;
  final Value<int> dayId;
  final Value<String> slotName;
  final Value<int?> recipeId;
  final Value<String?> notes;
  const MealSlotsCompanion({
    this.id = const Value.absent(),
    this.dayId = const Value.absent(),
    this.slotName = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.notes = const Value.absent(),
  });
  MealSlotsCompanion.insert({
    this.id = const Value.absent(),
    required int dayId,
    required String slotName,
    this.recipeId = const Value.absent(),
    this.notes = const Value.absent(),
  }) : dayId = Value(dayId),
       slotName = Value(slotName);
  static Insertable<MealSlot> custom({
    Expression<int>? id,
    Expression<int>? dayId,
    Expression<String>? slotName,
    Expression<int>? recipeId,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dayId != null) 'day_id': dayId,
      if (slotName != null) 'slot_name': slotName,
      if (recipeId != null) 'recipe_id': recipeId,
      if (notes != null) 'notes': notes,
    });
  }

  MealSlotsCompanion copyWith({
    Value<int>? id,
    Value<int>? dayId,
    Value<String>? slotName,
    Value<int?>? recipeId,
    Value<String?>? notes,
  }) {
    return MealSlotsCompanion(
      id: id ?? this.id,
      dayId: dayId ?? this.dayId,
      slotName: slotName ?? this.slotName,
      recipeId: recipeId ?? this.recipeId,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dayId.present) {
      map['day_id'] = Variable<int>(dayId.value);
    }
    if (slotName.present) {
      map['slot_name'] = Variable<String>(slotName.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<int>(recipeId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealSlotsCompanion(')
          ..write('id: $id, ')
          ..write('dayId: $dayId, ')
          ..write('slotName: $slotName, ')
          ..write('recipeId: $recipeId, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $IngredientsTable ingredients = $IngredientsTable(this);
  late final $IngredientAliasesTable ingredientAliases =
      $IngredientAliasesTable(this);
  late final $ShoppingListsTable shoppingLists = $ShoppingListsTable(this);
  late final $ShoppingListStoresTable shoppingListStores =
      $ShoppingListStoresTable(this);
  late final $ShoppingListSectionsTable shoppingListSections =
      $ShoppingListSectionsTable(this);
  late final $ShoppingListItemsTable shoppingListItems =
      $ShoppingListItemsTable(this);
  late final $RecipesTable recipes = $RecipesTable(this);
  late final $RecipeStepsTable recipeSteps = $RecipeStepsTable(this);
  late final $RecipeIngredientsTable recipeIngredients =
      $RecipeIngredientsTable(this);
  late final $MealPlansTable mealPlans = $MealPlansTable(this);
  late final $MealPlanDaysTable mealPlanDays = $MealPlanDaysTable(this);
  late final $MealSlotsTable mealSlots = $MealSlotsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    ingredients,
    ingredientAliases,
    shoppingLists,
    shoppingListStores,
    shoppingListSections,
    shoppingListItems,
    recipes,
    recipeSteps,
    recipeIngredients,
    mealPlans,
    mealPlanDays,
    mealSlots,
  ];
}

typedef $$IngredientsTableCreateCompanionBuilder =
    IngredientsCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> preferredUnit,
      Value<String?> nutritionRef,
    });
typedef $$IngredientsTableUpdateCompanionBuilder =
    IngredientsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> preferredUnit,
      Value<String?> nutritionRef,
    });

class $$IngredientsTableFilterComposer
    extends Composer<_$AppDatabase, $IngredientsTable> {
  $$IngredientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredUnit => $composableBuilder(
    column: $table.preferredUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nutritionRef => $composableBuilder(
    column: $table.nutritionRef,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IngredientsTableOrderingComposer
    extends Composer<_$AppDatabase, $IngredientsTable> {
  $$IngredientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredUnit => $composableBuilder(
    column: $table.preferredUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nutritionRef => $composableBuilder(
    column: $table.nutritionRef,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IngredientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IngredientsTable> {
  $$IngredientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get preferredUnit => $composableBuilder(
    column: $table.preferredUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nutritionRef => $composableBuilder(
    column: $table.nutritionRef,
    builder: (column) => column,
  );
}

class $$IngredientsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IngredientsTable,
          Ingredient,
          $$IngredientsTableFilterComposer,
          $$IngredientsTableOrderingComposer,
          $$IngredientsTableAnnotationComposer,
          $$IngredientsTableCreateCompanionBuilder,
          $$IngredientsTableUpdateCompanionBuilder,
          (
            Ingredient,
            BaseReferences<_$AppDatabase, $IngredientsTable, Ingredient>,
          ),
          Ingredient,
          PrefetchHooks Function()
        > {
  $$IngredientsTableTableManager(_$AppDatabase db, $IngredientsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IngredientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngredientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> preferredUnit = const Value.absent(),
                Value<String?> nutritionRef = const Value.absent(),
              }) => IngredientsCompanion(
                id: id,
                name: name,
                preferredUnit: preferredUnit,
                nutritionRef: nutritionRef,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> preferredUnit = const Value.absent(),
                Value<String?> nutritionRef = const Value.absent(),
              }) => IngredientsCompanion.insert(
                id: id,
                name: name,
                preferredUnit: preferredUnit,
                nutritionRef: nutritionRef,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IngredientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IngredientsTable,
      Ingredient,
      $$IngredientsTableFilterComposer,
      $$IngredientsTableOrderingComposer,
      $$IngredientsTableAnnotationComposer,
      $$IngredientsTableCreateCompanionBuilder,
      $$IngredientsTableUpdateCompanionBuilder,
      (
        Ingredient,
        BaseReferences<_$AppDatabase, $IngredientsTable, Ingredient>,
      ),
      Ingredient,
      PrefetchHooks Function()
    >;
typedef $$IngredientAliasesTableCreateCompanionBuilder =
    IngredientAliasesCompanion Function({
      Value<int> id,
      required String alias,
      required int ingredientId,
    });
typedef $$IngredientAliasesTableUpdateCompanionBuilder =
    IngredientAliasesCompanion Function({
      Value<int> id,
      Value<String> alias,
      Value<int> ingredientId,
    });

class $$IngredientAliasesTableFilterComposer
    extends Composer<_$AppDatabase, $IngredientAliasesTable> {
  $$IngredientAliasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alias => $composableBuilder(
    column: $table.alias,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IngredientAliasesTableOrderingComposer
    extends Composer<_$AppDatabase, $IngredientAliasesTable> {
  $$IngredientAliasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alias => $composableBuilder(
    column: $table.alias,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IngredientAliasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IngredientAliasesTable> {
  $$IngredientAliasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get alias =>
      $composableBuilder(column: $table.alias, builder: (column) => column);

  GeneratedColumn<int> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => column,
  );
}

class $$IngredientAliasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IngredientAliasesTable,
          IngredientAliase,
          $$IngredientAliasesTableFilterComposer,
          $$IngredientAliasesTableOrderingComposer,
          $$IngredientAliasesTableAnnotationComposer,
          $$IngredientAliasesTableCreateCompanionBuilder,
          $$IngredientAliasesTableUpdateCompanionBuilder,
          (
            IngredientAliase,
            BaseReferences<
              _$AppDatabase,
              $IngredientAliasesTable,
              IngredientAliase
            >,
          ),
          IngredientAliase,
          PrefetchHooks Function()
        > {
  $$IngredientAliasesTableTableManager(
    _$AppDatabase db,
    $IngredientAliasesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientAliasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IngredientAliasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngredientAliasesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> alias = const Value.absent(),
                Value<int> ingredientId = const Value.absent(),
              }) => IngredientAliasesCompanion(
                id: id,
                alias: alias,
                ingredientId: ingredientId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String alias,
                required int ingredientId,
              }) => IngredientAliasesCompanion.insert(
                id: id,
                alias: alias,
                ingredientId: ingredientId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IngredientAliasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IngredientAliasesTable,
      IngredientAliase,
      $$IngredientAliasesTableFilterComposer,
      $$IngredientAliasesTableOrderingComposer,
      $$IngredientAliasesTableAnnotationComposer,
      $$IngredientAliasesTableCreateCompanionBuilder,
      $$IngredientAliasesTableUpdateCompanionBuilder,
      (
        IngredientAliase,
        BaseReferences<
          _$AppDatabase,
          $IngredientAliasesTable,
          IngredientAliase
        >,
      ),
      IngredientAliase,
      PrefetchHooks Function()
    >;
typedef $$ShoppingListsTableCreateCompanionBuilder =
    ShoppingListsCompanion Function({
      Value<int> id,
      required String name,
      Value<DateTime> createdAt,
      Value<DateTime?> archivedAt,
    });
typedef $$ShoppingListsTableUpdateCompanionBuilder =
    ShoppingListsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<DateTime?> archivedAt,
    });

class $$ShoppingListsTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingListsTable> {
  $$ShoppingListsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShoppingListsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingListsTable> {
  $$ShoppingListsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShoppingListsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingListsTable> {
  $$ShoppingListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );
}

class $$ShoppingListsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShoppingListsTable,
          ShoppingList,
          $$ShoppingListsTableFilterComposer,
          $$ShoppingListsTableOrderingComposer,
          $$ShoppingListsTableAnnotationComposer,
          $$ShoppingListsTableCreateCompanionBuilder,
          $$ShoppingListsTableUpdateCompanionBuilder,
          (
            ShoppingList,
            BaseReferences<_$AppDatabase, $ShoppingListsTable, ShoppingList>,
          ),
          ShoppingList,
          PrefetchHooks Function()
        > {
  $$ShoppingListsTableTableManager(_$AppDatabase db, $ShoppingListsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShoppingListsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
              }) => ShoppingListsCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                archivedAt: archivedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
              }) => ShoppingListsCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                archivedAt: archivedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShoppingListsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShoppingListsTable,
      ShoppingList,
      $$ShoppingListsTableFilterComposer,
      $$ShoppingListsTableOrderingComposer,
      $$ShoppingListsTableAnnotationComposer,
      $$ShoppingListsTableCreateCompanionBuilder,
      $$ShoppingListsTableUpdateCompanionBuilder,
      (
        ShoppingList,
        BaseReferences<_$AppDatabase, $ShoppingListsTable, ShoppingList>,
      ),
      ShoppingList,
      PrefetchHooks Function()
    >;
typedef $$ShoppingListStoresTableCreateCompanionBuilder =
    ShoppingListStoresCompanion Function({
      Value<int> id,
      required int listId,
      required String storeName,
      Value<int> sortOrder,
    });
typedef $$ShoppingListStoresTableUpdateCompanionBuilder =
    ShoppingListStoresCompanion Function({
      Value<int> id,
      Value<int> listId,
      Value<String> storeName,
      Value<int> sortOrder,
    });

class $$ShoppingListStoresTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingListStoresTable> {
  $$ShoppingListStoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get listId => $composableBuilder(
    column: $table.listId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeName => $composableBuilder(
    column: $table.storeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShoppingListStoresTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingListStoresTable> {
  $$ShoppingListStoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get listId => $composableBuilder(
    column: $table.listId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeName => $composableBuilder(
    column: $table.storeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShoppingListStoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingListStoresTable> {
  $$ShoppingListStoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get listId =>
      $composableBuilder(column: $table.listId, builder: (column) => column);

  GeneratedColumn<String> get storeName =>
      $composableBuilder(column: $table.storeName, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$ShoppingListStoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShoppingListStoresTable,
          ShoppingListStore,
          $$ShoppingListStoresTableFilterComposer,
          $$ShoppingListStoresTableOrderingComposer,
          $$ShoppingListStoresTableAnnotationComposer,
          $$ShoppingListStoresTableCreateCompanionBuilder,
          $$ShoppingListStoresTableUpdateCompanionBuilder,
          (
            ShoppingListStore,
            BaseReferences<
              _$AppDatabase,
              $ShoppingListStoresTable,
              ShoppingListStore
            >,
          ),
          ShoppingListStore,
          PrefetchHooks Function()
        > {
  $$ShoppingListStoresTableTableManager(
    _$AppDatabase db,
    $ShoppingListStoresTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingListStoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingListStoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShoppingListStoresTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> listId = const Value.absent(),
                Value<String> storeName = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => ShoppingListStoresCompanion(
                id: id,
                listId: listId,
                storeName: storeName,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int listId,
                required String storeName,
                Value<int> sortOrder = const Value.absent(),
              }) => ShoppingListStoresCompanion.insert(
                id: id,
                listId: listId,
                storeName: storeName,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShoppingListStoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShoppingListStoresTable,
      ShoppingListStore,
      $$ShoppingListStoresTableFilterComposer,
      $$ShoppingListStoresTableOrderingComposer,
      $$ShoppingListStoresTableAnnotationComposer,
      $$ShoppingListStoresTableCreateCompanionBuilder,
      $$ShoppingListStoresTableUpdateCompanionBuilder,
      (
        ShoppingListStore,
        BaseReferences<
          _$AppDatabase,
          $ShoppingListStoresTable,
          ShoppingListStore
        >,
      ),
      ShoppingListStore,
      PrefetchHooks Function()
    >;
typedef $$ShoppingListSectionsTableCreateCompanionBuilder =
    ShoppingListSectionsCompanion Function({
      Value<int> id,
      required int storeId,
      required String sectionName,
      Value<int> sortOrder,
    });
typedef $$ShoppingListSectionsTableUpdateCompanionBuilder =
    ShoppingListSectionsCompanion Function({
      Value<int> id,
      Value<int> storeId,
      Value<String> sectionName,
      Value<int> sortOrder,
    });

class $$ShoppingListSectionsTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingListSectionsTable> {
  $$ShoppingListSectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sectionName => $composableBuilder(
    column: $table.sectionName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShoppingListSectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingListSectionsTable> {
  $$ShoppingListSectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sectionName => $composableBuilder(
    column: $table.sectionName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShoppingListSectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingListSectionsTable> {
  $$ShoppingListSectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get sectionName => $composableBuilder(
    column: $table.sectionName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$ShoppingListSectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShoppingListSectionsTable,
          ShoppingListSection,
          $$ShoppingListSectionsTableFilterComposer,
          $$ShoppingListSectionsTableOrderingComposer,
          $$ShoppingListSectionsTableAnnotationComposer,
          $$ShoppingListSectionsTableCreateCompanionBuilder,
          $$ShoppingListSectionsTableUpdateCompanionBuilder,
          (
            ShoppingListSection,
            BaseReferences<
              _$AppDatabase,
              $ShoppingListSectionsTable,
              ShoppingListSection
            >,
          ),
          ShoppingListSection,
          PrefetchHooks Function()
        > {
  $$ShoppingListSectionsTableTableManager(
    _$AppDatabase db,
    $ShoppingListSectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingListSectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingListSectionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ShoppingListSectionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> storeId = const Value.absent(),
                Value<String> sectionName = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => ShoppingListSectionsCompanion(
                id: id,
                storeId: storeId,
                sectionName: sectionName,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int storeId,
                required String sectionName,
                Value<int> sortOrder = const Value.absent(),
              }) => ShoppingListSectionsCompanion.insert(
                id: id,
                storeId: storeId,
                sectionName: sectionName,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShoppingListSectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShoppingListSectionsTable,
      ShoppingListSection,
      $$ShoppingListSectionsTableFilterComposer,
      $$ShoppingListSectionsTableOrderingComposer,
      $$ShoppingListSectionsTableAnnotationComposer,
      $$ShoppingListSectionsTableCreateCompanionBuilder,
      $$ShoppingListSectionsTableUpdateCompanionBuilder,
      (
        ShoppingListSection,
        BaseReferences<
          _$AppDatabase,
          $ShoppingListSectionsTable,
          ShoppingListSection
        >,
      ),
      ShoppingListSection,
      PrefetchHooks Function()
    >;
typedef $$ShoppingListItemsTableCreateCompanionBuilder =
    ShoppingListItemsCompanion Function({
      Value<int> id,
      required int sectionId,
      Value<int?> ingredientId,
      required String rawText,
      Value<double?> qty,
      Value<String?> unit,
      Value<bool> checked,
    });
typedef $$ShoppingListItemsTableUpdateCompanionBuilder =
    ShoppingListItemsCompanion Function({
      Value<int> id,
      Value<int> sectionId,
      Value<int?> ingredientId,
      Value<String> rawText,
      Value<double?> qty,
      Value<String?> unit,
      Value<bool> checked,
    });

class $$ShoppingListItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingListItemsTable> {
  $$ShoppingListItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sectionId => $composableBuilder(
    column: $table.sectionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get checked => $composableBuilder(
    column: $table.checked,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShoppingListItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingListItemsTable> {
  $$ShoppingListItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sectionId => $composableBuilder(
    column: $table.sectionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get checked => $composableBuilder(
    column: $table.checked,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShoppingListItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingListItemsTable> {
  $$ShoppingListItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sectionId =>
      $composableBuilder(column: $table.sectionId, builder: (column) => column);

  GeneratedColumn<int> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<double> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<bool> get checked =>
      $composableBuilder(column: $table.checked, builder: (column) => column);
}

class $$ShoppingListItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShoppingListItemsTable,
          ShoppingListItem,
          $$ShoppingListItemsTableFilterComposer,
          $$ShoppingListItemsTableOrderingComposer,
          $$ShoppingListItemsTableAnnotationComposer,
          $$ShoppingListItemsTableCreateCompanionBuilder,
          $$ShoppingListItemsTableUpdateCompanionBuilder,
          (
            ShoppingListItem,
            BaseReferences<
              _$AppDatabase,
              $ShoppingListItemsTable,
              ShoppingListItem
            >,
          ),
          ShoppingListItem,
          PrefetchHooks Function()
        > {
  $$ShoppingListItemsTableTableManager(
    _$AppDatabase db,
    $ShoppingListItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingListItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingListItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShoppingListItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sectionId = const Value.absent(),
                Value<int?> ingredientId = const Value.absent(),
                Value<String> rawText = const Value.absent(),
                Value<double?> qty = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<bool> checked = const Value.absent(),
              }) => ShoppingListItemsCompanion(
                id: id,
                sectionId: sectionId,
                ingredientId: ingredientId,
                rawText: rawText,
                qty: qty,
                unit: unit,
                checked: checked,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sectionId,
                Value<int?> ingredientId = const Value.absent(),
                required String rawText,
                Value<double?> qty = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<bool> checked = const Value.absent(),
              }) => ShoppingListItemsCompanion.insert(
                id: id,
                sectionId: sectionId,
                ingredientId: ingredientId,
                rawText: rawText,
                qty: qty,
                unit: unit,
                checked: checked,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShoppingListItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShoppingListItemsTable,
      ShoppingListItem,
      $$ShoppingListItemsTableFilterComposer,
      $$ShoppingListItemsTableOrderingComposer,
      $$ShoppingListItemsTableAnnotationComposer,
      $$ShoppingListItemsTableCreateCompanionBuilder,
      $$ShoppingListItemsTableUpdateCompanionBuilder,
      (
        ShoppingListItem,
        BaseReferences<
          _$AppDatabase,
          $ShoppingListItemsTable,
          ShoppingListItem
        >,
      ),
      ShoppingListItem,
      PrefetchHooks Function()
    >;
typedef $$RecipesTableCreateCompanionBuilder =
    RecipesCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> sourceUrl,
      Value<String> sourceType,
      Value<int?> servings,
      Value<String?> instructions,
      Value<String?> nutritionJson,
    });
typedef $$RecipesTableUpdateCompanionBuilder =
    RecipesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> sourceUrl,
      Value<String> sourceType,
      Value<int?> servings,
      Value<String?> instructions,
      Value<String?> nutritionJson,
    });

class $$RecipesTableFilterComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get servings => $composableBuilder(
    column: $table.servings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nutritionJson => $composableBuilder(
    column: $table.nutritionJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecipesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get servings => $composableBuilder(
    column: $table.servings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nutritionJson => $composableBuilder(
    column: $table.nutritionJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecipesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get servings =>
      $composableBuilder(column: $table.servings, builder: (column) => column);

  GeneratedColumn<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nutritionJson => $composableBuilder(
    column: $table.nutritionJson,
    builder: (column) => column,
  );
}

class $$RecipesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipesTable,
          Recipe,
          $$RecipesTableFilterComposer,
          $$RecipesTableOrderingComposer,
          $$RecipesTableAnnotationComposer,
          $$RecipesTableCreateCompanionBuilder,
          $$RecipesTableUpdateCompanionBuilder,
          (Recipe, BaseReferences<_$AppDatabase, $RecipesTable, Recipe>),
          Recipe,
          PrefetchHooks Function()
        > {
  $$RecipesTableTableManager(_$AppDatabase db, $RecipesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<int?> servings = const Value.absent(),
                Value<String?> instructions = const Value.absent(),
                Value<String?> nutritionJson = const Value.absent(),
              }) => RecipesCompanion(
                id: id,
                name: name,
                sourceUrl: sourceUrl,
                sourceType: sourceType,
                servings: servings,
                instructions: instructions,
                nutritionJson: nutritionJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> sourceUrl = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<int?> servings = const Value.absent(),
                Value<String?> instructions = const Value.absent(),
                Value<String?> nutritionJson = const Value.absent(),
              }) => RecipesCompanion.insert(
                id: id,
                name: name,
                sourceUrl: sourceUrl,
                sourceType: sourceType,
                servings: servings,
                instructions: instructions,
                nutritionJson: nutritionJson,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecipesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipesTable,
      Recipe,
      $$RecipesTableFilterComposer,
      $$RecipesTableOrderingComposer,
      $$RecipesTableAnnotationComposer,
      $$RecipesTableCreateCompanionBuilder,
      $$RecipesTableUpdateCompanionBuilder,
      (Recipe, BaseReferences<_$AppDatabase, $RecipesTable, Recipe>),
      Recipe,
      PrefetchHooks Function()
    >;
typedef $$RecipeStepsTableCreateCompanionBuilder =
    RecipeStepsCompanion Function({
      Value<int> id,
      required int recipeId,
      required int stepNumber,
      required String content,
    });
typedef $$RecipeStepsTableUpdateCompanionBuilder =
    RecipeStepsCompanion Function({
      Value<int> id,
      Value<int> recipeId,
      Value<int> stepNumber,
      Value<String> content,
    });

class $$RecipeStepsTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeStepsTable> {
  $$RecipeStepsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stepNumber => $composableBuilder(
    column: $table.stepNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecipeStepsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeStepsTable> {
  $$RecipeStepsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stepNumber => $composableBuilder(
    column: $table.stepNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecipeStepsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeStepsTable> {
  $$RecipeStepsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get recipeId =>
      $composableBuilder(column: $table.recipeId, builder: (column) => column);

  GeneratedColumn<int> get stepNumber => $composableBuilder(
    column: $table.stepNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);
}

class $$RecipeStepsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipeStepsTable,
          RecipeStep,
          $$RecipeStepsTableFilterComposer,
          $$RecipeStepsTableOrderingComposer,
          $$RecipeStepsTableAnnotationComposer,
          $$RecipeStepsTableCreateCompanionBuilder,
          $$RecipeStepsTableUpdateCompanionBuilder,
          (
            RecipeStep,
            BaseReferences<_$AppDatabase, $RecipeStepsTable, RecipeStep>,
          ),
          RecipeStep,
          PrefetchHooks Function()
        > {
  $$RecipeStepsTableTableManager(_$AppDatabase db, $RecipeStepsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeStepsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeStepsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeStepsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> recipeId = const Value.absent(),
                Value<int> stepNumber = const Value.absent(),
                Value<String> content = const Value.absent(),
              }) => RecipeStepsCompanion(
                id: id,
                recipeId: recipeId,
                stepNumber: stepNumber,
                content: content,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int recipeId,
                required int stepNumber,
                required String content,
              }) => RecipeStepsCompanion.insert(
                id: id,
                recipeId: recipeId,
                stepNumber: stepNumber,
                content: content,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecipeStepsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipeStepsTable,
      RecipeStep,
      $$RecipeStepsTableFilterComposer,
      $$RecipeStepsTableOrderingComposer,
      $$RecipeStepsTableAnnotationComposer,
      $$RecipeStepsTableCreateCompanionBuilder,
      $$RecipeStepsTableUpdateCompanionBuilder,
      (
        RecipeStep,
        BaseReferences<_$AppDatabase, $RecipeStepsTable, RecipeStep>,
      ),
      RecipeStep,
      PrefetchHooks Function()
    >;
typedef $$RecipeIngredientsTableCreateCompanionBuilder =
    RecipeIngredientsCompanion Function({
      Value<int> id,
      required int recipeId,
      required int ingredientId,
      Value<double?> qty,
      Value<String?> unit,
      Value<String?> notes,
    });
typedef $$RecipeIngredientsTableUpdateCompanionBuilder =
    RecipeIngredientsCompanion Function({
      Value<int> id,
      Value<int> recipeId,
      Value<int> ingredientId,
      Value<double?> qty,
      Value<String?> unit,
      Value<String?> notes,
    });

class $$RecipeIngredientsTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeIngredientsTable> {
  $$RecipeIngredientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecipeIngredientsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeIngredientsTable> {
  $$RecipeIngredientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecipeIngredientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeIngredientsTable> {
  $$RecipeIngredientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get recipeId =>
      $composableBuilder(column: $table.recipeId, builder: (column) => column);

  GeneratedColumn<int> get ingredientId => $composableBuilder(
    column: $table.ingredientId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$RecipeIngredientsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipeIngredientsTable,
          RecipeIngredient,
          $$RecipeIngredientsTableFilterComposer,
          $$RecipeIngredientsTableOrderingComposer,
          $$RecipeIngredientsTableAnnotationComposer,
          $$RecipeIngredientsTableCreateCompanionBuilder,
          $$RecipeIngredientsTableUpdateCompanionBuilder,
          (
            RecipeIngredient,
            BaseReferences<
              _$AppDatabase,
              $RecipeIngredientsTable,
              RecipeIngredient
            >,
          ),
          RecipeIngredient,
          PrefetchHooks Function()
        > {
  $$RecipeIngredientsTableTableManager(
    _$AppDatabase db,
    $RecipeIngredientsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeIngredientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeIngredientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeIngredientsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> recipeId = const Value.absent(),
                Value<int> ingredientId = const Value.absent(),
                Value<double?> qty = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => RecipeIngredientsCompanion(
                id: id,
                recipeId: recipeId,
                ingredientId: ingredientId,
                qty: qty,
                unit: unit,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int recipeId,
                required int ingredientId,
                Value<double?> qty = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => RecipeIngredientsCompanion.insert(
                id: id,
                recipeId: recipeId,
                ingredientId: ingredientId,
                qty: qty,
                unit: unit,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecipeIngredientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipeIngredientsTable,
      RecipeIngredient,
      $$RecipeIngredientsTableFilterComposer,
      $$RecipeIngredientsTableOrderingComposer,
      $$RecipeIngredientsTableAnnotationComposer,
      $$RecipeIngredientsTableCreateCompanionBuilder,
      $$RecipeIngredientsTableUpdateCompanionBuilder,
      (
        RecipeIngredient,
        BaseReferences<
          _$AppDatabase,
          $RecipeIngredientsTable,
          RecipeIngredient
        >,
      ),
      RecipeIngredient,
      PrefetchHooks Function()
    >;
typedef $$MealPlansTableCreateCompanionBuilder =
    MealPlansCompanion Function({
      Value<int> id,
      required String name,
      required DateTime startDate,
      required DateTime endDate,
    });
typedef $$MealPlansTableUpdateCompanionBuilder =
    MealPlansCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<DateTime> startDate,
      Value<DateTime> endDate,
    });

class $$MealPlansTableFilterComposer
    extends Composer<_$AppDatabase, $MealPlansTable> {
  $$MealPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MealPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $MealPlansTable> {
  $$MealPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealPlansTable> {
  $$MealPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);
}

class $$MealPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealPlansTable,
          MealPlan,
          $$MealPlansTableFilterComposer,
          $$MealPlansTableOrderingComposer,
          $$MealPlansTableAnnotationComposer,
          $$MealPlansTableCreateCompanionBuilder,
          $$MealPlansTableUpdateCompanionBuilder,
          (MealPlan, BaseReferences<_$AppDatabase, $MealPlansTable, MealPlan>),
          MealPlan,
          PrefetchHooks Function()
        > {
  $$MealPlansTableTableManager(_$AppDatabase db, $MealPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime> endDate = const Value.absent(),
              }) => MealPlansCompanion(
                id: id,
                name: name,
                startDate: startDate,
                endDate: endDate,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required DateTime startDate,
                required DateTime endDate,
              }) => MealPlansCompanion.insert(
                id: id,
                name: name,
                startDate: startDate,
                endDate: endDate,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MealPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealPlansTable,
      MealPlan,
      $$MealPlansTableFilterComposer,
      $$MealPlansTableOrderingComposer,
      $$MealPlansTableAnnotationComposer,
      $$MealPlansTableCreateCompanionBuilder,
      $$MealPlansTableUpdateCompanionBuilder,
      (MealPlan, BaseReferences<_$AppDatabase, $MealPlansTable, MealPlan>),
      MealPlan,
      PrefetchHooks Function()
    >;
typedef $$MealPlanDaysTableCreateCompanionBuilder =
    MealPlanDaysCompanion Function({
      Value<int> id,
      required int planId,
      required DateTime date,
    });
typedef $$MealPlanDaysTableUpdateCompanionBuilder =
    MealPlanDaysCompanion Function({
      Value<int> id,
      Value<int> planId,
      Value<DateTime> date,
    });

class $$MealPlanDaysTableFilterComposer
    extends Composer<_$AppDatabase, $MealPlanDaysTable> {
  $$MealPlanDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MealPlanDaysTableOrderingComposer
    extends Composer<_$AppDatabase, $MealPlanDaysTable> {
  $$MealPlanDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealPlanDaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealPlanDaysTable> {
  $$MealPlanDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);
}

class $$MealPlanDaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealPlanDaysTable,
          MealPlanDay,
          $$MealPlanDaysTableFilterComposer,
          $$MealPlanDaysTableOrderingComposer,
          $$MealPlanDaysTableAnnotationComposer,
          $$MealPlanDaysTableCreateCompanionBuilder,
          $$MealPlanDaysTableUpdateCompanionBuilder,
          (
            MealPlanDay,
            BaseReferences<_$AppDatabase, $MealPlanDaysTable, MealPlanDay>,
          ),
          MealPlanDay,
          PrefetchHooks Function()
        > {
  $$MealPlanDaysTableTableManager(_$AppDatabase db, $MealPlanDaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealPlanDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealPlanDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealPlanDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> planId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
              }) => MealPlanDaysCompanion(id: id, planId: planId, date: date),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int planId,
                required DateTime date,
              }) => MealPlanDaysCompanion.insert(
                id: id,
                planId: planId,
                date: date,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MealPlanDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealPlanDaysTable,
      MealPlanDay,
      $$MealPlanDaysTableFilterComposer,
      $$MealPlanDaysTableOrderingComposer,
      $$MealPlanDaysTableAnnotationComposer,
      $$MealPlanDaysTableCreateCompanionBuilder,
      $$MealPlanDaysTableUpdateCompanionBuilder,
      (
        MealPlanDay,
        BaseReferences<_$AppDatabase, $MealPlanDaysTable, MealPlanDay>,
      ),
      MealPlanDay,
      PrefetchHooks Function()
    >;
typedef $$MealSlotsTableCreateCompanionBuilder =
    MealSlotsCompanion Function({
      Value<int> id,
      required int dayId,
      required String slotName,
      Value<int?> recipeId,
      Value<String?> notes,
    });
typedef $$MealSlotsTableUpdateCompanionBuilder =
    MealSlotsCompanion Function({
      Value<int> id,
      Value<int> dayId,
      Value<String> slotName,
      Value<int?> recipeId,
      Value<String?> notes,
    });

class $$MealSlotsTableFilterComposer
    extends Composer<_$AppDatabase, $MealSlotsTable> {
  $$MealSlotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayId => $composableBuilder(
    column: $table.dayId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slotName => $composableBuilder(
    column: $table.slotName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MealSlotsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealSlotsTable> {
  $$MealSlotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayId => $composableBuilder(
    column: $table.dayId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slotName => $composableBuilder(
    column: $table.slotName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealSlotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealSlotsTable> {
  $$MealSlotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dayId =>
      $composableBuilder(column: $table.dayId, builder: (column) => column);

  GeneratedColumn<String> get slotName =>
      $composableBuilder(column: $table.slotName, builder: (column) => column);

  GeneratedColumn<int> get recipeId =>
      $composableBuilder(column: $table.recipeId, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$MealSlotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealSlotsTable,
          MealSlot,
          $$MealSlotsTableFilterComposer,
          $$MealSlotsTableOrderingComposer,
          $$MealSlotsTableAnnotationComposer,
          $$MealSlotsTableCreateCompanionBuilder,
          $$MealSlotsTableUpdateCompanionBuilder,
          (MealSlot, BaseReferences<_$AppDatabase, $MealSlotsTable, MealSlot>),
          MealSlot,
          PrefetchHooks Function()
        > {
  $$MealSlotsTableTableManager(_$AppDatabase db, $MealSlotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealSlotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealSlotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealSlotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dayId = const Value.absent(),
                Value<String> slotName = const Value.absent(),
                Value<int?> recipeId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => MealSlotsCompanion(
                id: id,
                dayId: dayId,
                slotName: slotName,
                recipeId: recipeId,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int dayId,
                required String slotName,
                Value<int?> recipeId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => MealSlotsCompanion.insert(
                id: id,
                dayId: dayId,
                slotName: slotName,
                recipeId: recipeId,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MealSlotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealSlotsTable,
      MealSlot,
      $$MealSlotsTableFilterComposer,
      $$MealSlotsTableOrderingComposer,
      $$MealSlotsTableAnnotationComposer,
      $$MealSlotsTableCreateCompanionBuilder,
      $$MealSlotsTableUpdateCompanionBuilder,
      (MealSlot, BaseReferences<_$AppDatabase, $MealSlotsTable, MealSlot>),
      MealSlot,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$IngredientsTableTableManager get ingredients =>
      $$IngredientsTableTableManager(_db, _db.ingredients);
  $$IngredientAliasesTableTableManager get ingredientAliases =>
      $$IngredientAliasesTableTableManager(_db, _db.ingredientAliases);
  $$ShoppingListsTableTableManager get shoppingLists =>
      $$ShoppingListsTableTableManager(_db, _db.shoppingLists);
  $$ShoppingListStoresTableTableManager get shoppingListStores =>
      $$ShoppingListStoresTableTableManager(_db, _db.shoppingListStores);
  $$ShoppingListSectionsTableTableManager get shoppingListSections =>
      $$ShoppingListSectionsTableTableManager(_db, _db.shoppingListSections);
  $$ShoppingListItemsTableTableManager get shoppingListItems =>
      $$ShoppingListItemsTableTableManager(_db, _db.shoppingListItems);
  $$RecipesTableTableManager get recipes =>
      $$RecipesTableTableManager(_db, _db.recipes);
  $$RecipeStepsTableTableManager get recipeSteps =>
      $$RecipeStepsTableTableManager(_db, _db.recipeSteps);
  $$RecipeIngredientsTableTableManager get recipeIngredients =>
      $$RecipeIngredientsTableTableManager(_db, _db.recipeIngredients);
  $$MealPlansTableTableManager get mealPlans =>
      $$MealPlansTableTableManager(_db, _db.mealPlans);
  $$MealPlanDaysTableTableManager get mealPlanDays =>
      $$MealPlanDaysTableTableManager(_db, _db.mealPlanDays);
  $$MealSlotsTableTableManager get mealSlots =>
      $$MealSlotsTableTableManager(_db, _db.mealSlots);
}
