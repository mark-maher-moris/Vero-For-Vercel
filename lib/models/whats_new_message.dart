/// Model representing a "What's New" release announcement message.
/// Used to deliver local notifications on app update.
class WhatsNewMessage {
  /// Unique identifier for this message (used to avoid sending the same notification twice)
  final String id;

  /// Target app version (e.g. "1.3.2")
  final String targetVersion;

  /// Notification title
  final String title;

  /// Notification body / description
  final String body;

  /// Whether this notification is targeted strictly to Pro users (`true`) or all users (`false`)
  final bool isProOnly;

  /// Whether this notification is targeted strictly to iOS users (`true`) or both iOS & Android (`false`)
  final bool isIosOnly;

  /// Whether this notification is targeted strictly to Android users (`true`) or both iOS & Android (`false`)
  final bool isAndroidOnly;

  /// Optional payload data (e.g. a deep link or route name)
  final String? payload;

  /// Optional release date
  final DateTime? releaseDate;

  const WhatsNewMessage({
    required this.id,
    required this.targetVersion,
    required this.title,
    required this.body,
    this.isProOnly = false,
    this.isIosOnly = false,
    this.isAndroidOnly = false,
    this.payload,
    this.releaseDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'targetVersion': targetVersion,
    'title': title,
    'body': body,
    'isProOnly': isProOnly,
    'isIosOnly': isIosOnly,
    'isAndroidOnly': isAndroidOnly,
    'payload': payload,
    'releaseDate': releaseDate?.toIso8601String(),
  };

  factory WhatsNewMessage.fromJson(Map<String, dynamic> json) => WhatsNewMessage(
    id: json['id'] as String,
    targetVersion: json['targetVersion'] as String? ?? '',
    title: json['title'] as String,
    body: json['body'] as String,
    isProOnly: json['isProOnly'] as bool? ?? false,
    isIosOnly: json['isIosOnly'] as bool? ?? false,
    isAndroidOnly: json['isAndroidOnly'] as bool? ?? false,
    payload: json['payload'] as String?,
    releaseDate: json['releaseDate'] != null
        ? DateTime.tryParse(json['releaseDate'] as String)
        : null,
  );
}
