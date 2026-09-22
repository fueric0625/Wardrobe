// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ClothingItemsTable extends ClothingItems
    with TableInfo<$ClothingItemsTable, ClothingItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClothingItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _styleMeta = const VerificationMeta('style');
  @override
  late final GeneratedColumn<String> style = GeneratedColumn<String>(
    'style',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _seasonMeta = const VerificationMeta('season');
  @override
  late final GeneratedColumn<String> season = GeneratedColumn<String>(
    'season',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _fabricMeta = const VerificationMeta('fabric');
  @override
  late final GeneratedColumn<String> fabric = GeneratedColumn<String>(
    'fabric',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _measurementsMeta = const VerificationMeta(
    'measurements',
  );
  @override
  late final GeneratedColumn<String> measurements = GeneratedColumn<String>(
    'measurements',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _purchasedAtMeta = const VerificationMeta(
    'purchasedAt',
  );
  @override
  late final GeneratedColumn<DateTime> purchasedAt = GeneratedColumn<DateTime>(
    'purchased_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchaseInfoMeta = const VerificationMeta(
    'purchaseInfo',
  );
  @override
  late final GeneratedColumn<String> purchaseInfo = GeneratedColumn<String>(
    'purchase_info',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    categoryId,
    imagePath,
    type,
    style,
    color,
    season,
    fabric,
    brand,
    price,
    measurements,
    purchasedAt,
    purchaseInfo,
    location,
    tags,
    note,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clothing_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClothingItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('style')) {
      context.handle(
        _styleMeta,
        style.isAcceptableOrUnknown(data['style']!, _styleMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('season')) {
      context.handle(
        _seasonMeta,
        season.isAcceptableOrUnknown(data['season']!, _seasonMeta),
      );
    }
    if (data.containsKey('fabric')) {
      context.handle(
        _fabricMeta,
        fabric.isAcceptableOrUnknown(data['fabric']!, _fabricMeta),
      );
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    }
    if (data.containsKey('measurements')) {
      context.handle(
        _measurementsMeta,
        measurements.isAcceptableOrUnknown(
          data['measurements']!,
          _measurementsMeta,
        ),
      );
    }
    if (data.containsKey('purchased_at')) {
      context.handle(
        _purchasedAtMeta,
        purchasedAt.isAcceptableOrUnknown(
          data['purchased_at']!,
          _purchasedAtMeta,
        ),
      );
    }
    if (data.containsKey('purchase_info')) {
      context.handle(
        _purchaseInfoMeta,
        purchaseInfo.isAcceptableOrUnknown(
          data['purchase_info']!,
          _purchaseInfoMeta,
        ),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClothingItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClothingItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      style: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}style'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      season: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}season'],
      )!,
      fabric: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fabric'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      ),
      measurements: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}measurements'],
      )!,
      purchasedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}purchased_at'],
      ),
      purchaseInfo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_info'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ClothingItemsTable createAlias(String alias) {
    return $ClothingItemsTable(attachedDatabase, alias);
  }
}

