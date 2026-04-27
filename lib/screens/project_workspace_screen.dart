import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import '../models/project.dart';
import '../models/deployment.dart';
import '../models/log.dart';
import '../models/analytics.dart';
import '../services/api_service.dart';
import '../providers/app_state.dart';
import '../providers/subscription_provider.dart';
import '../services/superwall_service.dart';
import '../models/deployment_file.dart';
import '../theme/app_theme.dart';
import '../models/env_var.dart';
import '../widgets/deployment_card.dart';
import '../widgets/project_logo_widget.dart';
// import '../widgets/traffic_globe.dart'; // Temporarily hidden
import '../widgets/analytics_metric_card.dart';
import '../widgets/analytics_chart.dart';
import '../widgets/analytics_breakdown_card.dart';
import 'file_content_screen.dart';
import 'deployment_logs_screen.dart';

class ProjectWorkspaceScreen extends StatefulWidget {
  final Project project;

  const ProjectWorkspaceScreen({super.key, required this.project});

  @override
  State<ProjectWorkspaceScreen> createState() => _ProjectWorkspaceScreenState();
}

class _ProjectWorkspaceScreenState extends State<ProjectWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  bool _isEditingEnvVar = false;
  late TabController _tabController;
  List<Deployment>? _deployments;
  List<dynamic>? _domains;
  List<dynamic>? _envVars;
  bool _isLoading = true;
  bool _isRedeploying = false;
  bool _isFetchingData = false;
  String? _errorMessage;
  late Future<List<DeploymentFile>> _deploymentFilesFuture;

  // Analytics State
  AnalyticsData _analyticsData = AnalyticsData();
  TimeRange _selectedTimeRange = TimeRange.week;
  bool _isLoadingAnalytics = false;
  String? _analyticsError;
  bool _analyticsLocked = false;
  bool get _analyticsEnabled => widget.project.webAnalytics != null && !_analyticsLocked;

  // Live deployment logs (request logs like competitor)
  List<Log>? _liveLogs;
  bool _isLoadingLiveLogs = false;
  String? _liveLogsError;
  String _logsFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
    // Initialize with a dummy future that will be replaced in _fetchData
    _deploymentFilesFuture = Future.value([]);
    // Track project workspace view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SuperwallService().trackScreenView('project_workspace', additionalProps: {
        'project_id': widget.project.id,
        'project_name': widget.project.name,
        'framework': widget.project.framework,
      });
    });
    // Listen to tab changes for analytics and lazy-load logs
    _tabController.addListener(_onTabChanged);
    _fetchData();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final tabNames = ['overview', 'logs', 'deployments', 'files', 'activity', 'cron_jobs', 'security', 'env_vars', 'domains'];
      SuperwallService().trackUserAction('switch_tab',
        context: 'project_workspace',
        properties: {
          'tab_name': tabNames[_tabController.index],
          'project_id': widget.project.id,
        }
      );
    }
    // Lazy load live logs when switching to logs tab
    if (_tabController.index == 1 && !_tabController.indexIsChanging) {
      _fetchLiveDeploymentLogs();
    }
    // Rebuild to update TabBarView physics based on current tab
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _fetchAnalytics() async {
    if (_isLoadingAnalytics) return;

    setState(() {
      _isLoadingAnalytics = true;
      _analyticsError = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final pid = widget.project.id;
      final range = _selectedTimeRange;

      // Parallel data fetching for analytics
      final results = await Future.wait([
        appState.apiService.getAnalyticsOverview(projectId: pid, from: range.from, to: range.to),
        appState.apiService.getAnalyticsOverview(projectId: pid, from: range.previousFrom, to: range.previousTo),
        appState.apiService.getAnalyticsTimeseries(projectId: pid, from: range.from, to: range.to),
        appState.apiService.getAnalyticsBreakdown(projectId: pid, from: range.from, to: range.to, groupBy: 'path'),
        appState.apiService.getAnalyticsBreakdown(projectId: pid, from: range.from, to: range.to, groupBy: 'referrer'),
        appState.apiService.getAnalyticsBreakdown(projectId: pid, from: range.from, to: range.to, groupBy: 'country'),
        appState.apiService.getAnalyticsBreakdown(projectId: pid, from: range.from, to: range.to, groupBy: 'device_type'),
        appState.apiService.getAnalyticsBreakdown(projectId: pid, from: range.from, to: range.to, groupBy: 'client_name'),
        appState.apiService.getAnalyticsBreakdown(projectId: pid, from: range.from, to: range.to, groupBy: 'os_name'),
        appState.apiService.getAnalyticsBreakdown(projectId: pid, from: range.from, to: range.to, groupBy: 'route'),
        appState.apiService.getAnalyticsBreakdown(projectId: pid, from: range.from, to: range.to, groupBy: 'hostname'),
      ]);

      if (mounted) {
        setState(() {
          _analyticsData = AnalyticsData()
            ..overview = results[0] as AnalyticsOverview
            ..previousOverview = results[1] as AnalyticsOverview
            ..timeseries = results[2] as List<TimeseriesPoint>
            ..pages = results[3] as List<BreakdownItem>
            ..referrers = results[4] as List<BreakdownItem>
            ..countries = results[5] as List<BreakdownItem>
            ..devices = results[6] as List<BreakdownItem>
            ..browsers = results[7] as List<BreakdownItem>
            ..os = results[8] as List<BreakdownItem>
            ..routes = results[9] as List<BreakdownItem>
            ..hostnames = results[10] as List<BreakdownItem>;
          _isLoadingAnalytics = false;
          _analyticsLocked = false;
        });
      }
    } on VercelApiException catch (e) {
      // Analytics not enabled: typically 403/forbidden
      final isForbidden = e.statusCode == 403 ||
          (e.code != null && (e.code == 'forbidden' || e.code == 'unauthorized'));
      final messageLower = e.message.toLowerCase();
      final isNotEnabled = messageLower.contains('not enabled') ||
          messageLower.contains('analytics') ||
          messageLower.contains('forbidden');

      print('[ProjectWorkspace] Analytics error: ${e.statusCode} - ${e.message} (code: ${e.code})');

        setState(() {
          if (isForbidden || isNotEnabled) {
            _analyticsLocked = true;
            _analyticsError = null; // suppress error, show locked state instead
          } else {
            _analyticsError = e.message;
          }
          _isLoadingAnalytics = false;
        });
    } catch (e) {
      print('[ProjectWorkspace] Error fetching analytics: $e');
      if (mounted) {
        setState(() {
          _analyticsError = e.toString();
          _isLoadingAnalytics = false;
        });
      }
    }
  }

  Future<void> _fetchLiveDeploymentLogs() async {
    print('[ProjectWorkspace] _fetchLiveDeploymentLogs called');
    final liveDeployment = _getLatestLiveDeployment();
    print('[ProjectWorkspace] Live deployment: ${liveDeployment?.uid} (state: ${liveDeployment?.state})');
    if (liveDeployment == null) {
      print('[ProjectWorkspace] No live deployment found');
      return;
    }

    setState(() {
      _isLoadingLiveLogs = true;
      _liveLogsError = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      // Use getProjectLogs (request-logs endpoint) like the competitor app - this works reliably
      print('[ProjectWorkspace] Fetching request logs for deployment: ${liveDeployment.uid}');
      // Get ownerId from team or user
      final ownerId = appState.currentTeamId ?? appState.user?['id']?.toString();
      if (ownerId == null) {
        throw Exception('No owner ID available. Please check your account settings.');
      }
      
      final result = await appState.apiService.getProjectLogs(
        projectId: widget.project.id,
        ownerId: ownerId,
        deploymentId: liveDeployment.uid,
      );
      print('[ProjectWorkspace] Request logs received: ${result.logs.length} entries');

      if (mounted) {
        setState(() {
          // Store full Log objects for competitor-style display
          _liveLogs = result.logs;
          _isLoadingLiveLogs = false;
        });
      }
    } catch (e) {
      print('[ProjectWorkspace] Error fetching request logs: $e');
      if (mounted) {
        setState(() {
          _liveLogsError = e.toString();
          _isLoadingLiveLogs = false;
        });
      }
    }
  }

  Deployment? _getLatestLiveDeployment() {
    if (_deployments == null || _deployments!.isEmpty) return null;

    // Find the latest READY deployment (live)
    final readyDeployments = _deployments!.where((d) => d.state == 'READY').toList();
    if (readyDeployments.isEmpty) return null;

    // Sort by created date descending and return the first
    readyDeployments.sort((a, b) => b.created.compareTo(a.created));
    return readyDeployments.first;
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (_isFetchingData) {
      print('[ProjectWorkspace] _fetchData already in progress, skipping');
      return;
    }
    _isFetchingData = true;
    print('[ProjectWorkspace] _fetchData started');

    final appState = Provider.of<AppState>(context, listen: false);
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Parallel data fetching for base project data and analytics
      final results = await Future.wait([
        appState.apiService.getDeployments(projectId: widget.project.id),
        appState.apiService.getProjectDomains(widget.project.id),
        appState.apiService.getProjectEnvVars(widget.project.id),
        _fetchAnalytics(),
      ]);

      final deps = results[0] as List<Deployment>;
      final doms = results[1] as List<dynamic>;
      final envs = results[2] as List<dynamic>;
      
      // Initialize and await the deployment files future
      // Use file-tree endpoint like competitor (works for all deployment types)
      if (deps.isNotEmpty) {
        final deployment = deps.first;
        _deploymentFilesFuture = appState.apiService.getDeploymentFileTree(
          deploymentUrl: deployment.url,
          base: 'src',
        ).catchError((error) {
          print('[ProjectWorkspace] Error fetching deployment files: $error');
          // Return empty list for Git deployments or other errors
          return <DeploymentFile>[];
        });
        // Wait for files to load before completing _fetchData
        await _deploymentFilesFuture;
      }
      
      if (mounted) {
        setState(() {
          _deployments = deps;
          _domains = doms;
          _envVars = envs;
          _isLoading = false;
        });
      }
      print('[ProjectWorkspace] _fetchData completed successfully');
    } catch (e) {
      print('[ProjectWorkspace] _fetchData error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    } finally {
      _isFetchingData = false;
      print('[ProjectWorkspace] _fetchData finished (isLoading: $_isLoading)');
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(!url.startsWith('http') ? 'https://$url' : url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> _redeployProject() async {
    final appState = Provider.of<AppState>(context, listen: false);
    setState(() => _isRedeploying = true);
    
    // Track deployment action
    SuperwallService().trackDeploymentAction('redeploy', widget.project.id, properties: {
      'project_name': widget.project.name,
    });
    
    try {
      await appState.apiService.createDeployment(
        projectId: widget.project.id,
        target: 'production',
        withLatestCommit: true,
      );
      await _fetchData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Redeployment triggered!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to redeploy: $e')));
      }
    } finally {
      setState(() => _isRedeploying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch subscription provider to check if user has Pro
    final subscription = context.watch<SubscriptionProvider>();
    final isPro = subscription.isPro;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            ProjectLogoWidget(
              project: widget.project,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.project.name,
                style: Theme.of(context).textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new, color: AppTheme.onSurfaceVariant),
            onPressed: () {
              if (_deployments != null && _deployments!.isNotEmpty) {
                _launchUrl(_deployments!.first.url);
              } else {
                _launchUrl('${widget.project.name}.vercel.app');
              }
            },
            tooltip: 'Visit Site',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.onSurfaceVariant),
            onPressed: _isRedeploying ? null : _redeployProject,
            tooltip: 'Redeploy',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          onTap: (index) {
            // Track tab tap attempt
            final tabNames = ['overview', 'logs', 'deployments', 'files', 'activity', 'cron_jobs', 'security', 'env_vars', 'domains'];
            SuperwallService().trackUserAction('tab_tapped', 
              context: 'project_workspace',
              properties: {
                'tab_name': tabNames[index],
                'is_pro_tab': index > 2,
                'is_pro_user': isPro,
              }
            );
            // If free user tries to access pro tabs, show paywall and reset to first tab
            if (!isPro && index > 2) {
              SuperwallService().trackSubscriptionEvent('paywall_triggered', properties: {
                'trigger': 'pro_tab_access',
                'tab_name': tabNames[index],
              });
              _showPaywall(context);
              // Reset to first tab after a short delay
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  _tabController.animateTo(0);
                }
              });
            }
          },
          indicator: BoxDecoration(
            color: AppTheme.surfaceContainerHigh,
            border: const Border(
              bottom: BorderSide(color: AppTheme.primary, width: 2),
            ),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.onSurfaceVariant,
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05 * 11,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.05 * 11,
          ),
          tabs: [
            const Tab(text: 'OVERVIEW'),
            const Tab(text: 'LOGS'),
            const Tab(text: 'DEPLOYMENTS'),
            _buildProTab('FILES', isPro),
            _buildProTab('ACTIVITY', isPro),
            _buildProTab('CRON JOBS', isPro),
            _buildProTab('SECURITY', isPro),
            _buildProTab('ENV VARS', isPro),
            _buildProTab('DOMAINS', isPro),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : _errorMessage != null
              ? _buildErrorView()
              : TabBarView(
                controller: _tabController,
                physics: _tabController.index == 0 ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
                children: [
                  _buildOverviewTab(),
                  _buildLogsTab(),
                  _buildDeploymentsTab(),
                  _buildBlurredTabIfNeeded(_buildFilesTab(), isPro, context),
                  _buildBlurredTabIfNeeded(_buildActivityTab(), isPro, context),
                  _buildBlurredTabIfNeeded(_buildCronJobsTab(), isPro, context),
                  _buildBlurredTabIfNeeded(_buildSecurityTab(), isPro, context),
                  _buildBlurredTabIfNeeded(_buildEnvVarsTab(), isPro, context),
                  _buildBlurredTabIfNeeded(_buildDomainsTab(), isPro, context),
                ],
              ),
    );
  }

  Widget _buildProTab(String text, bool isPro) {
    if (isPro) {
      return Tab(text: text);
    }
    // For free users, show tab with lock icon
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text),
          const SizedBox(width: 4),
          Icon(
            Icons.lock,
            size: 10,
            color: AppTheme.onSurfaceVariant.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurredTabIfNeeded(Widget child, bool isPro, BuildContext context) {
    if (isPro) {
      return child;
    }

    // For free users, wrap with blur overlay
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: AppTheme.surface.withOpacity(0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        color: AppTheme.primary,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Pro Feature',
                        style: TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upgrade to Vero Pro to access this feature',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showPaywall(context),
                        icon: const Icon(Icons.star, size: 18),
                        label: const Text('Upgrade to Pro'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPaywall(BuildContext context) async {
    await SuperwallService().presentPaywall();
    // Refresh subscription status after paywall closes
    if (mounted) {
      final subscription = Provider.of<SubscriptionProvider>(context, listen: false);
      subscription.refresh();
    }
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Failed to load project',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _fetchData, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _fetchData,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Project Overview Section (always visible)
          _buildProjectOverviewSection(),
          const SizedBox(height: 32),
          // Analytics Section (locked or real based on enabled state)
          _analyticsEnabled ? _buildRealAnalyticsSection() : _buildLockedAnalyticsSection(),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildProjectOverviewSection() {
    final projectUrl = widget.project.allUrls.isNotEmpty
        ? 'https://${widget.project.allUrls.first}'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Project Header
        Row(
          children: [
            ProjectLogoWidget(project: widget.project, size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.project.name.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.onSurfaceVariant.withOpacity(0.6),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.project.framework ?? 'Static',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            if (projectUrl != null)
              IconButton(
                icon: const Icon(Icons.open_in_new, color: AppTheme.primary),
                onPressed: () => launchUrl(Uri.parse(projectUrl)),
                tooltip: 'Open project',
              ),
          ],
        ),
        const SizedBox(height: 24),
        // Project Stats Row
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.surfaceContainerHigh),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildProjectStat(
                  'Deployments',
                  '${_deployments?.length ?? 0}',
                  Icons.rocket_outlined,
                ),
              ),
              Container(width: 1, height: 40, color: AppTheme.surfaceContainerHigh),
              Expanded(
                child: _buildProjectStat(
                  'Domains',
                  '${_domains?.length ?? 0}',
                  Icons.language_outlined,
                ),
              ),
              Container(width: 1, height: 40, color: AppTheme.surfaceContainerHigh),
              Expanded(
                child: _buildProjectStat(
                  'Env Vars',
                  '${_envVars?.length ?? 0}',
                  Icons.vpn_key_outlined,
                ),
              ),
              Container(width: 1, height: 40, color: AppTheme.surfaceContainerHigh),
              Expanded(
                child: _buildProjectStat(
                  'Created',
                  timeago.format(widget.project.createdAt),
                  Icons.calendar_today_outlined,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Project URLs
        if (widget.project.allUrls.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.project.allUrls.take(3).map((url) {
              final fullUrl = url.startsWith('http') ? url : 'https://$url';
              return ActionChip(
                avatar: const Icon(Icons.link, size: 16, color: AppTheme.primary),
                label: Text(
                  url.replaceAll('https://', ''),
                  style: const TextStyle(fontSize: 12, color: AppTheme.onSurface),
                ),
                backgroundColor: AppTheme.surfaceContainerHigh,
                side: BorderSide.none,
                onPressed: () => launchUrl(Uri.parse(fullUrl)),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildProjectStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary.withOpacity(0.7)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AppTheme.onSurfaceVariant.withOpacity(0.6),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLockedAnalyticsSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Column(
        children: [
          // Locked Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline,
              size: 48,
              color: AppTheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          // Title
          const Text(
            'Analytics Locked',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          // Description
          Text(
            'Web Analytics is not enabled for this project.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.onSurfaceVariant.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enable it from your Vercel Dashboard to view detailed visitor insights.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.onSurfaceVariant.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          // Enable Analytics Button
          ElevatedButton.icon(
            onPressed: () {
              final url = 'https://vercel.com/dashboard';
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Open Vercel Dashboard'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Preview of what they'd get
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.visibility_off, size: 16, color: AppTheme.onSurfaceVariant.withOpacity(0.5)),
                    const SizedBox(width: 8),
                    Text(
                      'Unlock analytics to see:'.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.onSurfaceVariant.withOpacity(0.6),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildFeatureChip(Icons.people_outline, 'Visitors'),
                    _buildFeatureChip(Icons.remove_red_eye_outlined, 'Page Views'),
                    _buildFeatureChip(Icons.public_outlined, 'Geography'),
                    _buildFeatureChip(Icons.devices_outlined, 'Devices'),
                    _buildFeatureChip(Icons.show_chart, 'Traffic Trends'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealAnalyticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnalyticsHeader(),
        const SizedBox(height: 24),
        _buildMetricCards(),
        const SizedBox(height: 24),
        SizedBox(
          height: 350,
          child: AnalyticsChart(
            data: _analyticsData.timeseries,
            isLoading: _isLoadingAnalytics,
          ),
        ),
        const SizedBox(height: 24),
        // TrafficGlobe(projectId: widget.project.id), // Temporarily hidden
        // const SizedBox(height: 24),
        _buildBreakdownGrid(),
      ],
    );
  }

  Widget _buildAnalyticsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.project.name.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.onSurfaceVariant.withOpacity(0.6),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.circle, size: 8, color: AppTheme.success),
                const SizedBox(width: 8),
                Text(
                  'LIVE ANALYTICS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
        _buildTimeRangePicker(),
      ],
    );
  }

  Widget _buildTimeRangePicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TimeRange>(
          value: _selectedTimeRange,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.primary),
          elevation: 16,
          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
          onChanged: (TimeRange? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedTimeRange = newValue;
              });
              _fetchAnalytics();
            }
          },
          items: TimeRange.values.map<DropdownMenuItem<TimeRange>>((TimeRange value) {
            return DropdownMenuItem<TimeRange>(
              value: value,
              child: Text(value.label),
            );
          }).toList(),
          dropdownColor: AppTheme.surfaceContainerHigh,
        ),
      ),
    );
  }

  Widget _buildMetricCards() {
    return LayoutBuilder(builder: (context, constraints) {
      final cardWidth = (constraints.maxWidth - 32) / 3;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: cardWidth,
            child: AnalyticsMetricCard(
              title: 'Visitors',
              value: NumberFormat.compact().format(_analyticsData.overview?.devices ?? 0),
              change: _analyticsData.visitorsChange,
              icon: Icons.people_outline,
            ),
          ),
          SizedBox(
            width: cardWidth,
            child: AnalyticsMetricCard(
              title: 'Views',
              value: NumberFormat.compact().format(_analyticsData.overview?.total ?? 0),
              change: _analyticsData.pageViewsChange,
              icon: Icons.remove_red_eye_outlined,
            ),
          ),
          SizedBox(
            width: cardWidth,
            child: AnalyticsMetricCard(
              title: 'Bounce',
              value: '${_analyticsData.overview?.bounceRate ?? 0}%',
              change: _analyticsData.bounceRateChange,
              invertChange: true,
              icon: Icons.undo_outlined,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildBreakdownGrid() {
    return Column(
      children: [
        AnalyticsBreakdownCard(
          title: 'Top Pages',
          icon: Icons.description_outlined,
          items: _analyticsData.pages,
          colorPalette: const [
            Color(0xFF7C3AED), // Purple
            Color(0xFF8B5CF6), // Light purple
            Color(0xFFA78BFA), // Lighter purple
            Color(0xFFC4B5FD), // Very light purple
            Color(0xFF6D28D9), // Dark purple
          ],
          onItemTap: (path) {
            final projectUrl = widget.project.allUrls.isNotEmpty
                ? 'https://${widget.project.allUrls.first}'
                : null;
            if (projectUrl != null && path.isNotEmpty) {
              final fullUrl = path.startsWith('/') 
                  ? '$projectUrl$path' 
                  : '$projectUrl/$path';
              launchUrl(Uri.parse(fullUrl), mode: LaunchMode.externalApplication);
            }
          },
        ),
        const SizedBox(height: 24),
        AnalyticsBreakdownCard(
          title: 'Top Referrers',
          icon: Icons.link_outlined,
          items: _analyticsData.referrers,
          emptyLabel: 'No external referrers found',
          colorPalette: const [
            Color(0xFF059669), // Green
            Color(0xFF10B981), // Light green
            Color(0xFF34D399), // Lighter green
            Color(0xFF6EE7B7), // Very light green
            Color(0xFF047857), // Dark green
          ],
        ),
        const SizedBox(height: 24),
        AnalyticsBreakdownCard(
          title: 'Countries',
          icon: Icons.public_outlined,
          items: _analyticsData.countries,
          colorPalette: const [
            Color(0xFFD97706), // Orange
            Color(0xFFF59E0B), // Light orange
            Color(0xFFFBBF24), // Lighter orange
            Color(0xFFFCD34D), // Very light orange
            Color(0xFFB45309), // Dark orange
          ],
        ),
        const SizedBox(height: 24),
        AnalyticsBreakdownCard(
          title: 'Devices',
          icon: Icons.devices_outlined,
          items: _analyticsData.devices,
          colorPalette: const [
            Color(0xFFDB2777), // Pink
            Color(0xFFEC4899), // Light pink
            Color(0xFFF472B6), // Lighter pink
            Color(0xFFFBCFE8), // Very light pink
            Color(0xFFBE185D), // Dark pink
          ],
        ),
        const SizedBox(height: 24),
        AnalyticsBreakdownCard(
          title: 'Browsers',
          icon: Icons.open_in_browser_outlined,
          items: _analyticsData.browsers,
          colorPalette: const [
            Color(0xFF0891B2), // Cyan
            Color(0xFF06B6D4), // Light cyan
            Color(0xFF22D3EE), // Lighter cyan
            Color(0xFF67E8F9), // Very light cyan
            Color(0xFF0E7490), // Dark cyan
          ],
        ),
      ],
    );
  }

  Widget _buildCronJobsTab() {
    final crons = widget.project.crons;
    final hasCrons = crons != null && crons.definitions.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Text('CRON JOBS', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(width: 8),
              if (hasCrons)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: crons!.isEnabled ? AppTheme.success.withOpacity(0.1) : AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    crons.isEnabled ? 'ENABLED' : 'DISABLED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: crons.isEnabled ? AppTheme.success : AppTheme.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasCrons)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Column(
                children: [
                  Icon(Icons.schedule, size: 48, color: AppTheme.onSurfaceVariant.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No Cron Jobs',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This project has no scheduled cron jobs configured.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...crons!.definitions.map((cron) => _buildCronItem(cron)),
                  if (crons.updatedAt != null) ...[
                    const Divider(height: 24),
                    Row(
                      children: [
                        Icon(Icons.update, size: 14, color: AppTheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text(
                          'Updated ${timeago.format(crons.updatedAt!)}',
                          style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCronItem(dynamic cron) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cron.path,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  cron.displaySchedule,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _copyToClipboard(cron.schedule),
                child: Text(
                  cron.schedule,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.language, size: 12, color: AppTheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  cron.host,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () => _launchUrl(cron.fullUrl),
                child: const Icon(
                  Icons.open_in_new,
                  size: 14,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildDeploymentsTab() {
    return RefreshIndicator(
      onRefresh: _fetchData,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('DEPLOYMENTS', style: Theme.of(context).textTheme.labelSmall),
              if (_deployments != null)
                Text(
                  '${_deployments!.length} total',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_deployments == null || _deployments!.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Center(
                child: Text(
                  'No deployments found',
                  style: TextStyle(color: AppTheme.onSurfaceVariant),
                ),
              ),
            )
          else
            ..._deployments!.map((dep) => DeploymentCard(
              deployment: dep,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeploymentLogsScreen(deployment: dep),
                  ),
                );
              },
            )),
        ],
      ),
    );
  }

  // Track expanded folders for lazy loading
  final Set<String> _expandedFolders = {};

  Widget _buildFilesTab() {
    if (_deployments == null || _deployments!.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchData,
        color: AppTheme.primary,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('DEPLOYMENT FILES', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Center(
                child: Text(
                  'No deployments available to view files',
                  style: TextStyle(color: AppTheme.onSurfaceVariant),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Use the latest deployment
    final deployment = _deployments!.first;

    return FutureBuilder<List<DeploymentFile>>(
      future: _deploymentFilesFuture,
      builder: (context, snapshot) {
        print('[ProjectWorkspace] Files FutureBuilder: connectionState=${snapshot.connectionState}, hasData=${snapshot.hasData}, hasError=${snapshot.hasError}, dataLength=${snapshot.data?.length}');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }

        if (snapshot.hasError) {
          final error = snapshot.error.toString();
          final isNotFound = error.contains('File tree not found');
          
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isNotFound ? Icons.info_outline : Icons.error_outline,
                    color: isNotFound ? AppTheme.onSurfaceVariant : AppTheme.error,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isNotFound ? 'File Tree Unavailable' : 'Failed to load files',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isNotFound ? 'File tree not available for this deployment.' : error,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  if (!isNotFound)
                    ElevatedButton(onPressed: () => setState(() {}), child: const Text('Retry')),
                ],
              ),
            ),
          );
        }

        final files = snapshot.data ?? [];
        if (files.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, color: AppTheme.onSurfaceVariant, size: 48),
                SizedBox(height: 16),
                Text('No files found for this deployment'),
              ],
            ),
          );
        }

        // Build file tree with lazy loading support
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index];
            return _buildFileTreeItem(
              file: file,
              deployment: deployment,
              level: 0,
              path: '',
            );
          },
        );
      },
    );
  }

  /// Build a file tree item with recursive children support and lazy loading
  /// Matches the competitor's FileTreeAsset component
  Widget _buildFileTreeItem({
    required DeploymentFile file,
    required Deployment deployment,
    required int level,
    required String path,
  }) {
    final isDir = file.type == 'directory';
    final fullPath = path.isEmpty ? file.name : '$path/${file.name}';
    final indentSize = 20.0 * level;
    final isExpanded = _expandedFolders.contains(fullPath);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File/folder row
        InkWell(
          onTap: () {
            if (isDir) {
              _toggleFolder(file, deployment, fullPath);
            } else if (file.uid != null || file.link != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FileContentScreen(
                    deploymentId: deployment.uid,
                    fileId: file.uid ?? file.link ?? '',
                    fileName: fullPath,
                    fileUrl: file.link,
                  ),
                ),
              );
            }
          },
          child: Container(
            padding: EdgeInsets.only(
              left: 16 + indentSize,
              right: 16,
              top: 8,
              bottom: 8,
            ),
            child: Row(
              children: [
                // Loading indicator or icon
                if (file.isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  )
                else
                  Icon(
                    isDir
                        ? (isExpanded ? Icons.folder_open_outlined : Icons.folder_outlined)
                        : _getFileIcon(file.name),
                    size: 20,
                    color: isDir ? AppTheme.primary : AppTheme.onSurfaceVariant,
                  ),
                const SizedBox(width: 12),
                // File name
                Expanded(
                  child: Text(
                    file.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: isDir ? null : 'monospace',
                      color: AppTheme.onSurface,
                      fontWeight: isDir ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
                if (!isDir)
                  const Icon(Icons.chevron_right, size: 16, color: AppTheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
        
        // Expanded children (lazy loaded)
        if (isDir && isExpanded && file.children != null)
          Column(
            children: file.children!.map((child) {
              return _buildFileTreeItem(
                file: child,
                deployment: deployment,
                level: level + 1,
                path: fullPath,
              );
            }).toList(),
          ),
      ],
    );
  }

  /// Expand/collapse a folder - with lazy loading like competitor
  Future<void> _toggleFolder(DeploymentFile folder, Deployment deployment, String fullPath) async {
    final isExpanded = _expandedFolders.contains(fullPath);
    
    // If expanding and no children loaded yet, fetch them
    if (!isExpanded && (folder.children == null || folder.children!.isEmpty) && !folder.hasLoadedChildren) {
      setState(() {
        folder.isLoading = true;
      });
      
      try {
        final appState = context.read<AppState>();
        final basePath = 'src/$fullPath';
        
        print('[ProjectWorkspace] Lazy loading folder: $basePath');
        
        final children = await appState.apiService.getDeploymentFileTree(
          deploymentUrl: deployment.url,
          base: basePath,
        );
        
        if (mounted) {
          setState(() {
            folder.children = children;
            folder.hasLoadedChildren = true;
            folder.isLoading = false;
            _expandedFolders.add(fullPath);
          });
        }
      } catch (e) {
        print('[ProjectWorkspace] Error loading folder contents: $e');
        if (mounted) {
          setState(() {
            folder.isLoading = false;
          });
        }
      }
    } else {
      // Just toggle expansion
      setState(() {
        if (isExpanded) {
          _expandedFolders.remove(fullPath);
        } else {
          _expandedFolders.add(fullPath);
        }
      });
    }
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'js':
      case 'ts':
      case 'jsx':
      case 'tsx':
        return Icons.code;
      case 'json':
        return Icons.settings_ethernet;
      case 'html':
      case 'css':
        return Icons.web;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'svg':
        return Icons.image;
      case 'md':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildLogsTab() {
    final liveDeployment = _getLatestLiveDeployment();

    return RefreshIndicator(
      onRefresh: _fetchLiveDeploymentLogs,
      color: AppTheme.primary,
      child: Column(
        children: [
          // Header with live deployment info and filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              border: Border(bottom: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.1))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.terminal, size: 16, color: AppTheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text(
                          'RUNTIME LOGS',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    if (liveDeployment != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppTheme.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              liveDeployment.name,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.success,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Filter chips on separate row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildLogFilterChip('All', _logsFilter == 'all', () => setState(() => _logsFilter = 'all')),
                      const SizedBox(width: 8),
                      _buildLogFilterChip('Info', _logsFilter == 'info', () => setState(() => _logsFilter = 'info')),
                      const SizedBox(width: 8),
                      _buildLogFilterChip('Errors', _logsFilter == 'errors', () => setState(() => _logsFilter = 'errors')),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Logs content
          Expanded(
            child: _buildLiveLogsContent(liveDeployment),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveLogsContent(Deployment? liveDeployment) {
    if (liveDeployment == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, color: AppTheme.onSurfaceVariant, size: 48),
            const SizedBox(height: 16),
            const Text(
              'No live deployment found',
              style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Deploy your project to see live logs here.',
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_isLoadingLiveLogs) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_liveLogsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Failed to load logs',
              style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _liveLogsError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchLiveDeploymentLogs,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_liveLogs == null || _liveLogs!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.terminal, color: AppTheme.onSurfaceVariant, size: 48),
            const SizedBox(height: 16),
            Text(
              'No logs available for ${liveDeployment.name}',
              style: const TextStyle(color: AppTheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    // Apply filter to request logs
    List<Log> filteredLogs = _liveLogs!;
    if (_logsFilter == 'errors') {
      filteredLogs = _liveLogs!.where((log) {
        return log.logs.any((l) => l.level.toLowerCase() == 'error') || log.statusCode >= 500;
      }).toList();
    } else if (_logsFilter == 'info') {
      filteredLogs = _liveLogs!.where((log) {
        return log.logs.every((l) => l.level.toLowerCase() != 'error') && log.statusCode < 500;
      }).toList();
    }

    if (filteredLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.filter_list, color: AppTheme.onSurfaceVariant, size: 48),
            const SizedBox(height: 16),
            Text(
              'No ${_logsFilter} logs found',
              style: const TextStyle(color: AppTheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    // Competitor-style request logs list
    return Column(
      children: [
        // Minimal header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.3)),
            ),
          ),
          child: Row(
            children: [
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
        ),
        // Log list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredLogs.length,
            itemBuilder: (context, index) {
              final log = filteredLogs[index];
              return _buildRequestLogRow(log, index % 2 == 0);
            },
          ),
        ),
      ],
    );
  }

  /// Build request log row matching competitor design
  Widget _buildRequestLogRow(Log log, bool isEven) {
    return InkWell(
      onTap: () => _showLogDetailsBottomSheet(log),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isEven ? AppTheme.surfaceContainerLow.withOpacity(0.3) : AppTheme.surface,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timestamp
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
            // Method badge + Path + Status
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
                      log.requestPath.isNotEmpty ? log.requestPath : '/',
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

  /// Show log details in a bottom sheet (like competitor app)
  void _showLogDetailsBottomSheet(Log log) {
    // Check subscription - show paywall if not subscribed
    final subscription = Provider.of<SubscriptionProvider>(context, listen: false);
    if (!subscription.isPro) {
      SuperwallService().trackSubscriptionEvent('paywall_triggered', properties: {
        'trigger': 'log_details_access',
      });
      _showPaywall(context);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.3)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getMethodColor(log.requestMethod).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log.requestMethod,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getMethodColor(log.requestMethod),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          log.requestPath,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        log.statusCode.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Log.getStatusColor(log.statusCode),
                        ),
                      ),
                    ],
                  ),
                ),
                // Scrollable content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      const SizedBox(height: 16),
                      // Info rows
                      _buildBottomSheetInfoRow('Timestamp', Icons.access_time, log.formattedTime),
                      _buildBottomSheetInfoRow('Domain', Icons.language, log.domain),
                      _buildBottomSheetInfoRow('Route', Icons.route, log.route.isNotEmpty ? log.route : 'N/A'),
                      _buildBottomSheetInfoRow('Cache', Icons.save, log.cache.isNotEmpty ? log.cache : 'N/A'),
                      _buildBottomSheetInfoRow('Environment', Icons.cloud, _capitalizeFirst(log.environment)),
                      if (log.memoryUsed != null)
                        _buildBottomSheetInfoRow('Memory', Icons.memory, log.memoryUsed!),
                      if (log.duration != null)
                        _buildBottomSheetInfoRow('Duration', Icons.timer, log.duration!),
                      _buildBottomSheetInfoRow('Region', Icons.map, log.regionLabel ?? log.clientRegion),
                      if (log.clientUserAgent.isNotEmpty)
                        _buildBottomSheetInfoRow('Agent', Icons.person, log.clientUserAgent.length > 40
                            ? '${log.clientUserAgent.substring(0, 40)}...'
                            : log.clientUserAgent),
                      const SizedBox(height: 24),
                      // Console logs section
                      if (log.logs.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.3)),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.terminal, size: 18, color: AppTheme.onSurfaceVariant),
                              const SizedBox(width: 8),
                              Text(
                                'Console Logs (${log.logs.length})',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...log.logs.asMap().entries.map((entry) {
                          final index = entry.key;
                          final logLine = entry.value;
                          return _buildConsoleLogLine(logLine, index);
                        }),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBottomSheetInfoRow(String label, IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.2)),
        ),
      ),
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
            child: Icon(icon, size: 18, color: AppTheme.onSurfaceVariant),
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
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsoleLogLine(LogLine logLine, int index) {
    final hour = logLine.timestamp.hour.toString().padLeft(2, '0');
    final minute = logLine.timestamp.minute.toString().padLeft(2, '0');
    final second = logLine.timestamp.second.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute:$second';

    final level = logLine.level.toLowerCase();
    final levelColor = _getLogLevelColor(level);
    final levelBgColor = levelColor.withOpacity(0.1);
    final levelIcon = _getLogLevelIcon(level);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with level badge and timestamp
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: levelBgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(levelIcon, size: 12, color: levelColor),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: levelColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    level.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: levelColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.onSurfaceVariant.withOpacity(0.7),
                    fontFamily: 'monospace',
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          // Log message
          Container(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              logLine.message,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: _getLogMessageColor(level),
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLogLevelColor(String level) {
    switch (level) {
      case 'error':
        return const Color(0xFFEF4444); // Red
      case 'warn':
      case 'warning':
        return const Color(0xFFF59E0B); // Orange/Yellow
      case 'debug':
        return const Color(0xFF8B5CF6); // Purple
      case 'info':
      default:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  Color _getLogMessageColor(String level) {
    switch (level) {
      case 'error':
        return const Color(0xFFEF4444);
      case 'warn':
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'debug':
        return const Color(0xFFA78BFA);
      case 'info':
      default:
        return AppTheme.onSurface;
    }
  }

  IconData _getLogLevelIcon(String level) {
    switch (level) {
      case 'error':
        return Icons.error_outline;
      case 'warn':
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'debug':
        return Icons.bug_report_outlined;
      case 'info':
      default:
        return Icons.info_outline;
    }
  }

  String _capitalizeFirst(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  Widget _buildLogFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.primary.withOpacity(0.5) : AppTheme.outlineVariant.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTab() {
    return RefreshIndicator(
      onRefresh: _fetchData,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PROJECT ACTIVITY', style: Theme.of(context).textTheme.labelSmall),
              if (_deployments != null)
                Text(
                  '${_deployments!.length} events',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (_deployments == null || _deployments!.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Center(
                child: Text(
                  'No activity found for this project',
                  style: TextStyle(color: AppTheme.onSurfaceVariant),
                ),
              ),
            )
          else
            Column(
              children: List.generate(_deployments!.length, (index) {
                final deployment = _deployments![index];
                final isLast = index == _deployments!.length - 1;
                final createdDate = DateTime.fromMillisecondsSinceEpoch(deployment.created * 1000);
                
                return _buildActivityItem(
                  isLast: isLast,
                  icon: _getIconForState(deployment.state),
                  title: deployment.name,
                  timeAgo: timeago.format(createdDate).toUpperCase(),
                  description: TextSpan(
                    children: [
                      const TextSpan(text: 'Deployment to '),
                      TextSpan(
                        text: deployment.url,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                      TextSpan(text: ' is ${deployment.state.toLowerCase()}.'),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DeploymentLogsScreen(deployment: deployment),
                      ),
                    );
                  },
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required bool isLast,
    required IconData icon,
    required String title,
    required String timeAgo,
    required TextSpan description,
    VoidCallback? onTap,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.1)),
                ),
                child: Icon(icon, size: 20, color: AppTheme.primary),
              ),
              Expanded(
                child: Container(
                  width: 1,
                  color: isLast ? Colors.transparent : AppTheme.surfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32, top: 2),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface, fontSize: 14)),
                        Text(timeAgo, style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.onSurfaceVariant, fontSize: 11, letterSpacing: 1)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14, height: 1.5),
                        children: [description],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForState(String state) {
    switch (state) {
      case 'READY': return Icons.rocket_launch;
      case 'ERROR': return Icons.error_outline;
      case 'BUILDING': return Icons.loop;
      default: return Icons.history;
    }
  }

  Widget _buildSecurityTab() {
    final security = widget.project.security ?? {};
    final firewallEnabled = security['firewallEnabled'] == true;
    final attackMode = security['attackModeEnabled'] == true;
    final ssoEnabled = widget.project.ssoProtection != null;
    final passwordProtected = widget.project.passwordProtection != null;

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('SECURITY SETTINGS', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Column(
              children: [
                _buildSecurityRow(
                  'Firewall',
                  firewallEnabled ? 'Enabled' : 'Disabled',
                  firewallEnabled ? AppTheme.success : AppTheme.onSurfaceVariant,
                  Icons.shield,
                ),
                const Divider(height: 24),
                _buildSecurityRow(
                  'Attack Mode',
                  attackMode ? 'Enabled' : 'Disabled',
                  attackMode ? AppTheme.error : AppTheme.onSurfaceVariant,
                  Icons.gpp_maybe,
                ),
                const Divider(height: 24),
                _buildSecurityRow(
                  'SSO Protection',
                  ssoEnabled ? 'Enabled' : 'Disabled',
                  ssoEnabled ? AppTheme.primary : AppTheme.onSurfaceVariant,
                  Icons.people,
                ),
                const Divider(height: 24),
                _buildSecurityRow(
                  'Password Protection',
                  passwordProtected ? 'Enabled' : 'Disabled',
                  passwordProtected ? AppTheme.error : AppTheme.onSurfaceVariant,
                  Icons.lock,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppTheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      'Security Note',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Security settings can be configured in the Vercel dashboard. Changes may take a few minutes to propagate.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityRow(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 16),
        Expanded(child: Text(label)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEnvVarsTab() {
    return RefreshIndicator(
      onRefresh: _fetchData,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ENVIRONMENT VARIABLES', style: Theme.of(context).textTheme.labelSmall),
              Row(
                children: [
                  if (_envVars != null)
                    Text(
                      '${_envVars!.length} variables',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isEditingEnvVar ? null : () => _showAddEnvVarDialog(),
                    icon: const Icon(Icons.add, size: 16, color: Colors.black),
                    label: const Text('ADD', style: TextStyle(color: Colors.black)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_envVars == null || _envVars!.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Center(
                child: Text(
                  'No environment variables configured',
                  style: TextStyle(color: AppTheme.onSurfaceVariant),
                ),
              ),
            )
          else
            ..._envVars!.map((env) => _buildEnvVarCard(env)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppTheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Secret values are hidden by default. Click the eye icon to reveal. Changes require redeployment to take effect.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvVarCard(dynamic env) {
    final envVar = env is EnvVar ? env : EnvVar.fromJson(env);
    final displayValue = envVar.isSecret ? '••••••••' : (envVar.value ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                envVar.isSecret ? Icons.lock : Icons.key,
                color: envVar.isSecret ? AppTheme.error : AppTheme.onSurfaceVariant,
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  envVar.key,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              if (envVar.isSecret)
                IconButton(
                  icon: const Icon(Icons.visibility, size: 18, color: AppTheme.onSurfaceVariant),
                  onPressed: _isEditingEnvVar ? null : () => _showDecryptedValueDialog(envVar),
                  tooltip: 'Reveal',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: AppTheme.primary),
                onPressed: _isEditingEnvVar ? null : () => _showEditEnvVarDialog(envVar),
                tooltip: 'Edit',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: AppTheme.error),
                onPressed: _isEditingEnvVar ? null : () => _showDeleteEnvVarDialog(envVar),
                tooltip: 'Delete',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayValue.isEmpty ? '(empty)' : displayValue,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: displayValue.isEmpty ? AppTheme.onSurfaceVariant : AppTheme.onSurface,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (!envVar.isSecret && displayValue.isNotEmpty)
                  InkWell(
                    onTap: () => _copyToClipboard(envVar.value ?? ''),
                    child: Icon(
                      Icons.copy,
                      size: 14,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  envVar.target.join(', '),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (envVar.type != 'plain') ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    envVar.type.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showDecryptedValueDialog(EnvVar envVar) async {
    final appState = Provider.of<AppState>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLow,
        content: Row(
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(width: 16),
            Text('Decrypting...'),
          ],
        ),
      ),
    );

    try {
      final decryptedValue = await appState.apiService.getDecryptedEnvVar(widget.project.id, envVar.id);
      if (mounted) {
        Navigator.pop(context);
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surfaceContainerLow,
            title: Text(envVar.key),
            content: SelectableText(
              decryptedValue,
              style: const TextStyle(fontFamily: 'monospace', color: AppTheme.primary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: decryptedValue));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Value copied to clipboard')),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Copy'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to decrypt value: $e')),
        );
      }
    }
  }

  Future<void> _showAddEnvVarDialog() async {
    final keyController = TextEditingController();
    final valueController = TextEditingController();
    String selectedTarget = 'production';
    bool isSecret = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceContainerLow,
          title: const Text('Add Environment Variable'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: keyController,
                  decoration: const InputDecoration(
                    labelText: 'Key',
                    hintText: 'e.g., API_KEY',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: valueController,
                  decoration: const InputDecoration(
                    labelText: 'Value',
                    hintText: 'Enter value',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: isSecret,
                  maxLines: isSecret ? 1 : 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedTarget,
                  decoration: const InputDecoration(
                    labelText: 'Target',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'production', child: Text('Production')),
                    DropdownMenuItem(value: 'preview', child: Text('Preview')),
                    DropdownMenuItem(value: 'development', child: Text('Development')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedTarget = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Secret (encrypted)'),
                  subtitle: const Text('Value will be hidden and encrypted'),
                  value: isSecret,
                  onChanged: (value) {
                    setDialogState(() => isSecret = value ?? false);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                if (keyController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Key is required')),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text('ADD', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() => _isEditingEnvVar = true);
      try {
        final appState = Provider.of<AppState>(context, listen: false);
        await appState.apiService.createEnvVars(
          widget.project.id,
          [{
            'key': keyController.text.trim(),
            'value': valueController.text,
            'target': [selectedTarget],
            'type': isSecret ? 'secret' : 'plain',
          }],
        );
        await _fetchData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Environment variable added')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add: $e')),
          );
        }
      } finally {
        setState(() => _isEditingEnvVar = false);
      }
    }
  }

  Future<void> _showEditEnvVarDialog(EnvVar envVar) async {
    final valueController = TextEditingController(text: envVar.value ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLow,
        title: Text('Edit ${envVar.key}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Key: ${envVar.key}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueController,
                decoration: InputDecoration(
                  labelText: 'Value',
                  hintText: 'Enter new value',
                  border: const OutlineInputBorder(),
                  helperText: envVar.isSecret ? 'Leave empty to keep current value' : null,
                ),
                obscureText: envVar.isSecret,
                maxLines: envVar.isSecret ? 1 : 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Target: ${envVar.target.join(', ')}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              if (envVar.isSecret)
                Text(
                  'Type: ENCRYPTED',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.error,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      setState(() => _isEditingEnvVar = true);
      try {
        final appState = Provider.of<AppState>(context, listen: false);
        final newValue = valueController.text;
        
        // If secret and empty, don't update value
        if (envVar.isSecret && newValue.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No changes made')),
            );
          }
          setState(() => _isEditingEnvVar = false);
          return;
        }

        await appState.apiService.updateEnvVar(
          widget.project.id,
          envVar.id,
          {
            'value': newValue,
            'target': envVar.target,
            'type': envVar.type,
          },
        );
        await _fetchData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Environment variable updated')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update: $e')),
          );
        }
      } finally {
        setState(() => _isEditingEnvVar = false);
      }
    }
  }

  Future<void> _showDeleteEnvVarDialog(EnvVar envVar) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLow,
        title: const Text('Delete Environment Variable'),
        content: Text('Are you sure you want to delete "${envVar.key}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      setState(() => _isEditingEnvVar = true);
      try {
        final appState = Provider.of<AppState>(context, listen: false);
        await appState.apiService.deleteEnvVar(
          widget.project.id,
          envVar.id,
          target: envVar.target.isNotEmpty ? envVar.target.first : null,
        );
        await _fetchData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Environment variable deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      } finally {
        setState(() => _isEditingEnvVar = false);
      }
    }
  }

  Widget _buildDomainsTab() {
    final aliases = widget.project.alias ?? [];

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('PRODUCTION DOMAINS', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 16),
          if (_domains == null || _domains!.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Center(
                child: Text(
                  'No domains configured',
                  style: TextStyle(color: AppTheme.onSurfaceVariant),
                ),
              ),
            )
          else
            ..._domains!.take(5).map((dom) {
              final verified = dom['verified'] == true;
              final redirect = dom['redirect'] as String?;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.language, color: AppTheme.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            dom['name'],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        if (verified)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Text(
                              'VERIFIED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _copyToClipboard(dom['name']),
                          child: const Icon(Icons.content_copy, color: AppTheme.onSurfaceVariant, size: 16),
                        ),
                      ],
                    ),
                    if (redirect != null && redirect.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.arrow_forward, size: 14, color: AppTheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Text(
                            'Redirects to: $redirect',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.onSurfaceVariant,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
          if (aliases.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('ALIASES', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 16),
            ...aliases.take(3).map((alias) {
              final domain = alias is String ? alias : (alias['domain'] as String? ?? '');
              final target = alias is String ? '' : (alias['target'] as String? ?? '');
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.language, size: 18, color: AppTheme.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(child: Text(domain, style: const TextStyle(fontFamily: 'monospace'))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        target,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Copied to clipboard')));
    }
  }
}
