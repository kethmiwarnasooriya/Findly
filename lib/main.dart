import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'data/auth_service.dart';
import 'data/secure_session_storage.dart';
import 'data/supabase_report_repository.dart';
import 'state/auth_controller.dart';
import 'state/settings_controller.dart';
import 'widgets/loading.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(_fontLicenses);

  if (!AppConfig.isConfigured) {
    runApp(const MissingConfigApp());
    return;
  }

  // Branded splash while the backend client and settings load. A short
  // minimum avoids a jarring flash on fast devices.
  runApp(
    const Directionality(textDirection: TextDirection.ltr, child: BootSplash()),
  );

  final settings = SettingsController(SharedPreferencesSettingsStore());
  await Future.wait([
    Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureSessionStorage(),
      ),
    ),
    settings.load(),
    Future<void>.delayed(const Duration(milliseconds: 700)),
  ]);
  final client = Supabase.instance.client;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(
          create: (_) => AuthController(AuthService(client.auth)),
        ),
      ],
      child: FindlyApp(
        createRepository: () => SupabaseReportRepository(client),
      ),
    ),
  );
}

Stream<LicenseEntry> _fontLicenses() async* {
  final text = await rootBundle.loadString('assets/licenses/poppins_OFL.txt');
  yield LicenseEntryWithLineBreaks(const ['Poppins (font)'], text);
}
