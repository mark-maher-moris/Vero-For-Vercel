import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../services/widget_service.dart';
import '../models/project.dart';
import '../widgets/video_player_sheet.dart';

enum _WidgetKind {
  logs('logs', 'Logs', Icons.terminal, false),
  analytics('analytics', 'Analytics', Icons.analytics_outlined, true),
  countries('countries', 'Countries', Icons.public, true),
  users('users', 'Users', Icons.people_alt_outlined, true);

  const _WidgetKind(this.key, this.label, this.icon, this.requiresAnalytics);

  final String key;
  final String label;
  final IconData icon;
  final bool requiresAnalytics;

  static _WidgetKind fromKey(String? key) {
    return _WidgetKind.values.firstWhere(
      (kind) => kind.key == key,
      orElse: () => _WidgetKind.logs,
    );
  }
}

class WidgetConfigScreen extends StatefulWidget {
  const WidgetConfigScreen({super.key, this.initialWidgetType});

  final String? initialWidgetType;

  @override
  State<WidgetConfigScreen> createState() => _WidgetConfigScreenState();
}

class _WidgetConfigScreenState extends State<WidgetConfigScreen> {
  final WidgetService _widgetService = WidgetService();

  late _WidgetKind _selectedKind;
  List<String> _logsProjectIds = [];
  String? _analyticsProjectId;
  String? _countriesProjectId;
  String? _usersProjectId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedKind = _WidgetKind.fromKey(widget.initialWidgetType);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final logsIds = await _widgetService.getSelectedProjectIds();
    final analyticsId = await _widgetService.getProjectForWidget('analytics');
    final countriesId = await _widgetService.getProjectForWidget('countries');
    final usersId = await _widgetService.getProjectForWidget('users');

