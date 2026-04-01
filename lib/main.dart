import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'providers/app_state.dart';
import 'providers/subscription_provider.dart';
import 'services/revenue_cat_service.dart';
import 'services/superwall_service.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  
  // Initialize RevenueCat SDK
  await RevenueCatService().initialize();
  
  // Initialize Superwall SDK (with RevenueCat integration)
  await SuperwallService().initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
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
      home: Consumer<AppState>(
        builder: (context, appState, child) {
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
            // Show paywall for new authenticated users
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              try {
                await RevenueCatUI.presentPaywallIfNeeded('pro');
              } catch (e) {
                debugPrint('Paywall presentation error: $e');
              }
            });
            return const MainScreen();
          }
          // Show onboarding first, then login
          if (!appState.hasCompletedOnboarding) {
            return const OnboardingScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
