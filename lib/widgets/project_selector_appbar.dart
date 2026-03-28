import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/project.dart';
import '../theme/app_theme.dart';

class ProjectSelectorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Map<String, dynamic>? user;
  
  const ProjectSelectorAppBar({super.key, this.user});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final projects = appState.projects;
        final selectedProject = appState.selectedProject;
        
        return AppBar(
          backgroundColor: AppTheme.surfaceContainerLow,
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTeamBadge(context, appState),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<Project?>(
                        isExpanded: true,
                        value: selectedProject,
                        dropdownColor: AppTheme.surfaceContainerHigh,
                        icon: const Icon(Icons.unfold_more, color: AppTheme.onSurfaceVariant, size: 20),
                        onChanged: (Project? newValue) {
                          appState.setSelectedProject(newValue);
                        },
                        items: [
                          ...projects.map<DropdownMenuItem<Project?>>((Project project) {
                            return DropdownMenuItem<Project?>(
                              value: project,
                              child: Text(
                                project.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.swap_horiz, color: AppTheme.onSurfaceVariant),
              onPressed: () => _showTeamPicker(context, appState),
            ),
            const SizedBox(width: 8),
          ],
        );
      },
    );
  }

  Widget _buildTeamBadge(BuildContext context, AppState appState) {
    String teamName = 'Personal Account';
    if (appState.currentTeamId != null) {
      final team = appState.teams.firstWhere(
        (t) => t['id'] == appState.currentTeamId,
        orElse: () => {'name': 'Team'},
      );
      teamName = team['name'] ?? 'Team';
    }

    return Text(
      teamName.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppTheme.onSurfaceVariant,
        fontSize: 9,
        letterSpacing: 1.0,
      ),
    );
  }

  void _showTeamPicker(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Switch Account',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.surfaceContainerHigh,
                  child: Icon(Icons.person, color: AppTheme.onSurfaceVariant),
                ),
                title: const Text('Personal Account'),
                trailing: appState.currentTeamId == null ? const Icon(Icons.check, color: AppTheme.primary) : null,
                onTap: () {
                  appState.switchTeam(null);
                  Navigator.pop(context);
                },
              ),
              ...appState.teams.map((team) {
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    child: Icon(Icons.group, color: AppTheme.onSurfaceVariant),
                  ),
                  title: Text(team['name'] ?? 'Team'),
                  trailing: appState.currentTeamId == team['id'] ? const Icon(Icons.check, color: AppTheme.primary) : null,
                  onTap: () {
                    appState.switchTeam(team['id']);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
