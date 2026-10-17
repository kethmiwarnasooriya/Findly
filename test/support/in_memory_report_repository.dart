import 'package:findly/core/errors/app_exception.dart';
import 'package:findly/data/report_repository.dart';
import 'package:findly/models/item_report.dart';
import 'package:findly/models/report_draft.dart';
import 'package:findly/models/report_photo.dart';
import 'package:findly/models/report_status.dart';

/// Test double that mimics the backend's ownership rules in memory.
class InMemoryReportRepository implements ReportRepository {
  InMemoryReportRepository({
    List<ItemReport> seed = const [],
    this.currentUserId = 'me',
  }) : _reports = [...seed];

  final List<ItemReport> _reports;
  int _nextId = 1;

  @override
  String? currentUserId;

  /// When set, the next call throws this instead of succeeding.
  AppException? failNextWith;

  void _maybeFail() {
    final failure = failNextWith;
    if (failure != null) {
      failNextWith = null;
      throw failure;
    }
  }

  ItemReport _ownedOrThrow(String id) {
    final index = _reports.indexWhere((r) => r.id == id);
    if (index == -1 || _reports[index].ownerId != currentUserId) {
      throw const AppException(AppErrorKind.notFound, 'Not found');
    }
    return _reports[index];
  }

  void _put(ItemReport report) {
    final index = _reports.indexWhere((r) => r.id == report.id);
    _reports[index] = report;
  }

  @override
  Future<List<ItemReport>> fetchReports() async {
    _maybeFail();
    return [..._reports]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<ItemReport> createReport(
    ReportDraft draft, {
    PickedPhoto? photo,
  }) async {
    _maybeFail();
    final report = ItemReport(
      id: 'new-${_nextId++}',
      ownerId: currentUserId!,
      type: draft.type,
      status: ReportStatus.active,
      title: draft.title.trim(),
      description: draft.description.trim(),
      category: draft.category,
      location: draft.location.trim(),
      eventDate: draft.eventDate,
      createdAt: DateTime.now(),
    );
    _reports.add(report);
    return report;
  }

  @override
  Future<ItemReport> updateReport(
    ItemReport report,
    ReportDraft draft, {
    PhotoChange photoChange = const KeepPhoto(),
  }) async {
    _maybeFail();
    final updated = _ownedOrThrow(report.id).copyWith(
      title: draft.title.trim(),
      description: draft.description.trim(),
      category: draft.category,
      location: draft.location.trim(),
      eventDate: draft.eventDate,
    );
    _put(updated);
    return updated;
  }

  @override
  Future<ItemReport> updateStatus(
    ItemReport report,
    ReportStatus status,
  ) async {
    _maybeFail();
    final updated = _ownedOrThrow(report.id).copyWith(
      status: status,
      resolvedAt: () => status == ReportStatus.resolved ? DateTime.now() : null,
    );
    _put(updated);
    return updated;
  }

  @override
  Future<void> deleteReport(ItemReport report) async {
    _maybeFail();
    _ownedOrThrow(report.id);
    _reports.removeWhere((r) => r.id == report.id);
  }

  @override
  Future<Map<String, String>> photoUrls(Iterable<String> paths) async =>
      const {};
}
