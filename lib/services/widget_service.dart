import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../models/analytics.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'superwall_service.dart';

/// Keys used to store widget data in SharedPreferences (Android) / UserDefaults (iOS).
/// Native widgets read these keys with the "flutter." prefix added by home_widget.
class WidgetKeys {
  static const String apiToken = 'vero_api_token';
  static const String teamId = 'vero_team_id';
  static const String isSubscribed = 'vero_is_subscribed';
  static const String lastUpdated = 'vero_last_updated';
  static const String projectsJson = 'vero_projects_json';

  // Per-widget selected project IDs
  static const String projectIdLogs = 'vero_project_logs_id';
  static const String projectIdAnalytics = 'vero_project_analytics_id';
  static const String projectIdCountries = 'vero_project_countries_id';
  static const String projectIdUsers = 'vero_project_users_id';

  // Logs widget data
  static const String logsData = 'vero_logs_data';
  static const String logsProjectName = 'vero_logs_project_name';
  static const String logsDeploymentStatus = 'vero_logs_deployment_status';

  // Analytics widget data
  static const String analyticsVisitors24h = 'vero_analytics_visitors_24h';
  static const String analyticsBounceRate = 'vero_analytics_bounce_rate';
  static const String analyticsTimeseries = 'vero_analytics_timeseries';
  static const String analyticsSources = 'vero_analytics_sources';
  static const String analyticsProjectName = 'vero_analytics_project_name';
  static const String analyticsEnabled = 'vero_analytics_enabled';

  // Countries widget data
  static const String countriesData = 'vero_countries_data';
  static const String countriesProjectName = 'vero_countries_project_name';

  // Users widget data
  static const String usersTotal24h = 'vero_users_total_24h';
  static const String usersBounceRate = 'vero_users_bounce_rate';
  static const String usersProjectName = 'vero_users_project_name';
}

/// Names of the native widget classes for triggering updates.
class WidgetNames {
  static const String usersSmallAndroid = 'com.buildagon.vero.UsersSmallWidget';
  static const String logsMediumAndroid = 'com.buildagon.vero.LogsMediumWidget';
  static const String logsLargeAndroid = 'com.buildagon.vero.LogsLargeWidget';
  static const String analyticsLargeAndroid = 'com.buildagon.vero.AnalyticsLargeWidget';
  static const String countriesMediumAndroid = 'com.buildagon.vero.CountriesMediumWidget';

  static const String usersSmallIOS = 'UsersSmallWidget';
  static const String logsMediumIOS = 'LogsMediumWidget';
  static const String logsLargeIOS = 'LogsLargeWidget';
  static const String analyticsLargeIOS = 'AnalyticsLargeWidget';
  static const String countriesMediumIOS = 'CountriesMediumWidget';
}

class WidgetService {
  static final WidgetService _instance = WidgetService._internal();
  factory WidgetService() => _instance;
  WidgetService._internal();

  static const String _appGroupId = 'group.com.buildagon.vero';

  final AuthService _authService = AuthService();

  Future<void> initialize() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  /// Push auth token and subscription status to native widgets.
  /// Call this after login and on app resume.
  Future<void> pushAuthData({
    required String? teamId,
    required bool isSubscribed,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return;
      await HomeWidget.saveWidgetData<String>(WidgetKeys.apiToken, token);
      if (teamId != null) {
        await HomeWidget.saveWidgetData<String>(WidgetKeys.teamId, teamId);
      }
      await HomeWidget.saveWidgetData<bool>(WidgetKeys.isSubscribed, isSubscribed);
    } catch (e) {
      if (kDebugMode) print('[WidgetService] pushAuthData error: $e');
    }
  }

