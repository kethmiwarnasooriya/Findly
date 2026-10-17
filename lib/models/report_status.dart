/// Lifecycle of a report.
///
/// The workflow is intentionally small: a report is [active] while it needs
/// attention and takes part in matching, and [resolved] once the item is back
/// with its owner or the report is no longer needed. Owners may reopen a
/// resolved report if it was closed by mistake.
enum ReportStatus {
  active('active', 'Active'),
  resolved('resolved', 'Resolved');

  const ReportStatus(this.dbValue, this.label);

  /// Value stored in the `report_status` Postgres enum.
  final String dbValue;
  final String label;

  bool canTransitionTo(ReportStatus next) => next != this;

  static ReportStatus fromDb(String value) => ReportStatus.values.firstWhere(
    (status) => status.dbValue == value,
    orElse: () => throw FormatException('Unknown report status: $value'),
  );
}
