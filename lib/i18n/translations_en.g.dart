///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'translations.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	dynamic operator[](String key) => _meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$app$en app = Translations$app$en.internal(_root);
	late final Translations$nav$en nav = Translations$nav$en.internal(_root);
	late final Translations$common$en common = Translations$common$en.internal(_root);
	late final Translations$buttons$en buttons = Translations$buttons$en.internal(_root);
	late final Translations$settings$en settings = Translations$settings$en.internal(_root);
	late final Translations$languages$en languages = Translations$languages$en.internal(_root);
	late final Translations$theme$en theme = Translations$theme$en.internal(_root);
	late final Translations$cache$en cache = Translations$cache$en.internal(_root);
	late final Translations$games$en games = Translations$games$en.internal(_root);
	late final Translations$sort$en sort = Translations$sort$en.internal(_root);
	late final Translations$filters$en filters = Translations$filters$en.internal(_root);
	late final Translations$pagination$en pagination = Translations$pagination$en.internal(_root);
	late final Translations$library$en library = Translations$library$en.internal(_root);
	late final Translations$detail$en detail = Translations$detail$en.internal(_root);
	late final Translations$downloads$en downloads = Translations$downloads$en.internal(_root);
	late final Translations$mirrors$en mirrors = Translations$mirrors$en.internal(_root);
	late final Translations$import$en import = Translations$import$en.internal(_root);
	late final Translations$setup$en setup = Translations$setup$en.internal(_root);
	late final Translations$gallery$en gallery = Translations$gallery$en.internal(_root);
	late final Translations$dashboard$en dashboard = Translations$dashboard$en.internal(_root);
	late final Translations$time$en time = Translations$time$en.internal(_root);
}

// Path: app
class Translations$app$en {
	Translations$app$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'f95hub'
	String get title => 'f95hub';

	/// en: 'Failed to load configuration'
	String get loadConfigFailed => 'Failed to load configuration';
}

// Path: nav
class Translations$nav$en {
	Translations$nav$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Games'
	String get games => 'Games';

	/// en: 'Library'
	String get library => 'Library';

	/// en: 'Downloads'
	String get downloads => 'Downloads';

	/// en: 'Settings'
	String get settings => 'Settings';

	/// en: 'Dashboard'
	String get dashboard => 'Dashboard';
}

// Path: common
class Translations$common$en {
	Translations$common$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Retry'
	String get retry => 'Retry';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Apply'
	String get apply => 'Apply';

	/// en: 'Browse'
	String get browse => 'Browse';

	/// en: 'Close'
	String get close => 'Close';

	/// en: 'Previous'
	String get previous => 'Previous';

	/// en: 'Next'
	String get next => 'Next';

	/// en: 'Add'
	String get add => 'Add';

	/// en: 'Download'
	String get download => 'Download';

	/// en: 'All'
	String get all => 'All';

	/// en: 'none'
	String get none => 'none';

	/// en: 'No matches'
	String get noMatches => 'No matches';

	/// en: 'Save'
	String get save => 'Save';

	/// en: 'View detail'
	String get viewDetail => 'View detail';
}

// Path: buttons
class Translations$buttons$en {
	Translations$buttons$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Create cache'
	String get createCache => 'Create cache';

	/// en: 'Continue build'
	String get continueBuild => 'Continue build';

	/// en: 'Refresh cache'
	String get refreshCache => 'Refresh cache';

	/// en: 'Delete cache'
	String get deleteCache => 'Delete cache';

	/// en: 'Finish'
	String get finish => 'Finish';

	/// en: 'Log in'
	String get logIn => 'Log in';

	/// en: 'Log out'
	String get logOut => 'Log out';

	/// en: 'Import game'
	String get importGame => 'Import game';

	/// en: 'Add to library'
	String get addToLibrary => 'Add to library';

	/// en: 'Open in browser'
	String get openInBrowser => 'Open in browser';

	/// en: 'Open folder'
	String get openFolder => 'Open folder';

	/// en: 'Launch game'
	String get launchGame => 'Launch game';

	/// en: 'Remove'
	String get remove => 'Remove';

	/// en: 'Keep files'
	String get keepFiles => 'Keep files';

	/// en: 'Delete files'
	String get deleteFiles => 'Delete files';

	/// en: 'Import selected ({count})'
	String importSelected({required Object count}) => 'Import selected (${count})';
}

