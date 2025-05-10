import 'last_message_info.dart'; // Import LastMessageInfo

class ConversationDTO {
  final int id;
  final int customerId;
  final String? customerEmail; // Added, nullable
  final String customerName; // Was customerName, maps to customerFullName
  final int? adminId; // Added, nullable
  final String? adminEmail; // Added, nullable
  final String? adminFullName; // Added, nullable
  final String title;
  final String status; // "moi", "dang_xu_ly", "da_dong"
  final DateTime createdDate;
  final DateTime updatedDate;
  final LastMessageInfo? lastMessage;
  final int unreadCount; // Maps to unreadMessagesCount

  ConversationDTO({
    required this.id,
    required this.customerId,
    this.customerEmail,
    required this.customerName,
    this.adminId,
    this.adminEmail,
    this.adminFullName,
    required this.title,
    required this.status,
    required this.createdDate,
    required this.updatedDate,
    this.lastMessage,
    required this.unreadCount,
  });

  factory ConversationDTO.fromJson(Map<String, dynamic> json) {
    return ConversationDTO(
      id: json['id'],
      customerId: json['customerId'],
      customerEmail: json['customerEmail'] as String?,
      customerName: json['customerFullName'] as String? ?? '', // Map from customerFullName, provide default
      adminId: json['adminId'] as int?,
      adminEmail: json['adminEmail'] as String?,
      adminFullName: json['adminFullName'] as String?,
      title: json['title'] as String? ?? 'Chat', // Provide default if title can be null
      status: json['status'] as String? ?? 'moi', // Provide default if status can be null
      createdDate: DateTime.parse(json['createdDate']),
      updatedDate: DateTime.parse(json['updatedDate']),
      lastMessage: json['lastMessage'] != null
          ? LastMessageInfo.fromJson(json['lastMessage'])
          : null,
      // Ensure unreadCount maps from unreadMessagesCount and handles null
      unreadCount: (json['unreadMessagesCount'] ?? json['unreadCount'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerEmail': customerEmail,
      'customerFullName': customerName, // Changed to customerFullName to match common API practice
      'adminId': adminId,
      'adminEmail': adminEmail,
      'adminFullName': adminFullName,
      'title': title,
      'status': status,
      'createdDate': createdDate.toIso8601String(),
      'updatedDate': updatedDate.toIso8601String(),
      'lastMessage': lastMessage?.toJson(),
      'unreadMessagesCount': unreadCount, // Changed to unreadMessagesCount
    };
  }
}

// Enum for conversation status for easier management
enum ConversationStatus { moi, dang_xu_ly, da_dong }

extension ConversationStatusExtension on ConversationStatus {
  String get value {
    switch (this) {
      case ConversationStatus.moi:
        return 'moi';
      case ConversationStatus.dang_xu_ly:
        return 'dang_xu_ly';
      case ConversationStatus.da_dong:
        return 'da_dong';
    }
  }

  static ConversationStatus fromString(String status) {
    switch (status) {
      case 'moi':
        return ConversationStatus.moi;
      case 'dang_xu_ly':
        return ConversationStatus.dang_xu_ly;
      case 'da_dong':
        return ConversationStatus.da_dong;
      default:
        return ConversationStatus.moi; // Default or throw error
    }
  }
}
