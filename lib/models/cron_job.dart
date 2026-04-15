class CronJob {
  final String host;
  final String path;
  final String schedule;

  CronJob({
    required this.host,
    required this.path,
    required this.schedule,
  });

  factory CronJob.fromJson(Map<String, dynamic> json) {
    return CronJob(
      host: json['host'] as String,
      path: json['path'] as String,
      schedule: json['schedule'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'host': host,
      'path': path,
      'schedule': schedule,
    };
  }

  String get fullUrl => 'https://$host$path';

  String get displaySchedule {
    final parts = schedule.split(' ');
    if (parts.length == 5) {
      final minute = parts[0];
      final hour = parts[1];
      final dayOfMonth = parts[2];
      final month = parts[3];
      final dayOfWeek = parts[4];

      if (minute == '0' && hour == '0' && dayOfMonth == '*' && month == '*' && dayOfWeek == '*') {
        return 'Daily at midnight';
      }
      if (minute == '0' && dayOfMonth == '*' && month == '*' && dayOfWeek == '*') {
        return 'Daily at $hour:00';
      }
      if (minute == '0' && hour == '0' && dayOfMonth == '*' && month == '*' && dayOfWeek == '0') {
        return 'Weekly on Sunday';
      }
      if (minute == '0' && hour == '0' && dayOfMonth == '1' && month == '*') {
        return 'Monthly on the 1st';
      }
      if (minute == '*/5' && dayOfMonth == '*' && month == '*' && dayOfWeek == '*') {
        return 'Every 5 minutes';
      }
      if (minute == '*/15' && dayOfMonth == '*' && month == '*' && dayOfWeek == '*') {
        return 'Every 15 minutes';
      }
      if (minute == '*/30' && dayOfMonth == '*' && month == '*' && dayOfWeek == '*') {
        return 'Every 30 minutes';
      }
      if (minute == '0' && hour == '*/1' && dayOfMonth == '*' && month == '*' && dayOfWeek == '*') {
        return 'Every hour';
      }
    }
    return schedule;
  }
}

class ProjectCrons {
  final DateTime? enabledAt;
  final DateTime? disabledAt;
  final DateTime? updatedAt;
  final String? deploymentId;
  final List<CronJob> definitions;

  ProjectCrons({
    this.enabledAt,
    this.disabledAt,
    this.updatedAt,
    this.deploymentId,
    required this.definitions,
  });

  factory ProjectCrons.fromJson(Map<String, dynamic> json) {
    return ProjectCrons(
      enabledAt: json['enabledAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['enabledAt'] as int)
          : null,
      disabledAt: json['disabledAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['disabledAt'] as int)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int)
          : null,
      deploymentId: json['deploymentId'] as String?,
      definitions: (json['definitions'] as List<dynamic>?)
              ?.map((e) => CronJob.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  bool get isEnabled => enabledAt != null && disabledAt == null;

  int get jobCount => definitions.length;
}
