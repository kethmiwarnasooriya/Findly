import 'package:findly/core/utils/text_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeText', () {
    test('lower-cases, strips punctuation and collapses whitespace', () {
      expect(normalizeText('  Blue   WATER-bottle!!  '), 'blue water bottle');
    });

    test('removes apostrophes without splitting words', () {
      expect(normalizeText("Kethmi's ID card"), 'kethmis id card');
    });

    test('keeps digits and non-Latin letters', () {
      expect(normalizeText('Room 3B — සිංහල'), 'room 3b සිංහල');
    });

    test('returns empty string for punctuation-only input', () {
      expect(normalizeText('?!...'), '');
    });
  });

  group('extractKeywords', () {
    test('drops stop words and single characters', () {
      expect(extractKeywords('I lost a black wallet in the canteen'), {
        'black',
        'wallet',
        'canteen',
      });
    });

    test('folds simple plurals', () {
      expect(extractKeywords('keys glasses batteries'), {
        'key',
        'glass',
        'battery',
      });
      expect(extractKeywords('bus campus'), {'bus', 'campus'});
    });

    test('is empty for empty input', () {
      expect(extractKeywords(''), isEmpty);
    });
  });

  group('jaccardSimilarity', () {
    test('identical sets score 1', () {
      expect(jaccardSimilarity({'a', 'b'}, {'a', 'b'}), 1);
    });

    test('disjoint sets score 0', () {
      expect(jaccardSimilarity({'a'}, {'b'}), 0);
    });

    test('partial overlap is |A∩B| / |A∪B|', () {
      expect(jaccardSimilarity({'a', 'b', 'c'}, {'b', 'c', 'd'}), 0.5);
    });

    test('empty sets score 0 instead of dividing by zero', () {
      expect(jaccardSimilarity({}, {}), 0);
      expect(jaccardSimilarity({'a'}, {}), 0);
    });
  });
}
