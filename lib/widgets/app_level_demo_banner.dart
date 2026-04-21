import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_theme.dart';
import '../services/superwall_service.dart';

class AppLevelDemoBanner extends StatelessWidget {
  const AppLevelDemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final subscription = context.watch<SubscriptionProvider>();

    // Only show if authenticated, in demo mode, and NOT actually subscribed
    if (!appState.isAuthenticated || 
        !appState.isDemoMode || 
        subscription.hasActiveSubscription) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.black,
      child: InkWell(
        onTap: () async {
          SuperwallService().trackUserAction(
            'app_level_demo_banner_tap',
            context: 'app_banner',
          );
          await subscription.showPaywall();
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF000000),
                const Color(0xFF0070F3).withValues(alpha: 0.15),
                const Color(0xFF000000),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.primary.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0070F3),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF0070F3),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'UPGRADE TO PRO TO UNLOCK ALL FEATURES',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Text(
                      'UPGRADE',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
