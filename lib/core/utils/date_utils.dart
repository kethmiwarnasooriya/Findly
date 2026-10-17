const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Whole calendar days from [from] to [to] (negative if [to] is earlier).
///
/// Uses UTC dates so daylight-saving changes cannot produce off-by-one results.
int daysBetween(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}

/// `2026-10-16`, the format Postgres expects for `date` columns.
String formatIsoDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

/// `16 Oct 2026`.
String formatDisplayDate(DateTime value) =>
    '${value.day} ${_monthNames[value.month - 1]} ${value.year}';

/// `Today`, `Yesterday`, `3 days ago`, or a full date for older values.
String formatRelativeDate(DateTime value, {DateTime? now}) {
  final days = daysBetween(value, now ?? DateTime.now());
  if (days <= 0) return 'Today';
  if (days == 1) return 'Yesterday';
  if (days < 7) return '$days days ago';
  return formatDisplayDate(value);
}
