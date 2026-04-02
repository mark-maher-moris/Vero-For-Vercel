import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../services/superwall_service.dart';
import '../theme/app_theme.dart';

/// Screen for managing subscriptions and displaying paywall
/// Uses Superwall Paywall UI or custom UI depending on configuration
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Track subscription screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subscription = context.read<SubscriptionProvider>();
      SuperwallService().trackScreenView('subscription', additionalProps: {
        'is_pro': subscription.isPro,
        'has_error': subscription.hasError,
      });
    });
    
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
          if (subscription.isLoading) {
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

          // Show upgrade button that triggers Superwall paywall
          return _buildUpgradeButton(context, subscription);
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
          _buildStatusCard(),
          const SizedBox(height: 32),

          // Benefits
          _buildBenefitsList(context),
          const SizedBox(height: 32),

          // Restore/Manage Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _restorePurchases(context, subscription),
              icon: const Icon(Icons.restore),
              label: const Text('Restore Purchases'),
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

  Widget _buildStatusCard() {
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
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.info_outline,
            'Management',
            'Manage in App Store / Play Store',
            Colors.white70,
          ),
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

  Widget _buildBenefitsList(BuildContext context) {
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

  Widget _buildUpgradeButton(BuildContext context, SubscriptionProvider subscription) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_open,
              color: AppTheme.primary,
              size: 64,
            ),
            const SizedBox(height: 24),
            const Text(
              'Upgrade to Vero Pro',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unlock unlimited projects, priority deployments, and more premium features.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: subscription.isLoading
                    ? null
                    : () => _openPaywall(context, subscription),
                icon: const Icon(Icons.star),
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
            TextButton(
              onPressed: subscription.isLoading
                  ? null
                  : () => _restorePurchases(context, subscription),
              child: const Text(
                'Restore Purchases',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPaywall(
    BuildContext context,
    SubscriptionProvider subscription,
  ) async {
    // Track paywall open attempt
    SuperwallService().trackSubscriptionEvent('paywall_opened', properties: {
      'context': 'subscription_screen',
    });
    
    final hasPro = await subscription.showPaywall();
    
    if (hasPro && context.mounted) {
      // Track successful subscription
      SuperwallService().trackSubscriptionEvent('purchase_complete', properties: {
        'context': 'subscription_screen',
      });
      
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
    // Track restore attempt
    SuperwallService().trackSubscriptionEvent('restore_started', properties: {
      'context': 'subscription_screen',
    });
    
    final hasPro = await subscription.restorePurchases();
    
    if (context.mounted) {
      if (hasPro) {
        // Track successful restore
        SuperwallService().trackSubscriptionEvent('restore_complete', properties: {
          'context': 'subscription_screen',
          'found_subscription': true,
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your Vero Pro subscription has been restored!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Track failed restore
        SuperwallService().trackSubscriptionEvent('restore_complete', properties: {
          'context': 'subscription_screen',
          'found_subscription': false,
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No previous purchases found.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}
