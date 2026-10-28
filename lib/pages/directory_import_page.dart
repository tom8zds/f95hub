import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import '../domain/scraper.dart';
import '../i18n/i18n.dart';
import '../state/directory_import.dart';
import '../widgets/directory_candidate_grid.dart';
import '../widgets/directory_matched_list.dart';
import '../widgets/game_picker_dialog.dart';
import '../widgets/game_search_results.dart';
import '../widgets/page_frame.dart';

/// Two-pane directory-import flow: the left pane lists the scanned folders
/// (single-select), the right pane the ones already matched to an f95zone game.
/// Selecting a left folder matches it (uniquely, or through the picker) and
/// moves it right; the bottom action batch-imports the right pane, which moves
/// each folder into the storage root and scrapes its metadata.
class DirectoryImportPage extends ConsumerStatefulWidget {
  const DirectoryImportPage({super.key});

  @override
  ConsumerState<DirectoryImportPage> createState() =>
      _DirectoryImportPageState();
}

class _DirectoryImportPageState extends ConsumerState<DirectoryImportPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(directoryImportProvider.notifier).pickAndScan());
  }

  Future<void> _pick() =>
      ref.read(directoryImportProvider.notifier).pickAndScan();

  Future<Game?> _pickGame([ImportItem? item]) => showDialog<Game>(
        context: context,
        builder: (_) => GamePickerDialog(
          initialQuery:
              item == null ? null : parseFolderName(item.name).title,
        ),
      );

  Future<void> _importRight() =>
      ref.read(directoryImportProvider.notifier).importRight();

  /// Matches a left-pane [item]: one catalogue hit auto-matches, otherwise the
  /// picker opens — with the folder's guessed title pre-filled — so zero or
  /// several hits both end in a manual choice.
  Future<void> _selectLeft(ImportItem item) async {
    final controller = ref.read(directoryImportProvider.notifier);
    final outcome = await controller.selectLeft(item);
    if (!mounted || outcome == LeftMatchOutcome.matched) return;
    final game = await _pickGame(item);
    if (game == null || !mounted) return;
    controller.matchLeft(item, game);
  }

  /// Re-picks the game for a right-pane [item], replacing its match.
  Future<void> _override(ImportItem item) async {
    final game = await _pickGame(item);
    if (game == null || !mounted) return;
    ref.read(directoryImportProvider.notifier).setMatchedGame(item.path, game);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(directoryImportProvider);
    return PageFrame(
      title: context.t.import.directoryTitle,
      loading: state.scanning || state.autoMatching || state.importing,
      actions: [
        if (state.autoMatching)
          IconButton(
            onPressed: () =>
                ref.read(directoryImportProvider.notifier).cancelAutoMatch(),
            icon: const Icon(Icons.stop_circle_outlined),
            tooltip: context.t.common.cancel,
          ),
        IconButton(
          onPressed: _pick,
          icon: const Icon(Icons.folder_open),
          tooltip: context.t.import.chooseDifferentFolder,
        ),
      ],
      child: _body(state),
    );
  }

  Widget _body(DirectoryImportState state) {
    final t = context.t;
    final controller = ref.read(directoryImportProvider.notifier);
    if (state.sourceDir == null) {
      return Center(child: Text(t.import.pickFolder));
    }
    if (state.scanning) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.scanError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.import.scanFailed),
            const SizedBox(height: 8),
            FilledButton(onPressed: _pick, child: Text(t.common.retry)),
          ],
        ),
      );
    }
    if (state.left.isEmpty && state.right.isEmpty) {
      return Center(child: Text(t.import.noFolders));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  state.sourceDir!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        if (state.totalPages > 0 && state.lastBuiltPage < state.totalPages)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: GameIndexCompletenessHint(
              lastBuiltPage: state.lastBuiltPage,
              totalPages: state.totalPages,
            ),
          ),
        if (state.autoMatching)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: state.autoMatchTotal == 0
                        ? null
                        : state.autoMatchDone / state.autoMatchTotal,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  t.import.autoMatching(
                    done: state.autoMatchDone,
                    total: state.autoMatchTotal,
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Pane(
                  title: t.import.leftTitle,
                  child: DirectoryCandidateGrid(
                    items: state.left,
                    onSelect: _selectLeft,
                    onCancel: (item) => controller.cancel(item.path),
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: _Pane(
                  title: t.import.rightTitle(count: state.right.length),
                  child: DirectoryMatchedList(
                    items: state.right,
                    onChangeMatch: _override,
                    onRemove: (item) => controller.removeRight(item),
                    onCancel: (item) => controller.cancel(item.path),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.icon(
                onPressed: state.right.isEmpty || state.importing
                    ? null
                    : _importRight,
                icon: const Icon(Icons.drive_folder_upload),
                label: Text(
                  t.import.importRight(count: state.right.length),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One titled pane of the two-pane layout (heading + scrolling content).
class _Pane extends StatelessWidget {
  const _Pane({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
