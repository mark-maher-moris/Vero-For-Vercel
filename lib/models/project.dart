import 'cron_job.dart';

class Project {
  final String id;
  final String name;
  final String? accountId;
  final String? framework;
  final String? nodeVersion;
  final String? buildCommand;
  final String? devCommand;
  final String? installCommand;
  final String? outputDirectory;
  final String? rootDirectory;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool? publicSource;
  final bool? directoryListing;
  final bool? live;
  final bool? paused;
  final bool? autoExposeSystemEnvs;
  final bool? gitForkProtection;
  final Map<String, dynamic>? targets;
  final List<dynamic>? latestDeployments;
  final List<dynamic>? env;
  final Map<String, dynamic>? link;
  final List<dynamic>? alias;
  final Map<String, dynamic>? analytics;
  final Map<String, dynamic>? webAnalytics;
  final Map<String, dynamic>? speedInsights;
  final Map<String, dynamic>? security;
  final Map<String, dynamic>? resourceConfig;
  final Map<String, dynamic>? deploymentExpiration;
  final Map<String, dynamic>? ssoProtection;
  final Map<String, dynamic>? rollingRelease;
  final Map<String, dynamic>? passwordProtection;
  final Map<String, dynamic>? gitComments;
  final Map<String, dynamic>? gitProviderOptions;
  final Map<String, dynamic>? oidcTokenConfig;
  final String? serverlessFunctionRegion;
  final bool? serverlessFunctionZeroConfigFailover;
  final ProjectCrons? crons;
  String? _cachedLogoUrl;

  /// Static cache of URLs known to return 401 (shared across all Project instances)
  static final Set<String> _known401Urls = {};

