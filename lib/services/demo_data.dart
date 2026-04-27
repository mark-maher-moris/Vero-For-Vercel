import 'dart:math';

import '../models/project.dart';
import '../models/deployment.dart';
import '../models/deployment_file.dart';
import '../models/domain.dart';
import '../models/env_var.dart';
import '../models/security.dart';
import '../models/analytics.dart';

/// Static demo data for showcase mode.
///
/// All projects listed here are real, well-known open-source applications
/// deployed on Vercel. This gives users a realistic tour of the app before
/// they connect their own Vercel account.
class DemoData {
  DemoData._();

  static const String demoTeamId = 'team_vero_demo';
  static const String demoUserId = 'user_vero_demo';

  /// The demo user (wraps the real /www/user response shape).
  static Map<String, dynamic> buildUserResponse() {
    return {
      'id': demoUserId,
      'email': 'demo@vero.app',
      'name': 'Vero Demo',
      'username': 'vero-demo',
      'avatar': null,
      'defaultTeamId': demoTeamId,
      'plan': 'pro',
      'createdAt': DateTime.now().subtract(const Duration(days: 412)).millisecondsSinceEpoch,
    };
  }

  /// List of demo teams returned by /v2/teams.
  static Map<String, dynamic> buildTeamsResponse() {
    return {
      'teams': [
        {
          'id': demoTeamId,
          'slug': 'vero-demo',
          'name': 'Vero Demo Team',
          'avatar': null,
          'createdAt': DateTime.now().subtract(const Duration(days: 400)).millisecondsSinceEpoch,
        },
      ],
    };
  }

  /// Build the list of demo projects (as `Project` models).
  ///
  /// Each project is a real, public open-source app deployed on Vercel with
  /// reachable URLs – this gives users real favicons, real screenshots when
  /// they follow the links, and a believable product tour.
  static List<Project> buildProjects() {
    final now = DateTime.now();

    return [
      _project(
        id: 'prj_demo_next_commerce',
        name: 'next-commerce',
        framework: 'nextjs',
        url: 'demo.vercel.store',
        alias: ['demo.vercel.store', 'next-commerce-demo.vercel.app', 'shop.vercel.store'],
        repo: 'vercel/commerce',
        branch: 'main',
        commitMessage: 'feat(cart): optimistic UI updates for line items and improved checkout flow',
        commitSha: 'a3f51cd2',
        state: 'READY',
        createdAgo: const Duration(days: 318),
        updatedAgo: const Duration(hours: 2),
        hasAnalytics: true,
        hasWebAnalytics: true,
        hasFirewall: true,
        hasCronJobs: true,
        now: now,
      ),
      _project(
        id: 'prj_demo_shadcn_ui',
        name: 'shadcn-ui',
        framework: 'nextjs',
        url: 'ui.shadcn.com',
        alias: ['ui.shadcn.com', 'shadcn-ui-docs.vercel.app'],
        repo: 'shadcn-ui/ui',
        branch: 'main',
        commitMessage: 'docs(calendar): add range selection example with date-fns integration',
        commitSha: '7d8b91fe',
        state: 'READY',
        createdAgo: const Duration(days: 512),
        updatedAgo: const Duration(hours: 6),
        hasAnalytics: true,
        hasWebAnalytics: true,
        now: now,
      ),
      _project(
        id: 'prj_demo_cal_com',
        name: 'cal-com',
        framework: 'nextjs',
        url: 'cal.com',
        alias: ['cal.com', 'www.cal.com', 'app.cal.com'],
        repo: 'calcom/cal.com',
        branch: 'main',
        commitMessage: 'fix(booking): handle timezone dst transitions correctly for international users',
        commitSha: 'c82a714b',
        state: 'READY',
        createdAgo: const Duration(days: 980),
        updatedAgo: const Duration(minutes: 47),
        hasAnalytics: true,
        hasWebAnalytics: true,
        hasFirewall: true,
        hasCronJobs: true,
        now: now,
      ),
      _project(
        id: 'prj_demo_docs',
        name: 'vero-docs',
        framework: 'nextjs',
        url: 'docs.vero.app',
        alias: ['docs.vero.app', 'vero-docs.vercel.app'],
        repo: 'buildagon/vero-docs',
        branch: 'main',
        commitMessage: 'docs: add getting-started guide for teams and advanced configuration',
        commitSha: 'e10cc431',
        state: 'BUILDING',
        createdAgo: const Duration(days: 64),
        updatedAgo: const Duration(minutes: 3),
        hasWebAnalytics: true,
        now: now,
      ),
      _project(
        id: 'prj_demo_marketing',
        name: 'vero-marketing',
        framework: 'astro',
        url: 'vero.app',
        alias: ['vero.app', 'www.vero.app', 'marketing.vero.app'],
        repo: 'buildagon/vero-marketing',
        branch: 'production',
        commitMessage: 'feat(pricing): add annual toggle with 20% off and updated enterprise tier',
        commitSha: '4b2e70af',
        state: 'READY',
        createdAgo: const Duration(days: 128),
        updatedAgo: const Duration(hours: 11),
        hasAnalytics: true,
        hasWebAnalytics: true,
        hasFirewall: true,
        hasCronJobs: true,
        now: now,
      ),
    ];
  }

  static Project _project({
    required String id,
    required String name,
    required String framework,
    required String url,
    required List<String> alias,
    required String repo,
    required String branch,
    required String commitMessage,
    required String commitSha,
    required String state,
    required Duration createdAgo,
    required Duration updatedAgo,
    bool hasAnalytics = false,
    bool hasWebAnalytics = false,
    bool hasFirewall = false,
    bool hasCronJobs = false,
    required DateTime now,
  }) {
    return Project.fromJson({
      'id': id,
      'name': name,
      'accountId': demoTeamId,
      'framework': framework,
      'nodeVersion': '20.x',
      'buildCommand': framework == 'astro' ? 'astro build' : 'next build',
      'devCommand': framework == 'astro' ? 'astro dev' : 'next dev',
      'installCommand': 'pnpm install',
      'outputDirectory': framework == 'astro' ? 'dist' : '.next',
      'rootDirectory': null,
      'createdAt': now.subtract(createdAgo).millisecondsSinceEpoch,
      'updatedAt': now.subtract(updatedAgo).millisecondsSinceEpoch,
      'live': state == 'READY',
      'paused': false,
      'targets': {
        'production': {
          'id': 'dpl_${id}_prod',
          'url': url,
          'alias': alias,
          'readyState': state,
          'target': 'production',
          'meta': {
            'githubCommitRef': branch,
            'githubCommitSha': '${commitSha}000000000000000000000000000',
            'githubCommitMessage': commitMessage,
            'githubCommitRepo': repo,
          },
        },
      },
      'latestDeployments': [
        {
          'id': 'dpl_${id}_prod',
          'url': url,
          'readyState': state,
          'target': 'production',
          'createdAt': now.subtract(updatedAgo).millisecondsSinceEpoch,
          'meta': {
            'githubCommitRef': branch,
            'githubCommitSha': '${commitSha}000000000000000000000000000',
            'githubCommitMessage': commitMessage,
            'githubCommitRepo': repo,
          },
        },
      ],
      'link': {
        'type': 'github',
        'repo': repo,
        'repoId': id.hashCode.abs(),
        'org': repo.split('/').first,
        'productionBranch': branch,
      },
      'alias': alias,
      if (hasAnalytics)
        'analytics': {
          'id': 'analytics_$id',
          'enabledAt': now.subtract(createdAgo ~/ 2).millisecondsSinceEpoch,
        },
      if (hasWebAnalytics)
        'webAnalytics': {
          'id': 'wa_$id',
          'enabledAt': now.subtract(createdAgo ~/ 2).millisecondsSinceEpoch,
        },
      if (hasFirewall)
        'security': {
          'firewallEnabled': true,
          'attackModeEnabled': false,
        },
      'serverlessFunctionRegion': 'iad1',
      if (hasCronJobs)
        'crons': {
          'enabledAt': now.subtract(const Duration(days: 60)).millisecondsSinceEpoch,
          'updatedAt': now.subtract(const Duration(days: 5)).millisecondsSinceEpoch,
          'deploymentId': 'dpl_${id}_prod',
          'definitions': _buildCronDefinitions(url),
        },
    });
  }

