import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../providers/subscription_provider.dart';
import '../services/superwall_service.dart';
import '../models/project.dart';
import '../theme/app_theme.dart';
import '../widgets/project_card.dart';
import 'import_github_project_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _usageData;
  bool _isLoadingUsage = false;

  @override
  void initState() {
    super.initState();
    _fetchUsageData();
    // Track dashboard screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SuperwallService().trackScreenView('dashboard', additionalProps: {
        'project_count': context.read<AppState>().projects.length,
        'has_teams': context.read<AppState>().teams.isNotEmpty,
      });
      // Register placement for potential paywall
      SuperwallService().registerPlacement('projects_screen');
    });
  }

  Future<void> _fetchUsageData() async {
    final appState = Provider.of<AppState>(context, listen: false);
    if (!appState.isAuthenticated) return;
    
    setState(() => _isLoadingUsage = true);
    try {
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, 1);
      
      final usage = await appState.apiService.getUsage(
        from: from.toUtc().toIso8601String(),
        to: now.toUtc().toIso8601String(),
      );
      if (mounted) {
        setState(() {
          _usageData = usage;
          _isLoadingUsage = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingUsage = false);
    }
  }

  String _formatRequests(num? count) {
    if (count == null) return '-';
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  String _formatBandwidth(num? bytes) {
    if (bytes == null) return '-';
    final gb = bytes / (1024 * 1024 * 1024);
    if (gb >= 1000) return '${(gb / 1024).toStringAsFixed(1)} TB';
    if (gb >= 1) return '${gb.toStringAsFixed(1)} GB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLow,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceContainerHigh,
              ),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Image.asset('assets/logo.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Vero', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.onSurfaceVariant),
            onPressed: () {
              SuperwallService().trackUserAction('import_github_project', context: 'dashboard');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ImportGithubProjectScreen()),
              );
            },
            tooltip: 'Import GitHub Project',
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: AppTheme.onSurfaceVariant),
            onPressed: () {
              SuperwallService().trackUserAction('switch_team', context: 'dashboard');
              _showTeamPicker(context, appState);
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: AppTheme.onSurfaceVariant),
            onPressed: () {
              SuperwallService().trackUserAction('logout', context: 'dashboard');
              appState.logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: appState.fetchInitialData,
        color: AppTheme.primary,
        child: appState.errorMessage != null 
          ? _buildErrorView(appState)
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
              children: [
                _buildSearchField(),
                const SizedBox(height: 24),
                _buildTeamInfo(appState),
                const SizedBox(height: 40),
                _buildProjectsGrid(appState.projects),
                const SizedBox(height: 40),
                _buildUsageOverview(),
              ],
            ),
      ),
    );
  }

  Widget _buildErrorView(AppState appState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Failed to load data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              appState.errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: appState.fetchInitialData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamInfo(AppState appState) {
    String teamName = 'Personal Account';
    if (appState.currentTeamId != null) {
      final team = appState.teams.firstWhere(
        (t) => t['id'] == appState.currentTeamId,
        orElse: () => {'name': 'Team'},
      );
      teamName = team['name'] ?? 'Team';
    }

    return Row(
      children: [
        const Icon(Icons.account_tree_outlined, size: 16, color: AppTheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          teamName.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  void _showTeamPicker(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Switch Account',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.surfaceContainerHigh,
                  child: Icon(Icons.person, color: AppTheme.onSurfaceVariant),
                ),
                title: const Text('Personal Account'),
                trailing: appState.currentTeamId == null ? const Icon(Icons.check, color: AppTheme.primary) : null,
                onTap: () {
                  appState.switchTeam(null);
                  Navigator.pop(context);
                },
              ),
              ...appState.teams.map((team) {
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    child: Icon(Icons.group, color: AppTheme.onSurfaceVariant),
                  ),
                  title: Text(team['name'] ?? 'Team'),
                  trailing: appState.currentTeamId == team['id'] ? const Icon(Icons.check, color: AppTheme.primary) : null,
                  onTap: () {
                    appState.switchTeam(team['id']);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(2),
      ),
      child: const TextField(
        style: TextStyle(color: AppTheme.onSurface),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search, color: AppTheme.onSurfaceVariant),
          hintText: 'Search projects...',
          hintStyle: TextStyle(color: AppTheme.onSurfaceVariant),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildProjectsGrid(List<Project> projects) {
    if (projects.isEmpty) {
      return const Center(
        child: Text('No projects found.', style: TextStyle(color: AppTheme.onSurfaceVariant)),
      );
    }

    // Watch subscription provider
    final subscription = context.watch<SubscriptionProvider>();
    final isPro = subscription.isPro;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1, // Let's make it list-like on mobile, or grid on tablet
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        childAspectRatio: 1.5,
      ),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final isBlurred = !isPro && index > 0;
        return ProjectCard(
          project: projects[index],
          isBlurred: isBlurred,
          onSubscribeTap: () => _showPaywall(context),
          onProjectTap: () {
            SuperwallService().trackProjectAction('view_project', 
              projectId: projects[index].id,
              properties: {'project_name': projects[index].name}
            );
          },
        );
      },
    );
  }

  void _showPaywall(BuildContext context) async {
    await SuperwallService().presentPaywall();
    // Refresh subscription status after paywall closes
    if (mounted) {
      final subscription = Provider.of<SubscriptionProvider>(context, listen: false);
      subscription.refresh();
    }
  }

  Widget _buildUsageOverview() {
    final requests = _usageData?['total']?['requests'] as num?;
    final bandwidth = _usageData?['total']?['bandwidth'] as num?;
    
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'USAGE SUMMARY',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isLoadingUsage)
                      const SizedBox(
                        height: 44,
                        width: 44,
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                          strokeWidth: 2,
                        ),
                      )
                    else
                      Text(
                        _formatRequests(requests),
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
                          letterSpacing: -1.5,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'REQUESTS / 30D',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isLoadingUsage)
                      const SizedBox(
                        height: 44,
                        width: 44,
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                          strokeWidth: 2,
                        ),
                      )
                    else
                      Text(
                        _formatBandwidth(bandwidth),
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
                          letterSpacing: -1.5,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'BANDWIDTH',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
