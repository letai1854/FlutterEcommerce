import 'package:intl/intl.dart';

class MessageDTO {
  final int id;
  final int conversationId;
  final int senderId;
  final String senderFullName;
  final String? content;
  final String? imageUrl;
  final DateTime sendTime;

  MessageDTO({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderFullName,
    this.content,
    this.imageUrl,
    required this.sendTime,
  });

  factory MessageDTO.fromJson(Map<String, dynamic> json) {
    return MessageDTO(
      id: json['id'],
      conversationId: json['conversationId'],
      senderId: json['senderId'],
      senderFullName: json['senderFullName'],
      content: json['content'],
      imageUrl: json['imageUrl'],
      sendTime: DateTime.parse(json['sendTime']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderFullName': senderFullName,
      'content': content,
      'imageUrl': imageUrl,
      'sendTime': sendTime.toIso8601String(),
    };
  }

  String get formattedSendTime {
    return DateFormat('hh:mm a').format(sendTime.toLocal());
  }
}
