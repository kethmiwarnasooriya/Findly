import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';
import '../core/errors/app_exception.dart';

/// Thin wrapper over Supabase Auth that converts failures to [AppException].
class AuthService {
  AuthService(this._auth);

  final GoTrueClient _auth;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;
  Session? get currentSession => _auth.currentSession;

  Future<void> signIn({required String email, required String password}) =>
      _run(
        () => _auth.signInWithPassword(email: email.trim(), password: password),
      );

  /// Returns `true` when the user must confirm their email before signing in.
  Future<bool> signUp({required String email, required String password}) =>
      _run(() async {
        final response = await _auth.signUp(
          email: email.trim(),
          password: password,
          emailRedirectTo: AppConfig.authRedirectUrl,
        );
        return response.session == null;
      });

  Future<void> resendConfirmation(String email) => _run(
    () => _auth.resend(
      type: OtpType.signup,
      email: email.trim(),
      emailRedirectTo: AppConfig.authRedirectUrl,
    ),
  );

  Future<void> sendPasswordReset(String email) => _run(
    () => _auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: AppConfig.authRedirectUrl,
    ),
  );

  Future<void> updatePassword(String newPassword) =>
      _run(() => _auth.updateUser(UserAttributes(password: newPassword)));

  /// Clears the local session even if the server cannot be reached.
  Future<void> signOut() async {
    try {
      await _auth.signOut().timeout(AppConfig.requestTimeout);
    } catch (_) {}
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(AppConfig.requestTimeout);
    } catch (error) {
      throw AppException.from(error);
    }
  }
}
