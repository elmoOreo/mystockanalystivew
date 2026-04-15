import 'report_item.dart';

class AnalystRun {
  final String id;
  final String threadId;
  final DateTime timestamp;
  final List<ReportItem> finalReport;

  AnalystRun(
      {required this.id,
      required this.threadId,
      required this.timestamp,
      required this.finalReport});

  factory AnalystRun.fromJson(Map<String, dynamic> json) {
    return AnalystRun(
      id: json['_id'],
      threadId: json['threadId'],
      timestamp: DateTime.parse(json['timestamp']),
      finalReport: (json['finalReport'] as List)
          .map((item) => ReportItem.fromJson(item))
          .toList(),
    );
  }
}