  static List<Map<String, dynamic>> _buildCronDefinitions(String host) {
    return [
      {
        'host': host,
        'path': '/api/cron/sync',
        'schedule': '0 */6 * * *', // Every 6 hours
        'description': 'Synchronize inventory data with external warehouse providers.',
      },
      {
        'host': host,
        'path': '/api/cron/cleanup',
        'schedule': '0 0 * * 0', // Weekly on Sunday
        'description': 'Hard delete expired sessions and temporary build artifacts from the database.',
      },
      {
        'host': host,
        'path': '/api/cron/health-check',
        'schedule': '*/5 * * * *', // Every 5 minutes
        'description': 'Perform heartbeat checks on all upstream microservices.',
      },
      {
        'host': host,
        'path': '/api/cron/generate-sitemap',
        'schedule': '0 2 * * *', // Every day at 2 AM
        'description': 'Re-index and generate the XML sitemap for SEO optimizations.',
      },
      {
        'host': host,
        'path': '/api/cron/backup-db',
        'schedule': '0 4 * * *', // Every day at 4 AM
        'description': 'Trigger automated database snapshots and upload to S3 bucket.',
      },
    ];
  }

  /// Build a list of demo deployments for a given project.
  static List<Deployment> buildDeployments(Project project) {
    final now = DateTime.now();
    final repo = (project.link?['repo'] as String?) ?? 'buildagon/${project.name}';
    final branch = (project.link?['productionBranch'] as String?) ?? 'main';
    final prodUrl = project.allUrls.isNotEmpty ? project.allUrls.first : '${project.name}.vercel.app';

    final deployments = <Deployment>[];

    final messages = [
      'feat: add new dashboard widgets',
      'fix: correct pagination edge case on search',
      'chore(deps): bump framer-motion to 11.3.0',
      'refactor: extract analytics provider to hooks',
      'perf: lazy-load images below the fold',
      'style: update button focus ring tokens',
      'docs: expand README with deploy instructions',
      'test: add e2e coverage for checkout flow',
      'feat(api): add rate limiting middleware',
      'fix(auth): session refresh for long-lived tabs',
    ];

    final states = ['READY', 'READY', 'READY', 'READY', 'ERROR', 'READY', 'READY', 'CANCELED', 'READY', 'READY'];

    for (var i = 0; i < 10; i++) {
      final createdAt = now.subtract(Duration(hours: i * 8 + 1));
      final buildingAt = createdAt.add(const Duration(seconds: 3));
      final ready = createdAt.add(Duration(seconds: 38 + (i * 3) % 40));
      final state = states[i];
      final isProd = i == 0 || i == 3 || i == 6;

      deployments.add(Deployment.fromJson({
        'uid': 'dpl_${project.id}_$i',
        'name': project.name,
        'url': i == 0
            ? prodUrl
            : '${project.name}-git-${branch}-vero-demo-${_shortHash(i)}.vercel.app',
        'created': createdAt.millisecondsSinceEpoch,
        'state': state,
        'readyState': state,
        'inspectorUrl': 'https://vercel.com/vero-demo/${project.name}/dpl_${project.id}_$i',
        'projectId': project.id,
        'target': isProd ? 'production' : 'preview',
        'source': 'git',
        'meta': {
          'githubCommitRef': isProd ? branch : 'feat/preview-$i',
          'githubCommitSha': '${_shortHash(i)}0a1b2c3d4e5f6',
          'githubCommitMessage': messages[i % messages.length],
          'githubCommitRepo': repo,
          'githubCommitAuthorName': 'vero-demo',
        },
        'creator': {
          'uid': demoUserId,
          'email': 'demo@vero.app',
          'username': 'vero-demo',
          'githubLogin': 'vero-demo',
        },
        'readySubstate': isProd ? 'PROMOTED' : null,
        'isRollbackCandidate': isProd,
        'buildingAt': buildingAt.millisecondsSinceEpoch,
        'ready': state == 'READY' ? ready.millisecondsSinceEpoch : null,
        'checksState': 'completed',
        'checksConclusion': state == 'READY' ? 'succeeded' : (state == 'ERROR' ? 'failed' : 'canceled'),
        if (state == 'ERROR') 'errorCode': 'BUILD_UTILS_SPAWN_1',
        if (state == 'ERROR') 'errorMessage': 'Command "pnpm build" exited with 1',
      }));
    }

    return deployments;
  }

  /// Environment variables for demo projects.
  static List<EnvVar> buildEnvVars(String projectId) {
    final now = DateTime.now();
    return [
      EnvVar.fromJson({
        'id': 'env_${projectId}_1',
        'key': 'DATABASE_URL',
        'value': 'postgres://readonly:••••••@db.vero.app:5432/app',
        'type': 'encrypted',
        'target': ['production', 'preview'],
        'createdAt': now.subtract(const Duration(days: 210)).millisecondsSinceEpoch,
        'updatedAt': now.subtract(const Duration(days: 18)).millisecondsSinceEpoch,
        'encrypted': true,
      }),
      EnvVar.fromJson({
        'id': 'env_${projectId}_2',
        'key': 'NEXT_PUBLIC_APP_URL',
        'value': 'https://vero.app',
        'type': 'plain',
        'target': ['production', 'preview', 'development'],
        'createdAt': now.subtract(const Duration(days: 300)).millisecondsSinceEpoch,
      }),
      EnvVar.fromJson({
        'id': 'env_${projectId}_3',
        'key': 'STRIPE_SECRET_KEY',
        'value': 'sk_live_••••••••••••••••••••••••',
        'type': 'encrypted',
        'target': ['production'],
        'createdAt': now.subtract(const Duration(days: 180)).millisecondsSinceEpoch,
        'encrypted': true,
      }),
      EnvVar.fromJson({
        'id': 'env_${projectId}_4',
        'key': 'NEXT_PUBLIC_ANALYTICS_ID',
        'value': 'G-VEROPAPP42',
        'type': 'plain',
        'target': ['production', 'preview', 'development'],
        'createdAt': now.subtract(const Duration(days: 95)).millisecondsSinceEpoch,
      }),
      EnvVar.fromJson({
        'id': 'env_${projectId}_5',
        'key': 'RESEND_API_KEY',
        'value': 're_••••••••••••••••••••',
        'type': 'encrypted',
        'target': ['production', 'preview'],
        'createdAt': now.subtract(const Duration(days: 56)).millisecondsSinceEpoch,
        'encrypted': true,
      }),
    ];
  }

  /// Project-level domains.
  static List<Map<String, dynamic>> buildProjectDomains(Project project) {
    final now = DateTime.now();
    final aliases = project.allUrls.toList();
    return aliases.asMap().entries.map((e) {
      final i = e.key;
      final name = e.value;
      return {
        'name': name,
        'apexName': name.split('.').length > 2
            ? name.split('.').sublist(1).join('.')
            : name,
        'projectId': project.id,
        'redirect': null,
        'redirectStatusCode': null,
        'gitBranch': i == 0 ? null : 'main',
        'verified': true,
        'verification': [],
        'createdAt': now.subtract(Duration(days: 120 + i * 20)).millisecondsSinceEpoch,
      };
    }).toList();
  }

  /// Global domains across all teams.
  static List<Domain> buildDomains() {
    final now = DateTime.now();
    final entries = [
      ('vero.app', true, 120),
      ('docs.vero.app', true, 95),
      ('demo.vercel.store', true, 64),
      ('cal.com', true, 410),
      ('ui.shadcn.com', true, 320),
    ];
    return entries.map((e) {
      return Domain.fromJson({
        'id': 'dom_${e.$1.replaceAll('.', '_')}',
        'name': e.$1,
        'verified': e.$2,
        'createdAt': now.subtract(Duration(days: e.$3)).millisecondsSinceEpoch,
      });
    }).toList();
  }

