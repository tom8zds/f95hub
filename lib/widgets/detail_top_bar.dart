import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A chrome-free, pinned title bar for a detail route.
///
/// The back control and the title sit above the scrollable content (not in an
/// [AppBar]), so the title is never scrolled over and the skeleton and the
/// loaded states share the exact same back position.
class DetailTopBar extends StatelessWidget {
  const DetailTopBar({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: kToolbarHeight,
        child: Row(
          children: [
            BackButton(
              onPressed: onBack ?? () => Navigator.maybePop(context),
            ),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
