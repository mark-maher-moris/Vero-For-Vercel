import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';

class VideoPlayerSheet extends StatefulWidget {
  final String videoPath;
  const VideoPlayerSheet({super.key, required this.videoPath});

  @override
  State<VideoPlayerSheet> createState() => _VideoPlayerSheetState();
}

class _VideoPlayerSheetState extends State<VideoPlayerSheet> {
  late VideoPlayerController _controller;
  bool _hasError = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoPath)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller.play();
          _isPlaying = true;
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      });
      
    _controller.addListener(() {
      if (mounted && _controller.value.isPlaying != _isPlaying) {
        setState(() {
          _isPlaying = _controller.value.isPlaying;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Instructions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: _hasError
                ? const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load video.\nPlease ensure the asset is added.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : _controller.value.isInitialized
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                VideoPlayer(_controller),
                                VideoProgressIndicator(_controller, allowScrubbing: true),
                                Center(
                                  child: IconButton(
                                    icon: Icon(
                                      _isPlaying
                                          ? Icons.pause_circle_filled
                                          : Icons.play_circle_filled,
                                      size: 80,
                                      color: Colors.white.withValues(alpha: _isPlaying ? 0.0 : 0.7),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        if (_controller.value.isPlaying) {
                                          _controller.pause();
                                          _isPlaying = false;
                                        } else {
                                          _controller.play();
                                          _isPlaying = true;
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : const Padding(
                        padding: EdgeInsets.all(48.0),
                        child: CircularProgressIndicator(color: AppTheme.primary),
                      ),
          ),
        ],
      ),
    );
  }
}
