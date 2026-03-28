import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/project.dart';
import '../theme/app_theme.dart';
import '../screens/project_details_screen.dart';

class ProjectCard extends StatelessWidget {
  final Project project;

  const ProjectCard({super.key, required this.project});

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
            builder: (context) => ProjectDetailsScreen(project: project),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(4),
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
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusStr.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Icon(Icons.code, size: 20, color: AppTheme.primary),
                ),
              ],
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_tree, size: 18, color: AppTheme.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Text('main', style: Theme.of(context).textTheme.bodyMedium),
                      const Spacer(),
                      Text(
                        timeago.format(project.updatedAt, locale: 'en_short'),
                        style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'https://\${project.name}.vercel.app',
                      style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                    ),
                    const Icon(Icons.open_in_new, size: 16, color: AppTheme.onSurfaceVariant),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
