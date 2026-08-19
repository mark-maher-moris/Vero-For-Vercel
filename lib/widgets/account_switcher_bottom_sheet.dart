import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vercel_account.dart';
import '../providers/app_state.dart';
import '../providers/subscription_provider.dart';
import '../services/superwall_service.dart';
import '../services/account_entitlement_policy.dart';
import '../theme/app_theme.dart';
import '../screens/login_screen.dart';

class AccountSwitcherBottomSheet extends StatelessWidget {
  const AccountSwitcherBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerLow,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const AccountSwitcherBottomSheet(),
    );
  }

  Future<void> _handleConnectNewAccount(BuildContext context) async {
    final appState = context.read<AppState>();
    final subscription = context.read<SubscriptionProvider>();

    SuperwallService().trackUserAction(
      'tap_connect_new_account',
      context: 'account_switcher_sheet',
      properties: {'account_count': appState.accounts.length},
    );

    final hasExistingAccount = appState.accounts.isNotEmpty;
    final canProceed = hasExistingAccount
        ? await subscription.authorizeAdditionalAccount(
            currentAccountCount: appState.accounts.length,
          )
        : true;

    // A first account uses the normal Pro gate. Only an additional account
    // requires the separate add-on entitlement.
    if (context.mounted && canProceed) {
      final navigator = Navigator.of(context);
      navigator.pop(); // Close sheet
      navigator.push(
        MaterialPageRoute(
          builder: (_) => LoginScreen(isAdditionalAccount: hasExistingAccount),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final accounts = appState.accounts;
    final activeAccount = appState.activeAccount;
    final isDemo = appState.isDemoMode;
    final canAddAccount =
        accounts.length < AccountEntitlementPolicy.maxConnectedAccounts;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Sheet Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Switch Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppTheme.onSurfaceVariant,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Demo mode notice
              if (isDemo) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You are viewing Demo Mode. Connect a Vercel account for live data.',
                          style: TextStyle(color: Colors.amber, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Workspaces / Teams under active account
              if (!isDemo && activeAccount != null) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Workspaces (@${activeAccount.username})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),

                // Personal Scope Tile
                _buildTeamTile(
                  context,
                  title: 'Personal Workspace',
                  subtitle: '@${activeAccount.username}',
                  isSelected: appState.currentTeamId == null,
                  icon: Icons.person_outline,
                  onTap: () {
                    appState.switchTeam(null);
                    Navigator.pop(context);
                  },
                ),

                // Team Scopes
                ...appState.teams.map((team) {
                  final isSelected = appState.currentTeamId == team['id'];
                  return _buildTeamTile(
                    context,
                    title: team['name']?.toString() ?? 'Team',
                    subtitle: team['slug'] != null
                        ? '@${team['slug']}'
                        : 'Team Scope',
                    isSelected: isSelected,
                    icon: Icons.groups_outlined,
                    avatarUrl: team['avatar'] != null
                        ? 'https://vercel.com/api/www/avatar/${team['avatar']}'
                        : null,
                    onTap: () {
                      appState.switchTeam(team['id']?.toString());
                      Navigator.pop(context);
                    },
                  );
                }),
              ],

              const SizedBox(height: 16),

              // Connect New Account Action Row
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.outlineVariant.withValues(alpha: 0.15),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      canAddAccount
                          ? 'Add Vercel Account'
                          : 'Account limit reached',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: canAddAccount
                            ? AppTheme.primary
                            : AppTheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: canAddAccount
                          ? AppTheme.onSurfaceVariant
                          : AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
                      size: 20,
                    ),
                    onTap: canAddAccount
                        ? () => _handleConnectNewAccount(context)
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'You can connect a maximum of 2 Vercel accounts.',
                                ),
                              ),
                            );
                          },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTile(
    BuildContext context,
    VercelAccount account,
    bool isActive,
    AppState appState,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primary.withValues(alpha: 0.08)
            : AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppTheme.primary.withValues(alpha: 0.3)
              : AppTheme.outlineVariant.withValues(alpha: 0.08),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 2,
          ),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfaceContainerHigh,
              image: account.avatarUrl != null
                  ? DecorationImage(
                      image: NetworkImage(account.avatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: account.avatarUrl == null
                ? Center(
                    child: Text(
                      (account.username.isNotEmpty ? account.username[0] : 'U')
                          .toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                        fontSize: 15,
                      ),
                    ),
                  )
                : null,
          ),
          title: Text(
            account.name.isNotEmpty ? account.name : account.username,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              color: AppTheme.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '@${account.username}${account.email != null && account.email!.isNotEmpty ? " • ${account.email}" : ""}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: isActive
              ? const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.primary,
                  size: 22,
                )
              : null,
          onTap: () {
            if (!isActive) {
              appState.switchAccount(account.id);
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _buildTeamTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isSelected,
    required IconData icon,
    String? avatarUrl,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primary.withValues(alpha: 0.06)
            : AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.25)
              : AppTheme.outlineVariant.withValues(alpha: 0.05),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 0,
          ),
          leading: Container(
            width: 28,
            height: 28,
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
                ? Icon(
                    icon,
                    size: 16,
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.onSurfaceVariant,
                  )
                : null,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppTheme.primary : AppTheme.onSurface,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          trailing: isSelected
              ? const Icon(Icons.check, color: AppTheme.primary, size: 18)
              : null,
          onTap: onTap,
        ),
      ),
    );
  }
}
