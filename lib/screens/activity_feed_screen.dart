import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/deployment.dart';
import '../models/project.dart';
import '../providers/app_state.dart';
import '../widgets/project_selector_appbar.dart';
import '../services/superwall_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({super.key});

  @override
  State<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen> {
  Project? _currentProject;
  String? _currentTeamId;
  Future<List<Deployment>>? _deploymentsFuture;

  @override
  void initState() {
    super.initState();
    // Track activity screen view and trigger paywall
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SuperwallService().trackScreenView('activity_feed');
      SuperwallService().registerPlacement('activity_view');
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final project = appState.selectedProject;
    final teamId = appState.currentTeamId;

    if (project != _currentProject || teamId != _currentTeamId) {
      _currentProject = project;
      _currentTeamId = teamId;
      _deploymentsFuture = appState.apiService.getDeployments(projectId: project?.id);
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: const ProjectSelectorAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _deploymentsFuture = appState.apiService.getDeployments(projectId: project?.id);
          });
          await _deploymentsFuture;
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
          children: [
            const Text(
              'Activity',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: AppTheme.primary,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Real-time developer events across your ecosystem.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 48),
            
            FutureBuilder<List<Deployment>>(
              future: _deploymentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}', 
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.error)
                        ),
                      ],
                    )
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No recent activity found.', style: TextStyle(color: AppTheme.onSurfaceVariant)));
                }

                final deployments = snapshot.data!;
                return Column(
                  children: List.generate(deployments.length, (index) {
                    final deployment = deployments[index];
                    final isLast = index == deployments.length - 1;
                    final createdDate = DateTime.fromMillisecondsSinceEpoch(deployment.created);
                    
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
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                final uri = Uri.parse(!deployment.url.startsWith('http') ? 'https://${deployment.url}' : deployment.url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                          ),
                          TextSpan(text: ' is ${deployment.state.toLowerCase()}.'),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getStatusIcon(deployment.state),
                              color: _getStatusColor(deployment.state),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    deployment.uid,
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    deployment.state.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppTheme.onSurfaceVariant,
                                      fontSize: 10,
                                      letterSpacing: 1,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: AppTheme.onSurfaceVariant, size: 14),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              },
            ),

            const SizedBox(height: 32),
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _deploymentsFuture = appState.apiService.getDeployments(projectId: project?.id);
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.surfaceContainerLow,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                ),
                child: const Text('Refresh activity', style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
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

  IconData _getStatusIcon(String state) {
    switch (state) {
      case 'READY': return Icons.check_circle;
      case 'ERROR': return Icons.cancel;
      case 'BUILDING': return Icons.pending;
      default: return Icons.help_outline;
    }
  }

  Color _getStatusColor(String state) {
    switch (state) {
      case 'READY': return AppTheme.success;
      case 'ERROR': return AppTheme.error;
      case 'BUILDING': return Colors.orange;
      default: return AppTheme.onSurfaceVariant;
    }
  }

  Widget _buildActivityItem({
    required bool isLast,
    required IconData icon,
    required String title,
    required String timeAgo,
    required TextSpan description,
    Widget? child,
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
                  border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.1)),
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
              padding: const EdgeInsets.only(bottom: 48, top: 2),
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
                  if (child != null) child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
