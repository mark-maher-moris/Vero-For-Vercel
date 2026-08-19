import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../models/analytics.dart';
import '../models/deployment.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'superwall_service.dart';

/// Keys used to store widget data in HomeWidgetPreferences (Android) /
/// UserDefaults (iOS).
class WidgetKeys {
  static const String apiToken = 'vero_api_token';
  static const String teamId = 'vero_team_id';
  static const String isSubscribed = 'vero_is_subscribed';
  static const String isDemoMode = 'vero_is_demo_mode';
  static const String userId = 'vero_user_id';
  static const String lastUpdated = 'vero_last_updated';
  static const String projectsJson = 'vero_projects_json';
  static const String selectedProjectIds = 'vero_selected_project_ids';

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
  static const String analytics30DayTimeseries =
      'vero_analytics_30day_timeseries';

  // Countries widget data
  static const String countriesData = 'vero_countries_data';
  static const String countriesProjectName = 'vero_countries_project_name';

  // Users widget data
  static const String usersTotal24h = 'vero_users_total_24h';
  static const String usersLastHour = 'vero_users_last_hour';
  static const String usersBounceRate = 'vero_users_bounce_rate';
  static const String usersProjectName = 'vero_users_project_name';
  static const String usersTimeseries = 'vero_users_timeseries';
}

