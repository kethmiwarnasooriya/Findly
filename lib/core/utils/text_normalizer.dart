/// Deterministic text helpers used by search and the matching engine.
library;

/// Common English words that carry no information about an item.
const Set<String> englishStopWords = {
  'a',
  'an',
  'and',
  'are',
  'as',
  'at',
  'be',
  'by',
  'for',
  'from',
  'has',
  'have',
  'he',
  'her',
  'his',
  'i',
  'in',
  'is',
  'it',
  'its',
  'my',
  'of',
  'on',
  'or',
  'our',
  'she',
  'that',
  'the',
  'their',
  'there',
  'this',
  'to',
  'was',
  'were',
  'with',
  'you',
  'your',
  'me',
  'we',
  'they',
  'them',
  'some',
  'very',
  'just',
  'about',
  'around',
  'near',
  'into',
  'onto',
  'if',
  'but',
  'so',
  'not',
  'no',
  'any',
  'one',
  'lost',
  'found',
  'item',
  'left',
  'please',
  'contact',
  'someone',
  'think',
  'maybe',
  'also',
  'had',
  'did',
  'got',
  'can',
  'will',
};

/// Lower-cases [text], replaces punctuation with spaces and collapses
/// whitespace. Letters (with combining marks, e.g. Sinhala vowel signs) and
/// digits from any script are kept.
String normalizeText(String text) {
  return text
      .toLowerCase()
      .replaceAll(RegExp(r"['’]"), '')
      .replaceAll(RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true), ' ')
      .trim();
}

/// Splits [text] into a set of meaningful keywords.
///
/// Stop words and single characters are removed, and a simple plural rule
/// folds `keys` → `key` so that singular and plural forms compare equal. This
/// is intentionally crude but fully predictable.
Set<String> extractKeywords(
  String text, {
  Set<String> stopWords = englishStopWords,
}) {
  final normalized = normalizeText(text);
  if (normalized.isEmpty) return <String>{};
  return normalized
      .split(' ')
      .where((token) => token.length > 1 && !stopWords.contains(token))
      .map(_singularize)
      .toSet();
}

String _singularize(String token) {
  if (token.length > 5 && token.endsWith('sses')) {
    return token.substring(0, token.length - 2);
  }
  if (token.length > 4 && token.endsWith('ies')) {
    return '${token.substring(0, token.length - 3)}y';
  }
  if (token.length > 3 &&
      token.endsWith('s') &&
      !token.endsWith('ss') &&
      !token.endsWith('us')) {
    return token.substring(0, token.length - 1);
  }
  return token;
}

/// Jaccard similarity |A ∩ B| / |A ∪ B|. Returns 0 when either set is empty.
double jaccardSimilarity(Set<String> a, Set<String> b) {
  if (a.isEmpty || b.isEmpty) return 0;
  final intersection = a.intersection(b).length;
  final union = a.union(b).length;
  return intersection / union;
}
