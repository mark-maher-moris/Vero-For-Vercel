class AnalyticsOverview {
  final int total;
  final int devices;
  final int bounceRate;

  AnalyticsOverview({
    required this.total,
    required this.devices,
    required this.bounceRate,
  });

  factory AnalyticsOverview.fromJson(Map<String, dynamic> json) {
    return AnalyticsOverview(
      total: json['total'] as int? ?? 0,
      devices: json['devices'] as int? ?? 0,
      bounceRate: json['bounceRate'] as int? ?? 0,
    );
  }
}

class TimeseriesPoint {
  final String key;
  final int total;
  final int devices;
  final int bounceRate;

  TimeseriesPoint({
    required this.key,
    required this.total,
    required this.devices,
    required this.bounceRate,
  });

  factory TimeseriesPoint.fromJson(Map<String, dynamic> json) {
    return TimeseriesPoint(
      key: json['key'] as String? ?? '',
      total: json['total'] as int? ?? 0,
      devices: json['devices'] as int? ?? 0,
      bounceRate: json['bounceRate'] as int? ?? 0,
    );
  }

  DateTime? get date {
    try {
      if (key.isEmpty) return null;
      // Vercel returns ISO 8601 or date strings like "2024-04-20"
      return DateTime.parse(key);
    } catch (e) {
      return null;
    }
  }
}

class BreakdownItem {
  final String key;
  final int visitors;

  BreakdownItem({
    required this.key,
    required this.visitors,
  });

  factory BreakdownItem.fromTimeseriesGroup(String key, List<dynamic> points) {
    // Breakdown items are often returned in a timeseries format where we sum the devices (visitors)
    int totalVisitors = 0;
    for (var point in points) {
      totalVisitors += (point['devices'] as int? ?? 0);
    }
    return BreakdownItem(
      key: key,
      visitors: totalVisitors,
    );
  }
}

enum TimeRange {
  day('24h', 'Last 24 Hours'),
  week('7d', 'Last 7 Days'),
  month('30d', 'Last 30 Days'),
  quarter('3mo', 'Last 3 Months'),
  year('12mo', 'Last 12 Months');

  final String value;
  final String label;
  const TimeRange(this.value, this.label);

  String _formatDate(DateTime date) {
    return '${date.toIso8601String().split('.')[0]}Z';
  }

  String get from {
    final now = DateTime.now().toUtc();
    switch (this) {
      case TimeRange.day:
        return _formatDate(now.subtract(const Duration(hours: 24)));
      case TimeRange.week:
        return _formatDate(now.subtract(const Duration(days: 7)));
      case TimeRange.month:
        return _formatDate(now.subtract(const Duration(days: 30)));
      case TimeRange.quarter:
        return _formatDate(now.subtract(const Duration(days: 90)));
      case TimeRange.year:
        return _formatDate(now.subtract(const Duration(days: 365)));
    }
  }

  String get to => _formatDate(DateTime.now().toUtc());

  String get previousFrom {
    final now = DateTime.now().toUtc();
    switch (this) {
      case TimeRange.day:
        return _formatDate(now.subtract(const Duration(hours: 48)));
      case TimeRange.week:
        return _formatDate(now.subtract(const Duration(days: 14)));
      case TimeRange.month:
        return _formatDate(now.subtract(const Duration(days: 60)));
      case TimeRange.quarter:
        return _formatDate(now.subtract(const Duration(days: 180)));
      case TimeRange.year:
        return _formatDate(now.subtract(const Duration(days: 730)));
    }
  }

  String get previousTo => from;
}

class AnalyticsData {
  AnalyticsOverview? overview;
  AnalyticsOverview? previousOverview;
  List<TimeseriesPoint> timeseries = [];
  List<BreakdownItem> pages = [];
  List<BreakdownItem> referrers = [];
  List<BreakdownItem> countries = [];
  List<BreakdownItem> devices = [];
  List<BreakdownItem> browsers = [];
  List<BreakdownItem> os = [];
  List<BreakdownItem> routes = [];
  List<BreakdownItem> hostnames = [];

  double? get visitorsChange => _percentChange(overview?.devices, previousOverview?.devices);
  double? get pageViewsChange => _percentChange(overview?.total, previousOverview?.total);
  double? get bounceRateChange {
    if (overview == null || previousOverview == null || previousOverview!.bounceRate == 0) return null;
    return (overview!.bounceRate - previousOverview!.bounceRate).toDouble();
  }

  double? _percentChange(int? current, int? previous) {
    if (current == null || previous == null || previous == 0) return null;
    return ((current - previous) / previous) * 100;
  }
}
