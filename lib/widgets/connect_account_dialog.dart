import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';
import '../providers/subscription_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class ConnectAccountDialog extends StatefulWidget {
  final VoidCallback? onAccountConnected;
  final String? replaceAccountId;
  final String? customTitle;
  final String? customSubtitle;
  final String? customButtonText;

  const ConnectAccountDialog({
    super.key,
    this.onAccountConnected,
    this.replaceAccountId,
    this.customTitle,
    this.customSubtitle,
    this.customButtonText,
  });

  static Future<bool?> show(
    BuildContext context, {
    VoidCallback? onAccountConnected,
    String? replaceAccountId,
    String? customTitle,
    String? customSubtitle,
    String? customButtonText,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConnectAccountDialog(
        onAccountConnected: onAccountConnected,
        replaceAccountId: replaceAccountId,
        customTitle: customTitle,
        customSubtitle: customSubtitle,
        customButtonText: customButtonText,
      ),
    );
  }

  @override
  State<ConnectAccountDialog> createState() => _ConnectAccountDialogState();
}

class _ConnectAccountDialogState extends State<ConnectAccountDialog> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _teamController = TextEditingController();
  final FocusNode _teamFocusNode = FocusNode();
  bool _showTeamField = false;
  bool _isLoading = false;
  bool _obscureText = true;
  String? _errorMessage;

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

  Future<void> _handleConnect() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your Vercel personal access token.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final appState = context.read<AppState>();
    final subscription = context.read<SubscriptionProvider>();
    final isAdditionalAccount =
        widget.replaceAccountId == null && appState.accounts.isNotEmpty;

    if (isAdditionalAccount) {
      final canConnect = await subscription.authorizeAdditionalAccount(
        currentAccountCount: appState.accountCount,
      );
      if (!canConnect) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                subscription.errorMessage ??
                'The additional-account purchase is required to connect another Vercel account.';
          });
        }
        return;
      }
    } else if (!subscription.hasActiveSubscription) {
      final isPro = await subscription.showPaywall();
      if (!isPro && !subscription.hasActiveSubscription) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'A Pro subscription is required to connect a real Vercel account.';
          });
        }
        return;
      }
    }

    try {
      await appState.connectNewAccount(
        token,
        teamId: _teamController.text.trim().isNotEmpty
            ? _teamController.text.trim()
            : null,
        replaceAccountId: widget.replaceAccountId,
        subscriptionProvider: subscription,
        isAdditionalAccount: isAdditionalAccount,
      );

      if (mounted) {
        widget.onAccountConnected?.call();
        Navigator.of(context).pop(true);
        final username = appState.activeAccount?.username ?? "account";
        final isReplacement = widget.replaceAccountId != null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  isReplacement
                      ? 'Token updated for @$username successfully!'
                      : 'Connected @$username successfully!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade800,
            duration: const Duration(seconds: 3),
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
    return Dialog(
      backgroundColor: AppTheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_link,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.customTitle ??
                              (widget.replaceAccountId != null
                                  ? 'Update Vercel Token'
                                  : 'Connect Vercel Account'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.customSubtitle ??
                              (widget.replaceAccountId != null
                                  ? 'Replace current token with full-access token'
                                  : 'Add another account to switch anytime'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Token Field
              const Text(
                'Personal Access Token',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _tokenController,
                obscureText: _obscureText,
                enabled: !_isLoading,
                style: const TextStyle(color: AppTheme.primary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Paste token from Vercel...',
                  hintStyle: TextStyle(
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: AppTheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: AppTheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: AppTheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: AppTheme.primary),
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 18,
                          color: AppTheme.onSurfaceVariant,
                        ),
                        onPressed: () =>
                            setState(() => _obscureText = !_obscureText),
                        tooltip: _obscureText ? 'Show token' : 'Hide token',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.content_paste,
                          size: 18,
                          color: AppTheme.primary,
                        ),
                        onPressed: _pasteFromClipboard,
                        tooltip: 'Paste from clipboard',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Team ID or Slug Field (Conditionally shown for team-scoped tokens)
              if (_showTeamField) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Team ID or Slug',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showTeamField = false;
                          _teamController.clear();
                        });
                      },
                      child: Text(
                        'Hide',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _teamController,
                  focusNode: _teamFocusNode,
                  enabled: !_isLoading,
                  style: const TextStyle(color: AppTheme.primary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Enter team ID or slug',
                    hintStyle: TextStyle(
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: AppTheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: AppTheme.outlineVariant.withValues(alpha: 0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: AppTheme.outlineVariant.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: AppTheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ] else ...[
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showTeamField = true;
                    });
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (mounted) _teamFocusNode.requestFocus();
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.group_work_outlined,
                          size: 14,
                          color: AppTheme.primary.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Using a team-scoped token?',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary.withValues(alpha: 0.85),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Helper link
              GestureDetector(
                onTap: _launchVercelTokens,
                child: Row(
                  children: [
                    Text(
                      'Create token at vercel.com/account/settings/tokens',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primary.withValues(alpha: 0.85),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.open_in_new,
                      size: 12,
                      color: AppTheme.primary.withValues(alpha: 0.85),
                    ),
                  ],
                ),
              ),

              // Error Display
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppTheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.error,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
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

              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppTheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleConnect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.onPrimary,
                              ),
                            ),
                          )
                        : Text(
                            widget.customButtonText ??
                                (widget.replaceAccountId != null
                                    ? 'Update Token'
                                    : 'Connect Account'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
