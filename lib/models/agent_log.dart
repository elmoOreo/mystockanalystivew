class AgentLog {
  final String id;
  final DateTime timestamp;
  final String agent;
  final String message;
  final Map<String, dynamic>? prompt;
  final Map<String, dynamic>? output;

  AgentLog(
      {required this.id,
      required this.timestamp,
      required this.agent,
      required this.message,
      this.prompt,
      this.output});

  factory AgentLog.fromJson(Map<String, dynamic> json) {
    String agentName = json['agentName'] ?? 'Unknown Agent';
    String ticker = json['prompt']?['ticker'] ?? 'N/A';
    String message;

    if (json['output'] != null) {
      final output = json['output'];
      if (output['news'] != null) {
        String summary = (output['news'] as String).split('\n').first;
        message = 'Fetched news for $ticker: $summary';
      } else if (output['sector'] != null) {
        message = 'Identified sector for $ticker: ${output['sector']}';
      } else if (output['regulatory_bodies'] != null) {
        message =
            'Identified bodies for $ticker: ${(output['regulatory_bodies'] as List).join(', ')}';
      } else if (output['sentiment'] != null) {
        message = 'Generated sentiment for $ticker: ${output['sentiment']}';
      } else {
        message = 'Completed step for $ticker.';
      }
    } else if (json['prompt'] != null) {
      message = 'Starting step for $ticker.';
    } else {
      message = 'Log entry with no prompt or output.';
    }

    return AgentLog(
      id: json['_id'],
      timestamp: DateTime.parse(json['timestamp']),
      agent: agentName.replaceAll('Agent', ''),
      message: message,
      prompt: json['prompt'],
      output: json['output'],
    );
  }
}
