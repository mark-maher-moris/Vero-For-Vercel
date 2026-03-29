import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import '../models/project.dart';
import '../models/deployment.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/deployment_card.dart';
import '../widgets/action_card.dart';
import 'deployment_logs_screen.dart';

class ProjectWorkspaceScreen extends StatefulWidget {
  final Project project;

  const ProjectWorkspaceScreen({super.key, required this.project});

  @override
  State<ProjectWorkspaceScreen> createState() => _ProjectWorkspaceScreenState();
}

class _ProjectWorkspaceScreenState extends State<ProjectWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Deployment>? _deployments;
  List<dynamic>? _domains;
  List<dynamic>? _envVars;
  bool _isLoading = true;
  bool _isRedeploying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
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
      final doms = await appState.apiService.getProjectDomains(
        widget.project.id,
      );
      final envs = await appState.apiService.getProjectEnvVars(widget.project.id);

      if (mounted) {
        setState(() {
          _deployments = deps;
          _domains = doms;
          _envVars = envs;
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
    setState(() => _isRedeploying = true);
    try {
      await Future.delayed(const Duration(seconds: 2));
      await _fetchData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Redeployment triggered!')));
      }
    } finally {
      setState(() => _isRedeploying = false);
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
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
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
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.onSurfaceVariant,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Deployments'),
            Tab(text: 'Logs'),
            Tab(text: 'Security'),
            Tab(text: 'Env Vars'),
            Tab(text: 'Domains'),
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
                  _buildLogsTab(),
                  _buildSecurityTab(),
                  _buildEnvVarsTab(),
                  _buildDomainsTab(),
                ],
              ),
    );
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

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildInfoCard(),
        const SizedBox(height: 24),
        _buildQuickActions(),
        const SizedBox(height: 24),
        if (repoUrl != null) _buildGitSection(repoUrl),
        if (repoUrl != null) const SizedBox(height: 24),
        _buildTechnicalStats(),
        const SizedBox(height: 24),
        _buildFeaturesSection(),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(4),
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
                onTap: () => _tabController.animateTo(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ActionCard(
                icon: Icons.settings,
                label: 'Config',
                onTap: () => _tabController.animateTo(4),
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
            borderRadius: BorderRadius.circular(4),
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
                  borderRadius: BorderRadius.circular(4),
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
                  borderRadius: BorderRadius.circular(4),
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
            borderRadius: BorderRadius.circular(4),
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
    return ListView(
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
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: Text(
                'No deployments found',
                style: TextStyle(color: AppTheme.onSurfaceVariant),
              ),
            ),
          )
        else
          ..._deployments!.map((dep) => DeploymentCard(deployment: dep)),
      ],
    );
  }

  Widget _buildLogsTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('DEPLOYMENT LOGS', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 16),
        if (_deployments == null || _deployments!.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(4),
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
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
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
    );
  }

  Widget _buildSecurityTab() {
    final security = widget.project.security ?? {};
    final firewallEnabled = security['firewallEnabled'] == true;
    final attackMode = security['attackModeEnabled'] == true;
    final ssoEnabled = widget.project.ssoProtection != null;
    final passwordProtected = widget.project.passwordProtection != null;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('SECURITY SETTINGS', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(4),
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
            borderRadius: BorderRadius.circular(4),
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
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ENVIRONMENT VARIABLES', style: Theme.of(context).textTheme.labelSmall),
            if (_envVars != null)
              Text(
                '${_envVars!.length} variables',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_envVars == null || _envVars!.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: Text(
                'No environment variables configured',
                style: TextStyle(color: AppTheme.onSurfaceVariant),
              ),
            ),
          )
        else
          ..._envVars!.map((env) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.key, color: AppTheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          env['key'] ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          env['target']?.join(', ') ?? 'All environments',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      '****',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppTheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Environment variables are encrypted and only available at runtime.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDomainsTab() {
    final aliases = widget.project.alias ?? [];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('PRODUCTION DOMAINS', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 16),
        if (_domains == null || _domains!.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(4),
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
                color: AppTheme.surfaceContainerLowest,
                border: const Border(bottom: BorderSide(color: AppTheme.primary, width: 2)),
                borderRadius: BorderRadius.circular(4),
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
                borderRadius: BorderRadius.circular(4),
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
