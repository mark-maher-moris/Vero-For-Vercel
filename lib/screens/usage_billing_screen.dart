import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';
import '../widgets/project_selector_appbar.dart';

class UsageBillingScreen extends StatelessWidget {
  const UsageBillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    
    if (appState.errorMessage != null) {
      return Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: const ProjectSelectorAppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                const SizedBox(height: 16),
                const Text('Failed to load billing info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Text(appState.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.onSurfaceVariant)),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: appState.fetchInitialData, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final user = appState.user?['user'];
    final billing = user?['billing'];
    final plan = billing?['plan']?.toUpperCase() ?? 'FREE';
    final projects = appState.projects;
    final email = user?['email'] ?? '';

    String accountName = 'Personal Account';
    if (appState.currentTeamId != null) {
      final team = appState.teams.firstWhere(
        (t) => t['id'] == appState.currentTeamId,
        orElse: () => {'name': 'Team'},
      );
      accountName = team['name'] ?? 'Team';
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: const ProjectSelectorAppBar(),
      body: RefreshIndicator(
        onRefresh: appState.fetchInitialData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
          children: [
            const Text(
              'USAGE OVERVIEW',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5),
            ),
            const SizedBox(height: 8),
            Text(
              accountName,
              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: -1.5),
            ),
            const SizedBox(height: 24),

            // Current Plan
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CURRENT PLAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$plan Plan', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2)),
                        child: const Text('ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.surface)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppTheme.surfaceContainerHigh),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Account: ${appState.currentTeamId != null ? accountName : (user?['username'] ?? 'Unknown')}', style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                      Text('${projects.length} PROJECTS', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // Projects count
            _buildMetricCard(
              title: 'ACTIVE PROJECTS',
              primaryValue: '${projects.length}',
              unit: '',
              limitText: 'Varies by plan',
              progress: projects.length / 50.0 > 1.0 ? 1.0 : projects.length / 50.0,
            ),

            const SizedBox(height: 16),
            // Billing Contact
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('BILLING CONTACT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Text(
                    email.isNotEmpty ? email : 'No billing email set',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.primary, letterSpacing: -0.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Cost Breakdown',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                const Text('DOWNLOAD CSV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5)),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  _buildTableRow('Edge Middleware', '1,204,500 units', '\$0.00', Icons.bolt),
                  const Divider(color: AppTheme.outlineVariant, height: 1, thickness: 0.1),
                  _buildTableRow('Artifacts Storage', '42.1 GB', '\$4.21', Icons.storage),
                  const Divider(color: AppTheme.outlineVariant, height: 1, thickness: 0.1),
                  _buildTableRow('Team Seats', '2 Seats', '\$40.00', Icons.group),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({required String title, required String primaryValue, required String unit, required String limitText, required double progress}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(text: primaryValue, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: -1)),
                          if (unit.isNotEmpty) TextSpan(text: ' $unit', style: const TextStyle(fontSize: 20, color: AppTheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(limitText, style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Container(
                    width: 120,
                    height: 4,
                    decoration: BoxDecoration(color: AppTheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(2)),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(String title, String usage, String cost, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.primary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(usage, style: const TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant)),
          const SizedBox(width: 24),
          SizedBox(
            width: 60,
            child: Text(cost, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary, fontFamily: 'monospace'), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
