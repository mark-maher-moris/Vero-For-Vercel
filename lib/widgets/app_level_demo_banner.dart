import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_theme.dart';
import '../services/superwall_service.dart';

class AppLevelDemoBanner extends StatefulWidget {
  const AppLevelDemoBanner({super.key});

  @override
  State<AppLevelDemoBanner> createState() => _AppLevelDemoBannerState();
}

class _AppLevelDemoBannerState extends State<AppLevelDemoBanner> {
  late DateTime _deadline;
  Timer? _timer;
  String _countdown = '36:00:00';

  @override
  void initState() {
    super.initState();
    _deadline = DateTime.now().add(const Duration(hours: 36));
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final difference = _deadline.difference(now);

    if (difference.isNegative) {
      setState(() {
        _countdown = '00:00:00';
      });
      return;
    }

    final hours = difference.inHours.toString().padLeft(2, '0');
    final minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');

    setState(() {
      _countdown = '$hours:$minutes:$seconds';
    });
  }

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Limited time lifetime deal - upgrade now, offer ends in',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _countdown,
                          style: const TextStyle(
                            color: Color(0xFF0070F3),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
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
