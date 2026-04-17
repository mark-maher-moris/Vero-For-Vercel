import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';
import '../widgets/syntax_highlighter.dart';

class FileContentScreen extends StatefulWidget {
  final String deploymentId;
  final String fileId;
  final String fileName;
  final String? fileUrl; // Optional: direct URL from file-tree API

  const FileContentScreen({
    super.key,
    required this.deploymentId,
    required this.fileId,
    required this.fileName,
    this.fileUrl,
  });

  @override
  State<FileContentScreen> createState() => _FileContentScreenState();
}

class _FileContentScreenState extends State<FileContentScreen> {
  bool _isLoading = true;
  String? _content;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchContent();
  }

  Future<void> _fetchContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final appState = context.read<AppState>();
      String content;
      
      // If fileUrl is provided (from file-tree API), fetch directly from URL
      if (widget.fileUrl != null && widget.fileUrl!.isNotEmpty) {
        print('[FileContentScreen] Fetching from URL: ${widget.fileUrl}');
        content = await appState.apiService.fetchFileFromUrl(widget.fileUrl!);
      } else {
        // Fall back to the old API method
        content = await appState.apiService.getDeploymentFileContents(
          widget.deploymentId,
          widget.fileId,
        );
      }
      
      if (mounted) {
        setState(() {
          _content = content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
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
        title: Text(widget.fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          if (_content != null)
            IconButton(
              icon: const Icon(Icons.copy, color: AppTheme.primary),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _content!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primary),
            onPressed: _fetchContent,
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
              const SizedBox(height: 16),
              const Text('Failed to load file content', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppTheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFF1E1E1E), // VSCode dark background
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: SyntaxHighlighter(
                        code: _content!,
                        fileName: widget.fileName,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_content == null) {
      return const Center(child: Text('No content available'));
    }

    return Expanded(
      child: Container(
        width: double.infinity,
        color: const Color(0xFF1E1E1E), // VSCode dark background
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SyntaxHighlighter(
              code: _content!,
              fileName: widget.fileName,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
