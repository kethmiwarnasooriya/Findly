import 'package:findly/core/errors/app_exception.dart';
import 'package:findly/models/report_type.dart';
import 'package:findly/screens/home/home_screen.dart';
import 'package:findly/screens/report/report_form_screen.dart';
import 'package:findly/widgets/header_panel.dart';
import 'package:findly/widgets/report_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_report_repository.dart';
import '../support/test_app.dart';

void main() {
  Finder cardTitled(String title) =>
      find.descendant(of: find.byType(ReportCard), matching: find.text(title));

  Future<void> scrollToResults(WidgetTester tester) async {
    await tester.dragUntilVisible(
      find.byType(ReportCard).first,
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders branding, summary counts and demo reports', (
    tester,
  ) async {
    await pumpWithReports(
      tester,
      repository: InMemoryReportRepository(seed: demoReports()),
      child: const HomeScreen(),
    );

    expect(find.text('Findly'), findsOneWidget);
    expect(find.text('Lost something? Find your way back.'), findsOneWidget);
    expect(find.text('Active lost'), findsOneWidget);
    expect(find.text('Active found'), findsOneWidget);
    expect(find.text('1'), findsOneWidget); // 1 active lost (hoodie resolved)
    expect(find.text('2'), findsOneWidget); // 2 active found
    expect(find.text('Recently reported'), findsOneWidget);

    await scrollToResults(tester);
    expect(cardTitled('Backpack'), findsOneWidget);
  });

  testWidgets('search and type filter narrow the list together', (
    tester,
  ) async {
    await pumpWithReports(
      tester,
      repository: InMemoryReportRepository(seed: demoReports()),
      child: const HomeScreen(),
    );

    await tester.enterText(find.byType(TextField).first, 'backpack');
    await tester.pumpAndSettle();
    expect(find.text('2 results'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(PillTabs<ReportType?>),
        matching: find.text('Found'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 result'), findsOneWidget);

    await scrollToResults(tester);
    expect(cardTitled('Backpack'), findsOneWidget);
    expect(cardTitled('Black laptop backpack'), findsNothing);
  });

  testWidgets('shows an empty state and can reset filters', (tester) async {
    await pumpWithReports(
      tester,
      repository: InMemoryReportRepository(seed: demoReports()),
      child: const HomeScreen(),
    );

    await tester.enterText(find.byType(TextField).first, 'unicorn');
    await tester.pumpAndSettle();
    expect(find.text('No matching reports'), findsOneWidget);

    expect(find.text('Reset filters'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Reset'));
    await tester.pumpAndSettle();
    expect(find.text('Recently reported'), findsOneWidget);
    expect(find.text('unicorn'), findsNothing);
  });

  testWidgets('shows a retryable error when the first load fails', (
    tester,
  ) async {
    final repository = InMemoryReportRepository(seed: demoReports())
      ..failNextWith = const AppException(
        AppErrorKind.network,
        'You appear to be offline.',
      );
    await pumpWithReports(
      tester,
      repository: repository,
      child: const HomeScreen(),
    );

    expect(find.text("Couldn't load reports"), findsOneWidget);
    expect(find.text('You appear to be offline.'), findsOneWidget);

    // The retry button sits low on the page; scroll it clear of the FAB.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load reports"), findsNothing);
    expect(find.text('Recently reported'), findsOneWidget);
  });

  testWidgets('the report button opens the form', (tester) async {
    await pumpWithReports(
      tester,
      repository: InMemoryReportRepository(seed: demoReports()),
      child: const HomeScreen(),
    );

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Report item'));
    await tester.pumpAndSettle();
    expect(find.byType(ReportFormScreen), findsOneWidget);
  });
}
