import 'package:findly/models/item_category.dart';
import 'package:findly/models/report_status.dart';
import 'package:findly/screens/item_details/item_details_screen.dart';
import 'package:findly/screens/matches/matches_screen.dart';
import 'package:findly/screens/report/report_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_report_repository.dart';
import '../support/test_app.dart';

void main() {
  group('Report form', () {
    testWidgets('blocks submission and explains missing required fields', (
      tester,
    ) async {
      final repository = InMemoryReportRepository();
      final controller = await pumpWithReports(
        tester,
        repository: repository,
        child: const ReportFormScreen(),
      );

      await scrollPageTo(tester, find.text('Post report'), delta: 200);
      await tester.tap(find.text('Post report'));
      await tester.pumpAndSettle();

      await scrollPageTo(
        tester,
        find.text('Please enter a title'),
        delta: -200,
      );
      expect(find.text('Please enter a title'), findsOneWidget);
      expect(find.text('Choose a category'), findsOneWidget);
      expect(controller.allReports, isEmpty);
    });

    testWidgets('a valid report is saved and added to the list', (
      tester,
    ) async {
      final repository = InMemoryReportRepository();
      final controller = await pumpWithReports(
        tester,
        repository: repository,
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ReportFormScreen(),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'What is it?'),
        'Blue umbrella',
      );
      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<ItemCategory>, 'Category'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accessories').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description'),
        'Folding umbrella with a wooden handle',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Where did you lose it?'),
        'Canteen',
      );

      await scrollPageTo(tester, find.text('Post report'), delta: 200);
      await tester.tap(find.text('Post report'));
      await tester.pumpAndSettle();

      expect(find.byType(ReportFormScreen), findsNothing);
      expect(find.text('Report posted. Thank you!'), findsOneWidget);
      expect(controller.allReports.single.title, 'Blue umbrella');
      expect(controller.allReports.single.category, ItemCategory.accessories);
    });
  });

  group('Item details', () {
    testWidgets('owner can mark a report resolved after confirming', (
      tester,
    ) async {
      final controller = await pumpWithReports(
        tester,
        repository: InMemoryReportRepository(seed: demoReports()),
        child: const ItemDetailsScreen(reportId: 'my-backpack'),
      );

      expect(find.text('Black laptop backpack'), findsOneWidget);
      expect(find.text('Your report'), findsOneWidget);

      await scrollPageTo(tester, find.text('Mark as resolved'), delta: 200);
      await tester.tap(find.text('Mark as resolved'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark resolved'));
      await tester.pumpAndSettle();

      expect(
        controller.reportById('my-backpack')!.status,
        ReportStatus.resolved,
      );
      expect(find.text('Marked as resolved'), findsOneWidget);
      expect(find.text('Reopen report'), findsOneWidget);
    });

    testWidgets('cancelling the confirmation leaves the report unchanged', (
      tester,
    ) async {
      final controller = await pumpWithReports(
        tester,
        repository: InMemoryReportRepository(seed: demoReports()),
        child: const ItemDetailsScreen(reportId: 'my-backpack'),
      );

      await scrollPageTo(tester, find.text('Mark as resolved'), delta: 200);
      await tester.tap(find.text('Mark as resolved'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(controller.reportById('my-backpack')!.status, ReportStatus.active);
    });

    testWidgets("owner actions are hidden on someone else's report", (
      tester,
    ) async {
      await pumpWithReports(
        tester,
        repository: InMemoryReportRepository(seed: demoReports()),
        child: const ItemDetailsScreen(reportId: 'found-keys'),
      );

      expect(find.text('Mark as resolved'), findsNothing);
      expect(find.byTooltip('More actions'), findsNothing);
    });

    testWidgets('matches screen lists the explained suggestion', (
      tester,
    ) async {
      await pumpWithReports(
        tester,
        repository: InMemoryReportRepository(seed: demoReports()),
        child: const MatchesScreen(reportId: 'my-backpack'),
      );

      expect(find.text('Backpack'), findsOneWidget);
      expect(find.text('Same category: Bags'), findsOneWidget);
      expect(find.text('Same location text'), findsOneWidget);
      expect(find.text('Car keys'), findsNothing);
    });
  });
}
