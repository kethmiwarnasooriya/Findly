import 'item_category.dart';
import 'report_status.dart';
import 'report_type.dart';

/// A lost or found report as stored in the `reports` table.
class ItemReport {
  const ItemReport({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.status,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.eventDate,
    required this.createdAt,
    this.photoPath,
    this.resolvedAt,
    this.isDemo = false,
  });

  factory ItemReport.fromJson(Map<String, dynamic> json) {
    return ItemReport(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      type: ReportType.fromDb(json['type'] as String),
      status: ReportStatus.fromDb(json['status'] as String),
      title: json['title'] as String,
      description: json['description'] as String,
      category: ItemCategory.fromDb(json['category'] as String),
      location: json['location'] as String,
      eventDate: DateTime.parse(json['event_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      photoPath: json['photo_path'] as String?,
      resolvedAt: switch (json['resolved_at']) {
        final String value => DateTime.parse(value).toLocal(),
        _ => null,
      },
      isDemo: json['is_demo'] as bool? ?? false,
    );
  }

  final String id;
  final String ownerId;
  final ReportType type;
  final ReportStatus status;
  final String title;
  final String description;
  final ItemCategory category;
  final String location;

  /// The calendar date the item was lost or found (no time component).
  final DateTime eventDate;
  final DateTime createdAt;

  /// Object path inside the `report-photos` storage bucket, never a URL.
  final String? photoPath;
  final DateTime? resolvedAt;
  final bool isDemo;

  bool get isActive => status == ReportStatus.active;
  bool get hasPhoto => photoPath != null && photoPath!.isNotEmpty;

  bool isOwnedBy(String? userId) => userId != null && userId == ownerId;

  ItemReport copyWith({
    ReportStatus? status,
    String? title,
    String? description,
    ItemCategory? category,
    String? location,
    DateTime? eventDate,
    String? Function()? photoPath,
    DateTime? Function()? resolvedAt,
  }) {
    return ItemReport(
      id: id,
      ownerId: ownerId,
      type: type,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      eventDate: eventDate ?? this.eventDate,
      createdAt: createdAt,
      photoPath: photoPath != null ? photoPath() : this.photoPath,
      resolvedAt: resolvedAt != null ? resolvedAt() : this.resolvedAt,
      isDemo: isDemo,
    );
  }
}
