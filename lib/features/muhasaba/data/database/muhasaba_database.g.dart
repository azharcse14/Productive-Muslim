// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'muhasaba_database.dart';

// ignore_for_file: type=lint
class $TrackerItemsTable extends TrackerItems
    with TableInfo<$TrackerItemsTable, TrackerItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackerItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<int> kind = GeneratedColumn<int>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dailyTargetMeta = const VerificationMeta(
    'dailyTarget',
  );
  @override
  late final GeneratedColumn<int> dailyTarget = GeneratedColumn<int>(
    'daily_target',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorIndexMeta = const VerificationMeta(
    'colorIndex',
  );
  @override
  late final GeneratedColumn<int> colorIndex = GeneratedColumn<int>(
    'color_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdOnMeta = const VerificationMeta(
    'createdOn',
  );
  @override
  late final GeneratedColumn<int> createdOn = GeneratedColumn<int>(
    'created_on',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedOnMeta = const VerificationMeta(
    'archivedOn',
  );
  @override
  late final GeneratedColumn<int> archivedOn = GeneratedColumn<int>(
    'archived_on',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedOnMeta = const VerificationMeta(
    'addedOn',
  );
  @override
  late final GeneratedColumn<int> addedOn = GeneratedColumn<int>(
    'added_on',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    kind,
    dailyTarget,
    icon,
    colorIndex,
    isDefault,
    archived,
    sortOrder,
    createdOn,
    archivedOn,
    addedOn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracker_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrackerItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('daily_target')) {
      context.handle(
        _dailyTargetMeta,
        dailyTarget.isAcceptableOrUnknown(
          data['daily_target']!,
          _dailyTargetMeta,
        ),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('color_index')) {
      context.handle(
        _colorIndexMeta,
        colorIndex.isAcceptableOrUnknown(data['color_index']!, _colorIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_colorIndexMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    } else if (isInserting) {
      context.missing(_isDefaultMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('created_on')) {
      context.handle(
        _createdOnMeta,
        createdOn.isAcceptableOrUnknown(data['created_on']!, _createdOnMeta),
      );
    }
    if (data.containsKey('archived_on')) {
      context.handle(
        _archivedOnMeta,
        archivedOn.isAcceptableOrUnknown(data['archived_on']!, _archivedOnMeta),
      );
    }
    if (data.containsKey('added_on')) {
      context.handle(
        _addedOnMeta,
        addedOn.isAcceptableOrUnknown(data['added_on']!, _addedOnMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrackerItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackerItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kind'],
      )!,
      dailyTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_target'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      colorIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_index'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdOn: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_on'],
      ),
      archivedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}archived_on'],
      ),
      addedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_on'],
      ),
    );
  }

  @override
  $TrackerItemsTable createAlias(String alias) {
    return $TrackerItemsTable(attachedDatabase, alias);
  }
}

class TrackerItemRow extends DataClass implements Insertable<TrackerItemRow> {
  final String id;
  final String name;

  /// Stored as `TrackerKind.code`.
  final int kind;
  final int? dailyTarget;
  final String icon;
  final int colorIndex;
  final bool isDefault;
  final bool archived;
  final int sortOrder;

  /// yyyymmdd of the first day the item counts toward daily completion
  /// (creation day, lowered if entries are back-filled earlier). Null =
  /// counts on every day.
  final int? createdOn;

  /// yyyymmdd of the day it was archived (it stops counting from that day
  /// on); null while active.
  final int? archivedOn;

  /// yyyymmdd of the real creation day — [createdOn] before any
  /// back-fill lowered it, so clearing those entries can raise it back.
  final int? addedOn;
  const TrackerItemRow({
    required this.id,
    required this.name,
    required this.kind,
    this.dailyTarget,
    required this.icon,
    required this.colorIndex,
    required this.isDefault,
    required this.archived,
    required this.sortOrder,
    this.createdOn,
    this.archivedOn,
    this.addedOn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<int>(kind);
    if (!nullToAbsent || dailyTarget != null) {
      map['daily_target'] = Variable<int>(dailyTarget);
    }
    map['icon'] = Variable<String>(icon);
    map['color_index'] = Variable<int>(colorIndex);
    map['is_default'] = Variable<bool>(isDefault);
    map['archived'] = Variable<bool>(archived);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || createdOn != null) {
      map['created_on'] = Variable<int>(createdOn);
    }
    if (!nullToAbsent || archivedOn != null) {
      map['archived_on'] = Variable<int>(archivedOn);
    }
    if (!nullToAbsent || addedOn != null) {
      map['added_on'] = Variable<int>(addedOn);
    }
    return map;
  }

  TrackerItemsCompanion toCompanion(bool nullToAbsent) {
    return TrackerItemsCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      dailyTarget: dailyTarget == null && nullToAbsent
          ? const Value.absent()
          : Value(dailyTarget),
      icon: Value(icon),
      colorIndex: Value(colorIndex),
      isDefault: Value(isDefault),
      archived: Value(archived),
      sortOrder: Value(sortOrder),
      createdOn: createdOn == null && nullToAbsent
          ? const Value.absent()
          : Value(createdOn),
      archivedOn: archivedOn == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedOn),
      addedOn: addedOn == null && nullToAbsent
          ? const Value.absent()
          : Value(addedOn),
    );
  }

  factory TrackerItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackerItemRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<int>(json['kind']),
      dailyTarget: serializer.fromJson<int?>(json['dailyTarget']),
      icon: serializer.fromJson<String>(json['icon']),
      colorIndex: serializer.fromJson<int>(json['colorIndex']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      archived: serializer.fromJson<bool>(json['archived']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdOn: serializer.fromJson<int?>(json['createdOn']),
      archivedOn: serializer.fromJson<int?>(json['archivedOn']),
      addedOn: serializer.fromJson<int?>(json['addedOn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<int>(kind),
      'dailyTarget': serializer.toJson<int?>(dailyTarget),
      'icon': serializer.toJson<String>(icon),
      'colorIndex': serializer.toJson<int>(colorIndex),
      'isDefault': serializer.toJson<bool>(isDefault),
      'archived': serializer.toJson<bool>(archived),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdOn': serializer.toJson<int?>(createdOn),
      'archivedOn': serializer.toJson<int?>(archivedOn),
      'addedOn': serializer.toJson<int?>(addedOn),
    };
  }

  TrackerItemRow copyWith({
    String? id,
    String? name,
    int? kind,
    Value<int?> dailyTarget = const Value.absent(),
    String? icon,
    int? colorIndex,
    bool? isDefault,
    bool? archived,
    int? sortOrder,
    Value<int?> createdOn = const Value.absent(),
    Value<int?> archivedOn = const Value.absent(),
    Value<int?> addedOn = const Value.absent(),
  }) => TrackerItemRow(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    dailyTarget: dailyTarget.present ? dailyTarget.value : this.dailyTarget,
    icon: icon ?? this.icon,
    colorIndex: colorIndex ?? this.colorIndex,
    isDefault: isDefault ?? this.isDefault,
    archived: archived ?? this.archived,
    sortOrder: sortOrder ?? this.sortOrder,
    createdOn: createdOn.present ? createdOn.value : this.createdOn,
    archivedOn: archivedOn.present ? archivedOn.value : this.archivedOn,
    addedOn: addedOn.present ? addedOn.value : this.addedOn,
  );
  TrackerItemRow copyWithCompanion(TrackerItemsCompanion data) {
    return TrackerItemRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      dailyTarget: data.dailyTarget.present
          ? data.dailyTarget.value
          : this.dailyTarget,
      icon: data.icon.present ? data.icon.value : this.icon,
      colorIndex: data.colorIndex.present
          ? data.colorIndex.value
          : this.colorIndex,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      archived: data.archived.present ? data.archived.value : this.archived,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdOn: data.createdOn.present ? data.createdOn.value : this.createdOn,
      archivedOn: data.archivedOn.present
          ? data.archivedOn.value
          : this.archivedOn,
      addedOn: data.addedOn.present ? data.addedOn.value : this.addedOn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackerItemRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('dailyTarget: $dailyTarget, ')
          ..write('icon: $icon, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('isDefault: $isDefault, ')
          ..write('archived: $archived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdOn: $createdOn, ')
          ..write('archivedOn: $archivedOn, ')
          ..write('addedOn: $addedOn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    kind,
    dailyTarget,
    icon,
    colorIndex,
    isDefault,
    archived,
    sortOrder,
    createdOn,
    archivedOn,
    addedOn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackerItemRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.dailyTarget == this.dailyTarget &&
          other.icon == this.icon &&
          other.colorIndex == this.colorIndex &&
          other.isDefault == this.isDefault &&
          other.archived == this.archived &&
          other.sortOrder == this.sortOrder &&
          other.createdOn == this.createdOn &&
          other.archivedOn == this.archivedOn &&
          other.addedOn == this.addedOn);
}

class TrackerItemsCompanion extends UpdateCompanion<TrackerItemRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> kind;
  final Value<int?> dailyTarget;
  final Value<String> icon;
  final Value<int> colorIndex;
  final Value<bool> isDefault;
  final Value<bool> archived;
  final Value<int> sortOrder;
  final Value<int?> createdOn;
  final Value<int?> archivedOn;
  final Value<int?> addedOn;
  final Value<int> rowid;
  const TrackerItemsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.dailyTarget = const Value.absent(),
    this.icon = const Value.absent(),
    this.colorIndex = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.archived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdOn = const Value.absent(),
    this.archivedOn = const Value.absent(),
    this.addedOn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrackerItemsCompanion.insert({
    required String id,
    required String name,
    required int kind,
    this.dailyTarget = const Value.absent(),
    required String icon,
    required int colorIndex,
    required bool isDefault,
    this.archived = const Value.absent(),
    required int sortOrder,
    this.createdOn = const Value.absent(),
    this.archivedOn = const Value.absent(),
    this.addedOn = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       kind = Value(kind),
       icon = Value(icon),
       colorIndex = Value(colorIndex),
       isDefault = Value(isDefault),
       sortOrder = Value(sortOrder);
  static Insertable<TrackerItemRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? kind,
    Expression<int>? dailyTarget,
    Expression<String>? icon,
    Expression<int>? colorIndex,
    Expression<bool>? isDefault,
    Expression<bool>? archived,
    Expression<int>? sortOrder,
    Expression<int>? createdOn,
    Expression<int>? archivedOn,
    Expression<int>? addedOn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (dailyTarget != null) 'daily_target': dailyTarget,
      if (icon != null) 'icon': icon,
      if (colorIndex != null) 'color_index': colorIndex,
      if (isDefault != null) 'is_default': isDefault,
      if (archived != null) 'archived': archived,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdOn != null) 'created_on': createdOn,
      if (archivedOn != null) 'archived_on': archivedOn,
      if (addedOn != null) 'added_on': addedOn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrackerItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? kind,
    Value<int?>? dailyTarget,
    Value<String>? icon,
    Value<int>? colorIndex,
    Value<bool>? isDefault,
    Value<bool>? archived,
    Value<int>? sortOrder,
    Value<int?>? createdOn,
    Value<int?>? archivedOn,
    Value<int?>? addedOn,
    Value<int>? rowid,
  }) {
    return TrackerItemsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      dailyTarget: dailyTarget ?? this.dailyTarget,
      icon: icon ?? this.icon,
      colorIndex: colorIndex ?? this.colorIndex,
      isDefault: isDefault ?? this.isDefault,
      archived: archived ?? this.archived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdOn: createdOn ?? this.createdOn,
      archivedOn: archivedOn ?? this.archivedOn,
      addedOn: addedOn ?? this.addedOn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(kind.value);
    }
    if (dailyTarget.present) {
      map['daily_target'] = Variable<int>(dailyTarget.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (colorIndex.present) {
      map['color_index'] = Variable<int>(colorIndex.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdOn.present) {
      map['created_on'] = Variable<int>(createdOn.value);
    }
    if (archivedOn.present) {
      map['archived_on'] = Variable<int>(archivedOn.value);
    }
    if (addedOn.present) {
      map['added_on'] = Variable<int>(addedOn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackerItemsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('dailyTarget: $dailyTarget, ')
          ..write('icon: $icon, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('isDefault: $isDefault, ')
          ..write('archived: $archived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdOn: $createdOn, ')
          ..write('archivedOn: $archivedOn, ')
          ..write('addedOn: $addedOn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyEntriesTable extends DailyEntries
    with TableInfo<$DailyEntriesTable, DailyEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracker_items (id)',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [itemId, date, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId, date};
  @override
  DailyEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyEntryRow(
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $DailyEntriesTable createAlias(String alias) {
    return $DailyEntriesTable(attachedDatabase, alias);
  }
}

class DailyEntryRow extends DataClass implements Insertable<DailyEntryRow> {
  final String itemId;

  /// Civil day encoded as a yyyymmdd integer (e.g. 20260612). Integer
  /// encoding makes range queries (`BETWEEN`) and `GROUP BY` date cheap
  /// and avoids timezone ambiguity for date-only data.
  final int date;
  final int value;
  const DailyEntryRow({
    required this.itemId,
    required this.date,
    required this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<String>(itemId);
    map['date'] = Variable<int>(date);
    map['value'] = Variable<int>(value);
    return map;
  }

  DailyEntriesCompanion toCompanion(bool nullToAbsent) {
    return DailyEntriesCompanion(
      itemId: Value(itemId),
      date: Value(date),
      value: Value(value),
    );
  }

  factory DailyEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyEntryRow(
      itemId: serializer.fromJson<String>(json['itemId']),
      date: serializer.fromJson<int>(json['date']),
      value: serializer.fromJson<int>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<String>(itemId),
      'date': serializer.toJson<int>(date),
      'value': serializer.toJson<int>(value),
    };
  }

  DailyEntryRow copyWith({String? itemId, int? date, int? value}) =>
      DailyEntryRow(
        itemId: itemId ?? this.itemId,
        date: date ?? this.date,
        value: value ?? this.value,
      );
  DailyEntryRow copyWithCompanion(DailyEntriesCompanion data) {
    return DailyEntryRow(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      date: data.date.present ? data.date.value : this.date,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyEntryRow(')
          ..write('itemId: $itemId, ')
          ..write('date: $date, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(itemId, date, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyEntryRow &&
          other.itemId == this.itemId &&
          other.date == this.date &&
          other.value == this.value);
}

class DailyEntriesCompanion extends UpdateCompanion<DailyEntryRow> {
  final Value<String> itemId;
  final Value<int> date;
  final Value<int> value;
  final Value<int> rowid;
  const DailyEntriesCompanion({
    this.itemId = const Value.absent(),
    this.date = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyEntriesCompanion.insert({
    required String itemId,
    required int date,
    required int value,
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       date = Value(date),
       value = Value(value);
  static Insertable<DailyEntryRow> custom({
    Expression<String>? itemId,
    Expression<int>? date,
    Expression<int>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (date != null) 'date': date,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyEntriesCompanion copyWith({
    Value<String>? itemId,
    Value<int>? date,
    Value<int>? value,
    Value<int>? rowid,
  }) {
    return DailyEntriesCompanion(
      itemId: itemId ?? this.itemId,
      date: date ?? this.date,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyEntriesCompanion(')
          ..write('itemId: $itemId, ')
          ..write('date: $date, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrackerArchiveSpansTable extends TrackerArchiveSpans
    with TableInfo<$TrackerArchiveSpansTable, ArchiveSpanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackerArchiveSpansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracker_items (id)',
    ),
  );
  static const VerificationMeta _startOnMeta = const VerificationMeta(
    'startOn',
  );
  @override
  late final GeneratedColumn<int> startOn = GeneratedColumn<int>(
    'start_on',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endOnMeta = const VerificationMeta('endOn');
  @override
  late final GeneratedColumn<int> endOn = GeneratedColumn<int>(
    'end_on',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [itemId, startOn, endOn];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracker_archive_spans';
  @override
  VerificationContext validateIntegrity(
    Insertable<ArchiveSpanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('start_on')) {
      context.handle(
        _startOnMeta,
        startOn.isAcceptableOrUnknown(data['start_on']!, _startOnMeta),
      );
    } else if (isInserting) {
      context.missing(_startOnMeta);
    }
    if (data.containsKey('end_on')) {
      context.handle(
        _endOnMeta,
        endOn.isAcceptableOrUnknown(data['end_on']!, _endOnMeta),
      );
    } else if (isInserting) {
      context.missing(_endOnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId, startOn};
  @override
  ArchiveSpanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArchiveSpanRow(
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      startOn: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_on'],
      )!,
      endOn: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_on'],
      )!,
    );
  }

  @override
  $TrackerArchiveSpansTable createAlias(String alias) {
    return $TrackerArchiveSpansTable(attachedDatabase, alias);
  }
}

class ArchiveSpanRow extends DataClass implements Insertable<ArchiveSpanRow> {
  final String itemId;

  /// yyyymmdd of the archive day (first day not counted).
  final int startOn;

  /// yyyymmdd of the restore day (counts again from this day).
  final int endOn;
  const ArchiveSpanRow({
    required this.itemId,
    required this.startOn,
    required this.endOn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<String>(itemId);
    map['start_on'] = Variable<int>(startOn);
    map['end_on'] = Variable<int>(endOn);
    return map;
  }

  TrackerArchiveSpansCompanion toCompanion(bool nullToAbsent) {
    return TrackerArchiveSpansCompanion(
      itemId: Value(itemId),
      startOn: Value(startOn),
      endOn: Value(endOn),
    );
  }

  factory ArchiveSpanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArchiveSpanRow(
      itemId: serializer.fromJson<String>(json['itemId']),
      startOn: serializer.fromJson<int>(json['startOn']),
      endOn: serializer.fromJson<int>(json['endOn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<String>(itemId),
      'startOn': serializer.toJson<int>(startOn),
      'endOn': serializer.toJson<int>(endOn),
    };
  }

  ArchiveSpanRow copyWith({String? itemId, int? startOn, int? endOn}) =>
      ArchiveSpanRow(
        itemId: itemId ?? this.itemId,
        startOn: startOn ?? this.startOn,
        endOn: endOn ?? this.endOn,
      );
  ArchiveSpanRow copyWithCompanion(TrackerArchiveSpansCompanion data) {
    return ArchiveSpanRow(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      startOn: data.startOn.present ? data.startOn.value : this.startOn,
      endOn: data.endOn.present ? data.endOn.value : this.endOn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArchiveSpanRow(')
          ..write('itemId: $itemId, ')
          ..write('startOn: $startOn, ')
          ..write('endOn: $endOn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(itemId, startOn, endOn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArchiveSpanRow &&
          other.itemId == this.itemId &&
          other.startOn == this.startOn &&
          other.endOn == this.endOn);
}

class TrackerArchiveSpansCompanion extends UpdateCompanion<ArchiveSpanRow> {
  final Value<String> itemId;
  final Value<int> startOn;
  final Value<int> endOn;
  final Value<int> rowid;
  const TrackerArchiveSpansCompanion({
    this.itemId = const Value.absent(),
    this.startOn = const Value.absent(),
    this.endOn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrackerArchiveSpansCompanion.insert({
    required String itemId,
    required int startOn,
    required int endOn,
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       startOn = Value(startOn),
       endOn = Value(endOn);
  static Insertable<ArchiveSpanRow> custom({
    Expression<String>? itemId,
    Expression<int>? startOn,
    Expression<int>? endOn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (startOn != null) 'start_on': startOn,
      if (endOn != null) 'end_on': endOn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrackerArchiveSpansCompanion copyWith({
    Value<String>? itemId,
    Value<int>? startOn,
    Value<int>? endOn,
    Value<int>? rowid,
  }) {
    return TrackerArchiveSpansCompanion(
      itemId: itemId ?? this.itemId,
      startOn: startOn ?? this.startOn,
      endOn: endOn ?? this.endOn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (startOn.present) {
      map['start_on'] = Variable<int>(startOn.value);
    }
    if (endOn.present) {
      map['end_on'] = Variable<int>(endOn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackerArchiveSpansCompanion(')
          ..write('itemId: $itemId, ')
          ..write('startOn: $startOn, ')
          ..write('endOn: $endOn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses
    with TableInfo<$ExpensesTable, ExpenseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, amount, category, date, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpenseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExpenseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class ExpenseRow extends DataClass implements Insertable<ExpenseRow> {
  final int id;

  /// Minor currency units.
  final int amount;

  /// `ExpenseCategory.name`.
  final String category;

  /// Floating wall time: microseconds since epoch of its UTC-flagged value.
  final int date;
  final String note;
  const ExpenseRow({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['amount'] = Variable<int>(amount);
    map['category'] = Variable<String>(category);
    map['date'] = Variable<int>(date);
    map['note'] = Variable<String>(note);
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      amount: Value(amount),
      category: Value(category),
      date: Value(date),
      note: Value(note),
    );
  }

  factory ExpenseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseRow(
      id: serializer.fromJson<int>(json['id']),
      amount: serializer.fromJson<int>(json['amount']),
      category: serializer.fromJson<String>(json['category']),
      date: serializer.fromJson<int>(json['date']),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'amount': serializer.toJson<int>(amount),
      'category': serializer.toJson<String>(category),
      'date': serializer.toJson<int>(date),
      'note': serializer.toJson<String>(note),
    };
  }

  ExpenseRow copyWith({
    int? id,
    int? amount,
    String? category,
    int? date,
    String? note,
  }) => ExpenseRow(
    id: id ?? this.id,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    date: date ?? this.date,
    note: note ?? this.note,
  );
  ExpenseRow copyWithCompanion(ExpensesCompanion data) {
    return ExpenseRow(
      id: data.id.present ? data.id.value : this.id,
      amount: data.amount.present ? data.amount.value : this.amount,
      category: data.category.present ? data.category.value : this.category,
      date: data.date.present ? data.date.value : this.date,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseRow(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('date: $date, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, amount, category, date, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseRow &&
          other.id == this.id &&
          other.amount == this.amount &&
          other.category == this.category &&
          other.date == this.date &&
          other.note == this.note);
}

class ExpensesCompanion extends UpdateCompanion<ExpenseRow> {
  final Value<int> id;
  final Value<int> amount;
  final Value<String> category;
  final Value<int> date;
  final Value<String> note;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.amount = const Value.absent(),
    this.category = const Value.absent(),
    this.date = const Value.absent(),
    this.note = const Value.absent(),
  });
  ExpensesCompanion.insert({
    this.id = const Value.absent(),
    required int amount,
    required String category,
    required int date,
    required String note,
  }) : amount = Value(amount),
       category = Value(category),
       date = Value(date),
       note = Value(note);
  static Insertable<ExpenseRow> custom({
    Expression<int>? id,
    Expression<int>? amount,
    Expression<String>? category,
    Expression<int>? date,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (date != null) 'date': date,
      if (note != null) 'note': note,
    });
  }

  ExpensesCompanion copyWith({
    Value<int>? id,
    Value<int>? amount,
    Value<String>? category,
    Value<int>? date,
    Value<String>? note,
  }) {
    return ExpensesCompanion(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('date: $date, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $ExpenseBudgetsTable extends ExpenseBudgets
    with TableInfo<$ExpenseBudgetsTable, ExpenseBudgetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpenseBudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, amount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expense_budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpenseBudgetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  ExpenseBudgetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseBudgetRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
    );
  }

  @override
  $ExpenseBudgetsTable createAlias(String alias) {
    return $ExpenseBudgetsTable(attachedDatabase, alias);
  }
}

class ExpenseBudgetRow extends DataClass
    implements Insertable<ExpenseBudgetRow> {
  final String key;
  final int amount;
  const ExpenseBudgetRow({required this.key, required this.amount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['amount'] = Variable<int>(amount);
    return map;
  }

  ExpenseBudgetsCompanion toCompanion(bool nullToAbsent) {
    return ExpenseBudgetsCompanion(key: Value(key), amount: Value(amount));
  }

  factory ExpenseBudgetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseBudgetRow(
      key: serializer.fromJson<String>(json['key']),
      amount: serializer.fromJson<int>(json['amount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'amount': serializer.toJson<int>(amount),
    };
  }

  ExpenseBudgetRow copyWith({String? key, int? amount}) =>
      ExpenseBudgetRow(key: key ?? this.key, amount: amount ?? this.amount);
  ExpenseBudgetRow copyWithCompanion(ExpenseBudgetsCompanion data) {
    return ExpenseBudgetRow(
      key: data.key.present ? data.key.value : this.key,
      amount: data.amount.present ? data.amount.value : this.amount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseBudgetRow(')
          ..write('key: $key, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, amount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseBudgetRow &&
          other.key == this.key &&
          other.amount == this.amount);
}

class ExpenseBudgetsCompanion extends UpdateCompanion<ExpenseBudgetRow> {
  final Value<String> key;
  final Value<int> amount;
  final Value<int> rowid;
  const ExpenseBudgetsCompanion({
    this.key = const Value.absent(),
    this.amount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpenseBudgetsCompanion.insert({
    required String key,
    required int amount,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       amount = Value(amount);
  static Insertable<ExpenseBudgetRow> custom({
    Expression<String>? key,
    Expression<int>? amount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (amount != null) 'amount': amount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpenseBudgetsCompanion copyWith({
    Value<String>? key,
    Value<int>? amount,
    Value<int>? rowid,
  }) {
    return ExpenseBudgetsCompanion(
      key: key ?? this.key,
      amount: amount ?? this.amount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseBudgetsCompanion(')
          ..write('key: $key, ')
          ..write('amount: $amount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$MuhasabaDatabase extends GeneratedDatabase {
  _$MuhasabaDatabase(QueryExecutor e) : super(e);
  $MuhasabaDatabaseManager get managers => $MuhasabaDatabaseManager(this);
  late final $TrackerItemsTable trackerItems = $TrackerItemsTable(this);
  late final $DailyEntriesTable dailyEntries = $DailyEntriesTable(this);
  late final $TrackerArchiveSpansTable trackerArchiveSpans =
      $TrackerArchiveSpansTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $ExpenseBudgetsTable expenseBudgets = $ExpenseBudgetsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    trackerItems,
    dailyEntries,
    trackerArchiveSpans,
    expenses,
    expenseBudgets,
  ];
}

typedef $$TrackerItemsTableCreateCompanionBuilder =
    TrackerItemsCompanion Function({
      required String id,
      required String name,
      required int kind,
      Value<int?> dailyTarget,
      required String icon,
      required int colorIndex,
      required bool isDefault,
      Value<bool> archived,
      required int sortOrder,
      Value<int?> createdOn,
      Value<int?> archivedOn,
      Value<int?> addedOn,
      Value<int> rowid,
    });
typedef $$TrackerItemsTableUpdateCompanionBuilder =
    TrackerItemsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> kind,
      Value<int?> dailyTarget,
      Value<String> icon,
      Value<int> colorIndex,
      Value<bool> isDefault,
      Value<bool> archived,
      Value<int> sortOrder,
      Value<int?> createdOn,
      Value<int?> archivedOn,
      Value<int?> addedOn,
      Value<int> rowid,
    });

final class $$TrackerItemsTableReferences
    extends
        BaseReferences<_$MuhasabaDatabase, $TrackerItemsTable, TrackerItemRow> {
  $$TrackerItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DailyEntriesTable, List<DailyEntryRow>>
  _dailyEntriesRefsTable(_$MuhasabaDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.dailyEntries,
        aliasName: 'tracker_items__id__daily_entries__item_id',
      );

  $$DailyEntriesTableProcessedTableManager get dailyEntriesRefs {
    final manager = $$DailyEntriesTableTableManager(
      $_db,
      $_db.dailyEntries,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_dailyEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TrackerArchiveSpansTable, List<ArchiveSpanRow>>
  _trackerArchiveSpansRefsTable(_$MuhasabaDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.trackerArchiveSpans,
        aliasName: 'tracker_items__id__tracker_archive_spans__item_id',
      );

  $$TrackerArchiveSpansTableProcessedTableManager get trackerArchiveSpansRefs {
    final manager = $$TrackerArchiveSpansTableTableManager(
      $_db,
      $_db.trackerArchiveSpans,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _trackerArchiveSpansRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TrackerItemsTableFilterComposer
    extends Composer<_$MuhasabaDatabase, $TrackerItemsTable> {
  $$TrackerItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyTarget => $composableBuilder(
    column: $table.dailyTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdOn => $composableBuilder(
    column: $table.createdOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get archivedOn => $composableBuilder(
    column: $table.archivedOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedOn => $composableBuilder(
    column: $table.addedOn,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> dailyEntriesRefs(
    Expression<bool> Function($$DailyEntriesTableFilterComposer f) f,
  ) {
    final $$DailyEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dailyEntries,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DailyEntriesTableFilterComposer(
            $db: $db,
            $table: $db.dailyEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> trackerArchiveSpansRefs(
    Expression<bool> Function($$TrackerArchiveSpansTableFilterComposer f) f,
  ) {
    final $$TrackerArchiveSpansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackerArchiveSpans,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackerArchiveSpansTableFilterComposer(
            $db: $db,
            $table: $db.trackerArchiveSpans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TrackerItemsTableOrderingComposer
    extends Composer<_$MuhasabaDatabase, $TrackerItemsTable> {
  $$TrackerItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyTarget => $composableBuilder(
    column: $table.dailyTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdOn => $composableBuilder(
    column: $table.createdOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get archivedOn => $composableBuilder(
    column: $table.archivedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedOn => $composableBuilder(
    column: $table.addedOn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrackerItemsTableAnnotationComposer
    extends Composer<_$MuhasabaDatabase, $TrackerItemsTable> {
  $$TrackerItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get dailyTarget => $composableBuilder(
    column: $table.dailyTarget,
    builder: (column) => column,
  );

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdOn =>
      $composableBuilder(column: $table.createdOn, builder: (column) => column);

  GeneratedColumn<int> get archivedOn => $composableBuilder(
    column: $table.archivedOn,
    builder: (column) => column,
  );

  GeneratedColumn<int> get addedOn =>
      $composableBuilder(column: $table.addedOn, builder: (column) => column);

  Expression<T> dailyEntriesRefs<T extends Object>(
    Expression<T> Function($$DailyEntriesTableAnnotationComposer a) f,
  ) {
    final $$DailyEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dailyEntries,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DailyEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.dailyEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> trackerArchiveSpansRefs<T extends Object>(
    Expression<T> Function($$TrackerArchiveSpansTableAnnotationComposer a) f,
  ) {
    final $$TrackerArchiveSpansTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.trackerArchiveSpans,
          getReferencedColumn: (t) => t.itemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TrackerArchiveSpansTableAnnotationComposer(
                $db: $db,
                $table: $db.trackerArchiveSpans,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TrackerItemsTableTableManager
    extends
        RootTableManager<
          _$MuhasabaDatabase,
          $TrackerItemsTable,
          TrackerItemRow,
          $$TrackerItemsTableFilterComposer,
          $$TrackerItemsTableOrderingComposer,
          $$TrackerItemsTableAnnotationComposer,
          $$TrackerItemsTableCreateCompanionBuilder,
          $$TrackerItemsTableUpdateCompanionBuilder,
          (TrackerItemRow, $$TrackerItemsTableReferences),
          TrackerItemRow,
          PrefetchHooks Function({
            bool dailyEntriesRefs,
            bool trackerArchiveSpansRefs,
          })
        > {
  $$TrackerItemsTableTableManager(
    _$MuhasabaDatabase db,
    $TrackerItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackerItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackerItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackerItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> kind = const Value.absent(),
                Value<int?> dailyTarget = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<int> colorIndex = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int?> createdOn = const Value.absent(),
                Value<int?> archivedOn = const Value.absent(),
                Value<int?> addedOn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrackerItemsCompanion(
                id: id,
                name: name,
                kind: kind,
                dailyTarget: dailyTarget,
                icon: icon,
                colorIndex: colorIndex,
                isDefault: isDefault,
                archived: archived,
                sortOrder: sortOrder,
                createdOn: createdOn,
                archivedOn: archivedOn,
                addedOn: addedOn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int kind,
                Value<int?> dailyTarget = const Value.absent(),
                required String icon,
                required int colorIndex,
                required bool isDefault,
                Value<bool> archived = const Value.absent(),
                required int sortOrder,
                Value<int?> createdOn = const Value.absent(),
                Value<int?> archivedOn = const Value.absent(),
                Value<int?> addedOn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrackerItemsCompanion.insert(
                id: id,
                name: name,
                kind: kind,
                dailyTarget: dailyTarget,
                icon: icon,
                colorIndex: colorIndex,
                isDefault: isDefault,
                archived: archived,
                sortOrder: sortOrder,
                createdOn: createdOn,
                archivedOn: archivedOn,
                addedOn: addedOn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TrackerItemsTable, TrackerItemRow>(table),
                  $$TrackerItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({dailyEntriesRefs = false, trackerArchiveSpansRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (dailyEntriesRefs) db.dailyEntries,
                    if (trackerArchiveSpansRefs) db.trackerArchiveSpans,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (dailyEntriesRefs)
                        await $_getPrefetchedDataByColumns<
                          TrackerItemRow,
                          $TrackerItemsTable,
                          DailyEntryRow,
                          $DailyEntriesTable
                        >(
                          currentTable: table,
                          referencedTable: $$TrackerItemsTableReferences
                              ._dailyEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TrackerItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).dailyEntriesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'item_id',
                          typedResults: items,
                        ),
                      if (trackerArchiveSpansRefs)
                        await $_getPrefetchedDataByColumns<
                          TrackerItemRow,
                          $TrackerItemsTable,
                          ArchiveSpanRow,
                          $TrackerArchiveSpansTable
                        >(
                          currentTable: table,
                          referencedTable: $$TrackerItemsTableReferences
                              ._trackerArchiveSpansRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TrackerItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).trackerArchiveSpansRefs,
                          currentColumn: 'id',
                          referencedColumn: 'item_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TrackerItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$MuhasabaDatabase,
      $TrackerItemsTable,
      TrackerItemRow,
      $$TrackerItemsTableFilterComposer,
      $$TrackerItemsTableOrderingComposer,
      $$TrackerItemsTableAnnotationComposer,
      $$TrackerItemsTableCreateCompanionBuilder,
      $$TrackerItemsTableUpdateCompanionBuilder,
      (TrackerItemRow, $$TrackerItemsTableReferences),
      TrackerItemRow,
      PrefetchHooks Function({
        bool dailyEntriesRefs,
        bool trackerArchiveSpansRefs,
      })
    >;
typedef $$DailyEntriesTableCreateCompanionBuilder =
    DailyEntriesCompanion Function({
      required String itemId,
      required int date,
      required int value,
      Value<int> rowid,
    });
typedef $$DailyEntriesTableUpdateCompanionBuilder =
    DailyEntriesCompanion Function({
      Value<String> itemId,
      Value<int> date,
      Value<int> value,
      Value<int> rowid,
    });

final class $$DailyEntriesTableReferences
    extends
        BaseReferences<_$MuhasabaDatabase, $DailyEntriesTable, DailyEntryRow> {
  $$DailyEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TrackerItemsTable _itemIdTable(_$MuhasabaDatabase db) =>
      db.trackerItems.createAlias('daily_entries__item_id__tracker_items__id');

  $$TrackerItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$TrackerItemsTableTableManager(
      $_db,
      $_db.trackerItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DailyEntriesTableFilterComposer
    extends Composer<_$MuhasabaDatabase, $DailyEntriesTable> {
  $$DailyEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  $$TrackerItemsTableFilterComposer get itemId {
    final $$TrackerItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.trackerItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackerItemsTableFilterComposer(
            $db: $db,
            $table: $db.trackerItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DailyEntriesTableOrderingComposer
    extends Composer<_$MuhasabaDatabase, $DailyEntriesTable> {
  $$DailyEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  $$TrackerItemsTableOrderingComposer get itemId {
    final $$TrackerItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.trackerItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackerItemsTableOrderingComposer(
            $db: $db,
            $table: $db.trackerItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DailyEntriesTableAnnotationComposer
    extends Composer<_$MuhasabaDatabase, $DailyEntriesTable> {
  $$DailyEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  $$TrackerItemsTableAnnotationComposer get itemId {
    final $$TrackerItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.trackerItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackerItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.trackerItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DailyEntriesTableTableManager
    extends
        RootTableManager<
          _$MuhasabaDatabase,
          $DailyEntriesTable,
          DailyEntryRow,
          $$DailyEntriesTableFilterComposer,
          $$DailyEntriesTableOrderingComposer,
          $$DailyEntriesTableAnnotationComposer,
          $$DailyEntriesTableCreateCompanionBuilder,
          $$DailyEntriesTableUpdateCompanionBuilder,
          (DailyEntryRow, $$DailyEntriesTableReferences),
          DailyEntryRow,
          PrefetchHooks Function({bool itemId})
        > {
  $$DailyEntriesTableTableManager(
    _$MuhasabaDatabase db,
    $DailyEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> itemId = const Value.absent(),
                Value<int> date = const Value.absent(),
                Value<int> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyEntriesCompanion(
                itemId: itemId,
                date: date,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String itemId,
                required int date,
                required int value,
                Value<int> rowid = const Value.absent(),
              }) => DailyEntriesCompanion.insert(
                itemId: itemId,
                date: date,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DailyEntriesTable, DailyEntryRow>(table),
                  $$DailyEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable: $$DailyEntriesTableReferences
                                    ._itemIdTable(db),
                                referencedColumn: $$DailyEntriesTableReferences
                                    ._itemIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DailyEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$MuhasabaDatabase,
      $DailyEntriesTable,
      DailyEntryRow,
      $$DailyEntriesTableFilterComposer,
      $$DailyEntriesTableOrderingComposer,
      $$DailyEntriesTableAnnotationComposer,
      $$DailyEntriesTableCreateCompanionBuilder,
      $$DailyEntriesTableUpdateCompanionBuilder,
      (DailyEntryRow, $$DailyEntriesTableReferences),
      DailyEntryRow,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$TrackerArchiveSpansTableCreateCompanionBuilder =
    TrackerArchiveSpansCompanion Function({
      required String itemId,
      required int startOn,
      required int endOn,
      Value<int> rowid,
    });
typedef $$TrackerArchiveSpansTableUpdateCompanionBuilder =
    TrackerArchiveSpansCompanion Function({
      Value<String> itemId,
      Value<int> startOn,
      Value<int> endOn,
      Value<int> rowid,
    });

final class $$TrackerArchiveSpansTableReferences
    extends
        BaseReferences<
          _$MuhasabaDatabase,
          $TrackerArchiveSpansTable,
          ArchiveSpanRow
        > {
  $$TrackerArchiveSpansTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TrackerItemsTable _itemIdTable(_$MuhasabaDatabase db) => db
      .trackerItems
      .createAlias('tracker_archive_spans__item_id__tracker_items__id');

  $$TrackerItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$TrackerItemsTableTableManager(
      $_db,
      $_db.trackerItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TrackerArchiveSpansTableFilterComposer
    extends Composer<_$MuhasabaDatabase, $TrackerArchiveSpansTable> {
  $$TrackerArchiveSpansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get startOn => $composableBuilder(
    column: $table.startOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endOn => $composableBuilder(
    column: $table.endOn,
    builder: (column) => ColumnFilters(column),
  );

  $$TrackerItemsTableFilterComposer get itemId {
    final $$TrackerItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.trackerItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackerItemsTableFilterComposer(
            $db: $db,
            $table: $db.trackerItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackerArchiveSpansTableOrderingComposer
    extends Composer<_$MuhasabaDatabase, $TrackerArchiveSpansTable> {
  $$TrackerArchiveSpansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get startOn => $composableBuilder(
    column: $table.startOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endOn => $composableBuilder(
    column: $table.endOn,
    builder: (column) => ColumnOrderings(column),
  );

  $$TrackerItemsTableOrderingComposer get itemId {
    final $$TrackerItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.trackerItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackerItemsTableOrderingComposer(
            $db: $db,
            $table: $db.trackerItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackerArchiveSpansTableAnnotationComposer
    extends Composer<_$MuhasabaDatabase, $TrackerArchiveSpansTable> {
  $$TrackerArchiveSpansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get startOn =>
      $composableBuilder(column: $table.startOn, builder: (column) => column);

  GeneratedColumn<int> get endOn =>
      $composableBuilder(column: $table.endOn, builder: (column) => column);

  $$TrackerItemsTableAnnotationComposer get itemId {
    final $$TrackerItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.trackerItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackerItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.trackerItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackerArchiveSpansTableTableManager
    extends
        RootTableManager<
          _$MuhasabaDatabase,
          $TrackerArchiveSpansTable,
          ArchiveSpanRow,
          $$TrackerArchiveSpansTableFilterComposer,
          $$TrackerArchiveSpansTableOrderingComposer,
          $$TrackerArchiveSpansTableAnnotationComposer,
          $$TrackerArchiveSpansTableCreateCompanionBuilder,
          $$TrackerArchiveSpansTableUpdateCompanionBuilder,
          (ArchiveSpanRow, $$TrackerArchiveSpansTableReferences),
          ArchiveSpanRow,
          PrefetchHooks Function({bool itemId})
        > {
  $$TrackerArchiveSpansTableTableManager(
    _$MuhasabaDatabase db,
    $TrackerArchiveSpansTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackerArchiveSpansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackerArchiveSpansTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TrackerArchiveSpansTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> itemId = const Value.absent(),
                Value<int> startOn = const Value.absent(),
                Value<int> endOn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrackerArchiveSpansCompanion(
                itemId: itemId,
                startOn: startOn,
                endOn: endOn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String itemId,
                required int startOn,
                required int endOn,
                Value<int> rowid = const Value.absent(),
              }) => TrackerArchiveSpansCompanion.insert(
                itemId: itemId,
                startOn: startOn,
                endOn: endOn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TrackerArchiveSpansTable, ArchiveSpanRow>(table),
                  $$TrackerArchiveSpansTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable:
                                    $$TrackerArchiveSpansTableReferences
                                        ._itemIdTable(db),
                                referencedColumn:
                                    $$TrackerArchiveSpansTableReferences
                                        ._itemIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TrackerArchiveSpansTableProcessedTableManager =
    ProcessedTableManager<
      _$MuhasabaDatabase,
      $TrackerArchiveSpansTable,
      ArchiveSpanRow,
      $$TrackerArchiveSpansTableFilterComposer,
      $$TrackerArchiveSpansTableOrderingComposer,
      $$TrackerArchiveSpansTableAnnotationComposer,
      $$TrackerArchiveSpansTableCreateCompanionBuilder,
      $$TrackerArchiveSpansTableUpdateCompanionBuilder,
      (ArchiveSpanRow, $$TrackerArchiveSpansTableReferences),
      ArchiveSpanRow,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$ExpensesTableCreateCompanionBuilder =
    ExpensesCompanion Function({
      Value<int> id,
      required int amount,
      required String category,
      required int date,
      required String note,
    });
typedef $$ExpensesTableUpdateCompanionBuilder =
    ExpensesCompanion Function({
      Value<int> id,
      Value<int> amount,
      Value<String> category,
      Value<int> date,
      Value<String> note,
    });

class $$ExpensesTableFilterComposer
    extends Composer<_$MuhasabaDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
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

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$MuhasabaDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
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

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExpensesTableAnnotationComposer
    extends Composer<_$MuhasabaDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$ExpensesTableTableManager
    extends
        RootTableManager<
          _$MuhasabaDatabase,
          $ExpensesTable,
          ExpenseRow,
          $$ExpensesTableFilterComposer,
          $$ExpensesTableOrderingComposer,
          $$ExpensesTableAnnotationComposer,
          $$ExpensesTableCreateCompanionBuilder,
          $$ExpensesTableUpdateCompanionBuilder,
          (
            ExpenseRow,
            BaseReferences<_$MuhasabaDatabase, $ExpensesTable, ExpenseRow>,
          ),
          ExpenseRow,
          PrefetchHooks Function()
        > {
  $$ExpensesTableTableManager(_$MuhasabaDatabase db, $ExpensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> date = const Value.absent(),
                Value<String> note = const Value.absent(),
              }) => ExpensesCompanion(
                id: id,
                amount: amount,
                category: category,
                date: date,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int amount,
                required String category,
                required int date,
                required String note,
              }) => ExpensesCompanion.insert(
                id: id,
                amount: amount,
                category: category,
                date: date,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExpensesTable, ExpenseRow>(table),
                  BaseReferences<
                    _$MuhasabaDatabase,
                    $ExpensesTable,
                    ExpenseRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$MuhasabaDatabase,
      $ExpensesTable,
      ExpenseRow,
      $$ExpensesTableFilterComposer,
      $$ExpensesTableOrderingComposer,
      $$ExpensesTableAnnotationComposer,
      $$ExpensesTableCreateCompanionBuilder,
      $$ExpensesTableUpdateCompanionBuilder,
      (
        ExpenseRow,
        BaseReferences<_$MuhasabaDatabase, $ExpensesTable, ExpenseRow>,
      ),
      ExpenseRow,
      PrefetchHooks Function()
    >;
typedef $$ExpenseBudgetsTableCreateCompanionBuilder =
    ExpenseBudgetsCompanion Function({
      required String key,
      required int amount,
      Value<int> rowid,
    });
typedef $$ExpenseBudgetsTableUpdateCompanionBuilder =
    ExpenseBudgetsCompanion Function({
      Value<String> key,
      Value<int> amount,
      Value<int> rowid,
    });

class $$ExpenseBudgetsTableFilterComposer
    extends Composer<_$MuhasabaDatabase, $ExpenseBudgetsTable> {
  $$ExpenseBudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExpenseBudgetsTableOrderingComposer
    extends Composer<_$MuhasabaDatabase, $ExpenseBudgetsTable> {
  $$ExpenseBudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExpenseBudgetsTableAnnotationComposer
    extends Composer<_$MuhasabaDatabase, $ExpenseBudgetsTable> {
  $$ExpenseBudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);
}

class $$ExpenseBudgetsTableTableManager
    extends
        RootTableManager<
          _$MuhasabaDatabase,
          $ExpenseBudgetsTable,
          ExpenseBudgetRow,
          $$ExpenseBudgetsTableFilterComposer,
          $$ExpenseBudgetsTableOrderingComposer,
          $$ExpenseBudgetsTableAnnotationComposer,
          $$ExpenseBudgetsTableCreateCompanionBuilder,
          $$ExpenseBudgetsTableUpdateCompanionBuilder,
          (
            ExpenseBudgetRow,
            BaseReferences<
              _$MuhasabaDatabase,
              $ExpenseBudgetsTable,
              ExpenseBudgetRow
            >,
          ),
          ExpenseBudgetRow,
          PrefetchHooks Function()
        > {
  $$ExpenseBudgetsTableTableManager(
    _$MuhasabaDatabase db,
    $ExpenseBudgetsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpenseBudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpenseBudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpenseBudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpenseBudgetsCompanion(
                key: key,
                amount: amount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required int amount,
                Value<int> rowid = const Value.absent(),
              }) => ExpenseBudgetsCompanion.insert(
                key: key,
                amount: amount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExpenseBudgetsTable, ExpenseBudgetRow>(table),
                  BaseReferences<
                    _$MuhasabaDatabase,
                    $ExpenseBudgetsTable,
                    ExpenseBudgetRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExpenseBudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$MuhasabaDatabase,
      $ExpenseBudgetsTable,
      ExpenseBudgetRow,
      $$ExpenseBudgetsTableFilterComposer,
      $$ExpenseBudgetsTableOrderingComposer,
      $$ExpenseBudgetsTableAnnotationComposer,
      $$ExpenseBudgetsTableCreateCompanionBuilder,
      $$ExpenseBudgetsTableUpdateCompanionBuilder,
      (
        ExpenseBudgetRow,
        BaseReferences<
          _$MuhasabaDatabase,
          $ExpenseBudgetsTable,
          ExpenseBudgetRow
        >,
      ),
      ExpenseBudgetRow,
      PrefetchHooks Function()
    >;

class $MuhasabaDatabaseManager {
  final _$MuhasabaDatabase _db;
  $MuhasabaDatabaseManager(this._db);
  $$TrackerItemsTableTableManager get trackerItems =>
      $$TrackerItemsTableTableManager(_db, _db.trackerItems);
  $$DailyEntriesTableTableManager get dailyEntries =>
      $$DailyEntriesTableTableManager(_db, _db.dailyEntries);
  $$TrackerArchiveSpansTableTableManager get trackerArchiveSpans =>
      $$TrackerArchiveSpansTableTableManager(_db, _db.trackerArchiveSpans);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$ExpenseBudgetsTableTableManager get expenseBudgets =>
      $$ExpenseBudgetsTableTableManager(_db, _db.expenseBudgets);
}
