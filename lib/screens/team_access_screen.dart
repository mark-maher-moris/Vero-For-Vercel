import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';

class TeamAccessScreen extends StatelessWidget {
  const TeamAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.user?['user'];
    final username = user?['username'] ?? 'User';
    final email = user?['email'] ?? '';
    final name = user?['name'] ?? username;

    // Build tabs from actual teams
    final teams = appState.teams;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
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
            const Expanded(
              child: Text(
                'Team Access',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
        children: [
          const Text(
            'Manage your team members, permissions, and security settings in one place.',
            style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant, height: 1.5),
          ),
          
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(4)),
                child: Row(
                  children: [
                    // Personal account tab
                    GestureDetector(
                      onTap: () => appState.switchTeam(null),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: appState.currentTeamId == null ? AppTheme.surfaceContainerHigh : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          'Personal',
                          style: TextStyle(
                            color: appState.currentTeamId == null ? AppTheme.primary : AppTheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Dynamic team tabs
                    ...teams.map((team) {
                      final isSelected = appState.currentTeamId == team['id'];
                      return GestureDetector(
                        onTap: () => appState.switchTeam(team['id']),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.surfaceContainerHigh : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            team['name'] ?? 'Team',
                            style: TextStyle(
                              color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                ),
                icon: const Icon(Icons.person_add, color: AppTheme.onPrimary, size: 18),
                label: const Text('Invite Member', style: TextStyle(color: AppTheme.onPrimary, fontWeight: FontWeight.bold)),
                onPressed: () {},
              ),
            ],
          ),

          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(color: AppTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(4)),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOTAL SEATS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5)),
                      SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('1', style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: -2)),
                          SizedBox(width: 8),
                          Text('/ 1', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(color: AppTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(4)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PENDING INVITES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      const Text('0', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Container(width: 32, height: 32, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.surfaceContainerHigh), child: const Icon(Icons.person, size: 16, color: AppTheme.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(color: AppTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(4)),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Team Members', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                      Container(
                        width: 200,
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: AppTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(2)),
                        child: const Row(
                          children: [
                            Icon(Icons.search, size: 16, color: AppTheme.onSurfaceVariant),
                            SizedBox(width: 8),
                            Text('Search members...', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.1)))),
                  child: const Row(
                    children: [
                      Expanded(flex: 3, child: Text('MEMBER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5))),
                      Expanded(child: Text('ROLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5))),
                      Expanded(child: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5))),
                      SizedBox(width: 48, child: Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5))),
                    ],
                  ),
                ),
                // Show user info for Personal account, or team-specific message
                if (appState.currentTeamId == null) ...[
                  _buildMemberRow(name, email, 'OWNER', true),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('Only you have access to this personal account.', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
                    ),
                  ),
                ] else ...[
                  _buildMemberRow(name, email, 'MEMBER', true),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('Team members would be listed here when team API data is available.', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberRow(String name, String email, String role, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.1)))),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.surfaceContainerHigh),
                  child: const Icon(Icons.person, color: AppTheme.onSurfaceVariant),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    Text(email, style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: role == 'OWNER' ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.surfaceVariant,
                  border: role == 'OWNER' ? Border.all(color: AppTheme.primary.withValues(alpha: 0.2)) : null,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(role.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: role == 'OWNER' ? AppTheme.primary : AppTheme.onSurfaceVariant, letterSpacing: 1)),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? AppTheme.primary : AppTheme.secondary,
                    boxShadow: isActive ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 4)] : null,
                  ),
                ),
                const SizedBox(width: 8),
                Text(isActive ? 'Active' : 'Pending invite...', style: TextStyle(fontSize: 12, color: isActive ? AppTheme.onSurface : AppTheme.onSurfaceVariant, fontStyle: isActive ? FontStyle.normal : FontStyle.italic)),
              ],
            ),
          ),
          SizedBox(
            width: 48,
            child: isActive
              ? const Icon(Icons.more_vert, color: AppTheme.onSurfaceVariant, size: 20)
              : const Row(mainAxisAlignment: MainAxisAlignment.end, children: [Icon(Icons.cancel, color: AppTheme.onSurfaceVariant, size: 20)]),
          ),
        ],
      ),
    );
  }
}
