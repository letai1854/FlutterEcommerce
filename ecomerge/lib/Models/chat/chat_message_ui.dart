import 'package:e_commerce_app/models/chat/message_dto.dart';
import 'package:e_commerce_app/services/chat_service.dart'; // For getImageUrl

// UI model for a chat message
class ChatMessageUI {
  final String id;
  final String? text;
  final String senderId;
  final String senderFullName;
  final DateTime sendTime;
  final String? imageUrl; // This will be the full URL
  final bool isImageLoading; // To indicate if the image is still being uploaded/processed

  ChatMessageUI({
    required this.id,
    this.text,
    required this.senderId,
    required this.senderFullName,
    required this.sendTime,
    this.imageUrl,
    this.isImageLoading = false,
  });
}

// Conversion function
ChatMessageUI messageDtoToChatMessageUI(MessageDTO dto, ChatService chatService) {
  String? fullImageUrl;
  if (dto.imageUrl != null && dto.imageUrl!.isNotEmpty) {
    // Assuming dto.imageUrl is a relative path from the backend
    // and chatService.getImageUrl constructs the full URL.
    fullImageUrl = chatService.getImageUrl(dto.imageUrl);
  }

  return ChatMessageUI(
    id: dto.id.toString(),
    text: dto.content,
    senderId: dto.senderId.toString(),
    senderFullName: dto.senderFullName,
    sendTime: dto.sendTime,
    imageUrl: fullImageUrl,
    // isImageLoading: dto.id < 0, // Example: if using negative IDs for optimistic local messages
  );
}
