import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_theme.dart';

/// Screen for managing subscriptions and displaying paywall
/// Uses RevenueCat Paywall UI or custom UI depending on configuration
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text(
          'Vero Pro',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, subscription, child) {
          if (subscription.isLoading && subscription.offerings == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (subscription.hasError) {
            return _buildErrorState(context, subscription);
          }

          // If user has Pro, show Pro status
          if (subscription.isPro) {
            return _buildProStatus(context, subscription);
          }

          // Otherwise show upgrade options
          return _buildUpgradeOptions(context, subscription);
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, SubscriptionProvider subscription) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              subscription.errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => subscription.refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProStatus(BuildContext context, SubscriptionProvider subscription) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pro Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.black, size: 18),
                SizedBox(width: 8),
                Text(
                  'Vero Pro Active',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Status Card
          _buildStatusCard(subscription),
          const SizedBox(height: 32),

          // Benefits
          _buildBenefitsList(),
          const SizedBox(height: 32),

          // Manage Subscription Button
          if (Platform.isIOS || Platform.isAndroid)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showCustomerCenter(context, subscription),
                icon: const Icon(Icons.settings),
                label: const Text('Manage Subscription'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white30),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(SubscriptionProvider subscription) {
    final expirationDate = subscription.proExpirationDate;
    final willRenew = subscription.willRenew;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subscription Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.check_circle,
            'Status',
            'Active',
            Colors.green,
          ),
          if (expirationDate != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.calendar_today,
              expirationDate.isAfter(DateTime.now().add(const Duration(days: 365 * 50)))
                  ? 'Valid Until'
                  : willRenew ? 'Renews On' : 'Expires On',
              expirationDate.isAfter(DateTime.now().add(const Duration(days: 365 * 50)))
                  ? 'Lifetime'
                  : _formatDate(expirationDate),
              Colors.white70,
            ),
          ],
          if (!willRenew && expirationDate != null && 
              !expirationDate.isAfter(DateTime.now().add(const Duration(days: 365 * 50)))) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.info_outline,
              'Auto-Renewal',
              'Off - Will not renew',
              Colors.orange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color valueColor) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white54),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsList() {
    final benefits = [
      'Unlimited projects',
      'Priority deployments',
      'Advanced analytics',
      'Custom domains',
      'API access',
      'Priority support',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pro Benefits',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...benefits.map((benefit) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Icon(
                  Icons.check,
                  color: AppTheme.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                benefit,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildUpgradeOptions(BuildContext context, SubscriptionProvider subscription) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Upgrade to Vero Pro',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Unlock the full power of Vero for Vercel',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),

          // Benefits
          _buildBenefitsList(),
          const SizedBox(height: 48),

          // Upgrade Button - Opens RevenueCat Paywall
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: subscription.isLoading
                  ? null
                  : () => _openPaywall(context, subscription),
              icon: const Icon(Icons.lock_open),
              label: const Text(
                'Upgrade Now',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Restore Purchases
          Center(
            child: TextButton(
              onPressed: subscription.isLoading
                  ? null
                  : () => _restorePurchases(context, subscription),
              child: const Text(
                'Restore Purchases',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _openPaywall(
    BuildContext context,
    SubscriptionProvider subscription,
  ) async {
    final hasPro = await subscription.showPaywall();
    
    if (hasPro && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome to Vero Pro!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _restorePurchases(
    BuildContext context,
    SubscriptionProvider subscription,
  ) async {
    final hasPro = await subscription.restorePurchases();
    
    if (context.mounted) {
      if (hasPro) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your Vero Pro subscription has been restored!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No previous purchases found.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _showCustomerCenter(
    BuildContext context,
    SubscriptionProvider subscription,
  ) async {
    await subscription.showCustomerCenter();
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

// Platform stub for web compatibility
class Platform {
  static bool get isIOS => false;
  static bool get isAndroid => false;
  static bool get isMacOS => false;
  static bool get isWindows => false;
  static bool get isLinux => false;
  static bool get isFuchsia => false;
}
