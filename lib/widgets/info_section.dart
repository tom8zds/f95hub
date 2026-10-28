import 'package:flutter/material.dart';

/// A labelled information block on the detail page: a small section title
/// above its [child] content.
class InfoSection extends StatelessWidget {
  const InfoSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
