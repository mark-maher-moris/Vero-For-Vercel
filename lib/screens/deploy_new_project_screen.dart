import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';
import '../widgets/project_selector_appbar.dart';

class DeployNewProjectScreen extends StatefulWidget {
  const DeployNewProjectScreen({super.key});

  @override
  State<DeployNewProjectScreen> createState() => _DeployNewProjectScreenState();
}

class _DeployNewProjectScreenState extends State<DeployNewProjectScreen> {
  String _selectedBranch = 'main';
  String _selectedTarget = 'preview';
  bool _isDeploying = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: const ProjectSelectorAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 120),
        children: [
          _buildTeamBadge(context, appState),
          const SizedBox(height: 16),
          const Text(
            'Deploy.',
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: AppTheme.primary,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            appState.selectedProject != null
              ? 'Ship ${appState.selectedProject!.name} to the edge instantly.'
              : 'Select a project to deploy.',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 48),

          _buildSectionLabel('SELECT BRANCH'),
          const SizedBox(height: 16),
          _buildBranchDropdown(),

          const SizedBox(height: 24),
          _buildSectionLabel('DEPLOYMENT TARGET'),
          const SizedBox(height: 16),
          _buildTargetDropdown(),

          const SizedBox(height: 40),
          _buildBuildSettings(),

          const SizedBox(height: 40),
          _buildDeployButton(context),
        ],
      ),
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

    return Row(
      children: [
        const Icon(Icons.account_tree_outlined, size: 14, color: AppTheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          teamName.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppTheme.onSurfaceVariant,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildBranchDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(4),
        border: Border(bottom: BorderSide(color: AppTheme.primary, width: 2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBranch,
          dropdownColor: AppTheme.surfaceContainerHigh,
          icon: const Icon(Icons.expand_more, color: AppTheme.onSurfaceVariant),
          isExpanded: true,
          style: const TextStyle(color: AppTheme.primary, fontSize: 16, fontWeight: FontWeight.normal),
          items: const [
            DropdownMenuItem(value: 'main', child: Text('main')),
            DropdownMenuItem(value: 'dev', child: Text('dev')),
            DropdownMenuItem(value: 'staging', child: Text('staging')),
            DropdownMenuItem(value: 'production', child: Text('production')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedBranch = val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildTargetDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(4),
        border: Border(bottom: BorderSide(color: AppTheme.primary, width: 2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTarget,
          dropdownColor: AppTheme.surfaceContainerHigh,
          icon: const Icon(Icons.expand_more, color: AppTheme.onSurfaceVariant),
          isExpanded: true,
          style: const TextStyle(color: AppTheme.primary, fontSize: 16, fontWeight: FontWeight.normal),
          items: const [
            DropdownMenuItem(value: 'preview', child: Text('Preview')),
            DropdownMenuItem(value: 'production', child: Text('Production')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedTarget = val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildBuildSettings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionLabel('BUILD SETTINGS'),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildSettingItem('Root Directory', './')),
              Expanded(child: _buildSettingItem('Install Command', 'npm install')),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildSettingItem('Build Command', 'npm run build')),
              Expanded(child: _buildSettingItem('Output Directory', '.next')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, color: AppTheme.primary, fontFamily: 'monospace')),
      ],
    );
  }

  Widget _buildDeployButton(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final selectedProject = appState.selectedProject;
        final bool canDeploy = selectedProject != null && !_isDeploying;
        
        return Column(
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppTheme.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (selectedProject == null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.onSurfaceVariant, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Select a project to deploy',
                        style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primary, Color(0xFFC7C6C6)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: canDeploy ? () => _deployProject(context, appState) : null,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _isDeploying
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF1B1C1C), strokeWidth: 2))
                            : Text(
                                'Deploy ${selectedProject.name}',
                                style: const TextStyle(
                                  color: Color(0xFF1B1C1C),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                          if (!_isDeploying) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.bolt, color: Color(0xFF1B1C1C)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _deployProject(BuildContext context, AppState appState) async {
    final selectedProject = appState.selectedProject;
    if (selectedProject == null) return;

    setState(() {
      _isDeploying = true;
      _errorMessage = null;
    });

    try {
      final deployment = await appState.apiService.createDeployment(
        projectId: selectedProject.id,
        target: _selectedTarget,
        withLatestCommit: true,
      );

      debugPrint('Deployment created: ${deployment.uid} - ${deployment.url}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deployment triggered for ${selectedProject.name} ($_selectedBranch)'),
            backgroundColor: AppTheme.primary,
          ),
        );
        Navigator.pop(context);
      }
    } on VercelApiException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to create deployment: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isDeploying = false);
      }
    }
  }
}
