import 'package:flutter/material.dart';

/// Helper to parse int from various API formats (int or String)
int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

/// Model for Vercel request logs
/// Based on the /logs/request-logs endpoint response (Revcel-style)
class Log {
  final String requestId;
  final DateTime timestamp;
  final String branch;
  final String deploymentId;
  final String domain;
  final String deploymentDomain;
  final String environment;
  final String requestPath;
  final String route;
  final String clientUserAgent;
  final String clientRegion;
  final Map<String, String> requestSearchParams;
  final String requestMethod;
  final String cache;
  final int statusCode;
  final List<LogEvent> events;
  final List<LogLine> logs;
  final List<String> requestTags;
  final double? latitude;
  final double? longitude;

  Log({
    required this.requestId,
    required this.timestamp,
    required this.branch,
    required this.deploymentId,
    required this.domain,
    required this.deploymentDomain,
    required this.environment,
    required this.requestPath,
    required this.route,
    required this.clientUserAgent,
    required this.clientRegion,
    required this.requestSearchParams,
    required this.requestMethod,
    required this.cache,
    required this.statusCode,
    required this.events,
    required this.logs,
    required this.requestTags,
    this.latitude,
    this.longitude,
  });

  factory Log.fromJson(Map<String, dynamic> json) {
    // Parse timestamp - handle both ISO string and Date
    DateTime parsedTimestamp;
    final ts = json['timestamp'];
    if (ts is String) {
      parsedTimestamp = DateTime.parse(ts);
    } else if (ts is int) {
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(ts);
    } else {
      parsedTimestamp = DateTime.now();
    }

    // Parse request search params
    final params = json['requestSearchParams'] as Map<String, dynamic>?;
    final searchParams = <String, String>{};
    if (params != null) {
      for (final entry in params.entries) {
        searchParams[entry.key] = entry.value.toString();
      }
    }

    // Parse events
    final eventsList = json['events'] as List<dynamic>? ?? [];
    final parsedEvents = eventsList
        .map((e) => LogEvent.fromJson(e as Map<String, dynamic>))
        .toList();

    // Parse log lines (console logs)
    final logsList = json['logs'] as List<dynamic>? ?? [];
    final parsedLogs = logsList
        .map((l) => LogLine.fromJson(l as Map<String, dynamic>))
        .toList();

    // Parse request tags
    final tagsList = json['requestTags'] as List<dynamic>? ?? [];
    final parsedTags = tagsList.map((t) => t.toString()).toList();

    // Extract geo data from headers if available
    final headers = json['proxyHeaders'] as Map<String, dynamic>? ?? 
                   json['headers'] as Map<String, dynamic>? ?? {};
    
    double? lat = double.tryParse(headers['x-vercel-ip-latitude']?.toString() ?? '');
    double? lng = double.tryParse(headers['x-vercel-ip-longitude']?.toString() ?? '');

    // Fallback to region-based coordinates if headers are missing
    final region = json['clientRegion'] as String? ?? '';
    if ((lat == null || lng == null) && region.isNotEmpty) {
      final coords = COORDINATES_FOR_REGION[region];
      if (coords != null) {
        lat = coords['lat'];
        lng = coords['lng'];
      }
    }

    return Log(
      requestId: json['requestId'] as String? ?? json['id'] as String? ?? '',
      timestamp: parsedTimestamp,
      branch: json['branch'] as String? ?? '',
      deploymentId: json['deploymentId'] as String? ?? '',
      domain: json['domain'] as String? ?? json['host'] as String? ?? '',
      deploymentDomain: json['deploymentDomain'] as String? ?? '',
      environment: json['environment'] as String? ?? 'production',
      requestPath: json['requestPath'] as String? ?? json['path'] as String? ?? '',
      route: json['route'] as String? ?? '',
      clientUserAgent: json['clientUserAgent'] as String? ?? '',
      clientRegion: region,
      requestSearchParams: searchParams,
      requestMethod: json['requestMethod'] as String? ?? json['method'] as String? ?? 'GET',
      cache: json['cache'] as String? ?? '',
      statusCode: _parseInt(json['statusCode']) ?? 0,
      events: parsedEvents,
      logs: parsedLogs,
      requestTags: parsedTags,
      latitude: lat,
      longitude: lng,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'timestamp': timestamp.toIso8601String(),
      'branch': branch,
      'deploymentId': deploymentId,
      'domain': domain,
      'deploymentDomain': deploymentDomain,
      'environment': environment,
      'requestPath': requestPath,
      'route': route,
      'clientUserAgent': clientUserAgent,
      'clientRegion': clientRegion,
      'requestSearchParams': requestSearchParams,
      'requestMethod': requestMethod,
      'cache': cache,
      'statusCode': statusCode,
      'events': events.map((e) => e.toJson()).toList(),
      'logs': logs.map((l) => l.toJson()).toList(),
      'requestTags': requestTags,
    };
  }

