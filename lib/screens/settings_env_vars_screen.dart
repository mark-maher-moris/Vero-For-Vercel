import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/project.dart';
import '../providers/app_state.dart';
import '../widgets/project_selector_appbar.dart';

class SettingsEnvVarsScreen extends StatefulWidget {
  final Project? project;

  const SettingsEnvVarsScreen({super.key, this.project});

  @override
  State<SettingsEnvVarsScreen> createState() => _SettingsEnvVarsScreenState();
}

class _SettingsEnvVarsScreenState extends State<SettingsEnvVarsScreen> {
  Project? _currentProject;
  String? _currentTeamId;
  Future<List<dynamic>>? _envVarsFuture;
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  bool _isProduction = true;
  bool _isPreview = false;
  bool _isDevelopment = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final project = widget.project ?? appState.selectedProject;
    final teamId = appState.currentTeamId;

    if (project != _currentProject || teamId != _currentTeamId) {
      _currentProject = project;
      _currentTeamId = teamId;
      _envVarsFuture = project != null ? appState.apiService.getProjectEnvVars(project.id) : null;
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: widget.project == null 
        ? const ProjectSelectorAppBar()
        : AppBar(
            backgroundColor: AppTheme.surfaceContainerLow,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
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
                Expanded(child: Text(widget.project!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              ],
            ),
          ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: -1.5),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage your project environment variables and build configurations.',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),

          // Env Vars Section
          Container(
            decoration: BoxDecoration(color: AppTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(4)),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Environment Variables', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary), overflow: TextOverflow.ellipsis),
                          SizedBox(height: 4),
                          Text('PROJECT CONFIGURATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      ),
                      onPressed: _isLoading ? null : () => _addEnvVar(context),
                      child: _isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppTheme.onPrimary, strokeWidth: 2))
                        : const Text('ADD VARIABLE', style: TextStyle(color: AppTheme.onPrimary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Add Form
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: AppTheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(2)),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _keyController,
                              style: const TextStyle(color: AppTheme.primary, fontFamily: 'monospace'),
                              decoration: const InputDecoration(
                                labelText: 'VARIABLE KEY',
                                labelStyle: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.surfaceVariant)),
                                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: TextField(
                              controller: _valueController,
                              obscureText: true,
                              style: const TextStyle(color: AppTheme.primary, fontFamily: 'monospace'),
                              decoration: const InputDecoration(
                                labelText: 'VALUE',
                                labelStyle: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.surfaceVariant)),
                                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          _buildCheckbox('PRODUCTION', _isProduction, (val) => setState(() => _isProduction = val)),
                          _buildCheckbox('PREVIEW', _isPreview, (val) => setState(() => _isPreview = val)),
                          _buildCheckbox('DEVELOPMENT', _isDevelopment, (val) => setState(() => _isDevelopment = val)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                if (project == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Select a project to view environment variables.', style: TextStyle(color: AppTheme.onSurfaceVariant))),
                  )
                else
                  FutureBuilder<List<dynamic>>(
                    future: _envVarsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: AppTheme.primary)));
                      } else if (snapshot.hasError) {
                        return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Error loading env vars: ${snapshot.error}', style: const TextStyle(color: AppTheme.error))));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: Text('No environment variables found.', style: TextStyle(color: AppTheme.onSurfaceVariant))),
                        );
                      }
                      
                      final envs = snapshot.data!;
                      return Column(
                        children: envs.map((env) => _buildEnvVar(
                          env['id'] ?? '',
                          env['key'] ?? 'UNKNOWN_KEY',
                          env['value'] ?? '••••••••',
                          env['target']?.contains('production') ?? false,
                          isEncrypted: (env['type'] == 'secret' || env['type'] == 'encrypted'),
                        )).toList(),
                      );
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: AppTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(2)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('FRAMEWORK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(project?.framework?.toUpperCase() ?? 'OTHER', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                          const Icon(Icons.circle, color: Colors.green, size: 12),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Detected based on build configuration.', style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: AppTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(2)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PROJECT ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.tag, color: AppTheme.onSurfaceVariant, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              project?.id ?? '-',
                              style: const TextStyle(fontFamily: 'monospace', color: AppTheme.primary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Unique identifier for this specific project.', style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCheckbox(String label, bool isChecked, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!isChecked),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isChecked ? Icons.check_box : Icons.check_box_outline_blank, color: isChecked ? AppTheme.primary : AppTheme.surfaceVariant, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.onSurface, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildEnvVar(String envId, String key, String value, bool isPrimary, {bool isEncrypted = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPrimary ? AppTheme.primary : AppTheme.secondary,
              boxShadow: isPrimary ? [
                BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 8)
              ] : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  key,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (isEncrypted) const Icon(Icons.lock, size: 10, color: AppTheme.onSurfaceVariant),
                    if (isEncrypted) const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(fontSize: 11, letterSpacing: 1, color: AppTheme.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.edit, size: 18, color: AppTheme.onSurfaceVariant),
            onPressed: envId.isNotEmpty ? () => _showEditEnvVarDialog(context, envId, key, value) : null,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: AppTheme.onSurfaceVariant),
            onPressed: envId.isNotEmpty ? () => _deleteEnvVar(context, envId) : null,
          ),
        ],
      ),
    );
  }

  Future<void> _addEnvVar(BuildContext context) async {
    final key = _keyController.text.trim();
    final value = _valueController.text.trim();

    if (key.isEmpty || value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both key and value')),
      );
      return;
    }

    final targets = <String>[];
    if (_isProduction) targets.add('production');
    if (_isPreview) targets.add('preview');
    if (_isDevelopment) targets.add('development');

    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one target environment')),
      );
      return;
    }

    final appState = context.read<AppState>();
    final project = widget.project ?? appState.selectedProject;
    if (project == null) return;

    setState(() => _isLoading = true);
    try {
      await appState.apiService.createEnvVars(project.id, [
        {
          'key': key,
          'value': value,
          'type': 'encrypted',
          'target': targets,
        }
      ]);
      _keyController.clear();
      _valueController.clear();
      setState(() {
        _envVarsFuture = appState.apiService.getProjectEnvVars(project.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Environment variable "$key" added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add environment variable: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEnvVar(BuildContext context, String envId) async {
    final appState = context.read<AppState>();
    final project = widget.project ?? appState.selectedProject;
    if (project == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLow,
        title: const Text('Delete Environment Variable?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await appState.apiService.deleteEnvVar(project.id, envId);
      setState(() {
        _envVarsFuture = appState.apiService.getProjectEnvVars(project.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Environment variable deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  Future<void> _showEditEnvVarDialog(BuildContext context, String envId, String currentKey, String currentValue) async {
    final editController = TextEditingController(text: currentValue);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLow,
        title: Text('Edit $currentKey'),
        content: TextField(
          controller: editController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'New Value',
            hintText: 'Enter new value...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newValue = editController.text.trim();
              if (newValue.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Value cannot be empty')),
                );
                return;
              }
              Navigator.pop(context);
              await _updateEnvVar(context, envId, newValue);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateEnvVar(BuildContext context, String envId, String newValue) async {
    final appState = context.read<AppState>();
    final project = widget.project ?? appState.selectedProject;
    if (project == null) return;

    try {
      await appState.apiService.deleteEnvVar(project.id, envId);
      await appState.apiService.createEnvVars(project.id, [
        {
          'value': newValue,
          'type': 'encrypted',
        }
      ]);
      setState(() {
        _envVarsFuture = appState.apiService.getProjectEnvVars(project.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Environment variable updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }
}
