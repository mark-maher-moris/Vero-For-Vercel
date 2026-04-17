import 'package:flutter/material.dart';
import 'dart:ui' show FontFeature;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/deployment.dart';
import '../models/log.dart';
import '../providers/app_state.dart';
import 'log_detail_screen.dart';

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
  List<Log>? _logs;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String _filter = 'all';
  
  // Pagination state
  int _currentPage = 0;
  bool _hasMoreRows = false;
  bool _isPaginatedView = true; // Toggle between old tab view and new paginated view
  
  // Filter state (Revcel-style)
  Map<String, List<String>> _selectedFilters = {};
  Map<String, List<LogFilterValue>> _availableFilters = {};
  bool _isLoadingFilters = false;
  
  // Date range
  DateTime _startDate = DateTime.now().subtract(const Duration(hours: 1));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _fetchLogs(useNewApi: true);
    _fetchAvailableFilters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging && !_isPaginatedView) {
      _fetchLogs(useNewApi: false);
    }
  }

  Future<void> _fetchLogs({bool useNewApi = true, bool loadMore = false}) async {
    if (loadMore) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        if (!loadMore) {
          _currentPage = 0;
          _logs = null;
        }
      });
    }

    try {
      final appState = context.read<AppState>();
      
      if (useNewApi) {
        // Use Revcel-style /logs/request-logs endpoint
        // Get ownerId from team or user
        final ownerId = appState.currentTeamId ?? appState.user?['id']?.toString();
        if (ownerId == null) {
          throw Exception('No owner ID available. Please check your account settings.');
        }
        
        final result = await appState.apiService.getProjectLogs(
          projectId: widget.projectId,
          ownerId: ownerId,
          deploymentId: widget.deployment.uid,
          startDate: _startDate.millisecondsSinceEpoch.toString(),
          endDate: _endDate.millisecondsSinceEpoch.toString(),
          page: loadMore ? _currentPage + 1 : 0,
          attributes: _selectedFilters.isNotEmpty ? _selectedFilters : null,
        );

        if (mounted) {
          setState(() {
            if (loadMore && _logs != null) {
              _logs!.addAll(result.logs);
              _currentPage++;
            } else {
              _logs = result.logs;
              _currentPage = 0;
            }
            _hasMoreRows = result.hasMoreRows;
            _isLoading = false;
            _isLoadingMore = false;
          });
        }
      } else {
        // Legacy tab-based fetching (kept for backward compatibility)
        await _fetchLegacyLogs(appState);
      }
    } catch (e) {
      print('[AdvancedLogs] Error fetching logs: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _fetchLegacyLogs(dynamic appState) async {
    // Legacy implementation for non-paginated view
    final currentIndex = _tabController.index;
    
    // Get ownerId from team or user
    final ownerId = appState.currentTeamId ?? appState.user?['id']?.toString();
    if (ownerId == null) {
      throw Exception('No owner ID available. Please check your account settings.');
    }
    
    if (currentIndex == 0) {
      final result = await appState.apiService.getProjectLogs(
        projectId: widget.projectId,
        ownerId: ownerId,
        deploymentId: widget.deployment.uid,
        startDate: _startDate.millisecondsSinceEpoch.toString(),
        endDate: _endDate.millisecondsSinceEpoch.toString(),
      );
      _logs = result.logs;
    } else if (currentIndex == 3) {
      // Build logs - create minimal Log objects from build events
      final buildLogs = await appState.apiService.getDeploymentBuildLogs(
        projectId: widget.projectId,
        deploymentId: widget.deployment.uid,
      );
      _logs = buildLogs.map((json) => Log.fromJson({
        'requestId': json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'timestamp': json['date'] ?? DateTime.now().toIso8601String(),
        'requestMethod': 'BUILD',
        'statusCode': json['type'] == 'error' ? 500 : 200,
        'domain': widget.deployment.url,
        'requestPath': json['text']?.toString() ?? '',
        'logs': [{
          'message': json['text']?.toString() ?? '',
          'level': json['type'] == 'error' ? 'error' : 'info',
          'timestamp': json['date'] ?? DateTime.now().toIso8601String(),
          'source': 'build',
        }],
        'events': [],
        'branch': '',
        'deploymentId': widget.deployment.uid,
        'deploymentDomain': widget.deployment.url,
        'environment': 'production',
        'route': '',
        'clientUserAgent': '',
        'clientRegion': '',
        'requestSearchParams': {},
        'cache': '',
        'requestTags': [],
      })).toList();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAvailableFilters() async {
    setState(() => _isLoadingFilters = true);
    
    try {
      final appState = context.read<AppState>();
      final filters = await appState.apiService.getProjectLogsFilters(
        projectId: widget.projectId,
        attributes: ['host', 'method', 'statusCode', 'source'],
        startDate: _startDate.millisecondsSinceEpoch.toString(),
        endDate: _endDate.millisecondsSinceEpoch.toString(),
      );
      
      if (mounted) {
        setState(() {
          _availableFilters = filters;
          _isLoadingFilters = false;
        });
      }
    } catch (e) {
      print('[AdvancedLogs] Error fetching filters: $e');
      if (mounted) {
        setState(() => _isLoadingFilters = false);
      }
    }
  }

  Future<void> _loadMoreLogs() async {
    if (_hasMoreRows && !_isLoadingMore) {
      await _fetchLogs(useNewApi: true, loadMore: true);
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
                if (_availableFilters.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.filter_list, size: 16, color: AppTheme.onSurfaceVariant),
                    onPressed: _showFilterDialog,
                    tooltip: 'Advanced filters',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const SizedBox(width: 8),
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
            child: _isPaginatedView 
              ? _buildPaginatedLogView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLogView(),
                    _buildLogView(),
                    _buildLogView(),
                    _buildLogView(),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginatedLogView() {
    if (_isLoading && _logs == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_errorMessage != null) {
      return RefreshIndicator(
        onRefresh: () => _fetchLogs(useNewApi: true),
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
                  ElevatedButton(onPressed: () => _fetchLogs(useNewApi: true), child: const Text('Retry')),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_logs == null || _logs!.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _fetchLogs(useNewApi: true),
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
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Apply client-side filtering based on console log levels
    List<Log> filteredLogs = _logs!;
    if (_filter == 'errors') {
      filteredLogs = _logs!.where((log) => 
        log.logs.any((l) => l.level.toLowerCase() == 'error') || log.statusCode >= 500
      ).toList();
    } else if (_filter == 'info') {
      filteredLogs = _logs!.where((log) => 
        log.logs.every((l) => l.level.toLowerCase() != 'error') && log.statusCode < 500
      ).toList();
    }

    return RefreshIndicator(
      onRefresh: () => _fetchLogs(useNewApi: true),
      color: AppTheme.primary,
      child: Column(
        children: [
          // Table header
          _buildTableHeader(),
          Expanded(
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredLogs.length,
              itemBuilder: (context, index) {
                final log = filteredLogs[index];
                return _buildLogListRow(log, index % 2 == 0);
              },
            ),
          ),
          if (_hasMoreRows)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _isLoadingMore ? null : _loadMoreLogs,
                child: _isLoadingMore
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Load More'),
              ),
            ),
        ],
      ),
    );
  }

  /// Build minimal header matching competitor's clean design
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          // Timestamp column
          SizedBox(
            width: 70,
            child: Text(
              'Time',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Request info column
          Expanded(
            child: Text(
              'Request',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build log list row matching competitor design
  /// Shows timestamp and a combined method+path+status message
  Widget _buildLogListRow(Log log, bool isEven) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LogDetailScreen(
              log: log,
              projectId: widget.projectId,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: isEven ? AppTheme.surfaceContainerLow.withOpacity(0.3) : AppTheme.surface,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timestamp (matching competitor's HH:mm:ss format)
            SizedBox(
              width: 70,
              child: Text(
                log.formattedTime,
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  color: AppTheme.onSurfaceVariant,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Method badge + Path + Status (combined like competitor)
            Expanded(
              child: Row(
                children: [
                  // Method badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getMethodColor(log.requestMethod).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      log.requestMethod,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getMethodColor(log.requestMethod),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Path
                  Expanded(
                    child: Text(
                      log.requestPath,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status code with color
                  Text(
                    log.statusCode.toString(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Log.getStatusColor(log.statusCode),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return const Color(0xFF22C55E); // Green
      case 'POST':
        return const Color(0xFF3B82F6); // Blue
      case 'PUT':
        return const Color(0xFFF59E0B); // Orange
      case 'DELETE':
        return const Color(0xFFEF4444); // Red
      case 'PATCH':
        return const Color(0xFF8B5CF6); // Purple
      default:
        return AppTheme.onSurfaceVariant;
    }
  }

  Widget _buildLogView() {
    // Legacy tab-based view - just show the paginated view for now
    return _buildPaginatedLogView();
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
    if (_logs == null || _logs!.isEmpty) return;

    try {
      final buffer = StringBuffer();
      buffer.writeln('=== Request Logs for ${widget.deployment.name} ===');
      buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
      buffer.writeln('');

      for (final log in _logs!) {
        buffer.writeln('[${log.timestamp}] ${log.displayMessage}');
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

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Logs',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (_isLoadingFilters)
                        const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_availableFilters.isEmpty)
                    const Text('No filters available'),
                  ..._availableFilters.entries.map((entry) {
                    final attributeName = entry.key;
                    final values = entry.value;
                    final selectedValues = _selectedFilters[attributeName] ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attributeName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: values.map((filterValue) {
                            final isSelected = selectedValues.contains(filterValue.attributeValue);
                            return FilterChip(
                              label: Text('${filterValue.attributeValue} (${filterValue.total})'),
                              selected: isSelected,
                              onSelected: (selected) {
                                setModalState(() {
                                  setState(() {
                                    if (selected) {
                                      _selectedFilters[attributeName] = [...selectedValues, filterValue.attributeValue];
                                    } else {
                                      _selectedFilters[attributeName] = selectedValues.where((v) => v != filterValue.attributeValue).toList();
                                    }
                                    if (_selectedFilters[attributeName]!.isEmpty) {
                                      _selectedFilters.remove(attributeName);
                                    }
                                  });
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            setState(() => _selectedFilters.clear());
                          });
                          _fetchLogs(useNewApi: true);
                          Navigator.pop(context);
                        },
                        child: const Text('Clear'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          _fetchLogs(useNewApi: true);
                          Navigator.pop(context);
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
