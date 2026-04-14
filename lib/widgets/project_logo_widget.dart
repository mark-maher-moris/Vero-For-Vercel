import 'package:flutter/material.dart';
import '../models/project.dart';
import '../theme/app_theme.dart';

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
  int _currentLogoIndex = 0;
  bool _allLogosFailed = false;

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
    final logoUrls = widget.project.logoUrls;

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
        child: !_allLogosFailed && logoUrls.isNotEmpty && _currentLogoIndex < logoUrls.length
            ? Image.network(
                logoUrls[_currentLogoIndex],
                width: widget.size,
                height: widget.size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // If using cached URL and it fails, reset and try all URLs
                  if (logoUrls.length == 1 && _currentLogoIndex == 0) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        // Clear cached URL and start fresh
                        widget.project.setCachedLogoUrl('');
                        _currentLogoIndex = 0;
                      });
                    });
                    return _buildFallback();
                  }

                  // Try next URL on error
                  if (_currentLogoIndex < logoUrls.length - 1) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _currentLogoIndex++;
                      });
                    });
                    // Show loading while trying next
                    return _buildLoadingIndicator();
                  } else {
                    // All URLs failed, show fallback
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _allLogosFailed = true;
                      });
                    });
                    return _buildFallback();
                  }
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    // Image loaded successfully - cache the URL
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final currentUrl = logoUrls[_currentLogoIndex];
                      widget.project.setCachedLogoUrl(currentUrl);
                    });
                    return child;
                  }
                  return _buildLoadingIndicator();
                },
              )
            : _buildFallback(),
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
