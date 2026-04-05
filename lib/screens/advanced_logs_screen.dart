import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/deployment.dart';
import '../providers/app_state.dart';

class AdvancedLogsScreen extends StatefulWidget {
  final Deployment deployment;
  final String projectId;

  const AdvancedLogsScreen({
    super.key,
    required this.deployment,
    required this.projectId,
  });

  @override
  State<AdvancedLogsScreen> createState() => _AdvancedLogsScreenState();
}

class _AdvancedLogsScreenState extends State<AdvancedLogsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>>? _runtimeLogs;
  List<Map<String, dynamic>>? _functionLogs;
  List<Map<String, dynamic>>? _requestLogs;
  List<Map<String, dynamic>>? _buildLogs;
  bool _isLoading = false;
  String? _errorMessage;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _fetchLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _fetchLogs();
    }
  }

  Future<void> _fetchLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = context.read<AppState>();
      final currentIndex = _tabController.index;

      if (currentIndex == 0) {
        _runtimeLogs = await appState.apiService.getDeploymentRuntimeLogs(
          projectId: widget.projectId,
          deploymentId: widget.deployment.uid,
          limit: 100,
        );
      } else if (currentIndex == 1) {
        _functionLogs = await appState.apiService.getDeploymentFunctionLogs(
          projectId: widget.projectId,
          deploymentId: widget.deployment.uid,
          limit: 100,
        );
      } else if (currentIndex == 2) {
        _requestLogs = await appState.apiService.getDeploymentRequestLogs(
          projectId: widget.projectId,
          deploymentId: widget.deployment.uid,
          limit: 100,
        );
      } else if (currentIndex == 3) {
        _buildLogs = await appState.apiService.getDeploymentBuildLogs(
          projectId: widget.projectId,
          deploymentId: widget.deployment.uid,
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Advanced Logs', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.onSurfaceVariant,
          tabs: const [
            Tab(icon: Icon(Icons.terminal), text: 'Runtime'),
            Tab(icon: Icon(Icons.functions), text: 'Functions'),
            Tab(icon: Icon(Icons.api), text: 'Requests'),
            Tab(icon: Icon(Icons.build), text: 'Build'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: AppTheme.surfaceContainerLow,
            child: Row(
              children: [
                _buildFilterChip('All', _filter == 'all', () => setState(() => _filter = 'all')),
                const SizedBox(width: 8),
                _buildFilterChip('Info', _filter == 'info', () => setState(() => _filter = 'info')),
                const SizedBox(width: 8),
                _buildFilterChip('Errors', _filter == 'errors', () => setState(() => _filter = 'errors')),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.download, size: 16, color: AppTheme.onSurfaceVariant),
                  onPressed: _downloadLogs,
                  tooltip: 'Copy logs to clipboard',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLogView(_runtimeLogs),
                _buildLogView(_functionLogs),
                _buildLogView(_requestLogs),
                _buildLogView(_buildLogs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogView(List<Map<String, dynamic>>? logs) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_errorMessage != null) {
      return RefreshIndicator(
        onRefresh: _fetchLogs,
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                  const SizedBox(height: 16),
                  const Text('Failed to load logs', style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
                  const SizedBox(height: 24),
                  ElevatedButton(onPressed: _fetchLogs, child: const Text('Retry')),
                  const SizedBox(height: 100), // Extra space for pull-to-refresh
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (logs == null || logs.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchLogs,
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No logs available', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                  const SizedBox(height: 100), // Extra space for pull-to-refresh
                ],
              ),
            ),
          ),
        ),
      );
    }

    List<Map<String, dynamic>> filteredLogs = logs;
    if (_filter == 'errors') {
      filteredLogs = logs.where((log) {
        final text = log['message'] ?? log['text'] ?? log.toString();
        return text.toString().toLowerCase().contains('error');
      }).toList();
    } else if (_filter == 'info') {
      filteredLogs = logs.where((log) {
        final text = log['message'] ?? log['text'] ?? log.toString();
        return !text.toString().toLowerCase().contains('error');
      }).toList();
    }

    return RefreshIndicator(
      onRefresh: _fetchLogs,
      color: AppTheme.primary,
      child: Container(
        color: const Color(0xFF000000),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          itemCount: filteredLogs.length,
          itemBuilder: (context, index) {
            final log = filteredLogs[index];
            final message = log['message'] ?? log['text'] ?? log.toString();
            final timestamp = log['timestamp'] ?? log['date'];
            final level = message.toString().toLowerCase().contains('error') ? 'ERROR' : 'INFO';

            return _buildLogLine(timestamp, level, message.toString());
          },
        ),
      ),
    );
  }

  Widget _buildLogLine(dynamic timestamp, String level, String message) {
    Color levelColor;
    switch (level) {
      case 'ERROR':
        levelColor = AppTheme.error;
        break;
      case 'WARN':
        levelColor = const Color(0xFFF5A623);
        break;
      default:
        levelColor = AppTheme.primary;
    }

    String timeStr = '';
    if (timestamp is int) {
      timeStr = DateTime.fromMillisecondsSinceEpoch(timestamp).toString().split(' ').last.split('.').first;
    } else if (timestamp is String) {
      timeStr = timestamp.split('T').last.split('.').first;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              timeStr,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Color(0xFF666666)),
            ),
          ),
          SizedBox(
            width: 45,
            child: Text(
              level,
              style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: levelColor, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: level == 'ERROR' ? AppTheme.error : AppTheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
          border: Border.all(color: isSelected ? AppTheme.primary.withOpacity(0.5) : AppTheme.outlineVariant.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Future<void> _downloadLogs() async {
    List<Map<String, dynamic>>? logsToDownload;
    String logType = 'logs';

    if (_tabController.index == 0) {
      logsToDownload = _runtimeLogs;
      logType = 'runtime-logs';
    } else if (_tabController.index == 1) {
      logsToDownload = _functionLogs;
      logType = 'function-logs';
    } else if (_tabController.index == 2) {
      logsToDownload = _requestLogs;
      logType = 'request-logs';
    } else if (_tabController.index == 3) {
      logsToDownload = _buildLogs;
      logType = 'build-logs';
    }

    if (logsToDownload == null || logsToDownload.isEmpty) return;

    try {
      final buffer = StringBuffer();
      buffer.writeln('=== $logType for ${widget.deployment.name} ===');
      buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
      buffer.writeln('');

      for (final log in logsToDownload) {
        final message = log['message'] ?? log['text'] ?? log.toString();
        final timestamp = log['timestamp'] ?? log['date'];
        buffer.writeln('[$timestamp] $message');
      }

      await Clipboard.setData(ClipboardData(text: buffer.toString()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logs copied to clipboard')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to copy logs: $e')),
        );
      }
    }
  }
}
