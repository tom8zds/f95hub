///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'translations.g.dart';

// Path: <root>
class TranslationsZh extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsZh({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zh,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <zh>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsZh _root = this; // ignore: unused_field

	@override 
	TranslationsZh $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsZh(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$zh app = _Translations$app$zh._(_root);
	@override late final _Translations$nav$zh nav = _Translations$nav$zh._(_root);
	@override late final _Translations$common$zh common = _Translations$common$zh._(_root);
	@override late final _Translations$buttons$zh buttons = _Translations$buttons$zh._(_root);
	@override late final _Translations$settings$zh settings = _Translations$settings$zh._(_root);
	@override late final _Translations$languages$zh languages = _Translations$languages$zh._(_root);
	@override late final _Translations$theme$zh theme = _Translations$theme$zh._(_root);
	@override late final _Translations$cache$zh cache = _Translations$cache$zh._(_root);
	@override late final _Translations$games$zh games = _Translations$games$zh._(_root);
	@override late final _Translations$sort$zh sort = _Translations$sort$zh._(_root);
	@override late final _Translations$filters$zh filters = _Translations$filters$zh._(_root);
	@override late final _Translations$pagination$zh pagination = _Translations$pagination$zh._(_root);
	@override late final _Translations$library$zh library = _Translations$library$zh._(_root);
	@override late final _Translations$detail$zh detail = _Translations$detail$zh._(_root);
	@override late final _Translations$downloads$zh downloads = _Translations$downloads$zh._(_root);
	@override late final _Translations$mirrors$zh mirrors = _Translations$mirrors$zh._(_root);
	@override late final _Translations$import$zh import = _Translations$import$zh._(_root);
	@override late final _Translations$setup$zh setup = _Translations$setup$zh._(_root);
	@override late final _Translations$gallery$zh gallery = _Translations$gallery$zh._(_root);
	@override late final _Translations$dashboard$zh dashboard = _Translations$dashboard$zh._(_root);
	@override late final _Translations$time$zh time = _Translations$time$zh._(_root);
}

// Path: app
class _Translations$app$zh extends Translations$app$en {
	_Translations$app$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => 'f95hub';
	@override String get loadConfigFailed => '配置加载失败';
}

// Path: nav
class _Translations$nav$zh extends Translations$nav$en {
	_Translations$nav$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get games => '游戏';
	@override String get library => '库';
	@override String get downloads => '下载';
	@override String get settings => '设置';
	@override String get dashboard => '仪表盘';
}

// Path: common
class _Translations$common$zh extends Translations$common$en {
	_Translations$common$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get retry => '重试';
	@override String get cancel => '取消';
	@override String get apply => '应用';
	@override String get browse => '浏览';
	@override String get close => '关闭';
	@override String get previous => '上一页';
	@override String get next => '下一页';
	@override String get add => '添加';
	@override String get download => '下载';
	@override String get all => '全部';
	@override String get none => '无';
	@override String get noMatches => '无匹配结果';
	@override String get save => '保存';
	@override String get viewDetail => '查看详情';
}

// Path: buttons
class _Translations$buttons$zh extends Translations$buttons$en {
	_Translations$buttons$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get createCache => '创建缓存';
	@override String get continueBuild => '继续构建';
	@override String get refreshCache => '刷新缓存';
	@override String get deleteCache => '删除缓存';
	@override String get finish => '完成';
	@override String get logIn => '登录';
	@override String get logOut => '退出登录';
	@override String get importGame => '导入游戏';
	@override String get addToLibrary => '加入库';
	@override String get openInBrowser => '在浏览器中打开';
	@override String get openFolder => '打开目录';
	@override String get launchGame => '启动游戏';
	@override String get remove => '移除';
	@override String get keepFiles => '保留文件';
	@override String get deleteFiles => '删除文件';
	@override String importSelected({required Object count}) => '导入所选（${count}）';
}

// Path: settings
class _Translations$settings$zh extends Translations$settings$en {
	_Translations$settings$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '设置';
	@override String get language => '语言';
	@override String get theme => '主题';
	@override late final _Translations$settings$storage$zh storage = _Translations$settings$storage$zh._(_root);
	@override late final _Translations$settings$network$zh network = _Translations$settings$network$zh._(_root);
	@override late final _Translations$settings$aria2$zh aria2 = _Translations$settings$aria2$zh._(_root);
	@override late final _Translations$settings$login$zh login = _Translations$settings$login$zh._(_root);
}

// Path: languages
class _Translations$languages$zh extends Translations$languages$en {
	_Translations$languages$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get system => '跟随系统';
	@override String get en => 'English';
	@override String get zh => '中文';
}

// Path: theme
class _Translations$theme$zh extends Translations$theme$en {
	_Translations$theme$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get dark => '深色主题';
	@override String get switchToLight => '切换到浅色主题';
	@override String get switchToDark => '切换到深色主题';
	@override late final _Translations$theme$presets$zh presets = _Translations$theme$presets$zh._(_root);
}

// Path: cache
class _Translations$cache$zh extends Translations$cache$en {
	_Translations$cache$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '缓存';
	@override String gamesCached({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '已缓存 1 个游戏',
		other: '已缓存 ${n} 个游戏',
	);
	@override String get lastUpdatedNever => '最后更新：从未';
	@override String lastUpdated({required Object date}) => '最后更新：${date}';
	@override String reached({required Object page, required Object total}) => '已到 ${page} / ${total} 页';
	@override String page({required Object page, required Object total}) => '第 ${page} / ${total} 页';
	@override String get fetchingPageCount => '正在获取页数…';
	@override String failed({required Object error}) => '缓存操作失败：${error}';
}

// Path: games
class _Translations$games$zh extends Translations$games$en {
	_Translations$games$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get searchHint => '搜索游戏';
	@override String get filters => '过滤器';
	@override String get sort => '排序';
	@override String get refresh => '刷新';
	@override String get throttled => '被限流，正在重试';
	@override String get loadFailed => '加载游戏失败';
	@override String get empty => '没有游戏';
	@override String get indexLoadFailed => '加载游戏索引失败';
	@override String get indexEmptyTitle => '游戏索引为空';
	@override String get indexEmptyMessage => '在设置中构建游戏缓存，即可离线搜索整个目录。';
	@override String get searchByTitle => '按标题搜索';
}

// Path: sort
class _Translations$sort$zh extends Translations$sort$en {
	_Translations$sort$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get heading => '排序';
	@override String get date => '日期';
	@override String get likes => '点赞';
	@override String get views => '浏览';
	@override String get title => '标题';
	@override String get rating => '评分';
}

// Path: filters
class _Translations$filters$zh extends Translations$filters$en {
	_Translations$filters$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '过滤器';
	@override String get category => '类别';
	@override String get engine => '引擎';
	@override String get status => '状态';
	@override String get all => '全部';
	@override String get search => '搜索';
	@override String get clear => '清除';
	@override late final _Translations$filters$date$zh date = _Translations$filters$date$zh._(_root);
}

// Path: pagination
class _Translations$pagination$zh extends Translations$pagination$en {
	_Translations$pagination$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get previous => '上一页';
	@override String get next => '下一页';
	@override String page({required Object page, required Object total}) => '第 ${page} / ${total} 页';
}

// Path: library
class _Translations$library$zh extends Translations$library$en {
	_Translations$library$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '库';
	@override String get importFolder => '导入本地文件夹';
	@override String get importFromDirectory => '从目录导入';
	@override String get loadFailed => '加载库失败';
	@override String get empty => '库中还没有游戏';
	@override String get searchHint => '搜索库';
	@override String get filters => '过滤器';
	@override String get sort => '排序';
	@override String get tags => '标签';
	@override String get onlyUpdates => '仅看有更新';
	@override String get sortTitle => '标题';
	@override String get sortUpdated => '最近更新';
	@override String get sortAdded => '最近加入';
	@override String get hasUpdate => '有更新';
	@override String get versionLocal => '本地';
	@override String get versionLatest => '最新';
	@override String get versionDifferent => '不同';
	@override String get editVersion => '编辑版本';
	@override String get editVersionTitle => '编辑本地版本';
	@override String get versionFieldLabel => '版本';
	@override String get removeTitle => '移除游戏';
	@override String removeConfirm({required Object title}) => '从库中移除「${title}」？';
	@override String removeFailed({required Object error}) => '移除失败：${error}';
	@override String get playTime => '游玩时长';
	@override String totalPlayTime({required Object duration}) => '总计：${duration}';
	@override String get playSessions => '游玩记录';
	@override String get noPlaySessions => '还没有游玩记录';
	@override String get launchEntry => '启动项';
	@override String get noLaunchEntry => '未选择';
	@override String get chooseLaunchEntry => '选择启动项';
	@override String get changeLaunchEntry => '更改';
	@override String get noLaunchEntries => '安装目录中未找到 .exe 或 .bat';
	@override String get inProgress => '进行中';
	@override String launchFailed({required Object error}) => '启动失败：${error}';
}

// Path: detail
class _Translations$detail$zh extends Translations$detail$en {
	_Translations$detail$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get loadFailed => '加载详情失败';
	@override String get screenshots => '截图';
	@override String get tags => '标签';
	@override String get category => '类别';
	@override String get engine => '引擎';
	@override String get developer => '开发者';
	@override String get version => '版本';
	@override String get releaseDate => '发布日期';
	@override String get lastUpdated => '最后更新';
	@override String get author => '作者';
	@override String get description => '描述';
	@override String get downloadLinks => '下载链接';
}

// Path: downloads
class _Translations$downloads$zh extends Translations$downloads$en {
	_Translations$downloads$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '下载';
	@override String get empty => '暂无下载';
	@override String get globalSpeedLimit => '全局限速';
	@override String get perTaskSpeedLimit => '单任务限速';
	@override String get noLimit => '不限速';
	@override String get pause => '暂停';
	@override String get resume => '继续';
	@override late final _Translations$downloads$status$zh status = _Translations$downloads$status$zh._(_root);
}

// Path: mirrors
class _Translations$mirrors$zh extends Translations$mirrors$en {
	_Translations$mirrors$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get notLoggedIn => '未登录 — 请先登录 f95zone 以查看下载链接';
	@override String get loadFailed => '加载下载链接失败';
	@override String get empty => '无下载链接';
	@override String get unsupported => '不支持';
	@override String get supported => '可下载';
	@override late final _Translations$mirrors$kind$zh kind = _Translations$mirrors$kind$zh._(_root);
}

// Path: import
class _Translations$import$zh extends Translations$import$en {
	_Translations$import$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '导入游戏';
	@override String get directoryTitle => '目录导入';
	@override String get chooseDifferentFolder => '选择其他文件夹';
	@override String get pickFolder => '选择要扫描的文件夹';
	@override String get scanFailed => '扫描文件夹失败';
	@override String get noFolders => '未找到可导入的文件夹';
	@override String get leftTitle => '扫描目录';
	@override String rightTitle({required Object count}) => '已匹配（${count}）';
	@override String get leftEmpty => '没有待匹配的目录';
	@override String get rightEmpty => '点击左侧目录进行匹配';
	@override String importRight({required Object count}) => '导入（${count}）';
	@override String get associateTitle => '关联 f95zone 游戏';
	@override String get installPath => '安装路径（可选）';
	@override String get localVersion => '本地版本（可选）';
	@override String get scraping => '正在抓取…';
	@override String get matched => '已匹配';
	@override String get noMatch => '未匹配';
	@override String get changeMatch => '更改匹配的游戏';
	@override String cacheIncomplete({required Object built, required Object total}) => '缓存 ${built}/${total} 页，可能缺后续字母';
	@override String imported({required Object title}) => '已导入：${title}';
	@override String get cancelled => '已取消';
	@override String failed({required Object error}) => '失败：${error}';
	@override String failedImport({required Object error}) => '导入失败：${error}';
	@override String get added => '已加入库';
	@override String addFailed({required Object error}) => '加入库失败：${error}';
	@override String autoMatching({required Object done, required Object total}) => '正在自动匹配（${done}/${total}）';
}

// Path: setup
class _Translations$setup$zh extends Translations$setup$en {
	_Translations$setup$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '设置向导';
	@override String get welcome => '欢迎使用 f95hub。请配置下载目录和 aria2 以开始使用。';
	@override String get downloadDirectory => '下载目录';
	@override String get noDirectory => '未选择目录';
	@override String get speedLimits => '限速';
	@override String get loginOptional => 'f95zone 登录（可选）';
}

// Path: gallery
class _Translations$gallery$zh extends Translations$gallery$en {
	_Translations$gallery$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get close => '关闭';
	@override String get previous => '上一张';
	@override String get next => '下一张';
}

// Path: dashboard
class _Translations$dashboard$zh extends Translations$dashboard$en {
	_Translations$dashboard$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get libraryGames => '库中游戏';
	@override String get updatesAvailable => '可更新';
	@override String get downloadTasks => '下载任务';
	@override String get gameIndex => '索引缓存';
	@override String get playTime => '游玩时长';
	@override String get gamesPlayed => '已玩游戏';
	@override String lastUpdated({required Object time}) => '最后更新：${time}';
	@override String get never => '从未';
	@override String get manageLibrary => '管理本地收藏';
	@override String get quickAccess => '快捷入口';
}

// Path: time
class _Translations$time$zh extends Translations$time$en {
	_Translations$time$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get justNow => '刚刚';
	@override String minutesAgo({required Object n}) => '${n} 分钟前';
	@override String hoursAgo({required Object n}) => '${n} 小时前';
	@override String daysAgo({required Object n}) => '${n} 天前';
	@override String weeksAgo({required Object n}) => '${n} 周前';
	@override String monthsAgo({required Object n}) => '${n} 个月前';
	@override String yearsAgo({required Object n}) => '${n} 年前';
}

// Path: settings.storage
class _Translations$settings$storage$zh extends Translations$settings$storage$en {
	_Translations$settings$storage$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '存储目录';
	@override String get none => '未设置存储目录';
	@override String fallback({required Object path}) => '库根目录回退到下载目录：${path}';
}

// Path: settings.network
class _Translations$settings$network$zh extends Translations$settings$network$en {
	_Translations$settings$network$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '网络';
	@override String get fetchInterval => '抓取间隔(秒)';
	@override String get fetchIntervalHelp => '两次请求之间的最小间隔；过小容易触发 429，默认 2 秒';
}

// Path: settings.aria2
class _Translations$settings$aria2$zh extends Translations$settings$aria2$en {
	_Translations$settings$aria2$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => 'aria2';
	@override String get rpcPort => 'RPC 端口';
	@override String get rpcSecret => 'RPC 密钥（可选，仅保存在内存中）';
	@override String get globalLimit => '全局限速（例如 1M）';
	@override String get perTaskLimit => '单任务限速（例如 10K）';
	@override String get noCap => '留空表示不限速';
}

// Path: settings.login
class _Translations$settings$login$zh extends Translations$settings$login$en {
	_Translations$settings$login$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => 'f95zone 登录';
	@override String get loggedIn => '已登录';
	@override String get notLoggedIn => '未登录';
	@override String get sessionCookie => '会话 Cookie';
	@override String get sessionCookieHelp => '粘贴浏览器中的 xf_user/cf_clearance';
}

// Path: theme.presets
class _Translations$theme$presets$zh extends Translations$theme$presets$en {
	_Translations$theme$presets$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get material => 'Material';
	@override String get materialYou => 'Material You';
	@override String get blue => '蓝色';
	@override String get green => '绿色';
	@override String get red => '红色';
}

// Path: filters.date
class _Translations$filters$date$zh extends Translations$filters$date$en {
	_Translations$filters$date$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get anytime => '不限';
	@override String get today => '今天';
	@override String get last7 => '7 天内';
	@override String get last30 => '30 天内';
}

// Path: downloads.status
class _Translations$downloads$status$zh extends Translations$downloads$status$en {
	_Translations$downloads$status$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get active => '下载中';
	@override String get queued => '排队中';
	@override String get paused => '已暂停';
	@override String get complete => '已完成';
	@override String get error => '错误';
	@override String get removed => '已移除';
}

// Path: mirrors.kind
class _Translations$mirrors$kind$zh extends Translations$mirrors$kind$en {
	_Translations$mirrors$kind$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get direct => '直链';
	@override String get magnet => '磁力';
	@override String get torrent => '种子';
}

/// The flat map containing all translations for locale <zh>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsZh {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'f95hub',
			'app.loadConfigFailed' => '配置加载失败',
			'nav.games' => '游戏',
			'nav.library' => '库',
			'nav.downloads' => '下载',
			'nav.settings' => '设置',
			'nav.dashboard' => '仪表盘',
			'common.retry' => '重试',
			'common.cancel' => '取消',
			'common.apply' => '应用',
			'common.browse' => '浏览',
			'common.close' => '关闭',
			'common.previous' => '上一页',
			'common.next' => '下一页',
			'common.add' => '添加',
			'common.download' => '下载',
			'common.all' => '全部',
			'common.none' => '无',
			'common.noMatches' => '无匹配结果',
			'common.save' => '保存',
			'common.viewDetail' => '查看详情',
			'buttons.createCache' => '创建缓存',
			'buttons.continueBuild' => '继续构建',
			'buttons.refreshCache' => '刷新缓存',
			'buttons.deleteCache' => '删除缓存',
			'buttons.finish' => '完成',
			'buttons.logIn' => '登录',
			'buttons.logOut' => '退出登录',
			'buttons.importGame' => '导入游戏',
			'buttons.addToLibrary' => '加入库',
			'buttons.openInBrowser' => '在浏览器中打开',
			'buttons.openFolder' => '打开目录',
			'buttons.launchGame' => '启动游戏',
			'buttons.remove' => '移除',
			'buttons.keepFiles' => '保留文件',
			'buttons.deleteFiles' => '删除文件',
			'buttons.importSelected' => ({required Object count}) => '导入所选（${count}）',
			'settings.title' => '设置',
			'settings.language' => '语言',
			'settings.theme' => '主题',
			'settings.storage.title' => '存储目录',
			'settings.storage.none' => '未设置存储目录',
			'settings.storage.fallback' => ({required Object path}) => '库根目录回退到下载目录：${path}',
			'settings.network.title' => '网络',
			'settings.network.fetchInterval' => '抓取间隔(秒)',
			'settings.network.fetchIntervalHelp' => '两次请求之间的最小间隔；过小容易触发 429，默认 2 秒',
			'settings.aria2.title' => 'aria2',
			'settings.aria2.rpcPort' => 'RPC 端口',
			'settings.aria2.rpcSecret' => 'RPC 密钥（可选，仅保存在内存中）',
			'settings.aria2.globalLimit' => '全局限速（例如 1M）',
			'settings.aria2.perTaskLimit' => '单任务限速（例如 10K）',
			'settings.aria2.noCap' => '留空表示不限速',
			'settings.login.title' => 'f95zone 登录',
			'settings.login.loggedIn' => '已登录',
			'settings.login.notLoggedIn' => '未登录',
			'settings.login.sessionCookie' => '会话 Cookie',
			'settings.login.sessionCookieHelp' => '粘贴浏览器中的 xf_user/cf_clearance',
			'languages.system' => '跟随系统',
			'languages.en' => 'English',
			'languages.zh' => '中文',
			'theme.dark' => '深色主题',
			'theme.switchToLight' => '切换到浅色主题',
			'theme.switchToDark' => '切换到深色主题',
			'theme.presets.material' => 'Material',
			'theme.presets.materialYou' => 'Material You',
			'theme.presets.blue' => '蓝色',
			'theme.presets.green' => '绿色',
			'theme.presets.red' => '红色',
			'cache.title' => '缓存',
			'cache.gamesCached' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '已缓存 1 个游戏', other: '已缓存 ${n} 个游戏', ), 
			'cache.lastUpdatedNever' => '最后更新：从未',
			'cache.lastUpdated' => ({required Object date}) => '最后更新：${date}',
			'cache.reached' => ({required Object page, required Object total}) => '已到 ${page} / ${total} 页',
			'cache.page' => ({required Object page, required Object total}) => '第 ${page} / ${total} 页',
			'cache.fetchingPageCount' => '正在获取页数…',
			'cache.failed' => ({required Object error}) => '缓存操作失败：${error}',
			'games.searchHint' => '搜索游戏',
			'games.filters' => '过滤器',
			'games.sort' => '排序',
			'games.refresh' => '刷新',
			'games.throttled' => '被限流，正在重试',
			'games.loadFailed' => '加载游戏失败',
			'games.empty' => '没有游戏',
			'games.indexLoadFailed' => '加载游戏索引失败',
			'games.indexEmptyTitle' => '游戏索引为空',
			'games.indexEmptyMessage' => '在设置中构建游戏缓存，即可离线搜索整个目录。',
			'games.searchByTitle' => '按标题搜索',
			'sort.heading' => '排序',
			'sort.date' => '日期',
			'sort.likes' => '点赞',
			'sort.views' => '浏览',
			'sort.title' => '标题',
			'sort.rating' => '评分',
			'filters.title' => '过滤器',
			'filters.category' => '类别',
			'filters.engine' => '引擎',
			'filters.status' => '状态',
			'filters.all' => '全部',
			'filters.search' => '搜索',
			'filters.clear' => '清除',
			'filters.date.anytime' => '不限',
			'filters.date.today' => '今天',
			'filters.date.last7' => '7 天内',
			'filters.date.last30' => '30 天内',
			'pagination.previous' => '上一页',
			'pagination.next' => '下一页',
			'pagination.page' => ({required Object page, required Object total}) => '第 ${page} / ${total} 页',
			'library.title' => '库',
			'library.importFolder' => '导入本地文件夹',
			'library.importFromDirectory' => '从目录导入',
			'library.loadFailed' => '加载库失败',
			'library.empty' => '库中还没有游戏',
			'library.searchHint' => '搜索库',
			'library.filters' => '过滤器',
			'library.sort' => '排序',
			'library.tags' => '标签',
			'library.onlyUpdates' => '仅看有更新',
			'library.sortTitle' => '标题',
			'library.sortUpdated' => '最近更新',
			'library.sortAdded' => '最近加入',
			'library.hasUpdate' => '有更新',
			'library.versionLocal' => '本地',
			'library.versionLatest' => '最新',
			'library.versionDifferent' => '不同',
			'library.editVersion' => '编辑版本',
			'library.editVersionTitle' => '编辑本地版本',
			'library.versionFieldLabel' => '版本',
			'library.removeTitle' => '移除游戏',
			'library.removeConfirm' => ({required Object title}) => '从库中移除「${title}」？',
			'library.removeFailed' => ({required Object error}) => '移除失败：${error}',
			'library.playTime' => '游玩时长',
			'library.totalPlayTime' => ({required Object duration}) => '总计：${duration}',
			'library.playSessions' => '游玩记录',
			'library.noPlaySessions' => '还没有游玩记录',
			'library.launchEntry' => '启动项',
			'library.noLaunchEntry' => '未选择',
			'library.chooseLaunchEntry' => '选择启动项',
			'library.changeLaunchEntry' => '更改',
			'library.noLaunchEntries' => '安装目录中未找到 .exe 或 .bat',
			'library.inProgress' => '进行中',
			'library.launchFailed' => ({required Object error}) => '启动失败：${error}',
			'detail.loadFailed' => '加载详情失败',
			'detail.screenshots' => '截图',
			'detail.tags' => '标签',
			'detail.category' => '类别',
			'detail.engine' => '引擎',
			'detail.developer' => '开发者',
			'detail.version' => '版本',
			'detail.releaseDate' => '发布日期',
			'detail.lastUpdated' => '最后更新',
			'detail.author' => '作者',
			'detail.description' => '描述',
			'detail.downloadLinks' => '下载链接',
			'downloads.title' => '下载',
			'downloads.empty' => '暂无下载',
			'downloads.globalSpeedLimit' => '全局限速',
			'downloads.perTaskSpeedLimit' => '单任务限速',
			'downloads.noLimit' => '不限速',
			'downloads.pause' => '暂停',
			'downloads.resume' => '继续',
			'downloads.status.active' => '下载中',
			'downloads.status.queued' => '排队中',
			'downloads.status.paused' => '已暂停',
			'downloads.status.complete' => '已完成',
			'downloads.status.error' => '错误',
			'downloads.status.removed' => '已移除',
			'mirrors.notLoggedIn' => '未登录 — 请先登录 f95zone 以查看下载链接',
			'mirrors.loadFailed' => '加载下载链接失败',
			'mirrors.empty' => '无下载链接',
			'mirrors.unsupported' => '不支持',
			'mirrors.supported' => '可下载',
			'mirrors.kind.direct' => '直链',
			'mirrors.kind.magnet' => '磁力',
			'mirrors.kind.torrent' => '种子',
			'import.title' => '导入游戏',
			'import.directoryTitle' => '目录导入',
			'import.chooseDifferentFolder' => '选择其他文件夹',
			'import.pickFolder' => '选择要扫描的文件夹',
			'import.scanFailed' => '扫描文件夹失败',
			'import.noFolders' => '未找到可导入的文件夹',
			'import.leftTitle' => '扫描目录',
			'import.rightTitle' => ({required Object count}) => '已匹配（${count}）',
			'import.leftEmpty' => '没有待匹配的目录',
			'import.rightEmpty' => '点击左侧目录进行匹配',
			'import.importRight' => ({required Object count}) => '导入（${count}）',
			'import.associateTitle' => '关联 f95zone 游戏',
			'import.installPath' => '安装路径（可选）',
			'import.localVersion' => '本地版本（可选）',
			'import.scraping' => '正在抓取…',
			'import.matched' => '已匹配',
			'import.noMatch' => '未匹配',
			'import.changeMatch' => '更改匹配的游戏',
			'import.cacheIncomplete' => ({required Object built, required Object total}) => '缓存 ${built}/${total} 页，可能缺后续字母',
			'import.imported' => ({required Object title}) => '已导入：${title}',
			'import.cancelled' => '已取消',
			'import.failed' => ({required Object error}) => '失败：${error}',
			'import.failedImport' => ({required Object error}) => '导入失败：${error}',
			'import.added' => '已加入库',
			'import.addFailed' => ({required Object error}) => '加入库失败：${error}',
			'import.autoMatching' => ({required Object done, required Object total}) => '正在自动匹配（${done}/${total}）',
			'setup.title' => '设置向导',
			'setup.welcome' => '欢迎使用 f95hub。请配置下载目录和 aria2 以开始使用。',
			'setup.downloadDirectory' => '下载目录',
			'setup.noDirectory' => '未选择目录',
			'setup.speedLimits' => '限速',
			'setup.loginOptional' => 'f95zone 登录（可选）',
			'gallery.close' => '关闭',
			'gallery.previous' => '上一张',
			'gallery.next' => '下一张',
			'dashboard.libraryGames' => '库中游戏',
			'dashboard.updatesAvailable' => '可更新',
			'dashboard.downloadTasks' => '下载任务',
			'dashboard.gameIndex' => '索引缓存',
			'dashboard.playTime' => '游玩时长',
			'dashboard.gamesPlayed' => '已玩游戏',
			'dashboard.lastUpdated' => ({required Object time}) => '最后更新：${time}',
			'dashboard.never' => '从未',
			'dashboard.manageLibrary' => '管理本地收藏',
			'dashboard.quickAccess' => '快捷入口',
			'time.justNow' => '刚刚',
			'time.minutesAgo' => ({required Object n}) => '${n} 分钟前',
			'time.hoursAgo' => ({required Object n}) => '${n} 小时前',
			'time.daysAgo' => ({required Object n}) => '${n} 天前',
			'time.weeksAgo' => ({required Object n}) => '${n} 周前',
			'time.monthsAgo' => ({required Object n}) => '${n} 个月前',
			'time.yearsAgo' => ({required Object n}) => '${n} 年前',
			_ => null,
		};
	}
}
