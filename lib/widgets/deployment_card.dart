import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/deployment.dart';
import '../theme/app_theme.dart';
import '../screens/deployment_logs_screen.dart';

class DeploymentCard extends StatelessWidget {
  final Deployment deployment;
  final VoidCallback? onLogsTap;

  const DeploymentCard({
    super.key,
    required this.deployment,
    this.onLogsTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isError = deployment.state == 'ERROR';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(2),
        border: isError ? const Border(left: BorderSide(color: AppTheme.error, width: 2)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deployment.url,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isError ? AppTheme.error : AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.account_tree, size: 12, color: AppTheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    const Text('main • ', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppTheme.onSurfaceVariant)),
                    Text(
                      timeago.format(DateTime.fromMillisecondsSinceEpoch(deployment.created)),
                      style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isError ? AppTheme.errorContainer : AppTheme.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: isError ? null : Border.all(color: AppTheme.success.withValues(alpha: 0.4)),
            ),
            child: Row(
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
    );
  }
}
