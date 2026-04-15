import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/agent_log.dart';
import '../../services/api_service.dart';

class AgentLogsView extends StatefulWidget {
  const AgentLogsView({super.key, this.threadId});
  final String? threadId;

  @override
  State<AgentLogsView> createState() => _AgentLogsViewState();
}

class _AgentLogsViewState extends State<AgentLogsView> {
  final ApiService _apiService = ApiService();
  List<AgentLog> _allAgentLogs = [];
  List<AgentLog> _filteredAgentLogs = [];
  bool _isLoading = false;
  String? _error;

  DateTime? _selectedDate;
  String? _selectedAgent;

  List<DateTime> _availableDates = [];
  List<String> _availableAgents = [];

  @override
  void initState() {
    super.initState();
    if (widget.threadId != null) {
      _fetchAgentLogs();
    }
  }

  @override
  void didUpdateWidget(covariant AgentLogsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.threadId != null && widget.threadId != oldWidget.threadId) {
      _fetchAgentLogs();
    }
  }

  Future<void> _fetchAgentLogs() async {
    if (widget.threadId == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _allAgentLogs = [];
      _filteredAgentLogs = [];
    });

    try {
      final logs = await _apiService.fetchAgentLogs(widget.threadId!);
      setState(() {
        _allAgentLogs = logs;
        _populateFilters();
        _filterLogs();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _populateFilters() {
    final dates = _allAgentLogs
        .map((log) => DateTime(
            log.timestamp.year, log.timestamp.month, log.timestamp.day))
        .toSet()
        .toList();
    final agents = _allAgentLogs.map((log) => log.agent).toSet().toList();

    dates.sort((a, b) => b.compareTo(a));
    agents.sort();

    setState(() {
      _availableDates = dates;
      _availableAgents = ['All', ...agents];
      _selectedAgent = 'All';
      if (_availableDates.isNotEmpty) {
        _selectedDate = _availableDates.first;
      }
    });
  }

  void _filterLogs() {
    List<AgentLog> logs = _allAgentLogs;

    if (_selectedDate != null) {
      logs = logs.where((log) {
        return log.timestamp.year == _selectedDate!.year &&
            log.timestamp.month == _selectedDate!.month &&
            log.timestamp.day == _selectedDate!.day;
      }).toList();
    }

    if (_selectedAgent != null && _selectedAgent != 'All') {
      logs = logs.where((log) => log.agent == _selectedAgent).toList();
    }

    logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    setState(() {
      _filteredAgentLogs = logs;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.threadId == null) {
      return const Center(
        child: Text('Select an analyst run to see its logs.'),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilters(),
          const SizedBox(height: 20),
          Expanded(child: _buildLogsList()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 20,
      runSpacing: 10,
      children: [
        DropdownButton<DateTime>(
          value: _selectedDate,
          hint: const Text('Select Date'),
          onChanged: (DateTime? newValue) {
            setState(() {
              _selectedDate = newValue;
              _filterLogs();
            });
          },
          items:
              _availableDates.map<DropdownMenuItem<DateTime>>((DateTime value) {
            return DropdownMenuItem<DateTime>(
              value: value,
              child: Text(DateFormat.yMd().format(value)),
            );
          }).toList(),
        ),
        DropdownButton<String>(
          value: _selectedAgent,
          hint: const Text('Select Agent'),
          onChanged: (String? newValue) {
            setState(() {
              _selectedAgent = newValue;
              _filterLogs();
            });
          },
          items: _availableAgents.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLogsList() {
    if (_filteredAgentLogs.isEmpty) {
      return const Center(child: Text('No logs for selected filters.'));
    }
    const jsonEncoder = JsonEncoder.withIndent('  ');

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xff1f2937), Color(0xff111827)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          itemCount: _filteredAgentLogs.length,
          itemBuilder: (context, index) {
            final log = _filteredAgentLogs[index];
            final title =
                '[${DateFormat('HH:mm:ss.SSS').format(log.timestamp.toLocal())}] [${log.agent}] ${log.message}';

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  iconColor: Colors.white70,
                  collapsedIconColor: Colors.white70,
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                  title: Text(
                    title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 13),
                  ),
                  children: [
                    if (log.prompt != null)
                      _buildJsonDetail(
                          'Prompt', jsonEncoder.convert(log.prompt)),
                    if (log.output != null)
                      _buildJsonDetail(
                          'Output', jsonEncoder.convert(log.output)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildJsonDetail(String title, String jsonString) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(6),
            ),
            child: SelectableText(
              jsonString,
              style: const TextStyle(
                color: Colors.lightGreenAccent,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
