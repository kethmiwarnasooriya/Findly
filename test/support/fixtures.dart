import 'package:findly/models/item_category.dart';
import 'package:findly/models/item_report.dart';
import 'package:findly/models/report_status.dart';
import 'package:findly/models/report_type.dart';

const ownerA = '00000000-0000-4000-8000-00000000000a';
const ownerB = '00000000-0000-4000-8000-00000000000b';

int _counter = 0;

/// Builds a report with sensible defaults; override only what a test cares
/// about.
ItemReport makeReport({
  String? id,
  String ownerId = ownerA,
  ReportType type = ReportType.lost,
  ReportStatus status = ReportStatus.active,
  String title = 'Black backpack',
  String description = 'Black backpack with a laptop inside',
  ItemCategory category = ItemCategory.bags,
  String location = 'Main library',
  DateTime? eventDate,
  DateTime? createdAt,
  String? photoPath,
}) {
  _counter++;
  return ItemReport(
    id: id ?? 'report-$_counter',
    ownerId: ownerId,
    type: type,
    status: status,
    title: title,
    description: description,
    category: category,
    location: location,
    eventDate: eventDate ?? DateTime(2026, 10, 10),
    createdAt:
        createdAt ??
        DateTime(2026, 10, 10, 12).add(Duration(minutes: _counter)),
    photoPath: photoPath,
  );
}
