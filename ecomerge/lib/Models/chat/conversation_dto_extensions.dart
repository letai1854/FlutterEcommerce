import 'package:e_commerce_app/models/chat/last_message_info.dart'; // Standardized to lowercase 'models'
import 'package:e_commerce_app/models/chat/conversation_dto.dart'; // Standardized to lowercase 'models'

extension ConversationDTOCopyWith on ConversationDTO {
  ConversationDTO copyWith({
    int? id,
    int? customerId,
    String? customerName,
    String? title,
    String? status,
    DateTime? createdDate,
    DateTime? updatedDate,
    LastMessageInfo? lastMessage,
    int? unreadCount,
  }) {
    return ConversationDTO(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      title: title ?? this.title,
      status: status ?? this.status,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
      lastMessage: lastMessage ?? this.lastMessage, // Removed unnecessary cast
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
