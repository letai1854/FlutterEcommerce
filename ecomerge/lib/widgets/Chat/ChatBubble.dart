import 'package:e_commerce_app/models/chat/chat_message_ui.dart'; // Changed import
import 'package:e_commerce_app/services/chat_service.dart'; 
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting time

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    Key? key,
    required this.message, // Will be ChatMessageUI
    required this.isMe,
    required this.chatService, 
  }) : super(key: key);

  final ChatMessageUI message; // Changed from MessageDTO to ChatMessageUI
  final bool isMe;
  final ChatService chatService; // Still needed if ChatMessageUI.imageUrl is relative, or for future uses

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe ? Colors.blue[100] : Colors.grey[200];
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleAlignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final textColor = Colors.black87;
    final timeColor = Colors.black54;

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMe ? 16 : 0),
      bottomRight: Radius.circular(isMe ? 0 : 16),
    );

    // Helper to format time from ChatMessageUI's sendTime
    String getFormattedSendTime(DateTime dt) {
      return DateFormat('hh:mm a').format(dt.toLocal());
    }

    Widget messageContent;
    // ChatMessageUI.imageUrl should already be the full URL if processed by messageDtoToChatMessageUI
    if (message.imageUrl != null && message.imageUrl!.isNotEmpty) {
      messageContent = Container(
        constraints: BoxConstraints(
          maxHeight: 200, 
          maxWidth: MediaQuery.of(context).size.width * 0.6, 
        ),
        child: ClipRRect(
          borderRadius: borderRadius, 
          child: Image.network(
            message.imageUrl!, // Directly use imageUrl from ChatMessageUI
            fit: BoxFit.cover,
            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
          ),
        ),
      );
    } else {
      messageContent = Text(
        message.text ?? '', // Use message.text from ChatMessageUI
        style: TextStyle(fontSize: 15, color: textColor),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      alignment: bubbleAlignment,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          // Use message.imageUrl from ChatMessageUI
          color: message.imageUrl != null && message.imageUrl!.isNotEmpty ? Colors.transparent : bubbleColor, 
          borderRadius: borderRadius,
        ),
        // Use message.imageUrl and message.text from ChatMessageUI
        padding: message.imageUrl != null && message.imageUrl!.isNotEmpty && message.text == null
            ? EdgeInsets.zero 
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: alignment,
          mainAxisSize: MainAxisSize.min,
          children: [
            messageContent,
            // Use message.text and message.imageUrl from ChatMessageUI
            if (message.text != null && message.imageUrl != null) 
              const SizedBox(height: 4),
            // Use message.text and message.imageUrl from ChatMessageUI
            if (message.text != null || (message.imageUrl != null && message.text == null)) 
              Padding(
                // Use message.imageUrl and message.text from ChatMessageUI
                padding: message.imageUrl != null && message.imageUrl!.isNotEmpty && message.text == null
                  ? const EdgeInsets.only(top: 4.0) 
                  : EdgeInsets.zero,
                child: Text(
                  getFormattedSendTime(message.sendTime), // Format sendTime from ChatMessageUI
                  style: TextStyle(fontSize: 10, color: timeColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
