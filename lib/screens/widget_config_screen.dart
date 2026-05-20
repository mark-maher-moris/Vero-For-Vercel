import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../services/widget_service.dart';
import '../models/project.dart';

class WidgetConfigScreen extends StatefulWidget {
  const WidgetConfigScreen({super.key});

  @override
  State<WidgetConfigScreen> createState() => _WidgetConfigScreenState();
}

class _WidgetConfigScreenState extends State<WidgetConfigScreen> with SingleTickerProviderStateMixin {
  final WidgetService _widgetService = WidgetService();
  late TabController _tabController;
  
  List<String> _logsProjectIds = [];
  String? _analyticsProjectId;
  String? _countriesProjectId;
  String? _usersProjectId;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _updateWidgetProject(String widgetType, Project project) async {
    setState(() {
      if (widgetType == 'analytics') _analyticsProjectId = project.id;
      if (widgetType == 'countries') _countriesProjectId = project.id;
      if (widgetType == 'users') _usersProjectId = project.id;
    });
    await _widgetService.setProjectForWidget(widgetType, project.id, project.name);
    _triggerRefresh();
  }

  void _triggerRefresh() {
    context.read<AppState>().refreshWidgets();
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
          'Edit Widgets',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.onSurfaceVariant,
          tabs: const [
            Tab(text: 'Logs'),
            Tab(text: 'Analytics'),
            Tab(text: 'Countries'),
            Tab(text: 'Users'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProjectList(
                  projects: projects,
                  selectedIds: _logsProjectIds,
                  onToggle: (id) => _updateLogsProjects(id),
                  isMultiSelect: true,
                  description: 'Select one or more projects to monitor. The widget will show logs from the most recently deployed project among your selection.',
                ),
                _buildProjectList(
                  projects: projects,
                  selectedId: _analyticsProjectId,
                  onSelect: (project) => _updateWidgetProject('analytics', project),
                  isMultiSelect: false,
                  description: 'Select the project to display visitors and bounce rate analytics.',
                ),
                _buildProjectList(
                  projects: projects,
                  selectedId: _countriesProjectId,
                  onSelect: (project) => _updateWidgetProject('countries', project),
                  isMultiSelect: false,
                  description: 'Select the project to display visitor locations breakdown.',
                ),
                _buildProjectList(
                  projects: projects,
                  selectedId: _usersProjectId,
                  onSelect: (project) => _updateWidgetProject('users', project),
                  isMultiSelect: false,
                  description: 'Select the project to display 24h user totals and real-time estimation.',
                ),
              ],
            ),
    );
  }

  Widget _buildProjectList({
    required List<Project> projects,
    List<String>? selectedIds,
    String? selectedId,
    Function(String)? onToggle,
    Function(Project)? onSelect,
    required bool isMultiSelect,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.onSurfaceVariant.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              final isSelected = isMultiSelect 
                  ? (selectedIds?.contains(project.id) ?? false)
                  : (selectedId == project.id);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () {
                    if (isMultiSelect) {
                      onToggle?.call(project.id);
                    } else {
                      onSelect?.call(project);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppTheme.primary.withOpacity(0.05)
                          : AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? AppTheme.primary.withOpacity(0.3)
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.folder_outlined,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.primary,
                                ),
                              ),
                              if (project.framework != null)
                                Text(
                                  project.framework!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.onSurfaceVariant.withOpacity(0.7),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isMultiSelect)
                          Checkbox(
                            value: isSelected,
                            onChanged: (_) => onToggle?.call(project.id),
                            activeColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          )
                        else if (isSelected)
                          const Icon(Icons.check_circle, color: AppTheme.primary)
                        else
                          Icon(Icons.circle_outlined, color: AppTheme.onSurfaceVariant.withOpacity(0.3)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