  Project({
    required this.id,
    required this.name,
    this.accountId,
    this.framework,
    this.nodeVersion,
    this.buildCommand,
    this.devCommand,
    this.installCommand,
    this.outputDirectory,
    this.rootDirectory,
    required this.createdAt,
    required this.updatedAt,
    this.publicSource,
    this.directoryListing,
    this.live,
    this.paused,
    this.autoExposeSystemEnvs,
    this.gitForkProtection,
    this.targets,
    this.latestDeployments,
    this.env,
    this.link,
    this.alias,
    this.analytics,
    this.webAnalytics,
    this.speedInsights,
    this.security,
    this.resourceConfig,
    this.deploymentExpiration,
    this.ssoProtection,
    this.rollingRelease,
    this.passwordProtection,
    this.gitComments,
    this.gitProviderOptions,
    this.oidcTokenConfig,
    this.serverlessFunctionRegion,
    this.serverlessFunctionZeroConfigFailover,
    this.crons,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      accountId: json['accountId'] as String?,
      framework: json['framework'] as String?,
      nodeVersion: json['nodeVersion'] as String?,
      buildCommand: json['buildCommand'] as String?,
      devCommand: json['devCommand'] as String?,
      installCommand: json['installCommand'] as String?,
      outputDirectory: json['outputDirectory'] as String?,
      rootDirectory: json['rootDirectory'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      publicSource: json['publicSource'] as bool?,
      directoryListing: json['directoryListing'] as bool?,
      live: json['live'] as bool?,
      paused: json['paused'] as bool?,
      autoExposeSystemEnvs: json['autoExposeSystemEnvs'] as bool?,
      gitForkProtection: json['gitForkProtection'] as bool?,
      targets: json['targets'] as Map<String, dynamic>?,
      latestDeployments: json['latestDeployments'] as List<dynamic>?,
      env: json['env'] as List<dynamic>?,
      link: json['link'] as Map<String, dynamic>?,
      alias: json['alias'] as List<dynamic>?,
      analytics: json['analytics'] as Map<String, dynamic>?,
      webAnalytics: json['webAnalytics'] as Map<String, dynamic>?,
      speedInsights: json['speedInsights'] as Map<String, dynamic>?,
      security: json['security'] as Map<String, dynamic>?,
      resourceConfig: json['resourceConfig'] as Map<String, dynamic>?,
      deploymentExpiration: json['deploymentExpiration'] as Map<String, dynamic>?,
      ssoProtection: json['ssoProtection'] as Map<String, dynamic>?,
      rollingRelease: json['rollingRelease'] as Map<String, dynamic>?,
      passwordProtection: json['passwordProtection'] as Map<String, dynamic>?,
      gitComments: json['gitComments'] as Map<String, dynamic>?,
      gitProviderOptions: json['gitProviderOptions'] as Map<String, dynamic>?,
      oidcTokenConfig: json['oidcTokenConfig'] as Map<String, dynamic>?,
      serverlessFunctionRegion: json['serverlessFunctionRegion'] as String?,
      serverlessFunctionZeroConfigFailover: json['serverlessFunctionZeroConfigFailover'] as bool?,
      crons: json['crons'] != null
          ? ProjectCrons.fromJson(json['crons'] as Map<String, dynamic>)
          : null,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  List<String> get allUrls {
    final urls = <String>{}; // Use Set to avoid duplicates

    // Add production URL from targets
    if (targets != null && targets!.containsKey('production')) {
      final prod = targets!['production'];
      if (prod is Map) {
        // Add main URL
        if (prod.containsKey('url')) {
          urls.add(prod['url'] as String);
        }
        // Add custom domain aliases
        if (prod.containsKey('alias')) {
          final aliases = prod['alias'];
          if (aliases is List) {
            for (final alias in aliases) {
              if (alias is String && alias.isNotEmpty) {
                urls.add(alias);
              }
            }
          }
        }
      }
    }

    // Add preview URL from targets
    if (targets != null && targets!.containsKey('preview')) {
      final preview = targets!['preview'];
      if (preview is Map && preview.containsKey('url')) {
        urls.add(preview['url'] as String);
      }
    }

    // Add latest deployment URL
    if (latestDeployments != null && latestDeployments!.isNotEmpty) {
      final latest = latestDeployments!.first;
      final url = latest['url'] as String?;
      if (url != null && url.isNotEmpty) {
        urls.add(url);
      }
    }

    return urls.toList();
  }

  bool get _isProtected {
    // Check password protection
    if (passwordProtection != null && passwordProtection!['password'] != null) {
      return true;
    }
    // Check SSO protection
    if (ssoProtection != null && ssoProtection!['ssoRequired'] == true) {
      return true;
    }
    // Check security field for Vercel Authentication (deployment protection)
    if (security != null && security!['deploymentProtection'] != null) {
      final protection = security!['deploymentProtection'];
      if (protection == 'enabled' || protection == true) {
        return true;
      }
    }
    return false;
  }

  /// Mark a URL as returning 401 (shared across all projects)
  static void markUrlAs401(String url) {
    _known401Urls.add(url);
  }

  List<String> get logoUrls {
    final urls = <String>[];

    // Skip logo fetching for protected projects (avoids 401 errors)
    if (_isProtected) {
      return urls;
    }

    // Return cached URL first if available (but only if not known 401)
    if (_cachedLogoUrl != null && _cachedLogoUrl!.isNotEmpty) {
      if (!_known401Urls.contains(_cachedLogoUrl)) {
        urls.add(_cachedLogoUrl!);
        return urls;
      }
      // Cached URL is 401, clear it and continue
      _cachedLogoUrl = null;
    }

    String? baseUrl;

    // Get the first available URL from allUrls (includes actual deployment URLs)
    if (allUrls.isNotEmpty) {
      final firstUrl = allUrls.first;
      baseUrl = firstUrl.startsWith('http') ? firstUrl : 'https://$firstUrl';
    }

    // Fallback to default Vercel URL
    baseUrl ??= 'https://${name}.vercel.app';

    // Try common logo paths in order of likelihood
    urls.addAll([
      '$baseUrl/favicon.ico',
      '$baseUrl/favicon.png',
      '$baseUrl/logo.png',
      '$baseUrl/logo.svg',
      '$baseUrl/icon.png',
      '$baseUrl/assets/logo.png',
      '$baseUrl/public/logo.png',
      '$baseUrl/img/logo.png',
      '$baseUrl/images/logo.png',
      '$baseUrl/_next/image?url=%2Flogo.png&w=128&q=75', // Next.js optimized image
      '$baseUrl/_next/static/media/logo.png', // Next.js static assets
    ]);

    // Filter out URLs known to return 401
    return urls.where((url) => !_known401Urls.contains(url)).toList();
  }

  void setCachedLogoUrl(String url) {
    _cachedLogoUrl = url;
  }
}

