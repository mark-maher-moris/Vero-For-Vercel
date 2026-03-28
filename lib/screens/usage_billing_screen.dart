import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UsageBillingScreen extends StatelessWidget {
  const UsageBillingScreen({super.key});

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
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Vero', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
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
            'USAGE OVERVIEW',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          const Text(
            'Usage & Billing',
            style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: -1.5),
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
                    const Text('Pro Team', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Next bill: Oct 24, 2023', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                    Text('\$20.00', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          // Bandwidth
          _buildMetricCard(
            title: 'BANDWIDTH',
            primaryValue: '842.12',
            unit: 'GB',
            limitText: 'Limit: 1 TB',
            progress: 0.84,
          ),

          const SizedBox(height: 16),
          // Total Requests
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TOTAL REQUESTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5)),
                const SizedBox(height: 4),
                const Text('14.8M', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: -1)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.trending_up, color: AppTheme.primary, size: 16),
                    const SizedBox(width: 8),
                    const Text('+12.3%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    const Spacer(),
                    const Text('vs last month', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          // Edge Functions
          _buildMetricCard(
            title: 'EDGE FUNCTION EXECUTIONS',
            primaryValue: '2.4M',
            unit: '',
            limitText: '/ 5M base',
            progress: 0.48,
          ),

          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cost Breakdown', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(text: primaryValue, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: -1)),
                        if (unit.isNotEmpty) TextSpan(text: ' \$unit', style: const TextStyle(fontSize: 20, color: AppTheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
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
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.primary)),
          const Spacer(),
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
