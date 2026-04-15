import 'package:flutter/material.dart';
import '../views/agent_logs_view.dart';
import '../views/analyst_runs_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _selectedThreadId;

  void _onAnalystRunSelected(String threadId) {
    // Use a post-frame callback to avoid calling setState during a build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _selectedThreadId != threadId) {
        setState(() {
          _selectedThreadId = threadId;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xff111827),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: const Text(
            'Stock Analyst Dashboard',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xff374151), Color(0xff111827)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter),
            ),
          ),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.cyanAccent,
            indicatorWeight: 3,
            tabs: [
              Tab(icon: Icon(Icons.analytics_outlined), text: 'Analyst Runs'),
              Tab(icon: Icon(Icons.plagiarism_outlined), text: 'Agent Logs'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AnalystRunsView(onRunSelected: _onAnalystRunSelected),
            AgentLogsView(threadId: _selectedThreadId),
          ],
        ),
      ),
    );
  }
}
