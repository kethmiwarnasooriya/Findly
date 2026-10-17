/// Build-time configuration passed with `--dart-define-from-file`.
///
/// Only the project URL and the client-side publishable (anon) key belong
/// here. Both are designed to ship inside the app; authorization is enforced
/// by row level security, not by keeping these values hidden. Never put a
/// service-role/secret key or database password in this file or in env files
/// used by the app.
abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  /// Deep link that email confirmation and password-reset links return to.
  /// Must also be listed under Authentication → URL Configuration → Redirect
  /// URLs in the Supabase dashboard, and match the Android intent filter.
  static const authRedirectUrl = 'com.findly.findly://login-callback';

  static const photoBucket = 'report-photos';
  static const maxPhotoBytes = 5 * 1024 * 1024;
  static const requestTimeout = Duration(seconds: 20);
  static const reportFetchLimit = 300;
}
