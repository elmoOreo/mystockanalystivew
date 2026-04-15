class ReportItem {
  final String ticker;
  final String sentiment;
  final double score;
  final String reasoning;

  ReportItem(
      {required this.ticker,
      required this.sentiment,
      required this.score,
      required this.reasoning});

  factory ReportItem.fromJson(Map<String, dynamic> json) {
    return ReportItem(
      ticker: json['ticker'],
      sentiment: json['sentiment'],
      score: (json['score'] as num).toDouble(),
      reasoning: json['reasoning'],
    );
  }
}
