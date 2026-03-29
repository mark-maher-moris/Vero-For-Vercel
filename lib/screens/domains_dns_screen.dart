import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';
import '../models/domain.dart';
import '../models/project.dart';
import 'package:timeago/timeago.dart' as timeago;

class DomainsDnsScreen extends StatefulWidget {
  const DomainsDnsScreen({super.key});

  @override
  State<DomainsDnsScreen> createState() => _DomainsDnsScreenState();
}

class _DomainsDnsScreenState extends State<DomainsDnsScreen> {
  Future<List<Domain>>? _domainsFuture;
  final TextEditingController _domainController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (_domainsFuture == null) {
      _domainsFuture = _fetchAllDomains(appState);
    }
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
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
            const Expanded(
              child: Text(
                'Domains',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
        children: [
          const Text(
            'Manage and configure your custom domains and DNS records.',
            style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant, height: 1.5),
          ),
          
          const SizedBox(height: 48),
          
          // Add Domain Bar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _domainController,
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
                  onPressed: _isLoading ? null : () => _addDomain(context, appState),
                  child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppTheme.onPrimary, strokeWidth: 2))
                    : const Text('Add', style: TextStyle(color: AppTheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          if (appState.projects.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No projects found.', style: TextStyle(color: AppTheme.onSurfaceVariant)),
              ),
            )
          else
            FutureBuilder<List<Domain>>(
              future: _domainsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppTheme.error)));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No domains found in your account.', style: TextStyle(color: AppTheme.onSurfaceVariant)));
                }

                final domains = snapshot.data!;
                return Column(
                  children: domains.map((domain) {
                    final name = domain.name;
                    final verified = domain.verified;
                    final ageStr = timeago.format(domain.createdAt);
                    final projectName = domain.projectId != null 
                        ? appState.projects.firstWhere(
                            (p) => p.id == domain.projectId,
                            orElse: () => Project(id: '', name: 'Unknown', createdAt: DateTime.now(), updatedAt: DateTime.now()),
                          ).name 
                        : 'Not assigned';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildDomainCard(
                        domain: name,
                        isValid: verified,
                        projectAssigned: projectName,
                        projectId: domain.projectId ?? '',
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
    required String projectId,
    required String age,
    String? errorMessage,
    String? errorDetails,
  }) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(domain, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isValid ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.errorContainer.withValues(alpha: 0.1),
                              border: Border.all(color: isValid ? AppTheme.success.withValues(alpha: 0.2) : AppTheme.error.withValues(alpha: 0.2)),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(isValid ? Icons.check_circle : Icons.error, size: 12, color: isValid ? AppTheme.success : AppTheme.error),
                                const SizedBox(width: 4),
                                Text(isValid ? 'Valid' : 'Invalid', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isValid ? AppTheme.success : AppTheme.error, letterSpacing: 1)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            side: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.2)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          ),
                          onPressed: () => _showDomainOptions(context, appState, domain, isValid, projectId),
                          child: const Text('Manage', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.more_vert, color: AppTheme.onSurfaceVariant),
                          onPressed: () => _showDomainOptions(context, appState, domain, isValid, projectId),
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
                              onPressed: () => _verifyDomain(context, appState, domain, projectId),
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
      },
    );
  }

  Future<void> _addDomain(BuildContext context, AppState appState) async {
    final domain = _domainController.text.trim();
    if (domain.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a domain name')),
      );
      return;
    }

    final project = appState.selectedProject;
    if (project == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project first')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await appState.apiService.addDomain(project.id, domain);
      _domainController.clear();
      await _refreshDomains(appState);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Domain "$domain" added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add domain: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyDomain(BuildContext context, AppState appState, String domain, String projectId) async {
    try {
      await appState.apiService.verifyDomain(projectId, domain);
      await _refreshDomains(appState);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Domain verification triggered')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e')),
        );
      }
    }
  }

  Future<void> _removeDomain(BuildContext context, AppState appState, String domain, String projectId) async {
    try {
      await appState.apiService.removeDomain(projectId, domain);
      await _refreshDomains(appState);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Domain "$domain" removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove domain: $e')),
        );
      }
    }
  }

  void _showDomainOptions(BuildContext context, AppState appState, String domain, bool isVerified, String projectId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Domain Options',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const Divider(),
            if (!isVerified)
              ListTile(
                leading: const Icon(Icons.verified, color: AppTheme.primary),
                title: const Text('Verify Domain'),
                onTap: () {
                  Navigator.pop(context);
                  _verifyDomain(context, appState, domain, projectId);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.error),
              title: const Text('Remove Domain', style: TextStyle(color: AppTheme.error)),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppTheme.surfaceContainerLow,
                    title: const Text('Remove Domain?'),
                    content: Text('Are you sure you want to remove "$domain"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _removeDomain(context, appState, domain, projectId);
                        },
                        child: const Text('Remove', style: TextStyle(color: AppTheme.error)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Domain>> _fetchAllDomains(AppState appState) async {
    // Use the v5/domains endpoint for efficient global domain listing
    return await appState.apiService.getDomains();
  }

  Future<void> _refreshDomains(AppState appState) async {
    setState(() {
      _domainsFuture = _fetchAllDomains(appState);
    });
  }
}
