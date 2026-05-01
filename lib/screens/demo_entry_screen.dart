import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../providers/subscription_provider.dart';
import '../services/superwall_service.dart';
import '../theme/app_theme.dart';

class DemoEntryScreen extends StatefulWidget {
  const DemoEntryScreen({super.key});

  @override
  State<DemoEntryScreen> createState() => _DemoEntryScreenState();
}

class _DemoEntryScreenState extends State<DemoEntryScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Track demo entry screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SuperwallService().trackScreenView('demo_entry');
    });
  }

  Future<void> _handleTestWithDemoOrUpgrade() async {
    setState(() => _isLoading = true);
    
    // Track the action
    SuperwallService().trackUserAction('test_or_upgrade_clicked', context: 'demo_entry');
    
    try {
      // The user wants a single button "Test with Demo Data or upgrade"
      // We will enter demo mode automatically, but also show them they can upgrade later.
      // Or we can show a paywall first? 
      // The request says: "Test with Demo Data or upgrade and then navigate user to the app itself to test with demo data"
      // This implies clicking the button goes to the app with demo data.
      
      await context.read<AppState>().enterDemoMode();
      
      if (mounted && kDebugMode) {
        print('[DemoEntryScreen] Entered demo mode, navigation handled by Consumer');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load demo data: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // App Logo or Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.rocket_launch,
                  size: 64,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Experience Vero',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                  letterSpacing: -1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Explore all features of Vero for Vercel using curated demo data. Ready to manage your own projects? Upgrade to Pro anytime.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // The main button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleTestWithDemoOrUpgrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'Test with Demo Data',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
