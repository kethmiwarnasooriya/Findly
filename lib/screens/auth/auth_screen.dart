import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../state/auth_controller.dart';
import '../../widgets/feedback.dart';
import '../../widgets/app_card.dart';
import 'auth_hero.dart';
import 'auth_validators.dart';

enum _Mode { signIn, signUp }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  _Mode _mode = _Mode.signIn;
  bool _busy = false;
  bool _obscure = true;
  String? _awaitingConfirmationFor;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final service = context.read<AuthController>().service;
    await _guard(() async {
      if (_mode == _Mode.signIn) {
        await service.signIn(email: _email.text, password: _password.text);
      } else {
        final needsConfirmation = await service.signUp(
          email: _email.text,
          password: _password.text,
        );
        if (needsConfirmation && mounted) {
          setState(() => _awaitingConfirmationFor = _email.text.trim());
        }
      }
    });
  }

  Future<void> _forgotPassword() async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) => _ResetPasswordDialog(initialEmail: _email.text),
    );
    if (email == null || !mounted) return;
    final service = context.read<AuthController>().service;
    await _guard(() async {
      await service.sendPasswordReset(email);
      if (mounted) {
        showMessage(
          context,
          'If an account exists for $email, a reset link is on its way. '
          'Open it on this phone.',
        );
      }
    });
  }

  Future<void> _resendConfirmation() async {
    final email = _awaitingConfirmationFor;
    if (email == null) return;
    final service = context.read<AuthController>().service;
    await _guard(() async {
      await service.resendConfirmation(email);
      if (mounted) showMessage(context, 'Confirmation email sent again.');
    });
  }

  Future<void> _guard(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on AppException catch (error) {
      if (!mounted) return;
      if (error.kind == AppErrorKind.emailNotConfirmed) {
        setState(() => _awaitingConfirmationFor = _email.text.trim());
      }
      showError(context, error);
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSignUp = _mode == _Mode.signUp;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHero(),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (context.watch<AuthController>().linkError
                          case final linkError?) ...[
                        _LinkErrorBanner(
                          message: linkError,
                          onDismiss: context
                              .read<AuthController>()
                              .clearLinkError,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_awaitingConfirmationFor case final email?)
                        _ConfirmEmailPanel(
                          email: email,
                          busy: _busy,
                          onResend: _resendConfirmation,
                          onBack: () => setState(() {
                            _awaitingConfirmationFor = null;
                            _mode = _Mode.signIn;
                          }),
                        )
                      else
                        Form(
                          key: _formKey,
                          child: AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SegmentedButton<_Mode>(
                                  segments: const [
                                    ButtonSegment(
                                      value: _Mode.signIn,
                                      label: Text('Sign in'),
                                    ),
                                    ButtonSegment(
                                      value: _Mode.signUp,
                                      label: Text('Create account'),
                                    ),
                                  ],
                                  selected: {_mode},
                                  onSelectionChanged: _busy
                                      ? null
                                      : (s) => setState(() => _mode = s.first),
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _email,
                                  enabled: !_busy,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.email],
                                  textInputAction: TextInputAction.next,
                                  autocorrect: false,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(
                                      Icons.alternate_email_rounded,
                                    ),
                                  ),
                                  validator: validateEmail,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _password,
                                  enabled: !_busy,
                                  obscureText: _obscure,
                                  autofillHints: [
                                    isSignUp
                                        ? AutofillHints.newPassword
                                        : AutofillHints.password,
                                  ],
                                  textInputAction: isSignUp
                                      ? TextInputAction.next
                                      : TextInputAction.done,
                                  onFieldSubmitted: isSignUp
                                      ? null
                                      : (_) => _submit(),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                    ),
                                    suffixIcon: IconButton(
                                      tooltip: _obscure
                                          ? 'Show password'
                                          : 'Hide password',
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                  ),
                                  validator: isSignUp
                                      ? validateNewPassword
                                      : (v) => (v ?? '').isEmpty
                                            ? 'Enter your password'
                                            : null,
                                ),
                                if (isSignUp) ...[
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _confirm,
                                    enabled: !_busy,
                                    obscureText: _obscure,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _submit(),
                                    decoration: const InputDecoration(
                                      labelText: 'Confirm password',
                                      prefixIcon: Icon(
                                        Icons.lock_outline_rounded,
                                      ),
                                    ),
                                    validator: (v) => v == _password.text
                                        ? null
                                        : 'Passwords do not match',
                                  ),
                                ],
                                const SizedBox(height: 20),
                                FilledButton(
                                  onPressed: _busy ? null : _submit,
                                  child: _busy
                                      ? const SizedBox.square(
                                          dimension: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          isSignUp
                                              ? 'Create account'
                                              : 'Sign in',
                                        ),
                                ),
                                if (!isSignUp)
                                  TextButton(
                                    onPressed: _busy ? null : _forgotPassword,
                                    child: const Text('Forgot password?'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        'Reports you post are visible to other signed-in Findly '
                        'users. Your email address is never shown to them.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkErrorBanner extends StatelessWidget {
  const _LinkErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Material(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.link_off_rounded, color: colors.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: colors.onErrorContainer),
                ),
              ),
              IconButton(
                tooltip: 'Dismiss',
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmEmailPanel extends StatelessWidget {
  const _ConfirmEmailPanel({
    required this.email,
    required this.busy,
    required this.onResend,
    required this.onBack,
  });

  final String email;
  final bool busy;
  final VoidCallback onResend;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.mark_email_unread_outlined,
            size: 40,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Check your inbox',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'We sent a confirmation link to $email. Open it on this phone '
            'to finish creating your account, then sign in.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: busy ? null : onResend,
            child: const Text('Resend email'),
          ),
          TextButton(
            onPressed: busy ? null : onBack,
            child: const Text('Back to sign in'),
          ),
        ],
      ),
    );
  }
}

class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_email.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset password'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _email,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
          validator: validateEmail,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Send link')),
      ],
    );
  }
}
