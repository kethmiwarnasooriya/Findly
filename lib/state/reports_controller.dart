import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../data/report_repository.dart';
import '../models/item_report.dart';
import '../models/match_result.dart';
import '../models/report_draft.dart';
import '../models/report_filter.dart';
import '../models/report_photo.dart';
import '../models/report_status.dart';
import '../models/report_type.dart';
import '../services/matching_service.dart';

enum LoadState { idle, loading, ready, failure }

/// App state for reports: the loaded list, current filters, photo URLs, and
/// the actions that change reports.
///
/// Mutations update the local list only after the server confirms them, so
/// the UI never shows data that was not actually saved.
class ReportsController extends ChangeNotifier {
  ReportsController({
    required this._repository,
    this._matching = const MatchingService(),
  });

  final ReportRepository _repository;
  final MatchingService _matching;

  static const _photoUrlMaxAge = Duration(minutes: 50);

  List<ItemReport> _reports = const [];
  LoadState _state = LoadState.idle;
  AppException? _loadError;
  ReportFilter _filter = ReportFilter.empty;
  Map<String, String> _photoUrls = const {};
  DateTime? _photoUrlsFetchedAt;
  bool _disposed = false;

  LoadState get state => _state;
  bool get isLoading => _state == LoadState.loading;

  /// The last load failure. When reports were already loaded they stay
  /// visible and this is shown as a non-blocking message.
  AppException? get loadError => _loadError;

  ReportFilter get filter => _filter;
  String? get currentUserId => _repository.currentUserId;

  List<ItemReport> get allReports => List.unmodifiable(_reports);
  List<ItemReport> get visibleReports => _filter.apply(_reports);

  List<ItemReport> get recentActiveReports =>
      ReportFilter(status: ReportStatus.active)
          .apply(_reports)
          .take(5)
          .toList();

  int get activeLostCount => _countActive(ReportType.lost);
  int get activeFoundCount => _countActive(ReportType.found);

  int _countActive(ReportType type) =>
      _reports.where((r) => r.isActive && r.type == type).length;

  bool isOwner(ItemReport report) => report.isOwnedBy(currentUserId);

  ItemReport? reportById(String id) {
    for (final report in _reports) {
      if (report.id == id) return report;
    }
    return null;
  }

  String? photoUrlFor(ItemReport report) {
    final path = report.photoPath;
    return path == null ? null : _photoUrls[path];
  }

  List<MatchResult> matchesFor(ItemReport report) =>
      _matching.findMatches(report, _reports);

  Future<void> load() async {
    if (_state == LoadState.loading) return;
    _state = LoadState.loading;
    _notify();
    try {
      _reports = await _repository.fetchReports();
      _loadError = null;
      _state = LoadState.ready;
      await _refreshPhotoUrls(force: true);
    } catch (error) {
      _loadError = AppException.from(error);
      _state = _reports.isEmpty ? LoadState.failure : LoadState.ready;
    }
    _notify();
  }

  void dismissLoadError() {
    _loadError = null;
    _notify();
  }

  void updateFilter(ReportFilter filter) {
    _filter = filter;
    _notify();
  }

  void resetFilters() => updateFilter(ReportFilter.empty);

  Future<ItemReport> createReport(
    ReportDraft draft, {
    PickedPhoto? photo,
  }) async {
    final created = await _repository.createReport(draft, photo: photo);
    _reports = [created, ..._reports];
    await _addPhotoUrl(created);
    _notify();
    return created;
  }

  Future<ItemReport> updateReport(
    ItemReport report,
    ReportDraft draft, {
    PhotoChange photoChange = const KeepPhoto(),
  }) async {
    final updated = await _repository.updateReport(
      report,
      draft,
      photoChange: photoChange,
    );
    _replace(updated);
    await _addPhotoUrl(updated);
    _notify();
    return updated;
  }

  Future<ItemReport> setStatus(ItemReport report, ReportStatus status) async {
    if (!report.status.canTransitionTo(status)) return report;
    final updated = await _repository.updateStatus(report, status);
    _replace(updated);
    _notify();
    return updated;
  }

  Future<void> deleteReport(ItemReport report) async {
    await _repository.deleteReport(report);
    _reports = _reports.where((r) => r.id != report.id).toList();
    _notify();
  }

  /// Re-signs photo URLs if they are close to expiring.
  Future<void> refreshPhotoUrlsIfStale() async {
    await _refreshPhotoUrls(force: false);
    _notify();
  }

  void _replace(ItemReport updated) {
    _reports = [for (final r in _reports) r.id == updated.id ? updated : r];
  }

  Future<void> _refreshPhotoUrls({required bool force}) async {
    final fetchedAt = _photoUrlsFetchedAt;
    final fresh =
        fetchedAt != null &&
        DateTime.now().difference(fetchedAt) < _photoUrlMaxAge;
    if (!force && fresh) return;
    final paths = _reports.map((r) => r.photoPath).whereType<String>();
    try {
      _photoUrls = await _repository.photoUrls(paths);
      _photoUrlsFetchedAt = DateTime.now();
    } catch (_) {
      // Photos are optional; cards fall back to a category icon.
    }
  }

  Future<void> _addPhotoUrl(ItemReport report) async {
    final path = report.photoPath;
    if (path == null || _photoUrls.containsKey(path)) return;
    try {
      final urls = await _repository.photoUrls([path]);
      _photoUrls = {..._photoUrls, ...urls};
    } catch (_) {}
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
