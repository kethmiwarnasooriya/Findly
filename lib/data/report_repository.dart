import '../models/item_report.dart';
import '../models/report_draft.dart';
import '../models/report_photo.dart';
import '../models/report_status.dart';

/// Persistence boundary for reports. The UI and controllers depend on this
/// interface so tests can substitute an in-memory implementation.
///
/// Implementations throw [AppException] for every failure.
abstract interface class ReportRepository {
  /// The signed-in user's id, used to decide which actions to offer. The
  /// backend enforces ownership independently.
  String? get currentUserId;

  /// Newest reports first, up to an implementation-defined limit.
  Future<List<ItemReport>> fetchReports();

  Future<ItemReport> createReport(ReportDraft draft, {PickedPhoto? photo});

  Future<ItemReport> updateReport(
    ItemReport report,
    ReportDraft draft, {
    PhotoChange photoChange = const KeepPhoto(),
  });

  Future<ItemReport> updateStatus(ItemReport report, ReportStatus status);

  Future<void> deleteReport(ItemReport report);

  /// Short-lived URLs for displaying photos, keyed by photo path. Paths the
  /// user may not view are omitted.
  Future<Map<String, String>> photoUrls(Iterable<String> paths);
}
