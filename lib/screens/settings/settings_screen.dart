import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/findly_colors.dart';
import '../../state/auth_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/app_card.dart';
import '../../widgets/feedback.dart';
import '../../widgets/findly_logo.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController?>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const _SectionTitle('Appearance'),
            const _ThemePicker(),
            const SizedBox(height: 28),
            if (auth != null) ...[
              const _SectionTitle('Account'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.alternate_email_rounded,
                      title: 'Signed in as',
                      subtitle: auth.email ?? 'Unknown',
                    ),
                    const Divider(indent: 68),
                    _SettingsTile(
                      icon: Icons.password_rounded,
                      title: 'Change password',
                      subtitle: "We'll email you a secure reset link",
                      onTap: () => _changePassword(context, auth),
                    ),
                    const Divider(indent: 68),
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      title: 'Sign out',
                      iconColor: scheme.error,
                      onTap: () => _signOut(context, auth),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],
            const _SectionTitle('Privacy & safety'),
            const AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.visibility_outlined,
                    title: 'Who can see my reports?',
                    subtitle:
                        'Everyone signed in to Findly. Your email address is '
                        'never shown to other users.',
                  ),
                  Divider(indent: 68),
                  _SettingsTile(
                    icon: Icons.join_inner_rounded,
                    title: 'About match suggestions',
                    subtitle:
                        'Scores compare categories, words, places and dates. '
                        'They are hints, not proof. Always check details '
                        'before handing anything over.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const _SectionTitle('About'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  const _SettingsTile(
                    leading: FindlyLogo(size: 40),
                    title: 'Findly',
                    subtitle:
                        'Version 1.0.0 · Lost something? Find your way back.',
                  ),
                  const Divider(indent: 68),
                  _SettingsTile(
                    icon: Icons.description_outlined,
                    title: 'Open-source licenses',
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: 'Findly',
                      applicationVersion: '1.0.0',
                      applicationIcon: const Padding(
                        padding: EdgeInsets.all(12),
                        child: FindlyLogo(size: 56),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePassword(
    BuildContext context,
    AuthController auth,
  ) async {
    final email = auth.email;
    if (email == null) return;
    final confirmed = await confirmAction(
      context,
      title: 'Change password?',
      message:
          "We'll send a reset link to $email. Open it on this phone to choose "
          'a new password.',
      confirmLabel: 'Send link',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await auth.service.sendPasswordReset(email);
      if (context.mounted) showMessage(context, 'Reset link sent to $email');
    } catch (error) {
      if (context.mounted) showError(context, error);
    }
  }

  Future<void> _signOut(BuildContext context, AuthController auth) async {
    final confirmed = await confirmAction(
      context,
      title: 'Sign out?',
      message: 'You can sign back in at any time.',
      confirmLabel: 'Sign out',
    );
    if (!confirmed || !context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    await auth.signOut();
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Semantics(
        header: true,
        child: Text(
          text.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    this.icon,
    this.leading,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor,
  });

  final IconData? icon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading:
          leading ??
          IconTile(
            icon: icon!,
            background: (iconColor ?? scheme.primary).withValues(alpha: 0.12),
            foreground: iconColor ?? scheme.primary,
          ),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
    );
  }
}

/// Three preview cards for System / Light / Dark.
class _ThemePicker extends StatelessWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    return Row(
      children: [
        for (final (mode, label, icon) in const [
          (ThemeMode.system, 'System', Icons.brightness_auto_rounded),
          (ThemeMode.light, 'Light', Icons.light_mode_rounded),
          (ThemeMode.dark, 'Dark', Icons.dark_mode_rounded),
        ]) ...[
          if (mode != ThemeMode.system) const SizedBox(width: 10),
          Expanded(
            child: _ThemeOption(
              mode: mode,
              label: label,
              icon: icon,
              selected: settings.themeMode == mode,
              onTap: () => settings.setThemeMode(mode),
            ),
          ),
        ],
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label theme',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radius + 2),
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: AppCard(
          onTap: onTap,
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              _ThemePreview(mode: mode),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: selected ? scheme.primary : null),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: selected ? scheme.primary : null,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tiny mock of the home screen in the given theme.
class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.mode});

  final ThemeMode mode;

  @override
  Widget build(BuildContext context) {
    Widget mock(FindlyColors brand, Color background) => Container(
      color: background,
      child: Column(
        children: [
          Container(
            height: 22,
            decoration: BoxDecoration(
              color: brand.header,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < 2; i++)
            Container(
              height: 10,
              margin: const EdgeInsets.fromLTRB(6, 0, 6, 5),
              decoration: BoxDecoration(
                color: brand.card,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );

    const light = Color(0xFFF6F4EF);
    const dark = Color(0xFF0E1512);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 64,
        child: switch (mode) {
          ThemeMode.light => mock(FindlyColors.light, light),
          ThemeMode.dark => mock(FindlyColors.dark, dark),
          ThemeMode.system => Row(
            children: [
              Expanded(child: mock(FindlyColors.light, light)),
              Expanded(child: mock(FindlyColors.dark, dark)),
            ],
          ),
        },
      ),
    );
  }
}
