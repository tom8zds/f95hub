import 'package:flutter_test/flutter_test.dart';

import 'package:f95hub/domain/title_similarity.dart';

/// Unit tests for the pure matching primitives behind ticket 56: the compact
/// (lowercase alphanumerics) title form and the longest-common-subsequence
/// similarity the local index search ranks candidates with.
void main() {
  group('compactTitle', () {
    test('keeps letters and digits, lowercased', () {
      expect(compactTitle('Devoted Wife'), 'devotedwife');
      expect(compactTitle('Game 61'), 'game61');
    });

    test('drops the bracket/prefix noise the listing carries', () {
      expect(
        compactTitle('Secret Care Cafe [v0.9.5] [Rare Alex]'),
        'secretcarecafe',
      );
      expect(compactTitle("Ren'Py - My Game"), 'mygame');
    });

    test('is empty when nothing alphanumeric is left', () {
      expect(compactTitle('!!!'), isEmpty);
      expect(compactTitle('   '), isEmpty);
    });

    test('keeps non-latin letters, so a localized title stays searchable', () {
      expect(compactTitle('Miko 巫女'), 'miko巫女');
    });
  });

  group('lcsLength', () {
    test('is zero when either side is empty', () {
      expect(lcsLength('', 'abc'), 0);
      expect(lcsLength('abc', ''), 0);
    });

    test('is the full length for identical strings', () {
      expect(lcsLength('devotedwife', 'devotedwife'), 11);
    });

    test('counts the longest common subsequence, not a substring', () {
      expect(lcsLength('koshinohimagicalacademydropout',
          'magicalacademydropout'), 21);
      expect(lcsLength('game61', 'game1'), 5);
      expect(lcsLength('abcbdab', 'bdcaba'), 4);
    });
  });

  group('lcsSimilarity', () {
    test('is the LCS length over the longer string', () {
      expect(lcsSimilarity('magicalacademydropout', 'magicalacademydropout'),
          1.0);
      expect(lcsSimilarity('koshinohimagicalacademydropout',
          'magicalacademydropout'), closeTo(21 / 30, 1e-9));
    });

    test('is zero when either side is empty (no division by zero)', () {
      expect(lcsSimilarity('', 'abc'), 0);
      expect(lcsSimilarity('abc', ''), 0);
      expect(lcsSimilarity('', ''), 0);
    });
  });
}
