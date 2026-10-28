import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/tokens.dart';

/// A friendly empty/placeholder state: icon in a tonal circle, a short title,
/// an optional supporting message, and an optional call-to-action.
///
/// Replaces bare `Center(Text(...))` empties across the pages so "nothing
/// here" moments explain themselves instead of looking broken.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;

  /// Supporting line under the title (optional).
  final String? message;

  /// Label for the call-to-action button; hidden when null.
  final String? actionLabel;

  /// Invoked when the action button is pressed; hidden when null.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: theme.textTheme.titleMedium),
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget previews
// ---------------------------------------------------------------------------

/// Plain empty state (icon + title + message).
@Preview(name: 'Basic', group: 'EmptyState', size: Size(480, 360))
Widget emptyStatePreview() => MaterialApp(
  home: Scaffold(
    body: EmptyState(
      icon: Icons.videogame_asset,
      title: 'No games yet',
      message: 'Browse f95zone and add games to your library.',
    ),
  ),
);

/// Empty state with a call-to-action button.
@Preview(name: 'With action', group: 'EmptyState', size: Size(480, 400))
Widget emptyStateActionPreview() => MaterialApp(
  home: Scaffold(
    body: EmptyState(
      icon: Icons.cloud_off,
      title: 'Failed to load',
      message: 'The f95zone endpoint could not be reached.',
      actionLabel: 'Retry',
      onAction: () {},
    ),
  ),
);
