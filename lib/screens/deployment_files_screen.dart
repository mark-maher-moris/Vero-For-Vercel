import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/deployment.dart';
import '../models/deployment_file.dart';
import '../providers/app_state.dart';
import 'file_content_screen.dart';

/// Deployment files screen with expandable file tree
/// Matches the competitor's DeploymentFileTree component design
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
      // Use the file-tree endpoint like the competitor app
      // Extract hostname from deployment URL
      final deploymentUrl = widget.deployment.url;
      print('[DeploymentFiles] Fetching file tree for: $deploymentUrl');
      
      final files = await appState.apiService.getDeploymentFileTree(
        deploymentUrl: deploymentUrl,
        base: 'src', // Fetch source files
      );
      
      if (mounted) {
        setState(() {
          // Use files as-is - lazy loading will fetch children when folders are clicked
          _files = files;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('File tree not found')) {
          errorMessage = 'File tree not available for this deployment.';
        }
        setState(() {
          _error = errorMessage;
          _isLoading = false;
        });
      }
    }
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
            Text('Deployment Files', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(widget.deployment.name, style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
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

  /// Expand/collapse a folder - with lazy loading like competitor
  Future<void> _toggleFolder(DeploymentFile folder, String path) async {
    final isExpanded = folder.isExpanded ?? false;
    
    // If expanding and no children loaded yet, fetch them
    if (!isExpanded && (folder.children == null || folder.children!.isEmpty) && !folder.hasLoadedChildren) {
      setState(() {
        folder.isLoading = true;
      });
      
      try {
        final appState = context.read<AppState>();
        final basePath = path.isEmpty ? 'src/${folder.name}' : 'src/$path/${folder.name}';
        
        print('[DeploymentFiles] Lazy loading folder: $basePath');
        
        final children = await appState.apiService.getDeploymentFileTree(
          deploymentUrl: widget.deployment.url,
          base: basePath,
        );
        
        if (mounted) {
          setState(() {
            folder.children = children;
            folder.hasLoadedChildren = true;
            folder.isLoading = false;
            folder.isExpanded = true;
          });
        }
      } catch (e) {
        print('[DeploymentFiles] Error loading folder contents: $e');
        if (mounted) {
          setState(() {
            folder.isLoading = false;
            folder.isExpanded = false;
          });
        }
      }
    } else {
      // Just toggle expansion
      setState(() {
        folder.isExpanded = !isExpanded;
      });
    }
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
            SizedBox(height: 16),
            Text('No files found for this deployment'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _files!.length,
      itemBuilder: (context, index) {
        final file = _files![index];
        return _buildFileTreeItem(
          file: file,
          level: 0,
          path: '',
        );
      },
    );
  }

  /// Build a file tree item with recursive children support
  /// Matches the competitor's FileTreeAsset component
  Widget _buildFileTreeItem({
    required DeploymentFile file,
    required int level,
    required String path,
  }) {
    final isDir = file.type == 'directory';
    final fullPath = path.isEmpty ? file.name : '$path/${file.name}';
    final indentSize = 20.0 * level;
    final isExpanded = file.isExpanded ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File/folder row
        InkWell(
          onTap: () {
            if (isDir) {
              _toggleFolder(file, path);
            } else if (file.uid != null || file.link != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FileContentScreen(
                    deploymentId: widget.deployment.uid,
                    fileId: file.uid ?? file.link ?? '',
                    fileName: fullPath,
                    fileUrl: file.link, // Pass the link for file-tree API files
                  ),
                ),
              );
            }
          },
          child: Container(
            padding: EdgeInsets.only(
              left: 16 + indentSize,
              right: 16,
              top: 8,
              bottom: 8,
            ),
            child: Row(
              children: [
                // Loading indicator or icon
                if (file.isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  )
                else
                  Icon(
                    isDir
                        ? (isExpanded ? Icons.folder_open_outlined : Icons.folder_outlined)
                        : Icons.insert_drive_file_outlined,
                    size: 20,
                    color: isDir ? AppTheme.onSurfaceVariant : AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                const SizedBox(width: 12),
                // File name
                Expanded(
                  child: Text(
                    file.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                      color: AppTheme.onSurface,
                      fontWeight: isDir ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Expanded children
        if (isDir && isExpanded && file.children != null)
          Column(
            children: file.children!.map((child) {
              return _buildFileTreeItem(
                file: child,
                level: level + 1,
                path: fullPath,
              );
            }).toList(),
          ),
      ],
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
