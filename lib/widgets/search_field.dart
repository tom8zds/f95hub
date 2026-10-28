import 'package:flutter/material.dart';

/// The title-bar search field: a dense, rounded text input that live-filters
/// the page's content as the user types.
///
/// Hosted as a page's AppBar title (games since ticket 22, the local library
/// since ticket 58).
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.fieldKey,
    this.focusNode,
  });

  /// Placeholder shown while the field is empty.
  final String hintText;

  /// Invoked on every keystroke with the new filter text.
  final ValueChanged<String> onChanged;

  /// Key placed on the inner [TextField] so tests can target it when a page
  /// hosts more than one input.
  final Key? fieldKey;

  /// Optional external focus node, so hosts can focus the field via keyboard
  /// shortcuts (Ctrl+F).
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      key: fieldKey,
      focusNode: focusNode,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        // M3 search-field silhouette: fully rounded, tonally filled.
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(48)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(48)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(const Radius.circular(48)),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
    );
  }
}
