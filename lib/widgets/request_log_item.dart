import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RequestLogItem extends StatelessWidget {
  final Map<String, dynamic> log;
  final VoidCallback? onTap;

  const RequestLogItem({
    super.key,
    required this.log,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = _formatTimestamp(log['timestamp'] ?? log['date']);
    final method = log['method']?.toString().toUpperCase() ?? 'GET';
    final statusCode = log['statusCode'] ?? log['status'] ?? 200;
    final domain = log['domain'] ?? log['host'] ?? 'unknown';
    final path = log['path'] ?? log['url'] ?? '/';

    final statusColor = _getStatusColor(statusCode);

    return InkWell(
      onTap: onTap ?? () => _showLogDetails(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: AppTheme.outlineVariant.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Timestamp
            SizedBox(
              width: 70,
              child: Text(
                timestamp,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Method
            SizedBox(
              width: 50,
              child: Text(
                method,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Status Code
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                statusCode.toString(),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Domain
            Expanded(
              flex: 2,
              child: Text(
                _truncateDomain(domain),
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Path
            Expanded(
              flex: 3,
              child: Text(
                _truncatePath(path.toString()),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.onSurface,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    DateTime? date;
    if (timestamp is int) {
      date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      date = DateTime.tryParse(timestamp);
    }
    
    if (date == null) return '--:--:--';
    
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(dynamic statusCode) {
    final code = statusCode is int ? statusCode : int.tryParse(statusCode.toString()) ?? 0;
    
    if (code >= 200 && code < 300) {
      return const Color(0xFF22C55E); // Green for 2xx
    } else if (code >= 300 && code < 400) {
      return const Color(0xFFF59E0B); // Yellow for 3xx
    } else if (code >= 400 && code < 500) {
      return const Color(0xFFF97316); // Orange for 4xx
    } else if (code >= 500) {
      return const Color(0xFFEF4444); // Red for 5xx
    }
    return AppTheme.onSurfaceVariant;
  }

  String _truncateDomain(String domain) {
    if (domain.length > 20) {
      return '${domain.substring(0, 17)}...';
    }
    return domain;
  }

  String _truncatePath(String path) {
    if (path.length > 30) {
      return '${path.substring(0, 27)}...';
    }
    return path;
  }

  void _showLogDetails(BuildContext context) {
    final timestamp = log['timestamp'] ?? log['date'];
    final method = log['method']?.toString().toUpperCase() ?? 'GET';
    final statusCode = log['statusCode'] ?? log['status'] ?? 200;
    final domain = log['domain'] ?? log['host'] ?? 'unknown';
    final path = log['path'] ?? log['url'] ?? '/';
    final userAgent = log['userAgent']?.toString() ?? 'Unknown';
    final ip = log['ip']?.toString() ?? 'Unknown';
    final region = log['region']?.toString() ?? 'Unknown';
    final duration = log['duration'] ?? log['responseTime'];
    final referer = log['referer']?.toString() ?? '';
    final requestId = log['requestId']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerLow,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outlineVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(statusCode).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusCode.toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _getStatusColor(statusCode),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$method $path',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            domain,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Details
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection('Request Details', [
                        _buildDetailRow('Method', method),
                        _buildDetailRow('URL', 'https://$domain$path'),
                        if (requestId.isNotEmpty) _buildDetailRow('Request ID', requestId),
                        _buildDetailRow('Timestamp', _formatFullTimestamp(timestamp)),
                        if (duration != null) _buildDetailRow('Duration', '${duration}ms'),
                      ]),
                      const SizedBox(height: 24),
                      _buildDetailSection('Client Information', [
                        _buildDetailRow('IP Address', ip),
                        _buildDetailRow('Region', region),
                        _buildDetailRow('User Agent', userAgent),
                        if (referer.isNotEmpty) _buildDetailRow('Referer', referer),
                      ]),
                      if (log['headers'] != null) ...[
                        const SizedBox(height: 24),
                        _buildDetailSection('Headers', _buildHeadersList(log['headers'])),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppTheme.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHeadersList(dynamic headers) {
    if (headers is! Map) return [];
    
    return headers.entries.map((entry) {
      return _buildDetailRow(
        entry.key.toString(),
        entry.value?.toString() ?? '',
      );
    }).toList();
  }

  String _formatFullTimestamp(dynamic timestamp) {
    DateTime? date;
    if (timestamp is int) {
      date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      date = DateTime.tryParse(timestamp);
    }
    
    if (date == null) return 'Unknown';
    
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
           '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }
}
