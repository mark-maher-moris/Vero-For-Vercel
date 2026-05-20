import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'providers/subscription_provider.dart';
import 'services/superwall_service.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/demo_entry_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/widget_config_screen.dart';
import 'services/widget_service.dart';
import 'widgets/auth_error_handler.dart';
import 'widgets/app_level_demo_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  
  // Initialize Superwall SDK
  await SuperwallService().initialize();
  
  // Initialize WidgetService (sets iOS App Group ID)
  await WidgetService().initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProxyProvider<AppState, SubscriptionProvider>(
          create: (context) => SubscriptionProvider(appState: context.read<AppState>()),
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

class _VeroAppState extends State<VeroApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final WidgetService _widgetService = WidgetService();

  @override
  void initState() {
    super.initState();
    _listenToWidgetClicks();
  }

  void _listenToWidgetClicks() {
    // Handle clicks when app is in foreground or background
    _widgetService.widgetClicked.listen((uri) {
      if (kDebugMode) {
        print('[WidgetDeepLink] Widget clicked (stream) - URI: $uri');
      }
      if (uri != null) {
        _handleWidgetDeepLink(uri);
      }
    });
  }

  void _handleWidgetDeepLink(Uri uri) {
    if (kDebugMode) {
      print('[WidgetDeepLink] Handling deep link: scheme=${uri.scheme}, path=${uri.path}, params=${uri.queryParameters}');
    }
    if (uri.scheme == 'vero' && uri.host == 'widget' && uri.path == '/configure') {
      final widgetType = uri.queryParameters['type'];
      if (kDebugMode) {
        print('[WidgetDeepLink] Widget type: $widgetType');
      }
      if (widgetType != null && _navigatorKey.currentState != null) {
        if (kDebugMode) {
          print('[WidgetDeepLink] Navigating to WidgetConfigScreen');
        }
        _navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => const WidgetConfigScreen(),
          ),
        );
      } else {
        if (kDebugMode) {
          print('[WidgetDeepLink] Cannot navigate - widgetType is null or navigator is null');
        }
      }
    } else {
      if (kDebugMode) {
        print('[WidgetDeepLink] URI does not match widget configure pattern');
      }
    }
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
            if (appState.isLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primary,
                  ),
                ),
              );
            }
            // Show onboarding first (takes priority over authentication)
            if (!appState.hasCompletedOnboarding) {
              return const OnboardingScreen();
            }
            if (appState.isAuthenticated) {
              if (subscription.isPro) {
                return const MainScreen();
              }
              return const SubscriptionScreen();
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
