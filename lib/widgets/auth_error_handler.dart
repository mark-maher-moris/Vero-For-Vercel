import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/app_state.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_theme.dart';

/// A wrapper widget that listens for authentication errors globally
/// and shows a dialog + redirects to login when the token is invalid/expired
class AuthErrorHandler extends StatefulWidget {
  final Widget child;

  const AuthErrorHandler({
    super.key,
    required this.child,
  });

  @override
  State<AuthErrorHandler> createState() => _AuthErrorHandlerState();
}

class _AuthErrorHandlerState extends State<AuthErrorHandler> {
  StreamSubscription<AuthErrorEvent>? _authErrorSubscription;
  bool _isShowingDialog = false;

  @override
  void initState() {
    super.initState();
    _subscribeToAuthErrors();
  }

  @override
  void dispose() {
    _authErrorSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToAuthErrors() {
    _authErrorSubscription = authErrorStream.listen((event) {
      if (event.isUnauthorized || event.isForbidden) {
        _handleAuthError(event);
      }
    });
  }

  void _handleAuthError(AuthErrorEvent event) {
    // Prevent showing multiple dialogs
    if (_isShowingDialog) return;

    final context = this.context;
    if (!mounted) return;

    final appState = context.read<AppState>();

    // Only handle if user is currently authenticated
    // (prevents showing dialog during initial failed login attempts)
    if (!appState.isAuthenticated) return;

    _isShowingDialog = true;

    // Show the session expired dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        title: Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: AppTheme.error,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('Session Expired'),
          ],
        ),
        content: Text(
          'Your Vercel access token has expired or is no longer valid. Please log in again to continue.',
          style: TextStyle(
            color: AppTheme.onSurface.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              _isShowingDialog = false;

              // Get subscription provider for logout cleanup
              final subscriptionProvider =
                  context.read<SubscriptionProvider>();

              // Logout and clear the invalid token
              await appState.logout(subscriptionProvider: subscriptionProvider);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text(
              'LOG IN AGAIN',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