// Path: settings
class Translations$settings$en {
	Translations$settings$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Settings'
	String get title => 'Settings';

	/// en: 'Language'
	String get language => 'Language';

	/// en: 'Theme'
	String get theme => 'Theme';

	late final Translations$settings$storage$en storage = Translations$settings$storage$en.internal(_root);
	late final Translations$settings$network$en network = Translations$settings$network$en.internal(_root);
	late final Translations$settings$aria2$en aria2 = Translations$settings$aria2$en.internal(_root);
	late final Translations$settings$login$en login = Translations$settings$login$en.internal(_root);
	late final Translations$settings$about$en about = Translations$settings$about$en.internal(_root);
}

// Path: languages
class Translations$languages$en {
	Translations$languages$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'System'
	String get system => 'System';

	/// en: 'English'
	String get en => 'English';

	/// en: '中文'
	String get zh => '中文';
}

// Path: theme
class Translations$theme$en {
	Translations$theme$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Dark theme'
	String get dark => 'Dark theme';

	/// en: 'Switch to light theme'
	String get switchToLight => 'Switch to light theme';

	/// en: 'Switch to dark theme'
	String get switchToDark => 'Switch to dark theme';

	late final Translations$theme$presets$en presets = Translations$theme$presets$en.internal(_root);
}

// Path: cache
class Translations$cache$en {
	Translations$cache$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Cache'
	String get title => 'Cache';

	/// en: '(one) {1 game cached} (other) {{n} games cached}'
	String gamesCached({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '1 game cached',
		other: '${n} games cached',
	);

	/// en: 'Last updated: never'
	String get lastUpdatedNever => 'Last updated: never';

	/// en: 'Last updated: {date}'
	String lastUpdated({required Object date}) => 'Last updated: ${date}';

	/// en: 'Reached {page} / {total} pages'
	String reached({required Object page, required Object total}) => 'Reached ${page} / ${total} pages';

	/// en: 'Page {page} / {total}'
	String page({required Object page, required Object total}) => 'Page ${page} / ${total}';

	/// en: 'Fetching page count…'
	String get fetchingPageCount => 'Fetching page count…';

	/// en: 'Cache operation failed: {error}'
	String failed({required Object error}) => 'Cache operation failed: ${error}';
}

// Path: games
class Translations$games$en {
	Translations$games$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Search games'
	String get searchHint => 'Search games';

	/// en: 'Filters'
	String get filters => 'Filters';

	/// en: 'Sort'
	String get sort => 'Sort';

	/// en: 'Refresh'
	String get refresh => 'Refresh';

	/// en: 'Rate limited, retrying'
	String get throttled => 'Rate limited, retrying';

	/// en: 'Failed to load games'
	String get loadFailed => 'Failed to load games';

	/// en: 'No games'
	String get empty => 'No games';

	/// en: 'Failed to load the game index'
	String get indexLoadFailed => 'Failed to load the game index';

	/// en: 'Game index is empty'
	String get indexEmptyTitle => 'Game index is empty';

	/// en: 'Build the game cache in Settings to search the whole catalogue offline.'
	String get indexEmptyMessage => 'Build the game cache in Settings to search the whole catalogue offline.';

	/// en: 'Search by title'
	String get searchByTitle => 'Search by title';
}

// Path: sort
class Translations$sort$en {
	Translations$sort$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Sort'
	String get heading => 'Sort';

	/// en: 'Date'
	String get date => 'Date';

	/// en: 'Likes'
	String get likes => 'Likes';

	/// en: 'Views'
	String get views => 'Views';

	/// en: 'Title'
	String get title => 'Title';

	/// en: 'Rating'
	String get rating => 'Rating';
}

// Path: filters
class Translations$filters$en {
	Translations$filters$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Filters'
	String get title => 'Filters';

	/// en: 'Category'
	String get category => 'Category';

	/// en: 'Engine'
	String get engine => 'Engine';

	/// en: 'Status'
	String get status => 'Status';

	/// en: 'All'
	String get all => 'All';

	/// en: 'Search'
	String get search => 'Search';

	/// en: 'Clear'
	String get clear => 'Clear';

	late final Translations$filters$date$en date = Translations$filters$date$en.internal(_root);
}

// Path: pagination
class Translations$pagination$en {
	Translations$pagination$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Previous'
	String get previous => 'Previous';

	/// en: 'Next'
	String get next => 'Next';

