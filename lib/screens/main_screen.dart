import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'activity_feed_screen.dart';
import 'deploy_new_project_screen.dart';
import 'usage_billing_screen.dart';
import 'settings_env_vars_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1;

  final List<Widget> _screens = [
    const ActivityFeedScreen(),
    const DashboardScreen(),
    const DeployNewProjectScreen(),
    const UsageBillingScreen(),
    const SettingsEnvVarsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          _screens[_currentIndex],
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.only(top: 12, bottom: 24, left: 16, right: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow.withValues(alpha: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.onSurface.withValues(alpha: 0.06),
                        blurRadius: 40,
                        offset: const Offset(0, -4),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavItem(
                        icon: Icons.home_outlined,
                        label: 'Home',
                        isActive: _currentIndex == 0,
                        onTap: () => setState(() => _currentIndex = 0),
                      ),
                      _NavItem(
                        icon: Icons.grid_view,
                        label: 'Projects',
                        isActive: _currentIndex == 1,
                        onTap: () => setState(() => _currentIndex = 1),
                      ),
                      _NavItem(
                        icon: Icons.add_circle_outline,
                        label: 'Deploy',
                        isActive: _currentIndex == 2,
                        onTap: () => setState(() => _currentIndex = 2),
                      ),
                      _NavItem(
                        icon: Icons.bar_chart,
                        label: 'Usage',
                        isActive: _currentIndex == 3,
                        onTap: () => setState(() => _currentIndex = 3),
                      ),
                      _NavItem(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        isActive: _currentIndex == 4,
                        onTap: () => setState(() => _currentIndex = 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.primary : AppTheme.onSurfaceVariant.withValues(alpha: 0.6);
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.05,
              color: color,
            ),
          ),
          if (isActive) ...[
            const SizedBox(height: 4),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
          ]
        ],
      ),
    );
  }
}
