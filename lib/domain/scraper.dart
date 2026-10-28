import 'models.dart';

/// Maps f95zone data onto a library-ready [Game].
///
/// The listing already carries the raw fields (`title`/`creator`/`latestVersion`/
/// `cover`/`screens`/`tagIds`/`prefixIds`); scraping adds what only the tag
/// table and thread page know: resolved tag names, the engine (from the
/// "Engine" prefix group), and the human-readable description.
///
/// The local [Game.version] defaults to the listing's (empty until the game is
/// downloaded/imported) unless [version] overrides it; [installPath] is only
/// set for manual imports.
Game scrapeToLibraryGame(
  Game listing,
  ThreadDetail thread,
  TagTable table, {
  String? installPath,
  String? version,
  DateTime? now,
}) {
  final resolved = _resolve(listing, table);
  final ts = now ?? DateTime.now();

  return Game(
    threadId: listing.threadId,
    title: listing.title.isNotEmpty ? listing.title : thread.title,
    creator: listing.creator,
    version: version ?? listing.version,
    latestVersion: listing.latestVersion,
    cover: listing.cover,
    screens: listing.screens,
    tags: resolved.tags,
    tagIds: listing.tagIds,
    prefixIds: listing.prefixIds,
    engine: resolved.engines.join(', '),
    developer: listing.developer,
    description: thread.description,
    installPath: installPath,
    rating: listing.rating,
    views: listing.views,
    likes: listing.likes,
    createdAt: ts,
    updatedAt: ts,
  );
}

/// Best-effort parse of a game version from a folder name, e.g.
/// `DevotedWife-0.56-pc` → `0.56`. Returns an empty string when no
/// dotted-numeric version token is found.
///
/// Tolerates a full path (only the last path segment is examined) and an
/// optional `v`/`V` prefix; a bare number with no dot is left unparsed so
/// years/dates in folder names don't masquerade as versions.
String parseVersionFromName(String name) {
  final base = name.replaceAll('\\', '/').split('/').last;
  final match = RegExp(r'[vV]?\d+(?:\.\d+)+').firstMatch(base);
  return match?.group(0) ?? '';
}

/// Trailing date sequence: a 19xx/20xx year followed by one or two numeric
/// month/day parts (`2025 11 14`, `2025-11`, …). Applied after separators are
/// collapsed to spaces, so every separator style is covered.
final _trailingDate = RegExp(r'(?:^|\s)(?:19|20)\d{2}(?:\s+\d{1,2}){1,2}$');

/// Parses a folder name into a clean title + numeric version.
///
/// Only the last path segment is examined (a full path is tolerated). The
/// version is the first dotted-numeric token (optionally `v`/`V`-prefixed,
/// returned *without* the prefix); the title is that segment with the version
/// token, a trailing date (`2025 11 14`, `2025-11-14`, `2025_11_14`,
/// `2025.11.14`, …) and common packaging noise (platform, language, Patreon,
/// demo/alpha/beta, …) removed, brackets/parens/dashes collapsed, and
/// whitespace normalized. The title is empty when nothing usable remains.
({String title, String version}) parseFolderName(String name) {
  final base = name.replaceAll('\\', '/').split('/').last;
  final match = RegExp(r'[vV]?\d+(?:\.\d+)+').firstMatch(base);
  final version =
      match == null ? '' : match.group(0)!.replaceFirst(RegExp(r'^[vV]'), '');

  var title = base;
  if (match != null) {
    title = title.replaceRange(match.start, match.end, ' ');
  }
  title = title
      .replaceAll(
        RegExp(
          r'\b(patreon|english|en|uncensored|pc|win|windows|mac|linux|android|walkthrough|final|demo|alpha|beta|early\s*access)\b',
          caseSensitive: false,
        ),
        ' ',
      )
      .replaceAll(RegExp(r'[\[\]()_-]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceFirst(_trailingDate, ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return (title: title, version: version);
}

/// Normalizes a f95zone thread title for matching: strips a leading category
/// prefix (`Others - `, `Ren'Py - `, …) and every `[...]` bracket group
/// (version/creator tags), then collapses and trims whitespace.
String normalizeThreadTitle(String title) {
  return title
      .replaceFirst(RegExp(r'^[^-]+ - '), '')
      .replaceAll(RegExp(r'\[[^\]]*\]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Resolved display names for a game's numeric ids (see [scrapeToLibraryGame]).
class ResolvedScrape {
  const ResolvedScrape({required this.tags, required this.engines});

  final List<String> tags;

  /// Prefix names under the "Engine" group (e.g. `Unity`, `Ren'Py`).
  final List<String> engines;
}

/// Resolves tag ids to names and prefix ids to engine names.
ResolvedScrape _resolve(Game listing, TagTable table) {
  final engines = table
      .prefixesFor(GameCategory.games, listing.prefixIds)
      .where((p) => p.group == 'Engine')
      .map((p) => p.name)
      .toList(growable: false);

  return ResolvedScrape(
    tags: listing.withResolvedTags(table).tags,
    engines: engines,
  );
}
