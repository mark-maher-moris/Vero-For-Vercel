import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import '../models/project.dart';
import '../models/deployment.dart';
import '../providers/app_state.dart';
import '../providers/subscription_provider.dart';
import '../services/superwall_service.dart';
import '../models/deployment_file.dart';
import '../theme/app_theme.dart';
import '../models/env_var.dart';
import '../widgets/action_card.dart';
import '../widgets/deployment_card.dart';
import '../widgets/traffic_globe.dart';
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
  String? _errorMessage;
  late Future<List<DeploymentFile>> _deploymentFilesFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
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
    // Listen to tab changes for analytics
    _tabController.addListener(_onTabChanged);
    _fetchData();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final tabNames = ['overview', 'deployments', 'logs', 'activity', 'security', 'env_vars', 'domains'];
      SuperwallService().trackUserAction('switch_tab', 
        context: 'project_workspace',
        properties: {
          'tab_name': tabNames[_tabController.index],
          'project_id': widget.project.id,
        }
      );
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final appState = Provider.of<AppState>(context, listen: false);
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final deps = await appState.apiService.getDeployments(
        projectId: widget.project.id,
      );
      final doms = await appState.apiService.getProjectDomains(widget.project.id);
      final envs = await appState.apiService.getProjectEnvVars(widget.project.id);
      if (mounted) {
        setState(() {
          _deployments = deps;
          _domains = doms;
          _envVars = envs;
          // Initialize the cached future for deployment files (only for non-Git deployments)
          if (_deployments != null && _deployments!.isNotEmpty && !_deployments!.first.isGit) {
            _deploymentFilesFuture = appState.apiService.getDeploymentFiles(_deployments!.first.uid);
          }
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(!url.startsWith('http') ? 'https://$url' : url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppTheme.success,
                shape: BoxShape.circle,
              ),
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
            final tabNames = ['overview', 'deployments', 'logs', 'activity', 'security', 'env_vars', 'domains'];
            SuperwallService().trackUserAction('tab_tapped', 
              context: 'project_workspace',
              properties: {
                'tab_name': tabNames[index],
                'is_pro_tab': index > 1,
                'is_pro_user': isPro,
              }
            );
            // If free user tries to access pro tabs, show paywall and reset to first tab
            if (!isPro && index > 1) {
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
            const Tab(text: 'DEPLOYMENTS'),
            // const Tab(text: 'FILES'), // HIDDEN temporarily
            _buildProTab('LOGS', isPro),
            _buildProTab('ACTIVITY', isPro),
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
                children: [
                  _buildOverviewTab(),
                  _buildDeploymentsTab(),
                  // _buildBlurredTabIfNeeded(_buildFilesTab(), isPro, context), // HIDDEN temporarily
                  _buildBlurredTabIfNeeded(_buildLogsTab(), isPro, context),
                  _buildBlurredTabIfNeeded(_buildActivityTab(), isPro, context),
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
    final repoUrl =
        widget.project.link != null
            ? 'https://github.com/${widget.project.link!['org']}/${widget.project.link!['repo']}'
            : null;

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 24),
          TrafficGlobe(projectId: widget.project.id),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          if (repoUrl != null) _buildGitSection(repoUrl),
          if (repoUrl != null) const SizedBox(height: 24),
          _buildTechnicalStats(),
          const SizedBox(height: 24),
          _buildFeaturesSection(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('PROJECT', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(width: 8),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'PRODUCTION',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.project.name,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppTheme.primary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Updated ${timeago.format(widget.project.updatedAt)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.fingerprint,
                size: 12,
                color: AppTheme.onSurfaceVariant.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                widget.project.id,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.onSurfaceVariant.withOpacity(0.6),
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _copyToClipboard(widget.project.id),
                child: Icon(
                  Icons.copy,
                  size: 12,
                  color: AppTheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    // Get subscription status
    final subscription = context.watch<SubscriptionProvider>();
    final isPro = subscription.isPro;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('QUICK ACTIONS', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ActionCard(
                icon: Icons.open_in_new,
                label: 'Visit',
                onTap: () {
                  if (_deployments != null && _deployments!.isNotEmpty) {
                    _launchUrl(_deployments!.first.url);
                  } else {
                    _launchUrl('${widget.project.name}.vercel.app');
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ActionCard(
                icon: Icons.terminal,
                label: 'Logs',
                onTap: isPro
                    ? () => _tabController.animateTo(2)
                    : () => _showPaywall(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ActionCard(
                icon: Icons.settings,
                label: 'Config',
                onTap: isPro
                    ? () => _tabController.animateTo(4)
                    : () => _showPaywall(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGitSection(String repoUrl) {
    final link = widget.project.link!;
    final type = link['type'] as String? ?? 'unknown';
    final branch = link['productionBranch'] as String? ?? 'main';
    final repo = link['repo'] as String? ?? '';
    final org = link['org'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('GIT CONFIGURATION', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 16),
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
                  Icon(Icons.code, color: AppTheme.onSurfaceVariant, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$org/$repo',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        Text(
                          type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Production Branch',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        Text(branch, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Provider',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        Text(type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicalStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TECHNICAL DETAILS', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FRAMEWORK', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.code, color: AppTheme.onSurface),
                        const SizedBox(width: 8),
                        Text(
                          widget.project.framework ?? 'Other',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    if (widget.project.nodeVersion != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Node ${widget.project.nodeVersion}',
                        style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('REGION', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 8),
                    Text(
                      widget.project.serverlessFunctionRegion ?? 'Auto-detected',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    final features = <Widget>[];

    if (widget.project.analytics != null && widget.project.analytics!['enabledAt'] != null) {
      features.add(_buildFeatureItem(Icons.analytics, 'Analytics', 'Enabled'));
    }
    if (widget.project.webAnalytics != null && widget.project.webAnalytics!['enabledAt'] != null) {
      features.add(_buildFeatureItem(Icons.speed, 'Web Analytics', 'Enabled'));
    }
    if (widget.project.speedInsights != null && widget.project.speedInsights!['enabledAt'] != null) {
      features.add(_buildFeatureItem(Icons.bolt, 'Speed Insights', 'Enabled'));
    }
    if (widget.project.gitComments?['onPullRequest'] == true ||
        widget.project.gitComments?['onCommit'] == true) {
      features.add(_buildFeatureItem(Icons.comment, 'Git Comments', 'Enabled'));
    }

    if (features.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FEATURES', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Column(children: features),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String name, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(child: Text(name)),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.success,
              fontWeight: FontWeight.bold,
            ),
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

    // For Git-based deployments, show the repo link directly without calling the API
    if (deployment.isGit) {
      final repoUrl = deployment.repositoryUrl;
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.onSurfaceVariant,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'File Tree Unavailable',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The file tree is not available for Git-based deployments via the Vercel API. You can view the source code directly on your Git provider.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.onSurfaceVariant),
                  ),
                  if (repoUrl != null) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _launchUrl(repoUrl),
                      icon: const Icon(Icons.open_in_new),
                      label: Text('View on ${deployment.providerName ?? 'Git'}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<DeploymentFile>>(
      future: _deploymentFilesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }

        if (snapshot.hasError) {
          final error = snapshot.error.toString();
          final isNotFound = error.contains('File tree not found');
          final isGitDeployment = deployment.isGit;
          final repoUrl = deployment.repositoryUrl;
          
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
                    isNotFound 
                      ? (isGitDeployment 
                          ? 'The file tree is not available for Git-based deployments via the Vercel API. You can view the source code directly on your Git provider.'
                          : 'The file tree is not available for this deployment. This can happen for older deployments or those created via certain integrations.')
                      : error,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  if (isNotFound && isGitDeployment && repoUrl != null)
                    ElevatedButton.icon(
                      onPressed: () => launchUrl(Uri.parse(repoUrl)),
                      icon: const Icon(Icons.open_in_new, size: 16, color: Colors.black),
                      label: Text('VIEW ON ${deployment.providerName?.toUpperCase() ?? 'GIT'}', style: const TextStyle(color: Colors.black)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    )
                  else if (!isNotFound)
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

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: files.length,
          separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, index) {
            final file = files[index];
            final isDir = file.type == 'directory';
            
            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDir ? AppTheme.primary.withOpacity(0.1) : AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isDir ? Icons.folder : _getFileIcon(file.name),
                  color: isDir ? AppTheme.primary : AppTheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              title: Text(
                file.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              subtitle: file.mode != null 
                ? Text('Mode: ${file.mode}', style: const TextStyle(fontSize: 12))
                : null,
              trailing: const Icon(Icons.chevron_right, size: 16, color: AppTheme.onSurfaceVariant),
              onTap: () {
                if (!isDir && file.uid != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FileContentScreen(
                        deploymentId: deployment.uid,
                        fileId: file.uid!,
                        fileName: file.name,
                      ),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
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
    return RefreshIndicator(
      onRefresh: _fetchData,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('DEPLOYMENT LOGS', style: Theme.of(context).textTheme.labelSmall),
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
                  'No deployments to show logs for',
                  style: TextStyle(color: AppTheme.onSurfaceVariant),
                ),
              ),
            )
          else
            ..._deployments!.take(5).map((dep) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: dep.state == 'READY' ? AppTheme.success : AppTheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dep.url,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            timeago.format(DateTime.fromMillisecondsSinceEpoch(dep.created * 1000)),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DeploymentLogsScreen(deployment: dep),
                          ),
                        );
                      },
                      child: const Text('VIEW LOGS'),
                    ),
                  ],
                ),
              );
            }),
        ],
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
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
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
                    InkWell(
                      onTap: () => _copyToClipboard(dom['name']),
                      child: const Icon(Icons.content_copy, color: AppTheme.onSurfaceVariant, size: 16),
                    ),
                  ],
                ),
              );
            }),
          if (aliases.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('ALIASES', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 16),
            ...aliases.take(3).map((alias) {
              final domain = alias['domain'] as String? ?? '';
              final target = alias['target'] as String? ?? '';
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
