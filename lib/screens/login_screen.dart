import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/app_state.dart';
import '../services/superwall_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  final _tokenController = TextEditingController();
  bool _hasToken = false;

  @override
  void initState() {
    super.initState();
    // Track login screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SuperwallService().trackScreenView('login');
    });
    _tokenController.addListener(_onTokenChanged);
  }

  void _onTokenChanged() {
    setState(() {
      _hasToken = _tokenController.text.isNotEmpty;
    });
  }

  Future<void> _pasteToken() async {
    final clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData?.text != null) {
      _tokenController.text = clipboardData!.text!;
    }
  }

  @override
  void dispose() {
    _tokenController.removeListener(_onTokenChanged);
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _handleTokenLogin() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a token'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Track login attempt
    SuperwallService().trackUserAction('login_attempt', context: 'login');

    try {
      await context.read<AppState>().login(token);
      if (mounted) {
        if (kDebugMode) print('[LoginScreen] Login successful, AppState.isAuthenticated should trigger navigation');
      }
    } catch (e) {
      if (mounted) {
        if (kDebugMode) print('[LoginScreen] Login failed with error: $e');
        // Track login error
        SuperwallService().trackError('login_failed', e.toString());
        _showErrorDialog(
          error: e.toString(),
          location: 'Token authentication failed',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleTryDemo() async {
    setState(() => _isLoading = true);
    SuperwallService().trackUserAction('try_demo_mode', context: 'login');
    try {
      await context.read<AppState>().enterDemoMode();
      if (mounted && kDebugMode) {
        print('[LoginScreen] Entered demo mode, navigation handled by Consumer');
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

  void _showErrorDialog({required String error, required String location}) {
    final fullErrorDetails = '''Error: $error
Location: Login Screen - $location
Time: ${DateTime.now().toIso8601String()}
App: VERO For Vercel''';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: AppTheme.error),
              const SizedBox(width: 8),
              const Text('Authentication Error'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We encountered an issue while connecting to your Vercel account:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorContainer.withOpacity(0.1),
                    border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    fullErrorDetails,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppTheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap and hold the error above to copy it, or use the Copy button below.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: fullErrorDetails));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error details copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy'),
            ),
            TextButton.icon(
              onPressed: () {
                _sendErrorEmail(fullErrorDetails);
              },
              icon: const Icon(Icons.email, size: 18),
              label: const Text('Email Support'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.onPrimary,
              ),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendErrorEmail(String errorDetails) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'hi@buildagon.com',
      queryParameters: {
        'subject': 'VERO App - Authentication Error Report',
        'body': "Hello VERO Support Team,\n\nI encountered an error while trying to connect my Vercel account. Here are the details:\n\n$errorDetails\n\nPlease assist me with resolving this issue.\n\nThank you!",
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open email app. Please copy the error and email us at hi@buildagon.com'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening email: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final navigator = Navigator.of(context);
            final canPop = navigator.canPop();
            
            if (canPop) {
              // Pop first to avoid race condition with Consumer rebuild
              navigator.pop();
              // Then reset onboarding state after navigation
              context.read<AppState>().resetOnboarding();
            } else {
              context.read<AppState>().resetOnboarding();
            }
          },
        ),
        actions: [
          IconButton(
            icon: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.workspace_premium,
                color: AppTheme.primary,
                size: 28,
              ),
            ),
            tooltip: 'Upgrade',
            onPressed: () {
              SuperwallService().presentPaywall();
            },
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Image.asset(
                'assets/logo.png',
                height: 80,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              Text(
                'Connect Your Vercel Account',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              TextField(
                controller: _tokenController,
                decoration: InputDecoration(
                  labelText: 'Personal Access Token',
                  hintText: 'Paste token from vercel.com/account/settings/tokens',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(_hasToken ? Icons.clear : Icons.content_paste),
                    onPressed: _hasToken
                        ? () => _tokenController.clear()
                        : _pasteToken,
                  ),
                ),
                obscureText: true,
                maxLines: 1,
                enabled: !_isLoading,
                readOnly: _hasToken,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: InkWell(
                      onTap: () async {
                        final uri = Uri.parse('https://vercel.com/account/settings/tokens');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      onLongPress: () {
                        Clipboard.setData(const ClipboardData(text: 'https://vercel.com/account/settings/tokens'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Link copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Text(
                        'Get your token from vercel.com/account/settings/tokens',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    color: AppTheme.primary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: 'https://vercel.com/account/settings/tokens'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.share, size: 16),
                    color: AppTheme.primary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Share.share('https://vercel.com/account/settings/tokens');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleTokenLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
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
                            'CONNECT',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: AppTheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _isLoading ? null : _handleTryDemo,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: BorderSide(
                    color: AppTheme.primary.withOpacity(0.5),
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_circle_outline, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'TRY WITH DEMO DATA',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Explore the app with realistic demo projects. No token required.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse('https://github.com/mark-maher-moris/Vero-For-Vercel');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          'https://cdn-icons-png.flaticon.com/512/25/25231.png',
                          height: 20,
                          width: 20,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Review the app code',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Your Vercel token doesn't leave your device. It is stored locally only.",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),)
    );
  }
}
