/// Represents the attack challenge mode status for a project
class AttackModeStatus {
  final bool enabled;
  final DateTime? activeUntil;
  final DateTime? updatedAt;

  AttackModeStatus({
    required this.enabled,
    this.activeUntil,
    this.updatedAt,
  });

  factory AttackModeStatus.fromJson(Map<String, dynamic> json) {
    return AttackModeStatus(
      enabled: json['attackModeEnabled'] == 'true' || json['attackModeEnabled'] == true,
      activeUntil: json['attackModeActiveUntil'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              int.tryParse(json['attackModeActiveUntil'].toString()) ?? 0)
          : null,
      updatedAt: json['attackModeUpdatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              int.tryParse(json['attackModeUpdatedAt'].toString()) ?? 0)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attackModeEnabled': enabled.toString(),
      if (activeUntil != null)
        'attackModeActiveUntil': activeUntil!.millisecondsSinceEpoch.toString(),
    };
  }
}

/// Represents a firewall rule
class FirewallRule {
  final String id;
  final String name;
  final String action;
  final String? ip;
  final String? hostname;
  final int? rateLimit;
  final String? rateLimitWindow;
  final bool? isWAFRule;
  final int? statusCode;
  final String? redirectLocation;

  FirewallRule({
    required this.id,
    required this.name,
    required this.action,
    this.ip,
    this.hostname,
    this.rateLimit,
    this.rateLimitWindow,
    this.isWAFRule,
    this.statusCode,
    this.redirectLocation,
  });

  factory FirewallRule.fromJson(Map<String, dynamic> json) {
    return FirewallRule(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unnamed Rule',
      action: json['action'] ?? 'deny',
      ip: json['ip'],
      hostname: json['hostname'],
      rateLimit: json['rateLimit'] != null
          ? int.tryParse(json['rateLimit'].toString())
          : null,
      rateLimitWindow: json['rateLimitWindow'],
      isWAFRule: json['isWAFRule'] == true || json['isWAFRule'] == 'true',
      statusCode: json['statusCode'] != null
          ? int.tryParse(json['statusCode'].toString())
          : null,
      redirectLocation: json['redirectLocation'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'action': action,
      'name': name,
    };
    if (ip != null) data['ip'] = ip;
      if (hostname != null) data['hostname'] = hostname;
    if (rateLimit != null) data['rateLimit'] = rateLimit.toString();
    if (rateLimitWindow != null) data['rateLimitWindow'] = rateLimitWindow;
    if (statusCode != null) data['statusCode'] = statusCode.toString();
    if (redirectLocation != null) data['redirectLocation'] = redirectLocation;
    return data;
  }
}

/// Represents the complete firewall configuration for a project
class FirewallConfig {
  final bool enabled;
  final List<FirewallRule> rules;
  final List<ManagedRuleset> managedRulesets;
  final List<String> ips;
  final DateTime? updatedAt;

  FirewallConfig({
    required this.enabled,
    required this.rules,
    required this.managedRulesets,
    required this.ips,
    this.updatedAt,
  });

  factory FirewallConfig.fromJson(Map<String, dynamic> json) {
    final rulesList = json['rules'] as List<dynamic>? ?? [];
    final rulesetsList = json['managedRulesets'] as List<dynamic>? ?? [];
    final ipsList = json['ips'] as List<dynamic>? ?? [];

    return FirewallConfig(
      enabled: json['enabled'] == true || json['enabled'] == 'true',
      rules: rulesList.map((r) => FirewallRule.fromJson(r)).toList(),
      managedRulesets: rulesetsList.map((r) => ManagedRuleset.fromJson(r)).toList(),
      ips: ipsList.map((ip) => ip.toString()).toList(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}

/// Represents a managed WAF ruleset
class ManagedRuleset {
  final String id;
  final String name;
  final bool enabled;
  final String action;
  final String? description;

  ManagedRuleset({
    required this.id,
    required this.name,
    required this.enabled,
    required this.action,
    this.description,
  });

  factory ManagedRuleset.fromJson(Map<String, dynamic> json) {
    return ManagedRuleset(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Ruleset',
      enabled: json['active'] == true || json['active'] == 'true',
      action: json['action'] ?? 'challenge',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'active': enabled,
      'action': action,
    };
  }
}
