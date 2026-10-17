import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

enum AppErrorKind {
  network,
  timeout,
  sessionExpired,
  permissionDenied,
  notFound,
  validation,
  rateLimited,
  invalidCredentials,
  emailNotConfirmed,
  unknown,
}

/// A failure translated into something the UI can explain and act on.
///
/// Messages are written for users and never include tokens, request payloads
/// or server internals.
class AppException implements Exception {
  const AppException(this.kind, this.message);

  final AppErrorKind kind;
  final String message;

  /// Whether retrying the same action could reasonably succeed.
  bool get isRetryable =>
      kind == AppErrorKind.network ||
      kind == AppErrorKind.timeout ||
      kind == AppErrorKind.unknown;

  @override
  String toString() => 'AppException(${kind.name})';

  static const _network = AppException(
    AppErrorKind.network,
    'You appear to be offline. Check your connection and try again.',
  );
  static const _timeout = AppException(
    AppErrorKind.timeout,
    'The server took too long to respond. Please try again.',
  );
  static const _session = AppException(
    AppErrorKind.sessionExpired,
    'Your session has expired. Please sign in again.',
  );
  static const _permission = AppException(
    AppErrorKind.permissionDenied,
    "You don't have permission to do that.",
  );
  static const _unknown = AppException(
    AppErrorKind.unknown,
    'Something went wrong. Please try again.',
  );

  /// Maps errors thrown by Supabase, the network stack or timeouts.
  static AppException from(Object error) {
    return switch (error) {
      AppException() => error,
      TimeoutException() => _timeout,
      SocketException() || http.ClientException() => _network,
      AuthRetryableFetchException() => _network,
      AuthException() => _fromAuth(error),
      PostgrestException() => _fromPostgrest(error),
      StorageException() => _fromStorage(error),
      _ => _unknown,
    };
  }

  static AppException _fromAuth(AuthException error) {
    return switch (error.code) {
      'invalid_credentials' => const AppException(
        AppErrorKind.invalidCredentials,
        'Incorrect email or password.',
      ),
      'email_not_confirmed' => const AppException(
        AppErrorKind.emailNotConfirmed,
        'Please confirm your email address first. Check your inbox.',
      ),
      'user_already_exists' || 'email_exists' => const AppException(
        AppErrorKind.validation,
        'An account with this email already exists. Try signing in.',
      ),
      'weak_password' => const AppException(
        AppErrorKind.validation,
        'Choose a stronger password (at least 8 characters, mixing letters and numbers).',
      ),
      'same_password' => const AppException(
        AppErrorKind.validation,
        'Your new password must be different from the old one.',
      ),
      'over_email_send_rate_limit' ||
      'over_request_rate_limit' => const AppException(
        AppErrorKind.rateLimited,
        'Too many attempts. Please wait a few minutes and try again.',
      ),
      'session_not_found' ||
      'session_expired' ||
      'refresh_token_not_found' ||
      'refresh_token_already_used' => _session,
      _ when error is AuthSessionMissingException => _session,
      _ => const AppException(
        AppErrorKind.unknown,
        'Authentication failed. Please try again.',
      ),
    };
  }

  static AppException _fromPostgrest(PostgrestException error) {
    final code = error.code ?? '';
    if (code == 'PGRST301' ||
        code == 'PGRST303' ||
        error.message.contains('JWT expired')) {
      return _session;
    }
    if (code == '42501') return _permission;
    // `.single()` found no row: either it doesn't exist or RLS hides it.
    if (code == 'PGRST116') {
      return const AppException(
        AppErrorKind.notFound,
        "This report no longer exists or you don't have permission to change it.",
      );
    }
    if (error.message.startsWith('rate_limit_exceeded')) {
      return const AppException(
        AppErrorKind.rateLimited,
        "You've created a lot of reports today. Please try again tomorrow.",
      );
    }
    if (code == '23514' || code == '22P02' || code == '23502') {
      return const AppException(
        AppErrorKind.validation,
        'Some details were not accepted. Please check the form and try again.',
      );
    }
    return _unknown;
  }

  static AppException _fromStorage(StorageException error) {
    return switch (error.statusCode) {
      '401' => _session,
      '403' => _permission,
      '404' => const AppException(
        AppErrorKind.notFound,
        'The photo could not be found.',
      ),
      '413' => const AppException(
        AppErrorKind.validation,
        'That photo is too large. Choose one under 5 MB.',
      ),
      '415' => const AppException(
        AppErrorKind.validation,
        'Only JPEG, PNG or WebP photos are supported.',
      ),
      _ => _unknown,
    };
  }
}