	/// en: 'Page {page} / {total}'
	String page({required Object page, required Object total}) => 'Page ${page} / ${total}';
}

// Path: library
class Translations$library$en {
	Translations$library$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Library'
	String get title => 'Library';

	/// en: 'Import a local folder'
	String get importFolder => 'Import a local folder';

	/// en: 'Import from a directory'
	String get importFromDirectory => 'Import from a directory';

	/// en: 'Failed to load library'
	String get loadFailed => 'Failed to load library';

	/// en: 'No games in your library yet'
	String get empty => 'No games in your library yet';

	/// en: 'Search library'
	String get searchHint => 'Search library';

	/// en: 'Filters'
	String get filters => 'Filters';

	/// en: 'Sort'
	String get sort => 'Sort';

	/// en: 'Tags'
	String get tags => 'Tags';

	/// en: 'Updates only'
	String get onlyUpdates => 'Updates only';

	/// en: 'Title'
	String get sortTitle => 'Title';

	/// en: 'Recently updated'
	String get sortUpdated => 'Recently updated';

	/// en: 'Recently added'
	String get sortAdded => 'Recently added';

	/// en: 'Update available'
	String get hasUpdate => 'Update available';

	/// en: 'Local'
	String get versionLocal => 'Local';

	/// en: 'Latest'
	String get versionLatest => 'Latest';

	/// en: 'Different'
	String get versionDifferent => 'Different';

	/// en: 'Edit version'
	String get editVersion => 'Edit version';

	/// en: 'Edit local version'
	String get editVersionTitle => 'Edit local version';

	/// en: 'Version'
	String get versionFieldLabel => 'Version';

	/// en: 'Remove game'
	String get removeTitle => 'Remove game';

	/// en: 'Remove "{title}" from your library?'
	String removeConfirm({required Object title}) => 'Remove "${title}" from your library?';

	/// en: 'Failed to remove: {error}'
	String removeFailed({required Object error}) => 'Failed to remove: ${error}';

	/// en: 'Play time'
	String get playTime => 'Play time';

	/// en: 'Total: {duration}'
	String totalPlayTime({required Object duration}) => 'Total: ${duration}';

	/// en: 'Sessions'
	String get playSessions => 'Sessions';

	/// en: 'No play sessions yet'
	String get noPlaySessions => 'No play sessions yet';

	/// en: 'Launch entry'
	String get launchEntry => 'Launch entry';

	/// en: 'Not selected'
	String get noLaunchEntry => 'Not selected';

	/// en: 'Choose launch entry'
	String get chooseLaunchEntry => 'Choose launch entry';

	/// en: 'Change'
	String get changeLaunchEntry => 'Change';

	/// en: 'No .exe or .bat found in the install folder'
	String get noLaunchEntries => 'No .exe or .bat found in the install folder';

	/// en: 'In progress'
	String get inProgress => 'In progress';

	/// en: 'Failed to launch: {error}'
	String launchFailed({required Object error}) => 'Failed to launch: ${error}';
}

// Path: detail
class Translations$detail$en {
	Translations$detail$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Failed to load details'
	String get loadFailed => 'Failed to load details';

	/// en: 'Screenshots'
	String get screenshots => 'Screenshots';

	/// en: 'Tags'
	String get tags => 'Tags';

	/// en: 'Category'
	String get category => 'Category';

	/// en: 'Engine'
	String get engine => 'Engine';

	/// en: 'Developer'
	String get developer => 'Developer';

	/// en: 'Version'
	String get version => 'Version';

	/// en: 'Release date'
	String get releaseDate => 'Release date';

	/// en: 'Last updated'
	String get lastUpdated => 'Last updated';

	/// en: 'Author'
	String get author => 'Author';

	/// en: 'Description'
	String get description => 'Description';

	/// en: 'Download links'
	String get downloadLinks => 'Download links';
}

// Path: downloads
class Translations$downloads$en {
	Translations$downloads$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Downloads'
	String get title => 'Downloads';

	/// en: 'No downloads yet'
	String get empty => 'No downloads yet';

	/// en: 'Global speed limit'
	String get globalSpeedLimit => 'Global speed limit';

	/// en: 'Per-task speed limit'
	String get perTaskSpeedLimit => 'Per-task speed limit';

	/// en: 'No limit'
	String get noLimit => 'No limit';

	/// en: 'Pause'
	String get pause => 'Pause';

