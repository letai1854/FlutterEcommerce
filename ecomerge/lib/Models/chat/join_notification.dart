class JoinNotification {
  final String type; // Should be "JOIN"
  final String user; // Username of the user who joined
  final DateTime timestamp;

  JoinNotification({
    required this.type,
    required this.user,
    required this.timestamp,
  });

  factory JoinNotification.fromJson(Map<String, dynamic> json) {
    return JoinNotification(
      type: json['type'],
      user: json['user'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