class ClothingItem extends DataClass implements Insertable<ClothingItem> {
  final String id;
  final String categoryId;
  final String? imagePath;
  final String type;
  final String style;
  final String color;
  final String season;
  final String fabric;
  final String brand;
  final double? price;
  final String measurements;
  final DateTime? purchasedAt;
  final String purchaseInfo;
  final String location;
  final String tags;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ClothingItem({
    required this.id,
    required this.categoryId,
    this.imagePath,
    required this.type,
    required this.style,
    required this.color,
    required this.season,
    required this.fabric,
    required this.brand,
    this.price,
    required this.measurements,
    this.purchasedAt,
    required this.purchaseInfo,
    required this.location,
    required this.tags,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category_id'] = Variable<String>(categoryId);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['type'] = Variable<String>(type);
    map['style'] = Variable<String>(style);
    map['color'] = Variable<String>(color);
    map['season'] = Variable<String>(season);
    map['fabric'] = Variable<String>(fabric);
    map['brand'] = Variable<String>(brand);
    if (!nullToAbsent || price != null) {
      map['price'] = Variable<double>(price);
    }
    map['measurements'] = Variable<String>(measurements);
    if (!nullToAbsent || purchasedAt != null) {
      map['purchased_at'] = Variable<DateTime>(purchasedAt);
    }
    map['purchase_info'] = Variable<String>(purchaseInfo);
    map['location'] = Variable<String>(location);
    map['tags'] = Variable<String>(tags);
    map['note'] = Variable<String>(note);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ClothingItemsCompanion toCompanion(bool nullToAbsent) {
    return ClothingItemsCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      type: Value(type),
      style: Value(style),
      color: Value(color),
      season: Value(season),
      fabric: Value(fabric),
      brand: Value(brand),
      price: price == null && nullToAbsent
          ? const Value.absent()
          : Value(price),
      measurements: Value(measurements),
      purchasedAt: purchasedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(purchasedAt),
      purchaseInfo: Value(purchaseInfo),
      location: Value(location),
      tags: Value(tags),
      note: Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ClothingItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClothingItem(
      id: serializer.fromJson<String>(json['id']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      type: serializer.fromJson<String>(json['type']),
      style: serializer.fromJson<String>(json['style']),
      color: serializer.fromJson<String>(json['color']),
      season: serializer.fromJson<String>(json['season']),
      fabric: serializer.fromJson<String>(json['fabric']),
      brand: serializer.fromJson<String>(json['brand']),
      price: serializer.fromJson<double?>(json['price']),
      measurements: serializer.fromJson<String>(json['measurements']),
      purchasedAt: serializer.fromJson<DateTime?>(json['purchasedAt']),
      purchaseInfo: serializer.fromJson<String>(json['purchaseInfo']),
      location: serializer.fromJson<String>(json['location']),
      tags: serializer.fromJson<String>(json['tags']),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'categoryId': serializer.toJson<String>(categoryId),
      'imagePath': serializer.toJson<String?>(imagePath),
      'type': serializer.toJson<String>(type),
      'style': serializer.toJson<String>(style),
      'color': serializer.toJson<String>(color),
      'season': serializer.toJson<String>(season),
      'fabric': serializer.toJson<String>(fabric),
      'brand': serializer.toJson<String>(brand),
      'price': serializer.toJson<double?>(price),
      'measurements': serializer.toJson<String>(measurements),
      'purchasedAt': serializer.toJson<DateTime?>(purchasedAt),
      'purchaseInfo': serializer.toJson<String>(purchaseInfo),
      'location': serializer.toJson<String>(location),
      'tags': serializer.toJson<String>(tags),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ClothingItem copyWith({
    String? id,
    String? categoryId,
    Value<String?> imagePath = const Value.absent(),
    String? type,
    String? style,
    String? color,
    String? season,
    String? fabric,
    String? brand,
    Value<double?> price = const Value.absent(),
    String? measurements,
    Value<DateTime?> purchasedAt = const Value.absent(),
    String? purchaseInfo,
    String? location,
    String? tags,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ClothingItem(
    id: id ?? this.id,
    categoryId: categoryId ?? this.categoryId,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    type: type ?? this.type,
    style: style ?? this.style,
    color: color ?? this.color,
    season: season ?? this.season,
    fabric: fabric ?? this.fabric,
    brand: brand ?? this.brand,
    price: price.present ? price.value : this.price,
    measurements: measurements ?? this.measurements,
    purchasedAt: purchasedAt.present ? purchasedAt.value : this.purchasedAt,
    purchaseInfo: purchaseInfo ?? this.purchaseInfo,
    location: location ?? this.location,
    tags: tags ?? this.tags,
    note: note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ClothingItem copyWithCompanion(ClothingItemsCompanion data) {
    return ClothingItem(
      id: data.id.present ? data.id.value : this.id,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      type: data.type.present ? data.type.value : this.type,
      style: data.style.present ? data.style.value : this.style,
      color: data.color.present ? data.color.value : this.color,
      season: data.season.present ? data.season.value : this.season,
      fabric: data.fabric.present ? data.fabric.value : this.fabric,
      brand: data.brand.present ? data.brand.value : this.brand,
      price: data.price.present ? data.price.value : this.price,
      measurements: data.measurements.present
          ? data.measurements.value
          : this.measurements,
      purchasedAt: data.purchasedAt.present
          ? data.purchasedAt.value
          : this.purchasedAt,
      purchaseInfo: data.purchaseInfo.present
          ? data.purchaseInfo.value
          : this.purchaseInfo,
      location: data.location.present ? data.location.value : this.location,
      tags: data.tags.present ? data.tags.value : this.tags,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClothingItem(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('imagePath: $imagePath, ')
          ..write('type: $type, ')
          ..write('style: $style, ')
          ..write('color: $color, ')
          ..write('season: $season, ')
          ..write('fabric: $fabric, ')
          ..write('brand: $brand, ')
          ..write('price: $price, ')
          ..write('measurements: $measurements, ')
          ..write('purchasedAt: $purchasedAt, ')
          ..write('purchaseInfo: $purchaseInfo, ')
          ..write('location: $location, ')
          ..write('tags: $tags, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    categoryId,
    imagePath,
    type,
    style,
    color,
    season,
    fabric,
    brand,
    price,
    measurements,
    purchasedAt,
    purchaseInfo,
    location,
    tags,
    note,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClothingItem &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.imagePath == this.imagePath &&
          other.type == this.type &&
          other.style == this.style &&
          other.color == this.color &&
          other.season == this.season &&
          other.fabric == this.fabric &&
          other.brand == this.brand &&
          other.price == this.price &&
          other.measurements == this.measurements &&
          other.purchasedAt == this.purchasedAt &&
          other.purchaseInfo == this.purchaseInfo &&
          other.location == this.location &&
          other.tags == this.tags &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ClothingItemsCompanion extends UpdateCompanion<ClothingItem> {
  final Value<String> id;
  final Value<String> categoryId;
  final Value<String?> imagePath;
  final Value<String> type;
  final Value<String> style;
  final Value<String> color;
  final Value<String> season;
  final Value<String> fabric;
  final Value<String> brand;
  final Value<double?> price;
  final Value<String> measurements;
  final Value<DateTime?> purchasedAt;
  final Value<String> purchaseInfo;
  final Value<String> location;
  final Value<String> tags;
  final Value<String> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ClothingItemsCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.type = const Value.absent(),
    this.style = const Value.absent(),
    this.color = const Value.absent(),
    this.season = const Value.absent(),
    this.fabric = const Value.absent(),
    this.brand = const Value.absent(),
    this.price = const Value.absent(),
    this.measurements = const Value.absent(),
    this.purchasedAt = const Value.absent(),
    this.purchaseInfo = const Value.absent(),
    this.location = const Value.absent(),
    this.tags = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClothingItemsCompanion.insert({
    required String id,
    required String categoryId,
    this.imagePath = const Value.absent(),
    this.type = const Value.absent(),
    this.style = const Value.absent(),
    this.color = const Value.absent(),
    this.season = const Value.absent(),
    this.fabric = const Value.absent(),
    this.brand = const Value.absent(),
    this.price = const Value.absent(),
    this.measurements = const Value.absent(),
    this.purchasedAt = const Value.absent(),
    this.purchaseInfo = const Value.absent(),
    this.location = const Value.absent(),
    this.tags = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       categoryId = Value(categoryId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ClothingItem> custom({
    Expression<String>? id,
    Expression<String>? categoryId,
    Expression<String>? imagePath,
    Expression<String>? type,
    Expression<String>? style,
    Expression<String>? color,
    Expression<String>? season,
    Expression<String>? fabric,
    Expression<String>? brand,
    Expression<double>? price,
    Expression<String>? measurements,
    Expression<DateTime>? purchasedAt,
    Expression<String>? purchaseInfo,
    Expression<String>? location,
    Expression<String>? tags,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (imagePath != null) 'image_path': imagePath,
      if (type != null) 'type': type,
      if (style != null) 'style': style,
      if (color != null) 'color': color,
      if (season != null) 'season': season,
      if (fabric != null) 'fabric': fabric,
      if (brand != null) 'brand': brand,
      if (price != null) 'price': price,
      if (measurements != null) 'measurements': measurements,
      if (purchasedAt != null) 'purchased_at': purchasedAt,
      if (purchaseInfo != null) 'purchase_info': purchaseInfo,
      if (location != null) 'location': location,
      if (tags != null) 'tags': tags,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClothingItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? categoryId,
    Value<String?>? imagePath,
    Value<String>? type,
    Value<String>? style,
    Value<String>? color,
    Value<String>? season,
    Value<String>? fabric,
    Value<String>? brand,
    Value<double?>? price,
    Value<String>? measurements,
    Value<DateTime?>? purchasedAt,
    Value<String>? purchaseInfo,
    Value<String>? location,
    Value<String>? tags,
    Value<String>? note,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ClothingItemsCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      imagePath: imagePath ?? this.imagePath,
      type: type ?? this.type,
      style: style ?? this.style,
      color: color ?? this.color,
      season: season ?? this.season,
      fabric: fabric ?? this.fabric,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      measurements: measurements ?? this.measurements,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      purchaseInfo: purchaseInfo ?? this.purchaseInfo,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (style.present) {
      map['style'] = Variable<String>(style.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (season.present) {
      map['season'] = Variable<String>(season.value);
    }
    if (fabric.present) {
      map['fabric'] = Variable<String>(fabric.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (measurements.present) {
      map['measurements'] = Variable<String>(measurements.value);
    }
    if (purchasedAt.present) {
      map['purchased_at'] = Variable<DateTime>(purchasedAt.value);
    }
    if (purchaseInfo.present) {
      map['purchase_info'] = Variable<String>(purchaseInfo.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClothingItemsCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('imagePath: $imagePath, ')
          ..write('type: $type, ')
          ..write('style: $style, ')
          ..write('color: $color, ')
          ..write('season: $season, ')
          ..write('fabric: $fabric, ')
          ..write('brand: $brand, ')
          ..write('price: $price, ')
          ..write('measurements: $measurements, ')
          ..write('purchasedAt: $purchasedAt, ')
          ..write('purchaseInfo: $purchaseInfo, ')
          ..write('location: $location, ')
          ..write('tags: $tags, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutfitsTable extends Outfits with TableInfo<$OutfitsTable, Outfit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutfitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceImagePathMeta = const VerificationMeta(
    'sourceImagePath',
  );
  @override
  late final GeneratedColumn<String> sourceImagePath = GeneratedColumn<String>(
    'source_image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverModeMeta = const VerificationMeta(
    'coverMode',
  );
  @override
  late final GeneratedColumn<String> coverMode = GeneratedColumn<String>(
    'cover_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('photo'),
  );
  static const VerificationMeta _collageLayoutMeta = const VerificationMeta(
    'collageLayout',
  );
  @override
  late final GeneratedColumn<String> collageLayout = GeneratedColumn<String>(
    'collage_layout',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _seasonMeta = const VerificationMeta('season');
  @override
  late final GeneratedColumn<String> season = GeneratedColumn<String>(
    'season',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    categoryId,
    imagePath,
    sourceImagePath,
    coverMode,
    collageLayout,
    name,
    season,
    note,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outfits';
  @override
  VerificationContext validateIntegrity(
    Insertable<Outfit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('source_image_path')) {
      context.handle(
        _sourceImagePathMeta,
        sourceImagePath.isAcceptableOrUnknown(
          data['source_image_path']!,
          _sourceImagePathMeta,
        ),
      );
    }
    if (data.containsKey('cover_mode')) {
      context.handle(
        _coverModeMeta,
        coverMode.isAcceptableOrUnknown(data['cover_mode']!, _coverModeMeta),
      );
    }
    if (data.containsKey('collage_layout')) {
      context.handle(
        _collageLayoutMeta,
        collageLayout.isAcceptableOrUnknown(
          data['collage_layout']!,
          _collageLayoutMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('season')) {
      context.handle(
        _seasonMeta,
        season.isAcceptableOrUnknown(data['season']!, _seasonMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Outfit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Outfit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      sourceImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_image_path'],
      ),
      coverMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_mode'],
      )!,
      collageLayout: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collage_layout'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      season: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}season'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $OutfitsTable createAlias(String alias) {
    return $OutfitsTable(attachedDatabase, alias);
  }
}

class Outfit extends DataClass implements Insertable<Outfit> {
  final String id;
  final String categoryId;
  final String? imagePath;
  final String? sourceImagePath;

  /// `photo` uses the full-body image. `collage` uses the arranged clothes.
  final String coverMode;

  /// JSON placements for a manual collage. Empty means an automatic layout.
  final String? collageLayout;
  final String name;
  final String season;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Outfit({
    required this.id,
    required this.categoryId,
    this.imagePath,
    this.sourceImagePath,
    required this.coverMode,
    this.collageLayout,
    required this.name,
    required this.season,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category_id'] = Variable<String>(categoryId);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    if (!nullToAbsent || sourceImagePath != null) {
      map['source_image_path'] = Variable<String>(sourceImagePath);
    }
    map['cover_mode'] = Variable<String>(coverMode);
    if (!nullToAbsent || collageLayout != null) {
      map['collage_layout'] = Variable<String>(collageLayout);
    }
    map['name'] = Variable<String>(name);
    map['season'] = Variable<String>(season);
    map['note'] = Variable<String>(note);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  OutfitsCompanion toCompanion(bool nullToAbsent) {
    return OutfitsCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      sourceImagePath: sourceImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceImagePath),
      coverMode: Value(coverMode),
      collageLayout: collageLayout == null && nullToAbsent
          ? const Value.absent()
          : Value(collageLayout),
      name: Value(name),
      season: Value(season),
      note: Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Outfit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Outfit(
      id: serializer.fromJson<String>(json['id']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      sourceImagePath: serializer.fromJson<String?>(json['sourceImagePath']),
      coverMode: serializer.fromJson<String>(json['coverMode']),
      collageLayout: serializer.fromJson<String?>(json['collageLayout']),
      name: serializer.fromJson<String>(json['name']),
      season: serializer.fromJson<String>(json['season']),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'categoryId': serializer.toJson<String>(categoryId),
      'imagePath': serializer.toJson<String?>(imagePath),
      'sourceImagePath': serializer.toJson<String?>(sourceImagePath),
      'coverMode': serializer.toJson<String>(coverMode),
      'collageLayout': serializer.toJson<String?>(collageLayout),
      'name': serializer.toJson<String>(name),
      'season': serializer.toJson<String>(season),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Outfit copyWith({
    String? id,
    String? categoryId,
    Value<String?> imagePath = const Value.absent(),
    Value<String?> sourceImagePath = const Value.absent(),
    String? coverMode,
    Value<String?> collageLayout = const Value.absent(),
    String? name,
    String? season,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Outfit(
    id: id ?? this.id,
    categoryId: categoryId ?? this.categoryId,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    sourceImagePath: sourceImagePath.present
        ? sourceImagePath.value
        : this.sourceImagePath,
    coverMode: coverMode ?? this.coverMode,
    collageLayout: collageLayout.present
        ? collageLayout.value
        : this.collageLayout,
    name: name ?? this.name,
    season: season ?? this.season,
    note: note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Outfit copyWithCompanion(OutfitsCompanion data) {
    return Outfit(
      id: data.id.present ? data.id.value : this.id,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      sourceImagePath: data.sourceImagePath.present
          ? data.sourceImagePath.value
          : this.sourceImagePath,
      coverMode: data.coverMode.present ? data.coverMode.value : this.coverMode,
      collageLayout: data.collageLayout.present
          ? data.collageLayout.value
          : this.collageLayout,
      name: data.name.present ? data.name.value : this.name,
      season: data.season.present ? data.season.value : this.season,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Outfit(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('imagePath: $imagePath, ')
          ..write('sourceImagePath: $sourceImagePath, ')
          ..write('coverMode: $coverMode, ')
          ..write('collageLayout: $collageLayout, ')
          ..write('name: $name, ')
          ..write('season: $season, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    categoryId,
    imagePath,
    sourceImagePath,
    coverMode,
    collageLayout,
    name,
    season,
    note,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Outfit &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.imagePath == this.imagePath &&
          other.sourceImagePath == this.sourceImagePath &&
          other.coverMode == this.coverMode &&
          other.collageLayout == this.collageLayout &&
          other.name == this.name &&
          other.season == this.season &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OutfitsCompanion extends UpdateCompanion<Outfit> {
  final Value<String> id;
  final Value<String> categoryId;
  final Value<String?> imagePath;
  final Value<String?> sourceImagePath;
  final Value<String> coverMode;
  final Value<String?> collageLayout;
  final Value<String> name;
  final Value<String> season;
  final Value<String> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const OutfitsCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.sourceImagePath = const Value.absent(),
    this.coverMode = const Value.absent(),
    this.collageLayout = const Value.absent(),
    this.name = const Value.absent(),
    this.season = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutfitsCompanion.insert({
    required String id,
    required String categoryId,
    this.imagePath = const Value.absent(),
    this.sourceImagePath = const Value.absent(),
    this.coverMode = const Value.absent(),
    this.collageLayout = const Value.absent(),
    this.name = const Value.absent(),
    this.season = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       categoryId = Value(categoryId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Outfit> custom({
    Expression<String>? id,
    Expression<String>? categoryId,
    Expression<String>? imagePath,
    Expression<String>? sourceImagePath,
    Expression<String>? coverMode,
    Expression<String>? collageLayout,
    Expression<String>? name,
    Expression<String>? season,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (imagePath != null) 'image_path': imagePath,
      if (sourceImagePath != null) 'source_image_path': sourceImagePath,
      if (coverMode != null) 'cover_mode': coverMode,
      if (collageLayout != null) 'collage_layout': collageLayout,
      if (name != null) 'name': name,
      if (season != null) 'season': season,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutfitsCompanion copyWith({
    Value<String>? id,
    Value<String>? categoryId,
    Value<String?>? imagePath,
    Value<String?>? sourceImagePath,
    Value<String>? coverMode,
    Value<String?>? collageLayout,
    Value<String>? name,
    Value<String>? season,
    Value<String>? note,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return OutfitsCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      imagePath: imagePath ?? this.imagePath,
      sourceImagePath: sourceImagePath ?? this.sourceImagePath,
      coverMode: coverMode ?? this.coverMode,
      collageLayout: collageLayout ?? this.collageLayout,
      name: name ?? this.name,
      season: season ?? this.season,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (sourceImagePath.present) {
      map['source_image_path'] = Variable<String>(sourceImagePath.value);
    }
    if (coverMode.present) {
      map['cover_mode'] = Variable<String>(coverMode.value);
    }
    if (collageLayout.present) {
      map['collage_layout'] = Variable<String>(collageLayout.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (season.present) {
      map['season'] = Variable<String>(season.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutfitsCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('imagePath: $imagePath, ')
          ..write('sourceImagePath: $sourceImagePath, ')
          ..write('coverMode: $coverMode, ')
          ..write('collageLayout: $collageLayout, ')
          ..write('name: $name, ')
          ..write('season: $season, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoryCoversTable extends CategoryCovers
    with TableInfo<$CategoryCoversTable, CategoryCover> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryCoversTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverItemIdMeta = const VerificationMeta(
    'coverItemId',
  );
  @override
  late final GeneratedColumn<String> coverItemId = GeneratedColumn<String>(
    'cover_item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [kind, categoryId, coverItemId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_covers';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryCover> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('cover_item_id')) {
      context.handle(
        _coverItemIdMeta,
        coverItemId.isAcceptableOrUnknown(
          data['cover_item_id']!,
          _coverItemIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kind, categoryId};
  @override
  CategoryCover map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryCover(
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      coverItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_item_id'],
      ),
    );
  }

  @override
  $CategoryCoversTable createAlias(String alias) {
    return $CategoryCoversTable(attachedDatabase, alias);
  }
}

class CategoryCover extends DataClass implements Insertable<CategoryCover> {
  final String kind;
  final String categoryId;
  final String? coverItemId;
  const CategoryCover({
    required this.kind,
    required this.categoryId,
    this.coverItemId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind'] = Variable<String>(kind);
    map['category_id'] = Variable<String>(categoryId);
    if (!nullToAbsent || coverItemId != null) {
      map['cover_item_id'] = Variable<String>(coverItemId);
    }
    return map;
  }

  CategoryCoversCompanion toCompanion(bool nullToAbsent) {
    return CategoryCoversCompanion(
      kind: Value(kind),
      categoryId: Value(categoryId),
      coverItemId: coverItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(coverItemId),
    );
  }

  factory CategoryCover.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryCover(
      kind: serializer.fromJson<String>(json['kind']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      coverItemId: serializer.fromJson<String?>(json['coverItemId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(kind),
      'categoryId': serializer.toJson<String>(categoryId),
      'coverItemId': serializer.toJson<String?>(coverItemId),
    };
  }

  CategoryCover copyWith({
    String? kind,
    String? categoryId,
    Value<String?> coverItemId = const Value.absent(),
  }) => CategoryCover(
    kind: kind ?? this.kind,
    categoryId: categoryId ?? this.categoryId,
    coverItemId: coverItemId.present ? coverItemId.value : this.coverItemId,
  );
  CategoryCover copyWithCompanion(CategoryCoversCompanion data) {
    return CategoryCover(
      kind: data.kind.present ? data.kind.value : this.kind,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      coverItemId: data.coverItemId.present
          ? data.coverItemId.value
          : this.coverItemId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryCover(')
          ..write('kind: $kind, ')
          ..write('categoryId: $categoryId, ')
          ..write('coverItemId: $coverItemId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kind, categoryId, coverItemId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryCover &&
          other.kind == this.kind &&
          other.categoryId == this.categoryId &&
          other.coverItemId == this.coverItemId);
}

class CategoryCoversCompanion extends UpdateCompanion<CategoryCover> {
  final Value<String> kind;
  final Value<String> categoryId;
  final Value<String?> coverItemId;
  final Value<int> rowid;
  const CategoryCoversCompanion({
    this.kind = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.coverItemId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoryCoversCompanion.insert({
    required String kind,
    required String categoryId,
    this.coverItemId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : kind = Value(kind),
       categoryId = Value(categoryId);
  static Insertable<CategoryCover> custom({
    Expression<String>? kind,
    Expression<String>? categoryId,
    Expression<String>? coverItemId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (categoryId != null) 'category_id': categoryId,
      if (coverItemId != null) 'cover_item_id': coverItemId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoryCoversCompanion copyWith({
    Value<String>? kind,
    Value<String>? categoryId,
    Value<String?>? coverItemId,
    Value<int>? rowid,
  }) {
    return CategoryCoversCompanion(
      kind: kind ?? this.kind,
      categoryId: categoryId ?? this.categoryId,
      coverItemId: coverItemId ?? this.coverItemId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (coverItemId.present) {
      map['cover_item_id'] = Variable<String>(coverItemId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryCoversCompanion(')
          ..write('kind: $kind, ')
          ..write('categoryId: $categoryId, ')
          ..write('coverItemId: $coverItemId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeFieldsMeta = const VerificationMeta(
    'sizeFields',
  );
  @override
  late final GeneratedColumn<String> sizeFields = GeneratedColumn<String>(
    'size_fields',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _isSystemMeta = const VerificationMeta(
    'isSystem',
  );
  @override
  late final GeneratedColumn<bool> isSystem = GeneratedColumn<bool>(
    'is_system',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_system" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    parentId,
    label,
    sortOrder,
    sizeFields,
    isSystem,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('size_fields')) {
      context.handle(
        _sizeFieldsMeta,
        sizeFields.isAcceptableOrUnknown(data['size_fields']!, _sizeFieldsMeta),
      );
    }
    if (data.containsKey('is_system')) {
      context.handle(
        _isSystemMeta,
        isSystem.isAcceptableOrUnknown(data['is_system']!, _isSystemMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kind, id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      sizeFields: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}size_fields'],
      )!,
      isSystem: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_system'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final String id;
  final String kind;
  final String? parentId;
  final String label;
  final int sortOrder;
  final String sizeFields;
  final bool isSystem;
  const Category({
    required this.id,
    required this.kind,
    this.parentId,
    required this.label,
    required this.sortOrder,
    required this.sizeFields,
    required this.isSystem,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['label'] = Variable<String>(label);
    map['sort_order'] = Variable<int>(sortOrder);
    map['size_fields'] = Variable<String>(sizeFields);
    map['is_system'] = Variable<bool>(isSystem);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      kind: Value(kind),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      label: Value(label),
      sortOrder: Value(sortOrder),
      sizeFields: Value(sizeFields),
      isSystem: Value(isSystem),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      label: serializer.fromJson<String>(json['label']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      sizeFields: serializer.fromJson<String>(json['sizeFields']),
      isSystem: serializer.fromJson<bool>(json['isSystem']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'parentId': serializer.toJson<String?>(parentId),
      'label': serializer.toJson<String>(label),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'sizeFields': serializer.toJson<String>(sizeFields),
      'isSystem': serializer.toJson<bool>(isSystem),
    };
  }

  Category copyWith({
    String? id,
    String? kind,
    Value<String?> parentId = const Value.absent(),
    String? label,
    int? sortOrder,
    String? sizeFields,
    bool? isSystem,
  }) => Category(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    parentId: parentId.present ? parentId.value : this.parentId,
    label: label ?? this.label,
    sortOrder: sortOrder ?? this.sortOrder,
    sizeFields: sizeFields ?? this.sizeFields,
    isSystem: isSystem ?? this.isSystem,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      label: data.label.present ? data.label.value : this.label,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      sizeFields: data.sizeFields.present
          ? data.sizeFields.value
          : this.sizeFields,
      isSystem: data.isSystem.present ? data.isSystem.value : this.isSystem,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('parentId: $parentId, ')
          ..write('label: $label, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('sizeFields: $sizeFields, ')
          ..write('isSystem: $isSystem')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, kind, parentId, label, sortOrder, sizeFields, isSystem);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.parentId == this.parentId &&
          other.label == this.label &&
          other.sortOrder == this.sortOrder &&
          other.sizeFields == this.sizeFields &&
          other.isSystem == this.isSystem);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String?> parentId;
  final Value<String> label;
  final Value<int> sortOrder;
  final Value<String> sizeFields;
  final Value<bool> isSystem;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.parentId = const Value.absent(),
    this.label = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.sizeFields = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String kind,
    this.parentId = const Value.absent(),
    required String label,
    required int sortOrder,
    this.sizeFields = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       label = Value(label),
       sortOrder = Value(sortOrder);
  static Insertable<Category> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? parentId,
    Expression<String>? label,
    Expression<int>? sortOrder,
    Expression<String>? sizeFields,
    Expression<bool>? isSystem,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (parentId != null) 'parent_id': parentId,
      if (label != null) 'label': label,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (sizeFields != null) 'size_fields': sizeFields,
      if (isSystem != null) 'is_system': isSystem,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String?>? parentId,
    Value<String>? label,
    Value<int>? sortOrder,
    Value<String>? sizeFields,
    Value<bool>? isSystem,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      parentId: parentId ?? this.parentId,
      label: label ?? this.label,
      sortOrder: sortOrder ?? this.sortOrder,
      sizeFields: sizeFields ?? this.sizeFields,
      isSystem: isSystem ?? this.isSystem,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (sizeFields.present) {
      map['size_fields'] = Variable<String>(sizeFields.value);
    }
    if (isSystem.present) {
      map['is_system'] = Variable<bool>(isSystem.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('parentId: $parentId, ')
          ..write('label: $label, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('sizeFields: $sizeFields, ')
          ..write('isSystem: $isSystem, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClothingItemImagesTable extends ClothingItemImages
    with TableInfo<$ClothingItemImagesTable, ClothingItemImage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClothingItemImagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('garment'),
  );
  static const VerificationMeta _originalPathMeta = const VerificationMeta(
    'originalPath',
  );
  @override
  late final GeneratedColumn<String> originalPath = GeneratedColumn<String>(
    'original_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _processedPathMeta = const VerificationMeta(
    'processedPath',
  );
  @override
  late final GeneratedColumn<String> processedPath = GeneratedColumn<String>(
    'processed_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maskPathMeta = const VerificationMeta(
    'maskPath',
  );
  @override
  late final GeneratedColumn<String> maskPath = GeneratedColumn<String>(
    'mask_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorJsonMeta = const VerificationMeta(
    'colorJson',
  );
  @override
  late final GeneratedColumn<String> colorJson = GeneratedColumn<String>(
    'color_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _ocrJsonMeta = const VerificationMeta(
    'ocrJson',
  );
  @override
  late final GeneratedColumn<String> ocrJson = GeneratedColumn<String>(
    'ocr_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isPrimaryMeta = const VerificationMeta(
    'isPrimary',
  );
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
    'is_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_primary" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    sortOrder,
    role,
    originalPath,
    processedPath,
    maskPath,
    colorJson,
    ocrJson,
    isPrimary,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clothing_item_images';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClothingItemImage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('original_path')) {
      context.handle(
        _originalPathMeta,
        originalPath.isAcceptableOrUnknown(
          data['original_path']!,
          _originalPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalPathMeta);
    }
    if (data.containsKey('processed_path')) {
      context.handle(
        _processedPathMeta,
        processedPath.isAcceptableOrUnknown(
          data['processed_path']!,
          _processedPathMeta,
        ),
      );
    }
    if (data.containsKey('mask_path')) {
      context.handle(
        _maskPathMeta,
        maskPath.isAcceptableOrUnknown(data['mask_path']!, _maskPathMeta),
      );
    }
    if (data.containsKey('color_json')) {
      context.handle(
        _colorJsonMeta,
        colorJson.isAcceptableOrUnknown(data['color_json']!, _colorJsonMeta),
      );
    }
    if (data.containsKey('ocr_json')) {
      context.handle(
        _ocrJsonMeta,
        ocrJson.isAcceptableOrUnknown(data['ocr_json']!, _ocrJsonMeta),
      );
    }
    if (data.containsKey('is_primary')) {
      context.handle(
        _isPrimaryMeta,
        isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClothingItemImage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClothingItemImage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      originalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_path'],
      )!,
      processedPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}processed_path'],
      ),
      maskPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mask_path'],
      ),
      colorJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_json'],
      )!,
      ocrJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ocr_json'],
      )!,
      isPrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary'],
      )!,
    );
  }

  @override
  $ClothingItemImagesTable createAlias(String alias) {
    return $ClothingItemImagesTable(attachedDatabase, alias);
  }
}

class ClothingItemImage extends DataClass
    implements Insertable<ClothingItemImage> {
  final String id;
  final String itemId;
  final int sortOrder;
  final String role;
  final String originalPath;
  final String? processedPath;
  final String? maskPath;
  final String colorJson;
  final String ocrJson;
  final bool isPrimary;
  const ClothingItemImage({
    required this.id,
    required this.itemId,
    required this.sortOrder,
    required this.role,
    required this.originalPath,
    this.processedPath,
    this.maskPath,
    required this.colorJson,
    required this.ocrJson,
    required this.isPrimary,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['item_id'] = Variable<String>(itemId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['role'] = Variable<String>(role);
    map['original_path'] = Variable<String>(originalPath);
    if (!nullToAbsent || processedPath != null) {
      map['processed_path'] = Variable<String>(processedPath);
    }
    if (!nullToAbsent || maskPath != null) {
      map['mask_path'] = Variable<String>(maskPath);
    }
    map['color_json'] = Variable<String>(colorJson);
    map['ocr_json'] = Variable<String>(ocrJson);
    map['is_primary'] = Variable<bool>(isPrimary);
    return map;
  }

  ClothingItemImagesCompanion toCompanion(bool nullToAbsent) {
    return ClothingItemImagesCompanion(
      id: Value(id),
      itemId: Value(itemId),
      sortOrder: Value(sortOrder),
      role: Value(role),
      originalPath: Value(originalPath),
      processedPath: processedPath == null && nullToAbsent
          ? const Value.absent()
          : Value(processedPath),
      maskPath: maskPath == null && nullToAbsent
          ? const Value.absent()
          : Value(maskPath),
      colorJson: Value(colorJson),
      ocrJson: Value(ocrJson),
      isPrimary: Value(isPrimary),
    );
  }

  factory ClothingItemImage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClothingItemImage(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      role: serializer.fromJson<String>(json['role']),
      originalPath: serializer.fromJson<String>(json['originalPath']),
      processedPath: serializer.fromJson<String?>(json['processedPath']),
      maskPath: serializer.fromJson<String?>(json['maskPath']),
      colorJson: serializer.fromJson<String>(json['colorJson']),
      ocrJson: serializer.fromJson<String>(json['ocrJson']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String>(itemId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'role': serializer.toJson<String>(role),
      'originalPath': serializer.toJson<String>(originalPath),
      'processedPath': serializer.toJson<String?>(processedPath),
      'maskPath': serializer.toJson<String?>(maskPath),
      'colorJson': serializer.toJson<String>(colorJson),
      'ocrJson': serializer.toJson<String>(ocrJson),
      'isPrimary': serializer.toJson<bool>(isPrimary),
    };
  }

  ClothingItemImage copyWith({
    String? id,
    String? itemId,
    int? sortOrder,
    String? role,
    String? originalPath,
    Value<String?> processedPath = const Value.absent(),
    Value<String?> maskPath = const Value.absent(),
    String? colorJson,
    String? ocrJson,
    bool? isPrimary,
  }) => ClothingItemImage(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    sortOrder: sortOrder ?? this.sortOrder,
    role: role ?? this.role,
    originalPath: originalPath ?? this.originalPath,
    processedPath: processedPath.present
        ? processedPath.value
        : this.processedPath,
    maskPath: maskPath.present ? maskPath.value : this.maskPath,
    colorJson: colorJson ?? this.colorJson,
    ocrJson: ocrJson ?? this.ocrJson,
    isPrimary: isPrimary ?? this.isPrimary,
  );
  ClothingItemImage copyWithCompanion(ClothingItemImagesCompanion data) {
    return ClothingItemImage(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      role: data.role.present ? data.role.value : this.role,
      originalPath: data.originalPath.present
          ? data.originalPath.value
          : this.originalPath,
      processedPath: data.processedPath.present
          ? data.processedPath.value
          : this.processedPath,
      maskPath: data.maskPath.present ? data.maskPath.value : this.maskPath,
      colorJson: data.colorJson.present ? data.colorJson.value : this.colorJson,
      ocrJson: data.ocrJson.present ? data.ocrJson.value : this.ocrJson,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClothingItemImage(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('role: $role, ')
          ..write('originalPath: $originalPath, ')
          ..write('processedPath: $processedPath, ')
          ..write('maskPath: $maskPath, ')
          ..write('colorJson: $colorJson, ')
          ..write('ocrJson: $ocrJson, ')
          ..write('isPrimary: $isPrimary')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    sortOrder,
    role,
    originalPath,
    processedPath,
    maskPath,
    colorJson,
    ocrJson,
    isPrimary,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClothingItemImage &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.sortOrder == this.sortOrder &&
          other.role == this.role &&
          other.originalPath == this.originalPath &&
          other.processedPath == this.processedPath &&
          other.maskPath == this.maskPath &&
          other.colorJson == this.colorJson &&
          other.ocrJson == this.ocrJson &&
          other.isPrimary == this.isPrimary);
}

class ClothingItemImagesCompanion extends UpdateCompanion<ClothingItemImage> {
  final Value<String> id;
  final Value<String> itemId;
  final Value<int> sortOrder;
  final Value<String> role;
  final Value<String> originalPath;
  final Value<String?> processedPath;
  final Value<String?> maskPath;
  final Value<String> colorJson;
  final Value<String> ocrJson;
  final Value<bool> isPrimary;
  final Value<int> rowid;
  const ClothingItemImagesCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.role = const Value.absent(),
    this.originalPath = const Value.absent(),
    this.processedPath = const Value.absent(),
    this.maskPath = const Value.absent(),
    this.colorJson = const Value.absent(),
    this.ocrJson = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClothingItemImagesCompanion.insert({
    required String id,
    required String itemId,
    required int sortOrder,
    this.role = const Value.absent(),
    required String originalPath,
    this.processedPath = const Value.absent(),
    this.maskPath = const Value.absent(),
    this.colorJson = const Value.absent(),
    this.ocrJson = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemId = Value(itemId),
       sortOrder = Value(sortOrder),
       originalPath = Value(originalPath);
  static Insertable<ClothingItemImage> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<int>? sortOrder,
    Expression<String>? role,
    Expression<String>? originalPath,
    Expression<String>? processedPath,
    Expression<String>? maskPath,
    Expression<String>? colorJson,
    Expression<String>? ocrJson,
    Expression<bool>? isPrimary,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (role != null) 'role': role,
      if (originalPath != null) 'original_path': originalPath,
      if (processedPath != null) 'processed_path': processedPath,
      if (maskPath != null) 'mask_path': maskPath,
      if (colorJson != null) 'color_json': colorJson,
      if (ocrJson != null) 'ocr_json': ocrJson,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClothingItemImagesCompanion copyWith({
    Value<String>? id,
    Value<String>? itemId,
    Value<int>? sortOrder,
    Value<String>? role,
    Value<String>? originalPath,
    Value<String?>? processedPath,
    Value<String?>? maskPath,
    Value<String>? colorJson,
    Value<String>? ocrJson,
    Value<bool>? isPrimary,
    Value<int>? rowid,
  }) {
    return ClothingItemImagesCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      sortOrder: sortOrder ?? this.sortOrder,
      role: role ?? this.role,
      originalPath: originalPath ?? this.originalPath,
      processedPath: processedPath ?? this.processedPath,
      maskPath: maskPath ?? this.maskPath,
      colorJson: colorJson ?? this.colorJson,
      ocrJson: ocrJson ?? this.ocrJson,
      isPrimary: isPrimary ?? this.isPrimary,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (originalPath.present) {
      map['original_path'] = Variable<String>(originalPath.value);
    }
    if (processedPath.present) {
      map['processed_path'] = Variable<String>(processedPath.value);
    }
    if (maskPath.present) {
      map['mask_path'] = Variable<String>(maskPath.value);
    }
    if (colorJson.present) {
      map['color_json'] = Variable<String>(colorJson.value);
    }
    if (ocrJson.present) {
      map['ocr_json'] = Variable<String>(ocrJson.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClothingItemImagesCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('role: $role, ')
          ..write('originalPath: $originalPath, ')
          ..write('processedPath: $processedPath, ')
          ..write('maskPath: $maskPath, ')
          ..write('colorJson: $colorJson, ')
          ..write('ocrJson: $ocrJson, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutfitItemsTable extends OutfitItems
    with TableInfo<$OutfitItemsTable, OutfitItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutfitItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _outfitIdMeta = const VerificationMeta(
    'outfitId',
  );
  @override
  late final GeneratedColumn<String> outfitId = GeneratedColumn<String>(
    'outfit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clothingItemIdMeta = const VerificationMeta(
    'clothingItemId',
  );
  @override
  late final GeneratedColumn<String> clothingItemId = GeneratedColumn<String>(
    'clothing_item_id',
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
  List<GeneratedColumn> get $columns => [outfitId, clothingItemId, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outfit_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutfitItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('outfit_id')) {
      context.handle(
        _outfitIdMeta,
        outfitId.isAcceptableOrUnknown(data['outfit_id']!, _outfitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_outfitIdMeta);
    }
    if (data.containsKey('clothing_item_id')) {
      context.handle(
        _clothingItemIdMeta,
        clothingItemId.isAcceptableOrUnknown(
          data['clothing_item_id']!,
          _clothingItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clothingItemIdMeta);
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
  Set<GeneratedColumn> get $primaryKey => {outfitId, clothingItemId};
  @override
  OutfitItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutfitItem(
      outfitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outfit_id'],
      )!,
      clothingItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clothing_item_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $OutfitItemsTable createAlias(String alias) {
    return $OutfitItemsTable(attachedDatabase, alias);
  }
}

class OutfitItem extends DataClass implements Insertable<OutfitItem> {
  final String outfitId;
  final String clothingItemId;
  final int sortOrder;
  const OutfitItem({
    required this.outfitId,
    required this.clothingItemId,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['outfit_id'] = Variable<String>(outfitId);
    map['clothing_item_id'] = Variable<String>(clothingItemId);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  OutfitItemsCompanion toCompanion(bool nullToAbsent) {
    return OutfitItemsCompanion(
      outfitId: Value(outfitId),
      clothingItemId: Value(clothingItemId),
      sortOrder: Value(sortOrder),
    );
  }

  factory OutfitItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutfitItem(
      outfitId: serializer.fromJson<String>(json['outfitId']),
      clothingItemId: serializer.fromJson<String>(json['clothingItemId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'outfitId': serializer.toJson<String>(outfitId),
      'clothingItemId': serializer.toJson<String>(clothingItemId),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  OutfitItem copyWith({
    String? outfitId,
    String? clothingItemId,
    int? sortOrder,
  }) => OutfitItem(
    outfitId: outfitId ?? this.outfitId,
    clothingItemId: clothingItemId ?? this.clothingItemId,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  OutfitItem copyWithCompanion(OutfitItemsCompanion data) {
    return OutfitItem(
      outfitId: data.outfitId.present ? data.outfitId.value : this.outfitId,
      clothingItemId: data.clothingItemId.present
          ? data.clothingItemId.value
          : this.clothingItemId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutfitItem(')
          ..write('outfitId: $outfitId, ')
          ..write('clothingItemId: $clothingItemId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(outfitId, clothingItemId, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutfitItem &&
          other.outfitId == this.outfitId &&
          other.clothingItemId == this.clothingItemId &&
          other.sortOrder == this.sortOrder);
}

class OutfitItemsCompanion extends UpdateCompanion<OutfitItem> {
  final Value<String> outfitId;
  final Value<String> clothingItemId;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const OutfitItemsCompanion({
    this.outfitId = const Value.absent(),
    this.clothingItemId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutfitItemsCompanion.insert({
    required String outfitId,
    required String clothingItemId,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : outfitId = Value(outfitId),
       clothingItemId = Value(clothingItemId);
  static Insertable<OutfitItem> custom({
    Expression<String>? outfitId,
    Expression<String>? clothingItemId,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (outfitId != null) 'outfit_id': outfitId,
      if (clothingItemId != null) 'clothing_item_id': clothingItemId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutfitItemsCompanion copyWith({
    Value<String>? outfitId,
    Value<String>? clothingItemId,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return OutfitItemsCompanion(
      outfitId: outfitId ?? this.outfitId,
      clothingItemId: clothingItemId ?? this.clothingItemId,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (outfitId.present) {
      map['outfit_id'] = Variable<String>(outfitId.value);
    }
    if (clothingItemId.present) {
      map['clothing_item_id'] = Variable<String>(clothingItemId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutfitItemsCompanion(')
          ..write('outfitId: $outfitId, ')
          ..write('clothingItemId: $clothingItemId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DayEventsTable extends DayEvents
    with TableInfo<$DayEventsTable, DayEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
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
  List<GeneratedColumn> get $columns => [id, day, title, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
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
  DayEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $DayEventsTable createAlias(String alias) {
    return $DayEventsTable(attachedDatabase, alias);
  }
}

class DayEvent extends DataClass implements Insertable<DayEvent> {
  final String id;
  final String day;
  final String title;
  final int sortOrder;
  const DayEvent({
    required this.id,
    required this.day,
    required this.title,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['day'] = Variable<String>(day);
    map['title'] = Variable<String>(title);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  DayEventsCompanion toCompanion(bool nullToAbsent) {
    return DayEventsCompanion(
      id: Value(id),
      day: Value(day),
      title: Value(title),
      sortOrder: Value(sortOrder),
    );
  }

  factory DayEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayEvent(
      id: serializer.fromJson<String>(json['id']),
      day: serializer.fromJson<String>(json['day']),
      title: serializer.fromJson<String>(json['title']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'day': serializer.toJson<String>(day),
      'title': serializer.toJson<String>(title),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  DayEvent copyWith({String? id, String? day, String? title, int? sortOrder}) =>
      DayEvent(
        id: id ?? this.id,
        day: day ?? this.day,
        title: title ?? this.title,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  DayEvent copyWithCompanion(DayEventsCompanion data) {
    return DayEvent(
      id: data.id.present ? data.id.value : this.id,
      day: data.day.present ? data.day.value : this.day,
      title: data.title.present ? data.title.value : this.title,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayEvent(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('title: $title, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, day, title, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayEvent &&
          other.id == this.id &&
          other.day == this.day &&
          other.title == this.title &&
          other.sortOrder == this.sortOrder);
}

class DayEventsCompanion extends UpdateCompanion<DayEvent> {
  final Value<String> id;
  final Value<String> day;
  final Value<String> title;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const DayEventsCompanion({
    this.id = const Value.absent(),
    this.day = const Value.absent(),
    this.title = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DayEventsCompanion.insert({
    required String id,
    required String day,
    required String title,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       day = Value(day),
       title = Value(title);
  static Insertable<DayEvent> custom({
    Expression<String>? id,
    Expression<String>? day,
    Expression<String>? title,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (day != null) 'day': day,
      if (title != null) 'title': title,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DayEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? day,
    Value<String>? title,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return DayEventsCompanion(
      id: id ?? this.id,
      day: day ?? this.day,
      title: title ?? this.title,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayEventsCompanion(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('title: $title, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DayOutfitsTable extends DayOutfits
    with TableInfo<$DayOutfitsTable, DayOutfit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayOutfitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outfitIdMeta = const VerificationMeta(
    'outfitId',
  );
  @override
  late final GeneratedColumn<String> outfitId = GeneratedColumn<String>(
    'outfit_id',
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
  List<GeneratedColumn> get $columns => [day, outfitId, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_outfits';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayOutfit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('outfit_id')) {
      context.handle(
        _outfitIdMeta,
        outfitId.isAcceptableOrUnknown(data['outfit_id']!, _outfitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_outfitIdMeta);
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
  Set<GeneratedColumn> get $primaryKey => {day, outfitId};
  @override
  DayOutfit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayOutfit(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      outfitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outfit_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $DayOutfitsTable createAlias(String alias) {
    return $DayOutfitsTable(attachedDatabase, alias);
  }
}

class DayOutfit extends DataClass implements Insertable<DayOutfit> {
  final String day;
  final String outfitId;
  final int sortOrder;
  const DayOutfit({
    required this.day,
    required this.outfitId,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<String>(day);
    map['outfit_id'] = Variable<String>(outfitId);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  DayOutfitsCompanion toCompanion(bool nullToAbsent) {
    return DayOutfitsCompanion(
      day: Value(day),
      outfitId: Value(outfitId),
      sortOrder: Value(sortOrder),
    );
  }

  factory DayOutfit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayOutfit(
      day: serializer.fromJson<String>(json['day']),
      outfitId: serializer.fromJson<String>(json['outfitId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<String>(day),
      'outfitId': serializer.toJson<String>(outfitId),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  DayOutfit copyWith({String? day, String? outfitId, int? sortOrder}) =>
      DayOutfit(
        day: day ?? this.day,
        outfitId: outfitId ?? this.outfitId,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  DayOutfit copyWithCompanion(DayOutfitsCompanion data) {
    return DayOutfit(
      day: data.day.present ? data.day.value : this.day,
      outfitId: data.outfitId.present ? data.outfitId.value : this.outfitId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayOutfit(')
          ..write('day: $day, ')
          ..write('outfitId: $outfitId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(day, outfitId, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayOutfit &&
          other.day == this.day &&
          other.outfitId == this.outfitId &&
          other.sortOrder == this.sortOrder);
}

class DayOutfitsCompanion extends UpdateCompanion<DayOutfit> {
  final Value<String> day;
  final Value<String> outfitId;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const DayOutfitsCompanion({
    this.day = const Value.absent(),
    this.outfitId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DayOutfitsCompanion.insert({
    required String day,
    required String outfitId,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : day = Value(day),
       outfitId = Value(outfitId);
  static Insertable<DayOutfit> custom({
    Expression<String>? day,
    Expression<String>? outfitId,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (outfitId != null) 'outfit_id': outfitId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DayOutfitsCompanion copyWith({
    Value<String>? day,
    Value<String>? outfitId,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return DayOutfitsCompanion(
      day: day ?? this.day,
      outfitId: outfitId ?? this.outfitId,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (outfitId.present) {
      map['outfit_id'] = Variable<String>(outfitId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayOutfitsCompanion(')
          ..write('day: $day, ')
          ..write('outfitId: $outfitId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ClothingItemsTable clothingItems = $ClothingItemsTable(this);
  late final $OutfitsTable outfits = $OutfitsTable(this);
  late final $CategoryCoversTable categoryCovers = $CategoryCoversTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ClothingItemImagesTable clothingItemImages =
      $ClothingItemImagesTable(this);
  late final $OutfitItemsTable outfitItems = $OutfitItemsTable(this);
  late final $DayEventsTable dayEvents = $DayEventsTable(this);
  late final $DayOutfitsTable dayOutfits = $DayOutfitsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    clothingItems,
    outfits,
    categoryCovers,
    categories,
    clothingItemImages,
    outfitItems,
    dayEvents,
    dayOutfits,
  ];
}

typedef $$ClothingItemsTableCreateCompanionBuilder =
    ClothingItemsCompanion Function({
      required String id,
      required String categoryId,
      Value<String?> imagePath,
      Value<String> type,
      Value<String> style,
      Value<String> color,
      Value<String> season,
      Value<String> fabric,
      Value<String> brand,
      Value<double?> price,
      Value<String> measurements,
      Value<DateTime?> purchasedAt,
      Value<String> purchaseInfo,
      Value<String> location,
      Value<String> tags,
      Value<String> note,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ClothingItemsTableUpdateCompanionBuilder =
    ClothingItemsCompanion Function({
      Value<String> id,
      Value<String> categoryId,
      Value<String?> imagePath,
      Value<String> type,
      Value<String> style,
      Value<String> color,
      Value<String> season,
      Value<String> fabric,
      Value<String> brand,
      Value<double?> price,
      Value<String> measurements,
      Value<DateTime?> purchasedAt,
      Value<String> purchaseInfo,
      Value<String> location,
      Value<String> tags,
      Value<String> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ClothingItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ClothingItemsTable> {
  $$ClothingItemsTableFilterComposer({
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

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get season => $composableBuilder(
    column: $table.season,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fabric => $composableBuilder(
    column: $table.fabric,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get measurements => $composableBuilder(
    column: $table.measurements,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get purchasedAt => $composableBuilder(
    column: $table.purchasedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purchaseInfo => $composableBuilder(
    column: $table.purchaseInfo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClothingItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClothingItemsTable> {
  $$ClothingItemsTableOrderingComposer({
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

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get season => $composableBuilder(
    column: $table.season,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fabric => $composableBuilder(
    column: $table.fabric,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get measurements => $composableBuilder(
    column: $table.measurements,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get purchasedAt => $composableBuilder(
    column: $table.purchasedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purchaseInfo => $composableBuilder(
    column: $table.purchaseInfo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClothingItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClothingItemsTable> {
  $$ClothingItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get style =>
      $composableBuilder(column: $table.style, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get season =>
      $composableBuilder(column: $table.season, builder: (column) => column);

  GeneratedColumn<String> get fabric =>
      $composableBuilder(column: $table.fabric, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get measurements => $composableBuilder(
    column: $table.measurements,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get purchasedAt => $composableBuilder(
    column: $table.purchasedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get purchaseInfo => $composableBuilder(
    column: $table.purchaseInfo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ClothingItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClothingItemsTable,
          ClothingItem,
          $$ClothingItemsTableFilterComposer,
          $$ClothingItemsTableOrderingComposer,
          $$ClothingItemsTableAnnotationComposer,
          $$ClothingItemsTableCreateCompanionBuilder,
          $$ClothingItemsTableUpdateCompanionBuilder,
          (
            ClothingItem,
            BaseReferences<_$AppDatabase, $ClothingItemsTable, ClothingItem>,
          ),
          ClothingItem,
          PrefetchHooks Function()
        > {
  $$ClothingItemsTableTableManager(_$AppDatabase db, $ClothingItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClothingItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClothingItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClothingItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> style = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<String> season = const Value.absent(),
                Value<String> fabric = const Value.absent(),
                Value<String> brand = const Value.absent(),
                Value<double?> price = const Value.absent(),
                Value<String> measurements = const Value.absent(),
                Value<DateTime?> purchasedAt = const Value.absent(),
                Value<String> purchaseInfo = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClothingItemsCompanion(
                id: id,
                categoryId: categoryId,
                imagePath: imagePath,
                type: type,
                style: style,
                color: color,
                season: season,
                fabric: fabric,
                brand: brand,
                price: price,
                measurements: measurements,
                purchasedAt: purchasedAt,
                purchaseInfo: purchaseInfo,
                location: location,
                tags: tags,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String categoryId,
                Value<String?> imagePath = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> style = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<String> season = const Value.absent(),
                Value<String> fabric = const Value.absent(),
                Value<String> brand = const Value.absent(),
                Value<double?> price = const Value.absent(),
                Value<String> measurements = const Value.absent(),
                Value<DateTime?> purchasedAt = const Value.absent(),
                Value<String> purchaseInfo = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String> note = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ClothingItemsCompanion.insert(
                id: id,
                categoryId: categoryId,
                imagePath: imagePath,
                type: type,
                style: style,
                color: color,
                season: season,
                fabric: fabric,
                brand: brand,
                price: price,
                measurements: measurements,
                purchasedAt: purchasedAt,
                purchaseInfo: purchaseInfo,
                location: location,
                tags: tags,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ClothingItemsTable, ClothingItem>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ClothingItemsTable,
                    ClothingItem
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClothingItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClothingItemsTable,
      ClothingItem,
      $$ClothingItemsTableFilterComposer,
      $$ClothingItemsTableOrderingComposer,
      $$ClothingItemsTableAnnotationComposer,
      $$ClothingItemsTableCreateCompanionBuilder,
      $$ClothingItemsTableUpdateCompanionBuilder,
      (
        ClothingItem,
        BaseReferences<_$AppDatabase, $ClothingItemsTable, ClothingItem>,
      ),
      ClothingItem,
      PrefetchHooks Function()
    >;
typedef $$OutfitsTableCreateCompanionBuilder = OutfitsCompanion Function({
  required String id,
  required String categoryId,
  Value<String?> imagePath,
  Value<String?> sourceImagePath,
  Value<String> coverMode,
  Value<String?> collageLayout,
  Value<String> name,
  Value<String> season,
  Value<String> note,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$OutfitsTableUpdateCompanionBuilder = OutfitsCompanion Function({
  Value<String> id,
  Value<String> categoryId,
  Value<String?> imagePath,
  Value<String?> sourceImagePath,
  Value<String> coverMode,
  Value<String?> collageLayout,
  Value<String> name,
  Value<String> season,
  Value<String> note,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$OutfitsTableFilterComposer
    extends Composer<_$AppDatabase, $OutfitsTable> {
  $$OutfitsTableFilterComposer({
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

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceImagePath => $composableBuilder(
    column: $table.sourceImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverMode => $composableBuilder(
    column: $table.coverMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collageLayout => $composableBuilder(
    column: $table.collageLayout,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get season => $composableBuilder(
    column: $table.season,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutfitsTableOrderingComposer
    extends Composer<_$AppDatabase, $OutfitsTable> {
  $$OutfitsTableOrderingComposer({
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

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceImagePath => $composableBuilder(
    column: $table.sourceImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverMode => $composableBuilder(
    column: $table.coverMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collageLayout => $composableBuilder(
    column: $table.collageLayout,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get season => $composableBuilder(
    column: $table.season,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutfitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutfitsTable> {
  $$OutfitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get sourceImagePath => $composableBuilder(
    column: $table.sourceImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverMode =>
      $composableBuilder(column: $table.coverMode, builder: (column) => column);

  GeneratedColumn<String> get collageLayout => $composableBuilder(
    column: $table.collageLayout,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get season =>
      $composableBuilder(column: $table.season, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OutfitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutfitsTable,
          Outfit,
          $$OutfitsTableFilterComposer,
          $$OutfitsTableOrderingComposer,
          $$OutfitsTableAnnotationComposer,
          $$OutfitsTableCreateCompanionBuilder,
          $$OutfitsTableUpdateCompanionBuilder,
          (Outfit, BaseReferences<_$AppDatabase, $OutfitsTable, Outfit>),
          Outfit,
          PrefetchHooks Function()
        > {
  $$OutfitsTableTableManager(_$AppDatabase db, $OutfitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutfitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutfitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutfitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String?> sourceImagePath = const Value.absent(),
                Value<String> coverMode = const Value.absent(),
                Value<String?> collageLayout = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> season = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutfitsCompanion(
                id: id,
                categoryId: categoryId,
                imagePath: imagePath,
                sourceImagePath: sourceImagePath,
                coverMode: coverMode,
                collageLayout: collageLayout,
                name: name,
                season: season,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String categoryId,
                Value<String?> imagePath = const Value.absent(),
                Value<String?> sourceImagePath = const Value.absent(),
                Value<String> coverMode = const Value.absent(),
                Value<String?> collageLayout = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> season = const Value.absent(),
                Value<String> note = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => OutfitsCompanion.insert(
                id: id,
                categoryId: categoryId,
                imagePath: imagePath,
                sourceImagePath: sourceImagePath,
                coverMode: coverMode,
                collageLayout: collageLayout,
                name: name,
                season: season,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutfitsTable, Outfit>(table),
                  BaseReferences<_$AppDatabase, $OutfitsTable, Outfit>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutfitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutfitsTable,
      Outfit,
      $$OutfitsTableFilterComposer,
      $$OutfitsTableOrderingComposer,
      $$OutfitsTableAnnotationComposer,
      $$OutfitsTableCreateCompanionBuilder,
      $$OutfitsTableUpdateCompanionBuilder,
      (Outfit, BaseReferences<_$AppDatabase, $OutfitsTable, Outfit>),
      Outfit,
      PrefetchHooks Function()
    >;
typedef $$CategoryCoversTableCreateCompanionBuilder =
    CategoryCoversCompanion Function({
      required String kind,
      required String categoryId,
      Value<String?> coverItemId,
      Value<int> rowid,
    });
typedef $$CategoryCoversTableUpdateCompanionBuilder =
    CategoryCoversCompanion Function({
      Value<String> kind,
      Value<String> categoryId,
      Value<String?> coverItemId,
      Value<int> rowid,
    });

class $$CategoryCoversTableFilterComposer
    extends Composer<_$AppDatabase, $CategoryCoversTable> {
  $$CategoryCoversTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverItemId => $composableBuilder(
    column: $table.coverItemId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoryCoversTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoryCoversTable> {
  $$CategoryCoversTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverItemId => $composableBuilder(
    column: $table.coverItemId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoryCoversTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoryCoversTable> {
  $$CategoryCoversTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverItemId => $composableBuilder(
    column: $table.coverItemId,
    builder: (column) => column,
  );
}

class $$CategoryCoversTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoryCoversTable,
          CategoryCover,
          $$CategoryCoversTableFilterComposer,
          $$CategoryCoversTableOrderingComposer,
          $$CategoryCoversTableAnnotationComposer,
          $$CategoryCoversTableCreateCompanionBuilder,
          $$CategoryCoversTableUpdateCompanionBuilder,
          (
            CategoryCover,
            BaseReferences<_$AppDatabase, $CategoryCoversTable, CategoryCover>,
          ),
          CategoryCover,
          PrefetchHooks Function()
        > {
  $$CategoryCoversTableTableManager(
    _$AppDatabase db,
    $CategoryCoversTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryCoversTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoryCoversTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoryCoversTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> kind = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String?> coverItemId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoryCoversCompanion(
                kind: kind,
                categoryId: categoryId,
                coverItemId: coverItemId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String kind,
                required String categoryId,
                Value<String?> coverItemId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoryCoversCompanion.insert(
                kind: kind,
                categoryId: categoryId,
                coverItemId: coverItemId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoryCoversTable, CategoryCover>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CategoryCoversTable,
                    CategoryCover
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoryCoversTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoryCoversTable,
      CategoryCover,
      $$CategoryCoversTableFilterComposer,
      $$CategoryCoversTableOrderingComposer,
      $$CategoryCoversTableAnnotationComposer,
      $$CategoryCoversTableCreateCompanionBuilder,
      $$CategoryCoversTableUpdateCompanionBuilder,
      (
        CategoryCover,
        BaseReferences<_$AppDatabase, $CategoryCoversTable, CategoryCover>,
      ),
      CategoryCover,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  required String kind,
  Value<String?> parentId,
  required String label,
  required int sortOrder,
  Value<String> sizeFields,
  Value<bool> isSystem,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String> kind,
  Value<String?> parentId,
  Value<String> label,
  Value<int> sortOrder,
  Value<String> sizeFields,
  Value<bool> isSystem,
  Value<int> rowid,
});

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sizeFields => $composableBuilder(
    column: $table.sizeFields,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sizeFields => $composableBuilder(
    column: $table.sizeFields,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get sizeFields => $composableBuilder(
    column: $table.sizeFields,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSystem =>
      $composableBuilder(column: $table.isSystem, builder: (column) => column);
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
          Category,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> sizeFields = const Value.absent(),
                Value<bool> isSystem = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                kind: kind,
                parentId: parentId,
                label: label,
                sortOrder: sortOrder,
                sizeFields: sizeFields,
                isSystem: isSystem,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                Value<String?> parentId = const Value.absent(),
                required String label,
                required int sortOrder,
                Value<String> sizeFields = const Value.absent(),
                Value<bool> isSystem = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                kind: kind,
                parentId: parentId,
                label: label,
                sortOrder: sortOrder,
                sizeFields: sizeFields,
                isSystem: isSystem,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, Category>(table),
                  BaseReferences<_$AppDatabase, $CategoriesTable, Category>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
      Category,
      PrefetchHooks Function()
    >;
typedef $$ClothingItemImagesTableCreateCompanionBuilder =
    ClothingItemImagesCompanion Function({
      required String id,
      required String itemId,
      required int sortOrder,
      Value<String> role,
      required String originalPath,
      Value<String?> processedPath,
      Value<String?> maskPath,
      Value<String> colorJson,
      Value<String> ocrJson,
      Value<bool> isPrimary,
      Value<int> rowid,
    });
typedef $$ClothingItemImagesTableUpdateCompanionBuilder =
    ClothingItemImagesCompanion Function({
      Value<String> id,
      Value<String> itemId,
      Value<int> sortOrder,
      Value<String> role,
      Value<String> originalPath,
      Value<String?> processedPath,
      Value<String?> maskPath,
      Value<String> colorJson,
      Value<String> ocrJson,
      Value<bool> isPrimary,
      Value<int> rowid,
    });

class $$ClothingItemImagesTableFilterComposer
    extends Composer<_$AppDatabase, $ClothingItemImagesTable> {
  $$ClothingItemImagesTableFilterComposer({
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

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get processedPath => $composableBuilder(
    column: $table.processedPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get maskPath => $composableBuilder(
    column: $table.maskPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorJson => $composableBuilder(
    column: $table.colorJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ocrJson => $composableBuilder(
    column: $table.ocrJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClothingItemImagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ClothingItemImagesTable> {
  $$ClothingItemImagesTableOrderingComposer({
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

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get processedPath => $composableBuilder(
    column: $table.processedPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get maskPath => $composableBuilder(
    column: $table.maskPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorJson => $composableBuilder(
    column: $table.colorJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ocrJson => $composableBuilder(
    column: $table.ocrJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClothingItemImagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClothingItemImagesTable> {
  $$ClothingItemImagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get processedPath => $composableBuilder(
    column: $table.processedPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get maskPath =>
      $composableBuilder(column: $table.maskPath, builder: (column) => column);

  GeneratedColumn<String> get colorJson =>
      $composableBuilder(column: $table.colorJson, builder: (column) => column);

  GeneratedColumn<String> get ocrJson =>
      $composableBuilder(column: $table.ocrJson, builder: (column) => column);

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);
}

class $$ClothingItemImagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClothingItemImagesTable,
          ClothingItemImage,
          $$ClothingItemImagesTableFilterComposer,
          $$ClothingItemImagesTableOrderingComposer,
          $$ClothingItemImagesTableAnnotationComposer,
          $$ClothingItemImagesTableCreateCompanionBuilder,
          $$ClothingItemImagesTableUpdateCompanionBuilder,
          (
            ClothingItemImage,
            BaseReferences<
              _$AppDatabase,
              $ClothingItemImagesTable,
              ClothingItemImage
            >,
          ),
          ClothingItemImage,
          PrefetchHooks Function()
        > {
  $$ClothingItemImagesTableTableManager(
    _$AppDatabase db,
    $ClothingItemImagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClothingItemImagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClothingItemImagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClothingItemImagesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> originalPath = const Value.absent(),
                Value<String?> processedPath = const Value.absent(),
                Value<String?> maskPath = const Value.absent(),
                Value<String> colorJson = const Value.absent(),
                Value<String> ocrJson = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClothingItemImagesCompanion(
                id: id,
                itemId: itemId,
                sortOrder: sortOrder,
                role: role,
                originalPath: originalPath,
                processedPath: processedPath,
                maskPath: maskPath,
                colorJson: colorJson,
                ocrJson: ocrJson,
                isPrimary: isPrimary,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itemId,
                required int sortOrder,
                Value<String> role = const Value.absent(),
                required String originalPath,
                Value<String?> processedPath = const Value.absent(),
                Value<String?> maskPath = const Value.absent(),
                Value<String> colorJson = const Value.absent(),
                Value<String> ocrJson = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClothingItemImagesCompanion.insert(
                id: id,
                itemId: itemId,
                sortOrder: sortOrder,
                role: role,
                originalPath: originalPath,
                processedPath: processedPath,
                maskPath: maskPath,
                colorJson: colorJson,
                ocrJson: ocrJson,
                isPrimary: isPrimary,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ClothingItemImagesTable, ClothingItemImage>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $ClothingItemImagesTable,
                    ClothingItemImage
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClothingItemImagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClothingItemImagesTable,
      ClothingItemImage,
      $$ClothingItemImagesTableFilterComposer,
      $$ClothingItemImagesTableOrderingComposer,
      $$ClothingItemImagesTableAnnotationComposer,
      $$ClothingItemImagesTableCreateCompanionBuilder,
      $$ClothingItemImagesTableUpdateCompanionBuilder,
      (
        ClothingItemImage,
        BaseReferences<
          _$AppDatabase,
          $ClothingItemImagesTable,
          ClothingItemImage
        >,
      ),
      ClothingItemImage,
      PrefetchHooks Function()
    >;
typedef $$OutfitItemsTableCreateCompanionBuilder =
    OutfitItemsCompanion Function({
      required String outfitId,
      required String clothingItemId,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$OutfitItemsTableUpdateCompanionBuilder =
    OutfitItemsCompanion Function({
      Value<String> outfitId,
      Value<String> clothingItemId,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$OutfitItemsTableFilterComposer
    extends Composer<_$AppDatabase, $OutfitItemsTable> {
  $$OutfitItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get outfitId => $composableBuilder(
    column: $table.outfitId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clothingItemId => $composableBuilder(
    column: $table.clothingItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutfitItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $OutfitItemsTable> {
  $$OutfitItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get outfitId => $composableBuilder(
    column: $table.outfitId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clothingItemId => $composableBuilder(
    column: $table.clothingItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutfitItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutfitItemsTable> {
  $$OutfitItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get outfitId =>
      $composableBuilder(column: $table.outfitId, builder: (column) => column);

  GeneratedColumn<String> get clothingItemId => $composableBuilder(
    column: $table.clothingItemId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$OutfitItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutfitItemsTable,
          OutfitItem,
          $$OutfitItemsTableFilterComposer,
          $$OutfitItemsTableOrderingComposer,
          $$OutfitItemsTableAnnotationComposer,
          $$OutfitItemsTableCreateCompanionBuilder,
          $$OutfitItemsTableUpdateCompanionBuilder,
          (
            OutfitItem,
            BaseReferences<_$AppDatabase, $OutfitItemsTable, OutfitItem>,
          ),
          OutfitItem,
          PrefetchHooks Function()
        > {
  $$OutfitItemsTableTableManager(_$AppDatabase db, $OutfitItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutfitItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutfitItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutfitItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> outfitId = const Value.absent(),
                Value<String> clothingItemId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutfitItemsCompanion(
                outfitId: outfitId,
                clothingItemId: clothingItemId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String outfitId,
                required String clothingItemId,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutfitItemsCompanion.insert(
                outfitId: outfitId,
                clothingItemId: clothingItemId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutfitItemsTable, OutfitItem>(table),
                  BaseReferences<_$AppDatabase, $OutfitItemsTable, OutfitItem>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutfitItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutfitItemsTable,
      OutfitItem,
      $$OutfitItemsTableFilterComposer,
      $$OutfitItemsTableOrderingComposer,
      $$OutfitItemsTableAnnotationComposer,
      $$OutfitItemsTableCreateCompanionBuilder,
      $$OutfitItemsTableUpdateCompanionBuilder,
      (
        OutfitItem,
        BaseReferences<_$AppDatabase, $OutfitItemsTable, OutfitItem>,
      ),
      OutfitItem,
      PrefetchHooks Function()
    >;
typedef $$DayEventsTableCreateCompanionBuilder = DayEventsCompanion Function({
  required String id,
  required String day,
  required String title,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$DayEventsTableUpdateCompanionBuilder = DayEventsCompanion Function({
  Value<String> id,
  Value<String> day,
  Value<String> title,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$DayEventsTableFilterComposer
    extends Composer<_$AppDatabase, $DayEventsTable> {
  $$DayEventsTableFilterComposer({
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

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DayEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $DayEventsTable> {
  $$DayEventsTableOrderingComposer({
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

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DayEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DayEventsTable> {
  $$DayEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$DayEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DayEventsTable,
          DayEvent,
          $$DayEventsTableFilterComposer,
          $$DayEventsTableOrderingComposer,
          $$DayEventsTableAnnotationComposer,
          $$DayEventsTableCreateCompanionBuilder,
          $$DayEventsTableUpdateCompanionBuilder,
          (DayEvent, BaseReferences<_$AppDatabase, $DayEventsTable, DayEvent>),
          DayEvent,
          PrefetchHooks Function()
        > {
  $$DayEventsTableTableManager(_$AppDatabase db, $DayEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DayEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayEventsCompanion(
                id: id,
                day: day,
                title: title,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String day,
                required String title,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayEventsCompanion.insert(
                id: id,
                day: day,
                title: title,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DayEventsTable, DayEvent>(table),
                  BaseReferences<_$AppDatabase, $DayEventsTable, DayEvent>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DayEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DayEventsTable,
      DayEvent,
      $$DayEventsTableFilterComposer,
      $$DayEventsTableOrderingComposer,
      $$DayEventsTableAnnotationComposer,
      $$DayEventsTableCreateCompanionBuilder,
      $$DayEventsTableUpdateCompanionBuilder,
      (DayEvent, BaseReferences<_$AppDatabase, $DayEventsTable, DayEvent>),
      DayEvent,
      PrefetchHooks Function()
    >;
typedef $$DayOutfitsTableCreateCompanionBuilder = DayOutfitsCompanion Function({
  required String day,
  required String outfitId,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$DayOutfitsTableUpdateCompanionBuilder = DayOutfitsCompanion Function({
  Value<String> day,
  Value<String> outfitId,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$DayOutfitsTableFilterComposer
    extends Composer<_$AppDatabase, $DayOutfitsTable> {
  $$DayOutfitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outfitId => $composableBuilder(
    column: $table.outfitId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DayOutfitsTableOrderingComposer
    extends Composer<_$AppDatabase, $DayOutfitsTable> {
  $$DayOutfitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outfitId => $composableBuilder(
    column: $table.outfitId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DayOutfitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DayOutfitsTable> {
  $$DayOutfitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get outfitId =>
      $composableBuilder(column: $table.outfitId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$DayOutfitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DayOutfitsTable,
          DayOutfit,
          $$DayOutfitsTableFilterComposer,
          $$DayOutfitsTableOrderingComposer,
          $$DayOutfitsTableAnnotationComposer,
          $$DayOutfitsTableCreateCompanionBuilder,
          $$DayOutfitsTableUpdateCompanionBuilder,
          (
            DayOutfit,
            BaseReferences<_$AppDatabase, $DayOutfitsTable, DayOutfit>,
          ),
          DayOutfit,
          PrefetchHooks Function()
        > {
  $$DayOutfitsTableTableManager(_$AppDatabase db, $DayOutfitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayOutfitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayOutfitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DayOutfitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> day = const Value.absent(),
                Value<String> outfitId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayOutfitsCompanion(
                day: day,
                outfitId: outfitId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String day,
                required String outfitId,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayOutfitsCompanion.insert(
                day: day,
                outfitId: outfitId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DayOutfitsTable, DayOutfit>(table),
                  BaseReferences<_$AppDatabase, $DayOutfitsTable, DayOutfit>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DayOutfitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DayOutfitsTable,
      DayOutfit,
      $$DayOutfitsTableFilterComposer,
      $$DayOutfitsTableOrderingComposer,
      $$DayOutfitsTableAnnotationComposer,
      $$DayOutfitsTableCreateCompanionBuilder,
      $$DayOutfitsTableUpdateCompanionBuilder,
      (DayOutfit, BaseReferences<_$AppDatabase, $DayOutfitsTable, DayOutfit>),
      DayOutfit,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ClothingItemsTableTableManager get clothingItems =>
      $$ClothingItemsTableTableManager(_db, _db.clothingItems);
  $$OutfitsTableTableManager get outfits =>
      $$OutfitsTableTableManager(_db, _db.outfits);
  $$CategoryCoversTableTableManager get categoryCovers =>
      $$CategoryCoversTableTableManager(_db, _db.categoryCovers);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ClothingItemImagesTableTableManager get clothingItemImages =>
      $$ClothingItemImagesTableTableManager(_db, _db.clothingItemImages);
  $$OutfitItemsTableTableManager get outfitItems =>
      $$OutfitItemsTableTableManager(_db, _db.outfitItems);
  $$DayEventsTableTableManager get dayEvents =>
      $$DayEventsTableTableManager(_db, _db.dayEvents);
  $$DayOutfitsTableTableManager get dayOutfits =>
      $$DayOutfitsTableTableManager(_db, _db.dayOutfits);
}
