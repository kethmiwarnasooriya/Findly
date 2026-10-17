import 'package:findly/core/theme/app_theme.dart';
import 'package:findly/data/report_repository.dart';
import 'package:findly/models/item_category.dart';
import 'package:findly/models/item_report.dart';
import 'package:findly/models/report_status.dart';
import 'package:findly/models/report_type.dart';
import 'package:findly/state/reports_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fixtures.dart';

/// Wraps [child] with the theme and a [ReportsController] over [repository],
/// and waits for the initial load.
Future<ReportsController> pumpWithReports(
  WidgetTester tester, {
  required ReportRepository repository,
  required Widget child,
}) async {
  // A typical phone viewport (390 x 844 logical pixels) instead of the
  // default 800 x 600 test surface.
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final controller = ReportsController(repository: repository);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: controller,
      child: MaterialApp(theme: AppTheme.light(), home: child),
    ),
  );
  await controller.load();
  await tester.pumpAndSettle();
  return controller;
}

/// A small, realistic data set. 'me' owns the lost backpack.
List<ItemReport> demoReports() => [
  makeReport(
    id: 'my-backpack',
    ownerId: 'me',
    type: ReportType.lost,
    title: 'Black laptop backpack',
    description: 'Black backpack with a Lenovo charger inside',
    category: ItemCategory.bags,
    location: 'Main library',
    eventDate: DateTime(2026, 10, 10),
    createdAt: DateTime(2026, 10, 10, 9),
  ),
  makeReport(
    id: 'found-backpack',
    ownerId: 'someone-else',
    type: ReportType.found,
    title: 'Backpack',
    description: 'Found a black backpack with a charger',
    category: ItemCategory.bags,
    location: 'Main library',
    eventDate: DateTime(2026, 10, 11),
    createdAt: DateTime(2026, 10, 11, 9),
  ),
  makeReport(
    id: 'found-keys',
    ownerId: 'someone-else',
    type: ReportType.found,
    title: 'Car keys',
    description: 'Toyota key with a red fob',
    category: ItemCategory.keys,
    location: 'Car park',
    eventDate: DateTime(2026, 10, 9),
    createdAt: DateTime(2026, 10, 9, 9),
  ),
  makeReport(
    id: 'resolved-hoodie',
    ownerId: 'someone-else',
    type: ReportType.lost,
    status: ReportStatus.resolved,
    title: 'Navy hoodie',
    description: 'Navy hoodie with faculty logo',
    category: ItemCategory.clothing,
    location: 'Basketball court',
    eventDate: DateTime(2026, 10, 1),
    createdAt: DateTime(2026, 10, 1, 9),
  ),
];

/// Scrolls the page's main scrollable (not a text field's inner one) until
/// [finder] is visible.
Future<void> scrollPageTo(
  WidgetTester tester,
  Finder finder, {
  double delta = 200,
}) => tester.scrollUntilVisible(
  finder,
  delta,
  scrollable: find.byType(Scrollable).first,
);