/// Names of the native widget classes for triggering updates.
class WidgetNames {
  static const String usersSmallAndroid = 'com.buildagon.vero.UsersSmallWidget';
  static const String logsMediumAndroid = 'com.buildagon.vero.LogsMediumWidget';
  static const String logsLargeAndroid = 'com.buildagon.vero.LogsLargeWidget';
  static const String analyticsLargeAndroid =
      'com.buildagon.vero.AnalyticsLargeWidget';
  static const String countriesMediumAndroid =
      'com.buildagon.vero.CountriesMediumWidget';

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
    required String? userId,
    required String? teamId,
    required bool isSubscribed,
    required bool isDemoMode,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token != null) {
        await HomeWidget.saveWidgetData<String>(WidgetKeys.apiToken, token);
      }
      if (userId != null && userId.isNotEmpty) {
        await HomeWidget.saveWidgetData<String>(WidgetKeys.userId, userId);
      }
      if (teamId != null) {
        await HomeWidget.saveWidgetData<String>(WidgetKeys.teamId, teamId);
      }
      await HomeWidget.saveWidgetData<bool>(
        WidgetKeys.isSubscribed,
        isSubscribed,
      );
      await HomeWidget.saveWidgetData<bool>(WidgetKeys.isDemoMode, isDemoMode);
    } catch (e) {
      if (kDebugMode) print('[WidgetService] pushAuthData error: $e');
    }
  }

  /// Clear all auth, token, and cached project data from native widgets (called on logout/expiration).
  Future<void> clearAuthData() async {
    try {
      await initialize();
      await HomeWidget.saveWidgetData<String>(WidgetKeys.apiToken, '');
      await HomeWidget.saveWidgetData<String>(WidgetKeys.userId, '');
      await HomeWidget.saveWidgetData<String>(WidgetKeys.teamId, '');
      await HomeWidget.saveWidgetData<bool>(WidgetKeys.isSubscribed, false);
      await HomeWidget.saveWidgetData<bool>(WidgetKeys.isDemoMode, false);
      await HomeWidget.saveWidgetData<String>(WidgetKeys.projectsJson, '[]');
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.selectedProjectIds,
        '[]',
      );

      // Clear every per-widget selection and cached display value so a logged
      // out account can never leave stale project data on the home screen.
      for (final key in [
        WidgetKeys.projectIdLogs,
        WidgetKeys.projectIdAnalytics,
        WidgetKeys.projectIdCountries,
        WidgetKeys.projectIdUsers,
        WidgetKeys.logsProjectName,
        WidgetKeys.logsDeploymentStatus,
        WidgetKeys.analyticsProjectName,
        WidgetKeys.countriesProjectName,
        WidgetKeys.usersProjectName,
        WidgetKeys.lastUpdated,
      ]) {
        await HomeWidget.saveWidgetData<String>(key, '');
      }

      await HomeWidget.saveWidgetData<String>(WidgetKeys.logsData, '[]');
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.analyticsSources,
        '[]',
      );
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.analyticsTimeseries,
        '[]',
      );
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.analytics30DayTimeseries,
        '[]',
      );
      await HomeWidget.saveWidgetData<String>(WidgetKeys.countriesData, '[]');
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.analyticsVisitors24h,
        '0',
      );
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.analyticsBounceRate,
        '0',
      );
      await HomeWidget.saveWidgetData<bool>(WidgetKeys.analyticsEnabled, true);
      await HomeWidget.saveWidgetData<String>(WidgetKeys.usersTotal24h, '0');
      await HomeWidget.saveWidgetData<String>(WidgetKeys.usersLastHour, '0');
      await HomeWidget.saveWidgetData<String>(WidgetKeys.usersBounceRate, '0');
      await HomeWidget.saveWidgetData<String>(WidgetKeys.usersTimeseries, '[]');
      await triggerAllWidgetUpdates();
    } catch (e) {
      if (kDebugMode) print('[WidgetService] clearAuthData error: $e');
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

  /// Save project selections for widgets.
  Future<void> setSelectedProjectIds(List<String> ids) async {
    try {
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.selectedProjectIds,
        jsonEncode(ids),
      );
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.projectIdLogs,
        ids.isNotEmpty ? ids.first : '',
      );
      if (ids.isEmpty) {
        await HomeWidget.saveWidgetData<String>(WidgetKeys.logsData, '[]');
      }
    } catch (e) {
      if (kDebugMode) print('[WidgetService] setSelectedProjectIds error: $e');
    }
  }

  /// Get project selections for widgets.
  Future<List<String>> getSelectedProjectIds() async {
    try {
      final json = await HomeWidget.getWidgetData<String>(
        WidgetKeys.selectedProjectIds,
      );
      if (json == null) return [];
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.cast<String>();
    } catch (e) {
      if (kDebugMode) print('[WidgetService] getSelectedProjectIds error: $e');
      return [];
    }
  }

  /// Refresh all widget data from the Vercel API and trigger widget redraws.
  Future<void> refreshAll({
    required VercelApi api,
    required List<Map<String, String>> projects,
  }) async {
    try {
      await initialize();
      final isSubscribed = await SuperwallService()
          .getCurrentSubscriptionStatus();
      await HomeWidget.saveWidgetData<bool>(
        WidgetKeys.isSubscribed,
        isSubscribed,
      );

      // Save projects list so native config screens can read them
      await pushProjects(
        projects
            .map((p) => {'id': p['id'] ?? '', 'name': p['name'] ?? ''})
            .toList(),
      );

      // Get stored project selections
      final selectedProjectIds = await getSelectedProjectIds();

      final projectIdLogs = await HomeWidget.getWidgetData<String>(
        WidgetKeys.projectIdLogs,
      );
      final projectIdAnalytics = await HomeWidget.getWidgetData<String>(
        WidgetKeys.projectIdAnalytics,
      );
      final projectIdCountries = await HomeWidget.getWidgetData<String>(
        WidgetKeys.projectIdCountries,
      );
      final projectIdUsers = await HomeWidget.getWidgetData<String>(
        WidgetKeys.projectIdUsers,
      );

      // Fetch data concurrently
      await Future.wait([
        _refreshLogs(api, selectedProjectIds, projectIdLogs),
        if (projectIdAnalytics != null && projectIdAnalytics.isNotEmpty)
          _refreshAnalytics(api, projectIdAnalytics),
        if (projectIdCountries != null && projectIdCountries.isNotEmpty)
          _refreshCountries(api, projectIdCountries),
        if (projectIdUsers != null && projectIdUsers.isNotEmpty)
          _refreshUsers(api, projectIdUsers),
      ]);

      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.lastUpdated,
        DateTime.now().toUtc().toIso8601String(),
      );
      await triggerAllWidgetUpdates();
    } catch (e) {
      if (kDebugMode) print('[WidgetService] refreshAll error: $e');
    }
  }

  Future<void> _refreshLogs(
    VercelApi api,
    List<String> selectedProjectIds,
    String? fallbackProjectId,
  ) async {
    try {
      String? targetProjectId = fallbackProjectId;
      String? deploymentId;

      // If we have multiple selected projects, we find the latest deployment across all of them
      if (selectedProjectIds.isNotEmpty) {
        List<Deployment> allDeployments = [];

        // Fetch deployments for each selected project to find the absolute latest
        // We do this in parallel for efficiency
        final deploymentsResults = await Future.wait(
          selectedProjectIds.map((id) => api.getDeployments(projectId: id)),
        );

        for (var deployments in deploymentsResults) {
          allDeployments.addAll(deployments);
        }

        if (allDeployments.isNotEmpty) {
          // Sort by date descending
          allDeployments.sort((a, b) => b.created.compareTo(a.created));
          final latest = allDeployments.first;

          targetProjectId = latest.projectId;
          deploymentId = latest.uid;

          await HomeWidget.saveWidgetData<String>(
            WidgetKeys.projectIdLogs,
            latest.projectId,
          );
          await HomeWidget.saveWidgetData<String>(
            WidgetKeys.logsProjectName,
            latest.name,
          );
          await HomeWidget.saveWidgetData<String>(
            WidgetKeys.logsDeploymentStatus,
            latest.state,
          );
        }
      }

      // Fallback to single project if no selected projects or no deployments found
      if (targetProjectId == null || targetProjectId.isEmpty) return;

      // Get the latest deployment if we don't have one yet
      if (deploymentId == null) {
        final deployments = await api.getDeployments(
          projectId: targetProjectId,
        );
        if (deployments.isEmpty) return;
        final latest = deployments.first;
        deploymentId = latest.uid;
        await HomeWidget.saveWidgetData<String>(
          WidgetKeys.logsProjectName,
          latest.name,
        );
        await HomeWidget.saveWidgetData<String>(
          WidgetKeys.logsDeploymentStatus,
          latest.state,
        );
      }

      // Get ownerId (project account ID, team ID, or user ID) for runtime logs API.
      final ownerId = await _resolveOwnerId(api, targetProjectId);
      if (ownerId == null || ownerId.isEmpty) {
        if (kDebugMode) {
          print('[WidgetService] No ownerId available for runtime logs');
        }
        await HomeWidget.saveWidgetData<String>(WidgetKeys.logsData, '[]');
        return;
      }

      final now = DateTime.now();
      final startDate = now
          .subtract(const Duration(hours: 1))
          .millisecondsSinceEpoch
          .toString();
      final endDate = now.millisecondsSinceEpoch.toString();

      // Fetch runtime logs using the same Hobby-safe window as the app
      final result = await api.getProjectLogs(
        projectId: targetProjectId,
        ownerId: ownerId,
        deploymentId: deploymentId,
        startDate: startDate,
        endDate: endDate,
      );

      // Transform Log objects into the simple format widgets expect
      final logEntries = <Map<String, dynamic>>[];
      for (final log in result.logs) {
        // Extract log lines from each Log entry
        for (final logLine in log.logs) {
          logEntries.add({
            'message': logLine.message,
            'level': logLine.level,
            'timestamp': logLine.timestamp.millisecondsSinceEpoch,
          });
        }
      }

      // The large widget supports 14 rows; the medium widget will display
      // the first 6 of the same shared payload.
      final widgetLogs = logEntries.take(14).toList();

      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.logsData,
        jsonEncode(widgetLogs),
      );
    } catch (e) {
      if (kDebugMode) print('[WidgetService] _refreshLogs error: $e');
    }
  }

  Future<void> _refreshAnalytics(VercelApi api, String projectId) async {
    try {
      final now = DateTime.now().toUtc();
      final from24h = now.subtract(const Duration(hours: 24)).toIso8601String();
      final from7d = now.subtract(const Duration(days: 7)).toIso8601String();
      final from30d = now.subtract(const Duration(days: 30)).toIso8601String();
      final to = now.toIso8601String();

      // Check if analytics is available by fetching overview (may throw if not enabled)
      AnalyticsOverview? overview;
      try {
        overview = await api.getAnalyticsOverview(
          projectId: projectId,
          from: from24h,
          to: to,
        );
        await HomeWidget.saveWidgetData<bool>(
          WidgetKeys.analyticsEnabled,
          true,
        );
      } catch (_) {
        await HomeWidget.saveWidgetData<bool>(
          WidgetKeys.analyticsEnabled,
          false,
        );
        return;
      }

      await HomeWidget.saveWidgetData<int>(
        WidgetKeys.analyticsVisitors24h,
        overview.devices,
      );
      await HomeWidget.saveWidgetData<int>(
        WidgetKeys.analyticsBounceRate,
        overview.bounceRate,
      );

      // Fetch 7-day timeseries for chart
      try {
        final timeseries = await api.getAnalyticsTimeseries(
          projectId: projectId,
          from: from7d,
          to: to,
        );
        final seriesData = timeseries
            .map((p) => {'date': p.key, 'value': p.devices})
            .toList();
        await HomeWidget.saveWidgetData<String>(
          WidgetKeys.analyticsTimeseries,
          jsonEncode(seriesData),
        );
      } catch (_) {}

      // Fetch 30-day timeseries for analytics widget chart
      try {
        final timeseries30d = await api.getAnalyticsTimeseries(
          projectId: projectId,
          from: from30d,
          to: to,
        );
        final seriesData30d = timeseries30d
            .map((p) => {'date': p.key, 'value': p.devices})
            .toList();
        await HomeWidget.saveWidgetData<String>(
          WidgetKeys.analytics30DayTimeseries,
          jsonEncode(seriesData30d),
        );
      } catch (_) {}

      // Fetch traffic sources (referrers)
      try {
        final sources = await api.getAnalyticsBreakdown(
          projectId: projectId,
          from: from7d,
          to: to,
          groupBy: 'referrer',
        );
        final sourcesData = sources
            .take(5)
            .map(
              (s) => {
                'source': s.key.isEmpty ? 'Direct' : s.key,
                'visitors': s.visitors,
              },
            )
            .toList();
        await HomeWidget.saveWidgetData<String>(
          WidgetKeys.analyticsSources,
          jsonEncode(sourcesData),
        );
      } catch (_) {}

      await _saveProjectName(api, projectId, WidgetKeys.analyticsProjectName);
    } catch (e) {
      await HomeWidget.saveWidgetData<bool>(WidgetKeys.analyticsEnabled, false);
      if (kDebugMode) print('[WidgetService] _refreshAnalytics error: $e');
    }
  }

  Future<void> _refreshCountries(VercelApi api, String projectId) async {
    try {
      await _saveProjectName(api, projectId, WidgetKeys.countriesProjectName);

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
      final countriesData = countries
          .take(6)
          .map(
            (c) => {
              'code': c.key,
              'name': _countryName(c.key),
              'visitors': c.visitors,
              'percentage': total > 0
                  ? ((c.visitors / total) * 100).round()
                  : 0,
            },
          )
          .toList();
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.countriesData,
        jsonEncode(countriesData),
      );
    } catch (e) {
      await HomeWidget.saveWidgetData<String>(WidgetKeys.countriesData, '[]');
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

      await HomeWidget.saveWidgetData<int>(
        WidgetKeys.usersTotal24h,
        overview.devices,
      );
      await HomeWidget.saveWidgetData<int>(
        WidgetKeys.usersBounceRate,
        overview.bounceRate,
      );

      // Fetch timeseries to estimate last-hour users as "online"
      final fromLastHour = now
          .subtract(const Duration(hours: 1))
          .toIso8601String();
      try {
        final recentOverview = await api.getAnalyticsOverview(
          projectId: projectId,
          from: fromLastHour,
          to: to,
        );
        // Store last hour visitors separately (used as "online now" approximation)
        await HomeWidget.saveWidgetData<int>(
          'vero_users_last_hour',
          recentOverview.devices,
        );
      } catch (_) {}

      // Fetch 24-hour timeseries for the chart
      try {
        final from24h = now
            .subtract(const Duration(hours: 24))
            .toIso8601String();
        final timeseries = await api.getAnalyticsTimeseries(
          projectId: projectId,
          from: from24h,
          to: to,
        );
        final seriesData = timeseries
            .map((p) => {'date': p.key, 'value': p.devices})
            .toList();
        await HomeWidget.saveWidgetData<String>(
          WidgetKeys.usersTimeseries,
          jsonEncode(seriesData),
        );
      } catch (_) {}

      await _saveProjectName(api, projectId, WidgetKeys.usersProjectName);
    } catch (e) {
      await HomeWidget.saveWidgetData<int>(WidgetKeys.usersTotal24h, 0);
      await HomeWidget.saveWidgetData<int>(WidgetKeys.usersLastHour, 0);
      await HomeWidget.saveWidgetData<String>(WidgetKeys.usersTimeseries, '[]');
      if (kDebugMode) print('[WidgetService] _refreshUsers error: $e');
    }
  }

  Future<void> triggerAllWidgetUpdates() async {
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

  /// Push demo data to widgets for demo mode display.
  Future<void> pushDemoData() async {
    try {
      await initialize();

      // Push auth data with demo mode enabled
      await HomeWidget.saveWidgetData<bool>(WidgetKeys.isSubscribed, false);
      await HomeWidget.saveWidgetData<bool>(WidgetKeys.isDemoMode, true);

      // Push demo logs
      final demoLogs = [
        {
          'message': 'Build started',
          'level': 'info',
          'timestamp': DateTime.now().millisecondsSinceEpoch - 300000,
        },
        {
          'message': 'Installing dependencies',
          'level': 'info',
          'timestamp': DateTime.now().millisecondsSinceEpoch - 240000,
        },
        {
          'message': 'Compiling TypeScript',
          'level': 'info',
          'timestamp': DateTime.now().millisecondsSinceEpoch - 180000,
        },
        {
          'message': 'Build complete',
          'level': 'success',
          'timestamp': DateTime.now().millisecondsSinceEpoch - 120000,
        },
      ];
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.logsData,
        jsonEncode(demoLogs),
      );
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.logsProjectName,
        'demo-project',
      );
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.logsDeploymentStatus,
        'READY',
      );

      // Push demo analytics
      await HomeWidget.saveWidgetData<int>(
        WidgetKeys.analyticsVisitors24h,
        2840,
      );
      await HomeWidget.saveWidgetData<int>(WidgetKeys.analyticsBounceRate, 38);
      final demoSources = [
        {'source': 'Direct', 'visitors': 1200},
        {'source': 'google.com', 'visitors': 840},
        {'source': 'twitter.com', 'visitors': 420},
        {'source': 'github.com', 'visitors': 210},
        {'source': 'ycombinator.com', 'visitors': 110},
      ];
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.analyticsSources,
        jsonEncode(demoSources),
      );
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.analyticsProjectName,
        'demo-project',
      );
      await HomeWidget.saveWidgetData<bool>(WidgetKeys.analyticsEnabled, true);
      final demoAnalytics30DayTimeseries = [
        {'date': 'Day 1', 'value': 850},
        {'date': 'Day 2', 'value': 920},
        {'date': 'Day 3', 'value': 780},
        {'date': 'Day 4', 'value': 1050},
        {'date': 'Day 5', 'value': 980},
        {'date': 'Day 6', 'value': 1200},
        {'date': 'Day 7', 'value': 1150},
        {'date': 'Day 8', 'value': 1380},
        {'date': 'Day 9', 'value': 1250},
        {'date': 'Day 10', 'value': 1420},
        {'date': 'Day 11', 'value': 1350},
        {'date': 'Day 12', 'value': 1580},
        {'date': 'Day 13', 'value': 1480},
        {'date': 'Day 14', 'value': 1720},
        {'date': 'Day 15', 'value': 1650},
        {'date': 'Day 16', 'value': 1890},
        {'date': 'Day 17', 'value': 1800},
        {'date': 'Day 18', 'value': 2050},
        {'date': 'Day 19', 'value': 1950},
        {'date': 'Day 20', 'value': 2180},
        {'date': 'Day 21', 'value': 2100},
        {'date': 'Day 22', 'value': 2350},
        {'date': 'Day 23', 'value': 2250},
        {'date': 'Day 24', 'value': 2480},
        {'date': 'Day 25', 'value': 2400},
        {'date': 'Day 26', 'value': 2650},
        {'date': 'Day 27', 'value': 2550},
        {'date': 'Day 28', 'value': 2800},
        {'date': 'Day 29', 'value': 2700},
        {'date': 'Day 30', 'value': 2950},
      ];
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.analytics30DayTimeseries,
        jsonEncode(demoAnalytics30DayTimeseries),
      );

      // Push demo countries
      final demoCountries = [
        {
          'code': 'US',
          'name': 'United States',
          'visitors': 1200,
          'percentage': 42,
        },
        {
          'code': 'GB',
          'name': 'United Kingdom',
          'visitors': 430,
          'percentage': 15,
        },
        {'code': 'DE', 'name': 'Germany', 'visitors': 290, 'percentage': 10},
        {'code': 'IN', 'name': 'India', 'visitors': 210, 'percentage': 7},
        {'code': 'CA', 'name': 'Canada', 'visitors': 180, 'percentage': 6},
      ];
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.countriesData,
        jsonEncode(demoCountries),
      );
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.countriesProjectName,
        'demo-project',
      );

      // Push demo users
      await HomeWidget.saveWidgetData<int>(WidgetKeys.usersTotal24h, 1240);
      await HomeWidget.saveWidgetData<int>(WidgetKeys.usersLastHour, 18);
      await HomeWidget.saveWidgetData<int>(WidgetKeys.usersBounceRate, 42);
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.usersProjectName,
        'demo-project',
      );
      final demoUsersTimeseries = [
        {'date': '0h', 'value': 120},
        {'date': '2h', 'value': 145},
        {'date': '4h', 'value': 132},
        {'date': '6h', 'value': 180},
        {'date': '8h', 'value': 165},
        {'date': '10h', 'value': 210},
        {'date': '12h', 'value': 195},
        {'date': '14h', 'value': 240},
        {'date': '16h', 'value': 225},
        {'date': '18h', 'value': 280},
        {'date': '20h', 'value': 265},
        {'date': '22h', 'value': 310},
      ];
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.usersTimeseries,
        jsonEncode(demoUsersTimeseries),
      );

      // Save last updated timestamp
      await HomeWidget.saveWidgetData<String>(
        WidgetKeys.lastUpdated,
        DateTime.now().toUtc().toIso8601String(),
      );

      await triggerAllWidgetUpdates();
    } catch (e) {
      if (kDebugMode) print('[WidgetService] pushDemoData error: $e');
    }
  }

  /// Save a project selection for a specific widget type.
  /// [widgetType]: 'logs' | 'analytics' | 'countries' | 'users'
  Future<void> setProjectForWidget(
    String widgetType,
    String projectId,
    String projectName,
  ) async {
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
    await triggerAllWidgetUpdates();
  }

  /// Listen for widget tap events (when user taps a widget to open the app).
  Stream<Uri?> get widgetClicked {
    if (kDebugMode) {
      print('[WidgetService] widgetClicked stream accessed');
    }
    return HomeWidget.widgetClicked;
  }

  /// Get the selected project ID for a specific widget type.
  Future<String?> getProjectForWidget(String widgetType) async {
    String key;
    switch (widgetType) {
      case 'logs':
        key = WidgetKeys.projectIdLogs;
        break;
      case 'analytics':
        key = WidgetKeys.projectIdAnalytics;
        break;
      case 'countries':
        key = WidgetKeys.projectIdCountries;
        break;
      case 'users':
        key = WidgetKeys.projectIdUsers;
        break;
      default:
        return null;
    }
    return await HomeWidget.getWidgetData<String>(key);
  }

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

  Future<String?> _resolveOwnerId(VercelApi api, String projectId) async {
    try {
      final projects = await api.getProjectsList();
      for (final project in projects) {
        if (project.id == projectId && project.accountId != null) {
          return project.accountId;
        }
      }
    } catch (_) {}

    if (api.teamId != null && api.teamId!.isNotEmpty) return api.teamId;

    final storedTeamId = await HomeWidget.getWidgetData<String>(
      WidgetKeys.teamId,
    );
    if (storedTeamId != null && storedTeamId.isNotEmpty) return storedTeamId;

    return HomeWidget.getWidgetData<String>(WidgetKeys.userId);
  }

  Future<void> _saveProjectName(
    VercelApi api,
    String projectId,
    String key,
  ) async {
    try {
      final projects = await api.getProjectsList();
      for (final project in projects) {
        if (project.id == projectId) {
          await HomeWidget.saveWidgetData<String>(key, project.name);
          return;
        }
      }
    } catch (_) {}
  }
}
