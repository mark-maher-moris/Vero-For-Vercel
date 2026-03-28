import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../providers/app_state.dart';
import '../models/project.dart';
import '../widgets/project_selector_appbar.dart';
import 'package:timeago/timeago.dart' as timeago;

class DomainsDnsScreen extends StatefulWidget {
  const DomainsDnsScreen({super.key});

  @override
  State<DomainsDnsScreen> createState() => _DomainsDnsScreenState();
}

class _DomainsDnsScreenState extends State<DomainsDnsScreen> {
  final VercelApi _api = VercelApi();
  Project? _currentProject;
  Future<List<dynamic>>? _domainsFuture;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final project = appState.selectedProject;

    if (project != _currentProject) {
      _currentProject = project;
      _domainsFuture = project != null ? _api.getProjectDomains(project.id) : null;
    }
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: const ProjectSelectorAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
        children: [
          Row(
            children: [
              const Text('ACCOUNT SETTINGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5)),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 14, color: AppTheme.onSurfaceVariant),
              const SizedBox(width: 8),
              const Text('DOMAINS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Domains',
            style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: -1.5),
          ),
          const SizedBox(height: 8),
          const Text('Manage and configure your custom domains and DNS records.', style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant, height: 1.5)),
          
          const SizedBox(height: 48),
          
          // Add Domain Bar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: AppTheme.primary, fontSize: 16, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Enter domain name...',
                      hintStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
                      filled: true,
                      fillColor: AppTheme.surfaceContainerLowest,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                  ),
                  onPressed: () {},
                  child: const Text('Add', style: TextStyle(color: AppTheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          if (project == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('Select a project to view domains.', style: TextStyle(color: AppTheme.onSurfaceVariant)),
              ),
            )
          else
            FutureBuilder<List<dynamic>>(
              future: _domainsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppTheme.error)));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No domains found for this project.', style: TextStyle(color: AppTheme.onSurfaceVariant)));
                }

                final domains = snapshot.data!;
                return Column(
                  children: domains.map((domain) {
                    final name = domain['name'] as String? ?? 'Unknown';
                    final verified = domain['verified'] as bool? ?? false;
                    final createdAt = domain['createdAt'] as int?;
                    final ageStr = createdAt != null 
                        ? timeago.format(DateTime.fromMillisecondsSinceEpoch(createdAt)) 
                        : 'Unknown';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildDomainCard(
                        domain: name,
                        isValid: verified,
                        projectAssigned: project.name,
                        age: ageStr,
                        errorMessage: verified ? null : 'Invalid Configuration',
                        errorDetails: verified ? null : 'Pending verification or DNS updates.',
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDomainCard({
    required String domain,
    required bool isValid,
    required String projectAssigned,
    required String age,
    String? errorMessage,
    String? errorDetails,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(domain, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isValid ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.errorContainer.withValues(alpha: 0.1),
                        border: Border.all(color: isValid ? AppTheme.success.withValues(alpha: 0.2) : AppTheme.error.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(
                        children: [
                          Icon(isValid ? Icons.check_circle : Icons.error, size: 12, color: isValid ? AppTheme.success : AppTheme.error),
                          const SizedBox(width: 4),
                          Text(isValid ? 'Valid' : 'Invalid', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isValid ? AppTheme.success : AppTheme.error, letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        side: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.2)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      ),
                      onPressed: () {},
                      child: const Text('Edit', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: AppTheme.onSurfaceVariant),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppTheme.surfaceContainerHigh),
          
          if (!isValid && errorMessage != null)
            Container(
              padding: const EdgeInsets.all(24),
              color: AppTheme.errorContainer.withValues(alpha: 0.05),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning, color: AppTheme.error, size: 20),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(errorMessage, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.error)),
                        const SizedBox(height: 4),
                        Text(errorDetails ?? '', style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8))),
                        const SizedBox(height: 16),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: AppTheme.error,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onPressed: () {},
                          child: const Text('Verify again', style: TextStyle(color: AppTheme.surface, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PROJECT ASSIGNED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Text(projectAssigned, style: const TextStyle(fontFamily: 'monospace', color: AppTheme.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Text(age, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    ],
                  ),
                ),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RENEWAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1)),
                      SizedBox(height: 8),
                      Text('Auto-renew ON', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
