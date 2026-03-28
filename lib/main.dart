import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const VercelApp(),
    ),
  );
}

class VercelApp extends StatelessWidget {
  const VercelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vercel App',
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
            return const MainScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
