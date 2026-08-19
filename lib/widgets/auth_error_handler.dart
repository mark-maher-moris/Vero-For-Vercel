import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../providers/app_state.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_theme.dart';

/// A wrapper widget that handles token expiration and invalidation gracefully.
/// If multiple accounts exist, it isolates the expiration to the active account,
/// allowing in-place token update or switching accounts without wiping the entire app state.
class AuthErrorHandler extends StatefulWidget {
  final Widget child;

  const AuthErrorHandler({super.key, required this.child});

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
      if (event.isUnauthorized) {
        _handleAuthError(event);
      }
    });
  }

  void _handleAuthError(AuthErrorEvent event) {
    // Prevent showing multiple dialogs concurrently
    if (_isShowingDialog) return;

    final context = this.context;
    if (!mounted) return;

    final appState = context.read<AppState>();

    // Only handle if user is currently authenticated
    if (!appState.isAuthenticated) return;

    final activeAccount = appState.activeAccount;
    final hasMultipleAccounts = appState.accounts.length > 1;
    final accountUsername = activeAccount?.username ?? 'account';
    final accountId = activeAccount?.id;

    _isShowingDialog = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: AppTheme.error, size: 28),
            const SizedBox(width: 12),
            const Text('Session Expired'),
          ],
        ),
        content: Text(
          hasMultipleAccounts
              ? 'The Vercel access token for @$accountUsername has expired or is no longer valid.\n\nYou can update the token, switch to another connected account, or disconnect this account.'
              : 'Your Vercel access token has expired or is no longer valid. Please update your token or log in again to continue.',
          style: TextStyle(color: AppTheme.onSurface.withValues(alpha: 0.8)),
        ),
        actions: [
          if (hasMultipleAccounts && accountId != null) ...[
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                _isShowingDialog = false;

                final subscriptionProvider =
                    context.read<SubscriptionProvider>();
                // Disconnect only the expired account and switch to another connected account
                await appState.disconnectAccount(
                  accountId,
                  subscriptionProvider: subscriptionProvider,
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.onSurfaceVariant,
              ),
              child: const Text('SWITCH ACCOUNT'),
            ),
          ] else ...[
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                _isShowingDialog = false;

                final subscriptionProvider =
                    context.read<SubscriptionProvider>();
                await appState.logout(
                  subscriptionProvider: subscriptionProvider,
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.onSurfaceVariant,
              ),
              child: const Text('LOG IN AGAIN'),
            ),
          ],
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _isShowingDialog = false;

              if (accountId != null) {
                _showUpdateTokenDialog(
                  context,
                  accountId: accountId,
                  username: accountUsername,
                  teamScope: activeAccount?.teamScope,
                );
              } else {
                final subscriptionProvider =
                    context.read<SubscriptionProvider>();
                appState.logout(subscriptionProvider: subscriptionProvider);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: const Text(
              'UPDATE TOKEN',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateTokenDialog(
    BuildContext context, {
    required String accountId,
    required String username,
    String? teamScope,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _ReauthenticateDialog(
        accountId: accountId,
        username: username,
        initialTeamScope: teamScope,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _ReauthenticateDialog extends StatefulWidget {
  final String accountId;
  final String username;
  final String? initialTeamScope;

  const _ReauthenticateDialog({
    required this.accountId,
    required this.username,
    this.initialTeamScope,
  });

  @override
  State<_ReauthenticateDialog> createState() => _ReauthenticateDialogState();
}

class _ReauthenticateDialogState extends State<_ReauthenticateDialog> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _teamController = TextEditingController();
  final FocusNode _teamFocusNode = FocusNode();
  bool _showTeamField = false;
  bool _isLoading = false;
  bool _obscureText = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialTeamScope != null &&
        widget.initialTeamScope!.isNotEmpty) {
      _teamController.text = widget.initialTeamScope!;
      _showTeamField = true;
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _teamController.dispose();
    _teamFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _tokenController.text = data.text!.trim();
        _errorMessage = null;
      });
    }
  }

  Future<void> _launchVercelTokens() async {
    final uri = Uri.parse('https://vercel.com/account/settings/tokens');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _handleUpdate() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid Vercel token.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final appState = context.read<AppState>();
    final subscription = context.read<SubscriptionProvider>();

    try {
      await appState.updateAccountToken(
        widget.accountId,
        token,
        teamId: _teamController.text.trim().isNotEmpty
            ? _teamController.text.trim()
            : null,
        subscriptionProvider: subscription,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Updated token for @${widget.username} successfully!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade800,
          ),
        );
      }
    } on TeamScopeRequiredException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showTeamField = true;
          _errorMessage = e.message;
        });
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _teamFocusNode.requestFocus();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Re-authenticate Account'),
          const SizedBox(height: 4),
          Text(
            '@${widget.username}',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.primary,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a new Vercel Personal Access Token to continue using this account.',
              style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tokenController,
              obscureText: _obscureText,
              autocorrect: false,
              enableSuggestions: false,
              style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
              decoration: InputDecoration(
                labelText: 'New Access Token',
                hintText: 'Paste new token...',
                filled: true,
                fillColor: AppTheme.surfaceContainerLow,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureText = !_obscureText),
                      tooltip: _obscureText ? 'Show token' : 'Hide token',
                    ),
                    IconButton(
                      icon: const Icon(Icons.paste, size: 20),
                      onPressed: _pasteFromClipboard,
                      tooltip: 'Paste from clipboard',
                    ),
                  ],
                ),
              ),
            ),
            if (_showTeamField) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _teamController,
                focusNode: _teamFocusNode,
                autocorrect: false,
                enableSuggestions: false,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Team ID or Slug',
                  hintText: 'team_xxxxxxxx or my-team',
                  filled: true,
                  fillColor: AppTheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  prefixIcon: Icon(Icons.group_outlined, size: 20),
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                color: AppTheme.error.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.error,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppTheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            InkWell(
              onTap: _launchVercelTokens,
              child: const Row(
                children: [
                  Icon(Icons.open_in_new, size: 14, color: AppTheme.primary),
                  SizedBox(width: 6),
                  Text(
                    'Create token at vercel.com/account/settings/tokens',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.onSurfaceVariant,
          ),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleUpdate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'SAVE & RE-AUTHENTICATE',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}
