import '../models/project.dart';
import '../models/deployment.dart';
import '../models/deployment_file.dart';
import '../models/domain.dart';
import '../models/env_var.dart';
import '../models/security.dart';

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
        alias: ['demo.vercel.store', 'next-commerce-demo.vercel.app'],
        repo: 'vercel/commerce',
        branch: 'main',
        commitMessage: 'feat(cart): optimistic UI updates for line items',
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
        alias: ['ui.shadcn.com'],
        repo: 'shadcn-ui/ui',
        branch: 'main',
        commitMessage: 'docs(calendar): add range selection example',
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
        alias: ['cal.com', 'www.cal.com'],
        repo: 'calcom/cal.com',
        branch: 'main',
        commitMessage: 'fix(booking): handle timezone dst transitions correctly',
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
        id: 'prj_demo_next_learn',
        name: 'nextjs-dashboard',
        framework: 'nextjs',
        url: 'next-learn-dashboard.vercel.sh',
        alias: ['next-learn-dashboard.vercel.sh'],
        repo: 'vercel/next-learn',
        branch: 'main',
        commitMessage: 'chore(deps): bump next to 15.1.4',
        commitSha: '2fe0a08c',
        state: 'READY',
        createdAgo: const Duration(days: 241),
        updatedAgo: const Duration(days: 1, hours: 3),
        hasWebAnalytics: true,
        now: now,
      ),
      _project(
        id: 'prj_demo_docs',
        name: 'vero-docs',
        framework: 'nextjs',
        url: 'vero-docs.vercel.app',
        alias: ['docs.vero.app', 'vero-docs.vercel.app'],
        repo: 'buildagon/vero-docs',
        branch: 'main',
        commitMessage: 'docs: add getting-started guide for teams',
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
        alias: ['vero.app', 'www.vero.app'],
        repo: 'buildagon/vero-marketing',
        branch: 'production',
        commitMessage: 'feat(pricing): add annual toggle with 20% off',
        commitSha: '4b2e70af',
        state: 'READY',
        createdAgo: const Duration(days: 128),
        updatedAgo: const Duration(hours: 11),
        hasAnalytics: true,
        hasWebAnalytics: true,
        hasFirewall: true,
        now: now,
      ),
      _project(
        id: 'prj_demo_tanstack',
        name: 'tanstack-query',
        framework: 'nextjs',
        url: 'tanstack.com',
        alias: ['tanstack.com', 'www.tanstack.com'],
        repo: 'TanStack/query',
        branch: 'main',
        commitMessage: 'feat(query): add experimental suspense support',
        commitSha: '9f3e2d1a',
        state: 'READY',
        createdAgo: const Duration(days: 720),
        updatedAgo: const Duration(days: 2),
        hasAnalytics: true,
        hasWebAnalytics: true,
        hasFirewall: true,
        hasCronJobs: true,
        now: now,
      ),
      _project(
        id: 'prj_demo_nuxt',
        name: 'nuxt-docs',
        framework: 'nuxtjs',
        url: 'nuxt.com',
        alias: ['nuxt.com', 'www.nuxt.com'],
        repo: 'nuxt/nuxt.com',
        branch: 'main',
        commitMessage: 'docs: update module integration guide',
        commitSha: 'b8c4f2e3',
        state: 'READY',
        createdAgo: const Duration(days: 540),
        updatedAgo: const Duration(hours: 4),
        hasAnalytics: true,
        hasWebAnalytics: true,
        now: now,
      ),
      _project(
        id: 'prj_demo_remix',
        name: 'remix-run',
        framework: 'remix',
        url: 'remix.run',
        alias: ['remix.run', 'www.remix.run'],
        repo: 'remix-run/remix',
        branch: 'dev',
        commitMessage: 'fix(loader): handle nested data loading errors',
        commitSha: 'd5a1b9c4',
        state: 'READY',
        createdAgo: const Duration(days: 890),
        updatedAgo: const Duration(minutes: 23),
        hasAnalytics: true,
        hasWebAnalytics: true,
        hasFirewall: true,
        now: now,
      ),
      _project(
        id: 'prj_demo_sveltekit',
        name: 'sveltekit-docs',
        framework: 'sveltekit',
        url: 'kit.svelte.dev',
        alias: ['kit.svelte.dev', 'sveltekit.dev'],
        repo: 'sveltejs/kit.svelte.dev',
        branch: 'main',
        commitMessage: 'feat(routing): add advanced route matching patterns',
        commitSha: 'e7f3c8d5',
        state: 'BUILDING',
        createdAgo: const Duration(days: 380),
        updatedAgo: const Duration(minutes: 8),
        hasWebAnalytics: true,
        now: now,
      ),
      _project(
        id: 'prj_demo_fastapi',
        name: 'fastapi-backend',
        framework: 'python',
        url: 'api.vero.app',
        alias: ['api.vero.app'],
        repo: 'buildagon/fastapi-backend',
        branch: 'main',
        commitMessage: 'feat(auth): implement JWT refresh token rotation',
        commitSha: 'f6a2e9b1',
        state: 'READY',
        createdAgo: const Duration(days: 156),
        updatedAgo: const Duration(hours: 5),
        hasAnalytics: true,
        hasFirewall: true,
        hasCronJobs: true,
        now: now,
      ),
      _project(
        id: 'prj_demo_vue',
        name: 'vue-docs',
        framework: 'vue',
        url: 'vuejs.org',
        alias: ['vuejs.org', 'www.vuejs.org'],
        repo: 'vuejs/docs',
        branch: 'main',
        commitMessage: 'docs(composition): add lifecycle hooks examples',
        commitSha: 'a4b7c3d2',
        state: 'READY',
        createdAgo: const Duration(days: 1100),
        updatedAgo: const Duration(days: 1, hours: 7),
        hasAnalytics: true,
        hasWebAnalytics: true,
        now: now,
      ),
      _project(
        id: 'prj_demo_supabase',
        name: 'supabase-docs',
        framework: 'nextjs',
        url: 'supabase.com',
        alias: ['supabase.com', 'www.supabase.com'],
        repo: 'supabase/supabase',
        branch: 'master',
        commitMessage: 'docs(auth): update OIDC provider configuration',
        commitSha: 'c3d8e4f1',
        state: 'READY',
        createdAgo: const Duration(days: 1250),
        updatedAgo: const Duration(hours: 3),
        hasAnalytics: true,
        hasWebAnalytics: true,
        hasFirewall: true,
        hasCronJobs: true,
        now: now,
      ),
      _project(
        id: 'prj_demo_tauri',
        name: 'tauri-app',
        framework: 'nextjs',
        url: 'tauri.app',
        alias: ['tauri.app', 'www.tauri.app'],
        repo: 'tauri-apps/tauri',
        branch: 'dev',
        commitMessage: 'feat(window): add custom window decorations API',
        commitSha: 'b5e9f3a2',
        state: 'ERROR',
        createdAgo: const Duration(days: 89),
        updatedAgo: const Duration(minutes: 15),
        hasWebAnalytics: true,
        now: now,
      ),
      _project(
        id: 'prj_demo_bun',
        name: 'bun-website',
        framework: 'remix',
        url: 'bun.sh',
        alias: ['bun.sh', 'www.bun.sh'],
        repo: 'oven-sh/bun',
        branch: 'main',
        commitMessage: 'perf(runtime): optimize JIT compilation',
        commitSha: 'd6f1a4e3',
        state: 'READY',
        createdAgo: const Duration(days: 340),
        updatedAgo: const Duration(hours: 9),
        hasAnalytics: true,
        hasWebAnalytics: true,
        hasFirewall: true,
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
      },
      {
        'host': host,
        'path': '/api/cron/cleanup',
        'schedule': '0 0 * * 0', // Weekly on Sunday
      },
      {
        'host': host,
        'path': '/api/cron/health-check',
        'schedule': '*/5 * * * *', // Every 5 minutes
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
      'page.tsx': '''import { Button } from "@/components/ui/button";

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-between p-24">
      <div className="z-10 max-w-5xl w-full items-center justify-between font-mono text-sm">
        <h1 className="text-4xl font-bold">Welcome to Vero</h1>
        <p className="mt-4 text-lg">Your modern Vercel management dashboard</p>
        <Button className="mt-6">Get Started</Button>
      </div>
    </main>
  );
}''',
      'layout.tsx': '''import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Vero - Vercel Dashboard",
  description: "Manage your Vercel deployments with ease",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={inter.className}>{children}</body>
    </html>
  );
}''',
      'globals.css': '''@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  --foreground-rgb: 0, 0, 0;
  --background-start-rgb: 214, 219, 220;
  --background-end-rgb: 255, 255, 255;
}

body {
  color: rgb(var(--foreground-rgb));
  background: linear-gradient(
      to bottom,
      transparent,
      rgb(var(--background-end-rgb))
    )
    rgb(var(--background-start-rgb));
}''',
      'button.tsx': '''import * as React from "react";

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "default" | "destructive" | "outline" | "secondary" | "ghost";
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = "default", ...props }, ref) => {
    return (
      <button
        className={\`px-4 py-2 rounded-md font-medium transition-colors \${className}\`}
        ref={ref}
        {...props}
      />
    );
  }
);
Button.displayName = "Button";

export { Button };''',
      'utils.ts': '''import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatDate(date: Date): string {
  return new Intl.DateTimeFormat("en-US", {
    month: "long",
    day: "numeric",
    year: "numeric",
  }).format(date);
}''',
      'package.json': '''{
  "name": "vero-app",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "15.1.4",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "clsx": "^2.1.0",
    "tailwind-merge": "^2.2.0"
  },
  "devDependencies": {
    "@types/node": "^20.11.0",
    "@types/react": "^18.2.48",
    "typescript": "^5.3.3",
    "tailwindcss": "^3.4.1"
  }
}''',
      'tsconfig.json': '''{
  "compilerOptions": {
    "target": "ES2017",
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
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}''',
      'next.config.js': '''/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    domains: ['vero.app'],
  },
};

module.exports = nextConfig;''',
      'tailwind.config.ts': '''import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        background: "var(--background)",
        foreground: "var(--foreground)",
      },
    },
  },
  plugins: [],
};
export default config;''',
      'README.md': '''# Vero App

A modern Vercel management dashboard built with Next.js 15.

## Getting Started

1. Install dependencies:
   \`\`\`bash
   pnpm install
   \`\`\`

2. Run the development server:
   \`\`\`bash
   pnpm dev
   \`\`\`

3. Open [http://localhost:3000](http://localhost:3000) in your browser.

## Features

- Real-time deployment monitoring
- Analytics dashboard
- Team collaboration tools
- Security firewall management

## License

MIT''',
      '.env.example': '''DATABASE_URL=postgresql://user:password@localhost:5432/vero
NEXT_PUBLIC_APP_URL=http://localhost:3000
NEXT_PUBLIC_ANALYTICS_ID=G-XXXXXX
STRIPE_SECRET_KEY=sk_test_XXXXXX
RESEND_API_KEY=re_XXXXXX''',
      'robots.txt': '''User-agent: *
Allow: /
Disallow: /api/
Sitemap: https://vero.app/sitemap.xml''',
    };

    return contents[fileName] ?? '// Demo file content\n// This is a placeholder for ${fileName}';
  }

  /// Deployment events / build logs (for the events endpoint).
  static List<Map<String, dynamic>> buildDeploymentEvents(String deploymentId) {
    final base = DateTime.now().subtract(const Duration(minutes: 4)).millisecondsSinceEpoch;
    int t(int s) => base + s * 1000;

    return [
      {'type': 'delimiter', 'created': t(0), 'text': 'Cloning github.com/vero-demo/app (Branch: main)'},
      {'type': 'stdout', 'created': t(2), 'text': 'Cloning completed: 812.456ms'},
      {'type': 'stdout', 'created': t(3), 'text': 'Running "install" command: `pnpm install`'},
      {'type': 'stdout', 'created': t(5), 'text': 'Packages: +1243, -0, changed 0'},
      {'type': 'stdout', 'created': t(7), 'text': 'Downloading packages...'},
      {'type': 'stdout', 'created': t(9), 'text': 'Progress: resolved 1243, reused 842, downloaded 401, added 1243'},
      {'type': 'stdout', 'created': t(11), 'text': 'Lockfile is up to date, resolution step is skipped'},
      {'type': 'stdout', 'created': t(14), 'text': 'Progress: resolved 1243, reused 1243, downloaded 0, added 1243, done'},
      {'type': 'stdout', 'created': t(16), 'text': 'node_modules installed in 13.2s'},
      {'type': 'delimiter', 'created': t(17), 'text': 'Running "build" command: `next build`'},
      {'type': 'stdout', 'created': t(19), 'text': '  ▲ Next.js 15.1.4'},
      {'type': 'stdout', 'created': t(20), 'text': '  - Linting and checking validity of types'},
      {'type': 'stdout', 'created': t(21), 'text': '  - Environments: .env.production, .env.local'},
      {'type': 'stdout', 'created': t(22), 'text': '  - Loading env from .env.production'},
      {'type': 'stdout', 'created': t(23), 'text': '  ✓ Loaded env from .env.production (8 variables)'},
      {'type': 'stdout', 'created': t(24), 'text': '   Creating an optimized production build ...'},
      {'type': 'stdout', 'created': t(28), 'text': '  ✓ Compiled successfully'},
      {'type': 'stdout', 'created': t(29), 'text': '  ✓ Linting and checking validity of types'},
      {'type': 'stdout', 'created': t(31), 'text': '  ✓ Collecting page data'},
      {'type': 'stdout', 'created': t(33), 'text': '    [ ] /'},
      {'type': 'stdout', 'created': t(34), 'text': '    [ ] /about'},
      {'type': 'stdout', 'created': t(35), 'text': '    [ ] /pricing'},
      {'type': 'stdout', 'created': t(36), 'text': '    [ ] /blog/[slug]'},
      {'type': 'stdout', 'created': t(37), 'text': '    [ ] /dashboard'},
      {'type': 'stdout', 'created': t(38), 'text': '    [ ] /api/auth/*'},
      {'type': 'stdout', 'created': t(39), 'text': '    [ ] /api/webhooks/*'},
      {'type': 'stdout', 'created': t(40), 'text': '  ✓ Generating static pages (27/27)'},
      {'type': 'stdout', 'created': t(41), 'text': '    / (312ms)'},
      {'type': 'stdout', 'created': t(42), 'text': '    /about (245ms)'},
      {'type': 'stdout', 'created': t(43), 'text': '    /pricing (287ms)'},
      {'type': 'stdout', 'created': t(44), 'text': '    /blog/first-post (198ms)'},
      {'type': 'stdout', 'created': t(45), 'text': '    /blog/second-post (203ms)'},
      {'type': 'stdout', 'created': t(46), 'text': '  ✓ Finalizing page optimization'},
      {'type': 'stdout', 'created': t(47), 'text': '  ✓ Collecting build traces'},
      {'type': 'stdout', 'created': t(48), 'text': '  ✓ Generating route manifests'},
      {'type': 'delimiter', 'created': t(49), 'text': 'Deploying outputs'},
      {'type': 'stdout', 'created': t(50), 'text': 'Uploading build output...'},
      {'type': 'stdout', 'created': t(52), 'text': 'Build output uploaded: 42.3 MB'},
      {'type': 'stdout', 'created': t(53), 'text': 'Deploying to Edge Network...'},
      {'type': 'stdout', 'created': t(55), 'text': 'Deployment completed in 52.3s'},
      {'type': 'stdout', 'created': t(56), 'text': 'Production: https://vero.app (42.3 MB)'},
      {'type': 'stdout', 'created': t(57), 'text': 'Preview: https://vero-app-git-main.vero-demo.vercel.app (42.3 MB)'},
    ];
  }

  /// Runtime / request logs for a deployment.
  static List<Map<String, dynamic>> buildRuntimeLogs() {
    final now = DateTime.now();
    final paths = ['/', '/api/health', '/api/products', '/checkout', '/about', '/api/auth/session'];
    final methods = ['GET', 'GET', 'GET', 'POST', 'GET', 'GET'];
    final statuses = [200, 200, 200, 201, 200, 200];

    return List.generate(12, (i) {
      return {
        'message':
            '${methods[i % methods.length]} ${paths[i % paths.length]} -> ${statuses[i % statuses.length]} (${12 + (i * 7) % 80}ms)',
        'level': 'info',
        'timestamp': now.subtract(Duration(seconds: i * 4)).toIso8601String(),
        'source': 'edge',
        'region': 'iad1',
      };
    });
  }

  /// Representative request logs (for the /logs/request-logs endpoint).
  static Map<String, dynamic> buildProjectLogsResponse(String projectId) {
    final now = DateTime.now();
    final rows = <Map<String, dynamic>>[];
    final paths = ['/', '/blog', '/pricing', '/api/users/me', '/api/checkout', '/dashboard'];
    final statuses = [200, 200, 304, 401, 200, 500];
    final methods = ['GET', 'GET', 'GET', 'GET', 'POST', 'GET'];
    final regions = ['iad1', 'fra1', 'sfo1', 'cdg1', 'hnd1'];

    for (var i = 0; i < 25; i++) {
      final ts = now.subtract(Duration(seconds: i * 7)).toIso8601String();
      rows.add({
        'requestId': 'req_${projectId}_$i',
        'timestamp': ts,
        'branch': 'main',
        'deploymentId': 'dpl_${projectId}_prod',
        'domain': 'vero.app',
        'deploymentDomain': 'vero.app',
        'environment': 'production',
        'requestPath': paths[i % paths.length],
        'route': paths[i % paths.length],
        'clientUserAgent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131 Safari/537.36',
        'clientRegion': regions[i % regions.length],
        'requestSearchParams': const <String, dynamic>{},
        'requestMethod': methods[i % methods.length],
        'cache': i % 3 == 0 ? 'HIT' : 'MISS',
        'statusCode': statuses[i % statuses.length],
        'events': const [],
        'logs': const [],
        'requestTags': const [],
      });
    }

    return {
      'rows': rows,
      'hasMoreRows': false,
    };
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
