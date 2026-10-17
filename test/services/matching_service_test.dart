import 'package:findly/models/item_category.dart';
import 'package:findly/models/report_status.dart';
import 'package:findly/models/report_type.dart';
import 'package:findly/services/matching_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fixtures.dart';

void main() {
  const service = MatchingService();

  group('categoryScore', () {
    test('same category scores 1, different scores 0', () {
      final bag = makeReport(category: ItemCategory.bags);
      expect(
        service.categoryScore(bag, makeReport(category: ItemCategory.bags)),
        1,
      );
      expect(
        service.categoryScore(bag, makeReport(category: ItemCategory.keys)),
        0,
      );
    });
  });

  group('locationScore', () {
    test('identical text after normalization scores 1', () {
      expect(service.locationScore('Main Library', 'main  library!'), 1);
    });

    test('partial word overlap scores between 0 and 1', () {
      final score = service.locationScore(
        'Main library 2nd floor',
        'Library ground floor',
      );
      expect(score, greaterThan(0));
      expect(score, lessThan(1));
    });

    test('generic place words alone do not create similarity', () {
      expect(
        service.locationScore('near the entrance area', 'outside cafe area'),
        0,
      );
    });

    test('unrelated places score 0', () {
      expect(service.locationScore('Bus stop', 'Science lab'), 0);
    });

    test('empty location scores 0', () {
      expect(service.locationScore('', 'Library'), 0);
      expect(service.locationScore('!!', '??'), 0);
    });
  });

  group('dateScore', () {
    final lost = DateTime(2026, 10, 10);

    test('same day scores 1', () {
      expect(service.dateScore(lost, DateTime(2026, 10, 10)), 1);
    });

    test('decays linearly inside the window', () {
      expect(
        service.dateScore(lost, DateTime(2026, 10, 17)),
        closeTo(0.5, 1e-9),
      );
    });

    test('scores 0 at and beyond the window boundary', () {
      expect(service.dateScore(lost, DateTime(2026, 10, 24)), 0);
      expect(service.dateScore(lost, DateTime(2026, 11, 30)), 0);
    });

    test('found one day before lost is tolerated', () {
      expect(service.dateScore(lost, DateTime(2026, 10, 9)), greaterThan(0));
    });

    test('found well before lost scores 0', () {
      expect(service.dateScore(lost, DateTime(2026, 10, 1)), 0);
    });

    test('window is configurable', () {
      const narrow = MatchingService(config: MatchingConfig(dateWindowDays: 2));
      expect(
        narrow.dateScore(lost, DateTime(2026, 10, 11)),
        closeTo(0.5, 1e-9),
      );
      expect(narrow.dateScore(lost, DateTime(2026, 10, 12)), 0);
    });
  });

  group('scorePair', () {
    test('identical lost/found reports score the maximum 100', () {
      final lost = makeReport(type: ReportType.lost);
      final found = makeReport(type: ReportType.found);
      final result = service.scorePair(lost, found)!;
      expect(result.breakdown.category, 40);
      expect(result.breakdown.description, 30);
      expect(result.breakdown.location, 20);
      expect(result.breakdown.date, 10);
      expect(result.score, 100);
    });

    test('total is the sum of component points', () {
      final lost = makeReport(
        type: ReportType.lost,
        title: 'Blue umbrella',
        description: 'Blue folding umbrella with wooden handle',
        category: ItemCategory.accessories,
        location: 'Canteen',
      );
      final found = makeReport(
        type: ReportType.found,
        title: 'Umbrella',
        description: 'Found an umbrella, blue colour',
        category: ItemCategory.other,
        location: 'Main library',
        eventDate: DateTime(2026, 10, 13),
      );
      final result = service.scorePair(lost, found)!;
      final b = result.breakdown;
      expect(b.category, 0);
      expect(b.location, 0);
      expect(b.description, greaterThan(0));
      expect(b.date, 8); // 1 - 3/14 = 0.786 → 7.86 → 8
      expect(result.score, b.category + b.description + b.location + b.date);
    });

    test('is symmetric regardless of which report is the target', () {
      final lost = makeReport(
        type: ReportType.lost,
        eventDate: DateTime(2026, 10, 10),
      );
      final found = makeReport(
        type: ReportType.found,
        title: 'Backpack',
        eventDate: DateTime(2026, 10, 12),
      );
      expect(
        service.scorePair(lost, found)!.score,
        service.scorePair(found, lost)!.score,
      );
    });

    test('rejects a found date far before the lost date', () {
      final lost = makeReport(
        type: ReportType.lost,
        eventDate: DateTime(2026, 10, 10),
      );
      final found = makeReport(
        type: ReportType.found,
        eventDate: DateTime(2026, 10, 1),
      );
      expect(service.scorePair(lost, found), isNull);
    });

    test('explains each contributing component', () {
      final lost = makeReport(type: ReportType.lost);
      final found = makeReport(
        type: ReportType.found,
        eventDate: DateTime(2026, 10, 12),
      );
      final reasons = service.scorePair(lost, found)!.reasons;
      expect(reasons, contains('Same category: Bags'));
      expect(
        reasons.any((r) => r.startsWith('Shared description words:')),
        isTrue,
      );
      expect(reasons, contains('Same location text'));
      expect(reasons, contains('Dates are 2 days apart'));
    });

    test('gives no reasons for components that scored 0', () {
      final lost = makeReport(
        type: ReportType.lost,
        title: 'Calculator',
        description: 'Casio scientific calculator',
        category: ItemCategory.electronics,
        location: 'Exam hall',
      );
      final found = makeReport(
        type: ReportType.found,
        title: 'Calculator',
        description: 'Casio calculator on a desk',
        category: ItemCategory.booksStationery,
        location: 'Bus stop',
        eventDate: DateTime(2026, 12, 1),
      );
      final reasons = service.scorePair(lost, found)!.reasons;
      expect(reasons.length, 1);
      expect(
        reasons.single,
        startsWith('Shared description words: calculator, casio'),
      );
    });
  });

  group('isEligiblePair', () {
    final lost = makeReport(type: ReportType.lost);

    test('lost vs found is eligible', () {
      expect(
        service.isEligiblePair(lost, makeReport(type: ReportType.found)),
        isTrue,
      );
    });

    test('same type is not eligible', () {
      expect(
        service.isEligiblePair(lost, makeReport(type: ReportType.lost)),
        isFalse,
      );
    });

    test('a report never matches itself', () {
      expect(service.isEligiblePair(lost, lost), isFalse);
    });

    test('resolved candidates and targets are excluded', () {
      final resolvedFound = makeReport(
        type: ReportType.found,
        status: ReportStatus.resolved,
      );
      expect(service.isEligiblePair(lost, resolvedFound), isFalse);
      final resolvedLost = makeReport(
        type: ReportType.lost,
        status: ReportStatus.resolved,
      );
      expect(
        service.isEligiblePair(
          resolvedLost,
          makeReport(type: ReportType.found),
        ),
        isFalse,
      );
    });
  });

  group('findMatches', () {
    test(
      'returns only eligible candidates above the minimum score, best first',
      () {
        final target = makeReport(type: ReportType.lost);
        final best = makeReport(id: 'best', type: ReportType.found);
        final partial = makeReport(
          id: 'partial',
          type: ReportType.found,
          title: 'Backpack',
          description: 'Grey backpack',
          location: 'Library entrance',
          eventDate: DateTime(2026, 10, 15),
        );
        final unrelated = makeReport(
          id: 'unrelated',
          type: ReportType.found,
          title: 'Earrings',
          description: 'Silver earrings',
          category: ItemCategory.accessories,
          location: 'Gym',
          eventDate: DateTime(2026, 9, 1),
        );
        final sameType = makeReport(id: 'same-type', type: ReportType.lost);
        final resolved = makeReport(
          id: 'resolved',
          type: ReportType.found,
          status: ReportStatus.resolved,
        );

        final results = service.findMatches(target, [
          unrelated,
          partial,
          sameType,
          resolved,
          best,
          target,
        ]);

        expect(results.map((r) => r.candidate.id), ['best', 'partial']);
        expect(results.first.score, greaterThan(results.last.score));
      },
    );

    test('a resolved target has no matches', () {
      final target = makeReport(
        type: ReportType.lost,
        status: ReportStatus.resolved,
      );
      expect(
        service.findMatches(target, [makeReport(type: ReportType.found)]),
        isEmpty,
      );
    });

    test('ties are broken by closer date', () {
      final target = makeReport(
        type: ReportType.lost,
        eventDate: DateTime(2026, 10, 10),
      );
      const noDates = MatchingService(config: MatchingConfig(dateWeight: 0));
      final far = makeReport(
        id: 'far',
        type: ReportType.found,
        eventDate: DateTime(2026, 10, 13),
      );
      final near = makeReport(
        id: 'near',
        type: ReportType.found,
        eventDate: DateTime(2026, 10, 11),
      );
      final results = noDates.findMatches(target, [far, near]);
      expect(results.first.score, results.last.score);
      expect(results.map((r) => r.candidate.id), ['near', 'far']);
    });

    test('respects maxResults', () {
      const limited = MatchingService(config: MatchingConfig(maxResults: 2));
      final target = makeReport(type: ReportType.lost);
      final pool = List.generate(5, (_) => makeReport(type: ReportType.found));
      expect(limited.findMatches(target, pool), hasLength(2));
    });

    test('handles empty descriptions and locations without errors', () {
      final target = makeReport(
        type: ReportType.lost,
        description: '',
        location: '',
      );
      final candidate = makeReport(
        type: ReportType.found,
        description: '',
        location: '',
      );
      final result = service.scorePair(target, candidate)!;
      expect(result.breakdown.location, 0);
      expect(result.score, inInclusiveRange(0, 100));
    });
  });
}
