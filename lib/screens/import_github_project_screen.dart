import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';

class ImportGithubProjectScreen extends StatefulWidget {
  const ImportGithubProjectScreen({super.key});

  @override
  State<ImportGithubProjectScreen> createState() => _ImportGithubProjectScreenState();
}

class _ImportGithubProjectScreenState extends State<ImportGithubProjectScreen> {
  final _nameController = TextEditingController();
  final _repoController = TextEditingController();
  final _rootDirController = TextEditingController();
  String? _selectedFramework;
  bool _isImporting = false;
  String? _errorMessage;

  final List<Map<String, String>> _frameworks = [
    {'value': '', 'label': 'Auto-detect'},
    {'value': 'nextjs', 'label': 'Next.js'},
    {'value': 'react', 'label': 'React'},
    {'value': 'vue', 'label': 'Vue.js'},
    {'value': 'nuxtjs', 'label': 'Nuxt.js'},
    {'value': 'svelte', 'label': 'Svelte'},
    {'value': 'sveltekit', 'label': 'SvelteKit'},
    {'value': 'astro', 'label': 'Astro'},
    {'value': 'remix', 'label': 'Remix'},
    {'value': 'gatsby', 'label': 'Gatsby'},
    {'value': 'angular', 'label': 'Angular'},
    {'value': 'flutter', 'label': 'Flutter Web'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _repoController.dispose();
    _rootDirController.dispose();
    super.dispose();
  }

  String? _validateRepo(String repo) {
    // Accept formats: owner/repo or https://github.com/owner/repo
    if (repo.trim().isEmpty) return 'Repository is required';
    
    final trimmed = repo.trim();
    
    // If full URL, extract owner/repo
    if (trimmed.startsWith('https://github.com/')) {
      final parts = trimmed.replaceFirst('https://github.com/', '').split('/');
      if (parts.length >= 2) {
        return null; // Valid format
      }
      return 'Invalid GitHub URL format';
    }
    
    // Check owner/repo format
    final parts = trimmed.split('/');
    if (parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return null;
    }
    
    return 'Use format: owner/repo or https://github.com/owner/repo';
  }

  String _extractRepo(String repo) {
    final trimmed = repo.trim();
    if (trimmed.startsWith('https://github.com/')) {
      return trimmed.replaceFirst('https://github.com/', '').replaceFirst('.git', '');
    }
    return trimmed.replaceFirst('.git', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLow,
        elevation: 0,
        title: const Text(
          'Import GitHub Project',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.onSurfaceVariant),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
        children: [
          const Text(
            'Import.',
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: AppTheme.primary,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Deploy a new project from your GitHub repository.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 48),

          _buildSectionLabel('GITHUB REPOSITORY'),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _repoController,
            hint: 'owner/repo or https://github.com/owner/repo',
            icon: Icons.link,
          ),

          const SizedBox(height: 24),
          _buildSectionLabel('PROJECT NAME'),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _nameController,
            hint: 'my-awesome-project',
            icon: Icons.folder_outlined,
          ),

          const SizedBox(height: 24),
          _buildSectionLabel('FRAMEWORK'),
          const SizedBox(height: 16),
          _buildFrameworkDropdown(),

          const SizedBox(height: 24),
          _buildSectionLabel('ROOT DIRECTORY (OPTIONAL)'),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _rootDirController,
            hint: './ (leave empty for root)',
            icon: Icons.folder_open_outlined,
          ),

          const SizedBox(height: 24),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
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
            const SizedBox(height: 24),
          ],

          const SizedBox(height: 40),
          _buildImportButton(),
        ],
      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(2),
        border: Border(bottom: BorderSide(color: AppTheme.primary, width: 2)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppTheme.primary, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
          border: InputBorder.none,
          icon: Icon(icon, color: AppTheme.onSurfaceVariant, size: 20),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFrameworkDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(2),
        border: Border(bottom: BorderSide(color: AppTheme.primary, width: 2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedFramework,
          dropdownColor: AppTheme.surfaceContainerHigh,
          icon: const Icon(Icons.expand_more, color: AppTheme.onSurfaceVariant),
          isExpanded: true,
          style: const TextStyle(color: AppTheme.primary, fontSize: 16),
          hint: const Text('Auto-detect framework', style: TextStyle(color: AppTheme.onSurfaceVariant)),
          items: _frameworks.map((fw) {
            return DropdownMenuItem<String?>(
              value: fw['value']!.isEmpty ? null : fw['value'],
              child: Text(fw['label']!),
            );
          }).toList(),
          onChanged: (val) {
            setState(() => _selectedFramework = val);
          },
        ),
      ),
    );
  }

  Widget _buildImportButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, Color(0xFFC7C6C6)],
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isImporting ? null : _importProject,
          borderRadius: BorderRadius.circular(2),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isImporting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF1B1C1C), strokeWidth: 2))
                  : const Text(
                      'Import & Deploy',
                      style: TextStyle(
                        color: Color(0xFF1B1C1C),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                if (!_isImporting) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.bolt, color: Color(0xFF1B1C1C)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _importProject() async {
    final repoValidation = _validateRepo(_repoController.text);
    if (repoValidation != null) {
      setState(() => _errorMessage = repoValidation);
      return;
    }

    final repo = _extractRepo(_repoController.text);
    final name = _nameController.text.trim().isEmpty
        ? repo.split('/').last
        : _nameController.text.trim();

    setState(() {
      _isImporting = true;
      _errorMessage = null;
    });

    final appState = context.read<AppState>();

    try {
      // Create the project
      final project = await appState.apiService.createProject(
        name: name,
        repo: repo,
        framework: _selectedFramework,
        rootDirectory: _rootDirController.text.trim().isEmpty ? null : _rootDirController.text.trim(),
      );

      debugPrint('Project created: ${project['id']} - ${project['name']}');

      // Refresh projects list
      await appState.fetchProjects();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project "$name" imported from GitHub'),
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
        setState(() => _errorMessage = 'Failed to import project: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }
}
