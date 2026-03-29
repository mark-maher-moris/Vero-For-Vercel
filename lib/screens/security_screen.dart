import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../models/security.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> with SingleTickerProviderStateMixin {
  Project? _selectedProject;
  AttackModeStatus? _attackModeStatus;
  FirewallConfig? _firewallConfig;
  List<ManagedRuleset>? _managedRulesets;
  bool _isLoading = false;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSecurityData() async {
    if (_selectedProject == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = Provider.of<AppState>(context, listen: false).apiService;

      final results = await Future.wait([
        api.getAttackModeStatus(_selectedProject!.id),
        api.getFirewallConfig(_selectedProject!.id),
        api.getManagedRulesets(_selectedProject!.id),
      ]);

      if (mounted) {
        setState(() {
          _attackModeStatus = results[0] as AttackModeStatus;
          _firewallConfig = results[1] as FirewallConfig;
          _managedRulesets = results[2] as List<ManagedRuleset>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleAttackMode(bool enabled) async {
    if (_selectedProject == null) return;

    setState(() => _isLoading = true);

    try {
      final api = Provider.of<AppState>(context, listen: false).apiService;

      final activeUntil = enabled
          ? DateTime.now().add(const Duration(hours: 24))
          : null;

      final status = await api.updateAttackMode(
        projectId: _selectedProject!.id,
        enabled: enabled,
        activeUntil: activeUntil,
      );

      if (mounted) {
        setState(() {
          _attackModeStatus = status;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled
                  ? 'Attack Mode enabled for 24 hours'
                  : 'Attack Mode disabled',
            ),
            backgroundColor: enabled ? Colors.orange : AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update Attack Mode: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showProjectPicker(List<Project> projects) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerLow,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select Project',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    final isSelected = _selectedProject?.id == project.id;

                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Icon(
                          _getFrameworkIcon(project.framework),
                          color: AppTheme.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(project.name),
                      subtitle: Text(
                        _selectedProject!.latestDeployments?.isNotEmpty == true
                            ? _selectedProject!.latestDeployments!.first['url'] ?? 'No deployments'
                            : 'No deployments',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: AppTheme.primary)
                          : null,
                      onTap: () {
                        setState(() => _selectedProject = project);
                        Navigator.pop(context);
                        _loadSecurityData();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getFrameworkIcon(String? framework) {
    switch (framework?.toLowerCase()) {
      case 'nextjs':
      case 'next.js':
        return Icons.auto_awesome;
      case 'react':
        return Icons.code;
      case 'vue':
      case 'nuxt':
      case 'nuxtjs':
        return Icons.view_agenda;
      case 'angular':
        return Icons.web;
      case 'svelte':
      case 'sveltekit':
        return Icons.animation;
      default:
        return Icons.folder_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final projects = appState.projects;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLow,
        elevation: 0,
        title: const Text(
          'Security',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          if (projects.isNotEmpty)
            TextButton.icon(
              onPressed: () => _showProjectPicker(projects),
              icon: const Icon(Icons.folder_outlined, size: 18),
              label: Text(
                _selectedProject?.name ?? 'Select Project',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
        ],
        bottom: _selectedProject != null
            ? TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primary,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.onSurfaceVariant,
                tabs: const [
                  Tab(icon: Icon(Icons.shield_outlined), text: 'Overview'),
                  Tab(icon: Icon(Icons.security_outlined), text: 'Firewall'),
                  Tab(icon: Icon(Icons.rule_outlined), text: 'WAF Rules'),
                ],
              )
            : null,
      ),
      body: _selectedProject == null
          ? _buildEmptyState(projects)
          : _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
              : _error != null
                  ? _buildErrorState()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(),
                        _buildFirewallTab(),
                        _buildWafTab(),
                      ],
                    ),
    );
  }

  Widget _buildEmptyState(List<Project> projects) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.security_outlined,
                size: 40,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              projects.isEmpty ? 'No Projects Available' : 'Select a Project',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              projects.isEmpty
                  ? 'Create a project first to manage security settings'
                  : 'Choose a project to configure security settings',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.onSurfaceVariant.withOpacity(0.7)),
            ),
            const SizedBox(height: 24),
            if (projects.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () => _showProjectPicker(projects),
                icon: const Icon(Icons.folder_outlined),
                label: const Text('Select Project'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Failed to load security data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadSecurityData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadSecurityData,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildAttackModeCard(),
          const SizedBox(height: 24),
          _buildSecurityStatsCard(),
          const SizedBox(height: 24),
          _buildQuickActionsCard(),
        ],
      ),
    );
  }

  Widget _buildAttackModeCard() {
    final isEnabled = _attackModeStatus?.enabled ?? false;
    final isActive = _attackModeStatus?.activeUntil?.isAfter(DateTime.now()) ?? false;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isEnabled
              ? [Colors.orange.withOpacity(0.1), Colors.red.withOpacity(0.05)]
              : [AppTheme.surfaceContainerHigh, AppTheme.surfaceContainerLow],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEnabled ? Colors.orange.withOpacity(0.1) : AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Icon(
                  isEnabled ? Icons.warning_amber_rounded : Icons.shield_outlined,
                  color: isEnabled ? Colors.orange : AppTheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attack Challenge Mode',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEnabled
                          ? isActive
                              ? 'Active until ${_formatDate(_attackModeStatus!.activeUntil!)}'
                              : 'Enabled but expired'
                          : 'Disabled - visitors can access normally',
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isEnabled,
                onChanged: _toggleAttackMode,
                activeColor: Colors.orange,
              ),
            ],
          ),
          if (isEnabled) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All visitors will see a challenge page before accessing your site',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSecurityStatsCard() {
    final ruleCount = _firewallConfig?.rules.length ?? 0;
    final blockedIps = _firewallConfig?.ips.length ?? 0;
    final managedRules = _managedRulesets?.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROTECTION STATUS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatItem(
                icon: Icons.rule_outlined,
                value: ruleCount.toString(),
                label: 'Custom Rules',
                color: AppTheme.primary,
              ),
              _buildStatItem(
                icon: Icons.block_outlined,
                value: blockedIps.toString(),
                label: 'Blocked IPs',
                color: Colors.redAccent,
              ),
              _buildStatItem(
                icon: Icons.verified_user_outlined,
                value: managedRules.toString(),
                label: 'WAF Rules',
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK ACTIONS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionTile(
            icon: Icons.add_circle_outline,
            title: 'Add IP Block',
            subtitle: 'Block a specific IP address',
            onTap: () => _showAddIpBlockDialog(),
          ),
          const Divider(height: 1),
          _buildActionTile(
            icon: Icons.gavel_outlined,
            title: 'Create Firewall Rule',
            subtitle: 'Set up rate limiting or access control',
            onTap: () => _showAddFirewallRuleDialog(),
          ),
          const Divider(height: 1),
          _buildActionTile(
            icon: Icons.settings_outlined,
            title: 'WAF Settings',
            subtitle: 'Configure managed security rules',
            onTap: () => _tabController.animateTo(2),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.onSurfaceVariant,
          fontSize: 13,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.onSurfaceVariant),
      onTap: onTap,
    );
  }

  Widget _buildFirewallTab() {
    final rules = _firewallConfig?.rules ?? [];
    final ips = _firewallConfig?.ips ?? [];

    return RefreshIndicator(
      onRefresh: _loadSecurityData,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Firewall Rules',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAddFirewallRuleDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Rule'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (rules.isEmpty)
            _buildEmptyListState(
              icon: Icons.rule_outlined,
              title: 'No Custom Rules',
              subtitle: 'Create rules to block IPs, rate limit, or challenge visitors',
            )
          else
            ...rules.map((rule) => _buildRuleCard(rule)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Blocked IP Addresses',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAddIpBlockDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Block IP'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (ips.isEmpty)
            _buildEmptyListState(
              icon: Icons.block_outlined,
              title: 'No Blocked IPs',
              subtitle: 'Block specific IP addresses or CIDR ranges',
            )
          else
            ...ips.map((ip) => _buildIpCard(ip)),
        ],
      ),
    );
  }

  Widget _buildRuleCard(FirewallRule rule) {
    final actionColor = _getActionColor(rule.action);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: actionColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Icon(
              _getActionIcon(rule.action),
              color: actionColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  _buildRuleDescription(rule),
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: actionColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              rule.action.toUpperCase(),
              style: TextStyle(
                color: actionColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIpCard(String ip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Icon(
              Icons.block_outlined,
              color: Colors.redAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ip,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Blocked',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _showRemoveIpDialog(ip),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyListState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppTheme.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWafTab() {
    final rulesets = _managedRulesets ?? [];

    return RefreshIndicator(
      onRefresh: _loadSecurityData,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Managed rulesets provide automatic protection against common attacks like SQL injection, XSS, and more.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Managed WAF Rulesets',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (rulesets.isEmpty)
            _buildEmptyListState(
              icon: Icons.verified_user_outlined,
              title: 'No Rulesets Available',
              subtitle: 'Managed WAF rulesets will appear here',
            )
          else
            ...rulesets.map((ruleset) => _buildRulesetCard(ruleset)),
        ],
      ),
    );
  }

  Widget _buildRulesetCard(ManagedRuleset ruleset) {
    final actionColor = _getActionColor(ruleset.action);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ruleset.enabled ? Colors.green.withOpacity(0.1) : AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Icon(
              ruleset.enabled ? Icons.verified_user : Icons.verified_user_outlined,
              color: ruleset.enabled ? Colors.green : AppTheme.onSurfaceVariant,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ruleset.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (ruleset.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    ruleset.description!,
                    style: TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: actionColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        ruleset.action.toUpperCase(),
                        style: TextStyle(
                          color: actionColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ruleset.enabled
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        ruleset.enabled ? 'ACTIVE' : 'INACTIVE',
                        style: TextStyle(
                          color: ruleset.enabled ? Colors.green : Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: ruleset.enabled,
            onChanged: (value) => _updateRuleset(ruleset, value),
            activeColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Future<void> _updateRuleset(ManagedRuleset ruleset, bool enabled) async {
    if (_selectedProject == null) return;

    setState(() => _isLoading = true);

    try {
      final api = Provider.of<AppState>(context, listen: false).apiService;

      await api.updateManagedRuleset(
        projectId: _selectedProject!.id,
        rulesetId: ruleset.id,
        enabled: enabled,
        action: ruleset.action,
      );

      await _loadSecurityData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${ruleset.name} ${enabled ? 'enabled' : 'disabled'}'),
            backgroundColor: enabled ? Colors.green : AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update ruleset: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showAddIpBlockDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceContainerLow,
          title: const Text('Block IP Address'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'IP Address or CIDR',
              hintText: '192.168.1.1 or 10.0.0.0/24',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final ip = controller.text.trim();
                if (ip.isEmpty) return;

                Navigator.pop(context);
                await _blockIp(ip);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Block'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _blockIp(String ip) async {
    if (_selectedProject == null) return;

    setState(() => _isLoading = true);

    try {
      final api = Provider.of<AppState>(context, listen: false).apiService;

      await api.blockIp(
        projectId: _selectedProject!.id,
        ip: ip,
        note: 'Blocked via Vero app',
      );

      await _loadSecurityData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('IP $ip blocked successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to block IP: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showRemoveIpDialog(String ip) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceContainerLow,
          title: const Text('Remove IP Block'),
          content: Text('Are you sure you want to unblock $ip?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                // Note: IP unblocking would need a separate API endpoint
                // For now, we show a message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Use Vercel Dashboard to remove IP blocks'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Unblock'),
            ),
          ],
        );
      },
    );
  }

  void _showAddFirewallRuleDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceContainerLow,
          title: const Text('Create Firewall Rule'),
          content: const SingleChildScrollView(
            child: Text(
              'Advanced firewall rules can be configured through the Vercel Dashboard. '
              'This includes rate limiting, geo-blocking, and custom conditions.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Open Vercel dashboard
              },
              child: const Text('Open Dashboard'),
            ),
          ],
        );
      },
    );
  }

  String _buildRuleDescription(FirewallRule rule) {
    final parts = <String>[];
    if (rule.ip != null) parts.add('IP: ${rule.ip}');
    if (rule.hostname != null) parts.add('Host: ${rule.hostname}');
    if (rule.rateLimit != null) parts.add('${rule.rateLimit}/${rule.rateLimitWindow ?? "min"}');
    return parts.isEmpty ? 'Matches all requests' : parts.join(' • ');
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'deny':
      case 'block':
        return Colors.redAccent;
      case 'challenge':
        return Colors.orange;
      case 'rate_limit':
        return Colors.blue;
      case 'redirect':
        return Colors.purple;
      case 'log':
        return Colors.grey;
      default:
        return AppTheme.primary;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'deny':
      case 'block':
        return Icons.block_outlined;
      case 'challenge':
        return Icons.help_outline;
      case 'rate_limit':
        return Icons.speed_outlined;
      case 'redirect':
        return Icons.arrow_forward;
      case 'log':
        return Icons.article_outlined;
      default:
        return Icons.security_outlined;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.inHours < 1) {
      return '${diff.inMinutes}m';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m';
    } else {
      return '${diff.inDays}d ${diff.inHours % 24}h';
    }
  }
}
