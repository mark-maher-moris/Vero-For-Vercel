import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';
import '../widgets/project_selector_appbar.dart';
import 'settings_env_vars_screen.dart';
import 'domains_dns_screen.dart';
import 'team_access_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.user?['user'];
    final username = user?['username'] ?? 'User';
    final email = user?['email'] ?? '';
    final name = user?['name'] ?? username;
    final avatarUrl = user?['avatar'];

    String teamName = 'Personal Account';
    if (appState.currentTeamId != null) {
      final team = appState.teams.firstWhere(
        (t) => t['id'] == appState.currentTeamId,
        orElse: () => {'name': 'Team'},
      );
      teamName = team['name'] ?? 'Team';
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: const ProjectSelectorAppBar(),
      body: RefreshIndicator(
        onRefresh: appState.fetchInitialData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
          children: [
            // Header
            const Text(
              'ACCOUNT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurfaceVariant,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Profile & Settings',
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: AppTheme.primary,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Profile Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.surfaceContainerHigh,
                      image: avatarUrl != null
                          ? DecorationImage(
                              image: NetworkImage(avatarUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: avatarUrl == null
                        ? const Icon(Icons.person, size: 32, color: AppTheme.onSurfaceVariant)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            teamName.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Quick Actions Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildActionCard(
                  context,
                  icon: Icons.people,
                  title: 'Team',
                  subtitle: 'Members & Access',
                  onTap: () => _navigateTo(context, const TeamAccessScreen()),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.language,
                  title: 'Domains',
                  subtitle: 'DNS & SSL',
                  onTap: () => _navigateTo(context, const DomainsDnsScreen()),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.key,
                  title: 'Environment',
                  subtitle: 'Env Variables',
                  onTap: () => _navigateTo(context, const SettingsEnvVarsScreen()),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.link_off,
                  title: 'Disconnect',
                  subtitle: 'Unlink Vercel',
                  onTap: () => _showDisconnectDialog(context, appState),
                  isDestructive: true,
                ),
                _buildActionCard(
                  context,
                  icon: Icons.logout,
                  title: 'Logout',
                  subtitle: 'Sign out',
                  onTap: () => _showLogoutDialog(context, appState),
                  isDestructive: true,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Account Info Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ACCOUNT INFO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurfaceVariant,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Username', username),
                  const Divider(height: 24),
                  _buildInfoRow('Current Team', teamName),
                  const Divider(height: 24),
                  _buildInfoRow('Projects', '${appState.projects.length}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppTheme.error : AppTheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: AppTheme.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDestructive ? AppTheme.error : AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLow,
        title: const Text('Sign Out', style: TextStyle(color: AppTheme.primary)),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              appState.logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showDisconnectDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLow,
        title: const Text('Disconnect from Vercel', style: TextStyle(color: AppTheme.primary)),
        content: const Text(
          'Are you sure you want to unlink this app from Vercel? This will remove the connection and you will need to reconnect to manage deployments.',
          style: TextStyle(color: AppTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              appState.disconnectFromVercel();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}
