import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_state.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_theme.dart';
import '../services/superwall_service.dart';
import '../screens/demo_entry_screen.dart';
import '../screens/login_screen.dart';

class AppLevelDemoBanner extends StatefulWidget {
  final Widget? currentScreen;
  
  const AppLevelDemoBanner({super.key, this.currentScreen});

  @override
  State<AppLevelDemoBanner> createState() => _AppLevelDemoBannerState();
}

class _AppLevelDemoBannerState extends State<AppLevelDemoBanner> {
  static const String _firstLaunchKey = 'first_launch_timestamp';
  late DateTime _deadline;
  Timer? _timer;
  String _countdown = '36:00:00';
  bool _isOfferExpired = false;

  @override
  void initState() {
    super.initState();
    _initializeDeadline();
  }

  Future<void> _initializeDeadline() async {
    final prefs = await SharedPreferences.getInstance();
    final firstLaunchTimestamp = prefs.getInt(_firstLaunchKey);

    if (firstLaunchTimestamp == null) {
      // First time launching the app - store the timestamp
      await prefs.setInt(_firstLaunchKey, DateTime.now().millisecondsSinceEpoch);
      _deadline = DateTime.now().add(const Duration(hours: 36));
    } else {
      // Calculate deadline from stored first launch timestamp
      _deadline = DateTime.fromMillisecondsSinceEpoch(firstLaunchTimestamp).add(const Duration(hours: 36));
    }

    // Check if offer has expired
    if (DateTime.now().isAfter(_deadline)) {
      setState(() {
        _isOfferExpired = true;
      });
    } else {
      _startCountdown();
    }
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

    // Don't show if user has an active subscription
    if (subscription.hasActiveSubscription) {
      return const SizedBox.shrink();
    }

    // Check if we're on the DemoEntryScreen or LoginScreen by checking widget type
    final currentScreen = widget.currentScreen;
    final isDemoEntryScreen = currentScreen is DemoEntryScreen;
    final isLoginScreen = currentScreen is LoginScreen;

    // Show banner if:
    // 1. User is in demo mode (authenticated with demo data), OR
    // 2. User is on DemoEntryScreen, OR
    // 3. User is on LoginScreen and doesn't have a subscription
    final shouldShowBanner = (appState.isAuthenticated && appState.isDemoMode) ||
        isDemoEntryScreen ||
        isLoginScreen;

    if (!shouldShowBanner) {
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
                        Text(
                          _isOfferExpired
                              ? 'Upgrade now and unlock the full app'
                              : 'Limited time lifetime deal - upgrade now, offer ends in',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (!_isOfferExpired) ...[
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
