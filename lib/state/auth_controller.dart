import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_service.dart';

/// Exposes the current session, whether the user arrived through a
/// password-reset link, and problems with email links.
class AuthController extends ChangeNotifier {
  AuthController(this.service) : _session = service.currentSession {
    _subscription = service.authStateChanges.listen(
      _onAuthState,
      onError: _onAuthError,
    );
  }

  final AuthService service;
  late final StreamSubscription<AuthState> _subscription;

  Session? _session;
  bool _isRecoveringPassword = false;
  String? _linkError;

  Session? get session => _session;
  String? get userId => _session?.user.id;
  String? get email => _session?.user.email;
  bool get isSignedIn => _session != null;
  bool get isRecoveringPassword => _isRecoveringPassword;

  /// A user-facing explanation when an email confirmation or password-reset
  /// link could not be used, e.g. because it expired or was already opened.
  String? get linkError => _linkError;

  void clearLinkError() {
    _linkError = null;
    notifyListeners();
  }

  void _onAuthState(AuthState state) {
    _session = state.session;
    if (_session != null) _linkError = null;
    switch (state.event) {
      case AuthChangeEvent.passwordRecovery:
        _isRecoveringPassword = true;
      case AuthChangeEvent.signedOut:
        _isRecoveringPassword = false;
      default:
        break;
    }
    notifyListeners();
  }

  /// Errors on this stream come from deep links (and occasionally failed
  /// token refreshes, which also surface through API calls). Only link
  /// errors are shown to the user.
  void _onAuthError(Object error) {
    if (error is! AuthException) return;
    final details = '${error.code} ${error.statusCode} ${error.message}'
        .toLowerCase();
    if (!details.contains('expired') &&
        !details.contains('invalid') &&
        !details.contains('access_denied')) {
      return;
    }
    _linkError = details.contains('expired')
        ? 'That email link has expired or was already used. If you already '
              'confirmed your account, just sign in. Otherwise request a new '
              'link and open only the newest email.'
        : "That email link couldn't be used. Please request a new one.";
    notifyListeners();
  }

  Future<void> updatePassword(String newPassword) async {
    await service.updatePassword(newPassword);
    _isRecoveringPassword = false;
    notifyListeners();
  }

  Future<void> signOut() => service.signOut();

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
