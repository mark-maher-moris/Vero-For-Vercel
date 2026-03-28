import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/deployment.dart';
import '../services/api_service.dart';

class DeploymentLogsScreen extends StatefulWidget {
  final Deployment deployment;

  const DeploymentLogsScreen({super.key, required this.deployment});

  @override
  State<DeploymentLogsScreen> createState() => _DeploymentLogsScreenState();
}

class _DeploymentLogsScreenState extends State<DeploymentLogsScreen> {
  final VercelApi _api = VercelApi();
  List<dynamic>? _logs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    try {
      final logs = await _api.getDeploymentEvents(widget.deployment.uid);
      if (mounted) {
        setState(() {
          _logs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final readyState = widget.deployment.state;
    final isError = readyState == 'ERROR';
    final isReady = readyState == 'READY';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLow,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.deployment.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(widget.deployment.uid, style: const TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant, fontFamily: 'monospace')),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isReady ? AppTheme.success : (isError ? AppTheme.error : AppTheme.secondary),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  readyState.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Subheader Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              border: Border(bottom: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.1))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.commit, size: 16, color: AppTheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      'main_branch', // placeholder
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                  ],
                ),
                Text(
                  'Deploy triggered from push', // placeholder
                  style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Tools / Filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: AppTheme.surfaceContainerLow,
            child: Row(
              children: [
                _buildFilterChip('All', true),
                const SizedBox(width: 8),
                _buildFilterChip('Info', false),
                const SizedBox(width: 8),
                _buildFilterChip('Errors', false),
                const Spacer(),
                const Icon(Icons.download, size: 16, color: AppTheme.onSurfaceVariant),
                const SizedBox(width: 16),
                const Icon(Icons.view_sidebar, size: 16, color: AppTheme.onSurfaceVariant),
              ],
            ),
          ),

          // Terminal Area
          Expanded(
            child: Container(
              color: const Color(0xFF000000), // Pure black terminal background
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : (_logs == null || _logs!.isEmpty)
                  ? const Center(child: Text('No logs available.', style: TextStyle(color: AppTheme.onSurfaceVariant)))
                  : ListView.builder(
                      itemCount: _logs!.length,
                      itemBuilder: (context, index) {
                        final log = _logs![index];
                        final payload = log['payload'] ?? {};
                        final text = payload['text'] ?? payload['message'] ?? log.toString();
                        final isErrorLog = text.toString().toLowerCase().contains('error');
                        final isWarnLog = text.toString().toLowerCase().contains('warn');
                        final level = isErrorLog ? 'ERROR' : (isWarnLog ? 'WARN' : 'INFO');
                        // mock time as api might not provide consistent format easily parseable here in demo
                        return _buildLogLine('', level, text.toString());
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
        border: Border.all(color: isSelected ? AppTheme.primary.withValues(alpha: 0.5) : AppTheme.outlineVariant.withValues(alpha: 0.2)),
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
    );
  }

  Widget _buildLogLine(String time, String level, String message) {
    Color levelColor;
    switch (level) {
      case 'ERROR':
        levelColor = AppTheme.error;
        break;
      case 'WARN':
        levelColor = const Color(0xFFF5A623); // Vercel Warning Yellow
        break;
      default:
        levelColor = AppTheme.primary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              time,
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
}
