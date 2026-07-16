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
import 'widgets/auth_error_handler.dart';
import 'widgets/app_level_demo_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

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
  Uri? _pendingWidgetConfigUri;
  bool _isFlushingWidgetConfigRoute = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _widgetService.widgetClicked.listen((uri) {
      if (uri != null) {
        _handleWidgetDeepLink(uri);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialWidgetLaunch();
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
    if (appState.isAuthenticated || appState.isDemoMode) {
      appState.refreshWidgets();
    }
  }

  Future<void> _checkInitialWidgetLaunch() async {
    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (uri != null) {
      _handleWidgetDeepLink(uri);
    }
  }

  void _handleWidgetDeepLink(Uri uri) {
    if (kDebugMode) {
      print('[WidgetDeepLink] $uri');
    }
    if (uri.scheme == 'vero' &&
        uri.host == 'widget' &&
        uri.path == '/configure') {
      _pendingWidgetConfigUri = uri;
      _flushPendingWidgetConfigRoute();
    }
  }

  void _flushPendingWidgetConfigRoute() {
    if (_pendingWidgetConfigUri == null || _isFlushingWidgetConfigRoute) {
      return;
    }

    _isFlushingWidgetConfigRoute = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isFlushingWidgetConfigRoute = false;
      final pendingUri = _pendingWidgetConfigUri;
      if (pendingUri == null) return;

      final navigator = _navigatorKey.currentState;
      final context = _navigatorKey.currentContext;
      if (navigator == null || context == null) {
        _flushPendingWidgetConfigRoute();
        return;
      }

      final appState = context.read<AppState>();
      if (appState.isLoading) {
        _flushPendingWidgetConfigRoute();
        return;
      }

      _pendingWidgetConfigUri = null;
      navigator.push(
        MaterialPageRoute(builder: (_) => const WidgetConfigScreen()),
      );
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
            _flushPendingWidgetConfigRoute();
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
