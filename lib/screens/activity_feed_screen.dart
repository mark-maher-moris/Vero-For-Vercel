import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ActivityFeedScreen extends StatelessWidget {
  const ActivityFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLow,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceContainerHigh,
              ),
              child: const Icon(Icons.change_history, size: 20, color: AppTheme.onSurface),
            ),
            const SizedBox(width: 12),
            const Text('Vero', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.onSurfaceVariant),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: AppTheme.onSurfaceVariant),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
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
          
          _buildActivityItem(
            isLast: false,
            icon: Icons.person,
            title: 'Felix Miller',
            timeAgo: '2M AGO',
            description: const TextSpan(
              children: [
                TextSpan(text: 'Deployed to '),
                TextSpan(text: 'production', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                TextSpan(text: ' in '),
                TextSpan(text: 'acme-corp-dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
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
                  const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('acme-corp-db-7x2j1', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                        SizedBox(height: 4),
                        Text('PRODUCTION • MAIN', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: AppTheme.onSurfaceVariant, size: 14),
                ],
              ),
            ),
          ),

          _buildActivityItem(
            isLast: false,
            icon: Icons.merge_type,
            title: 'Sarah Jenkins',
            timeAgo: '14M AGO',
            description: const TextSpan(
              children: [
                TextSpan(text: 'Merged branch '),
                TextSpan(text: 'feature/auth-redesign', style: TextStyle(backgroundColor: AppTheme.surfaceContainerHigh, color: AppTheme.primary, fontFamily: 'monospace')),
                TextSpan(text: ' into '),
                TextSpan(text: 'marketing-site', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 16, color: AppTheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  const Text('REVIEWED BY MARCUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),

          _buildActivityItem(
            isLast: false,
            icon: Icons.language,
            title: 'System',
            timeAgo: '1H AGO',
            description: const TextSpan(
              children: [
                TextSpan(text: 'Domain '),
                TextSpan(text: 'api.acme.com', style: TextStyle(decoration: TextDecoration.underline, color: AppTheme.primary)),
                TextSpan(text: ' verified successfully.'),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  const Text('SSL Certificate Issued', style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppTheme.onSurface)),
                ],
              ),
            ),
          ),

          _buildActivityItem(
            isLast: true,
            icon: Icons.group_add,
            title: 'Alex Rivera',
            timeAgo: '3H AGO',
            description: const TextSpan(
              children: [
                TextSpan(text: 'Joined the '),
                TextSpan(text: 'Engineering', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                TextSpan(text: ' team as '),
                TextSpan(text: 'Contributor', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                TextSpan(text: '.'),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Center(
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.surfaceContainerLow,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: const Text('Load previous activity', style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.bold)),
            ),
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