    if (mounted) {
      setState(() {
        _logsProjectIds = logsIds;
        _analyticsProjectId = analyticsId;
        _countriesProjectId = countriesId;
        _usersProjectId = usersId;
        _isLoading = false;
      });
    }
  }

  String? _selectedProjectIdFor(_WidgetKind kind) {
    switch (kind) {
      case _WidgetKind.logs:
        return null;
      case _WidgetKind.analytics:
        return _analyticsProjectId;
      case _WidgetKind.countries:
        return _countriesProjectId;
      case _WidgetKind.users:
        return _usersProjectId;
    }
  }

  Future<void> _updateLogsProjects(String projectId) async {
    setState(() {
      if (_logsProjectIds.contains(projectId)) {
        _logsProjectIds.remove(projectId);
      } else {
        _logsProjectIds.add(projectId);
      }
    });
    await _widgetService.setSelectedProjectIds(_logsProjectIds);
    _triggerRefresh();
  }

  Future<void> _updateWidgetProject(_WidgetKind kind, Project project) async {
    if (kind.requiresAnalytics && !_hasVercelAnalytics(project)) {
      _showAnalyticsRequired(project);
      return;
    }

    setState(() {
      if (kind == _WidgetKind.analytics) _analyticsProjectId = project.id;
      if (kind == _WidgetKind.countries) _countriesProjectId = project.id;
      if (kind == _WidgetKind.users) _usersProjectId = project.id;
    });
    await _widgetService.setProjectForWidget(
      kind.key,
      project.id,
      project.name,
    );
    _triggerRefresh();
  }

  void _triggerRefresh() {
    context.read<AppState>().refreshWidgets();
  }

  void _showAnalyticsRequired(Project project) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${project.name} does not have Vercel Analytics enabled.',
        ),
        backgroundColor: AppTheme.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _hasVercelAnalytics(Project project) {
    final webAnalytics = project.webAnalytics;
    final analytics = project.analytics;
    return _analyticsMapEnabled(webAnalytics) ||
        _analyticsMapEnabled(analytics);
  }

  bool _analyticsMapEnabled(Map<String, dynamic>? value) {
    if (value == null || value.isEmpty) return false;
    if (value['enabledAt'] != null) return true;
    if (value['disabledAt'] != null) return false;
    if (value['id'] != null) return true;
    return value.isNotEmpty;
  }

  String _projectNameById(List<Project> projects, String? id) {
    if (id == null || id.isEmpty) return 'No project selected';
    for (final project in projects) {
      if (project.id == id) return project.name;
    }
    return 'Selected project unavailable';
  }

  bool _projectHasAnyWidget(Project project) {
    return _logsProjectIds.contains(project.id) ||
        _analyticsProjectId == project.id ||
        _countriesProjectId == project.id ||
        _usersProjectId == project.id;
  }

  List<Project> _suggestedAnalyticsProjects(List<Project> projects) {
    return projects
        .where((project) {
          return _hasVercelAnalytics(project) && !_projectHasAnyWidget(project);
        })
        .take(2)
        .toList();
  }

  void _openWidgetInstructions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          const VideoPlayerSheet(videoPath: 'assets/home_widgets.mp4'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final projects = appState.projects;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text(
          'Configure Widgets',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWidgetChooser(projects),
                const Divider(height: 1, color: AppTheme.outlineVariant),
                Expanded(child: _buildProjectPicker(projects)),
              ],
            ),
    );
  }

  Widget _buildWidgetChooser(List<Project> projects) {
    return SizedBox(
      height: 116,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final kind = _WidgetKind.values[index];
          final isSelected = kind == _selectedKind;
          final subtitle = kind == _WidgetKind.logs
              ? '${_logsProjectIds.length} selected'
              : _projectNameById(projects, _selectedProjectIdFor(kind));

          return InkWell(
            onTap: () => setState(() => _selectedKind = kind),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 148,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.surfaceContainerHigh
                    : AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(kind.icon, color: AppTheme.primary, size: 18),
                      const Spacer(),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: AppTheme.primary,
                          size: 16,
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    kind.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.75),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemCount: _WidgetKind.values.length,
      ),
    );
  }

  Widget _buildProjectPicker(List<Project> projects) {
    final analyticsProjects = projects.where(_hasVercelAnalytics).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Row(
          children: [
            Icon(_selectedKind.icon, color: AppTheme.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${_selectedKind.label} widget',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _selectedKind == _WidgetKind.logs
              ? 'Logs are available for all projects.'
              : '$analyticsProjects of ${projects.length} projects have Vercel Analytics enabled.',
          style: TextStyle(
            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
            fontSize: 13,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        ..._buildSuggestionCards(projects),
        if (projects.isEmpty)
          _buildEmptyState()
        else
          ...projects.map((project) {
            if (_selectedKind == _WidgetKind.logs) {
              return _buildProjectRow(
                project: project,
                selected: _logsProjectIds.contains(project.id),
                enabled: true,
                onTap: () => _updateLogsProjects(project.id),
                trailing: Checkbox(
                  value: _logsProjectIds.contains(project.id),
                  onChanged: (_) => _updateLogsProjects(project.id),
                  activeColor: AppTheme.primary,
                  checkColor: AppTheme.onPrimary,
                ),
              );
            }

            final hasAnalytics = _hasVercelAnalytics(project);
            final isSelected =
                _selectedProjectIdFor(_selectedKind) == project.id;
            return _buildProjectRow(
              project: project,
              selected: isSelected,
              enabled: hasAnalytics,
              onTap: () => _updateWidgetProject(_selectedKind, project),
              trailing: hasAnalytics
                  ? Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                    )
                  : const _StatusPill(label: 'Analytics off'),
            );
          }),
      ],
    );
  }

  List<Widget> _buildSuggestionCards(List<Project> projects) {
    if (!_selectedKind.requiresAnalytics) return const [];

    final suggestions = _suggestedAnalyticsProjects(projects);
    if (suggestions.isEmpty) return const [];

    return [
      ...suggestions.map(
        (project) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _WidgetSuggestionCard(
            projectName: project.name,
            widgetLabel: _selectedKind.label,
            onTap: _openWidgetInstructions,
          ),
        ),
      ),
      const SizedBox(height: 4),
    ];
  }

  Widget _buildProjectRow({
    required Project project,
    required bool selected,
    required bool enabled,
    required VoidCallback onTap,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: enabled ? onTap : () => _showAnalyticsRequired(project),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: enabled ? 1 : 0.52,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.surfaceContainerHigh
                  : AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? AppTheme.primary
                    : AppTheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    project.name.isEmpty ? '?' : project.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        project.framework ?? 'Project',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant.withValues(
                            alpha: 0.75,
                          ),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: const Text(
        'No projects found.',
        style: TextStyle(color: AppTheme.onSurfaceVariant),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _WidgetSuggestionCard extends StatelessWidget {
  const _WidgetSuggestionCard({
    required this.projectName,
    required this.widgetLabel,
    required this.onTap,
  });

  final String projectName;
  final String widgetLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.32)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/large-analysis-widget.png',
                width: 92,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suggested for $projectName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This project supports Vercel Analytics. Add a $widgetLabel widget for quick home screen stats.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.82),
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.play_circle_outline,
              color: AppTheme.primary,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}