	/// en: 'Resume'
	String get resume => 'Resume';

	late final Translations$downloads$status$en status = Translations$downloads$status$en.internal(_root);
}

// Path: mirrors
class Translations$mirrors$en {
	Translations$mirrors$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Not logged in — log in to f95zone to view download links'
	String get notLoggedIn => 'Not logged in — log in to f95zone to view download links';

	/// en: 'Failed to load download links'
	String get loadFailed => 'Failed to load download links';

	/// en: 'No download links'
	String get empty => 'No download links';

	/// en: 'Unsupported'
	String get unsupported => 'Unsupported';

	/// en: 'Downloadable'
	String get supported => 'Downloadable';

	late final Translations$mirrors$kind$en kind = Translations$mirrors$kind$en.internal(_root);
}

// Path: import
class Translations$import$en {
	Translations$import$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Import game'
	String get title => 'Import game';

	/// en: 'Directory import'
	String get directoryTitle => 'Directory import';

	/// en: 'Choose a different folder'
	String get chooseDifferentFolder => 'Choose a different folder';

	/// en: 'Pick a folder to scan'
	String get pickFolder => 'Pick a folder to scan';

	/// en: 'Failed to scan folder'
	String get scanFailed => 'Failed to scan folder';

	/// en: 'No importable folders found'
	String get noFolders => 'No importable folders found';

	/// en: 'Scanned folders'
	String get leftTitle => 'Scanned folders';

	/// en: 'Matched ({count})'
	String rightTitle({required Object count}) => 'Matched (${count})';

	/// en: 'No folders left to match'
	String get leftEmpty => 'No folders left to match';

	/// en: 'Select a folder on the left to match it'
	String get rightEmpty => 'Select a folder on the left to match it';

	/// en: 'Import ({count})'
	String importRight({required Object count}) => 'Import (${count})';

	/// en: 'Associate f95zone game'
	String get associateTitle => 'Associate f95zone game';

	/// en: 'Install path (optional)'
	String get installPath => 'Install path (optional)';

	/// en: 'Local version (optional)'
	String get localVersion => 'Local version (optional)';

	/// en: 'Scraping…'
	String get scraping => 'Scraping…';

	/// en: 'Matched'
	String get matched => 'Matched';

	/// en: 'Not matched'
	String get noMatch => 'Not matched';

	/// en: 'Change matched game'
	String get changeMatch => 'Change matched game';

	/// en: 'Cache has {built}/{total} pages — later letters may be missing'
	String cacheIncomplete({required Object built, required Object total}) => 'Cache has ${built}/${total} pages — later letters may be missing';

	/// en: 'Imported: {title}'
	String imported({required Object title}) => 'Imported: ${title}';

	/// en: 'Cancelled'
	String get cancelled => 'Cancelled';

	/// en: 'Failed: {error}'
	String failed({required Object error}) => 'Failed: ${error}';

	/// en: 'Failed to import: {error}'
	String failedImport({required Object error}) => 'Failed to import: ${error}';

	/// en: 'Added to library'
	String get added => 'Added to library';

	/// en: 'Failed to add: {error}'
	String addFailed({required Object error}) => 'Failed to add: ${error}';

	/// en: 'Auto-matching folders {done}/{total}'
	String autoMatching({required Object done, required Object total}) => 'Auto-matching folders ${done}/${total}';
}

// Path: setup
class Translations$setup$en {
	Translations$setup$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Setup'
	String get title => 'Setup';

	/// en: 'Welcome to f95hub. Configure your download directory and aria2 to get started.'
	String get welcome => 'Welcome to f95hub. Configure your download directory and aria2 to get started.';

	/// en: 'Download directory'
	String get downloadDirectory => 'Download directory';

	/// en: 'No directory selected'
	String get noDirectory => 'No directory selected';

	/// en: 'Speed limits'
	String get speedLimits => 'Speed limits';

	/// en: 'f95zone login (optional)'
	String get loginOptional => 'f95zone login (optional)';
}

// Path: gallery
class Translations$gallery$en {
	Translations$gallery$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Close'
	String get close => 'Close';

	/// en: 'Previous image'
	String get previous => 'Previous image';

	/// en: 'Next image'
	String get next => 'Next image';
}

// Path: dashboard
class Translations$dashboard$en {
	Translations$dashboard$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Library games'
	String get libraryGames => 'Library games';

