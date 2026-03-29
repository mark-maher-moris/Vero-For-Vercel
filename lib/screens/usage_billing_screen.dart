import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';
import '../widgets/project_selector_appbar.dart';

class UsageBillingScreen extends StatefulWidget {
  const UsageBillingScreen({super.key});

  @override
  State<UsageBillingScreen> createState() => _UsageBillingScreenState();
}

class _UsageBillingScreenState extends State<UsageBillingScreen> {
  Map<String, dynamic>? _usageData;
  bool _isLoadingUsage = false;

  @override
  void initState() {
    super.initState();
    _fetchUsageData();
  }

  Future<void> _fetchUsageData() async {
    final appState = Provider.of<AppState>(context, listen: false);
    if (!appState.isAuthenticated) return;

    setState(() => _isLoadingUsage = true);
    try {
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, 1);

      // Format dates to ISO 8601 with milliseconds (truncate microseconds)
      final fromStr = from.toUtc().toIso8601String().split('.').first + 'Z';
      final toStr = now.toUtc().toIso8601String().split('.').first + 'Z';

      final usage = await appState.apiService.getUsage(
        from: fromStr,
        to: toStr,
      );
      if (mounted) {
        setState(() {
          _usageData = usage;
          _isLoadingUsage = false;
        });
      }
    } catch (e) {
      print('Usage API Error: $e');
      // Fallback to empty data to show default metrics
      if (mounted) {
        setState(() {
          _usageData = {};
          _isLoadingUsage = false;
        });
      }
    }
  }

  List<UsageMetric> _getMetrics() {
    if (_usageData == null) return _getDefaultMetrics();

    final metrics = <UsageMetric>[];
    final data = _usageData;

    // Fluid Active CPU
    final cpuSeconds = data?['cpuDuration']?['total'] as num? ?? 0;
    metrics.add(UsageMetric(
      name: 'Fluid Active CPU',
      current: cpuSeconds.toDouble(),
      limit: 4 * 3600,
      unit: 'seconds',
      displayUnit: 'time',
    ));

    // Image Optimization - Transformations
    final imgTransform = data?['imageOptimization']?['transformations']?['total'] as num? ?? 0;
    metrics.add(UsageMetric(
      name: 'Image Optimization - Transformations',
      current: imgTransform.toDouble(),
      limit: 5000,
      unit: 'transformations',
      displayUnit: 'count',
    ));

    // Edge Requests
    final edgeReqs = data?['edgeRequests']?['total'] as num? ?? 0;
    metrics.add(UsageMetric(
      name: 'Edge Requests',
      current: edgeReqs.toDouble(),
      limit: 1000000,
      unit: 'requests',
      displayUnit: 'count',
    ));

    // Fast Data Transfer
    final dataTransfer = data?['fastDataTransfer']?['total'] as num? ?? 0;
    metrics.add(UsageMetric(
      name: 'Fast Data Transfer',
      current: dataTransfer.toDouble(),
      limit: 100 * 1024 * 1024 * 1024,
      unit: 'bytes',
      displayUnit: 'data',
    ));

    // Fluid Provisioned Memory
    final memHours = data?['memory']?['provisioned']?['total'] as num? ?? 0;
    metrics.add(UsageMetric(
      name: 'Fluid Provisioned Memory',
      current: memHours.toDouble(),
      limit: 360,
      unit: 'GB-hours',
      displayUnit: 'memory',
    ));

    // Fast Origin Transfer
    final originTransfer = data?['fastOriginTransfer']?['total'] as num? ?? 0;
    metrics.add(UsageMetric(
      name: 'Fast Origin Transfer',
      current: originTransfer.toDouble(),
      limit: 10 * 1024 * 1024 * 1024,
      unit: 'bytes',
      displayUnit: 'data',
    ));

    // Function Invocations
    final fnInvocations = data?['invocations']?['total'] as num? ?? 0;
    metrics.add(UsageMetric(
      name: 'Function Invocations',
      current: fnInvocations.toDouble(),
      limit: 1000000,
      unit: 'invocations',
      displayUnit: 'count',
    ));

    // ISR Reads
    final isrReads = data?['isrReads']?['total'] as num? ?? 0;
    metrics.add(UsageMetric(
      name: 'ISR Reads',
      current: isrReads.toDouble(),
      limit: 1000000,
      unit: 'reads',
      displayUnit: 'count',
    ));

    // Image Optimization - Cache Writes
    final cacheWrites = data?['imageOptimization']?['cacheWrites']?['total'] as num? ?? 0;
    metrics.add(UsageMetric(
      name: 'Image Optimization - Cache Writes',
      current: cacheWrites.toDouble(),
      limit: 100000,
      unit: 'writes',
      displayUnit: 'count',
    ));

    // Image Optimization - Cache Reads
    final cacheReads = data?['imageOptimization']?['cacheReads']?['total'] as num? ?? 0;
    metrics.add(UsageMetric(
      name: 'Image Optimization - Cache Reads',
      current: cacheReads.toDouble(),
      limit: 300000,
      unit: 'reads',
      displayUnit: 'count',
    ));

    return metrics;
  }

  List<UsageMetric> _getDefaultMetrics() {
    return [
      UsageMetric(name: 'Fluid Active CPU', current: 0, limit: 4 * 3600, unit: 'seconds', displayUnit: 'time'),
      UsageMetric(name: 'Image Optimization - Transformations', current: 0, limit: 5000, unit: 'transformations', displayUnit: 'count'),
      UsageMetric(name: 'Edge Requests', current: 0, limit: 1000000, unit: 'requests', displayUnit: 'count'),
      UsageMetric(name: 'Fast Data Transfer', current: 0, limit: 100 * 1024 * 1024 * 1024, unit: 'bytes', displayUnit: 'data'),
      UsageMetric(name: 'Fluid Provisioned Memory', current: 0, limit: 360, unit: 'GB-hours', displayUnit: 'memory'),
      UsageMetric(name: 'Fast Origin Transfer', current: 0, limit: 10 * 1024 * 1024 * 1024, unit: 'bytes', displayUnit: 'data'),
      UsageMetric(name: 'Function Invocations', current: 0, limit: 1000000, unit: 'invocations', displayUnit: 'count'),
      UsageMetric(name: 'ISR Reads', current: 0, limit: 1000000, unit: 'reads', displayUnit: 'count'),
      UsageMetric(name: 'Image Optimization - Cache Writes', current: 0, limit: 100000, unit: 'writes', displayUnit: 'count'),
      UsageMetric(name: 'Image Optimization - Cache Reads', current: 0, limit: 300000, unit: 'reads', displayUnit: 'count'),
    ];
  }

  String _formatCurrentValue(double value, String displayUnit) {
    switch (displayUnit) {
      case 'time':
        final hours = (value / 3600).floor();
        final minutes = ((value % 3600) / 60).floor();
        final seconds = (value % 60).floor();
        if (hours > 0) return '${hours}m ${minutes.toString().padLeft(2, '0')}s';
        return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
      case 'count':
        if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(0)}M';
        if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
        return value.toInt().toString();
      case 'data':
        final gb = value / (1024 * 1024 * 1024);
        if (gb >= 1) return '${gb.toStringAsFixed(2)} GB';
        final mb = value / (1024 * 1024);
        return '${mb.toStringAsFixed(2)} MB';
      case 'memory':
        return '${value.toStringAsFixed(1)} GB-Hrs';
      default:
        return value.toStringAsFixed(0);
    }
  }

  String _formatLimitValue(double limit, String displayUnit) {
    switch (displayUnit) {
      case 'time':
        return '4h';
      case 'count':
        if (limit >= 1000000) return '1M';
        if (limit >= 1000) return '${(limit / 1000).toStringAsFixed(0)}K';
        return limit.toInt().toString();
      case 'data':
        final gb = limit / (1024 * 1024 * 1024);
        return '${gb.toStringAsFixed(0)} GB';
      case 'memory':
        return '${limit.toStringAsFixed(0)} GB-Hrs';
      default:
        return limit.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _getMetrics();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: const ProjectSelectorAppBar(),
      body: RefreshIndicator(
        onRefresh: _fetchUsageData,
        color: AppTheme.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
          children: [
            // Header with Upgrade button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Last 30 days',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Upgrade',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Usage Metrics List
            if (_isLoadingUsage)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              )
            else
              ...metrics.map((metric) => _buildUsageMetricItem(metric)),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageMetricItem(UsageMetric metric) {
    final progress = metric.limit > 0 ? (metric.current / metric.limit).clamp(0.0, 1.0) : 0.0;
    final currentStr = _formatCurrentValue(metric.current, metric.displayUnit);
    final limitStr = _formatLimitValue(metric.limit, metric.displayUnit);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Progress ring
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: AppTheme.surfaceContainerHigh,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress > 0.8 ? Colors.orange : const Color(0xFF3B82F6),
                  ),
                ),
                Center(
                  child: Icon(
                    _getIconForMetric(metric.name),
                    size: 16,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Metric name and progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Progress bar
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: progress > 0.8 ? Colors.orange : const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Usage values
          Text(
            '$currentStr / $limitStr',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurface,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForMetric(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('cpu')) return Icons.memory;
    if (lower.contains('image')) return Icons.image;
    if (lower.contains('edge')) return Icons.network_check;
    if (lower.contains('data') || lower.contains('transfer')) return Icons.swap_horiz;
    if (lower.contains('memory')) return Icons.storage;
    if (lower.contains('function') || lower.contains('invocation')) return Icons.code;
    if (lower.contains('isr')) return Icons.refresh;
    if (lower.contains('cache')) return Icons.cached;
    return Icons.circle_outlined;
  }
}

class UsageMetric {
  final String name;
  final double current;
  final double limit;
  final String unit;
  final String displayUnit;

  UsageMetric({
    required this.name,
    required this.current,
    required this.limit,
    required this.unit,
    required this.displayUnit,
  });
}
