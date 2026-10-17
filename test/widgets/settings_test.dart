import 'package:findly/core/theme/app_theme.dart';
import 'package:findly/screens/home/home_screen.dart';
import 'package:findly/screens/settings/settings_screen.dart';
import 'package:findly/state/reports_controller.dart';
import 'package:findly/state/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../support/in_memory_report_repository.dart';
import '../support/test_app.dart';

class _MemoryStore implements SettingsStore {
  final values = <String, String>{};
  bool failReads = false;

  @override
  Future<String?> read(String key) async {
    if (failReads) throw StateError('storage unavailable');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

/// The settings screen inside a MaterialApp that follows the controller,
/// like the real app root.
Widget _app(SettingsController settings, Widget home) {
  return ChangeNotifierProvider.value(
    value: settings,
    child: Consumer<SettingsController>(
      builder: (context, s, _) => MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: s.themeMode,
        home: home,
      ),
    ),
  );
}

void main() {
  group('SettingsController', () {
    test('defaults to the system theme', () async {
      final settings = SettingsController(_MemoryStore());
      await settings.load();
      expect(settings.themeMode, ThemeMode.system);
    });

    test('saves the choice and restores it on the next launch', () async {
      final store = _MemoryStore();
      await SettingsController(store).setThemeMode(ThemeMode.dark);

      final restored = SettingsController(store);
      await restored.load();
      expect(restored.themeMode, ThemeMode.dark);
    });

    test('falls back to system when storage fails or holds junk', () async {
      final store = _MemoryStore()..values['theme_mode'] = 'purple';
      final settings = SettingsController(store);
      await settings.load();
      expect(settings.themeMode, ThemeMode.system);

      store.failReads = true;
      await settings.load();
      expect(settings.themeMode, ThemeMode.system);
    });
  });

  testWidgets('choosing Dark in settings switches the app theme', (
    tester,
  ) async {
    final settings = SettingsController(_MemoryStore());
    await tester.pumpWidget(_app(settings, const SettingsScreen()));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
      Brightness.light,
    );

    await tester.tap(find.bySemanticsLabel('Dark theme'));
    await tester.pumpAndSettle();

    expect(settings.themeMode, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('home screen renders in the dark theme without layout errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final settings = SettingsController(_MemoryStore());
    await settings.setThemeMode(ThemeMode.dark);
    final reports = ReportsController(
      repository: InMemoryReportRepository(seed: demoReports()),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: reports,
        child: _app(settings, const HomeScreen()),
      ),
    );
    await reports.load();
    await tester.pumpAndSettle();

    expect(find.text('Recently reported'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