  /// Get a display-friendly message
  String get displayMessage {
    if (logs.isNotEmpty && logs.first.message.isNotEmpty) {
      return logs.first.message;
    }
    return '$requestMethod $requestPath';
  }

  /// Get formatted timestamp string (HH:mm:ss)
  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final second = timestamp.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  /// Get color for status code
  static Color getStatusColor(int code) {
    if (code >= 200 && code < 300) return const Color(0xFF22C55E); // Green
    if (code >= 300 && code < 400) return const Color(0xFF3B82F6); // Blue
    if (code >= 400 && code < 500) return const Color(0xFFF59E0B); // Orange
    return const Color(0xFFEF4444); // Red (500+ errors)
  }

  /// Get the first event (main request event)
  LogEvent? get mainEvent => events.isNotEmpty ? events.first : null;

  /// Get memory usage from the first event
  String? get memoryUsed {
    final event = mainEvent;
    if (event != null && event.source != 'static' && event.functionMaxMemoryUsed > 0) {
      return '${event.functionMaxMemoryUsed} MB';
    }
    return null;
  }

  /// Get duration from the first event
  String? get duration {
    final event = mainEvent;
    if (event != null && event.source != 'static' && event.durationMs > 0) {
      return '${(event.durationMs / 1000).toStringAsFixed(2)}s';
    }
    return null;
  }

  /// Get region label for display
  String? get regionLabel => LABEL_FOR_REGION[clientRegion] ?? clientRegion;

  /// Get routed to region label
  String? get routedToLabel {
    final event = mainEvent;
    if (event != null) {
      return LABEL_FOR_REGION[event.region] ?? event.region;
    }
    return null;
  }

  /// Get search params as query string
  String get searchParamsString {
    if (requestSearchParams.isEmpty) return 'NONE';
    return requestSearchParams.entries.map((e) => '${e.key}=${e.value}').join('&');
  }
}

/// Log event from request processing
class LogEvent {
  final String? source;
  final String route;
  final String pathType;
  final DateTime timestamp;
  final int httpStatus;
  final String region;
  final String cache;
  final int functionMaxMemoryUsed;
  final int functionMemorySize;
  final int durationMs;

  LogEvent({
    this.source,
    required this.route,
    required this.pathType,
    required this.timestamp,
    required this.httpStatus,
    required this.region,
    required this.cache,
    required this.functionMaxMemoryUsed,
    required this.functionMemorySize,
    required this.durationMs,
  });

  factory LogEvent.fromJson(Map<String, dynamic> json) {
    DateTime parsedTimestamp;
    final ts = json['timestamp'];
    if (ts is String) {
      parsedTimestamp = DateTime.parse(ts);
    } else if (ts is int) {
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(ts);
    } else {
      parsedTimestamp = DateTime.now();
    }

    return LogEvent(
      source: json['source'] as String?,
      route: json['route'] as String? ?? '',
      pathType: json['pathType'] as String? ?? '',
      timestamp: parsedTimestamp,
      httpStatus: _parseInt(json['httpStatus']) ?? 0,
      region: json['region'] as String? ?? '',
      cache: json['cache'] as String? ?? '',
      functionMaxMemoryUsed: _parseInt(json['functionMaxMemoryUsed']) ?? 0,
      functionMemorySize: _parseInt(json['functionMemorySize']) ?? 0,
      durationMs: _parseInt(json['durationMs']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'route': route,
      'pathType': pathType,
      'timestamp': timestamp.toIso8601String(),
      'httpStatus': httpStatus,
      'region': region,
      'cache': cache,
      'functionMaxMemoryUsed': functionMaxMemoryUsed,
      'functionMemorySize': functionMemorySize,
      'durationMs': durationMs,
    };
  }
}

/// Individual log line (console output)
class LogLine {
  final String source;
  final String level;
  final String message;
  final DateTime timestamp;

  LogLine({
    required this.source,
    required this.level,
    required this.message,
    required this.timestamp,
  });

