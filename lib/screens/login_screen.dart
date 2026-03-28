import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _handleOAuthLogin() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<AppState>().loginWithOAuth();
    } catch (e) {
      if (mounted) {
        // Don't show error if user just canceled
        if (e.toString().contains('CANCELED')) {
          setState(() => _isLoading = false);
          return;
        }
        setState(() {
          _error = 'Authentication failed: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.change_history, // Vercel Triangle placeholder
                size: 80,
                color: AppTheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'VERO',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorContainer.withOpacity(0.1),
                    border: Border.all(color: AppTheme.error.withOpacity(0.5)),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppTheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
              ],
              ElevatedButton(
                onPressed: _isLoading ? null : _handleOAuthLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero, // Brutalist sharp edges
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.onPrimary,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.login, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'CONNECT VERCEL ACCOUNT',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: AppTheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
              Text(
                'Securely connect your Vercel account to manage deployments, domains, and more.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
