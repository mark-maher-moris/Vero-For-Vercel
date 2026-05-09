import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum WidgetLockReason { subscription, analytics }

class WidgetLockOverlay extends StatelessWidget {
  final WidgetLockReason reason;
  final VoidCallback? onUpgrade;
  final VoidCallback? onEnableAnalytics;

  const WidgetLockOverlay({
    super.key,
    required this.reason,
    this.onUpgrade,
    this.onEnableAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    final isSubscription = reason == WidgetLockReason.subscription;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.outlineVariant.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      isSubscription
                          ? Icons.lock_outline_rounded
                          : Icons.bar_chart_outlined,
                      color: AppTheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isSubscription ? 'Pro Required' : 'Analytics Disabled',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSubscription
                        ? 'Upgrade to Pro to use home screen widgets'
                        : 'Enable Vercel Web Analytics to use this widget',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: isSubscription ? onUpgrade : onEnableAnalytics,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.secondaryFixedDim],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        isSubscription ? 'Upgrade to Pro' : 'Enable Analytics',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
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
