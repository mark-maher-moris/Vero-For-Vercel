import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../providers/subscription_provider.dart';
import '../services/superwall_service.dart';
import '../theme/app_theme.dart';

/// Upgrade CTA card shown while the user is browsing demo data.
///
/// In demo mode we don't show the regular project blur / Pro gates, so this
/// card replaces them as the primary upgrade CTA. Tapping it opens the
/// Superwall paywall.
class DemoUpgradeCard extends StatelessWidget {
  const DemoUpgradeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final subscription = context.watch<SubscriptionProvider>();
    if (subscription.isPro) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withOpacity(0.18),
            AppTheme.primary.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: AppTheme.primary.withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: AppTheme.onPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
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
                  'Unlock unlimited projects, advanced logs, '
                  'team features and priority support.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () async {
              SuperwallService().trackUserAction(
                'demo_upgrade_tap',
                context: 'demo_upgrade_card',
              );
              await subscription.showPaywall();
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
    );
  }
}

/// Banner shown inside home / settings while in demo mode that prompts the
/// user to connect a real Vercel account. Tapping it exits demo mode, which
/// clears demo data and lets the Consumer in `main.dart` render the login
/// screen – no manual navigation required.
class ConnectRealAccountBanner extends StatelessWidget {
  /// A short, screen-appropriate label. Defaults to "Connect real account".
  final String title;
  final String subtitle;
  final IconData icon;

  const ConnectRealAccountBanner({
    super.key,
    this.title = 'Connect real account',
    this.subtitle = 'You are browsing demo data. Add your Vercel token to manage your own projects.',
    this.icon = Icons.link,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (!appState.isDemoMode) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(2),
        onTap: () => _handleConnect(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: AppTheme.primary.withOpacity(0.35),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                      
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.primary,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleConnect(BuildContext context) async {
    SuperwallService().trackUserAction(
      'demo_connect_real_tap',
      context: 'demo_banner',
    );

    final appState = context.read<AppState>();
    final subscription = context.read<SubscriptionProvider>();

    // Pop any nested screens so the Consumer in main.dart swaps the root
    // widget cleanly to the LoginScreen – avoids navigation stack conflicts.
    Navigator.of(context).popUntil((route) => route.isFirst);

    await appState.exitDemoMode(subscriptionProvider: subscription);
  }
}
