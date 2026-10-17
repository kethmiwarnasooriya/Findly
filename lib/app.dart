import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/report_repository.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/auth/set_new_password_screen.dart';
import 'screens/home/home_screen.dart';
import 'state/auth_controller.dart';
import 'state/reports_controller.dart';
import 'state/settings_controller.dart';

/// Root widget. Chooses the first screen from the auth state and scopes
/// report data to the signed-in user, so signing out discards it.
class FindlyApp extends StatelessWidget {
  const FindlyApp({super.key, required this.createRepository});

  final ReportRepository Function() createRepository;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final themeMode = context.select<SettingsController, ThemeMode>(
      (settings) => settings.themeMode,
    );
    final userId = auth.userId;

    final app = MaterialApp(
      title: 'Findly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: switch (auth) {
        AuthController(isRecoveringPassword: true) =>
          const SetNewPasswordScreen(),
        AuthController(isSignedIn: true) => const HomeScreen(),
        _ => const AuthScreen(),
      },
    );

    if (userId == null) return app;
    return ChangeNotifierProvider<ReportsController>(
      key: ValueKey(userId),
      create: (_) => ReportsController(repository: createRepository())..load(),
      child: app,
    );
  }
}

/// Shown instead of the app when it was built without Supabase settings.
class MissingConfigApp extends StatelessWidget {
  const MissingConfigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Findly is not configured.\n\n'
                'Run with:\nflutter run --dart-define-from-file=env/dev.json\n\n'
                'See docs/SUPABASE_SETUP.md.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
