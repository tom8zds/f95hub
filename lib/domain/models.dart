/// Pure domain types for f95hub: no I/O and no Flutter dependencies.
///
/// These are the shapes the three ports (MetadataSource, DownloadEngine,
/// LibraryStore) exchange. Adapters live behind those ports; nothing in here
/// talks to the network, disk, or database.
library;

/// f95zone game categories. Only [GameCategory.games] is in scope for v1.
enum GameCategory { games, comics, animations, assets }

/// A released version of a game, kept as free text.
///
/// Version strings are deliberately *not* parsed or compared — the app only
/// displays local vs. latest side by side (see spec "Implementation Decisions").
class Version {
  const Version({required this.value, this.releasedAt});

  /// Free-text version string, e.g. `v0.0.1`.
  final String value;

  /// When this version was released, if known.
  final DateTime? releasedAt;

  @override
  bool operator ==(Object other) =>
      other is Version &&
      other.value == value &&
      other.releasedAt == releasedAt;

  @override
  int get hashCode => Object.hash(value, releasedAt);

  @override
  String toString() => 'Version($value)';
}

/// A game in the local library: metadata scraped from f95zone plus local
/// install information.
///
/// [threadId] is the unique key linking this entry back to f95zone metadata.
/// [version] is the locally installed version; [latestVersion] is what f95zone
/// currently reports. [tags] are resolved *names* (the scraper maps numeric ids
/// through the static tag table).
class Game {
  const Game({
    required this.threadId,
    required this.title,
    required this.creator,
    this.version = '',
    this.latestVersion = '',
    this.cover,
    this.screens = const [],
    this.tags = const [],
    this.tagIds = const [],
    this.prefixIds = const [],
    this.engine = '',
    this.developer = '',
    this.description = '',
    this.installPath,
    this.launchPath,
    this.rating = 0,
    this.views = 0,
    this.likes = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final int threadId;
  final String title;
  final String creator;

  final String version;
  final String latestVersion;

  /// The version to display: f95zone's [latestVersion] when known, else the
  /// locally installed [version] (spec "并列显示本地 vs 最新").
  String get displayVersion =>
      latestVersion.isNotEmpty ? latestVersion : version;

  /// Returns a copy with [tags] resolved from [tagIds] via [table].
  ///
  /// The listing exposes only numeric tag ids; this maps them to names for
  /// display. A game with no tag ids is returned unchanged (avoiding a
  /// needless allocation and preserving any already-resolved names).
  Game withResolvedTags(TagTable table) {
    if (tagIds.isEmpty) {
      return this;
    }
    return Game(
      threadId: threadId,
      title: title,
      creator: creator,
      version: version,
      latestVersion: latestVersion,
      cover: cover,
      screens: screens,
      tags: table.tagNamesFor(tagIds),
      tagIds: tagIds,
      prefixIds: prefixIds,
      engine: engine,
      developer: developer,
      description: description,
      installPath: installPath,
      launchPath: launchPath,
      rating: rating,
      views: views,
      likes: likes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Average f95zone rating (`0` = unrated), from the listing.
  final double rating;

  /// f95zone view count, from the listing.
  final int views;

  /// f95zone like count, from the listing.
  final int likes;

  /// Absolute cover image URL, if any.
  final String? cover;

  /// Absolute screenshot URLs.
  final List<String> screens;

  /// Resolved tag names.
  final List<String> tags;

  /// Numeric f95zone tag ids (resolved to [tags] via the static tag table).
  final List<int> tagIds;

  /// Numeric f95zone prefix ids (resolved to engine/category via the table).
  final List<int> prefixIds;

  final String engine;
  final String developer;
  final String description;

  /// Local directory where the game is installed, if downloaded/imported.
  final String? installPath;

  /// Absolute path of the executable (`.exe`/`.bat`) chosen as this game's
  /// launch entry, if the user picked one.
  final String? launchPath;

  /// Whether this game has a remembered launch entry to start from.
  bool get hasLaunchPath => launchPath != null && launchPath!.isNotEmpty;

  /// Returns a copy of this game with [launchPath] replaced (or cleared when
  /// null/blank).
  Game withLaunchPath(String? launchPath) {
    final next = launchPath == null || launchPath.trim().isEmpty
        ? null
        : launchPath;
    return Game(
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
      launchPath: next,
      rating: rating,
      views: views,
      likes: likes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Returns a copy of this game with [version] replaced.
  ///
  /// The version is free text and is stored verbatim: it may be empty (the
  /// user clearing the local version) because f95zone versions themselves are
  /// unparsed free text.
  Game withVersion(String version) {
    return Game(
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
      rating: rating,
      views: views,
      likes: likes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  final DateTime createdAt;
  final DateTime updatedAt;
}

/// One played session of a library game.
///
/// A session is inserted when the game process starts ([endedAt] and
/// [durationSeconds] still null) and closed when it exits. [durationSeconds] is
/// stored rather than derived so a historic session stays stable even if the
/// wall clock shifts.
class PlaySession {
  const PlaySession({
    this.id,
    required this.threadId,
    required this.startedAt,
    this.endedAt,
    this.durationSeconds,
  });

  /// Database id; null until [PlaySession] has been inserted.
  final int? id;

  final int threadId;
  final DateTime startedAt;

  /// When the process exited, or null while the game is still running.
  final DateTime? endedAt;

  /// Length of the session in whole seconds, or null while still running.
  final int? durationSeconds;

  bool get isRunning => endedAt == null;

  /// The recorded duration, or null while the session is still open.
  Duration? get duration => durationSeconds == null
      ? null
      : Duration(seconds: durationSeconds!);

  PlaySession copyWith({
    int? id,
    DateTime? endedAt,
    int? durationSeconds,
  }) {
    return PlaySession(
      id: id ?? this.id,
      threadId: threadId,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }
}

/// Aggregated playtime for one library game: the total time plus its sessions,
/// newest first.
class PlayStats {
  const PlayStats({this.total = Duration.zero, this.sessions = const []});

  final Duration total;
  final List<PlaySession> sessions;

  bool get isEmpty => sessions.isEmpty;
}

/// Aggregate playtime across the whole library, for the dashboard.
class LibraryPlaytime {
  const LibraryPlaytime({this.total = Duration.zero, this.gamesPlayed = 0});

  final Duration total;

  /// Number of library games with at least one recorded session.
  final int gamesPlayed;
}

/// Lifecycle status of a download task.
enum DownloadStatus { queued, active, paused, complete, error, removed }

/// A download task (backed by an aria2 gid) for a game thread.
class Download {
  const Download({
    required this.gid,
    required this.threadId,
    required this.status,
    required this.progress,
    required this.targetDir,
    required this.createdAt,
    required this.updatedAt,
  });

  /// aria2 download identifier.
  final String gid;

  /// f95zone thread this download belongs to.
  final int threadId;

  final DownloadStatus status;

  /// Completion ratio in `0.0 .. 1.0`.
  final double progress;

  final String targetDir;

  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Details for a single f95zone thread, scraped from its XenForo thread page.
///
/// The listing only exposes `thread_id`/`title`/`version`/`cover`/`screens`
/// plus numeric tag/prefix ids; the human-readable [description] lives on the
/// thread page (`og:description` or the first post's `bbWrapper`).
class ThreadDetail {
  const ThreadDetail({
    required this.threadId,
    required this.title,
    this.description = '',
  });

  final int threadId;
  final String title;
  final String description;
}

/// One prefix within a [PrefixGroup].
class Prefix {
  const Prefix({required this.id, required this.name});

  final int id;
  final String name;
}

/// A named group of prefixes (e.g. `Engine`, `Other`, `Status` for games).
class PrefixGroup {
  const PrefixGroup({
    required this.id,
    required this.name,
    required this.prefixes,
  });

  final int id;
  final String name;
  final List<Prefix> prefixes;
}

/// Static f95zone id→name table, parsed from the inline `var latestUpdates`
/// object on the `/latest` page (research 01 §4).
///
/// Tags are a flat `{id: name}` map. Prefixes are hierarchical: each
/// [GameCategory] has a list of [PrefixGroup]s, each holding [Prefix]es. The
/// numeric id namespace is *shared* across groups/categories, so a prefix id
/// only means something within its category — hence [prefixName] takes a
/// category.
class TagTable {
  const TagTable({required this.tags, required this.prefixes});

  /// Flat tag id → name map (153 entries for the current site).
  final Map<int, String> tags;

  /// Prefix groups keyed by category.
  final Map<GameCategory, List<PrefixGroup>> prefixes;

  /// The prefix groups for [cat], or an empty list when [cat] is unknown.
  ///
  /// Order is preserved as captured (research 01 §4.2). The games listing uses
  /// this to build its 类别/引擎/状态 filter sections from the `Other`/`Engine`/
  /// `Status` groups.
  List<PrefixGroup> prefixGroupItems(GameCategory cat) =>
      prefixes[cat] ?? const <PrefixGroup>[];

  /// Resolves a tag id to its name, or null when unknown.
  String? tagName(int id) => tags[id];

  /// Resolves [ids] to tag names, dropping ids that aren't in the table.
  List<String> tagNamesFor(Iterable<int> ids) =>
      ids.map(tagName).whereType<String>().toList(growable: false);

  /// The flat tags as an ordered `(id, name)` list, mirroring
  /// [prefixGroupItems] for prefixes. Order is preserved as captured
  /// (research 01 §4.1).
  List<({int id, String name})> tagItems() =>
      [for (final e in tags.entries) (id: e.key, name: e.value)];

  /// Resolves [ids] to `(group, name)` pairs within [cat], dropping unknown
  /// ids. The numeric id namespace is shared across groups/categories, so
  /// lookup always scans [cat]'s own group structure.
  List<({String? group, String name})> prefixesFor(
    GameCategory cat,
    Iterable<int> ids,
  ) => ids
          .map((id) => prefixName(cat, id))
          .whereType<({String? group, String name})>()
          .toList(growable: false);

  /// Resolves a prefix id to `(group, name)` within [cat], or null.
  ///
  /// The same integer can name different things across categories (e.g. id
  /// `3` is `Unity` under the games "Engine" group but `Other` as a group
  /// id), so lookup always scans [cat]'s own group structure.
  ({String? group, String name})? prefixName(GameCategory cat, int id) {
    final groups = prefixes[cat];
    if (groups == null) {
      return null;
    }
    for (final group in groups) {
      for (final prefix in group.prefixes) {
        if (prefix.id == id) {
          return (group: group.name, name: prefix.name);
        }
      }
    }
    return null;
  }
}
