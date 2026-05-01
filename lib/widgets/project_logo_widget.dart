import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

/// A widget that loads a favicon image with proper error handling.
/// Falls back to a placeholder if the image fails to load or decode.
class _FaviconImage extends StatefulWidget {
  final String url;
  final double size;
  final Widget fallback;
  final Widget loading;

  const _FaviconImage({
    required this.url,
    required this.size,
    required this.fallback,
    required this.loading,
  });

  @override
  State<_FaviconImage> createState() => _FaviconImageState();
}

class _FaviconImageState extends State<_FaviconImage> {
  bool _hasError = false;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallback;
    }

    return Image.network(
      widget.url,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          _isLoading = false;
          return child;
        }
        return widget.loading;
      },
      errorBuilder: (context, error, stackTrace) {
        // Mark error and show fallback on next frame to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _hasError = true);
          }
        });
        return widget.loading;
      },
    );
  }
}

class ProjectLogoWidget extends StatefulWidget {
  final Project project;
  final double size;
  final BoxShape shape;

  const ProjectLogoWidget({
    super.key,
    required this.project,
    this.size = 40,
    this.shape = BoxShape.circle,
  });

  @override
  State<ProjectLogoWidget> createState() => _ProjectLogoWidgetState();
}

class _ProjectLogoWidgetState extends State<ProjectLogoWidget> {
  Future<String?>? _faviconFuture;

  @override
  void initState() {
    super.initState();
    // Defer favicon fetch until first build when context is available
  }

  @override
  void didUpdateWidget(ProjectLogoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project.id != widget.project.id) {
      _faviconFuture = null; // Reset to fetch new project's favicon
    }
  }

  Future<String?> _fetchFavicon(BuildContext context) async {
    final appState = context.read<AppState>();
    return await appState.getCachedFavicon(widget.project.id);
  }

  String get _frameworkIcon {
    switch (widget.project.framework?.toLowerCase()) {
      case 'nextjs':
        return '▲';
      case 'astro':
        return '🚀';
      case 'remix':
      case 'react-router':
        return '⚛';
      case 'svelte':
      case 'sveltekit':
        return '🔥';
      case 'vue':
      case 'nuxtjs':
        return '🟢';
      case 'angular':
        return '🅰';
      case 'gatsby':
        return 'G';
      case 'hugo':
        return 'H';
      case 'jekyll':
        return '📄';
      case 'express':
      case 'fastify':
      case 'nestjs':
      case 'koa':
        return '🟢';
      default:
        return '⚡';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize favicon future on first build if not already set
    _faviconFuture ??= _fetchFavicon(context);

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: widget.shape,
        color: AppTheme.surfaceContainerHigh,
      ),
      child: ClipRRect(
        borderRadius: widget.shape == BoxShape.circle
            ? BorderRadius.circular(widget.size / 2)
            : BorderRadius.circular(4),
        child: FutureBuilder<String?>(
          future: _faviconFuture,
          builder: (context, snapshot) {
            // Loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingIndicator();
            }

            // Error or no favicon found - show fallback
            if (snapshot.hasError || snapshot.data == null) {
              return _buildFallback();
            }

            // Try to load the favicon image
            final faviconUrl = snapshot.data!;
            return _FaviconImage(
              url: faviconUrl,
              size: widget.size,
              fallback: _buildFallback(),
              loading: _buildLoadingIndicator(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: EdgeInsets.all(widget.size * 0.2),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        shape: widget.shape,
      ),
      child: SizedBox(
        width: widget.size * 0.5,
        height: widget.size * 0.5,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      padding: EdgeInsets.all(widget.size * 0.2),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        shape: widget.shape,
      ),
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text(
          _frameworkIcon,
          style: TextStyle(
            fontSize: widget.size * 0.5,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }
}
