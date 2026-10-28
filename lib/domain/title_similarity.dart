import 'scraper.dart';

/// The pure primitives behind the local index's fuzzy title matching
/// (ticket 56).
///
/// A folder name and a f95zone listing title rarely agree character for
/// character: the folder may drop spaces (`DevotedWife`), carry an author
/// prefix, or end in a release date. Comparing the *compact* forms of both
/// sides — lowercase alphanumerics only, after the listing normalizer has
/// stripped bracket/version noise — makes those differences disappear, and an
/// LCS similarity tolerates whatever noise is left.

/// [title] as stored/compared: the listing normalizer applied and lowercased.
///
/// Shared by the index's `normalizedTitle` and its compact form so a query and
/// a stored row are always normalized the same way.
String normalizedSearchTitle(String title) {
  final cleaned = normalizeThreadTitle(title).toLowerCase();
  return cleaned.isEmpty ? title.trim().toLowerCase() : cleaned;
}

/// Everything that is not a letter or a decimal digit.
///
/// Unicode-aware on purpose: a Cyrillic or CJK title must keep its letters,
/// otherwise its compact form would be empty and it would drop out of the
/// fuzzy search entirely.
final _nonAlphanumerics = RegExp(r'[^\p{L}\p{Nd}]', unicode: true);

/// [title] reduced to lowercase alphanumerics only (`Devoted Wife` →
/// `devotedwife`), after [normalizedSearchTitle].
///
/// Runs on both sides of a match, so a query missing spaces, an author prefix
/// or a date suffix collapses onto the stored title's form.
String compactTitle(String title) =>
    normalizedSearchTitle(title).replaceAll(_nonAlphanumerics, '');

/// Length of the longest common subsequence of [a] and [b].
///
/// Two rolling rows of the DP table, so the cost is `O(len(a) * len(b))` time
/// but `O(min(len))` memory — enough for titles, cheap enough to score every
/// prefiltered candidate.
int lcsLength(String a, String b) {
  if (a.isEmpty || b.isEmpty) {
    return 0;
  }
  // Walk the rows over the longer string, keep the columns on the shorter one.
  final long = a.length >= b.length ? a : b;
  final short = a.length >= b.length ? b : a;
  var previous = List<int>.filled(short.length + 1, 0);
  var current = List<int>.filled(short.length + 1, 0);
  for (var i = 1; i <= long.length; i++) {
    final code = long.codeUnitAt(i - 1);
    for (var j = 1; j <= short.length; j++) {
      if (code == short.codeUnitAt(j - 1)) {
        current[j] = previous[j - 1] + 1;
      } else {
        final above = previous[j];
        final left = current[j - 1];
        current[j] = above > left ? above : left;
      }
    }
    final swap = previous;
    previous = current;
    current = swap;
  }
  return previous[short.length];
}

/// [lcsLength] normalized by the longer of the two strings: `1.0` for equal
/// strings, `0` when either side is empty (never divides by zero).
double lcsSimilarity(String a, String b) {
  final longest = a.length >= b.length ? a.length : b.length;
  return longest == 0 ? 0 : lcsLength(a, b) / longest;
}