	/// en: 'Updates available'
	String get updatesAvailable => 'Updates available';

	/// en: 'Download tasks'
	String get downloadTasks => 'Download tasks';

	/// en: 'Game index'
	String get gameIndex => 'Game index';

	/// en: 'Play time'
	String get playTime => 'Play time';

	/// en: 'Games played'
	String get gamesPlayed => 'Games played';

	/// en: 'Last updated: {time}'
	String lastUpdated({required Object time}) => 'Last updated: ${time}';

	/// en: 'never'
	String get never => 'never';

	/// en: 'Manage your local collection'
	String get manageLibrary => 'Manage your local collection';

	/// en: 'Quick access'
	String get quickAccess => 'Quick access';
}

// Path: time
class Translations$time$en {
	Translations$time$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Just now'
	String get justNow => 'Just now';

	/// en: '{n} min ago'
	String minutesAgo({required Object n}) => '${n} min ago';

	/// en: '{n} h ago'
	String hoursAgo({required Object n}) => '${n} h ago';

	/// en: '{n} d ago'
	String daysAgo({required Object n}) => '${n} d ago';

	/// en: '{n} w ago'
	String weeksAgo({required Object n}) => '${n} w ago';

	/// en: '{n} mo ago'
	String monthsAgo({required Object n}) => '${n} mo ago';

	/// en: '{n} y ago'
	String yearsAgo({required Object n}) => '${n} y ago';
}

// Path: settings.storage
class Translations$settings$storage$en {
	Translations$settings$storage$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Storage directory'
	String get title => 'Storage directory';

	/// en: 'No storage directory set'
	String get none => 'No storage directory set';

	/// en: 'Library root falls back to download directory: {path}'
	String fallback({required Object path}) => 'Library root falls back to download directory: ${path}';
}

// Path: settings.network
class Translations$settings$network$en {
	Translations$settings$network$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Network'
	String get title => 'Network';

	/// en: 'Fetch interval (seconds)'
	String get fetchInterval => 'Fetch interval (seconds)';

	/// en: 'Minimum gap between two requests; too small may trigger 429. Default 2 seconds.'
	String get fetchIntervalHelp => 'Minimum gap between two requests; too small may trigger 429. Default 2 seconds.';
}

// Path: settings.aria2
class Translations$settings$aria2$en {
	Translations$settings$aria2$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'aria2'
	String get title => 'aria2';

	/// en: 'RPC port'
	String get rpcPort => 'RPC port';

	/// en: 'RPC secret (optional, kept in memory)'
	String get rpcSecret => 'RPC secret (optional, kept in memory)';

	/// en: 'Global limit (e.g. 1M)'
	String get globalLimit => 'Global limit (e.g. 1M)';

	/// en: 'Per-task limit (e.g. 10K)'
	String get perTaskLimit => 'Per-task limit (e.g. 10K)';

	/// en: 'Leave empty for no cap'
	String get noCap => 'Leave empty for no cap';
}

// Path: settings.login
class Translations$settings$login$en {
	Translations$settings$login$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'f95zone login'
	String get title => 'f95zone login';

	/// en: 'Logged in'
	String get loggedIn => 'Logged in';

	/// en: 'Not logged in'
	String get notLoggedIn => 'Not logged in';

	/// en: 'Session cookie'
	String get sessionCookie => 'Session cookie';

	/// en: 'Paste xf_user/cf_clearance from your browser'
	String get sessionCookieHelp => 'Paste xf_user/cf_clearance from your browser';
}

// Path: settings.about
class Translations$settings$about$en {
	Translations$settings$about$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Version {version}'
	String version({required Object version}) => 'Version ${version}';

	/// en: 'Made by {author}'
	String author({required Object author}) => 'Made by ${author}';

	/// en: 'GitHub repository'
	String get github => 'GitHub repository';
}

// Path: theme.presets
class Translations$theme$presets$en {
	Translations$theme$presets$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Black & red'
	String get material => 'Black & red';

	/// en: 'Blue'
	String get blue => 'Blue';

	/// en: 'Green'
	String get green => 'Green';
}

// Path: filters.date
class Translations$filters$date$en {
	Translations$filters$date$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Anytime'
	String get anytime => 'Anytime';

	/// en: 'Today'
	String get today => 'Today';

	/// en: '< 7 days'
	String get last7 => '< 7 days';

