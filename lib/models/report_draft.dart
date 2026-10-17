import '../core/utils/date_utils.dart';
import 'item_category.dart';
import 'report_type.dart';

/// Field limits shared by the form and [ReportDraft.validate].
///
/// The same limits are enforced by CHECK constraints in the database, so a
/// modified client cannot bypass them.
abstract final class ReportLimits {
  static const titleMin = 3;
  static const titleMax = 80;
  static const descriptionMin = 10;
  static const descriptionMax = 1000;
  static const locationMin = 2;
  static const locationMax = 120;
  static final earliestEventDate = DateTime(2000);
}

/// User input for creating or editing a report, before it is saved.
class ReportDraft {
  const ReportDraft({
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.eventDate,
  });

  final ReportType type;
  final String title;
  final String description;
  final ItemCategory category;
  final String location;
  final DateTime eventDate;

  /// Returns field name → error message. An empty map means the draft is valid.
  Map<String, String> validate({DateTime? now}) {
    final errors = <String, String>{};
    void check(String field, String? error) {
      if (error != null) errors[field] = error;
    }

    check('title', validateTitle(title));
    check('description', validateDescription(description));
    check('location', validateLocation(location));
    check('eventDate', validateEventDate(eventDate, now: now));
    return errors;
  }

  bool isValid({DateTime? now}) => validate(now: now).isEmpty;

  /// Columns the client is allowed to write. `owner_id`, `status`, timestamps
  /// and `is_demo` are set by the database, not the client.
  Map<String, dynamic> toJson() => {
    'type': type.dbValue,
    'title': title.trim(),
    'description': description.trim(),
    'category': category.dbValue,
    'location': location.trim(),
    'event_date': formatIsoDate(eventDate),
  };

  static String? validateTitle(String? value) => _validateLength(
    value,
    label: 'a title',
    min: ReportLimits.titleMin,
    max: ReportLimits.titleMax,
  );

  static String? validateDescription(String? value) => _validateLength(
    value,
    label: 'a description',
    min: ReportLimits.descriptionMin,
    max: ReportLimits.descriptionMax,
  );

  static String? validateLocation(String? value) => _validateLength(
    value,
    label: 'where it happened',
    min: ReportLimits.locationMin,
    max: ReportLimits.locationMax,
  );

  static String? validateEventDate(DateTime? value, {DateTime? now}) {
    if (value == null) return 'Choose a date';
    final today = dateOnly(now ?? DateTime.now());
    if (dateOnly(value).isAfter(today)) {
      return 'The date cannot be in the future';
    }
    if (value.isBefore(ReportLimits.earliestEventDate)) {
      return 'Choose a more recent date';
    }
    return null;
  }

  static String? _validateLength(
    String? value, {
    required String label,
    required int min,
    required int max,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Please enter $label';
    if (trimmed.length < min) return 'Use at least $min characters';
    if (trimmed.length > max) return 'Use at most $max characters';
    return null;
  }
}
