import 'package:flutter/material.dart';

import '../adapters/url_opener.dart';
import '../domain/models.dart';
import '../i18n/i18n.dart';

/// The detail page's floating action: opens the game's f95zone thread in the
/// system browser.
///
/// [onOpen] is injectable for tests; it defaults to [openExternalUrl].
class OpenInBrowserButton extends StatelessWidget {
  const OpenInBrowserButton({super.key, required this.game, this.onOpen});

  final Game game;

  /// Overrides the browser launch (tests); defaults to [openExternalUrl].
  final Future<void> Function(String url)? onOpen;

  /// The thread URL the button opens (the id-only form redirects to the slug).
  static Uri threadUri(Game game) =>
      Uri.parse('https://f95zone.to/threads/${game.threadId}/');

  @override
  Widget build(BuildContext context) {
    final url = threadUri(game).toString();
    return FloatingActionButton.extended(
      onPressed: () => (onOpen ?? openExternalUrl)(url),
      icon: const Icon(Icons.open_in_browser),
      label: Text(context.t.buttons.openInBrowser),
    );
  }
}
