/// Human-readable byte formatting for the download queue (no `intl`).
library;

import '../i18n/translations.g.dart';

/// Formats a byte count as `1.2 MB` / `840 B` / `3.0 GB`.
String formatBytes(int bytes) {
  if (bytes <= 0) {
    return '0 B';
  }
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final decimals = unit == 0 ? 0 : (value >= 100 ? 0 : 1);
  return '${value.toStringAsFixed(decimals)} ${units[unit]}';
}

/// Formats a byte/second rate as `1.2 MB/s`.
String formatSpeed(int bytesPerSecond) =>
    '${formatBytes(bytesPerSecond)}/s';

/// Formats a playtime duration as `12s`, `3m 04s`, or `2h 05m`.
///
/// Deliberately compact (no days unit): library sessions are minutes-to-hours
/// scale and the detail page shows one row per session.
String formatPlaytime(Duration duration) {
  final seconds = duration.inSeconds;
  if (seconds <= 0) {
    return '0s';
  }
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  final rest = seconds % 60;
  if (hours > 0) {
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }
  if (minutes > 0) {
    return '${minutes}m ${rest.toString().padLeft(2, '0')}s';
  }
  return '${rest}s';
}

/// Formats a local date-time as `2026-10-24 21:05` (no `intl` dependency).
String formatDateTime(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)} '
      '${two(value.hour)}:${two(value.minute)}';
}

/// Adaptive "how long ago" label: minutes within the hour, hours within the
/// day, then days/weeks/months/years — the granularity grows with age.
String formatRelativeTime(
  Translations t,
  DateTime at, {
  DateTime? now,
}) {
  final diff = (now ?? DateTime.now()).difference(at);
  if (diff < const Duration(minutes: 1)) {
    return t.time.justNow;
  }
  if (diff < const Duration(hours: 1)) {
    return t.time.minutesAgo(n: diff.inMinutes);
  }
  if (diff < const Duration(days: 1)) {
    return t.time.hoursAgo(n: diff.inHours);
  }
  if (diff < const Duration(days: 7)) {
    return t.time.daysAgo(n: diff.inDays);
  }
  if (diff < const Duration(days: 30)) {
    return t.time.weeksAgo(n: diff.inDays ~/ 7);
  }
  if (diff < const Duration(days: 365)) {
    return t.time.monthsAgo(n: diff.inDays ~/ 30);
  }
  return t.time.yearsAgo(n: diff.inDays ~/ 365);
}
