import 'package:flutter/material.dart';

import '../i18n/i18n.dart';
import '../theme/tokens.dart';

/// Whether the locally installed [version] differs from f95zone's
/// [latestVersion] as free text.
///
/// Versions are free text and are *not* parsed/ordered (spec §Implementation
/// Decisions): the flag is purely a difference, with no "newer" claim. An
/// unknown latest version (`latestVersion` empty) is never flagged.
bool versionsDiffer({required String version, required String latestVersion}) {
  if (latestVersion.trim().isEmpty) {
    return false;
  }
  return version.trim() != latestVersion.trim();
}

/// Side-by-side "本地版本 vs 最新版本" display plus a neutral difference flag.
///
/// The two versions are shown alongside each other without any ordering or
/// parsing; a chip reads `不同` when the strings differ (no "update available"
/// judgement) and nothing otherwise.
class VersionSideBySide extends StatelessWidget {
  const VersionSideBySide({
    super.key,
    required this.version,
    required this.latestVersion,
    this.onEditVersion,
  });

  /// Locally installed version (free text).
  final String version;

  /// Version currently reported by f95zone (free text).
  final String latestVersion;

  /// Opens the "edit local version" flow; the edit affordance is hidden when
  /// null (read-only embedded previews).
  final VoidCallback? onEditVersion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final differs = versionsDiffer(
      version: version,
      latestVersion: latestVersion,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wrap (not Row) so the pair stacks inside narrow sidebars.
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _VersionColumn(
              label: context.t.library.versionLocal,
              value: version,
              trailing: onEditVersion == null
                  ? null
                  : IconButton(
                      onPressed: onEditVersion,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      tooltip: context.t.library.editVersion,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                    ),
            ),
            _VersionColumn(
              label: context.t.library.versionLatest,
              value: latestVersion,
            ),
            if (differs)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  context.t.library.versionDifferent,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onTertiary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _VersionColumn extends StatelessWidget {
  const _VersionColumn({
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              trailing!,
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '—' : value,
          style: theme.textTheme.titleMedium,
        ),
      ],
    );
  }
}