	/// en: '< 30 days'
	String get last30 => '< 30 days';
}

// Path: downloads.status
class Translations$downloads$status$en {
	Translations$downloads$status$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Downloading'
	String get active => 'Downloading';

	/// en: 'Queued'
	String get queued => 'Queued';

	/// en: 'Paused'
	String get paused => 'Paused';

	/// en: 'Complete'
	String get complete => 'Complete';

	/// en: 'Error'
	String get error => 'Error';

	/// en: 'Removed'
	String get removed => 'Removed';
}

// Path: mirrors.kind
class Translations$mirrors$kind$en {
	Translations$mirrors$kind$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Direct link'
	String get direct => 'Direct link';

	/// en: 'Magnet'
	String get magnet => 'Magnet';

	/// en: 'Torrent'
	String get torrent => 'Torrent';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'f95hub',
			'app.loadConfigFailed' => 'Failed to load configuration',
			'nav.games' => 'Games',
			'nav.library' => 'Library',
			'nav.downloads' => 'Downloads',
			'nav.settings' => 'Settings',
			'nav.dashboard' => 'Dashboard',
			'common.retry' => 'Retry',
			'common.cancel' => 'Cancel',
			'common.apply' => 'Apply',
			'common.browse' => 'Browse',
			'common.close' => 'Close',
			'common.previous' => 'Previous',
			'common.next' => 'Next',
			'common.add' => 'Add',
			'common.download' => 'Download',
			'common.all' => 'All',
			'common.none' => 'none',
			'common.noMatches' => 'No matches',
			'common.save' => 'Save',
			'common.viewDetail' => 'View detail',
			'buttons.createCache' => 'Create cache',
			'buttons.continueBuild' => 'Continue build',
			'buttons.refreshCache' => 'Refresh cache',
			'buttons.deleteCache' => 'Delete cache',
			'buttons.finish' => 'Finish',
			'buttons.logIn' => 'Log in',
			'buttons.logOut' => 'Log out',
			'buttons.importGame' => 'Import game',
			'buttons.addToLibrary' => 'Add to library',
			'buttons.openInBrowser' => 'Open in browser',
			'buttons.openFolder' => 'Open folder',
			'buttons.launchGame' => 'Launch game',
			'buttons.remove' => 'Remove',
			'buttons.keepFiles' => 'Keep files',
			'buttons.deleteFiles' => 'Delete files',
			'buttons.importSelected' => ({required Object count}) => 'Import selected (${count})',
			'settings.title' => 'Settings',
			'settings.language' => 'Language',
			'settings.theme' => 'Theme',
			'settings.storage.title' => 'Storage directory',
			'settings.storage.none' => 'No storage directory set',
			'settings.storage.fallback' => ({required Object path}) => 'Library root falls back to download directory: ${path}',
			'settings.network.title' => 'Network',
			'settings.network.fetchInterval' => 'Fetch interval (seconds)',
			'settings.network.fetchIntervalHelp' => 'Minimum gap between two requests; too small may trigger 429. Default 2 seconds.',
			'settings.aria2.title' => 'aria2',
			'settings.aria2.rpcPort' => 'RPC port',
			'settings.aria2.rpcSecret' => 'RPC secret (optional, kept in memory)',
			'settings.aria2.globalLimit' => 'Global limit (e.g. 1M)',
			'settings.aria2.perTaskLimit' => 'Per-task limit (e.g. 10K)',
			'settings.aria2.noCap' => 'Leave empty for no cap',
			'settings.login.title' => 'f95zone login',
			'settings.login.loggedIn' => 'Logged in',
			'settings.login.notLoggedIn' => 'Not logged in',
			'settings.login.sessionCookie' => 'Session cookie',
			'settings.login.sessionCookieHelp' => 'Paste xf_user/cf_clearance from your browser',
			'settings.about.version' => ({required Object version}) => 'Version ${version}',
			'settings.about.author' => ({required Object author}) => 'Made by ${author}',
			'settings.about.github' => 'GitHub repository',
			'languages.system' => 'System',
			'languages.en' => 'English',
			'languages.zh' => '中文',
			'theme.dark' => 'Dark theme',
			'theme.switchToLight' => 'Switch to light theme',
			'theme.switchToDark' => 'Switch to dark theme',
			'theme.presets.material' => 'Black & red',
			'theme.presets.blue' => 'Blue',
			'theme.presets.green' => 'Green',
			'cache.title' => 'Cache',
			'cache.gamesCached' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '1 game cached', other: '${n} games cached', ), 
			'cache.lastUpdatedNever' => 'Last updated: never',
			'cache.lastUpdated' => ({required Object date}) => 'Last updated: ${date}',
			'cache.reached' => ({required Object page, required Object total}) => 'Reached ${page} / ${total} pages',
			'cache.page' => ({required Object page, required Object total}) => 'Page ${page} / ${total}',
			'cache.fetchingPageCount' => 'Fetching page count…',
			'cache.failed' => ({required Object error}) => 'Cache operation failed: ${error}',
			'games.searchHint' => 'Search games',
			'games.filters' => 'Filters',
			'games.sort' => 'Sort',
			'games.refresh' => 'Refresh',
			'games.throttled' => 'Rate limited, retrying',
			'games.loadFailed' => 'Failed to load games',
			'games.empty' => 'No games',
			'games.indexLoadFailed' => 'Failed to load the game index',
			'games.indexEmptyTitle' => 'Game index is empty',
			'games.indexEmptyMessage' => 'Build the game cache in Settings to search the whole catalogue offline.',
			'games.searchByTitle' => 'Search by title',
			'sort.heading' => 'Sort',
			'sort.date' => 'Date',
			'sort.likes' => 'Likes',
			'sort.views' => 'Views',
			'sort.title' => 'Title',
			'sort.rating' => 'Rating',
			'filters.title' => 'Filters',
			'filters.category' => 'Category',
			'filters.engine' => 'Engine',
			'filters.status' => 'Status',
			'filters.all' => 'All',
			'filters.search' => 'Search',
			'filters.clear' => 'Clear',
			'filters.date.anytime' => 'Anytime',
			'filters.date.today' => 'Today',
			'filters.date.last7' => '< 7 days',
			'filters.date.last30' => '< 30 days',
			'pagination.previous' => 'Previous',
			'pagination.next' => 'Next',
			'pagination.page' => ({required Object page, required Object total}) => 'Page ${page} / ${total}',
			'library.title' => 'Library',
			'library.importFolder' => 'Import a local folder',
			'library.importFromDirectory' => 'Import from a directory',
			'library.loadFailed' => 'Failed to load library',
			'library.empty' => 'No games in your library yet',
			'library.searchHint' => 'Search library',
			'library.filters' => 'Filters',
			'library.sort' => 'Sort',
			'library.tags' => 'Tags',
			'library.onlyUpdates' => 'Updates only',
			'library.sortTitle' => 'Title',
			'library.sortUpdated' => 'Recently updated',
			'library.sortAdded' => 'Recently added',
			'library.hasUpdate' => 'Update available',
			'library.versionLocal' => 'Local',
			'library.versionLatest' => 'Latest',
			'library.versionDifferent' => 'Different',
			'library.editVersion' => 'Edit version',
			'library.editVersionTitle' => 'Edit local version',
			'library.versionFieldLabel' => 'Version',
			'library.removeTitle' => 'Remove game',
			'library.removeConfirm' => ({required Object title}) => 'Remove "${title}" from your library?',
			'library.removeFailed' => ({required Object error}) => 'Failed to remove: ${error}',
			'library.playTime' => 'Play time',
			'library.totalPlayTime' => ({required Object duration}) => 'Total: ${duration}',
			'library.playSessions' => 'Sessions',
			'library.noPlaySessions' => 'No play sessions yet',
			'library.launchEntry' => 'Launch entry',
			'library.noLaunchEntry' => 'Not selected',
			'library.chooseLaunchEntry' => 'Choose launch entry',
			'library.changeLaunchEntry' => 'Change',
			'library.noLaunchEntries' => 'No .exe or .bat found in the install folder',
			'library.inProgress' => 'In progress',
			'library.launchFailed' => ({required Object error}) => 'Failed to launch: ${error}',
			'detail.loadFailed' => 'Failed to load details',
			'detail.screenshots' => 'Screenshots',
			'detail.tags' => 'Tags',
			'detail.category' => 'Category',
			'detail.engine' => 'Engine',
			'detail.developer' => 'Developer',
			'detail.version' => 'Version',
			'detail.releaseDate' => 'Release date',
			'detail.lastUpdated' => 'Last updated',
			'detail.author' => 'Author',
			'detail.description' => 'Description',
			'detail.downloadLinks' => 'Download links',
			'downloads.title' => 'Downloads',
			'downloads.empty' => 'No downloads yet',
			'downloads.globalSpeedLimit' => 'Global speed limit',
			'downloads.perTaskSpeedLimit' => 'Per-task speed limit',
			'downloads.noLimit' => 'No limit',
			'downloads.pause' => 'Pause',
			'downloads.resume' => 'Resume',
			'downloads.status.active' => 'Downloading',
			'downloads.status.queued' => 'Queued',
			'downloads.status.paused' => 'Paused',
			'downloads.status.complete' => 'Complete',
			'downloads.status.error' => 'Error',
			'downloads.status.removed' => 'Removed',
			'mirrors.notLoggedIn' => 'Not logged in — log in to f95zone to view download links',
			'mirrors.loadFailed' => 'Failed to load download links',
			'mirrors.empty' => 'No download links',
			'mirrors.unsupported' => 'Unsupported',
			'mirrors.supported' => 'Downloadable',
			'mirrors.kind.direct' => 'Direct link',
			'mirrors.kind.magnet' => 'Magnet',
			'mirrors.kind.torrent' => 'Torrent',
			'import.title' => 'Import game',
			'import.directoryTitle' => 'Directory import',
			'import.chooseDifferentFolder' => 'Choose a different folder',
			'import.pickFolder' => 'Pick a folder to scan',
			'import.scanFailed' => 'Failed to scan folder',
			'import.noFolders' => 'No importable folders found',
			'import.leftTitle' => 'Scanned folders',
			'import.rightTitle' => ({required Object count}) => 'Matched (${count})',
			'import.leftEmpty' => 'No folders left to match',
			'import.rightEmpty' => 'Select a folder on the left to match it',
			'import.importRight' => ({required Object count}) => 'Import (${count})',
			'import.associateTitle' => 'Associate f95zone game',
			'import.installPath' => 'Install path (optional)',
			'import.localVersion' => 'Local version (optional)',
			'import.scraping' => 'Scraping…',
			'import.matched' => 'Matched',
			'import.noMatch' => 'Not matched',
			'import.changeMatch' => 'Change matched game',
			'import.cacheIncomplete' => ({required Object built, required Object total}) => 'Cache has ${built}/${total} pages — later letters may be missing',
			'import.imported' => ({required Object title}) => 'Imported: ${title}',
			'import.cancelled' => 'Cancelled',
			'import.failed' => ({required Object error}) => 'Failed: ${error}',
			'import.failedImport' => ({required Object error}) => 'Failed to import: ${error}',
			'import.added' => 'Added to library',
			'import.addFailed' => ({required Object error}) => 'Failed to add: ${error}',
			'import.autoMatching' => ({required Object done, required Object total}) => 'Auto-matching folders ${done}/${total}',
			'setup.title' => 'Setup',
			'setup.welcome' => 'Welcome to f95hub. Configure your download directory and aria2 to get started.',
			'setup.downloadDirectory' => 'Download directory',
			'setup.noDirectory' => 'No directory selected',
			'setup.speedLimits' => 'Speed limits',
			'setup.loginOptional' => 'f95zone login (optional)',
			'gallery.close' => 'Close',
			'gallery.previous' => 'Previous image',
			'gallery.next' => 'Next image',
			'dashboard.libraryGames' => 'Library games',
			'dashboard.updatesAvailable' => 'Updates available',
			'dashboard.downloadTasks' => 'Download tasks',
			'dashboard.gameIndex' => 'Game index',
			'dashboard.playTime' => 'Play time',
			'dashboard.gamesPlayed' => 'Games played',
			'dashboard.lastUpdated' => ({required Object time}) => 'Last updated: ${time}',
			'dashboard.never' => 'never',
			'dashboard.manageLibrary' => 'Manage your local collection',
			'dashboard.quickAccess' => 'Quick access',
			'time.justNow' => 'Just now',
			'time.minutesAgo' => ({required Object n}) => '${n} min ago',
			'time.hoursAgo' => ({required Object n}) => '${n} h ago',
			'time.daysAgo' => ({required Object n}) => '${n} d ago',
			'time.weeksAgo' => ({required Object n}) => '${n} w ago',
			'time.monthsAgo' => ({required Object n}) => '${n} mo ago',
			'time.yearsAgo' => ({required Object n}) => '${n} y ago',
			_ => null,
		};
	}
}
