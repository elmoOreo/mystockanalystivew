import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/agent_log.dart';
import '../models/analyst_run.dart';

class ApiService {
  Future<List<AnalystRun>> fetchAnalystRuns() async {
    final response =
        await http.get(Uri.parse('${AppConfig.apiBaseUrl}/analystruns'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => AnalystRun.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load analyst runs: ${response.statusCode}');
    }
  }

  Future<List<AgentLog>> fetchAgentLogs(String threadId) async {
    final response = await http
        .get(Uri.parse('${AppConfig.apiBaseUrl}/checkpoints/$threadId'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => AgentLog.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load agent logs: ${response.statusCode}');
    }
  }
}
