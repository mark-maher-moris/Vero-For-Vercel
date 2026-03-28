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
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Project?>(
                    isExpanded: true,
                    value: selectedProject,
                    dropdownColor: AppTheme.surfaceContainerHigh,
                    icon: const Icon(Icons.unfold_more, color: AppTheme.onSurfaceVariant, size: 20),
                    onChanged: (Project? newValue) {
                      appState.setSelectedProject(newValue);
                    },
                    items: [
                      // Allow selecting "no project" (account level view) if desired, 
                      // but Vercel logic often forces a project. We will list all projects.
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
              ),
            ],
          ),
          actions: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.surfaceContainerHigh,
              child: const Icon(Icons.person, size: 16, color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(width: 16),
          ],
        );
      },
    );
  }
}
