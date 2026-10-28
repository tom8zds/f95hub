// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_database.dart';

// ignore_for_file: type=lint
class $GamesTable extends Games with TableInfo<$GamesTable, GameRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GamesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _threadIdMeta = const VerificationMeta(
    'threadId',
  );
  @override
  late final GeneratedColumn<int> threadId = GeneratedColumn<int>(
    'thread_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _creatorMeta = const VerificationMeta(
    'creator',
  );
  @override
  late final GeneratedColumn<String> creator = GeneratedColumn<String>(
    'creator',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _latestVersionMeta = const VerificationMeta(
    'latestVersion',
  );
  @override
  late final GeneratedColumn<String> latestVersion = GeneratedColumn<String>(
    'latest_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _coverMeta = const VerificationMeta('cover');
  @override
  late final GeneratedColumn<String> cover = GeneratedColumn<String>(
    'cover',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _screensMeta = const VerificationMeta(
    'screens',
  );
  @override
  late final GeneratedColumn<String> screens = GeneratedColumn<String>(
    'screens',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _tagIdsMeta = const VerificationMeta('tagIds');
  @override
  late final GeneratedColumn<String> tagIds = GeneratedColumn<String>(
    'tag_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _prefixIdsMeta = const VerificationMeta(
    'prefixIds',
  );
  @override
  late final GeneratedColumn<String> prefixIds = GeneratedColumn<String>(
    'prefix_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _engineMeta = const VerificationMeta('engine');
  @override
  late final GeneratedColumn<String> engine = GeneratedColumn<String>(
    'engine',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _developerMeta = const VerificationMeta(
    'developer',
  );
  @override
  late final GeneratedColumn<String> developer = GeneratedColumn<String>(
    'developer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _installPathMeta = const VerificationMeta(
    'installPath',
  );
  @override
  late final GeneratedColumn<String> installPath = GeneratedColumn<String>(
    'install_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _launchPathMeta = const VerificationMeta(
    'launchPath',
  );
  @override
  late final GeneratedColumn<String> launchPath = GeneratedColumn<String>(
    'launch_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    threadId,
    title,
    creator,
    version,
    latestVersion,
    cover,
    screens,
    tags,
    tagIds,
    prefixIds,
    engine,
    developer,
    description,
    installPath,
    launchPath,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'games';
  @override
  VerificationContext validateIntegrity(
    Insertable<GameRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('thread_id')) {
      context.handle(
        _threadIdMeta,
        threadId.isAcceptableOrUnknown(data['thread_id']!, _threadIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('creator')) {
      context.handle(
        _creatorMeta,
        creator.isAcceptableOrUnknown(data['creator']!, _creatorMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('latest_version')) {
      context.handle(
        _latestVersionMeta,
        latestVersion.isAcceptableOrUnknown(
          data['latest_version']!,
          _latestVersionMeta,
        ),
      );
    }
    if (data.containsKey('cover')) {
      context.handle(
        _coverMeta,
        cover.isAcceptableOrUnknown(data['cover']!, _coverMeta),
      );
    }
    if (data.containsKey('screens')) {
      context.handle(
        _screensMeta,
        screens.isAcceptableOrUnknown(data['screens']!, _screensMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('tag_ids')) {
      context.handle(
        _tagIdsMeta,
        tagIds.isAcceptableOrUnknown(data['tag_ids']!, _tagIdsMeta),
      );
    }
    if (data.containsKey('prefix_ids')) {
      context.handle(
        _prefixIdsMeta,
        prefixIds.isAcceptableOrUnknown(data['prefix_ids']!, _prefixIdsMeta),
      );
    }
    if (data.containsKey('engine')) {
      context.handle(
        _engineMeta,
        engine.isAcceptableOrUnknown(data['engine']!, _engineMeta),
      );
    }
    if (data.containsKey('developer')) {
      context.handle(
        _developerMeta,
        developer.isAcceptableOrUnknown(data['developer']!, _developerMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('install_path')) {
      context.handle(
        _installPathMeta,
        installPath.isAcceptableOrUnknown(
          data['install_path']!,
          _installPathMeta,
        ),
      );
    }
    if (data.containsKey('launch_path')) {
      context.handle(
        _launchPathMeta,
        launchPath.isAcceptableOrUnknown(data['launch_path']!, _launchPathMeta),
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
  Set<GeneratedColumn> get $primaryKey => {threadId};
  @override
  GameRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GameRow(
      threadId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}thread_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      creator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creator'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      )!,
      latestVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}latest_version'],
      )!,
      cover: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover'],
      ),
      screens: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}screens'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      tagIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_ids'],
      )!,
      prefixIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prefix_ids'],
      )!,
      engine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}engine'],
      )!,
      developer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}developer'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      installPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}install_path'],
      ),
      launchPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}launch_path'],
      ),
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
  $GamesTable createAlias(String alias) {
    return $GamesTable(attachedDatabase, alias);
  }
}

class GameRow extends DataClass implements Insertable<GameRow> {
  final int threadId;
  final String title;
  final String creator;
  final String version;
  final String latestVersion;
  final String? cover;
  final String screens;
  final String tags;
  final String tagIds;
  final String prefixIds;
  final String engine;
  final String developer;
  final String description;
  final String? installPath;
  final String? launchPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  const GameRow({
    required this.threadId,
    required this.title,
    required this.creator,
    required this.version,
    required this.latestVersion,
    this.cover,
    required this.screens,
    required this.tags,
    required this.tagIds,
    required this.prefixIds,
    required this.engine,
    required this.developer,
    required this.description,
    this.installPath,
    this.launchPath,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['thread_id'] = Variable<int>(threadId);
    map['title'] = Variable<String>(title);
    map['creator'] = Variable<String>(creator);
    map['version'] = Variable<String>(version);
    map['latest_version'] = Variable<String>(latestVersion);
    if (!nullToAbsent || cover != null) {
      map['cover'] = Variable<String>(cover);
    }
    map['screens'] = Variable<String>(screens);
    map['tags'] = Variable<String>(tags);
    map['tag_ids'] = Variable<String>(tagIds);
    map['prefix_ids'] = Variable<String>(prefixIds);
    map['engine'] = Variable<String>(engine);
    map['developer'] = Variable<String>(developer);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || installPath != null) {
      map['install_path'] = Variable<String>(installPath);
    }
    if (!nullToAbsent || launchPath != null) {
      map['launch_path'] = Variable<String>(launchPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  GamesCompanion toCompanion(bool nullToAbsent) {
    return GamesCompanion(
      threadId: Value(threadId),
      title: Value(title),
      creator: Value(creator),
      version: Value(version),
      latestVersion: Value(latestVersion),
      cover: cover == null && nullToAbsent
          ? const Value.absent()
          : Value(cover),
      screens: Value(screens),
      tags: Value(tags),
      tagIds: Value(tagIds),
      prefixIds: Value(prefixIds),
      engine: Value(engine),
      developer: Value(developer),
      description: Value(description),
      installPath: installPath == null && nullToAbsent
          ? const Value.absent()
          : Value(installPath),
      launchPath: launchPath == null && nullToAbsent
          ? const Value.absent()
          : Value(launchPath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory GameRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GameRow(
      threadId: serializer.fromJson<int>(json['threadId']),
      title: serializer.fromJson<String>(json['title']),
      creator: serializer.fromJson<String>(json['creator']),
      version: serializer.fromJson<String>(json['version']),
      latestVersion: serializer.fromJson<String>(json['latestVersion']),
      cover: serializer.fromJson<String?>(json['cover']),
      screens: serializer.fromJson<String>(json['screens']),
      tags: serializer.fromJson<String>(json['tags']),
      tagIds: serializer.fromJson<String>(json['tagIds']),
      prefixIds: serializer.fromJson<String>(json['prefixIds']),
      engine: serializer.fromJson<String>(json['engine']),
      developer: serializer.fromJson<String>(json['developer']),
      description: serializer.fromJson<String>(json['description']),
      installPath: serializer.fromJson<String?>(json['installPath']),
      launchPath: serializer.fromJson<String?>(json['launchPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'threadId': serializer.toJson<int>(threadId),
      'title': serializer.toJson<String>(title),
      'creator': serializer.toJson<String>(creator),
      'version': serializer.toJson<String>(version),
      'latestVersion': serializer.toJson<String>(latestVersion),
      'cover': serializer.toJson<String?>(cover),
      'screens': serializer.toJson<String>(screens),
      'tags': serializer.toJson<String>(tags),
      'tagIds': serializer.toJson<String>(tagIds),
      'prefixIds': serializer.toJson<String>(prefixIds),
      'engine': serializer.toJson<String>(engine),
      'developer': serializer.toJson<String>(developer),
      'description': serializer.toJson<String>(description),
      'installPath': serializer.toJson<String?>(installPath),
      'launchPath': serializer.toJson<String?>(launchPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  GameRow copyWith({
    int? threadId,
    String? title,
    String? creator,
    String? version,
    String? latestVersion,
    Value<String?> cover = const Value.absent(),
    String? screens,
    String? tags,
    String? tagIds,
    String? prefixIds,
    String? engine,
    String? developer,
    String? description,
    Value<String?> installPath = const Value.absent(),
    Value<String?> launchPath = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => GameRow(
    threadId: threadId ?? this.threadId,
    title: title ?? this.title,
    creator: creator ?? this.creator,
    version: version ?? this.version,
    latestVersion: latestVersion ?? this.latestVersion,
    cover: cover.present ? cover.value : this.cover,
    screens: screens ?? this.screens,
    tags: tags ?? this.tags,
    tagIds: tagIds ?? this.tagIds,
    prefixIds: prefixIds ?? this.prefixIds,
    engine: engine ?? this.engine,
    developer: developer ?? this.developer,
    description: description ?? this.description,
    installPath: installPath.present ? installPath.value : this.installPath,
    launchPath: launchPath.present ? launchPath.value : this.launchPath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  GameRow copyWithCompanion(GamesCompanion data) {
    return GameRow(
      threadId: data.threadId.present ? data.threadId.value : this.threadId,
      title: data.title.present ? data.title.value : this.title,
      creator: data.creator.present ? data.creator.value : this.creator,
      version: data.version.present ? data.version.value : this.version,
      latestVersion: data.latestVersion.present
          ? data.latestVersion.value
          : this.latestVersion,
      cover: data.cover.present ? data.cover.value : this.cover,
      screens: data.screens.present ? data.screens.value : this.screens,
      tags: data.tags.present ? data.tags.value : this.tags,
      tagIds: data.tagIds.present ? data.tagIds.value : this.tagIds,
      prefixIds: data.prefixIds.present ? data.prefixIds.value : this.prefixIds,
      engine: data.engine.present ? data.engine.value : this.engine,
      developer: data.developer.present ? data.developer.value : this.developer,
      description: data.description.present
          ? data.description.value
          : this.description,
      installPath: data.installPath.present
          ? data.installPath.value
          : this.installPath,
      launchPath: data.launchPath.present
          ? data.launchPath.value
          : this.launchPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GameRow(')
          ..write('threadId: $threadId, ')
          ..write('title: $title, ')
          ..write('creator: $creator, ')
          ..write('version: $version, ')
          ..write('latestVersion: $latestVersion, ')
          ..write('cover: $cover, ')
          ..write('screens: $screens, ')
          ..write('tags: $tags, ')
          ..write('tagIds: $tagIds, ')
          ..write('prefixIds: $prefixIds, ')
          ..write('engine: $engine, ')
          ..write('developer: $developer, ')
          ..write('description: $description, ')
          ..write('installPath: $installPath, ')
          ..write('launchPath: $launchPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    threadId,
    title,
    creator,
    version,
    latestVersion,
    cover,
    screens,
    tags,
    tagIds,
    prefixIds,
    engine,
    developer,
    description,
    installPath,
    launchPath,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameRow &&
          other.threadId == this.threadId &&
          other.title == this.title &&
          other.creator == this.creator &&
          other.version == this.version &&
          other.latestVersion == this.latestVersion &&
          other.cover == this.cover &&
          other.screens == this.screens &&
          other.tags == this.tags &&
          other.tagIds == this.tagIds &&
          other.prefixIds == this.prefixIds &&
          other.engine == this.engine &&
          other.developer == this.developer &&
          other.description == this.description &&
          other.installPath == this.installPath &&
          other.launchPath == this.launchPath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class GamesCompanion extends UpdateCompanion<GameRow> {
  final Value<int> threadId;
  final Value<String> title;
  final Value<String> creator;
  final Value<String> version;
  final Value<String> latestVersion;
  final Value<String?> cover;
  final Value<String> screens;
  final Value<String> tags;
  final Value<String> tagIds;
  final Value<String> prefixIds;
  final Value<String> engine;
  final Value<String> developer;
  final Value<String> description;
  final Value<String?> installPath;
  final Value<String?> launchPath;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const GamesCompanion({
    this.threadId = const Value.absent(),
    this.title = const Value.absent(),
    this.creator = const Value.absent(),
    this.version = const Value.absent(),
    this.latestVersion = const Value.absent(),
    this.cover = const Value.absent(),
    this.screens = const Value.absent(),
    this.tags = const Value.absent(),
    this.tagIds = const Value.absent(),
    this.prefixIds = const Value.absent(),
    this.engine = const Value.absent(),
    this.developer = const Value.absent(),
    this.description = const Value.absent(),
    this.installPath = const Value.absent(),
    this.launchPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  GamesCompanion.insert({
    this.threadId = const Value.absent(),
    this.title = const Value.absent(),
    this.creator = const Value.absent(),
    this.version = const Value.absent(),
    this.latestVersion = const Value.absent(),
    this.cover = const Value.absent(),
    this.screens = const Value.absent(),
    this.tags = const Value.absent(),
    this.tagIds = const Value.absent(),
    this.prefixIds = const Value.absent(),
    this.engine = const Value.absent(),
    this.developer = const Value.absent(),
    this.description = const Value.absent(),
    this.installPath = const Value.absent(),
    this.launchPath = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<GameRow> custom({
    Expression<int>? threadId,
    Expression<String>? title,
    Expression<String>? creator,
    Expression<String>? version,
    Expression<String>? latestVersion,
    Expression<String>? cover,
    Expression<String>? screens,
    Expression<String>? tags,
    Expression<String>? tagIds,
    Expression<String>? prefixIds,
    Expression<String>? engine,
    Expression<String>? developer,
    Expression<String>? description,
    Expression<String>? installPath,
    Expression<String>? launchPath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (threadId != null) 'thread_id': threadId,
      if (title != null) 'title': title,
      if (creator != null) 'creator': creator,
      if (version != null) 'version': version,
      if (latestVersion != null) 'latest_version': latestVersion,
      if (cover != null) 'cover': cover,
      if (screens != null) 'screens': screens,
      if (tags != null) 'tags': tags,
      if (tagIds != null) 'tag_ids': tagIds,
      if (prefixIds != null) 'prefix_ids': prefixIds,
      if (engine != null) 'engine': engine,
      if (developer != null) 'developer': developer,
      if (description != null) 'description': description,
      if (installPath != null) 'install_path': installPath,
      if (launchPath != null) 'launch_path': launchPath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  GamesCompanion copyWith({
    Value<int>? threadId,
    Value<String>? title,
    Value<String>? creator,
    Value<String>? version,
    Value<String>? latestVersion,
    Value<String?>? cover,
    Value<String>? screens,
    Value<String>? tags,
    Value<String>? tagIds,
    Value<String>? prefixIds,
    Value<String>? engine,
    Value<String>? developer,
    Value<String>? description,
    Value<String?>? installPath,
    Value<String?>? launchPath,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return GamesCompanion(
      threadId: threadId ?? this.threadId,
      title: title ?? this.title,
      creator: creator ?? this.creator,
      version: version ?? this.version,
      latestVersion: latestVersion ?? this.latestVersion,
      cover: cover ?? this.cover,
      screens: screens ?? this.screens,
      tags: tags ?? this.tags,
      tagIds: tagIds ?? this.tagIds,
      prefixIds: prefixIds ?? this.prefixIds,
      engine: engine ?? this.engine,
      developer: developer ?? this.developer,
      description: description ?? this.description,
      installPath: installPath ?? this.installPath,
      launchPath: launchPath ?? this.launchPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (threadId.present) {
      map['thread_id'] = Variable<int>(threadId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (creator.present) {
      map['creator'] = Variable<String>(creator.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (latestVersion.present) {
      map['latest_version'] = Variable<String>(latestVersion.value);
    }
    if (cover.present) {
      map['cover'] = Variable<String>(cover.value);
    }
    if (screens.present) {
      map['screens'] = Variable<String>(screens.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (tagIds.present) {
      map['tag_ids'] = Variable<String>(tagIds.value);
    }
    if (prefixIds.present) {
      map['prefix_ids'] = Variable<String>(prefixIds.value);
    }
    if (engine.present) {
      map['engine'] = Variable<String>(engine.value);
    }
    if (developer.present) {
      map['developer'] = Variable<String>(developer.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (installPath.present) {
      map['install_path'] = Variable<String>(installPath.value);
    }
    if (launchPath.present) {
      map['launch_path'] = Variable<String>(launchPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GamesCompanion(')
          ..write('threadId: $threadId, ')
          ..write('title: $title, ')
          ..write('creator: $creator, ')
          ..write('version: $version, ')
          ..write('latestVersion: $latestVersion, ')
          ..write('cover: $cover, ')
          ..write('screens: $screens, ')
          ..write('tags: $tags, ')
          ..write('tagIds: $tagIds, ')
          ..write('prefixIds: $prefixIds, ')
          ..write('engine: $engine, ')
          ..write('developer: $developer, ')
          ..write('description: $description, ')
          ..write('installPath: $installPath, ')
          ..write('launchPath: $launchPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DownloadsTable extends Downloads
    with TableInfo<$DownloadsTable, DownloadRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _gidMeta = const VerificationMeta('gid');
  @override
  late final GeneratedColumn<String> gid = GeneratedColumn<String>(
    'gid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _threadIdMeta = const VerificationMeta(
    'threadId',
  );
  @override
  late final GeneratedColumn<int> threadId = GeneratedColumn<int>(
    'thread_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetDirMeta = const VerificationMeta(
    'targetDir',
  );
  @override
  late final GeneratedColumn<String> targetDir = GeneratedColumn<String>(
    'target_dir',
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
    gid,
    threadId,
    status,
    progress,
    targetDir,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloads';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('gid')) {
      context.handle(
        _gidMeta,
        gid.isAcceptableOrUnknown(data['gid']!, _gidMeta),
      );
    } else if (isInserting) {
      context.missing(_gidMeta);
    }
    if (data.containsKey('thread_id')) {
      context.handle(
        _threadIdMeta,
        threadId.isAcceptableOrUnknown(data['thread_id']!, _threadIdMeta),
      );
    } else if (isInserting) {
      context.missing(_threadIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    } else if (isInserting) {
      context.missing(_progressMeta);
    }
    if (data.containsKey('target_dir')) {
      context.handle(
        _targetDirMeta,
        targetDir.isAcceptableOrUnknown(data['target_dir']!, _targetDirMeta),
      );
    } else if (isInserting) {
      context.missing(_targetDirMeta);
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
  Set<GeneratedColumn> get $primaryKey => {gid};
  @override
  DownloadRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadRow(
      gid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gid'],
      )!,
      threadId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}thread_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress'],
      )!,
      targetDir: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_dir'],
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
  $DownloadsTable createAlias(String alias) {
    return $DownloadsTable(attachedDatabase, alias);
  }
}

class DownloadRow extends DataClass implements Insertable<DownloadRow> {
  final String gid;
  final int threadId;
  final String status;
  final double progress;
  final String targetDir;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DownloadRow({
    required this.gid,
    required this.threadId,
    required this.status,
    required this.progress,
    required this.targetDir,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['gid'] = Variable<String>(gid);
    map['thread_id'] = Variable<int>(threadId);
    map['status'] = Variable<String>(status);
    map['progress'] = Variable<double>(progress);
    map['target_dir'] = Variable<String>(targetDir);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DownloadsCompanion toCompanion(bool nullToAbsent) {
    return DownloadsCompanion(
      gid: Value(gid),
      threadId: Value(threadId),
      status: Value(status),
      progress: Value(progress),
      targetDir: Value(targetDir),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DownloadRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadRow(
      gid: serializer.fromJson<String>(json['gid']),
      threadId: serializer.fromJson<int>(json['threadId']),
      status: serializer.fromJson<String>(json['status']),
      progress: serializer.fromJson<double>(json['progress']),
      targetDir: serializer.fromJson<String>(json['targetDir']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'gid': serializer.toJson<String>(gid),
      'threadId': serializer.toJson<int>(threadId),
      'status': serializer.toJson<String>(status),
      'progress': serializer.toJson<double>(progress),
      'targetDir': serializer.toJson<String>(targetDir),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DownloadRow copyWith({
    String? gid,
    int? threadId,
    String? status,
    double? progress,
    String? targetDir,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DownloadRow(
    gid: gid ?? this.gid,
    threadId: threadId ?? this.threadId,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    targetDir: targetDir ?? this.targetDir,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DownloadRow copyWithCompanion(DownloadsCompanion data) {
    return DownloadRow(
      gid: data.gid.present ? data.gid.value : this.gid,
      threadId: data.threadId.present ? data.threadId.value : this.threadId,
      status: data.status.present ? data.status.value : this.status,
      progress: data.progress.present ? data.progress.value : this.progress,
      targetDir: data.targetDir.present ? data.targetDir.value : this.targetDir,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadRow(')
          ..write('gid: $gid, ')
          ..write('threadId: $threadId, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('targetDir: $targetDir, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    gid,
    threadId,
    status,
    progress,
    targetDir,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadRow &&
          other.gid == this.gid &&
          other.threadId == this.threadId &&
          other.status == this.status &&
          other.progress == this.progress &&
          other.targetDir == this.targetDir &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DownloadsCompanion extends UpdateCompanion<DownloadRow> {
  final Value<String> gid;
  final Value<int> threadId;
  final Value<String> status;
  final Value<double> progress;
  final Value<String> targetDir;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DownloadsCompanion({
    this.gid = const Value.absent(),
    this.threadId = const Value.absent(),
    this.status = const Value.absent(),
    this.progress = const Value.absent(),
    this.targetDir = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadsCompanion.insert({
    required String gid,
    required int threadId,
    required String status,
    required double progress,
    required String targetDir,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : gid = Value(gid),
       threadId = Value(threadId),
       status = Value(status),
       progress = Value(progress),
       targetDir = Value(targetDir),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DownloadRow> custom({
    Expression<String>? gid,
    Expression<int>? threadId,
    Expression<String>? status,
    Expression<double>? progress,
    Expression<String>? targetDir,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (gid != null) 'gid': gid,
      if (threadId != null) 'thread_id': threadId,
      if (status != null) 'status': status,
      if (progress != null) 'progress': progress,
      if (targetDir != null) 'target_dir': targetDir,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadsCompanion copyWith({
    Value<String>? gid,
    Value<int>? threadId,
    Value<String>? status,
    Value<double>? progress,
    Value<String>? targetDir,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DownloadsCompanion(
      gid: gid ?? this.gid,
      threadId: threadId ?? this.threadId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      targetDir: targetDir ?? this.targetDir,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (gid.present) {
      map['gid'] = Variable<String>(gid.value);
    }
    if (threadId.present) {
      map['thread_id'] = Variable<int>(threadId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (targetDir.present) {
      map['target_dir'] = Variable<String>(targetDir.value);
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
    return (StringBuffer('DownloadsCompanion(')
          ..write('gid: $gid, ')
          ..write('threadId: $threadId, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('targetDir: $targetDir, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VersionsTable extends Versions
    with TableInfo<$VersionsTable, VersionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VersionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _threadIdMeta = const VerificationMeta(
    'threadId',
  );
  @override
  late final GeneratedColumn<int> threadId = GeneratedColumn<int>(
    'thread_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _releasedAtMeta = const VerificationMeta(
    'releasedAt',
  );
  @override
  late final GeneratedColumn<DateTime> releasedAt = GeneratedColumn<DateTime>(
    'released_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, threadId, value, releasedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<VersionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('thread_id')) {
      context.handle(
        _threadIdMeta,
        threadId.isAcceptableOrUnknown(data['thread_id']!, _threadIdMeta),
      );
    } else if (isInserting) {
      context.missing(_threadIdMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('released_at')) {
      context.handle(
        _releasedAtMeta,
        releasedAt.isAcceptableOrUnknown(data['released_at']!, _releasedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VersionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VersionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      threadId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}thread_id'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      releasedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}released_at'],
      ),
    );
  }

  @override
  $VersionsTable createAlias(String alias) {
    return $VersionsTable(attachedDatabase, alias);
  }
}

class VersionRow extends DataClass implements Insertable<VersionRow> {
  final int id;
  final int threadId;
  final String value;
  final DateTime? releasedAt;
  const VersionRow({
    required this.id,
    required this.threadId,
    required this.value,
    this.releasedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['thread_id'] = Variable<int>(threadId);
    map['value'] = Variable<String>(value);
    if (!nullToAbsent || releasedAt != null) {
      map['released_at'] = Variable<DateTime>(releasedAt);
    }
    return map;
  }

  VersionsCompanion toCompanion(bool nullToAbsent) {
    return VersionsCompanion(
      id: Value(id),
      threadId: Value(threadId),
      value: Value(value),
      releasedAt: releasedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(releasedAt),
    );
  }

  factory VersionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VersionRow(
      id: serializer.fromJson<int>(json['id']),
      threadId: serializer.fromJson<int>(json['threadId']),
      value: serializer.fromJson<String>(json['value']),
      releasedAt: serializer.fromJson<DateTime?>(json['releasedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'threadId': serializer.toJson<int>(threadId),
      'value': serializer.toJson<String>(value),
      'releasedAt': serializer.toJson<DateTime?>(releasedAt),
    };
  }

  VersionRow copyWith({
    int? id,
    int? threadId,
    String? value,
    Value<DateTime?> releasedAt = const Value.absent(),
  }) => VersionRow(
    id: id ?? this.id,
    threadId: threadId ?? this.threadId,
    value: value ?? this.value,
    releasedAt: releasedAt.present ? releasedAt.value : this.releasedAt,
  );
  VersionRow copyWithCompanion(VersionsCompanion data) {
    return VersionRow(
      id: data.id.present ? data.id.value : this.id,
      threadId: data.threadId.present ? data.threadId.value : this.threadId,
      value: data.value.present ? data.value.value : this.value,
      releasedAt: data.releasedAt.present
          ? data.releasedAt.value
          : this.releasedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VersionRow(')
          ..write('id: $id, ')
          ..write('threadId: $threadId, ')
          ..write('value: $value, ')
          ..write('releasedAt: $releasedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, threadId, value, releasedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VersionRow &&
          other.id == this.id &&
          other.threadId == this.threadId &&
          other.value == this.value &&
          other.releasedAt == this.releasedAt);
}

class VersionsCompanion extends UpdateCompanion<VersionRow> {
  final Value<int> id;
  final Value<int> threadId;
  final Value<String> value;
  final Value<DateTime?> releasedAt;
  const VersionsCompanion({
    this.id = const Value.absent(),
    this.threadId = const Value.absent(),
    this.value = const Value.absent(),
    this.releasedAt = const Value.absent(),
  });
  VersionsCompanion.insert({
    this.id = const Value.absent(),
    required int threadId,
    required String value,
    this.releasedAt = const Value.absent(),
  }) : threadId = Value(threadId),
       value = Value(value);
  static Insertable<VersionRow> custom({
    Expression<int>? id,
    Expression<int>? threadId,
    Expression<String>? value,
    Expression<DateTime>? releasedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (threadId != null) 'thread_id': threadId,
      if (value != null) 'value': value,
      if (releasedAt != null) 'released_at': releasedAt,
    });
  }

  VersionsCompanion copyWith({
    Value<int>? id,
    Value<int>? threadId,
    Value<String>? value,
    Value<DateTime?>? releasedAt,
  }) {
    return VersionsCompanion(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      value: value ?? this.value,
      releasedAt: releasedAt ?? this.releasedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (threadId.present) {
      map['thread_id'] = Variable<int>(threadId.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (releasedAt.present) {
      map['released_at'] = Variable<DateTime>(releasedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VersionsCompanion(')
          ..write('id: $id, ')
          ..write('threadId: $threadId, ')
          ..write('value: $value, ')
          ..write('releasedAt: $releasedAt')
          ..write(')'))
        .toString();
  }
}

class $GameIndexTable extends GameIndex
    with TableInfo<$GameIndexTable, GameIndexRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GameIndexTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _threadIdMeta = const VerificationMeta(
    'threadId',
  );
  @override
  late final GeneratedColumn<int> threadId = GeneratedColumn<int>(
    'thread_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _normalizedTitleMeta = const VerificationMeta(
    'normalizedTitle',
  );
  @override
  late final GeneratedColumn<String> normalizedTitle = GeneratedColumn<String>(
    'normalized_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _compactTitleMeta = const VerificationMeta(
    'compactTitle',
  );
  @override
  late final GeneratedColumn<String> compactTitle = GeneratedColumn<String>(
    'compact_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _creatorMeta = const VerificationMeta(
    'creator',
  );
  @override
  late final GeneratedColumn<String> creator = GeneratedColumn<String>(
    'creator',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _latestVersionMeta = const VerificationMeta(
    'latestVersion',
  );
  @override
  late final GeneratedColumn<String> latestVersion = GeneratedColumn<String>(
    'latest_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _coverMeta = const VerificationMeta('cover');
  @override
  late final GeneratedColumn<String> cover = GeneratedColumn<String>(
    'cover',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _screensMeta = const VerificationMeta(
    'screens',
  );
  @override
  late final GeneratedColumn<String> screens = GeneratedColumn<String>(
    'screens',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _prefixesMeta = const VerificationMeta(
    'prefixes',
  );
  @override
  late final GeneratedColumn<String> prefixes = GeneratedColumn<String>(
    'prefixes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _viewsMeta = const VerificationMeta('views');
  @override
  late final GeneratedColumn<int> views = GeneratedColumn<int>(
    'views',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _likesMeta = const VerificationMeta('likes');
  @override
  late final GeneratedColumn<int> likes = GeneratedColumn<int>(
    'likes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<int> ts = GeneratedColumn<int>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    threadId,
    title,
    normalizedTitle,
    compactTitle,
    creator,
    latestVersion,
    cover,
    screens,
    tags,
    prefixes,
    rating,
    views,
    likes,
    ts,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'game_index';
  @override
  VerificationContext validateIntegrity(
    Insertable<GameIndexRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('thread_id')) {
      context.handle(
        _threadIdMeta,
        threadId.isAcceptableOrUnknown(data['thread_id']!, _threadIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('normalized_title')) {
      context.handle(
        _normalizedTitleMeta,
        normalizedTitle.isAcceptableOrUnknown(
          data['normalized_title']!,
          _normalizedTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedTitleMeta);
    }
    if (data.containsKey('compact_title')) {
      context.handle(
        _compactTitleMeta,
        compactTitle.isAcceptableOrUnknown(
          data['compact_title']!,
          _compactTitleMeta,
        ),
      );
    }
    if (data.containsKey('creator')) {
      context.handle(
        _creatorMeta,
        creator.isAcceptableOrUnknown(data['creator']!, _creatorMeta),
      );
    }
    if (data.containsKey('latest_version')) {
      context.handle(
        _latestVersionMeta,
        latestVersion.isAcceptableOrUnknown(
          data['latest_version']!,
          _latestVersionMeta,
        ),
      );
    }
    if (data.containsKey('cover')) {
      context.handle(
        _coverMeta,
        cover.isAcceptableOrUnknown(data['cover']!, _coverMeta),
      );
    }
    if (data.containsKey('screens')) {
      context.handle(
        _screensMeta,
        screens.isAcceptableOrUnknown(data['screens']!, _screensMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('prefixes')) {
      context.handle(
        _prefixesMeta,
        prefixes.isAcceptableOrUnknown(data['prefixes']!, _prefixesMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('views')) {
      context.handle(
        _viewsMeta,
        views.isAcceptableOrUnknown(data['views']!, _viewsMeta),
      );
    }
    if (data.containsKey('likes')) {
      context.handle(
        _likesMeta,
        likes.isAcceptableOrUnknown(data['likes']!, _likesMeta),
      );
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {threadId};
  @override
  GameIndexRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GameIndexRow(
      threadId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}thread_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      normalizedTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_title'],
      )!,
      compactTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}compact_title'],
      )!,
      creator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creator'],
      )!,
      latestVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}latest_version'],
      )!,
      cover: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover'],
      ),
      screens: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}screens'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      prefixes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prefixes'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating'],
      )!,
      views: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}views'],
      )!,
      likes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}likes'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $GameIndexTable createAlias(String alias) {
    return $GameIndexTable(attachedDatabase, alias);
  }
}

class GameIndexRow extends DataClass implements Insertable<GameIndexRow> {
  final int threadId;
  final String title;
  final String normalizedTitle;
  final String compactTitle;
  final String creator;
  final String latestVersion;
  final String? cover;
  final String screens;
  final String tags;
  final String prefixes;
  final double rating;
  final int views;
  final int likes;
  final int ts;
  final DateTime cachedAt;
  const GameIndexRow({
    required this.threadId,
    required this.title,
    required this.normalizedTitle,
    required this.compactTitle,
    required this.creator,
    required this.latestVersion,
    this.cover,
    required this.screens,
    required this.tags,
    required this.prefixes,
    required this.rating,
    required this.views,
    required this.likes,
    required this.ts,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['thread_id'] = Variable<int>(threadId);
    map['title'] = Variable<String>(title);
    map['normalized_title'] = Variable<String>(normalizedTitle);
    map['compact_title'] = Variable<String>(compactTitle);
    map['creator'] = Variable<String>(creator);
    map['latest_version'] = Variable<String>(latestVersion);
    if (!nullToAbsent || cover != null) {
      map['cover'] = Variable<String>(cover);
    }
    map['screens'] = Variable<String>(screens);
    map['tags'] = Variable<String>(tags);
    map['prefixes'] = Variable<String>(prefixes);
    map['rating'] = Variable<double>(rating);
    map['views'] = Variable<int>(views);
    map['likes'] = Variable<int>(likes);
    map['ts'] = Variable<int>(ts);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  GameIndexCompanion toCompanion(bool nullToAbsent) {
    return GameIndexCompanion(
      threadId: Value(threadId),
      title: Value(title),
      normalizedTitle: Value(normalizedTitle),
      compactTitle: Value(compactTitle),
      creator: Value(creator),
      latestVersion: Value(latestVersion),
      cover: cover == null && nullToAbsent
          ? const Value.absent()
          : Value(cover),
      screens: Value(screens),
      tags: Value(tags),
      prefixes: Value(prefixes),
      rating: Value(rating),
      views: Value(views),
      likes: Value(likes),
      ts: Value(ts),
      cachedAt: Value(cachedAt),
    );
  }

  factory GameIndexRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GameIndexRow(
      threadId: serializer.fromJson<int>(json['threadId']),
      title: serializer.fromJson<String>(json['title']),
      normalizedTitle: serializer.fromJson<String>(json['normalizedTitle']),
      compactTitle: serializer.fromJson<String>(json['compactTitle']),
      creator: serializer.fromJson<String>(json['creator']),
      latestVersion: serializer.fromJson<String>(json['latestVersion']),
      cover: serializer.fromJson<String?>(json['cover']),
      screens: serializer.fromJson<String>(json['screens']),
      tags: serializer.fromJson<String>(json['tags']),
      prefixes: serializer.fromJson<String>(json['prefixes']),
      rating: serializer.fromJson<double>(json['rating']),
      views: serializer.fromJson<int>(json['views']),
      likes: serializer.fromJson<int>(json['likes']),
      ts: serializer.fromJson<int>(json['ts']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'threadId': serializer.toJson<int>(threadId),
      'title': serializer.toJson<String>(title),
      'normalizedTitle': serializer.toJson<String>(normalizedTitle),
      'compactTitle': serializer.toJson<String>(compactTitle),
      'creator': serializer.toJson<String>(creator),
      'latestVersion': serializer.toJson<String>(latestVersion),
      'cover': serializer.toJson<String?>(cover),
      'screens': serializer.toJson<String>(screens),
      'tags': serializer.toJson<String>(tags),
      'prefixes': serializer.toJson<String>(prefixes),
      'rating': serializer.toJson<double>(rating),
      'views': serializer.toJson<int>(views),
      'likes': serializer.toJson<int>(likes),
      'ts': serializer.toJson<int>(ts),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  GameIndexRow copyWith({
    int? threadId,
    String? title,
    String? normalizedTitle,
    String? compactTitle,
    String? creator,
    String? latestVersion,
    Value<String?> cover = const Value.absent(),
    String? screens,
    String? tags,
    String? prefixes,
    double? rating,
    int? views,
    int? likes,
    int? ts,
    DateTime? cachedAt,
  }) => GameIndexRow(
    threadId: threadId ?? this.threadId,
    title: title ?? this.title,
    normalizedTitle: normalizedTitle ?? this.normalizedTitle,
    compactTitle: compactTitle ?? this.compactTitle,
    creator: creator ?? this.creator,
    latestVersion: latestVersion ?? this.latestVersion,
    cover: cover.present ? cover.value : this.cover,
    screens: screens ?? this.screens,
    tags: tags ?? this.tags,
    prefixes: prefixes ?? this.prefixes,
    rating: rating ?? this.rating,
    views: views ?? this.views,
    likes: likes ?? this.likes,
    ts: ts ?? this.ts,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  GameIndexRow copyWithCompanion(GameIndexCompanion data) {
    return GameIndexRow(
      threadId: data.threadId.present ? data.threadId.value : this.threadId,
      title: data.title.present ? data.title.value : this.title,
      normalizedTitle: data.normalizedTitle.present
          ? data.normalizedTitle.value
          : this.normalizedTitle,
      compactTitle: data.compactTitle.present
          ? data.compactTitle.value
          : this.compactTitle,
      creator: data.creator.present ? data.creator.value : this.creator,
      latestVersion: data.latestVersion.present
          ? data.latestVersion.value
          : this.latestVersion,
      cover: data.cover.present ? data.cover.value : this.cover,
      screens: data.screens.present ? data.screens.value : this.screens,
      tags: data.tags.present ? data.tags.value : this.tags,
      prefixes: data.prefixes.present ? data.prefixes.value : this.prefixes,
      rating: data.rating.present ? data.rating.value : this.rating,
      views: data.views.present ? data.views.value : this.views,
      likes: data.likes.present ? data.likes.value : this.likes,
      ts: data.ts.present ? data.ts.value : this.ts,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GameIndexRow(')
          ..write('threadId: $threadId, ')
          ..write('title: $title, ')
          ..write('normalizedTitle: $normalizedTitle, ')
          ..write('compactTitle: $compactTitle, ')
          ..write('creator: $creator, ')
          ..write('latestVersion: $latestVersion, ')
          ..write('cover: $cover, ')
          ..write('screens: $screens, ')
          ..write('tags: $tags, ')
          ..write('prefixes: $prefixes, ')
          ..write('rating: $rating, ')
          ..write('views: $views, ')
          ..write('likes: $likes, ')
          ..write('ts: $ts, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    threadId,
    title,
    normalizedTitle,
    compactTitle,
    creator,
    latestVersion,
    cover,
    screens,
    tags,
    prefixes,
    rating,
    views,
    likes,
    ts,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameIndexRow &&
          other.threadId == this.threadId &&
          other.title == this.title &&
          other.normalizedTitle == this.normalizedTitle &&
          other.compactTitle == this.compactTitle &&
          other.creator == this.creator &&
          other.latestVersion == this.latestVersion &&
          other.cover == this.cover &&
          other.screens == this.screens &&
          other.tags == this.tags &&
          other.prefixes == this.prefixes &&
          other.rating == this.rating &&
          other.views == this.views &&
          other.likes == this.likes &&
          other.ts == this.ts &&
          other.cachedAt == this.cachedAt);
}

class GameIndexCompanion extends UpdateCompanion<GameIndexRow> {
  final Value<int> threadId;
  final Value<String> title;
  final Value<String> normalizedTitle;
  final Value<String> compactTitle;
  final Value<String> creator;
  final Value<String> latestVersion;
  final Value<String?> cover;
  final Value<String> screens;
  final Value<String> tags;
  final Value<String> prefixes;
  final Value<double> rating;
  final Value<int> views;
  final Value<int> likes;
  final Value<int> ts;
  final Value<DateTime> cachedAt;
  const GameIndexCompanion({
    this.threadId = const Value.absent(),
    this.title = const Value.absent(),
    this.normalizedTitle = const Value.absent(),
    this.compactTitle = const Value.absent(),
    this.creator = const Value.absent(),
    this.latestVersion = const Value.absent(),
    this.cover = const Value.absent(),
    this.screens = const Value.absent(),
    this.tags = const Value.absent(),
    this.prefixes = const Value.absent(),
    this.rating = const Value.absent(),
    this.views = const Value.absent(),
    this.likes = const Value.absent(),
    this.ts = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  GameIndexCompanion.insert({
    this.threadId = const Value.absent(),
    required String title,
    required String normalizedTitle,
    this.compactTitle = const Value.absent(),
    this.creator = const Value.absent(),
    this.latestVersion = const Value.absent(),
    this.cover = const Value.absent(),
    this.screens = const Value.absent(),
    this.tags = const Value.absent(),
    this.prefixes = const Value.absent(),
    this.rating = const Value.absent(),
    this.views = const Value.absent(),
    this.likes = const Value.absent(),
    this.ts = const Value.absent(),
    required DateTime cachedAt,
  }) : title = Value(title),
       normalizedTitle = Value(normalizedTitle),
       cachedAt = Value(cachedAt);
  static Insertable<GameIndexRow> custom({
    Expression<int>? threadId,
    Expression<String>? title,
    Expression<String>? normalizedTitle,
    Expression<String>? compactTitle,
    Expression<String>? creator,
    Expression<String>? latestVersion,
    Expression<String>? cover,
    Expression<String>? screens,
    Expression<String>? tags,
    Expression<String>? prefixes,
    Expression<double>? rating,
    Expression<int>? views,
    Expression<int>? likes,
    Expression<int>? ts,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (threadId != null) 'thread_id': threadId,
      if (title != null) 'title': title,
      if (normalizedTitle != null) 'normalized_title': normalizedTitle,
      if (compactTitle != null) 'compact_title': compactTitle,
      if (creator != null) 'creator': creator,
      if (latestVersion != null) 'latest_version': latestVersion,
      if (cover != null) 'cover': cover,
      if (screens != null) 'screens': screens,
      if (tags != null) 'tags': tags,
      if (prefixes != null) 'prefixes': prefixes,
      if (rating != null) 'rating': rating,
      if (views != null) 'views': views,
      if (likes != null) 'likes': likes,
      if (ts != null) 'ts': ts,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  GameIndexCompanion copyWith({
    Value<int>? threadId,
    Value<String>? title,
    Value<String>? normalizedTitle,
    Value<String>? compactTitle,
    Value<String>? creator,
    Value<String>? latestVersion,
    Value<String?>? cover,
    Value<String>? screens,
    Value<String>? tags,
    Value<String>? prefixes,
    Value<double>? rating,
    Value<int>? views,
    Value<int>? likes,
    Value<int>? ts,
    Value<DateTime>? cachedAt,
  }) {
    return GameIndexCompanion(
      threadId: threadId ?? this.threadId,
      title: title ?? this.title,
      normalizedTitle: normalizedTitle ?? this.normalizedTitle,
      compactTitle: compactTitle ?? this.compactTitle,
      creator: creator ?? this.creator,
      latestVersion: latestVersion ?? this.latestVersion,
      cover: cover ?? this.cover,
      screens: screens ?? this.screens,
      tags: tags ?? this.tags,
      prefixes: prefixes ?? this.prefixes,
      rating: rating ?? this.rating,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      ts: ts ?? this.ts,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (threadId.present) {
      map['thread_id'] = Variable<int>(threadId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (normalizedTitle.present) {
      map['normalized_title'] = Variable<String>(normalizedTitle.value);
    }
    if (compactTitle.present) {
      map['compact_title'] = Variable<String>(compactTitle.value);
    }
    if (creator.present) {
      map['creator'] = Variable<String>(creator.value);
    }
    if (latestVersion.present) {
      map['latest_version'] = Variable<String>(latestVersion.value);
    }
    if (cover.present) {
      map['cover'] = Variable<String>(cover.value);
    }
    if (screens.present) {
      map['screens'] = Variable<String>(screens.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (prefixes.present) {
      map['prefixes'] = Variable<String>(prefixes.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (views.present) {
      map['views'] = Variable<int>(views.value);
    }
    if (likes.present) {
      map['likes'] = Variable<int>(likes.value);
    }
    if (ts.present) {
      map['ts'] = Variable<int>(ts.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GameIndexCompanion(')
          ..write('threadId: $threadId, ')
          ..write('title: $title, ')
          ..write('normalizedTitle: $normalizedTitle, ')
          ..write('compactTitle: $compactTitle, ')
          ..write('creator: $creator, ')
          ..write('latestVersion: $latestVersion, ')
          ..write('cover: $cover, ')
          ..write('screens: $screens, ')
          ..write('tags: $tags, ')
          ..write('prefixes: $prefixes, ')
          ..write('rating: $rating, ')
          ..write('views: $views, ')
          ..write('likes: $likes, ')
          ..write('ts: $ts, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $IndexMetaTable extends IndexMeta
    with TableInfo<$IndexMetaTable, IndexMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IndexMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'index_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<IndexMetaRow> instance, {
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
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  IndexMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IndexMetaRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $IndexMetaTable createAlias(String alias) {
    return $IndexMetaTable(attachedDatabase, alias);
  }
}

class IndexMetaRow extends DataClass implements Insertable<IndexMetaRow> {
  final String key;
  final String value;
  const IndexMetaRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  IndexMetaCompanion toCompanion(bool nullToAbsent) {
    return IndexMetaCompanion(key: Value(key), value: Value(value));
  }

  factory IndexMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IndexMetaRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  IndexMetaRow copyWith({String? key, String? value}) =>
      IndexMetaRow(key: key ?? this.key, value: value ?? this.value);
  IndexMetaRow copyWithCompanion(IndexMetaCompanion data) {
    return IndexMetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IndexMetaRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IndexMetaRow &&
          other.key == this.key &&
          other.value == this.value);
}

class IndexMetaCompanion extends UpdateCompanion<IndexMetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const IndexMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IndexMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<IndexMetaRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IndexMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return IndexMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IndexMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaySessionsTable extends PlaySessions
    with TableInfo<$PlaySessionsTable, PlaySessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaySessionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _threadIdMeta = const VerificationMeta(
    'threadId',
  );
  @override
  late final GeneratedColumn<int> threadId = GeneratedColumn<int>(
    'thread_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    threadId,
    startedAt,
    endedAt,
    durationSeconds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'play_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaySessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('thread_id')) {
      context.handle(
        _threadIdMeta,
        threadId.isAcceptableOrUnknown(data['thread_id']!, _threadIdMeta),
      );
    } else if (isInserting) {
      context.missing(_threadIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaySessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaySessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      threadId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}thread_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
    );
  }

  @override
  $PlaySessionsTable createAlias(String alias) {
    return $PlaySessionsTable(attachedDatabase, alias);
  }
}

class PlaySessionRow extends DataClass implements Insertable<PlaySessionRow> {
  final int id;
  final int threadId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? durationSeconds;
  const PlaySessionRow({
    required this.id,
    required this.threadId,
    required this.startedAt,
    this.endedAt,
    this.durationSeconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['thread_id'] = Variable<int>(threadId);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    return map;
  }

  PlaySessionsCompanion toCompanion(bool nullToAbsent) {
    return PlaySessionsCompanion(
      id: Value(id),
      threadId: Value(threadId),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
    );
  }

  factory PlaySessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaySessionRow(
      id: serializer.fromJson<int>(json['id']),
      threadId: serializer.fromJson<int>(json['threadId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'threadId': serializer.toJson<int>(threadId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
    };
  }

  PlaySessionRow copyWith({
    int? id,
    int? threadId,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    Value<int?> durationSeconds = const Value.absent(),
  }) => PlaySessionRow(
    id: id ?? this.id,
    threadId: threadId ?? this.threadId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
  );
  PlaySessionRow copyWithCompanion(PlaySessionsCompanion data) {
    return PlaySessionRow(
      id: data.id.present ? data.id.value : this.id,
      threadId: data.threadId.present ? data.threadId.value : this.threadId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaySessionRow(')
          ..write('id: $id, ')
          ..write('threadId: $threadId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationSeconds: $durationSeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, threadId, startedAt, endedAt, durationSeconds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaySessionRow &&
          other.id == this.id &&
          other.threadId == this.threadId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.durationSeconds == this.durationSeconds);
}

class PlaySessionsCompanion extends UpdateCompanion<PlaySessionRow> {
  final Value<int> id;
  final Value<int> threadId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int?> durationSeconds;
  const PlaySessionsCompanion({
    this.id = const Value.absent(),
    this.threadId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.durationSeconds = const Value.absent(),
  });
  PlaySessionsCompanion.insert({
    this.id = const Value.absent(),
    required int threadId,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.durationSeconds = const Value.absent(),
  }) : threadId = Value(threadId),
       startedAt = Value(startedAt);
  static Insertable<PlaySessionRow> custom({
    Expression<int>? id,
    Expression<int>? threadId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? durationSeconds,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (threadId != null) 'thread_id': threadId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
    });
  }

  PlaySessionsCompanion copyWith({
    Value<int>? id,
    Value<int>? threadId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<int?>? durationSeconds,
  }) {
    return PlaySessionsCompanion(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (threadId.present) {
      map['thread_id'] = Variable<int>(threadId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaySessionsCompanion(')
          ..write('id: $id, ')
          ..write('threadId: $threadId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationSeconds: $durationSeconds')
          ..write(')'))
        .toString();
  }
}

abstract class _$LibraryDatabase extends GeneratedDatabase {
  _$LibraryDatabase(QueryExecutor e) : super(e);
  $LibraryDatabaseManager get managers => $LibraryDatabaseManager(this);
  late final $GamesTable games = $GamesTable(this);
  late final $DownloadsTable downloads = $DownloadsTable(this);
  late final $VersionsTable versions = $VersionsTable(this);
  late final $GameIndexTable gameIndex = $GameIndexTable(this);
  late final $IndexMetaTable indexMeta = $IndexMetaTable(this);
  late final $PlaySessionsTable playSessions = $PlaySessionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    games,
    downloads,
    versions,
    gameIndex,
    indexMeta,
    playSessions,
  ];
}

typedef $$GamesTableCreateCompanionBuilder =
    GamesCompanion Function({
      Value<int> threadId,
      Value<String> title,
      Value<String> creator,
      Value<String> version,
      Value<String> latestVersion,
      Value<String?> cover,
      Value<String> screens,
      Value<String> tags,
      Value<String> tagIds,
      Value<String> prefixIds,
      Value<String> engine,
      Value<String> developer,
      Value<String> description,
      Value<String?> installPath,
      Value<String?> launchPath,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$GamesTableUpdateCompanionBuilder =
    GamesCompanion Function({
      Value<int> threadId,
      Value<String> title,
      Value<String> creator,
      Value<String> version,
      Value<String> latestVersion,
      Value<String?> cover,
      Value<String> screens,
      Value<String> tags,
      Value<String> tagIds,
      Value<String> prefixIds,
      Value<String> engine,
      Value<String> developer,
      Value<String> description,
      Value<String?> installPath,
      Value<String?> launchPath,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$GamesTableFilterComposer
    extends Composer<_$LibraryDatabase, $GamesTable> {
  $$GamesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creator => $composableBuilder(
    column: $table.creator,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get latestVersion => $composableBuilder(
    column: $table.latestVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get screens => $composableBuilder(
    column: $table.screens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagIds => $composableBuilder(
    column: $table.tagIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prefixIds => $composableBuilder(
    column: $table.prefixIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get engine => $composableBuilder(
    column: $table.engine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get developer => $composableBuilder(
    column: $table.developer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installPath => $composableBuilder(
    column: $table.installPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get launchPath => $composableBuilder(
    column: $table.launchPath,
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

class $$GamesTableOrderingComposer
    extends Composer<_$LibraryDatabase, $GamesTable> {
  $$GamesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creator => $composableBuilder(
    column: $table.creator,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get latestVersion => $composableBuilder(
    column: $table.latestVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get screens => $composableBuilder(
    column: $table.screens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagIds => $composableBuilder(
    column: $table.tagIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prefixIds => $composableBuilder(
    column: $table.prefixIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get engine => $composableBuilder(
    column: $table.engine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get developer => $composableBuilder(
    column: $table.developer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installPath => $composableBuilder(
    column: $table.installPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get launchPath => $composableBuilder(
    column: $table.launchPath,
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

class $$GamesTableAnnotationComposer
    extends Composer<_$LibraryDatabase, $GamesTable> {
  $$GamesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get threadId =>
      $composableBuilder(column: $table.threadId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get creator =>
      $composableBuilder(column: $table.creator, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get latestVersion => $composableBuilder(
    column: $table.latestVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cover =>
      $composableBuilder(column: $table.cover, builder: (column) => column);

  GeneratedColumn<String> get screens =>
      $composableBuilder(column: $table.screens, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get tagIds =>
      $composableBuilder(column: $table.tagIds, builder: (column) => column);

  GeneratedColumn<String> get prefixIds =>
      $composableBuilder(column: $table.prefixIds, builder: (column) => column);

  GeneratedColumn<String> get engine =>
      $composableBuilder(column: $table.engine, builder: (column) => column);

  GeneratedColumn<String> get developer =>
      $composableBuilder(column: $table.developer, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get installPath => $composableBuilder(
    column: $table.installPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get launchPath => $composableBuilder(
    column: $table.launchPath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$GamesTableTableManager
    extends
        RootTableManager<
          _$LibraryDatabase,
          $GamesTable,
          GameRow,
          $$GamesTableFilterComposer,
          $$GamesTableOrderingComposer,
          $$GamesTableAnnotationComposer,
          $$GamesTableCreateCompanionBuilder,
          $$GamesTableUpdateCompanionBuilder,
          (GameRow, BaseReferences<_$LibraryDatabase, $GamesTable, GameRow>),
          GameRow,
          PrefetchHooks Function()
        > {
  $$GamesTableTableManager(_$LibraryDatabase db, $GamesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GamesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GamesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GamesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> threadId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> creator = const Value.absent(),
                Value<String> version = const Value.absent(),
                Value<String> latestVersion = const Value.absent(),
                Value<String?> cover = const Value.absent(),
                Value<String> screens = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String> tagIds = const Value.absent(),
                Value<String> prefixIds = const Value.absent(),
                Value<String> engine = const Value.absent(),
                Value<String> developer = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String?> installPath = const Value.absent(),
                Value<String?> launchPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => GamesCompanion(
                threadId: threadId,
                title: title,
                creator: creator,
                version: version,
                latestVersion: latestVersion,
                cover: cover,
                screens: screens,
                tags: tags,
                tagIds: tagIds,
                prefixIds: prefixIds,
                engine: engine,
                developer: developer,
                description: description,
                installPath: installPath,
                launchPath: launchPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> threadId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> creator = const Value.absent(),
                Value<String> version = const Value.absent(),
                Value<String> latestVersion = const Value.absent(),
                Value<String?> cover = const Value.absent(),
                Value<String> screens = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String> tagIds = const Value.absent(),
                Value<String> prefixIds = const Value.absent(),
                Value<String> engine = const Value.absent(),
                Value<String> developer = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String?> installPath = const Value.absent(),
                Value<String?> launchPath = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => GamesCompanion.insert(
                threadId: threadId,
                title: title,
                creator: creator,
                version: version,
                latestVersion: latestVersion,
                cover: cover,
                screens: screens,
                tags: tags,
                tagIds: tagIds,
                prefixIds: prefixIds,
                engine: engine,
                developer: developer,
                description: description,
                installPath: installPath,
                launchPath: launchPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GamesTable, GameRow>(table),
                  BaseReferences<_$LibraryDatabase, $GamesTable, GameRow>(
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

typedef $$GamesTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDatabase,
      $GamesTable,
      GameRow,
      $$GamesTableFilterComposer,
      $$GamesTableOrderingComposer,
      $$GamesTableAnnotationComposer,
      $$GamesTableCreateCompanionBuilder,
      $$GamesTableUpdateCompanionBuilder,
      (GameRow, BaseReferences<_$LibraryDatabase, $GamesTable, GameRow>),
      GameRow,
      PrefetchHooks Function()
    >;
typedef $$DownloadsTableCreateCompanionBuilder =
    DownloadsCompanion Function({
      required String gid,
      required int threadId,
      required String status,
      required double progress,
      required String targetDir,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$DownloadsTableUpdateCompanionBuilder =
    DownloadsCompanion Function({
      Value<String> gid,
      Value<int> threadId,
      Value<String> status,
      Value<double> progress,
      Value<String> targetDir,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$DownloadsTableFilterComposer
    extends Composer<_$LibraryDatabase, $DownloadsTable> {
  $$DownloadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get gid => $composableBuilder(
    column: $table.gid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetDir => $composableBuilder(
    column: $table.targetDir,
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

class $$DownloadsTableOrderingComposer
    extends Composer<_$LibraryDatabase, $DownloadsTable> {
  $$DownloadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get gid => $composableBuilder(
    column: $table.gid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetDir => $composableBuilder(
    column: $table.targetDir,
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

class $$DownloadsTableAnnotationComposer
    extends Composer<_$LibraryDatabase, $DownloadsTable> {
  $$DownloadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get gid =>
      $composableBuilder(column: $table.gid, builder: (column) => column);

  GeneratedColumn<int> get threadId =>
      $composableBuilder(column: $table.threadId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<String> get targetDir =>
      $composableBuilder(column: $table.targetDir, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DownloadsTableTableManager
    extends
        RootTableManager<
          _$LibraryDatabase,
          $DownloadsTable,
          DownloadRow,
          $$DownloadsTableFilterComposer,
          $$DownloadsTableOrderingComposer,
          $$DownloadsTableAnnotationComposer,
          $$DownloadsTableCreateCompanionBuilder,
          $$DownloadsTableUpdateCompanionBuilder,
          (
            DownloadRow,
            BaseReferences<_$LibraryDatabase, $DownloadsTable, DownloadRow>,
          ),
          DownloadRow,
          PrefetchHooks Function()
        > {
  $$DownloadsTableTableManager(_$LibraryDatabase db, $DownloadsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> gid = const Value.absent(),
                Value<int> threadId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<String> targetDir = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadsCompanion(
                gid: gid,
                threadId: threadId,
                status: status,
                progress: progress,
                targetDir: targetDir,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String gid,
                required int threadId,
                required String status,
                required double progress,
                required String targetDir,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DownloadsCompanion.insert(
                gid: gid,
                threadId: threadId,
                status: status,
                progress: progress,
                targetDir: targetDir,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DownloadsTable, DownloadRow>(table),
                  BaseReferences<
                    _$LibraryDatabase,
                    $DownloadsTable,
                    DownloadRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadsTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDatabase,
      $DownloadsTable,
      DownloadRow,
      $$DownloadsTableFilterComposer,
      $$DownloadsTableOrderingComposer,
      $$DownloadsTableAnnotationComposer,
      $$DownloadsTableCreateCompanionBuilder,
      $$DownloadsTableUpdateCompanionBuilder,
      (
        DownloadRow,
        BaseReferences<_$LibraryDatabase, $DownloadsTable, DownloadRow>,
      ),
      DownloadRow,
      PrefetchHooks Function()
    >;
typedef $$VersionsTableCreateCompanionBuilder =
    VersionsCompanion Function({
      Value<int> id,
      required int threadId,
      required String value,
      Value<DateTime?> releasedAt,
    });
typedef $$VersionsTableUpdateCompanionBuilder =
    VersionsCompanion Function({
      Value<int> id,
      Value<int> threadId,
      Value<String> value,
      Value<DateTime?> releasedAt,
    });

class $$VersionsTableFilterComposer
    extends Composer<_$LibraryDatabase, $VersionsTable> {
  $$VersionsTableFilterComposer({
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

  ColumnFilters<int> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get releasedAt => $composableBuilder(
    column: $table.releasedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VersionsTableOrderingComposer
    extends Composer<_$LibraryDatabase, $VersionsTable> {
  $$VersionsTableOrderingComposer({
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

  ColumnOrderings<int> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get releasedAt => $composableBuilder(
    column: $table.releasedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VersionsTableAnnotationComposer
    extends Composer<_$LibraryDatabase, $VersionsTable> {
  $$VersionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get threadId =>
      $composableBuilder(column: $table.threadId, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get releasedAt => $composableBuilder(
    column: $table.releasedAt,
    builder: (column) => column,
  );
}

class $$VersionsTableTableManager
    extends
        RootTableManager<
          _$LibraryDatabase,
          $VersionsTable,
          VersionRow,
          $$VersionsTableFilterComposer,
          $$VersionsTableOrderingComposer,
          $$VersionsTableAnnotationComposer,
          $$VersionsTableCreateCompanionBuilder,
          $$VersionsTableUpdateCompanionBuilder,
          (
            VersionRow,
            BaseReferences<_$LibraryDatabase, $VersionsTable, VersionRow>,
          ),
          VersionRow,
          PrefetchHooks Function()
        > {
  $$VersionsTableTableManager(_$LibraryDatabase db, $VersionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VersionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VersionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VersionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> threadId = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime?> releasedAt = const Value.absent(),
              }) => VersionsCompanion(
                id: id,
                threadId: threadId,
                value: value,
                releasedAt: releasedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int threadId,
                required String value,
                Value<DateTime?> releasedAt = const Value.absent(),
              }) => VersionsCompanion.insert(
                id: id,
                threadId: threadId,
                value: value,
                releasedAt: releasedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VersionsTable, VersionRow>(table),
                  BaseReferences<_$LibraryDatabase, $VersionsTable, VersionRow>(
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

typedef $$VersionsTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDatabase,
      $VersionsTable,
      VersionRow,
      $$VersionsTableFilterComposer,
      $$VersionsTableOrderingComposer,
      $$VersionsTableAnnotationComposer,
      $$VersionsTableCreateCompanionBuilder,
      $$VersionsTableUpdateCompanionBuilder,
      (
        VersionRow,
        BaseReferences<_$LibraryDatabase, $VersionsTable, VersionRow>,
      ),
      VersionRow,
      PrefetchHooks Function()
    >;
typedef $$GameIndexTableCreateCompanionBuilder =
    GameIndexCompanion Function({
      Value<int> threadId,
      required String title,
      required String normalizedTitle,
      Value<String> compactTitle,
      Value<String> creator,
      Value<String> latestVersion,
      Value<String?> cover,
      Value<String> screens,
      Value<String> tags,
      Value<String> prefixes,
      Value<double> rating,
      Value<int> views,
      Value<int> likes,
      Value<int> ts,
      required DateTime cachedAt,
    });
typedef $$GameIndexTableUpdateCompanionBuilder =
    GameIndexCompanion Function({
      Value<int> threadId,
      Value<String> title,
      Value<String> normalizedTitle,
      Value<String> compactTitle,
      Value<String> creator,
      Value<String> latestVersion,
      Value<String?> cover,
      Value<String> screens,
      Value<String> tags,
      Value<String> prefixes,
      Value<double> rating,
      Value<int> views,
      Value<int> likes,
      Value<int> ts,
      Value<DateTime> cachedAt,
    });

class $$GameIndexTableFilterComposer
    extends Composer<_$LibraryDatabase, $GameIndexTable> {
  $$GameIndexTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedTitle => $composableBuilder(
    column: $table.normalizedTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get compactTitle => $composableBuilder(
    column: $table.compactTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creator => $composableBuilder(
    column: $table.creator,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get latestVersion => $composableBuilder(
    column: $table.latestVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get screens => $composableBuilder(
    column: $table.screens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prefixes => $composableBuilder(
    column: $table.prefixes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get views => $composableBuilder(
    column: $table.views,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get likes => $composableBuilder(
    column: $table.likes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GameIndexTableOrderingComposer
    extends Composer<_$LibraryDatabase, $GameIndexTable> {
  $$GameIndexTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedTitle => $composableBuilder(
    column: $table.normalizedTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get compactTitle => $composableBuilder(
    column: $table.compactTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creator => $composableBuilder(
    column: $table.creator,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get latestVersion => $composableBuilder(
    column: $table.latestVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get screens => $composableBuilder(
    column: $table.screens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prefixes => $composableBuilder(
    column: $table.prefixes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get views => $composableBuilder(
    column: $table.views,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get likes => $composableBuilder(
    column: $table.likes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GameIndexTableAnnotationComposer
    extends Composer<_$LibraryDatabase, $GameIndexTable> {
  $$GameIndexTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get threadId =>
      $composableBuilder(column: $table.threadId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get normalizedTitle => $composableBuilder(
    column: $table.normalizedTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get compactTitle => $composableBuilder(
    column: $table.compactTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get creator =>
      $composableBuilder(column: $table.creator, builder: (column) => column);

  GeneratedColumn<String> get latestVersion => $composableBuilder(
    column: $table.latestVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cover =>
      $composableBuilder(column: $table.cover, builder: (column) => column);

  GeneratedColumn<String> get screens =>
      $composableBuilder(column: $table.screens, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get prefixes =>
      $composableBuilder(column: $table.prefixes, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get views =>
      $composableBuilder(column: $table.views, builder: (column) => column);

  GeneratedColumn<int> get likes =>
      $composableBuilder(column: $table.likes, builder: (column) => column);

  GeneratedColumn<int> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$GameIndexTableTableManager
    extends
        RootTableManager<
          _$LibraryDatabase,
          $GameIndexTable,
          GameIndexRow,
          $$GameIndexTableFilterComposer,
          $$GameIndexTableOrderingComposer,
          $$GameIndexTableAnnotationComposer,
          $$GameIndexTableCreateCompanionBuilder,
          $$GameIndexTableUpdateCompanionBuilder,
          (
            GameIndexRow,
            BaseReferences<_$LibraryDatabase, $GameIndexTable, GameIndexRow>,
          ),
          GameIndexRow,
          PrefetchHooks Function()
        > {
  $$GameIndexTableTableManager(_$LibraryDatabase db, $GameIndexTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GameIndexTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GameIndexTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GameIndexTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> threadId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> normalizedTitle = const Value.absent(),
                Value<String> compactTitle = const Value.absent(),
                Value<String> creator = const Value.absent(),
                Value<String> latestVersion = const Value.absent(),
                Value<String?> cover = const Value.absent(),
                Value<String> screens = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String> prefixes = const Value.absent(),
                Value<double> rating = const Value.absent(),
                Value<int> views = const Value.absent(),
                Value<int> likes = const Value.absent(),
                Value<int> ts = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => GameIndexCompanion(
                threadId: threadId,
                title: title,
                normalizedTitle: normalizedTitle,
                compactTitle: compactTitle,
                creator: creator,
                latestVersion: latestVersion,
                cover: cover,
                screens: screens,
                tags: tags,
                prefixes: prefixes,
                rating: rating,
                views: views,
                likes: likes,
                ts: ts,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> threadId = const Value.absent(),
                required String title,
                required String normalizedTitle,
                Value<String> compactTitle = const Value.absent(),
                Value<String> creator = const Value.absent(),
                Value<String> latestVersion = const Value.absent(),
                Value<String?> cover = const Value.absent(),
                Value<String> screens = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String> prefixes = const Value.absent(),
                Value<double> rating = const Value.absent(),
                Value<int> views = const Value.absent(),
                Value<int> likes = const Value.absent(),
                Value<int> ts = const Value.absent(),
                required DateTime cachedAt,
              }) => GameIndexCompanion.insert(
                threadId: threadId,
                title: title,
                normalizedTitle: normalizedTitle,
                compactTitle: compactTitle,
                creator: creator,
                latestVersion: latestVersion,
                cover: cover,
                screens: screens,
                tags: tags,
                prefixes: prefixes,
                rating: rating,
                views: views,
                likes: likes,
                ts: ts,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GameIndexTable, GameIndexRow>(table),
                  BaseReferences<
                    _$LibraryDatabase,
                    $GameIndexTable,
                    GameIndexRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GameIndexTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDatabase,
      $GameIndexTable,
      GameIndexRow,
      $$GameIndexTableFilterComposer,
      $$GameIndexTableOrderingComposer,
      $$GameIndexTableAnnotationComposer,
      $$GameIndexTableCreateCompanionBuilder,
      $$GameIndexTableUpdateCompanionBuilder,
      (
        GameIndexRow,
        BaseReferences<_$LibraryDatabase, $GameIndexTable, GameIndexRow>,
      ),
      GameIndexRow,
      PrefetchHooks Function()
    >;
typedef $$IndexMetaTableCreateCompanionBuilder =
    IndexMetaCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$IndexMetaTableUpdateCompanionBuilder =
    IndexMetaCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$IndexMetaTableFilterComposer
    extends Composer<_$LibraryDatabase, $IndexMetaTable> {
  $$IndexMetaTableFilterComposer({
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

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IndexMetaTableOrderingComposer
    extends Composer<_$LibraryDatabase, $IndexMetaTable> {
  $$IndexMetaTableOrderingComposer({
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

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IndexMetaTableAnnotationComposer
    extends Composer<_$LibraryDatabase, $IndexMetaTable> {
  $$IndexMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$IndexMetaTableTableManager
    extends
        RootTableManager<
          _$LibraryDatabase,
          $IndexMetaTable,
          IndexMetaRow,
          $$IndexMetaTableFilterComposer,
          $$IndexMetaTableOrderingComposer,
          $$IndexMetaTableAnnotationComposer,
          $$IndexMetaTableCreateCompanionBuilder,
          $$IndexMetaTableUpdateCompanionBuilder,
          (
            IndexMetaRow,
            BaseReferences<_$LibraryDatabase, $IndexMetaTable, IndexMetaRow>,
          ),
          IndexMetaRow,
          PrefetchHooks Function()
        > {
  $$IndexMetaTableTableManager(_$LibraryDatabase db, $IndexMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IndexMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IndexMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IndexMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IndexMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => IndexMetaCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IndexMetaTable, IndexMetaRow>(table),
                  BaseReferences<
                    _$LibraryDatabase,
                    $IndexMetaTable,
                    IndexMetaRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IndexMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDatabase,
      $IndexMetaTable,
      IndexMetaRow,
      $$IndexMetaTableFilterComposer,
      $$IndexMetaTableOrderingComposer,
      $$IndexMetaTableAnnotationComposer,
      $$IndexMetaTableCreateCompanionBuilder,
      $$IndexMetaTableUpdateCompanionBuilder,
      (
        IndexMetaRow,
        BaseReferences<_$LibraryDatabase, $IndexMetaTable, IndexMetaRow>,
      ),
      IndexMetaRow,
      PrefetchHooks Function()
    >;
typedef $$PlaySessionsTableCreateCompanionBuilder =
    PlaySessionsCompanion Function({
      Value<int> id,
      required int threadId,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<int?> durationSeconds,
    });
typedef $$PlaySessionsTableUpdateCompanionBuilder =
    PlaySessionsCompanion Function({
      Value<int> id,
      Value<int> threadId,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<int?> durationSeconds,
    });

class $$PlaySessionsTableFilterComposer
    extends Composer<_$LibraryDatabase, $PlaySessionsTable> {
  $$PlaySessionsTableFilterComposer({
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

  ColumnFilters<int> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlaySessionsTableOrderingComposer
    extends Composer<_$LibraryDatabase, $PlaySessionsTable> {
  $$PlaySessionsTableOrderingComposer({
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

  ColumnOrderings<int> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaySessionsTableAnnotationComposer
    extends Composer<_$LibraryDatabase, $PlaySessionsTable> {
  $$PlaySessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get threadId =>
      $composableBuilder(column: $table.threadId, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );
}

class $$PlaySessionsTableTableManager
    extends
        RootTableManager<
          _$LibraryDatabase,
          $PlaySessionsTable,
          PlaySessionRow,
          $$PlaySessionsTableFilterComposer,
          $$PlaySessionsTableOrderingComposer,
          $$PlaySessionsTableAnnotationComposer,
          $$PlaySessionsTableCreateCompanionBuilder,
          $$PlaySessionsTableUpdateCompanionBuilder,
          (
            PlaySessionRow,
            BaseReferences<
              _$LibraryDatabase,
              $PlaySessionsTable,
              PlaySessionRow
            >,
          ),
          PlaySessionRow,
          PrefetchHooks Function()
        > {
  $$PlaySessionsTableTableManager(
    _$LibraryDatabase db,
    $PlaySessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaySessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaySessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaySessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> threadId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
              }) => PlaySessionsCompanion(
                id: id,
                threadId: threadId,
                startedAt: startedAt,
                endedAt: endedAt,
                durationSeconds: durationSeconds,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int threadId,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
              }) => PlaySessionsCompanion.insert(
                id: id,
                threadId: threadId,
                startedAt: startedAt,
                endedAt: endedAt,
                durationSeconds: durationSeconds,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaySessionsTable, PlaySessionRow>(table),
                  BaseReferences<
                    _$LibraryDatabase,
                    $PlaySessionsTable,
                    PlaySessionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlaySessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDatabase,
      $PlaySessionsTable,
      PlaySessionRow,
      $$PlaySessionsTableFilterComposer,
      $$PlaySessionsTableOrderingComposer,
      $$PlaySessionsTableAnnotationComposer,
      $$PlaySessionsTableCreateCompanionBuilder,
      $$PlaySessionsTableUpdateCompanionBuilder,
      (
        PlaySessionRow,
        BaseReferences<_$LibraryDatabase, $PlaySessionsTable, PlaySessionRow>,
      ),
      PlaySessionRow,
      PrefetchHooks Function()
    >;

class $LibraryDatabaseManager {
  final _$LibraryDatabase _db;
  $LibraryDatabaseManager(this._db);
  $$GamesTableTableManager get games =>
      $$GamesTableTableManager(_db, _db.games);
  $$DownloadsTableTableManager get downloads =>
      $$DownloadsTableTableManager(_db, _db.downloads);
  $$VersionsTableTableManager get versions =>
      $$VersionsTableTableManager(_db, _db.versions);
  $$GameIndexTableTableManager get gameIndex =>
      $$GameIndexTableTableManager(_db, _db.gameIndex);
  $$IndexMetaTableTableManager get indexMeta =>
      $$IndexMetaTableTableManager(_db, _db.indexMeta);
  $$PlaySessionsTableTableManager get playSessions =>
      $$PlaySessionsTableTableManager(_db, _db.playSessions);
}