  /// DNS records for a given demo domain.
  static List<Map<String, dynamic>> buildDnsRecords(String domain) {
    final now = DateTime.now();
    return [
      {
        'id': 'rec_${domain}_a',
        'name': '',
        'type': 'A',
        'value': '76.76.21.21',
        'ttl': 60,
        'createdAt': now.subtract(const Duration(days: 100)).millisecondsSinceEpoch,
      },
      {
        'id': 'rec_${domain}_cname',
        'name': 'www',
        'type': 'CNAME',
        'value': 'cname.vercel-dns.com',
        'ttl': 60,
        'createdAt': now.subtract(const Duration(days: 100)).millisecondsSinceEpoch,
      },
      {
        'id': 'rec_${domain}_mx',
        'name': '',
        'type': 'MX',
        'value': 'feedback-smtp.eu-west-1.amazonses.com',
        'priority': 10,
        'ttl': 3600,
        'createdAt': now.subtract(const Duration(days: 80)).millisecondsSinceEpoch,
      },
      {
        'id': 'rec_${domain}_txt_spf',
        'name': '',
        'type': 'TXT',
        'value': 'v=spf1 include:amazonses.com ~all',
        'ttl': 3600,
        'createdAt': now.subtract(const Duration(days: 80)).millisecondsSinceEpoch,
      },
    ];
  }

  /// Monthly usage totals returned by /v4/usage.
  static Map<String, dynamic> buildUsage() {
    return {
      'total': {
        'requests': 2847392,
        'bandwidth': 184 * 1024 * 1024 * 1024, // 184 GB
        'executionTime': 112_347_000, // ms
      },
      'limits': {
        'requests': 10000000,
        'bandwidth': 1024 * 1024 * 1024 * 1024, // 1 TB
      },
    };
  }

  /// Monthly billing summary returned by /v1/billing/charges.
  static Map<String, dynamic> buildBilling() {
    return {
      'charges': [
        {
          'id': 'ch_demo_pro',
          'name': 'Pro Plan',
          'amount': 20.00,
          'currency': 'usd',
          'date': DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch,
        },
        {
          'id': 'ch_demo_bandwidth',
          'name': 'Additional Bandwidth',
          'amount': 12.50,
          'currency': 'usd',
          'date': DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch,
        },
      ],
    };
  }

  /// Attack-challenge mode status (always off in demo).
  static AttackModeStatus buildAttackMode() {
    return AttackModeStatus(enabled: false);
  }

  /// Firewall configuration with representative rules.
  static FirewallConfig buildFirewallConfig() {
    return FirewallConfig(
      enabled: true,
      rules: [
        FirewallRule(
          id: 'rule_demo_bots',
          name: 'Block known bad bots',
          action: 'deny',
          hostname: '*',
          isWAFRule: true,
        ),
        FirewallRule(
          id: 'rule_demo_ratelimit',
          name: 'Rate limit /api/*',
          action: 'rate_limit',
          rateLimit: 100,
          rateLimitWindow: '1m',
        ),
        FirewallRule(
          id: 'rule_demo_admin',
          name: 'Challenge /admin',
          action: 'challenge',
          hostname: '*',
        ),
      ],
      managedRulesets: [
        ManagedRuleset(
          id: 'owasp-core',
          name: 'OWASP Core Rule Set',
          enabled: true,
          action: 'challenge',
          description: 'Protects against common web vulnerabilities (SQLi, XSS, RFI).',
        ),
        ManagedRuleset(
          id: 'wordpress',
          name: 'WordPress Rule Set',
          enabled: false,
          action: 'log',
          description: 'Mitigations for WordPress-specific attacks.',
        ),
      ],
      ips: ['185.220.101.34', '45.155.205.12'],
    );
  }

  /// No active attacks in demo.
  static List<ActiveAttack> buildActiveAttacks() => const [];

