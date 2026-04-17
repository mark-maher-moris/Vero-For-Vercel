import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/log.dart';

/// Log detail screen - shows detailed information about a single request log
/// Matches the competitor's log details screen design
class LogDetailScreen extends StatelessWidget {
  final Log log;
  final String projectId;

  const LogDetailScreen({
    super.key,
    required this.log,
    required this.projectId,
  });

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
        title: const Text('Log Details', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Info rows section
            _buildInfoRowsSection(),
            
            // Console logs section
            if (log.logs.isNotEmpty)
              _buildConsoleLogsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRowsSection() {
    return Column(
      children: [
        _InfoRow(
          label: 'Timestamp',
          icon: Icons.access_time,
          value: log.formattedTime,
          isLight: true,
        ),
        _InfoRow(
          label: 'Method',
          icon: Icons.code,
          value: log.requestMethod,
        ),
        _InfoRow(
          label: 'Status',
          icon: Icons.bar_chart,
          value: log.statusCode.toString(),
          isLight: true,
          valueColor: Log.getStatusColor(log.statusCode),
        ),
        _InfoRow(
          label: 'Domain',
          icon: Icons.language,
          value: log.domain,
        ),
        _InfoRow(
          label: 'Path',
          icon: Icons.route,
          value: log.requestPath,
          isLight: true,
        ),
        _InfoRow(
          label: 'Search Params',
          icon: Icons.search,
          value: log.searchParamsString,
        ),
        _InfoRow(
          label: 'Route',
          icon: Icons.navigation,
          value: log.route,
          isLight: true,
        ),
        _InfoRow(
          label: 'Cache',
          icon: Icons.save,
          value: log.cache.isNotEmpty ? log.cache : 'N/A',
        ),
        _InfoRow(
          label: 'Agent',
          icon: Icons.person,
          value: log.clientUserAgent.isNotEmpty 
            ? (log.clientUserAgent.length > 50 
                ? '${log.clientUserAgent.substring(0, 50)}...' 
                : log.clientUserAgent)
            : 'N/A',
          isLight: true,
        ),
        _InfoRow(
          label: 'Received In',
          icon: Icons.map,
          value: log.regionLabel ?? log.clientRegion,
        ),
        _InfoRow(
          label: 'Deployment ID',
          icon: Icons.language,
          value: log.deploymentId.isNotEmpty 
            ? '${log.deploymentId.substring(0, log.deploymentId.length > 8 ? 8 : log.deploymentId.length)}...'
            : 'N/A',
          isLight: true,
          onCopy: log.deploymentId.isNotEmpty 
            ? () => _copyToClipboard(log.deploymentId)
            : null,
        ),
        if (log.memoryUsed != null)
          _InfoRow(
            label: 'Memory',
            icon: Icons.memory,
            value: log.memoryUsed!,
          ),
        if (log.duration != null)
          _InfoRow(
            label: 'Duration',
            icon: Icons.timer,
            value: log.duration!,
            isLight: true,
          ),
        _InfoRow(
          label: 'Type',
          icon: Icons.info,
          value: log.mainEvent?.source != null 
            ? _capitalizeFirst(log.mainEvent!.source!)
            : 'Unknown',
        ),
        _InfoRow(
          label: 'Routed To',
          icon: Icons.map,
          value: log.routedToLabel ?? 'N/A',
          isLight: true,
        ),
        _InfoRow(
          label: 'Environment',
          icon: Icons.cloud,
          value: _capitalizeFirst(log.environment),
        ),
        _InfoRow(
          label: 'Branch',
          icon: Icons.account_tree,
          value: log.branch.isNotEmpty ? log.branch : 'N/A',
          isLight: true,
        ),
      ],
    );
  }

  Widget _buildConsoleLogsSection() {
    return Container(
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.surfaceContainerLow,
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 18, color: AppTheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Console Logs (${log.logs.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          ...log.logs.asMap().entries.map((entry) {
            final index = entry.key;
            final logLine = entry.value;
            return _buildLogLine(logLine, index);
          }),
        ],
      ),
    );
  }

  Widget _buildLogLine(LogLine logLine, int index) {
    final timeStr = _formatTime(logLine.timestamp);
    final isError = logLine.level.toLowerCase() == 'error';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: index % 2 == 0 ? AppTheme.surfaceContainerLow.withOpacity(0.5) : Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            timeStr,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            logLine.message,
            style: TextStyle(
              fontSize: 13,
              color: isError ? AppTheme.error : AppTheme.onSurface,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final second = timestamp.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  String _capitalizeFirst(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }
}

/// Info row widget - matches the competitor's InfoRow component
class _InfoRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final bool isLight;
  final Color? valueColor;
  final VoidCallback? onCopy;

  const _InfoRow({
    required this.label,
    required this.icon,
    required this.value,
    this.isLight = false,
    this.valueColor,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: isLight ? AppTheme.surfaceContainerLow.withOpacity(0.3) : AppTheme.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 14,
                          color: valueColor ?? AppTheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (onCopy != null)
                      GestureDetector(
                        onTap: onCopy,
                        child: const Icon(
                          Icons.copy,
                          size: 16,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
