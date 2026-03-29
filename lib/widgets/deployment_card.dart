import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import '../models/deployment.dart';
import '../theme/app_theme.dart';
import '../screens/deployment_logs_screen.dart';

class DeploymentCard extends StatelessWidget {
  final Deployment deployment;
  final VoidCallback? onLogsTap;
  final VoidCallback? onTap;

  const DeploymentCard({
    super.key,
    required this.deployment,
    this.onLogsTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isError = deployment.state == 'ERROR';
    bool isProduction = deployment.target == 'production';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(2),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(2),
          border: isError 
            ? const Border(left: BorderSide(color: AppTheme.error, width: 2)) 
            : isProduction 
              ? const Border(left: BorderSide(color: AppTheme.primary, width: 2))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final uri = Uri.parse(!deployment.url.startsWith('http') ? 'https://${deployment.url}' : deployment.url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          child: Text(
                            deployment.url,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isError ? AppTheme.error : AppTheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (isProduction)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PROD',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.account_tree, 
                        size: 12, 
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        deployment.branch,
                        style: TextStyle(
                          fontSize: 11, 
                          fontFamily: 'monospace', 
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.9),
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(
                          fontSize: 11, 
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      Text(
                        timeago.format(DateTime.fromMillisecondsSinceEpoch(deployment.created)),
                        style: TextStyle(
                          fontSize: 11, 
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                      if (deployment.formattedDuration.isNotEmpty) ...[
                        Text(
                          ' • ',
                          style: TextStyle(
                            fontSize: 11, 
                            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        Icon(
                          Icons.timer,
                          size: 10,
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          deployment.formattedDuration,
                          style: TextStyle(
                            fontSize: 11, 
                            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (deployment.deployerName != 'unknown') ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 10,
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'by ${deployment.deployerName}',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (deployment.commitMessage.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      deployment.commitMessage,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (isError && deployment.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 14, color: AppTheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              deployment.errorMessage!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.error,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isError ? AppTheme.errorContainer : AppTheme.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: isError ? null : Border.all(color: AppTheme.success.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    deployment.state.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: isError ? AppTheme.error : AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onLogsTap ?? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DeploymentLogsScreen(deployment: deployment),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Logs', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
