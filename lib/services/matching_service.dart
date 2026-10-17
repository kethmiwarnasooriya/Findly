import '../core/utils/date_utils.dart';
import '../core/utils/text_normalizer.dart';
import '../models/item_report.dart';
import '../models/match_result.dart';
import '../models/report_type.dart';

/// Tunable parameters for [MatchingService].
///
/// The default weights are initial product assumptions, not measured values.
class MatchingConfig {
  const MatchingConfig({
    this.categoryWeight = 40,
    this.descriptionWeight = 30,
    this.locationWeight = 20,
    this.dateWeight = 10,
    this.dateWindowDays = 14,
    this.foundBeforeLostToleranceDays = 1,
    this.minimumScore = 25,
    this.maxResults = 20,
  }) : assert(dateWindowDays > 0),
       assert(foundBeforeLostToleranceDays >= 0);

  final int categoryWeight;
  final int descriptionWeight;
  final int locationWeight;
  final int dateWeight;

  /// Dates further apart than this earn no date points.
  final int dateWindowDays;

  /// How many days earlier than the loss a "found" date may be and still be
  /// considered. Dates are approximate, so a small tolerance avoids
  /// discarding genuine matches; anything earlier is physically implausible.
  final int foundBeforeLostToleranceDays;

  /// Candidates scoring below this are not suggested.
  final int minimumScore;
  final int maxResults;

  int get maxScore =>
      categoryWeight + descriptionWeight + locationWeight + dateWeight;
}

/// Explainable, deterministic matching between lost and found reports.
///
/// Each component returns a similarity in the range 0..1 and is exposed
/// separately so it can be unit-tested and explained to the user.
class MatchingService {
  const MatchingService({this.config = const MatchingConfig()});

  final MatchingConfig config;

  /// Generic place words that say nothing about *which* place it was.
  static const Set<String> locationStopWords = {
    ...englishStopWords,
    'area',
    'place',
    'side',
    'inside',
    'outside',
    'next',
    'behind',
    'front',
    'opposite',
    'beside',
    'close',
  };

  /// Returns active candidates of the opposite type, best match first.
  ///
  /// Resolved targets get no suggestions: there is nothing left to find.
  List<MatchResult> findMatches(ItemReport target, Iterable<ItemReport> pool) {
    if (!target.isActive) return const [];

    final results = <MatchResult>[];
    for (final candidate in pool) {
      if (!isEligiblePair(target, candidate)) continue;
      final result = scorePair(target, candidate);
      if (result != null && result.score >= config.minimumScore) {
        results.add(result);
      }
    }

    results.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      final byDate = a.dayDifference.compareTo(b.dayDifference);
      if (byDate != 0) return byDate;
      return b.candidate.createdAt.compareTo(a.candidate.createdAt);
    });
    return results.take(config.maxResults).toList(growable: false);
  }

  /// Only an active lost report and an active found report can match, and a
  /// report never matches itself.
  bool isEligiblePair(ItemReport target, ItemReport candidate) {
    return target.id != candidate.id &&
        target.isActive &&
        candidate.isActive &&
        candidate.type == target.type.opposite;
  }

  /// Scores an eligible pair, or returns `null` if the dates make the pair
  /// implausible (the item was "found" well before it was lost).
  MatchResult? scorePair(ItemReport target, ItemReport candidate) {
    final lost = target.type == ReportType.lost ? target : candidate;
    final found = identical(lost, target) ? candidate : target;

    final days = daysBetween(lost.eventDate, found.eventDate);
    if (days < -config.foundBeforeLostToleranceDays) return null;

    final categorySimilarity = categoryScore(target, candidate);
    final targetKeywords = itemKeywords(target);
    final candidateKeywords = itemKeywords(candidate);
    final descriptionSimilarity = jaccardSimilarity(
      targetKeywords,
      candidateKeywords,
    );
    final locationSimilarity = locationScore(
      target.location,
      candidate.location,
    );
    final dateSimilarity = dateScore(lost.eventDate, found.eventDate);

    final breakdown = ScoreBreakdown(
      category: (categorySimilarity * config.categoryWeight).round(),
      description: (descriptionSimilarity * config.descriptionWeight).round(),
      location: (locationSimilarity * config.locationWeight).round(),
      date: (dateSimilarity * config.dateWeight).round(),
    );
    final shared = targetKeywords.intersection(candidateKeywords);

    return MatchResult(
      candidate: candidate,
      breakdown: breakdown,
      sharedKeywords: shared,
      dayDifference: days.abs(),
      reasons: _explain(
        target: target,
        candidate: candidate,
        breakdown: breakdown,
        sharedKeywords: shared,
        days: days.abs(),
      ),
    );
  }

  /// 1 if both reports use the same category, otherwise 0.
  double categoryScore(ItemReport a, ItemReport b) =>
      a.category == b.category ? 1 : 0;

  /// Keywords from the title and description together, because people often
  /// put the most distinctive word ("AirPods", "Casio") only in the title.
  Set<String> itemKeywords(ItemReport report) =>
      extractKeywords('${report.title} ${report.description}');

  /// Conservative text comparison of two free-text locations.
  ///
  /// Identical normalized text scores 1; otherwise the Jaccard similarity of
  /// meaningful location words. This only says the *descriptions* overlap.
  /// It makes no claim that two different places are physically near.
  double locationScore(String a, String b) {
    final normalizedA = normalizeText(a);
    final normalizedB = normalizeText(b);
    if (normalizedA.isEmpty || normalizedB.isEmpty) return 0;
    if (normalizedA == normalizedB) return 1;
    return jaccardSimilarity(
      extractKeywords(a, stopWords: locationStopWords),
      extractKeywords(b, stopWords: locationStopWords),
    );
  }

  /// Linear decay from 1 (same day) to 0 at [MatchingConfig.dateWindowDays].
  ///
  /// [lostDate] and [foundDate] are compared as calendar dates. A found date
  /// earlier than the lost date (beyond the tolerance) scores 0.
  double dateScore(DateTime lostDate, DateTime foundDate) {
    final days = daysBetween(lostDate, foundDate);
    if (days < -config.foundBeforeLostToleranceDays) return 0;
    final distance = days.abs();
    if (distance >= config.dateWindowDays) return 0;
    return 1 - distance / config.dateWindowDays;
  }

  List<String> _explain({
    required ItemReport target,
    required ItemReport candidate,
    required ScoreBreakdown breakdown,
    required Set<String> sharedKeywords,
    required int days,
  }) {
    final reasons = <String>[];
    if (breakdown.category > 0) {
      reasons.add('Same category: ${candidate.category.label}');
    }
    if (sharedKeywords.isNotEmpty) {
      final words = (sharedKeywords.toList()..sort()).take(6).join(', ');
      reasons.add('Shared description words: $words');
    }
    if (breakdown.location > 0) {
      reasons.add(
        breakdown.location == config.locationWeight
            ? 'Same location text'
            : 'Similar location wording',
      );
    }
    if (breakdown.date > 0) {
      reasons.add(switch (days) {
        0 => 'Reported for the same day',
        1 => 'Dates are 1 day apart',
        _ => 'Dates are $days days apart',
      });
    }
    return reasons;
  }
}
