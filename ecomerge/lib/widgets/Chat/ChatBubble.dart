import 'package:e_commerce_app/Models/ChatMessage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Thêm intl để định dạng thời gian

class ChatBubble extends StatelessWidget {
  const ChatBubble({Key? key, required this.message}) : super(key: key);

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    // Định dạng thời gian (ví dụ: 10:30)
    final timeFormat = DateFormat('HH:mm');

    // Xác định màu sắc và căn chỉnh dựa trên người gửi
    final bubbleColor = message.isMe ? Colors.blue[100] : Colors.grey[200]; // Màu nhạt hơn
    final alignment = message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleAlignment = message.isMe ? Alignment.centerRight : Alignment.centerLeft;
    final textColor = message.isMe ? Colors.black87 : Colors.black87;
    final timeColor = message.isMe ? Colors.black54 : Colors.black54;

    // Radius bo góc
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      // Bo góc dưới khác nhau tùy người gửi
      bottomLeft: Radius.circular(message.isMe ? 16 : 0),
      bottomRight: Radius.circular(message.isMe ? 0 : 16),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Giảm vertical padding
      alignment: bubbleAlignment, // Căn cả container bubble sang trái hoặc phải
      child: Container(
        constraints: BoxConstraints(
          // Giới hạn chiều rộng của bubble
          maxWidth: MediaQuery.of(context).size.width * 0.7, // Tối đa 70% chiều rộng màn hình
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: borderRadius,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Padding bên trong bubble
        child: Column(
          crossAxisAlignment: alignment, // Căn text và thời gian bên trong bubble
          mainAxisSize: MainAxisSize.min, // Chỉ chiếm không gian cần thiết
          children: [
            Text(
              message.text,
              style: TextStyle(fontSize: 15, color: textColor), // Cỡ chữ 15
            ),
            SizedBox(height: 4), // Khoảng cách nhỏ
            Text(
              timeFormat.format(message.timestamp), // Hiển thị thời gian đã định dạng
              style: TextStyle(fontSize: 10, color: timeColor),
            ),
          ],
        ),
      ),
    );
  }
}
