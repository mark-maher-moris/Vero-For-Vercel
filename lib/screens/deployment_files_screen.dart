import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/deployment.dart';
import '../models/deployment_file.dart';
import '../providers/app_state.dart';
import 'file_content_screen.dart';

class DeploymentFilesScreen extends StatefulWidget {
  final Deployment deployment;

  const DeploymentFilesScreen({
    super.key,
    required this.deployment,
  });

  @override
  State<DeploymentFilesScreen> createState() => _DeploymentFilesScreenState();
}

class _DeploymentFilesScreenState extends State<DeploymentFilesScreen> {
  bool _isLoading = true;
  List<DeploymentFile>? _files;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchFiles();
  }

  Future<void> _fetchFiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final appState = context.read<AppState>();
      final files = await appState.apiService.getDeploymentFiles(widget.deployment.uid);
      
      if (mounted) {
        setState(() {
          _files = _organizeFiles(files);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        bool isGitDeployment = widget.deployment.source == 'git' || widget.deployment.meta?.containsKey('githubCommitSha') == true;
        
        if (errorMessage.contains('File tree not found')) {
          if (isGitDeployment) {
            errorMessage = 'The file tree is not available for Git-based deployments via the Vercel API. You can view the source code directly on your Git provider.';
          } else {
            errorMessage = 'The file tree is not available for this deployment. This can happen for older deployments or those created via certain integrations.';
          }
        }
        setState(() {
          _error = errorMessage;
          _isLoading = false;
        });
      }
    }
  }

  List<DeploymentFile> _organizeFiles(List<DeploymentFile> files) {
    // Vercel returns files in a flat list with full paths.
    // For now, we'll just sort them alphabetically.
    files.sort((a, b) => a.name.compareTo(b.name));
    return files;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Deployment Files', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(widget.deployment.name, style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primary),
            onPressed: _fetchFiles,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_error != null) {
      final isGitDeployment = widget.deployment.isGit;
      final repoUrl = widget.deployment.repositoryUrl;
      
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _error!.contains('File tree not found') ? Icons.info_outline : Icons.error_outline,
                color: _error!.contains('File tree not found') ? AppTheme.onSurfaceVariant : AppTheme.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _error!.contains('File tree not found') ? 'File Tree Unavailable' : 'Failed to load files',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              if (isGitDeployment && repoUrl != null)
                ElevatedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(repoUrl)),
                  icon: const Icon(Icons.open_in_new, size: 18, color: Colors.black),
                  label: Text('VIEW ON ${widget.deployment.providerName?.toUpperCase() ?? 'GIT'}', style: const TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: _fetchFiles,
                  child: const Text('Retry'),
                ),
            ],
          ),
        ),
      );
    }

    if (_files == null || _files!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, color: AppTheme.onSurfaceVariant, size: 48),
            const SizedBox(height: 16),
            Text('No files found for this deployment'),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: _files!.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final file = _files![index];
        final isDir = file.type == 'directory';
        
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDir ? AppTheme.primary.withOpacity(0.1) : AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isDir ? Icons.folder : _getFileIcon(file.name),
              color: isDir ? AppTheme.primary : AppTheme.onSurfaceVariant,
              size: 20,
            ),
          ),
          title: Text(
            file.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          subtitle: file.mode != null 
            ? Text('Mode: ${file.mode}', style: const TextStyle(fontSize: 12))
            : null,
          trailing: const Icon(Icons.chevron_right, size: 16, color: AppTheme.onSurfaceVariant),
          onTap: () {
            if (!isDir && file.uid != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FileContentScreen(
                    deploymentId: widget.deployment.uid,
                    fileId: file.uid!,
                    fileName: file.name,
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'js':
      case 'ts':
      case 'jsx':
      case 'tsx':
        return Icons.code;
      case 'json':
        return Icons.settings_ethernet;
      case 'html':
      case 'css':
        return Icons.web;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'svg':
        return Icons.image;
      case 'md':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }
}