  /// Deployment files for demo mode.
  static List<DeploymentFile> buildDeploymentFiles(String deploymentId) {
    return [
      DeploymentFile(
        name: 'src',
        type: 'directory',
        uid: 'dir_src',
        mode: '0755',
        link: 'demo://file/src',
        children: [
          DeploymentFile(
            name: 'app',
            type: 'directory',
            uid: 'dir_app',
            mode: '0755',
            link: 'demo://file/src/app',
            children: [
              DeploymentFile(
                name: 'page.tsx',
                type: 'file',
                uid: 'file_page',
                mode: '0644',
                contentType: 'text/typescript',
                link: 'demo://file/page.tsx',
              ),
              DeploymentFile(
                name: 'layout.tsx',
                type: 'file',
                uid: 'file_layout',
                mode: '0644',
                contentType: 'text/typescript',
                link: 'demo://file/layout.tsx',
              ),
              DeploymentFile(
                name: 'globals.css',
                type: 'file',
                uid: 'file_globals',
                mode: '0644',
                contentType: 'text/css',
                link: 'demo://file/globals.css',
              ),
              DeploymentFile(
                name: 'about',
                type: 'directory',
                uid: 'dir_about',
                mode: '0755',
                link: 'demo://file/src/app/about',
                children: [
                  DeploymentFile(
                    name: 'page.tsx',
                    type: 'file',
                    uid: 'file_about_page',
                    mode: '0644',
                    contentType: 'text/typescript',
                    link: 'demo://file/about/page.tsx',
                  ),
                ],
              ),
              DeploymentFile(
                name: 'pricing',
                type: 'directory',
                uid: 'dir_pricing',
                mode: '0755',
                link: 'demo://file/src/app/pricing',
                children: [
                  DeploymentFile(
                    name: 'page.tsx',
                    type: 'file',
                    uid: 'file_pricing_page',
                    mode: '0644',
                    contentType: 'text/typescript',
                    link: 'demo://file/pricing/page.tsx',
                  ),
                ],
              ),
              DeploymentFile(
                name: 'blog',
                type: 'directory',
                uid: 'dir_blog',
                mode: '0755',
                link: 'demo://file/src/app/blog',
                children: [
                  DeploymentFile(
                    name: '[slug]',
                    type: 'directory',
                    uid: 'dir_blog_slug',
                    mode: '0755',
                    link: 'demo://file/src/app/blog/[slug]',
                    children: [
                      DeploymentFile(
                        name: 'page.tsx',
                        type: 'file',
                        uid: 'file_blog_page',
                        mode: '0644',
                        contentType: 'text/typescript',
                        link: 'demo://file/blog/[slug]/page.tsx',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          DeploymentFile(
            name: 'components',
            type: 'directory',
            uid: 'dir_components',
            mode: '0755',
            link: 'demo://file/src/components',
            children: [
              DeploymentFile(
                name: 'ui',
                type: 'directory',
                uid: 'dir_ui',
                mode: '0755',
                link: 'demo://file/src/components/ui',
                children: [
                  DeploymentFile(
                    name: 'button.tsx',
                    type: 'file',
                    uid: 'file_button',
                    mode: '0644',
                    contentType: 'text/typescript',
                    link: 'demo://file/button.tsx',
                  ),
                  DeploymentFile(
                    name: 'card.tsx',
                    type: 'file',
                    uid: 'file_card',
                    mode: '0644',
                    contentType: 'text/typescript',
                    link: 'demo://file/card.tsx',
                  ),
                  DeploymentFile(
                    name: 'input.tsx',
                    type: 'file',
                    uid: 'file_input',
                    mode: '0644',
                    contentType: 'text/typescript',
                    link: 'demo://file/input.tsx',
                  ),
                ],
              ),
              DeploymentFile(
                name: 'Header.tsx',
                type: 'file',
                uid: 'file_header',
                mode: '0644',
                contentType: 'text/typescript',
                link: 'demo://file/Header.tsx',
              ),
              DeploymentFile(
                name: 'Footer.tsx',
                type: 'file',
                uid: 'file_footer',
                mode: '0644',
                contentType: 'text/typescript',
                link: 'demo://file/Footer.tsx',
              ),
            ],
          ),
          DeploymentFile(
            name: 'lib',
            type: 'directory',
            uid: 'dir_lib',
            mode: '0755',
            link: 'demo://file/src/lib',
            children: [
              DeploymentFile(
                name: 'utils.ts',
                type: 'file',
                uid: 'file_utils',
                mode: '0644',
                contentType: 'text/typescript',
                link: 'demo://file/utils.ts',
              ),
              DeploymentFile(
                name: 'db.ts',
                type: 'file',
                uid: 'file_db',
                mode: '0644',
                contentType: 'text/typescript',
                link: 'demo://file/db.ts',
              ),
            ],
          ),
        ],
      ),
      DeploymentFile(
        name: 'public',
        type: 'directory',
        uid: 'dir_public',
        mode: '0755',
        link: 'demo://file/public',
        children: [
          DeploymentFile(
            name: 'favicon.ico',
            type: 'file',
            uid: 'file_favicon',
            mode: '0644',
            contentType: 'image/x-icon',
            link: 'demo://file/favicon.ico',
          ),
          DeploymentFile(
            name: 'robots.txt',
            type: 'file',
            uid: 'file_robots',
            mode: '0644',
            contentType: 'text/plain',
            link: 'demo://file/robots.txt',
          ),
          DeploymentFile(
            name: 'images',
            type: 'directory',
            uid: 'dir_images',
            mode: '0755',
            link: 'demo://file/public/images',
            children: [
              DeploymentFile(
                name: 'logo.png',
                type: 'file',
                uid: 'file_logo',
                mode: '0644',
                contentType: 'image/png',
                link: 'demo://file/logo.png',
              ),
              DeploymentFile(
                name: 'hero.jpg',
                type: 'file',
                uid: 'file_hero',
                mode: '0644',
                contentType: 'image/jpeg',
                link: 'demo://file/hero.jpg',
              ),
            ],
          ),
        ],
      ),
      DeploymentFile(
        name: 'package.json',
        type: 'file',
        uid: 'file_package',
        mode: '0644',
        contentType: 'application/json',
        link: 'demo://file/package.json',
      ),
      DeploymentFile(
        name: 'tsconfig.json',
        type: 'file',
        uid: 'file_tsconfig',
        mode: '0644',
        contentType: 'application/json',
        link: 'demo://file/tsconfig.json',
      ),
      DeploymentFile(
        name: 'next.config.js',
        type: 'file',
        uid: 'file_nextconfig',
        mode: '0644',
        contentType: 'application/javascript',
        link: 'demo://file/next.config.js',
      ),
      DeploymentFile(
        name: 'tailwind.config.ts',
        type: 'file',
        uid: 'file_tailwind',
        mode: '0644',
        contentType: 'text/typescript',
        link: 'demo://file/tailwind.config.ts',
      ),
      DeploymentFile(
        name: 'README.md',
        type: 'file',
        uid: 'file_readme',
        mode: '0644',
        contentType: 'text/markdown',
        link: 'demo://file/README.md',
      ),
      DeploymentFile(
        name: '.env.example',
        type: 'file',
        uid: 'file_env_example',
        mode: '0644',
        contentType: 'text/plain',
        link: 'demo://file/.env.example',
      ),
    ];
  }

  /// Get demo file content for a given file.
  static String getDemoFileContent(String fileName) {
    final contents = {
      'page.tsx': '''import { Suspense } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { fetchLatestProducts } from "@/lib/db";
import { Metadata } from "next";

export const metadata: Metadata = {
  title: "Vero | The Modern Vercel Dashboard",
  description: "Experience the ultimate control over your deployments, analytics, and infrastructure with Vero.",
};

async function ProductList() {
  const products = await fetchLatestProducts();
  
  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
      {products.map((product) => (
        <Card key={product.id} className="overflow-hidden border-2 border-primary/10 hover:border-primary/30 transition-all">
          <CardHeader className="p-0">
            <div className="h-48 bg-muted animate-pulse" />
          </CardHeader>
          <CardHeader>
            <CardTitle>{product.name}</CardTitle>
            <CardDescription>{product.category}</CardDescription>
          </CardHeader>
          <CardContent>
            <p className="text-2xl font-bold">\${product.price}</p>
          </CardContent>
          <CardFooter>
            <Button className="w-full">Add to Cart</Button>
          </CardFooter>
        </Card>
      ))}
    </div>
  );
}

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center p-8 md:p-24 bg-gradient-to-b from-background to-muted/20">
      <div className="z-10 max-w-6xl w-full items-center justify-between font-mono text-sm">
        <section className="text-center mb-16">
          <h1 className="text-6xl font-extrabold tracking-tight mb-4 bg-clip-text text-transparent bg-gradient-to-r from-primary to-primary/60">
            Welcome to Vero
          </h1>
          <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
            Your modern Vercel management dashboard. Seamlessly monitor, deploy, and scale your applications with unprecedented visibility.
          </p>
          <div className="mt-8 flex gap-4 justify-center">
            <Button size="lg" className="rounded-full px-8">Get Started</Button>
            <Button size="lg" variant="outline" className="rounded-full px-8">Documentation</Button>
          </div>
        </section>

        <section className="space-y-8">
          <div className="flex items-center justify-between">
            <h2 className="text-3xl font-bold">Featured Products</h2>
            <Button variant="link">View all products</Button>
          </div>
          
          <Suspense fallback={<div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {[1, 2, 3].map((i) => <Skeleton key={i} className="h-[400px] w-full rounded-xl" />)}
          </div>}>
            <ProductList />
          </Suspense>
        </section>
      </div>
    </main>
  );
}''',
    'layout.tsx': '''import type { Metadata, Viewport } from "next";
import { Inter, JetBrains_Mono } from "next/font/google";
import { ThemeProvider } from "@/components/theme-provider";
import { Toaster } from "@/components/ui/toaster";
import { Navigation } from "@/components/navigation";
import { Footer } from "@/components/footer";
import "./globals.css";

const inter = Inter({ 
  subsets: ["latin"],
  variable: "--font-sans",
});

const mono = JetBrains_Mono({
  subsets: ["latin"],
  variable: "--font-mono",
});

export const metadata: Metadata = {
  title: {
    default: "Vero - Modern Vercel Dashboard",
    template: "%s | Vero",
  },
  description: "Advanced analytics, deployment monitoring, and team collaboration for Vercel users.",
  keywords: ["vercel", "dashboard", "analytics", "deployment", "nextjs", "react"],
  authors: [{ name: "Buildagon Team", url: "https://buildagon.com" }],
  creator: "Buildagon",
  icons: {
    icon: "/favicon.ico",
    shortcut: "/favicon-16x16.png",
    apple: "/apple-touch-icon.png",
  },
};

export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "white" },
    { media: "(prefers-color-scheme: dark)", color: "black" },
  ],
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={`\${inter.variable} \${mono.variable} font-sans antialiased min-h-screen flex flex-col`}>
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange
        >
          <Navigation />
          <div className="flex-1">
            {children}
          </div>
          <Footer />
          <Toaster />
        </ThemeProvider>
      </body>
    </html>
  );
}''',
    'globals.css': '''@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 240 10% 3.9%;
    --card: 0 0% 100%;
    --card-foreground: 240 10% 3.9%;
    --popover: 0 0% 100%;
    --popover-foreground: 240 10% 3.9%;
    --primary: 240 5.9% 10%;
    --primary-foreground: 0 0% 98%;
    --secondary: 240 4.8% 95.9%;
    --secondary-foreground: 240 5.9% 10%;
    --muted: 240 4.8% 95.9%;
    --muted-foreground: 240 3.8% 46.1%;
    --accent: 240 4.8% 95.9%;
    --accent-foreground: 240 5.9% 10%;
    --destructive: 0 84.2% 60.2%;
    --destructive-foreground: 0 0% 98%;
    --border: 240 5.9% 90%;
    --input: 240 5.9% 90%;
    --ring: 240 5.9% 10%;
    --radius: 0.75rem;
  }

  .dark {
    --background: 240 10% 3.9%;
    --foreground: 0 0% 98%;
    --card: 240 10% 3.9%;
    --card-foreground: 0 0% 98%;
    --popover: 240 10% 3.9%;
    --popover-foreground: 0 0% 98%;
    --primary: 0 0% 98%;
    --primary-foreground: 240 5.9% 10%;
    --secondary: 240 3.7% 15.9%;
    --secondary-foreground: 0 0% 98%;
    --muted: 240 3.7% 15.9%;
    --muted-foreground: 240 5% 64.9%;
    --accent: 240 3.7% 15.9%;
    --accent-foreground: 0 0% 98%;
    --destructive: 0 62.8% 30.6%;
    --destructive-foreground: 0 0% 98%;
    --border: 240 3.7% 15.9%;
    --input: 240 3.7% 15.9%;
    --ring: 240 4.9% 83.9%;
  }
}

@layer base {
  * {
    @apply border-border;
  }
  body {
    @apply bg-background text-foreground font-sans;
    font-feature-settings: "rlig" 1, "calt" 1;
  }
}

.glass {
  background: rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  border: 1px solid rgba(255, 255, 255, 0.1);
}''',
    'button.tsx': '''import * as React from "react";
import { Slot } from "@radix-ui/react-slot";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const buttonVariants = cva(
  "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground shadow hover:bg-primary/90",
        destructive: "bg-destructive text-destructive-foreground shadow-sm hover:bg-destructive/90",
        outline: "border border-input bg-background shadow-sm hover:bg-accent hover:text-accent-foreground",
        secondary: "bg-secondary text-secondary-foreground shadow-sm hover:bg-secondary/80",
        ghost: "hover:bg-accent hover:text-accent-foreground",
        link: "text-primary underline-offset-4 hover:underline",
      },
      size: {
        default: "h-9 px-4 py-2",
        sm: "h-8 rounded-md px-3 text-xs",
        lg: "h-10 rounded-md px-8",
        icon: "h-9 w-9",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: bool;
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : "button";
    return (
      <Comp
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    );
  }
);
Button.displayName = "Button";

export { Button, buttonVariants };''',
    'utils.ts': '''import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

/**
 * Merges multiple tailwind classes and resolves conflicts.
 * Uses clsx for conditional classes and tailwind-merge for conflict resolution.
 */
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

/**
 * Formats a date using the standard en-US locale.
 * @param date The date object to format.
 * @returns A string in the format "Month Day, Year".
 */
export function formatDate(date: Date | number): string {
  const d = typeof date === 'number' ? new Date(date) : date;
  return new Intl.DateTimeFormat("en-US", {
    month: "long",
    day: "numeric",
    year: "numeric",
  }).format(d);
}

/**
 * Formats a currency amount to USD string.
 */
export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
  }).format(amount);
}

/**
 * Capitalizes the first letter of each word in a string.
 */
export function titleCase(str: string): string {
  return str.toLowerCase().split(' ').map(word => 
    word.charAt(0).toUpperCase() + word.slice(1)
  ).join(' ');
}

/**
 * Returns a promise that resolves after a specified delay.
 */
export const wait = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));
''',
    'package.json': '''{
  "name": "vero-app-v2",
  "version": "2.4.1",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "analyze": "ANALYZE=true next build",
    "type-check": "tsc --noEmit"
  },
  "dependencies": {
    "@radix-ui/react-slot": "^1.1.1",
    "class-variance-authority": "^0.7.1",
    "clsx": "^2.1.1",
    "date-fns": "^4.1.0",
    "lucide-react": "^0.473.0",
    "next": "15.1.4",
    "next-themes": "^0.4.4",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "tailwind-merge": "^2.6.0",
    "tailwindcss-animate": "^1.0.7"
  },
  "devDependencies": {
    "@types/node": "^22.10.7",
    "@types/react": "^19.0.7",
    "@types/react-dom": "^19.0.3",
    "autoprefixer": "^10.4.20",
    "postcss": "^8.5.1",
    "tailwindcss": "^3.4.17",
    "typescript": "^5.7.3"
  },
  "pnpm": {
    "overrides": {
      "react": "^19.0.0",
      "react-dom": "^19.0.0"
    }
  }
}''',
    'tsconfig.json': '''{
  "compilerOptions": {
    "target": "ESNext",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./src/*"]
    },
    "forceConsistentCasingInFileNames": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": [
    "next-env.d.ts",
    "**/*.ts",
    "**/*.tsx",
    ".next/types/**/*.ts"
  ],
  "exclude": ["node_modules"]
}''',
    'next.config.js': '''/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'images.unsplash.com',
      },
      {
        protocol: 'https',
        hostname: 'vero.app',
      }
    ],
  },
  experimental: {
    optimizePackageImports: ["lucide-react", "date-fns"],
    serverActions: {
      bodySizeLimit: '2mb',
    },
  },
  logging: {
    fetches: {
      fullUrl: true,
    },
  },
};

module.exports = nextConfig;''',
    'tailwind.config.ts': '''import type { Config } from "tailwindcss";
import animate from "tailwindcss-animate";

const config: Config = {
    darkMode: ["class"],
    content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
  	extend: {
  		colors: {
  			background: "hsl(var(--background))",
  			foreground: "hsl(var(--foreground))",
  			card: {
  				DEFAULT: "hsl(var(--card))",
  				foreground: "hsl(var(--card-foreground))"
  			},
  			primary: {
  				DEFAULT: "hsl(var(--primary))",
  				foreground: "hsl(var(--primary-foreground))"
  			},
  			secondary: {
  				DEFAULT: "hsl(var(--secondary))",
  				foreground: "hsl(var(--secondary-foreground))"
  			},
  			muted: {
  				DEFAULT: "hsl(var(--muted))",
  				foreground: "hsl(var(--muted-foreground))"
  			},
  			accent: {
  				DEFAULT: "hsl(var(--accent))",
  				foreground: "hsl(var(--accent-foreground))"
  			},
  			destructive: {
  				DEFAULT: "hsl(var(--destructive))",
  				foreground: "hsl(var(--destructive-foreground))"
  			},
  			border: "hsl(var(--border))",
  			input: "hsl(var(--input))",
  			ring: "hsl(var(--ring))",
  		},
  		borderRadius: {
  			lg: "var(--radius)",
  			md: "calc(var(--radius) - 2px)",
  			sm: "calc(var(--radius) - 4px)"
  		}
  	}
  },
  plugins: [animate],
};
export default config;''',
    'README.md': '''# Vero Enterprise v2.4

Welcome to the future of Vercel deployment management. Vero provides a sophisticated interface over the Vercel API, offering enhanced observability, streamlined workflows, and enterprise-grade security controls.

## ✨ Features

- **Real-time Deployment Tracking**: Watch your builds progress in real-time with granular log access.
- **Advanced Analytics**: Interactive dashboards for bandwidth, requests, and performance metrics.
- **Team Collaboration**: Shared workspace with RBAC (Role-Based Access Control).
- **Security First**: Managed WAF rulesets, DDoS protection, and attack-challenge mode integration.
- **Global Edge Network**: Seamlessly manage deployments across all Vercel edge regions.

## 🚀 Quick Start

1. **Environment Setup**:
   Copy `.env.example` to `.env.local` and fill in your Vercel API tokens.

2. **Installation**:
   ```bash
   pnpm install
   ```

3. **Development**:
   ```bash
   pnpm dev
   ```

4. **Production Build**:
   ```bash
   pnpm build
   pnpm start
   ```

## 🛠 Tech Stack

- **Framework**: Next.js 15 (App Router)
- **Styling**: Tailwind CSS 3.4
- **Components**: Radix UI + shadcn/ui
- **Icons**: Lucide React
- **Type Safety**: TypeScript 5.7

## 📄 License

Proprietary. 2026 Buildagon Inc. All rights reserved.
''',
    '.env.example': '''# Vercel API Credentials
VERCEL_TOKEN=your_token_here
VERCEL_TEAM_ID=your_team_id_here

# Database Configuration (Neon/Supabase)
DATABASE_URL=postgresql://user:password@aws-0-us-east-1.pooler.neon.tech/vero_main?sslmode=require

# Authentication (NextAuth.js)
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=generate_a_long_random_string_here

# Third-party Services
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key_here
RESEND_API_KEY=re_123456789
NEXT_PUBLIC_GA_ID=G-VERO4242

# Feature Flags
ENABLE_ANALYTICS=true
ENABLE_BETA_FEATURES=false
''',
    'robots.txt': '''# https://www.robotstxt.org/robotstxt.html
User-agent: *
Allow: /

# Sitemap
Sitemap: https://vero.app/sitemap.xml

# Security
Disallow: /api/
Disallow: /_next/
Disallow: /admin/
''',
  };

  return contents[fileName] ?? '// Demo file content\n// This is a placeholder for ${fileName}';
}

  /// Deployment events / build logs (for the events endpoint).
  static List<Map<String, dynamic>> buildDeploymentEvents(String deploymentId) {
    final base = DateTime.now().subtract(const Duration(minutes: 12)).millisecondsSinceEpoch;
    int t(int s) => base + s * 1000;

    return [
      {'type': 'delimiter', 'created': t(0), 'text': 'Cloning github.com/vero-demo/app (Branch: main, Commit: a3f51cd)'},
      {'type': 'stdout', 'created': t(1), 'text': 'Cloning into \'/vercel/path0\'...'},
      {'type': 'stdout', 'created': t(2), 'text': 'Cloning completed: 1.2s'},
      {'type': 'stdout', 'created': t(3), 'text': 'Checking for build cache...'},
      {'type': 'stdout', 'created': t(4), 'text': 'Found cache for branch "main" (124 MB)'},
      {'type': 'stdout', 'created': t(5), 'text': 'Restored build cache in 2.1s'},
      {'type': 'stdout', 'created': t(6), 'text': 'Detected package manager: pnpm (v9.5.0)'},
      {'type': 'stdout', 'created': t(7), 'text': 'Running "install" command: `pnpm install`'},
      {'type': 'stdout', 'created': t(10), 'text': 'Packages: +1542, -0, changed 0'},
      {'type': 'stdout', 'created': t(12), 'text': 'Downloading packages...'},
      {'type': 'stdout', 'created': t(15), 'text': 'Progress: resolved 1542, reused 1420, downloaded 122, added 1542'},
      {'type': 'stdout', 'created': t(18), 'text': 'Lockfile is up to date, resolution step is skipped'},
      {'type': 'stdout', 'created': t(22), 'text': 'Progress: resolved 1542, reused 1542, downloaded 0, added 1542, done'},
      {'type': 'stdout', 'created': t(25), 'text': 'node_modules installed in 18.4s'},
      {'type': 'delimiter', 'created': t(26), 'text': 'Running "build" command: `next build`'},
      {'type': 'stdout', 'created': t(28), 'text': '  ▲ Next.js 15.1.4'},
      {'type': 'stdout', 'created': t(29), 'text': '  - Linting and checking validity of types'},
      {'type': 'stdout', 'created': t(30), 'text': '  - Environments: .env.production, .env.local'},
      {'type': 'stdout', 'created': t(31), 'text': '  - Loading env from .env.production'},
      {'type': 'stdout', 'created': t(32), 'text': '  ✓ Loaded env from .env.production (12 variables)'},
      {'type': 'stdout', 'created': t(33), 'text': '   Creating an optimized production build ...'},
      {'type': 'stdout', 'created': t(38), 'text': '  (node:14) [DEP0040] DeprecationWarning: The `punycode` module is deprecated.'},
      {'type': 'stdout', 'created': t(45), 'text': '  ✓ Compiled successfully'},
      {'type': 'stdout', 'created': t(46), 'text': '  ✓ Linting and checking validity of types'},
      {'type': 'stdout', 'created': t(50), 'text': '  ✓ Collecting page data'},
      {'type': 'stdout', 'created': t(52), 'text': '    [ ] /'},
      {'type': 'stdout', 'created': t(53), 'text': '    [ ] /about'},
      {'type': 'stdout', 'created': t(54), 'text': '    [ ] /pricing'},
      {'type': 'stdout', 'created': t(55), 'text': '    [ ] /blog/[slug]'},
      {'type': 'stdout', 'created': t(56), 'text': '    [ ] /dashboard'},
      {'type': 'stdout', 'created': t(57), 'text': '    [ ] /api/auth/*'},
      {'type': 'stdout', 'created': t(58), 'text': '    [ ] /api/webhooks/*'},
      {'type': 'stdout', 'created': t(59), 'text': '    [ ] /api/v1/analytics'},
      {'type': 'stdout', 'created': t(60), 'text': '    [ ] /api/v1/users'},
      {'type': 'stdout', 'created': t(65), 'text': '  ✓ Generating static pages (54/54)'},
      {'type': 'stdout', 'created': t(66), 'text': '    / (412ms)'},
      {'type': 'stdout', 'created': t(67), 'text': '    /about (315ms)'},
      {'type': 'stdout', 'created': t(68), 'text': '    /pricing (297ms)'},
      {'type': 'stdout', 'created': t(69), 'text': '    /blog/getting-started (242ms)'},
      {'type': 'stdout', 'created': t(70), 'text': '    /blog/advanced-patterns (283ms)'},
      {'type': 'stdout', 'created': t(71), 'text': '    /blog/nextjs-15-deep-dive (312ms)'},
      {'type': 'stdout', 'created': t(72), 'text': '    /blog/optimizing-performance (256ms)'},
      {'type': 'stdout', 'created': t(75), 'text': '  ✓ Finalizing page optimization'},
      {'type': 'stdout', 'created': t(78), 'text': '  ✓ Collecting build traces'},
      {'type': 'stdout', 'created': t(82), 'text': '  ✓ Generating route manifests'},
      {'type': 'stdout', 'created': t(85), 'text': '  Route (app)                              Size     First Load JS'},
      {'type': 'stdout', 'created': t(86), 'text': '  ┌ ○ /                                    1.2 kB          104 kB'},
      {'type': 'stdout', 'created': t(87), 'text': '  ├ ○ /about                               452 B           103 kB'},
      {'type': 'stdout', 'created': t(88), 'text': '  ├ ○ /pricing                             892 B           104 kB'},
      {'type': 'stdout', 'created': t(89), 'text': '  └ λ /blog/[slug]                         1.1 kB          104 kB'},
      {'type': 'stdout', 'created': t(90), 'text': '  + First Load JS shared by all            103 kB'},
      {'type': 'stdout', 'created': t(91), 'text': '    ├ chunks/framework-f3b1.js             45.2 kB'},
      {'type': 'stdout', 'created': t(92), 'text': '    ├ chunks/main-c9a2.js                  32.1 kB'},
      {'type': 'stdout', 'created': t(93), 'text': '    └ chunks/pages/_app-d8f2.js            24.8 kB'},
      {'type': 'delimiter', 'created': t(95), 'text': 'Deploying outputs'},
      {'type': 'stdout', 'created': t(96), 'text': 'Uploading build output...'},
      {'type': 'stdout', 'created': t(100), 'text': 'Build output uploaded: 56.8 MB'},
      {'type': 'stdout', 'created': t(102), 'text': 'Deploying to Edge Network...'},
      {'type': 'stdout', 'created': t(105), 'text': 'Checking for domain verification...'},
      {'type': 'stdout', 'created': t(106), 'text': 'Configuring Edge Middleware...'},
      {'type': 'stdout', 'created': t(107), 'text': 'Analyzing project security headers...'},
      {'type': 'stdout', 'created': t(108), 'text': 'Deployment completed in 1m 12s'},
      {'type': 'stdout', 'created': t(110), 'text': 'Production: https://vero.app (56.8 MB)'},
      {'type': 'stdout', 'created': t(112), 'text': 'Preview: https://vero-app-git-main-vero-demo.vercel.app'},
    ];
  }

  /// Runtime / request logs for a deployment.
  static List<Map<String, dynamic>> buildRuntimeLogs() {
    final now = DateTime.now();
    
    final logTemplates = [
      {
        'method': 'GET',
        'path': '/api/v1/user/profile',
        'status': 200,
        'region': 'iad1',
        'duration': 42,
        'messages': [
          'DEBUG: Incoming request from authenticated user session',
          'INFO: Cache miss for user_profile:user_882',
          'INFO: Fetching user data from PostgreSQL (primary)...',
          'DEBUG: DB Query: SELECT * FROM users WHERE id = \'user_882\' LIMIT 1',
          'INFO: Request processed successfully in 42ms'
        ]
      },
      {
        'method': 'POST',
        'path': '/api/webhooks/stripe',
        'status': 201,
        'region': 'fra1',
        'duration': 156,
        'messages': [
          'INFO: Received Stripe webhook: checkout.session.completed',
          'DEBUG: Verifying webhook signature...',
          'INFO: Signature verified successfully',
          'INFO: Updating subscription status for org_992...',
          'DEBUG: DB Query: UPDATE subscriptions SET status = \'active\' WHERE org_id = \'org_992\'',
          'INFO: Triggering welcome email sequence via Resend API'
        ]
      },
      {
        'method': 'GET',
        'path': '/dashboard/analytics',
        'status': 500,
        'region': 'sfo1',
        'duration': 1204,
        'messages': [
          'ERROR: Unhandled exception in server-side component',
          'ERROR: ConnectionTimeout: Failed to connect to analytics-db-replica:5432 after 1000ms',
          'ERROR: Stack trace:\n  at fetchAnalytics (/var/task/.next/server/app/dashboard/analytics/page.js:412:12)\n  at async Page (/var/task/.next/server/app/dashboard/analytics/page.js:89:18)',
          'WARN: Retrying connection (attempt 1/3)...'
        ]
      },
      {
        'method': 'GET',
        'path': '/',
        'status': 200,
        'region': 'cdg1',
        'duration': 18,
        'messages': [
          'INFO: Edge Network: Cache hit (stale-while-revalidate)',
          'DEBUG: Serving static page from edge cache (TTL: 3600s)',
          'INFO: X-Vercel-Cache: HIT'
        ]
      },
      {
        'method': 'GET',
        'path': '/api/v1/products/search?q=vero',
        'status': 200,
        'region': 'hnd1',
        'duration': 89,
        'messages': [
          'INFO: Search query received: "vero"',
          'DEBUG: Sanitizing input query...',
          'INFO: Searching Elasticsearch index: products_v2',
          'DEBUG: Query DSL: {"query": {"match": {"name": "vero"}}}',
          'INFO: Found 12 results in 45ms',
          'DEBUG: Serializing response with fast-json-stringify'
        ]
      }
    ];

    return List.generate(8, (i) {
      final template = logTemplates[i % logTemplates.length];
      final timestamp = now.subtract(Duration(seconds: i * 45)).toIso8601String();
      final method = template['method'] as String;
      final path = template['path'] as String;
      final status = template['status'] as int;
      final duration = template['duration'] as int;
      final region = template['region'] as String;
      final messages = template['messages'] as List<String>;
      
      return {
        'message': '$method $path -> $status (${duration}ms)\n${messages.join('\n')}',
        'level': status >= 500 ? 'error' : (status >= 400 ? 'warning' : 'info'),
        'timestamp': timestamp,
        'source': 'edge',
        'region': region,
        'requestId': 'req_runtime_${_shortHash(i)}',
      };
    });
  }

  /// Representative request logs (for the /logs/request-logs endpoint).
  static Map<String, dynamic> buildProjectLogsResponse(String projectId) {
    final now = DateTime.now();
    final rows = <Map<String, dynamic>>[];
    
    final scenarios = [
      {
        'path': '/api/v1/auth/session',
        'method': 'GET',
        'status': 200,
        'cache': 'MISS',
        'region': 'iad1',
        'logs': [
          {'level': 'info', 'message': '[auth] Initiating session validation for JWT cookie: session_v2_...'},
          {'level': 'debug', 'message': '[jwt] Decoded payload: {"sub":"user_992","iat":1714041600,"exp":1714128000,"role":"admin"}'},
          {'level': 'info', 'message': '[db] Fetching user preferences from neon_db_main...'},
          {'level': 'debug', 'message': '[db] Query: SELECT * FROM user_settings WHERE user_id = \'user_992\''},
          {'level': 'info', 'message': '[auth] Session valid. Extending expiry by 24h.'},
          {'level': 'debug', 'message': '[response] Set-Cookie: session_v2=...; HttpOnly; Secure; SameSite=Lax'},
        ]
      },
      {
        'path': '/api/v1/orders/create',
        'method': 'POST',
        'status': 201,
        'cache': 'BYPASS',
        'region': 'fra1',
        'logs': [
          {'level': 'info', 'message': '[orders] Processing new order request...'},
          {'level': 'debug', 'message': '[request] Payload: {"items":[{"id":"sku_1","qty":1},{"id":"sku_42","qty":3}],"total":299.00}'},
          {'level': 'info', 'message': '[inventory] Validating stock levels for items: [sku_1, sku_42]'},
          {'level': 'debug', 'message': '[db] Query: SELECT stock_count FROM inventory WHERE sku_id IN (\'sku_1\', \'sku_42\') FOR UPDATE'},
          {'level': 'info', 'message': r'[stripe] Creating PaymentIntent for $299.00...'},
          {'level': 'debug', 'message': '[stripe] API Response: {"id":"pi_3P92k8L1","status":"requires_payment_method","client_secret":"pi_3P9..._secret_..."}'},
          {'level': 'info', 'message': '[orders] Order #ORD-2026-X92 pending payment confirmation.'},
        ]
      },
      {
        'path': '/api/v1/reports/export',
        'method': 'GET',
        'status': 401,
        'cache': 'MISS',
        'region': 'sfo1',
        'logs': [
          {'level': 'warn', 'message': '[security] Unauthorized access attempt to protected export endpoint.'},
          {'level': 'error', 'message': '[auth] Authentication failed: Missing or invalid Authorization header.'},
          {'level': 'debug', 'message': '[headers] { "host": "vero.app", "user-agent": "curl/8.4.0", "accept": "*/*" }'},
          {'level': 'info', 'message': '[security] IP 192.168.1.42 flagged for rate-limit observation.'},
        ]
      },
      {
        'path': '/dashboard/billing',
        'method': 'GET',
        'status': 500,
        'cache': 'MISS',
        'region': 'cdg1',
        'logs': [
          {'level': 'info', 'message': '[billing] Fetching usage data for current billing cycle...'},
          {'level': 'error', 'message': '[upstream] Internal Server Error: Failed to connect to BillingProvider gateway.'},
          {'level': 'error', 'message': 'ConnectionResetError: Remote host [10.42.1.88:443] closed the connection during handshake.'},
          {'level': 'debug', 'message': '[stack] Error: ConnectionResetError\n    at BillingProvider.fetchData (/var/task/lib/billing.js:142:18)\n    at async Page (/var/task/.next/server/app/dashboard/billing/page.js:89:12)'},
          {'level': 'warn', 'message': '[circuit-breaker] Billing service is currently degraded. Falling back to cached data.'},
        ]
      },
      {
        'path': '/api/v1/inventory/sync',
        'method': 'POST',
        'status': 200,
        'cache': 'MISS',
        'region': 'hnd1',
        'logs': [
          {'level': 'info', 'message': '[sync] Starting manual inventory synchronization with AWS SCM...'},
          {'level': 'info', 'message': '[sync] Found 1,242 SKU updates in the last 24 hours.'},
          {'level': 'debug', 'message': '[db] Batch Update: UPDATE products SET stock = ? WHERE id = ? [250 operations]'},
          {'level': 'debug', 'message': '[db] Batch Update: UPDATE products SET stock = ? WHERE id = ? [250 operations]'},
          {'level': 'debug', 'message': '[db] Batch Update: UPDATE products SET stock = ? WHERE id = ? [250 operations]'},
          {'level': 'debug', 'message': '[db] Batch Update: UPDATE products SET stock = ? WHERE id = ? [250 operations]'},
          {'level': 'debug', 'message': '[db] Batch Update: UPDATE products SET stock = ? WHERE id = ? [242 operations]'},
          {'level': 'info', 'message': '[sync] Synchronization completed successfully in 4.2s.'},
        ]
      },
      {
        'path': '/api/v1/analytics/track',
        'method': 'POST',
        'status': 204,
        'cache': 'BYPASS',
        'region': 'icn1',
        'logs': [
          {'level': 'info', 'message': '[analytics] Received tracking beacon: page_view'},
          {'level': 'debug', 'message': '[analytics] Properties: {"url":"/pricing","referrer":"google.com","screen":"1920x1080"}'},
          {'level': 'info', 'message': '[ingest] Dispatching to ClickHouse event queue...'},
          {'level': 'debug', 'message': '[ingest] Sequence ID: seq_8812903_v2'},
        ]
      }
    ];

    for (var i = 0; i < 8; i++) {
      final scenario = scenarios[i % scenarios.length];
      final ts = now.subtract(Duration(minutes: i * 15)).toIso8601String();
      final path = scenario['path'] as String;
      final status = scenario['status'] as int;
      final method = scenario['method'] as String;
      final region = scenario['region'] as String;
      
      rows.add({
        'requestId': 'req_${projectId}_${_shortHash(i)}',
        'timestamp': ts,
        'branch': 'main',
        'deploymentId': 'dpl_${projectId}_prod',
        'domain': 'vero.app',
        'deploymentDomain': 'vero-app-git-main-vero-demo.vercel.app',
        'environment': 'production',
        'requestPath': path,
        'route': path,
        'clientUserAgent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131 Safari/537.36',
        'clientRegion': region,
        'requestMethod': method,
        'cache': scenario['cache'],
        'statusCode': status,
        'events': [
          {
            'source': 'lambda',
            'route': path,
            'pathType': 'route',
            'timestamp': ts,
            'httpStatus': status,
            'region': region,
            'cache': scenario['cache'],
            'functionMaxMemoryUsed': status >= 500 ? 512 : 128,
            'functionMemorySize': 1024,
            'durationMs': 120 + (i * 45) % 500,
          }
        ],
        'logs': scenario['logs'],
        'requestTags': ['demo', 'production', region],
      });
    }

    return {
      'rows': rows,
      'hasMoreRows': false,
    };
  }

  // ===========================================================================
  // ANALYTICS DEMO DATA
  // ===========================================================================

  /// Build realistic analytics overview data for demo projects.
  /// If [from] is provided and is more than ~2 days in the past, returns
  /// previous-period data (~15% lower) so percent-change metrics look realistic.
  static AnalyticsOverview buildAnalyticsOverview({String? from, String? projectId}) {
    var previousPeriod = false;
    if (from != null) {
      try {
        final fromDate = DateTime.parse(from);
        // If the from date is more than 2 days ago, treat as previous period
        previousPeriod = DateTime.now().toUtc().difference(fromDate).inDays > 2;
      } catch (_) {
        // ignore parse errors
      }
    }
    
    // Use projectId to vary base values (seeded by project ID hash)
    final seed = projectId?.hashCode ?? 0;
    final random = Random(seed);
    final baseViews = 80000 + random.nextInt(80000); // 80K-160K
    final baseVisitors = (baseViews * 0.35).round(); // ~35% conversion
    final baseBounceRate = 28 + random.nextInt(12); // 28-40%
    
    final multiplier = previousPeriod ? 0.85 : 1.0;
    return AnalyticsOverview(
      total: (baseViews * multiplier).round(), // Page views
      devices: (baseVisitors * multiplier).round(), // Unique visitors
      bounceRate: baseBounceRate, // Percentage
    );
  }

  /// Build timeseries data for the analytics chart.
  static List<TimeseriesPoint> buildAnalyticsTimeseries(String from, String to, {String? projectId}) {
    final points = <TimeseriesPoint>[];
    final fromDate = DateTime.parse(from);
    final toDate = DateTime.parse(to);
    final duration = toDate.difference(fromDate);
    
    // Use projectId to seed random for consistent but unique data per project
    final seed = projectId?.hashCode ?? 42;
    final random = Random(seed);
    
    // Base traffic level varies by project
    final baseTraffic = 1000 + random.nextInt(1000); // 1000-2000
    
    // Determine interval based on duration
    final intervalHours = duration.inDays > 30 ? 24 : (duration.inDays > 7 ? 6 : 1);
    final steps = (duration.inHours / intervalHours).ceil();
    
    // Generate realistic traffic patterns (higher during weekdays, peak hours)
    for (var i = 0; i < steps; i++) {
      final timestamp = fromDate.add(Duration(hours: i * intervalHours));
      final isWeekend = timestamp.weekday == 6 || timestamp.weekday == 7;
      final baseMultiplier = isWeekend ? 0.6 : 1.0;
      final hourFactor = (timestamp.hour >= 9 && timestamp.hour <= 18) ? 1.3 : 0.7;
      
      final total = (baseTraffic * baseMultiplier * hourFactor + random.nextInt(500)).round();
      final devices = (total * 0.4).round();
      
      final bounceRate = 30 + random.nextInt(10);
      points.add(TimeseriesPoint(
        key: timestamp.toIso8601String(),
        total: total,
        devices: devices,
        bounceRate: bounceRate,
      ));
    }
    
    return points;
  }

  /// Build breakdown items for analytics (pages, referrers, countries, etc.)
  static List<BreakdownItem> buildAnalyticsBreakdown(String groupBy, {String? projectId}) {
    // Use projectId to seed random for consistent but unique data per project
    final seed = projectId?.hashCode ?? 0;
    final random = Random(seed);
    
    // Vary visitor counts by project (±30%)
    final multiplier = 0.7 + (random.nextDouble() * 0.6);
    
    final Map<String, List<Map<String, dynamic>>> demoData = {
      'path': [
        {'key': '/', 'visitors': ((15420 * multiplier).round())},
        {'key': '/pricing', 'visitors': ((8320 * multiplier).round())},
        {'key': '/docs', 'visitors': ((6450 * multiplier).round())},
        {'key': '/blog', 'visitors': ((4210 * multiplier).round())},
        {'key': '/about', 'visitors': ((2890 * multiplier).round())},
        {'key': '/contact', 'visitors': ((1450 * multiplier).round())},
        {'key': '/features', 'visitors': ((1120 * multiplier).round())},
      ],
      'referrer': [
        {'key': 'Direct', 'visitors': ((18500 * multiplier).round())},
        {'key': 'google.com', 'visitors': ((12400 * multiplier).round())},
        {'key': 'github.com', 'visitors': ((6800 * multiplier).round())},
        {'key': 'twitter.com', 'visitors': ((4200 * multiplier).round())},
        {'key': 'linkedin.com', 'visitors': ((3100 * multiplier).round())},
        {'key': 'vercel.com', 'visitors': ((2800 * multiplier).round())},
        {'key': 'reddit.com', 'visitors': ((1500 * multiplier).round())},
      ],
      'country': [
        {'key': 'United States', 'visitors': ((18500 * multiplier).round())},
        {'key': 'United Kingdom', 'visitors': ((6200 * multiplier).round())},
        {'key': 'Germany', 'visitors': ((4800 * multiplier).round())},
        {'key': 'Canada', 'visitors': ((3900 * multiplier).round())},
        {'key': 'India', 'visitors': ((3400 * multiplier).round())},
        {'key': 'France', 'visitors': ((2800 * multiplier).round())},
        {'key': 'Netherlands', 'visitors': ((2100 * multiplier).round())},
        {'key': 'Australia', 'visitors': ((1800 * multiplier).round())},
      ],
      'device_type': [
        {'key': 'Desktop', 'visitors': ((28500 * multiplier).round())},
        {'key': 'Mobile', 'visitors': ((12300 * multiplier).round())},
        {'key': 'Tablet', 'visitors': ((4200 * multiplier).round())},
      ],
      'client_name': [
        {'key': 'Chrome', 'visitors': ((22400 * multiplier).round())},
        {'key': 'Safari', 'visitors': ((10200 * multiplier).round())},
        {'key': 'Firefox', 'visitors': ((6800 * multiplier).round())},
        {'key': 'Edge', 'visitors': ((3400 * multiplier).round())},
        {'key': 'Samsung Browser', 'visitors': ((2100 * multiplier).round())},
      ],
      'os_name': [
        {'key': 'Mac OS X', 'visitors': ((18500 * multiplier).round())},
        {'key': 'Windows', 'visitors': ((14200 * multiplier).round())},
        {'key': 'iOS', 'visitors': ((8900 * multiplier).round())},
        {'key': 'Android', 'visitors': ((7600 * multiplier).round())},
        {'key': 'Linux', 'visitors': ((3800 * multiplier).round())},
      ],
      'route': [
        {'key': '/', 'visitors': ((15420 * multiplier).round())},
        {'key': '/api/health', 'visitors': ((12400 * multiplier).round())},
        {'key': '/api/webhooks', 'visitors': ((8200 * multiplier).round())},
        {'key': '/dashboard', 'visitors': ((6400 * multiplier).round())},
        {'key': '/settings', 'visitors': ((3200 * multiplier).round())},
        {'key': '/api/users', 'visitors': ((2800 * multiplier).round())},
      ],
      'hostname': [
        {'key': 'vero.app', 'visitors': ((28500 * multiplier).round())},
        {'key': 'www.vero.app', 'visitors': ((12400 * multiplier).round())},
        {'key': 'api.vero.app', 'visitors': ((4200 * multiplier).round())},
        {'key': 'docs.vero.app', 'visitors': ((3800 * multiplier).round())},
      ],
    };

    final items = demoData[groupBy] ?? demoData['path']!;
    return items
        .map((item) => BreakdownItem(
              key: item['key'] as String,
              visitors: item['visitors'] as int,
            ))
        .toList()
      ..sort((a, b) => b.visitors.compareTo(a.visitors));
  }

  static String _shortHash(int i) {
    const chars = 'abcdef0123456789';
    final sb = StringBuffer();
    var n = (i * 2654435761) & 0xFFFFFFFF;
    for (var j = 0; j < 7; j++) {
      sb.write(chars[n & 0xF]);
      n >>= 4;
    }
    return sb.toString();
  }
}
