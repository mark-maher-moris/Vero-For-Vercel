import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';

class DeployNewProjectScreen extends StatefulWidget {
  const DeployNewProjectScreen({super.key});

  @override
  State<DeployNewProjectScreen> createState() => _DeployNewProjectScreenState();
}

class _DeployNewProjectScreenState extends State<DeployNewProjectScreen> {
  String _selectedBranch = 'main';
  bool _isDeploying = false;

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
                  'Switch Account for Deployment',
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

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLow,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceContainerHigh,
              ),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Image.asset('assets/logo.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Vero', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: AppTheme.onSurfaceVariant),
            onPressed: () => _showTeamPicker(context, appState),
          ),
          const SizedBox(width: 8),
        ],
      ),
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
          const Text(
            'Ship your latest updates to the edge instantly.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 48),

          _buildSectionLabel('SELECT BRANCH'),
          const SizedBox(height: 16),
          _buildDropdown(),

          const SizedBox(height: 40),
          _buildBuildSettings(),

          const SizedBox(height: 40),
          _buildDeployButton(),
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

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(4),
        border: Border(bottom: BorderSide(color: AppTheme.primary, width: 2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: 'main',
          dropdownColor: AppTheme.surfaceContainerHigh,
          icon: const Icon(Icons.expand_more, color: AppTheme.onSurfaceVariant),
          isExpanded: true,
          style: const TextStyle(color: AppTheme.primary, fontSize: 16, fontWeight: FontWeight.normal),
          items: const [
            DropdownMenuItem(value: 'main', child: Text('main')),
            DropdownMenuItem(value: 'dev', child: Text('dev')),
            DropdownMenuItem(value: 'feature/ui-update', child: Text('feature/ui-update')),
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

  Widget _buildDeployButton() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Container(
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
              onTap: _isDeploying ? null : () => _deployProject(context, appState),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _isDeploying
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF1B1C1C), strokeWidth: 2))
                      : const Text(
                          'Deploy Project',
                          style: TextStyle(
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
        );
      },
    );
  }

  Future<void> _deployProject(BuildContext context, AppState appState) async {
    setState(() => _isDeploying = true);
    try {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deployment from $_selectedBranch triggered!')),
        );
        Navigator.pop(context);
      }
    } finally {
      setState(() => _isDeploying = false);
    }
  }
}
