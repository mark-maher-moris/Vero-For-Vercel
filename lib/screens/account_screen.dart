import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/superwall_service.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';
import '../providers/subscription_provider.dart';
import '../widgets/demo_mode_banners.dart';
import 'domains_dns_screen.dart';
import 'team_access_screen.dart';
import 'onboarding_screen.dart';

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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
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
                borderRadius: BorderRadius.circular(2),
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
                  borderRadius: BorderRadius.circular(2),
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
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Icon(
                        Icons.star,
                        color: AppTheme.onPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Upgrade to Pro',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Unlock all features',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        // Print subscription debug data
                        final supportId = await SuperwallService().getUserId();
                        final entitlements = await SuperwallService().getEntitlements();
                        final customerInfo = await SuperwallService().getCustomerInfo();
                        if (kDebugMode) {
                          print('========== UPGRADE BUTTON CLICKED - DEBUG DATA ==========');
                          print('Subscription Status:');
                          print('  - isPro: ${subscriptionProvider.isPro}');
                          print('  - hasActiveSubscription: ${subscriptionProvider.hasActiveSubscription}');
                          print('  - isLoading: ${subscriptionProvider.isLoading}');
                          print('  - errorMessage: ${subscriptionProvider.errorMessage}');
                          print('');
                          print('Superwall Service Data:');
                          print('  - isInitialized: ${SuperwallService().isInitialized}');
                          print('  - hasActiveSubscription: ${SuperwallService().hasActiveSubscription}');
                          print('  - supportId/userId: $supportId');
                          print('');
                          print('Entitlements:');
                          print('  - active: ${entitlements.active.isEmpty ? "(none)" : entitlements.active.map((e) => "${e.id} (products: ${e.productIds.join(",")})").join(", ")}');
                          print('  - inactive: ${entitlements.inactive.isEmpty ? "(none)" : entitlements.inactive.map((e) => e.id).join(", ")}');
                          print('  - all: ${entitlements.all.map((e) => e.id).join(", ")}');
                          print('');
                          print('Subscriptions (Products):');
                          if (customerInfo.subscriptions.isEmpty) {
                            print('  (no subscriptions)');
                          } else {
                            for (final sub in customerInfo.subscriptions) {
                              print('  - ${sub.productId}: active=${sub.isActive}, willRenew=${sub.willRenew}, store=${sub.store}');
                            }
                          }
                          print('=========================================================');
                        }
                        
                        subscriptionProvider.showPaywall();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
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
                  icon: Icons.vpn_key,
                  title: 'API Token',
                  subtitle: 'Change token',
                  onTap: () => _showChangeTokenDialog(context),
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
                borderRadius: BorderRadius.circular(2),
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
                  _buildCopyableInfoRow('Support ID', _supportId, _copySupportId),
                  const Divider(height: 24),
                  _buildRestorePurchasesButton(),
                  const Divider(height: 24),
                  _buildReplayOnboardingButton(context),
                ]
                )
            ),

            const SizedBox(height: 32),

            // Contact Us Section
            GestureDetector(
              onTap: () => _launchEmail(context),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(2),
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
                        Icon(
                          Icons.email,
                          color: AppTheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Contact Us',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
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
                        Icon(
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

  void _launchEmail(BuildContext context) async {
    final uri = Uri.parse('mailto:hi@buildagon.com');
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $uri');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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
          borderRadius: BorderRadius.circular(2),
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
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.restore,
                size: 18,
                color: AppTheme.primary,
              ),
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
      await SuperwallService().restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchases restored successfully'),
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
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.replay,
                size: 18,
                color: AppTheme.primary,
              ),
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
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  void _showChangeTokenDialog(BuildContext context) {
    final TextEditingController tokenController = TextEditingController();
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
                      borderRadius: BorderRadius.circular(2),
                      borderSide: BorderSide.none,
                    ),
                    errorText: errorMessage,
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
                onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
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
                        try {
                          await appState.login(token);

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
                                  content: Text('API token updated successfully'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          setDialogState(() {
                            isLoading = false;
                            errorMessage = 'Invalid token. Please check and try again.';
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
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.onPrimary),
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
          SnackBar(
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
            onPressed: () async {
              Navigator.pop(context);
              final subscriptionProvider = context.read<SubscriptionProvider>();
              await appState.logout(subscriptionProvider: subscriptionProvider);
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                  (route) => false,
                );
              }
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
            onPressed: () async {
              Navigator.pop(context);
              final subscriptionProvider = context.read<SubscriptionProvider>();
              await appState.disconnectFromVercel(subscriptionProvider: subscriptionProvider);
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const OnboardingScreen()),
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
}
