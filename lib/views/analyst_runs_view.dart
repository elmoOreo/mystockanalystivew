import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/analyst_run.dart';
import '../models/report_item.dart';
import '../services/api_service.dart';

class AnalystRunsView extends StatefulWidget {
  const AnalystRunsView({super.key, required this.onRunSelected});
  final void Function(String) onRunSelected;

  @override
  State<AnalystRunsView> createState() => _AnalystRunsViewState();
}

class _AnalystRunsViewState extends State<AnalystRunsView> {
  final ApiService _apiService = ApiService();
  List<AnalystRun> _allAnalystRuns = [];
  bool _isLoading = true;
  String? _error;

  List<ReportItem> _displayReportItems = [];

  DateTime? _selectedTimestamp;
  String? _selectedTicker;

  List<DateTime> _availableTimestamps = [];
  List<String> _availableTickers = [];

  @override
  void initState() {
    super.initState();
    _fetchAnalystRuns();
  }

  Future<void> _fetchAnalystRuns() async {
    try {
      final runs = await _apiService.fetchAnalystRuns();
      setState(() {
        _allAnalystRuns = runs;
        _populateFilters();
        if (runs.isNotEmpty) {
          widget.onRunSelected(runs.first.threadId);
        }
        if (_availableTimestamps.isNotEmpty) {
          _selectedTimestamp = _availableTimestamps.first;
          _filterReports();
        }
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
    final timestamps =
        _allAnalystRuns.map((run) => run.timestamp).toSet().toList();
    final tickers = _allAnalystRuns
        .expand((run) => run.finalReport.map((item) => item.ticker))
        .toSet()
        .toList();

    // The API already sorts the runs by timestamp descending, so no need to sort here.
    tickers.sort();

    setState(() {
      _availableTimestamps = timestamps;
      _availableTickers = ['All', ...tickers]; // Add 'All' option
      _selectedTicker = 'All';
    });
  }

  void _filterReports() {
    if (_selectedTimestamp == null) return;

    final run =
        _allAnalystRuns.firstWhere((r) => r.timestamp == _selectedTimestamp);
    widget.onRunSelected(run.threadId);

    List<ReportItem> items = run.finalReport;
    if (_selectedTicker != null && _selectedTicker != 'All') {
      items = items.where((item) => item.ticker == _selectedTicker).toList();
    }

    setState(() {
      _displayReportItems = items;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
          child: Text('Error: $_error',
              style: const TextStyle(color: Colors.redAccent)));
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff1f2937), Color(0xff111827)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilters(),
            const SizedBox(height: 20),
            Expanded(child: _buildReportList()),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: const Color(0xff374151), // Dropdown menu background
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 10,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[700]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DateTime>(
                value: _selectedTimestamp,
                hint: const Text('Select Run',
                    style: TextStyle(color: Colors.white70)),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                onChanged: (DateTime? newValue) {
                  setState(() {
                    _selectedTimestamp = newValue;
                    _filterReports();
                  });
                },
                items: _availableTimestamps
                    .map<DropdownMenuItem<DateTime>>((DateTime value) {
                  return DropdownMenuItem<DateTime>(
                    value: value,
                    child: Text(
                        DateFormat.yMd().add_jms().format(value.toLocal())),
                  );
                }).toList(),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[700]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTicker,
                hint: const Text('Select Ticker',
                    style: TextStyle(color: Colors.white70)),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTicker = newValue;
                    _filterReports();
                  });
                },
                items: _availableTickers
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportList() {
    if (_displayReportItems.isEmpty) {
      return const Center(
          child: Text('No data for selected filters.',
              style: TextStyle(color: Colors.white70)));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: _displayReportItems.length,
      itemBuilder: (context, index) {
        final item = _displayReportItems[index];
        return _buildReportCard(item);
      },
    );
  }

  Widget _buildReportCard(ReportItem item) {
    final Color sentimentColor;
    final IconData sentimentIcon;

    switch (item.sentiment.toLowerCase()) {
      case 'bullish':
        sentimentColor = Colors.greenAccent[400]!;
        sentimentIcon = Icons.trending_up;
        break;
      case 'bearish':
        sentimentColor = Colors.redAccent[400]!;
        sentimentIcon = Icons.trending_down;
        break;
      default:
        sentimentColor = Colors.grey[500]!;
        sentimentIcon = Icons.trending_flat;
        break;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      color: const Color(0xff374151).withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.ticker,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(sentimentIcon, color: sentimentColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            item.sentiment,
                            style: TextStyle(
                              color: sentimentColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 70,
                  height: 70,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: item.score,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey[800],
                        valueColor:
                            AlwaysStoppedAnimation<Color>(sentimentColor),
                      ),
                      Text(
                        '${(item.score * 100).toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 32),
            Text(
              item.reasoning,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
