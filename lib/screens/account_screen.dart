import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/vercel_account.dart';
import '../services/superwall_service.dart';
import '../services/account_entitlement_policy.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';
import '../providers/subscription_provider.dart';
import '../widgets/demo_mode_banners.dart';
import '../widgets/account_switcher_bottom_sheet.dart';
import 'login_screen.dart';
import 'domains_dns_screen.dart';
import 'team_access_screen.dart';
import 'onboarding_screen.dart';
import 'widget_config_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _supportId = '';

  @override
  void initState() {
    super.initState();
    _loadSupportId();
  }

  Future<void> _loadSupportId() async {
    final supportId = await SuperwallService().getUserId();
    if (mounted) {
      setState(() {
        _supportId = supportId;
      });
    }
  }

  void _copySupportId() {
    if (_supportId.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _supportId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Support ID copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  Future<void> _handleConnectNewAccount(BuildContext context) async {
    final appState = context.read<AppState>();
    final subscription = context.read<SubscriptionProvider>();

    SuperwallService().trackUserAction(
      'tap_connect_new_account',
      context: 'settings_screen',
      properties: {'account_count': appState.accounts.length},
    );

    // Authorize the exact Pro + additional-account entitlements before
    // opening the token flow.
    final canProceed = await subscription.authorizeAdditionalAccount(
      currentAccountCount: appState.accounts.length,
    );

    // Only open the connect screen after the exact entitlement check succeeds.
    if (context.mounted && canProceed) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(isAdditionalAccount: true),
        ),
      );
    }
  }

  Widget _buildCopyableInfoRow(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          Row(
            children: [
              Text(
                value.length > 20 ? '${value.substring(0, 17)}...' : value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.copy,
                size: 16,
                color: AppTheme.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final isPro = subscriptionProvider.isPro;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text(
          'Account',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
      ),
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
              'Settings',
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: AppTheme.primary,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Home Widgets Card
            GestureDetector(
              onTap: () => _navigateTo(context, const WidgetConfigScreen()),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8A2BE2), Color(0xFF4B0082)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8A2BE2).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Home Widgets',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Configure your home widgets',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ==========================================
            // CONNECTED ACCOUNTS SECTION
            // ==========================================
            _buildConnectedAccountsSection(context, appState, isPro),

            const SizedBox(height: 32),

            // Demo mode: CTA to connect a real Vercel account.
            if (appState.isDemoMode) ...[
              const ConnectRealAccountBanner(
                title: 'Connect with real data',
                subtitle:
                    'You are signed in to the demo. Connect your Vercel account to view your own projects and manage them.',
                icon: Icons.vpn_key,
              ),
              const SizedBox(height: 24),
            ],

            // Upgrade Banner (non-pro users only)
            if (!isPro)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.star,
                        color: AppTheme.onPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upgrade to Pro',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Unlock all features & multi-accounts',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        subscriptionProvider.showPaywall();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text('Upgrade'),
                    ),
                  ],
                ),
              ),

            if (!isPro) const SizedBox(height: 32),

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
                  onTap: isPro
                      ? () => _navigateTo(context, const TeamAccessScreen())
                      : () => subscriptionProvider.showPaywall(),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.language,
                  title: 'Domains',
                  subtitle: 'DNS & SSL',
                  onTap: isPro
                      ? () => _navigateTo(context, const DomainsDnsScreen())
                      : () => subscriptionProvider.showPaywall(),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.swap_horiz,
                  title: 'Switch Account',
                  subtitle: '${appState.accounts.length} connected',
                  onTap: () => AccountSwitcherBottomSheet.show(context),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.widgets_outlined,
                  title: 'Widgets',
                  subtitle: 'Edit home widgets',
                  onTap: () => _navigateTo(context, const WidgetConfigScreen()),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.vpn_key,
                  title: 'API Token',
                  subtitle: 'Update active token',
                  onTap: () {
                    if (subscriptionProvider.hasActiveSubscription) {
                      _showChangeTokenDialog(context);
                    } else {
                      subscriptionProvider.showPaywall();
                    }
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.logout,
                  title: 'Logout',
                  subtitle: 'Sign out of all',
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
                borderRadius: BorderRadius.circular(8),
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
                  _buildCopyableInfoRow(
                    'Support ID',
                    _supportId,
                    _copySupportId,
                  ),
                  const Divider(height: 24),
                  _buildRestorePurchasesButton(),
                  const Divider(height: 24),
                  _buildReplayOnboardingButton(context),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Contact Us Section
            GestureDetector(
              onTap: () => _launchEmail(context),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SUPPORT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurfaceVariant,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.email, color: AppTheme.primary, size: 24),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Contact Us',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'hi@buildagon.com',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.open_in_new,
                          color: AppTheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedAccountsSection(
    BuildContext context,
    AppState appState,
    bool isPro,
  ) {
    final accounts = appState.accounts;
    final activeAccount = appState.activeAccount;
    final canAddAccount =
        accounts.length < AccountEntitlementPolicy.maxConnectedAccounts;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CONNECTED ACCOUNTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${accounts.length} ${accounts.length == 1 ? "Account" : "Accounts"}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Accounts List
          if (accounts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No accounts connected. Connect an account below.',
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            )
          else
            ...accounts.map((acc) {
              final isActive = activeAccount?.id == acc.id;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.primary.withValues(alpha: 0.08)
                      : AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive
                        ? AppTheme.primary.withValues(alpha: 0.4)
                        : AppTheme.outlineVariant.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.surfaceContainerHigh,
                        image: acc.avatarUrl != null
                            ? DecorationImage(
                                image: NetworkImage(acc.avatarUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: acc.avatarUrl == null
                          ? Center(
                              child: Text(
                                (acc.username.isNotEmpty
                                        ? acc.username[0]
                                        : 'U')
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  acc.name.isNotEmpty ? acc.name : acc.username,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isActive
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: AppTheme.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isActive) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      color: AppTheme.onPrimary,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${acc.username}${acc.teamScope != null ? " (Team: ${acc.teamScope})" : ""}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (!isActive)
                      TextButton(
                        onPressed: () => appState.switchAccount(acc.id),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Switch',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        size: 18,
                        color: AppTheme.onSurfaceVariant,
                      ),
                      color: AppTheme.surfaceContainerHigh,
                      onSelected: (value) {
                        if (value == 'switch') {
                          appState.switchAccount(acc.id);
                        } else if (value == 'disconnect') {
                          _showDisconnectSpecificAccountDialog(
                            context,
                            appState,
                            acc,
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        if (!isActive)
                          const PopupMenuItem(
                            value: 'switch',
                            child: Row(
                              children: [
                                Icon(Icons.swap_horiz, size: 18),
                                SizedBox(width: 8),
                                Text('Switch to this account'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'disconnect',
                          child: Row(
                            children: [
                              Icon(
                                Icons.link_off,
                                color: AppTheme.error,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Disconnect',
                                style: TextStyle(color: AppTheme.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 12),

          // Connect New Account Action Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.15),
                  AppTheme.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.add,
                  color: AppTheme.onPrimary,
                  size: 20,
                ),
              ),
              title: Text(
                canAddAccount ? 'Connect New Account' : 'Account limit reached',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: canAddAccount
                      ? AppTheme.primary
                      : AppTheme.onSurfaceVariant,
                ),
              ),
              subtitle: Text(
                canAddAccount
                    ? 'Add another account & switch instantly'
                    : 'You can connect a maximum of 2 accounts',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: canAddAccount
                    ? AppTheme.primary
                    : AppTheme.onSurfaceVariant,
                size: 20,
              ),
              onTap: canAddAccount
                  ? () => _handleConnectNewAccount(context)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showDisconnectSpecificAccountDialog(
    BuildContext context,
    AppState appState,
    VercelAccount account,
  ) {
    final isOnlyAccount = appState.accounts.length <= 1;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLow,
        title: Text(
          isOnlyAccount
              ? 'Disconnect Vercel'
              : 'Disconnect @${account.username}',
          style: const TextStyle(color: AppTheme.primary),
        ),
        content: Text(
          isOnlyAccount
              ? 'This is your only connected account. Disconnecting will sign you out of the app.'
              : 'Are you sure you want to disconnect @${account.username}? Your other connected accounts will remain active.',
          style: const TextStyle(color: AppTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final subscriptionProvider = context.read<SubscriptionProvider>();
              await appState.disconnectAccount(
                account.id,
                subscriptionProvider: subscriptionProvider,
              );

              if (context.mounted && isOnlyAccount) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnboardingScreen(),
                  ),
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  void _launchEmail(BuildContext context) async {
    final uri = Uri.parse('mailto:hi@buildagon.com');
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $uri');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open email app'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
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
          borderRadius: BorderRadius.circular(8),
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

  Widget _buildRestorePurchasesButton() {
    return GestureDetector(
      onTap: () => _restorePurchases(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Restore Purchases',
            style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant),
          ),
          Row(
            children: [
              const Icon(Icons.restore, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'Tap to restore',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _restorePurchases() async {
    try {
      final restored = await context
          .read<SubscriptionProvider>()
          .restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              restored
                  ? 'Purchases restored successfully'
                  : 'No active Pro purchase was found to restore',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore purchases: $e'),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildReplayOnboardingButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _replayOnboarding(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Replay Onboarding',
            style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant),
          ),
          Row(
            children: [
              const Icon(Icons.replay, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'Debug only',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _replayOnboarding(BuildContext context) async {
    final appState = context.read<AppState>();
    await appState.resetOnboarding();
  }

  void _showChangeTokenDialog(BuildContext context) {
    final TextEditingController tokenController = TextEditingController();
    final TextEditingController teamController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.surfaceContainerLow,
            title: const Text(
              'Change API Token',
              style: TextStyle(color: AppTheme.primary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your new Vercel API token:',
                  style: TextStyle(color: AppTheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tokenController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'vercel_api_token_...',
                    hintStyle: TextStyle(
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    errorText: errorMessage,
                  ),
                  style: const TextStyle(color: AppTheme.primary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: teamController,
                  decoration: InputDecoration(
                    labelText: 'Team ID or slug (optional)',
                    hintText: 'Only for a team-scoped token',
                    hintStyle: TextStyle(
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: AppTheme.primary),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _launchVercelTokens(context),
                  child: Text(
                    'Get your token from Vercel →',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primary.withValues(alpha: 0.8),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final token = tokenController.text.trim();
                        if (token.isEmpty) {
                          setDialogState(() {
                            errorMessage = 'Please enter a token';
                          });
                          return;
                        }

                        setDialogState(() {
                          isLoading = true;
                          errorMessage = null;
                        });

                        final appState = context.read<AppState>();
                        final subscription = context
                            .read<SubscriptionProvider>();
                        try {
                          if (!subscription.hasActiveSubscription) {
                            final hasPro = await subscription.showPaywall();
                            if (!hasPro ||
                                !subscription.hasActiveSubscription) {
                              setDialogState(() {
                                isLoading = false;
                                errorMessage =
                                    'An active Pro subscription is required to use a live Vercel account.';
                              });
                              return;
                            }
                          }

                          final activeAccountId = appState.activeAccount?.id;
                          if (activeAccountId == null) {
                            setDialogState(() {
                              isLoading = false;
                              errorMessage = 'No active Vercel account found.';
                            });
                            return;
                          }

                          await appState.updateAccountToken(
                            activeAccountId,
                            token,
                            teamId: teamController.text,
                            subscriptionProvider: subscription,
                          );

                          if (appState.errorMessage != null) {
                            setDialogState(() {
                              isLoading = false;
                              errorMessage = appState.errorMessage;
                            });
                          } else {
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'API token updated successfully',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          setDialogState(() {
                            isLoading = false;
                            errorMessage = e.toString();
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.onPrimary,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.onPrimary,
                          ),
                        ),
                      )
                    : const Text('Update Token'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _launchVercelTokens(BuildContext context) async {
    final uri = Uri.parse('https://vercel.com/account/tokens');
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $uri');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Vercel link'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showLogoutDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLow,
        title: const Text(
          'Sign Out',
          style: TextStyle(color: AppTheme.primary),
        ),
        content: const Text(
          'Are you sure you want to sign out of all connected accounts?',
          style: TextStyle(color: AppTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final subscriptionProvider = context.read<SubscriptionProvider>();
              await appState.logout(subscriptionProvider: subscriptionProvider);
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnboardingScreen(),
                  ),
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Sign Out All'),
          ),
        ],
      ),
    );
  }
}
