import '../core/utils/text_normalizer.dart';
import 'item_category.dart';
import 'item_report.dart';
import 'report_status.dart';
import 'report_type.dart';

/// Search text plus optional filters. A `null` filter means "any".
///
/// All criteria are combined with AND, so the search query and the selected
/// filters always narrow the same list together.
class ReportFilter {
  const ReportFilter({this.query = '', this.type, this.status, this.category});

  static const empty = ReportFilter();

  final String query;
  final ReportType? type;
  final ReportStatus? status;
  final ItemCategory? category;

  bool get isEmpty =>
      query.trim().isEmpty &&
      type == null &&
      status == null &&
      category == null;

  /// Returns matching reports, newest first. Does not modify [reports].
  List<ItemReport> apply(Iterable<ItemReport> reports) {
    final terms = normalizeText(query).split(' ').where((t) => t.isNotEmpty);
    final result = reports.where((report) {
      if (type != null && report.type != type) return false;
      if (status != null && report.status != status) return false;
      if (category != null && report.category != category) return false;
      if (terms.isEmpty) return true;
      final haystack = _searchableText(report);
      return terms.every(haystack.contains);
    }).toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  static String _searchableText(ItemReport report) => normalizeText(
    '${report.title} ${report.description} ${report.category.label} '
    '${report.location}',
  );

  ReportFilter copyWith({
    String? query,
    ReportType? Function()? type,
    ReportStatus? Function()? status,
    ItemCategory? Function()? category,
  }) {
    return ReportFilter(
      query: query ?? this.query,
      type: type != null ? type() : this.type,
      status: status != null ? status() : this.status,
      category: category != null ? category() : this.category,
    );
  }
}
