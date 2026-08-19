import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'providers/subscription_provider.dart';
import 'services/superwall_service.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/demo_entry_screen.dart';
import 'screens/widget_config_screen.dart';
import 'services/widget_service.dart';
import 'services/local_notification_service.dart';
import 'services/whats_new_service.dart';
import 'widgets/auth_error_handler.dart';
import 'widgets/app_level_demo_banner.dart';
import 'widgets/account_switcher_bottom_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final localNotificationService = LocalNotificationService.instance;
  await localNotificationService.initialize();
  await localNotificationService.requestPermissions();

  // Initialize Superwall SDK
  await SuperwallService().initialize();

  await WidgetService().initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProxyProvider<AppState, SubscriptionProvider>(
          create: (context) =>
              SubscriptionProvider(appState: context.read<AppState>()),
          update: (_, appState, subscriptionProvider) =>
              subscriptionProvider ?? SubscriptionProvider(appState: appState),
        ),
      ],
      child: const VeroApp(),
    ),
  );
}

class VeroApp extends StatefulWidget {
  const VeroApp({super.key});

  @override
  State<VeroApp> createState() => _VeroAppState();
}

class _VeroAppState extends State<VeroApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final WidgetService _widgetService = WidgetService();
  final WhatsNewService _whatsNewService = WhatsNewService();
  Uri? _pendingDeepLinkUri;
  bool _isFlushingDeepLink = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Listen for notification taps (foreground / background)
    LocalNotificationService.instance.setOnNotificationTap((response) {
      final payload = response.payload;
      if (payload != null && payload.isNotEmpty) {
        final uri = Uri.tryParse(payload);
        if (uri != null) {
          _handleDeepLink(uri);
        }
      }
    });

    _widgetService.widgetClicked.listen((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialWidgetLaunch();
      _checkInitialNotificationLaunch();
      _checkWhatsNewNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final context = _navigatorKey.currentContext;
    if (context == null) return;
    final appState = context.read<AppState>();
    if ((appState.isAuthenticated || appState.isDemoMode) &&
        !appState.isLoading) {
      appState.refreshWidgets();
    }
    _checkWhatsNewNotifications();
  }

  Future<void> _checkWhatsNewNotifications() async {
    try {
      final isPro = await SuperwallService().getCurrentSubscriptionStatus();
      await _whatsNewService.checkAndDeliverWhatsNew(isProUser: isPro);
    } catch (e) {
      if (kDebugMode) {
        print('[VeroApp] Error checking What\'s New notifications: $e');
      }
    }
  }

  Future<void> _checkInitialWidgetLaunch() async {
    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (uri != null) {
      _handleDeepLink(uri);
    }
  }

  Future<void> _checkInitialNotificationLaunch() async {
    final response = await LocalNotificationService.instance.getNotificationAppLaunchDetails();
    if (response != null && response.payload != null && response.payload!.isNotEmpty) {
      final uri = Uri.tryParse(response.payload!);
      if (uri != null) {
        _handleDeepLink(uri);
      }
    }
  }

  void _handleDeepLink(Uri uri) {
    if (kDebugMode) {
      print('[DeepLink] $uri');
    }
    if (uri.scheme == 'vero') {
      _pendingDeepLinkUri = uri;
      _flushPendingDeepLink();
    }
  }

  void _flushPendingDeepLink() {
    if (_pendingDeepLinkUri == null || _isFlushingDeepLink) {
      return;
    }

    _isFlushingDeepLink = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isFlushingDeepLink = false;
      final pendingUri = _pendingDeepLinkUri;
      if (pendingUri == null) return;

      final navigator = _navigatorKey.currentState;
      final context = _navigatorKey.currentContext;
      if (navigator == null || context == null) {
        _flushPendingDeepLink();
        return;
      }

      final appState = context.read<AppState>();
      if (appState.isLoading) {
        _flushPendingDeepLink();
        return;
      }

      _pendingDeepLinkUri = null;

      if (pendingUri.host == 'widget' && pendingUri.path == '/configure') {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => WidgetConfigScreen(
              initialWidgetType: pendingUri.queryParameters['type'],
            ),
          ),
        );
      } else if (pendingUri.host == 'account' &&
          (pendingUri.path == '/switcher' || pendingUri.path.isEmpty)) {
        if (appState.isAuthenticated || appState.isDemoMode) {
          AccountSwitcherBottomSheet.show(context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vero For Vercel',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      builder: (context, child) {
        return Column(
          children: [
            AppLevelDemoBanner(currentScreen: child),
            Expanded(child: child!),
          ],
        );
      },
      home: AuthErrorHandler(
        child: Consumer2<AppState, SubscriptionProvider>(
          builder: (context, appState, subscription, child) {
            _flushPendingDeepLink();
            if (appState.isLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              );
            }

            // Show onboarding first (takes priority over authentication)
            if (!appState.hasCompletedOnboarding) {
              return const OnboardingScreen();
            }

            if (appState.isAuthenticated) {
              return const MainScreen();
            }

            // If the user is subscribed but not authenticated, they can see the login screen
            // to connect their real Vercel account.
            if (subscription.hasActiveSubscription) {
              return const LoginScreen();
            }

            return const DemoEntryScreen();
          },
        ),
      ),
    );
  }
}
