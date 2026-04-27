import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_globe_3d/flutter_globe_3d.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';
import '../models/log.dart';

class TrafficGlobe extends StatefulWidget {
  final String projectId;
  final String? deploymentId;

  const TrafficGlobe({
    super.key,
    required this.projectId,
    this.deploymentId,
  });

  @override
  State<TrafficGlobe> createState() => _TrafficGlobeState();
}

class _TrafficGlobeState extends State<TrafficGlobe> {
  late final EarthController _controller;
  Timer? _pollingTimer;
  final List<Map<String, dynamic>> _recentVisitors = [];
  bool _isLive = false;
  String? _activeDeploymentId;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _activeDeploymentId = widget.deploymentId;
    _controller = EarthController();
    // Configure for interactive use - MUST be done before Earth3D is built
    _controller.enableAutoRotate = false;
    _controller.rotateSpeed = 0.0; // Extra safeguard
    _controller.minZoom = 0.3;
    _controller.maxZoom = 5.0;
    _controller.lockZoom = false;
    _controller.lockNorthSouth = false;
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startPolling() {
    _fetchTrafficData();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) => _fetchTrafficData());
  }

  Future<void> _fetchTrafficData() async {
    if (!mounted) return;
    
    final appState = Provider.of<AppState>(context, listen: false);
    
    try {
      if (_activeDeploymentId == null) {
        final deployments = await appState.apiService.getDeployments(projectId: widget.projectId);
        
        // Find the latest live (READY) deployment
        final liveDeployments = deployments.where((d) => d.state == 'READY').toList();
        
        if (liveDeployments.isNotEmpty) {
          liveDeployments.sort((a, b) => b.created.compareTo(a.created));
          _activeDeploymentId = liveDeployments.first.uid;
        } else if (deployments.isNotEmpty) {
          deployments.sort((a, b) => b.created.compareTo(a.created));
          _activeDeploymentId = deployments.first.uid;
        }
      }

      if (_activeDeploymentId == null) {
        return;
      }

      // Get ownerId from team or user
      final ownerId = appState.currentTeamId ?? appState.user?['id']?.toString();
      if (ownerId == null) return;

      // Use the robust getProjectLogs endpoint like the competitor app
      final result = await appState.apiService.getProjectLogs(
        projectId: widget.projectId,
        ownerId: ownerId,
        deploymentId: _activeDeploymentId,
      );

      final logs = result.logs;

      if (logs.isNotEmpty) {
        bool foundAnyGeo = false;
        for (var log in logs) {
          if (log.latitude != null && log.longitude != null) {
            foundAnyGeo = true;
            final visitor = {
              'id': log.requestId,
              'lat': log.latitude,
              'lng': log.longitude,
              'city': log.regionLabel ?? 'Unknown',
              'country': log.clientRegion.toUpperCase(),
              'timestamp': log.timestamp.millisecondsSinceEpoch,
            };
            _addVisitorToGlobe(visitor);
          }
        }
        if (mounted) {
          setState(() {
            _isLive = foundAnyGeo;
            _isFirstLoad = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLive = false;
            _isFirstLoad = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLive = false;
          _isFirstLoad = false;
        });
      }
    }
  }

  void _addVisitorToGlobe(Map<String, dynamic> visitor) {
    if (_recentVisitors.any((v) => v['id'] == visitor['id'])) return;

    if (mounted) {
      setState(() {
        _recentVisitors.insert(0, visitor);
        if (_recentVisitors.length > 20) _recentVisitors.removeLast();

        _controller.addNode(
          EarthNode(
            id: visitor['id'],
            latitude: visitor['lat'],
            longitude: visitor['lng'],
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show globe if no visitors and still loading or if truly empty
    if (_recentVisitors.isEmpty && !_isFirstLoad) {
      return Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.surfaceContainerHigh),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.public, color: AppTheme.onSurfaceVariant.withOpacity(0.2), size: 32),
              const SizedBox(height: 12),
              Text(
                'Waiting for traffic...',
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant.withOpacity(0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      height: 400,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF000000), // Pure black for Vercel vibe
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          children: [
            // The globe - wrapped to absorb vertical scroll gestures
            GestureDetector(
              onVerticalDragStart: (_) {},
              onVerticalDragUpdate: (_) {},
              onVerticalDragEnd: (_) {},
              behavior: HitTestBehavior.opaque,
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  1.5, 0, 0, 0, 0,
                  0, 1.5, 0, 0, 0,
                  0, 0, 1.5, 0, 0,
                  0, 0, 0, 1, 0,
                ]),
                child: Earth3D(
                  controller: _controller,
                  texture: const NetworkImage(
                    'https://raw.githubusercontent.com/mrdoob/three.js/master/examples/textures/planets/earth_atmos_2048.jpg',
                  ),
                  initialScale: 4.0
                ),
              ),
            ),
            // Header
            Positioned(
              top: 16,
              left: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isLive ? AppTheme.success : AppTheme.onSurfaceVariant.withOpacity(0.3),
                          shape: BoxShape.circle,
                          boxShadow: _isLive ? [
                            BoxShadow(
                              color: AppTheme.success.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ] : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LIVE VISITOR TRAFFIC',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._recentVisitors.take(3).map((v) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 10, color: AppTheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              '${v['city']}, ${v['country']}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            // Bottom stats
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  '${_recentVisitors.length} Recent HITS',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            // Loading overlay
            if (_isFirstLoad)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
