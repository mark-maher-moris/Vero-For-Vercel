import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import '../models/project.dart';
import '../theme/app_theme.dart';
import '../screens/project_workspace_screen.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final bool isBlurred;
  final VoidCallback? onSubscribeTap;
  final VoidCallback? onProjectTap;

  const ProjectCard({
    super.key,
    required this.project,
    this.isBlurred = false,
    this.onSubscribeTap,
    this.onProjectTap,
  });

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
      final defaultUrl = '${project.name}.vercel.app';
      return [
        InkWell(
          onTap: () async {
            final uri = Uri.parse('https://$defaultUrl');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  defaultUrl,
                  style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.open_in_new, size: 16, color: AppTheme.onSurfaceVariant),
            ],
          ),
        ),
      ];
    }

    return urls.map((url) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: () async {
            final uri = Uri.parse(!url.startsWith('http') ? 'https://$url' : url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
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

    Widget cardContent = GestureDetector(
      onTap: isBlurred
          ? onSubscribeTap
          : () {
              onProjectTap?.call();
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
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
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
              const SizedBox(height: 16),
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
      ),
    );

    if (isBlurred) {
      return Stack(
        children: [
          cardContent,
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock,
                          color: AppTheme.primary,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Pro Feature',
                          style: TextStyle(
                            color: AppTheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Upgrade to access more projects',
                          style: TextStyle(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: onSubscribeTap,
                          icon: const Icon(Icons.star, size: 16),
                          label: const Text('Upgrade to Pro'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
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

    return cardContent;
  }
}
