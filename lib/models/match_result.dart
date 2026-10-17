import 'item_report.dart';

/// Points awarded to a candidate for each scoring component.
class ScoreBreakdown {
  const ScoreBreakdown({
    required this.category,
    required this.description,
    required this.location,
    required this.date,
  });

  final int category;
  final int description;
  final int location;
  final int date;

  int get total => category + description + location + date;
}

/// How much weight a user should give a suggestion. A high score is a reason
/// to look closer, never proof that two reports describe the same item.
enum MatchStrength {
  strong('Strong match'),
  possible('Possible match'),
  weak('Weak match');

  const MatchStrength(this.label);
  final String label;
}

/// A candidate report suggested for a target report, with its explanation.
class MatchResult {
  const MatchResult({
    required this.candidate,
    required this.breakdown,
    required this.reasons,
    required this.sharedKeywords,
    required this.dayDifference,
  });

  final ItemReport candidate;
  final ScoreBreakdown breakdown;

  /// Human-readable explanations, most significant first.
  final List<String> reasons;
  final Set<String> sharedKeywords;

  /// Absolute days between the two event dates.
  final int dayDifference;

  int get score => breakdown.total;

  MatchStrength get strength => switch (score) {
    >= 70 => MatchStrength.strong,
    >= 45 => MatchStrength.possible,
    _ => MatchStrength.weak,
  };
}
