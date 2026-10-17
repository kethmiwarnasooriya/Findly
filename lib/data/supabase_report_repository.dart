import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';
import '../core/errors/app_exception.dart';
import '../models/item_report.dart';
import '../models/report_draft.dart';
import '../models/report_photo.dart';
import '../models/report_status.dart';
import 'report_repository.dart';

/// [ReportRepository] backed by the `reports` table and the `report-photos`
/// storage bucket. Row level security decides what each call may touch; this
/// class never sends `owner_id`, which the database fills in from the JWT.
class SupabaseReportRepository implements ReportRepository {
  SupabaseReportRepository(this._client);

  final SupabaseClient _client;
  final Random _random = Random.secure();

  static const _table = 'reports';
  static const _columns =
      'id, owner_id, type, status, title, description, category, location, '
      'event_date, photo_path, is_demo, resolved_at, created_at';
  static const _signedUrlLifetimeSeconds = 60 * 60;
  static const _uploadTimeout = Duration(seconds: 90);

  StorageFileApi get _photos => _client.storage.from(AppConfig.photoBucket);

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<List<ItemReport>> fetchReports() => _run(() async {
    final rows = await _client
        .from(_table)
        .select(_columns)
        .order('created_at', ascending: false)
        .limit(AppConfig.reportFetchLimit);
    return rows.map(ItemReport.fromJson).toList();
  });

  @override
  Future<ItemReport> createReport(ReportDraft draft, {PickedPhoto? photo}) =>
      _run(timeout: photo == null ? null : _uploadTimeout, () async {
        final userId = _requireUserId();
        final photoPath = photo == null ? null : await _upload(userId, photo);
        try {
          final row = await _client
              .from(_table)
              .insert({...draft.toJson(), 'photo_path': photoPath})
              .select(_columns)
              .single();
          return ItemReport.fromJson(row);
        } catch (_) {
          if (photoPath != null) await _removeQuietly(photoPath);
          rethrow;
        }
      });

  @override
  Future<ItemReport> updateReport(
    ItemReport report,
    ReportDraft draft, {
    PhotoChange photoChange = const KeepPhoto(),
  }) => _run(
    timeout: photoChange is ReplacePhoto ? _uploadTimeout : null,
    () async {
      final userId = _requireUserId();
      final (String? newPath, String? uploadedPath) = switch (photoChange) {
        KeepPhoto() => (report.photoPath, null),
        RemovePhoto() => (null, null),
        ReplacePhoto(:final photo) => await _upload(
          userId,
          photo,
        ).then((path) => (path, path)),
      };

      // The report type is fixed at creation; the column is not updatable.
      final values = draft.toJson()
        ..remove('type')
        ..['photo_path'] = newPath;

      final ItemReport updated;
      try {
        final row = await _client
            .from(_table)
            .update(values)
            .eq('id', report.id)
            .select(_columns)
            .single();
        updated = ItemReport.fromJson(row);
      } catch (_) {
        if (uploadedPath != null) await _removeQuietly(uploadedPath);
        rethrow;
      }

      final oldPath = report.photoPath;
      if (oldPath != null && oldPath != newPath) await _removeQuietly(oldPath);
      return updated;
    },
  );

  @override
  Future<ItemReport> updateStatus(ItemReport report, ReportStatus status) =>
      _run(() async {
        final row = await _client
            .from(_table)
            .update({'status': status.dbValue})
            .eq('id', report.id)
            .select(_columns)
            .single();
        return ItemReport.fromJson(row);
      });

  @override
  Future<void> deleteReport(ItemReport report) => _run(() async {
    // RLS turns an unauthorized delete into "0 rows", not an error, so check.
    final deleted = await _client
        .from(_table)
        .delete()
        .eq('id', report.id)
        .select('id');
    if (deleted.isEmpty) {
      throw const AppException(
        AppErrorKind.notFound,
        "This report no longer exists or you don't have permission to delete it.",
      );
    }
    final photoPath = report.photoPath;
    if (photoPath != null) await _removeQuietly(photoPath);
  });

  @override
  Future<Map<String, String>> photoUrls(Iterable<String> paths) =>
      _run(() async {
        final unique = paths.toSet().toList();
        if (unique.isEmpty) return const {};
        final results = await _photos.createSignedUrlsResult(
          unique,
          _signedUrlLifetimeSeconds,
        );
        return {
          for (final result in results.whereType<SignedUrlSuccess>())
            result.path: result.signedUrl,
        };
      });

  String _requireUserId() {
    final id = currentUserId;
    if (id == null) {
      throw const AppException(
        AppErrorKind.sessionExpired,
        'Your session has expired. Please sign in again.',
      );
    }
    return id;
  }

  /// Uploads into `<userId>/<millis>-<random>.<ext>`. Storage policies only
  /// allow writes inside the caller's own folder, and never overwrite.
  Future<String> _upload(String userId, PickedPhoto photo) async {
    final suffix = List.generate(
      4,
      (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final path =
        '$userId/${DateTime.now().millisecondsSinceEpoch}-$suffix.${photo.format.extension}';
    await _photos.uploadBinary(
      path,
      photo.bytes,
      fileOptions: FileOptions(
        contentType: photo.format.contentType,
        upsert: false,
      ),
    );
    return path;
  }

  /// Best-effort cleanup. A failure leaves an orphaned object that is only
  /// visible to its owner; it never affects the report itself.
  Future<void> _removeQuietly(String path) async {
    try {
      await _photos.remove([path]);
    } catch (_) {}
  }

  Future<T> _run<T>(Future<T> Function() action, {Duration? timeout}) async {
    try {
      return await action().timeout(timeout ?? AppConfig.requestTimeout);
    } catch (error) {
      throw AppException.from(error);
    }
  }
}
