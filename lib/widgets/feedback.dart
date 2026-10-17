import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/errors/app_exception.dart';
import '../state/auth_controller.dart';

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Shows [error] with the most useful follow-up action: sign in again for an
/// expired session, or retry for transient failures.
void showError(BuildContext context, Object error, {VoidCallback? onRetry}) {
  final appError = AppException.from(error);
  SnackBarAction? action;
  if (appError.kind == AppErrorKind.sessionExpired) {
    final auth = context.read<AuthController?>();
    if (auth != null) {
      action = SnackBarAction(label: 'Sign in', onPressed: auth.signOut);
    }
  } else if (onRetry != null && appError.isRetryable) {
    action = SnackBarAction(label: 'Retry', onPressed: onRetry);
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(appError.message), action: action));
}

/// Asks the user to confirm an action. Returns `true` only on confirmation.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final colors = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: colors.error,
                  foregroundColor: colors.onError,
                )
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
