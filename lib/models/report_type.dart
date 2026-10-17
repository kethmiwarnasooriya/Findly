/// Whether a report describes something the reporter lost or found.
enum ReportType {
  lost('lost', 'Lost'),
  found('found', 'Found');

  const ReportType(this.dbValue, this.label);

  /// Value stored in the `report_type` Postgres enum.
  final String dbValue;
  final String label;

  /// The type a report must have to be a matching candidate for this one.
  ReportType get opposite =>
      this == ReportType.lost ? ReportType.found : ReportType.lost;

  static ReportType fromDb(String value) => ReportType.values.firstWhere(
    (type) => type.dbValue == value,
    orElse: () => throw FormatException('Unknown report type: $value'),
  );
}
