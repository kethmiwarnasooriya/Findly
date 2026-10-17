final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Enter your email';
  if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address';
  return null;
}

/// Client-side guidance only; the Supabase password policy is the authority.
String? validateNewPassword(String? value) {
  final password = value ?? '';
  if (password.length < 8) return 'Use at least 8 characters';
  final hasLetter = password.contains(RegExp(r'[A-Za-z]'));
  final hasDigit = password.contains(RegExp(r'[0-9]'));
  if (!hasLetter || !hasDigit) return 'Use both letters and numbers';
  return null;
}
