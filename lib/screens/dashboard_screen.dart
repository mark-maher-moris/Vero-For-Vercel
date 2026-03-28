import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/project.dart';
import '../theme/app_theme.dart';
import '../widgets/project_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLow,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceContainerHigh,
              ),
              child: const Icon(Icons.person, size: 20, color: AppTheme.onSurface),
            ),
            const SizedBox(width: 12),
            const Text('Vero', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: AppTheme.onSurfaceVariant),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: AppTheme.onSurfaceVariant),
            onPressed: () => appState.logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: appState.fetchInitialData,
        color: AppTheme.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
          children: [
            _buildSearchField(),
            const SizedBox(height: 40),
            _buildProjectsGrid(appState.projects),
            const SizedBox(height: 40),
            _buildUsageOverview(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const TextField(
        style: TextStyle(color: AppTheme.onSurface),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search, color: AppTheme.onSurfaceVariant),
          hintText: 'Search projects...',
          hintStyle: TextStyle(color: AppTheme.onSurfaceVariant),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildProjectsGrid(List<Project> projects) {
    if (projects.isEmpty) {
      return const Center(
        child: Text('No projects found.', style: TextStyle(color: AppTheme.onSurfaceVariant)),
      );
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1, // Let's make it list-like on mobile, or grid on tablet
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        childAspectRatio: 1.5,
      ),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        return ProjectCard(project: projects[index]);
      },
    );
  }

  Widget _buildUsageOverview() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'USAGE SUMMARY',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '1.2M',
                      style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: -1.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'REQUESTS / 30D',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '84.2%',
                      style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: -1.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'BANDWIDTH',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
