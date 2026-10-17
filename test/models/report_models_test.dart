import 'package:findly/models/item_category.dart';
import 'package:findly/models/item_report.dart';
import 'package:findly/models/report_draft.dart';
import 'package:findly/models/report_filter.dart';
import 'package:findly/models/report_status.dart';
import 'package:findly/models/report_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fixtures.dart';

ReportDraft draft({
  String title = 'Blue water bottle',
  String description = 'Steel bottle with a sticker',
  String location = 'Gym',
  DateTime? eventDate,
}) => ReportDraft(
  type: ReportType.found,
  title: title,
  description: description,
  category: ItemCategory.bottles,
  location: location,
  eventDate: eventDate ?? DateTime(2026, 10, 15),
);

void main() {
  final now = DateTime(2026, 10, 16, 9);

  group('ReportDraft.validate', () {
    test('a complete draft is valid', () {
      expect(draft().validate(now: now), isEmpty);
    });

    test('required fields report errors when blank or whitespace', () {
      final errors = draft(
        title: '   ',
        description: '',
        location: ' ',
      ).validate(now: now);
      expect(errors.keys, containsAll(['title', 'description', 'location']));
    });

    test('length boundaries', () {
      expect(ReportDraft.validateTitle('ab'), isNotNull);
      expect(ReportDraft.validateTitle('abc'), isNull);
      expect(ReportDraft.validateTitle('a' * ReportLimits.titleMax), isNull);
      expect(
        ReportDraft.validateTitle('a' * (ReportLimits.titleMax + 1)),
        isNotNull,
      );
      expect(ReportDraft.validateDescription('a' * 9), isNotNull);
      expect(ReportDraft.validateDescription('a' * 10), isNull);
    });

    test('lengths are measured after trimming', () {
      expect(ReportDraft.validateTitle('  ab  '), isNotNull);
    });

    test('today is allowed, tomorrow is not', () {
      expect(
        ReportDraft.validateEventDate(DateTime(2026, 10, 16), now: now),
        isNull,
      );
      expect(
        ReportDraft.validateEventDate(DateTime(2026, 10, 17), now: now),
        isNotNull,
      );
    });

    test('very old dates are rejected', () {
      expect(
        ReportDraft.validateEventDate(DateTime(1999, 12, 31), now: now),
        isNotNull,
      );
    });

    test('toJson trims text and writes only client-owned columns', () {
      final json = draft(title: '  Bottle  ').toJson();
      expect(json['title'], 'Bottle');
      expect(json['event_date'], '2026-10-15');
      expect(json.keys, isNot(contains('owner_id')));
      expect(json.keys, isNot(contains('status')));
    });
  });

  group('ItemReport.fromJson', () {
    test('parses a database row', () {
      final report = ItemReport.fromJson({
        'id': 'r1',
        'owner_id': ownerA,
        'type': 'found',
        'status': 'resolved',
        'title': 'Keys',
        'description': 'Three keys on a ring',
        'category': 'keys',
        'location': 'Car park',
        'event_date': '2026-10-01',
        'created_at': '2026-10-01T10:00:00+00:00',
        'resolved_at': '2026-10-02T10:00:00+00:00',
        'photo_path': null,
        'is_demo': true,
      });
      expect(report.type, ReportType.found);
      expect(report.status, ReportStatus.resolved);
      expect(report.category, ItemCategory.keys);
      expect(report.eventDate, DateTime(2026, 10, 1));
      expect(report.resolvedAt, isNotNull);
      expect(report.hasPhoto, isFalse);
      expect(report.isDemo, isTrue);
    });

    test('rejects an unknown report type', () {
      expect(() => ReportType.fromDb('stolen'), throwsFormatException);
    });
  });

  group('ReportStatus transitions', () {
    test('active ↔ resolved are the only transitions', () {
      expect(
        ReportStatus.active.canTransitionTo(ReportStatus.resolved),
        isTrue,
      );
      expect(
        ReportStatus.resolved.canTransitionTo(ReportStatus.active),
        isTrue,
      );
      expect(ReportStatus.active.canTransitionTo(ReportStatus.active), isFalse);
    });

    test('ownership check requires a signed-in matching user', () {
      final report = makeReport(ownerId: ownerA);
      expect(report.isOwnedBy(ownerA), isTrue);
      expect(report.isOwnedBy(ownerB), isFalse);
      expect(report.isOwnedBy(null), isFalse);
    });
  });

  group('ReportFilter', () {
    final lostBag = makeReport(
      id: 'lost-bag',
      type: ReportType.lost,
      title: 'Red backpack',
      location: 'Library',
      createdAt: DateTime(2026, 10, 1),
    );
    final foundBag = makeReport(
      id: 'found-bag',
      type: ReportType.found,
      title: 'Backpack',
      description: 'Grey backpack',
      location: 'Canteen',
      createdAt: DateTime(2026, 10, 3),
    );
    final resolvedKeys = makeReport(
      id: 'keys',
      type: ReportType.found,
      status: ReportStatus.resolved,
      title: 'Car keys',
      description: 'Toyota key with fob',
      category: ItemCategory.keys,
      location: 'Library car park',
      createdAt: DateTime(2026, 10, 2),
    );
    final all = [lostBag, foundBag, resolvedKeys];
    List<String> ids(ReportFilter f) => f.apply(all).map((r) => r.id).toList();

    test('empty filter returns everything newest first', () {
      expect(ids(ReportFilter.empty), ['found-bag', 'keys', 'lost-bag']);
      expect(ReportFilter.empty.isEmpty, isTrue);
    });

    test('query searches title, description, category and location', () {
      expect(ids(const ReportFilter(query: 'toyota')), ['keys']);
      expect(ids(const ReportFilter(query: 'canteen')), ['found-bag']);
      expect(ids(const ReportFilter(query: 'Bags')), ['found-bag', 'lost-bag']);
    });

    test(
      'query is case- and punctuation-insensitive and requires all terms',
      () {
        expect(ids(const ReportFilter(query: 'LIBRARY, backpack!')), [
          'lost-bag',
        ]);
      },
    );

    test('type, status and category filters combine with the query', () {
      expect(ids(const ReportFilter(type: ReportType.found)), [
        'found-bag',
        'keys',
      ]);
      expect(ids(const ReportFilter(status: ReportStatus.resolved)), ['keys']);
      expect(
        ids(const ReportFilter(query: 'library', type: ReportType.found)),
        ['keys'],
      );
      expect(
        ids(
          const ReportFilter(
            query: 'library',
            type: ReportType.found,
            status: ReportStatus.active,
          ),
        ),
        isEmpty,
      );
      expect(ids(const ReportFilter(category: ItemCategory.keys)), ['keys']);
    });

    test('copyWith can clear a filter back to "any"', () {
      const filter = ReportFilter(type: ReportType.lost, query: 'bag');
      final cleared = filter.copyWith(type: () => null);
      expect(cleared.type, isNull);
      expect(cleared.query, 'bag');
    });
  });
}
