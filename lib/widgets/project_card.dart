import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/project.dart';
import '../theme/app_theme.dart';
import '../screens/project_workspace_screen.dart';

class ProjectCard extends StatelessWidget {
  final Project project;

  const ProjectCard({super.key, required this.project});

  String get _frameworkIcon {
    switch (project.framework?.toLowerCase()) {
      case 'nextjs':
        return '▲';
      case 'astro':
        return '🚀';
      case 'remix':
      case 'react-router':
        return '⚛';
      case 'svelte':
      case 'sveltekit':
        return '🔥';
      case 'vue':
      case 'nuxtjs':
        return '🟢';
      case 'angular':
        return '🅰';
      case 'gatsby':
        return 'G';
      case 'hugo':
        return 'H';
      case 'jekyll':
        return '📄';
      case 'express':
      case 'fastify':
      case 'nestjs':
      case 'koa':
        return '🟢';
      default:
        return '⚡';
    }
  }

  String get _branchName {
    if (project.link != null && project.link!['productionBranch'] != null) {
      return project.link!['productionBranch'] as String;
    }
    if (project.latestDeployments != null && project.latestDeployments!.isNotEmpty) {
      final target = project.latestDeployments!.first['target'] as String?;
      if (target != null) return target;
    }
    return 'main';
  }

  List<Widget> _buildStatusIndicators() {
    final indicators = <Widget>[];
    
    if (project.analytics != null && project.analytics!['enabledAt'] != null) {
      indicators.add(_buildIndicator(Icons.analytics, 'Analytics', AppTheme.primary));
    }
    if (project.webAnalytics != null && project.webAnalytics!['enabledAt'] != null) {
      indicators.add(_buildIndicator(Icons.speed, 'Web Analytics', AppTheme.primary));
    }
    if (project.passwordProtection != null) {
      indicators.add(_buildIndicator(Icons.lock, 'Protected', AppTheme.error));
    }
    if (project.security?['firewallEnabled'] == true) {
      indicators.add(_buildIndicator(Icons.shield, 'Firewall', AppTheme.success));
    }
    
    return indicators.isEmpty 
        ? [const SizedBox.shrink()] 
        : indicators;
  }

  Widget _buildIndicator(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: label,
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  List<Widget> _buildUrlRows() {
    final urls = project.allUrls;
    if (urls.isEmpty) {
      return [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${project.name}.vercel.app',
                style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.open_in_new, size: 16, color: AppTheme.onSurfaceVariant),
          ],
        ),
      ];
    }

    return urls.map((url) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                url,
                style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.open_in_new, size: 16, color: AppTheme.onSurfaceVariant),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    bool isSuccess = true;
    String statusStr = 'Production';
    
    if (project.latestDeployments != null && project.latestDeployments!.isNotEmpty) {
      final latest = project.latestDeployments!.first;
      if (latest['readyState'] == 'ERROR') {
        isSuccess = false;
        statusStr = 'Failed';
      } else if (latest['readyState'] == 'BUILDING') {
        statusStr = 'Building...';
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectWorkspaceScreen(project: project),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isSuccess ? AppTheme.success : AppTheme.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            project.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            statusStr.toUpperCase(),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(width: 8),
                          ..._buildStatusIndicators(),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      _frameworkIcon,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_tree, size: 18, color: AppTheme.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Text(_branchName, style: Theme.of(context).textTheme.bodyMedium),
                        const Spacer(),
                        Text(
                          timeago.format(project.updatedAt, locale: 'en_short'),
                          style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildUrlRows(),
                  ),
                ],
              ),
            ],
          ),
        ),
    );
  }
}
