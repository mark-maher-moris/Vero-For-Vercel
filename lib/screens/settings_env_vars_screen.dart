import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/project.dart';
import '../services/api_service.dart';

class SettingsEnvVarsScreen extends StatefulWidget {
  final Project? project;

  const SettingsEnvVarsScreen({super.key, this.project});

  @override
  State<SettingsEnvVarsScreen> createState() => _SettingsEnvVarsScreenState();
}

class _SettingsEnvVarsScreenState extends State<SettingsEnvVarsScreen> {
  final VercelApi _api = VercelApi();
  List<dynamic>? _envVars;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEnvVars();
  }

  Future<void> _fetchEnvVars() async {
    if (widget.project == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final vars = await _api.getProjectEnvVars(widget.project!.id);
      if (mounted) {
        setState(() {
          _envVars = vars;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                color: AppTheme.primary,
              ),
              child: const Icon(Icons.change_history, size: 20, color: AppTheme.onPrimary),
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
          const SizedBox(width: 8),
        ],
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
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Environment Variables', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        SizedBox(height: 4),
                        Text('PROJECT CONFIGURATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5)),
                      ],
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      ),
                      onPressed: () {},
                      child: const Text('ADD VARIABLE', style: TextStyle(color: AppTheme.onPrimary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
                      const Row(
                        children: [
                          Expanded(
                            child: TextField(
                              style: TextStyle(color: AppTheme.primary, fontFamily: 'monospace'),
                              decoration: InputDecoration(
                                labelText: 'VARIABLE KEY',
                                labelStyle: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.surfaceVariant)),
                                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
                              ),
                            ),
                          ),
                          SizedBox(width: 24),
                          Expanded(
                            child: TextField(
                              obscureText: true,
                              style: TextStyle(color: AppTheme.primary, fontFamily: 'monospace'),
                              decoration: InputDecoration(
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
                      Row(
                        children: [
                          _buildCheckbox('PRODUCTION', true),
                          const SizedBox(width: 16),
                          _buildCheckbox('PREVIEW', false),
                          const SizedBox(width: 16),
                          _buildCheckbox('DEVELOPMENT', false),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                if (widget.project == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Select a project to view environment variables.', style: TextStyle(color: AppTheme.onSurfaceVariant))),
                  )
                else if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                else if (_envVars == null || _envVars!.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('No environment variables found.', style: TextStyle(color: AppTheme.onSurfaceVariant))),
                  )
                else
                  ..._envVars!.map((env) => _buildEnvVar(
                    env['key'] ?? 'UNKNOWN_KEY',
                    env['value'] ?? '••••••••',
                    env['target']?.contains('production') ?? false,
                    isEncrypted: (env['type'] == 'secret' || env['type'] == 'encrypted'),
                  )),
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
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NODE.JS VERSION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5)),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('20.x (Current)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                          Icon(Icons.circle, color: Colors.green, size: 12),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text('Automatic updates enabled for minor versions.', style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: AppTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(2)),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ROOT DIRECTORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5)),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.folder_outlined, color: AppTheme.onSurfaceVariant, size: 20),
                          SizedBox(width: 8),
                          Text('./apps/web', style: TextStyle(fontFamily: 'monospace', color: AppTheme.primary)),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text('Monorepo structure detected.', style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          // Danger Zone
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.errorContainer.withValues(alpha: 0.05),
              border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Danger Zone', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.error)),
                const SizedBox(height: 8),
                const Text('Permanently remove this project and all of its deployments and domain aliases.', style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant)),
                const SizedBox(height: 24),
                TextButton(
                  style: TextButton.styleFrom(
                    side: BorderSide(color: AppTheme.error.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                  ),
                  onPressed: () {},
                  child: const Text('DELETE PROJECT', style: TextStyle(color: AppTheme.error, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(String label, bool isChecked) {
    return Row(
      children: [
        Icon(isChecked ? Icons.check_box : Icons.check_box_outline_blank, color: isChecked ? AppTheme.primary : AppTheme.surfaceVariant, size: 20),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.onSurface, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildEnvVar(String key, String value, bool isPrimary, {bool isEncrypted = false}) {
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(key, style: const TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (isEncrypted) const Icon(Icons.lock, size: 10, color: AppTheme.onSurfaceVariant),
                  if (isEncrypted) const SizedBox(width: 4),
                  Text(value, style: const TextStyle(fontSize: 11, letterSpacing: 1, color: AppTheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.edit, size: 18, color: AppTheme.onSurfaceVariant),
          const SizedBox(width: 16),
          const Icon(Icons.delete, size: 18, color: AppTheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
