class LastMessageInfo {
  final int id;
  final String senderFullName;
  final String? content;
  final DateTime sendTime;
  // Add other relevant fields from MessageDTO if needed for display in conversation list

  LastMessageInfo({
    required this.id,
    required this.senderFullName,
    this.content,
    required this.sendTime,
  });

  factory LastMessageInfo.fromJson(Map<String, dynamic> json) {
    return LastMessageInfo(
      id: json['id'],
      senderFullName: json['senderFullName'],
      content: json['content'],
      sendTime: DateTime.parse(json['sendTime']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderFullName': senderFullName,
      'content': content,
      'sendTime': sendTime.toIso8601String(),
    };
  }
}