  factory LogLine.fromJson(Map<String, dynamic> json) {
    DateTime parsedTimestamp;
    final ts = json['timestamp'];
    if (ts is String) {
      parsedTimestamp = DateTime.parse(ts);
    } else if (ts is int) {
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(ts);
    } else {
      parsedTimestamp = DateTime.now();
    }

    return LogLine(
      source: json['source'] as String? ?? '',
      level: json['level'] as String? ?? 'info',
      message: json['message'] as String? ?? '',
      timestamp: parsedTimestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'level': level,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Get color for log level
  Color get levelColor {
    switch (level.toLowerCase()) {
      case 'error':
        return const Color(0xFFEF4444);
      case 'warn':
        return const Color(0xFFF59E0B);
      case 'debug':
        return const Color(0xFF6B7280);
      case 'info':
      default:
        return const Color(0xFF3B82F6);
    }
  }
}

/// Region code to human-readable label mapping
const LABEL_FOR_REGION = {
  'arn1': 'Stockholm, Sweden',
  'bom1': 'Mumbai, India',
  'cdg1': 'Paris, France',
  'cle1': 'Cleveland, USA',
  'cpt1': 'Cape Town, South Africa',
  'dub1': 'Dublin, Ireland',
  'fra1': 'Frankfurt, Germany',
  'gru1': 'São Paulo, Brazil',
  'hkg1': 'Hong Kong',
  'hnd1': 'Tokyo, Japan',
  'iad1': 'Washington, D.C., USA',
  'icn1': 'Seoul, South Korea',
  'kix1': 'Osaka, Japan',
  'lhr1': 'London, United Kingdom',
  'pdx1': 'Portland, USA',
  'sfo1': 'San Francisco, USA',
  'sin1': 'Singapore',
  'syd1': 'Sydney, Australia',
};

/// Coordinate mapping for Vercel regions (approximate locations)
const COORDINATES_FOR_REGION = {
  'arn1': {'lat': 59.3293, 'lng': 18.0686}, // Stockholm, Sweden
  'bom1': {'lat': 19.0760, 'lng': 72.8777}, // Mumbai, India
  'cdg1': {'lat': 48.8566, 'lng': 2.3522},  // Paris, France
  'cle1': {'lat': 41.4993, 'lng': -81.6944}, // Cleveland, USA
  'cpt1': {'lat': -33.9249, 'lng': 18.4241}, // Cape Town, South Africa
  'dub1': {'lat': 53.3498, 'lng': -6.2603},  // Dublin, Ireland
  'fra1': {'lat': 50.1109, 'lng': 8.6821},   // Frankfurt, Germany
  'gru1': {'lat': -23.5505, 'lng': -46.6333}, // São Paulo, Brazil
  'hkg1': {'lat': 22.3193, 'lng': 114.1694}, // Hong Kong
  'hnd1': {'lat': 35.6762, 'lng': 139.6503}, // Tokyo, Japan
  'iad1': {'lat': 38.9072, 'lng': -77.0369}, // Washington, D.C., USA
  'icn1': {'lat': 37.4563, 'lng': 126.7052}, // Seoul, South Korea
  'kix1': {'lat': 34.6937, 'lng': 135.5023}, // Osaka, Japan
  'lhr1': {'lat': 51.5074, 'lng': -0.1278},  // London, United Kingdom
  'pdx1': {'lat': 45.5152, 'lng': -122.6784}, // Portland, USA
  'sfo1': {'lat': 37.7749, 'lng': -122.4194}, // San Francisco, USA
  'sin1': {'lat': 1.3521, 'lng': 103.8198},  // Singapore
  'syd1': {'lat': -33.8688, 'lng': 151.2093}, // Sydney, Australia
};

/// Result from project logs API call
class ProjectLogsResult {
  final List<Log> logs;
  final bool hasMoreRows;
  final int? nextPage;

  ProjectLogsResult({
    required this.logs,
    required this.hasMoreRows,
    this.nextPage,
  });
}

/// Filter value option for logs
class LogFilterValue {
  final String attributeValue;
  final int total;

  LogFilterValue({
    required this.attributeValue,
    required this.total,
  });

  factory LogFilterValue.fromJson(Map<String, dynamic> json) {
    // Handle total as either int or string (API returns both)
    final totalRaw = json['total'];
    int total;
    if (totalRaw is int) {
      total = totalRaw;
    } else if (totalRaw is String) {
      total = int.tryParse(totalRaw) ?? 0;
    } else {
      total = 0;
    }
    
    return LogFilterValue(
      attributeValue: json['attributeValue']?.toString() ?? '',
      total: total,
    );
  }
}
