import 'package:flutter/material.dart';

/// A wrapping row of tag chips.
class TagChips extends StatelessWidget {
  const TagChips({super.key, required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tag in tags)
          Chip(
            label: Text(tag),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}
