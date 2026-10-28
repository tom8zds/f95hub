import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../domain/models.dart';
import '../widgets/detail_top_bar.dart';
import '../widgets/library_detail.dart';

/// A library entry's full detail as a pushed route (narrow windows): the same
/// content as the wide layout's pane tab, under the shared pinned top bar so
/// the title stays visible and the back button keeps one position.
class LibraryDetailPage extends StatelessWidget {
  const LibraryDetailPage({super.key, required this.game, this.cacheManager});

  final Game game;

  /// Cache manager for the cover/gallery; null uses the shared disk cache.
  final BaseCacheManager? cacheManager;

  @override
  Widget build(BuildContext context) {
    return LibraryDetailPaneTab(
      game: game,
      cacheManager: cacheManager,
      showTitle: false,
      topBar: DetailTopBar(title: game.title),
      onClose: () => Navigator.maybePop(context),
    );
  }
}
