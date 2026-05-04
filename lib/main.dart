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
import 'widgets/auth_error_handler.dart';
import 'widgets/app_level_demo_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  
  // Initialize Superwall SDK
  await SuperwallService().initialize();
  
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

class VeroApp extends StatelessWidget {
  const VeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vero For Vercel',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
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
            if (appState.isAuthenticated) {
              return const MainScreen();
            }
            // Show onboarding first, then demo entry
            if (!appState.hasCompletedOnboarding) {
              return const OnboardingScreen();
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
