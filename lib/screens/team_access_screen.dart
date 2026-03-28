import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';

class TeamAccessScreen extends StatefulWidget {
  const TeamAccessScreen({super.key});

  @override
  State<TeamAccessScreen> createState() => _TeamAccessScreenState();
}

class _TeamAccessScreenState extends State<TeamAccessScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _showInviteDialog(BuildContext context, AppState appState) async {
    if (appState.currentTeamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a team first')),
      );
      return;
    }

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLow,
        title: const Text('Invite Team Member'),
        content: TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'colleague@example.com',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _emailController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _isLoading ? null : () => _inviteMember(context, appState),
            child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Invite'),
          ),
        ],
      ),
    );
  }

  Future<void> _inviteMember(BuildContext context, AppState appState) async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    final teamId = appState.currentTeamId;
    if (teamId == null) return;

    setState(() => _isLoading = true);
    try {
      await appState.apiService.inviteTeamMember(teamId, email);
      _emailController.clear();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invitation sent to $email')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send invitation: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: AppTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(4)),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
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
                ),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                ),
                icon: const Icon(Icons.person_add, color: AppTheme.onPrimary, size: 18),
                label: const Text('Invite Member', style: TextStyle(color: AppTheme.onPrimary, fontWeight: FontWeight.bold)),
                onPressed: () => _showInviteDialog(context, appState),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL SEATS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5)),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            appState.currentTeamId == null ? '1' : '${appState.teams.length + 1}',
                            style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: -2)
                          ),
                          const SizedBox(width: 8),
                          Text('/ ${appState.currentTeamId == null ? 1 : (appState.teams.firstWhere((t) => t['id'] == appState.currentTeamId, orElse: () => {'seats': 1})['seats'] ?? 1)}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant)
                          ),
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
                      const Text('-', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppTheme.primary)),
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
                      const Expanded(
                        child: Text('Team Members', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppTheme.surfaceContainerLowest,
                            hintText: 'Search members...',
                            hintStyle: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
                            prefixIcon: const Icon(Icons.search, size: 16, color: AppTheme.onSurfaceVariant),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(2),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          style: const TextStyle(color: AppTheme.onSurface),
                          onChanged: (value) {
                            // TODO: Implement member search filtering
                          },
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary), overflow: TextOverflow.ellipsis, maxLines: 1),
                      Text(email, style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant), overflow: TextOverflow.ellipsis, maxLines: 1),
                    ],
                  ),
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
              ? IconButton(
                  icon: const Icon(Icons.more_vert, color: AppTheme.onSurfaceVariant, size: 20),
                  onPressed: () => _showMemberOptions(context, name),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              : IconButton(
                  icon: const Icon(Icons.cancel, color: AppTheme.onSurfaceVariant, size: 20),
                  onPressed: () => _cancelInvite(context, email),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
          ),
        ],
      ),
    );
  }

  void _showMemberOptions(BuildContext context, String name) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person, color: AppTheme.primary),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('View profile for $name')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.primary),
              title: const Text('Change Role'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Change role coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.error),
              title: const Text('Remove Member', style: TextStyle(color: AppTheme.error)),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppTheme.surfaceContainerLow,
                    title: const Text('Remove Member?'),
                    content: Text('Are you sure you want to remove $name?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$name removed')),
                          );
                        },
                        child: const Text('Remove', style: TextStyle(color: AppTheme.error)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _cancelInvite(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLow,
        title: const Text('Cancel Invitation?'),
        content: Text('Are you sure you want to cancel the invitation to $email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Invitation to $email cancelled')),
              );
            },
            child: const Text('Cancel Invite', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}
