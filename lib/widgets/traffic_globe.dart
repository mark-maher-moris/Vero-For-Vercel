import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/point.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';

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
  late FlutterEarthGlobeController _controller;
  Timer? _pollingTimer;
  final List<Map<String, dynamic>> _recentVisitors = [];
  bool _isLive = false;
  String? _activeDeploymentId;
  final List<String> _debugLogs = [];

  void _log(String msg) {
    debugPrint('TrafficGlobe: $msg');
    if (mounted) {
      setState(() {
        _debugLogs.insert(0, '[${DateTime.now().toString().split('.').first}] $msg');
        if (_debugLogs.length > 10) _debugLogs.removeLast();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _activeDeploymentId = widget.deploymentId;
    _controller = FlutterEarthGlobeController(
      rotationSpeed: 0.05,
      isRotating: true,
    );
    _startPolling();
  }

  void _startPolling() {
    _fetchTrafficData();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) => _fetchTrafficData());
  }

  Future<void> _fetchTrafficData() async {
    if (!mounted) return;
    
    _log('Fetching for project: ${widget.projectId}');
    
    final appState = Provider.of<AppState>(context, listen: false);
    
    try {
      if (_activeDeploymentId == null) {
        _log('Fetching deployments...');
        final deployments = await appState.apiService.getDeployments(projectId: widget.projectId);
        _log('Found ${deployments.length} deployments');
        
        // Find the latest live (READY) deployment
        final liveDeployments = deployments.where((d) => d.state == 'READY').toList();
        _log('${liveDeployments.length} are READY');
        
        if (liveDeployments.isNotEmpty) {
          liveDeployments.sort((a, b) => b.created.compareTo(a.created));
          _activeDeploymentId = liveDeployments.first.uid;
          _log('Using deployment: ${_activeDeploymentId!.substring(0, 8)}...');
        } else if (deployments.isNotEmpty) {
          deployments.sort((a, b) => b.created.compareTo(a.created));
          _activeDeploymentId = deployments.first.uid;
          _log('No READY, using latest: ${deployments.first.state}');
        } else {
          _log('NO DEPLOYMENTS!');
        }
      }

      if (_activeDeploymentId == null) {
        _log('ERROR: No deployment ID');
        return;
      }

      _log('Fetching logs...');
      final logs = await appState.apiService.getDeploymentRequestLogs(
        projectId: widget.projectId,
        deploymentId: _activeDeploymentId!,
        limit: 20,
      );
      _log('Got ${logs.length} logs');

      if (logs.isNotEmpty) {
        _log('First log keys: ${(logs.first['proxyHeaders'] ?? logs.first['headers'] ?? {}).keys.toList()}');
        bool foundAnyGeo = false;
        for (var log in logs) {
          final headers = log['proxyHeaders'] ?? log['headers'] ?? {};
          final latVal = headers['x-vercel-ip-latitude'];
          final lngVal = headers['x-vercel-ip-longitude'];

          if (latVal != null && lngVal != null) {
            final lat = double.tryParse(latVal.toString());
            final lng = double.tryParse(lngVal.toString());

            if (lat != null && lng != null) {
              foundAnyGeo = true;
              final visitor = {
                'id': log['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                'lat': lat,
                'lng': lng,
                'city': headers['x-vercel-ip-city'] ?? 'Unknown',
                'country': headers['x-vercel-ip-country'] ?? '??',
                'timestamp': log['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
              };
              _addVisitorToGlobe(visitor);
            }
          }
        }
        if (mounted) {
          setState(() {
            _isLive = foundAnyGeo;
          });
        }
        _log('Processing done: ${foundAnyGeo ? "GEO FOUND" : "NO GEO"}, visitors: ${_recentVisitors.length}');
      } else {
        _log('NO LOGS FROM API');
      }
    } catch (e) {
      _log('ERROR: $e');
      if (mounted) {
        setState(() => _isLive = false);
      }
    }
  }

  void _addVisitorToGlobe(Map<String, dynamic> visitor) {
    if (_recentVisitors.any((v) => v['id'] == visitor['id'])) return;

    if (mounted) {
      setState(() {
        _recentVisitors.insert(0, visitor);
        if (_recentVisitors.length > 10) _recentVisitors.removeLast();

        _controller.addPoint(
          Point(
            id: visitor['id'],
            coordinates: GlobeCoordinates(visitor['lat'], visitor['lng']),
            label: visitor['city'],
            isLabelVisible: true,
            style: const PointStyle(
              color: AppTheme.primary,
              size: 6,
            ),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Don't show globe if no visitors
    if (_recentVisitors.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      height: 400,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          children: [
            // Blue background circle for globe
            Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: const BoxDecoration(
                  color: Color(0xFF1A237E),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // The globe
            FlutterEarthGlobe(
              controller: _controller,
              radius: 130,
            ),
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
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LIVE VISITOR TRAFFIC',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._recentVisitors.take(3).map((v) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 10, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              '${v['city']}, ${v['country']}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.surfaceContainerHigh),
                ),
                child: Text(
                  '${_recentVisitors.length} Recent Visits',
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