  /// Push list of available projects for widget configuration.
  Future<void> pushProjects(List<Map<String, String>> projects) async {
    try {
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.projectsJson,
        jsonEncode(projects),
      );
    } catch (e) {
      if (kDebugMode) print('[WidgetService] pushProjects error: $e');
    }
  }

  /// Refresh all widget data from the Vercel API and trigger widget redraws.
  Future<void> refreshAll({
    required VercelApi api,
    required List<Map<String, String>> projects,
  }) async {
    try {
      await initialize();
      final isSubscribed = await SuperwallService().getCurrentSubscriptionStatus();
      await HomeWidget.saveWidgetData<bool>(WidgetKeys.isSubscribed, isSubscribed);
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.lastUpdated,
        DateTime.now().toIso8601String(),
      );

      // Save projects list so native config screens can read them
      await pushProjects(projects
          .map((p) => {'id': p['id'] ?? '', 'name': p['name'] ?? ''})
          .toList());

      // Get stored project selections
      final projectIdLogs = await HomeWidget.getWidgetData<String>(WidgetKeys.projectIdLogs);
      final projectIdAnalytics = await HomeWidget.getWidgetData<String>(WidgetKeys.projectIdAnalytics);
      final projectIdCountries = await HomeWidget.getWidgetData<String>(WidgetKeys.projectIdCountries);
      final projectIdUsers = await HomeWidget.getWidgetData<String>(WidgetKeys.projectIdUsers);

      // Fetch data concurrently
      await Future.wait([
        if (projectIdLogs != null && projectIdLogs.isNotEmpty)
          _refreshLogs(api, projectIdLogs),
        if (projectIdAnalytics != null && projectIdAnalytics.isNotEmpty)
          _refreshAnalytics(api, projectIdAnalytics),
        if (projectIdCountries != null && projectIdCountries.isNotEmpty)
          _refreshCountries(api, projectIdCountries),
        if (projectIdUsers != null && projectIdUsers.isNotEmpty)
          _refreshUsers(api, projectIdUsers),
      ]);

      await _triggerAllWidgetUpdates();
    } catch (e) {
      if (kDebugMode) print('[WidgetService] refreshAll error: $e');
    }
  }

  Future<void> _refreshLogs(VercelApi api, String projectId) async {
    try {
      final deployments = await api.getDeployments(projectId: projectId);
      if (deployments.isEmpty) return;

      final latest = deployments.first;
      final projectName = latest.name;

      await HomeWidget.saveWidgetData<String>(WidgetKeys.logsProjectName, projectName);
      await HomeWidget.saveWidgetData<String>(WidgetKeys.logsDeploymentStatus, latest.state);

      final events = await api.getDeploymentEvents(latest.uid);
      final logEntries = events
          .where((e) => e is Map && e['type'] == 'stdout')
          .take(10)
          .map((e) {
            final created = e['created'] as int? ?? 0;
            final payload = e['payload'] as Map? ?? {};
            return {
              'message': payload['text'] as String? ?? '',
              'level': payload['level'] as String? ?? 'info',
              'timestamp': created,
            };
          })
          .toList();

      await HomeWidget.saveWidgetData<String>(WidgetKeys.logsData, jsonEncode(logEntries));
    } catch (e) {
      if (kDebugMode) print('[WidgetService] _refreshLogs error: $e');
    }
  }

  Future<void> _refreshAnalytics(VercelApi api, String projectId) async {
    try {
      final now = DateTime.now().toUtc();
      final from24h = now.subtract(const Duration(hours: 24)).toIso8601String();
      final from7d = now.subtract(const Duration(days: 7)).toIso8601String();
      final to = now.toIso8601String();

      // Check if analytics is available by fetching overview (may throw if not enabled)
      AnalyticsOverview? overview;
      try {
        overview = await api.getAnalyticsOverview(
          projectId: projectId,
          from: from24h,
          to: to,
        );
        await HomeWidget.saveWidgetData<bool>(WidgetKeys.analyticsEnabled, true);
      } catch (_) {
        await HomeWidget.saveWidgetData<bool>(WidgetKeys.analyticsEnabled, false);
        return;
      }

      await HomeWidget.saveWidgetData<int>(WidgetKeys.analyticsVisitors24h, overview.devices);
      await HomeWidget.saveWidgetData<int>(WidgetKeys.analyticsBounceRate, overview.bounceRate);

      // Fetch 7-day timeseries for chart
      try {
        final timeseries = await api.getAnalyticsTimeseries(
          projectId: projectId,
          from: from7d,
          to: to,
        );
        final seriesData = timeseries.map((p) => {
          'date': p.key,
          'value': p.devices,
        }).toList();
        await HomeWidget.saveWidgetData<String>(WidgetKeys.analyticsTimeseries, jsonEncode(seriesData));
      } catch (_) {}

      // Fetch traffic sources (referrers)
      try {
        final sources = await api.getAnalyticsBreakdown(
          projectId: projectId,
          from: from7d,
          to: to,
          groupBy: 'referrer',
        );
        final sourcesData = sources.take(5).map((s) => {
          'source': s.key.isEmpty ? 'Direct' : s.key,
          'visitors': s.visitors,
        }).toList();
        await HomeWidget.saveWidgetData<String>(WidgetKeys.analyticsSources, jsonEncode(sourcesData));
      } catch (_) {}

      // Fetch countries for analytics widget
      try {
        final countries = await api.getAnalyticsBreakdown(
          projectId: projectId,
          from: from7d,
          to: to,
          groupBy: 'country',
        );
        final total = countries.fold<int>(0, (sum, c) => sum + c.visitors);
        final countriesData = countries.take(5).map((c) => {
          'code': c.key,
          'name': _countryName(c.key),
          'visitors': c.visitors,
          'percentage': total > 0 ? ((c.visitors / total) * 100).round() : 0,
        }).toList();
        await HomeWidget.saveWidgetData<String>(WidgetKeys.countriesData, jsonEncode(countriesData));
      } catch (_) {}
    } catch (e) {
      if (kDebugMode) print('[WidgetService] _refreshAnalytics error: $e');
    }
  }

  Future<void> _refreshCountries(VercelApi api, String projectId) async {
    try {
      final projects = await api.getProjectsList();
      final project = projects.firstWhere(
        (p) => p.id == projectId,
        orElse: () => projects.first,
      );
      await HomeWidget.saveWidgetData<String>(WidgetKeys.countriesProjectName, project.name);

      final now = DateTime.now().toUtc();
      final from7d = now.subtract(const Duration(days: 7)).toIso8601String();
      final to = now.toIso8601String();

      final countries = await api.getAnalyticsBreakdown(
        projectId: projectId,
        from: from7d,
        to: to,
        groupBy: 'country',
      );
      final total = countries.fold<int>(0, (sum, c) => sum + c.visitors);
      final countriesData = countries.take(6).map((c) => {
        'code': c.key,
        'name': _countryName(c.key),
        'visitors': c.visitors,
        'percentage': total > 0 ? ((c.visitors / total) * 100).round() : 0,
      }).toList();
      await HomeWidget.saveWidgetData<String>(WidgetKeys.countriesData, jsonEncode(countriesData));
    } catch (e) {
      if (kDebugMode) print('[WidgetService] _refreshCountries error: $e');
    }
  }

  Future<void> _refreshUsers(VercelApi api, String projectId) async {
    try {
      final now = DateTime.now().toUtc();
      final from = now.subtract(const Duration(hours: 24)).toIso8601String();
      final to = now.toIso8601String();

      final overview = await api.getAnalyticsOverview(
        projectId: projectId,
        from: from,
        to: to,
      );

      await HomeWidget.saveWidgetData<int>(WidgetKeys.usersTotal24h, overview.devices);
      await HomeWidget.saveWidgetData<int>(WidgetKeys.usersBounceRate, overview.bounceRate);

      // Fetch timeseries to estimate last-hour users as "online"
      final fromLastHour = now.subtract(const Duration(hours: 1)).toIso8601String();
      try {
        final recentOverview = await api.getAnalyticsOverview(
          projectId: projectId,
          from: fromLastHour,
          to: to,
        );
        // Store last hour visitors separately (used as "online now" approximation)
        await HomeWidget.saveWidgetData<int>('vero_users_last_hour', recentOverview.devices);
      } catch (_) {}

      final projects = await api.getProjectsList();
      final project = projects.firstWhere(
        (p) => p.id == projectId,
        orElse: () => projects.first,
      );
      await HomeWidget.saveWidgetData<String>(WidgetKeys.usersProjectName, project.name);
    } catch (e) {
      if (kDebugMode) print('[WidgetService] _refreshUsers error: $e');
    }
  }

  Future<void> _triggerAllWidgetUpdates() async {
    final updates = [
      HomeWidget.updateWidget(
        iOSName: WidgetNames.usersSmallIOS,
        qualifiedAndroidName: WidgetNames.usersSmallAndroid,
      ),
      HomeWidget.updateWidget(
        iOSName: WidgetNames.logsMediumIOS,
        qualifiedAndroidName: WidgetNames.logsMediumAndroid,
      ),
      HomeWidget.updateWidget(
        iOSName: WidgetNames.logsLargeIOS,
        qualifiedAndroidName: WidgetNames.logsLargeAndroid,
      ),
      HomeWidget.updateWidget(
        iOSName: WidgetNames.analyticsLargeIOS,
        qualifiedAndroidName: WidgetNames.analyticsLargeAndroid,
      ),
      HomeWidget.updateWidget(
        iOSName: WidgetNames.countriesMediumIOS,
        qualifiedAndroidName: WidgetNames.countriesMediumAndroid,
      ),
    ];
    await Future.wait(updates);
  }

  /// Save a project selection for a specific widget type.
  /// [widgetType]: 'logs' | 'analytics' | 'countries' | 'users'
  Future<void> setProjectForWidget(String widgetType, String projectId, String projectName) async {
    String key;
    String nameKey;
    switch (widgetType) {
      case 'logs':
        key = WidgetKeys.projectIdLogs;
        nameKey = WidgetKeys.logsProjectName;
        break;
      case 'analytics':
        key = WidgetKeys.projectIdAnalytics;
        nameKey = WidgetKeys.analyticsProjectName;
        break;
      case 'countries':
        key = WidgetKeys.projectIdCountries;
        nameKey = WidgetKeys.countriesProjectName;
        break;
      case 'users':
        key = WidgetKeys.projectIdUsers;
        nameKey = WidgetKeys.usersProjectName;
        break;
      default:
        return;
    }
    await HomeWidget.saveWidgetData<String>(key, projectId);
    await HomeWidget.saveWidgetData<String>(nameKey, projectName);
    await _triggerAllWidgetUpdates();
  }

  /// Listen for widget tap events (when user taps a widget to open the app).
  Stream<Uri?> get widgetClicked => HomeWidget.widgetClicked;

  /// Resolve country code to display name
  String _countryName(String code) {
    const names = {
      'US': 'United States',
      'GB': 'United Kingdom',
      'CA': 'Canada',
      'AU': 'Australia',
      'DE': 'Germany',
      'FR': 'France',
      'IN': 'India',
      'JP': 'Japan',
      'BR': 'Brazil',
      'MX': 'Mexico',
      'KR': 'South Korea',
      'NL': 'Netherlands',
      'PL': 'Poland',
      'SE': 'Sweden',
      'NO': 'Norway',
      'DK': 'Denmark',
      'FI': 'Finland',
      'IT': 'Italy',
      'ES': 'Spain',
      'PT': 'Portugal',
      'SG': 'Singapore',
      'HK': 'Hong Kong',
      'TW': 'Taiwan',
      'CN': 'China',
      'RU': 'Russia',
      'UA': 'Ukraine',
      'TR': 'Turkey',
      'ZA': 'South Africa',
      'EG': 'Egypt',
      'NG': 'Nigeria',
      'AR': 'Argentina',
      'CO': 'Colombia',
      'CL': 'Chile',
      'PH': 'Philippines',
      'ID': 'Indonesia',
      'TH': 'Thailand',
      'VN': 'Vietnam',
      'PK': 'Pakistan',
      'BD': 'Bangladesh',
      'EE': 'Estonia',
      'LT': 'Lithuania',
      'LV': 'Latvia',
      'CZ': 'Czech Republic',
      'SK': 'Slovakia',
      'HU': 'Hungary',
      'RO': 'Romania',
      'BG': 'Bulgaria',
      'HR': 'Croatia',
      'RS': 'Serbia',
      'GR': 'Greece',
      'AT': 'Austria',
      'CH': 'Switzerland',
      'BE': 'Belgium',
      'IE': 'Ireland',
      'NZ': 'New Zealand',
      'IL': 'Israel',
      'SA': 'Saudi Arabia',
      'AE': 'UAE',
    };
    return names[code.toUpperCase()] ?? code;
  }
}
