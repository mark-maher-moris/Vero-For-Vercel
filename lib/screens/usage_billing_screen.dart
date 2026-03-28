import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';
import '../widgets/project_selector_appbar.dart';

class UsageBillingScreen extends StatefulWidget {
  const UsageBillingScreen({super.key});

  @override
  State<UsageBillingScreen> createState() => _UsageBillingScreenState();
}

class _UsageBillingScreenState extends State<UsageBillingScreen> {
  Map<String, dynamic>? _billingData;
  bool _isLoadingBilling = false;

  @override
  void initState() {
    super.initState();
    _fetchBillingData();
  }

  Future<void> _fetchBillingData() async {
    final appState = Provider.of<AppState>(context, listen: false);
    if (!appState.isAuthenticated) return;
    
    setState(() => _isLoadingBilling = true);
    try {
      final billing = await appState.apiService.getBilling();
      if (mounted) {
        setState(() {
          _billingData = billing;
          _isLoadingBilling = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingBilling = false);
    }
  }

  List<Map<String, dynamic>> _getBillingItems() {
    if (_billingData == null) return [];
    
    final items = <Map<String, dynamic>>[];
    final breakdown = _billingData?['breakdown'] as List<dynamic>?;
    
    if (breakdown != null) {
      for (final item in breakdown) {
        items.add({
          'title': item['name'] ?? 'Unknown',
          'usage': _formatUsage(item['usage'], item['unit']),
          'cost': '\$${(item['cost'] ?? 0).toStringAsFixed(2)}',
          'icon': _getIconForItem(item['name']?.toString() ?? ''),
        });
      }
    }
    
    return items.isNotEmpty ? items : _getDefaultBillingItems();
  }

  List<Map<String, dynamic>> _getDefaultBillingItems() {
    return [
      {'title': 'Edge Middleware', 'usage': 'Calculating...', 'cost': '-', 'icon': Icons.bolt},
      {'title': 'Artifacts Storage', 'usage': 'Calculating...', 'cost': '-', 'icon': Icons.storage},
      {'title': 'Team Seats', 'usage': 'Calculating...', 'cost': '-', 'icon': Icons.group},
    ];
  }

  String _formatUsage(dynamic usage, String? unit) {
    if (usage == null) return '-';
    final value = usage is num ? usage : 0;
    if (unit == 'GB') return '${value.toStringAsFixed(1)} GB';
    if (unit == 'requests') return '${(value / 1000).toStringAsFixed(0)}K units';
    if (unit == 'seats') return '${value.toInt()} Seats';
    return '${value.toStringAsFixed(1)} ${unit ?? 'units'}';
  }

  IconData _getIconForItem(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('middleware') || lower.contains('edge')) return Icons.bolt;
    if (lower.contains('storage') || lower.contains('artifact')) return Icons.storage;
    if (lower.contains('team') || lower.contains('seat')) return Icons.group;
    if (lower.contains('bandwidth')) return Icons.network_check;
    if (lower.contains('function')) return Icons.code;
    return Icons.receipt;
  }

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
            const Text(
              'Cost Breakdown',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
            const SizedBox(height: 24),
            if (_isLoadingBilling)
              const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            else
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: _buildBillingRows(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBillingRows() {
    final items = _getBillingItems();
    if (items.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(24),
          child: Text('No billing data available', style: TextStyle(color: AppTheme.onSurfaceVariant)),
        ),
      ];
    }
    
    final rows = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      rows.add(_buildTableRow(
        item['title'] as String,
        item['usage'] as String,
        item['cost'] as String,
        item['icon'] as IconData,
      ));
      if (i < items.length - 1) {
        rows.add(const Divider(color: AppTheme.outlineVariant, height: 1, thickness: 0.1));
      }
    }
    return rows;
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
