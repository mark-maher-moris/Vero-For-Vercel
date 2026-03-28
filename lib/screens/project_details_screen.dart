import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'deployment_logs_screen.dart';
import '../models/project.dart';
import '../models/deployment.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/deployment_card.dart';
import '../widgets/action_card.dart';
import 'settings_env_vars_screen.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailsScreen({super.key, required this.project});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  final VercelApi _api = VercelApi();
  List<Deployment>? _deployments;
  List<dynamic>? _domains;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final deps = await _api.getDeployments(projectId: widget.project.id);
      final doms = await _api.getProjectDomains(widget.project.id);
      if (mounted) {
        setState(() {
          _deployments = deps;
          _domains = doms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(!url.startsWith('http') ? 'https://\$url' : url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.project.name, style: Theme.of(context).textTheme.titleSmall),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          _buildHeroSection(),
          _buildPrimaryActions(),
          _buildDomainSection(),
          _buildDeploymentHistory(),
          _buildTechnicalStats(),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('PROJECT', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(width: 8),
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('PRODUCTION', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(widget.project.name, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: -1.5)),
          const SizedBox(height: 8),
          Text('Updated \${timeago.format(widget.project.updatedAt)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildPrimaryActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [AppTheme.primary, AppTheme.secondaryFixedDim]),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {}, // Redeploy logic not implemented yet
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.refresh, color: AppTheme.onPrimary, size: 20),
                      const SizedBox(width: 8),
                      Text('Redeploy', style: const TextStyle(color: AppTheme.onPrimary, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ActionCard(
                  icon: Icons.open_in_new,
                  label: 'Visit',
                  onTap: () {
                    if (_deployments != null && _deployments!.isNotEmpty) {
                      _launchUrl(_deployments!.first.url);
                    } else if (widget.project.name.isNotEmpty) {
                      _launchUrl('\${widget.project.name}.vercel.app');
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: ActionCard(icon: Icons.terminal, label: 'Logs', onTap: () {
                if (_deployments != null && _deployments!.isNotEmpty) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => DeploymentLogsScreen(deployment: _deployments!.first)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No deployments to show logs for.')));
                }
              })),
              const SizedBox(width: 12),
              Expanded(child: ActionCard(icon: Icons.settings, label: 'Config', onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsEnvVarsScreen(project: widget.project)));
              })),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDomainSection() {
    if (_isLoading) return const SizedBox.shrink();
    if (_domains == null || _domains!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PRODUCTION DOMAIN', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 16),
            const Text('No domains configured', style: TextStyle(color: AppTheme.onSurfaceVariant)),
          ],
        ),
      );
    }
    
    // Show up to 3 domains
    final domainsToShow = _domains!.take(3).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DOMAINS', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 16),
          ...domainsToShow.map((dom) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                border: const Border(bottom: BorderSide(color: AppTheme.primary, width: 2)),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language, color: AppTheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(dom['name'], style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  ),
                  const Icon(Icons.content_copy, color: AppTheme.onSurfaceVariant, size: 16),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDeploymentHistory() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('DEPLOYMENT HISTORY', style: Theme.of(context).textTheme.labelSmall),
              Text('VIEW ALL', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          else if (_deployments == null || _deployments!.isEmpty)
            Text('No deployments found.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant))
          else
            ..._deployments!.take(3).map((dep) => DeploymentCard(deployment: dep)),
        ],
      ),
    );
  }


  Widget _buildTechnicalStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
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
                      Text(widget.project.framework ?? 'Other', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('REGION', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.public, color: AppTheme.onSurface),
                      const SizedBox(width: 8),
                      const Text('IAD1', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

