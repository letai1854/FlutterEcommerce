import 'package:e_commerce_app/models/chat/conversation_dto.dart'; // Updated import
import 'package:e_commerce_app/widgets/Chat/MessageListItem.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting dates
import 'package:e_commerce_app/services/chat_service.dart'; // Import ChatService

class MessageList extends StatefulWidget {
  final List<ConversationDTO> conversations; // Changed from Future to List
  final Function(ConversationDTO) onChatSelected;
  final int? selectedChatId;
  final ScrollController scrollController; // For pagination
  final bool isLoadingMore; // To show loading indicator at the bottom
  final ChatService chatService; // Add ChatService

  const MessageList({
    Key? key,
    required this.conversations,
    required this.onChatSelected,
    this.selectedChatId,
    required this.scrollController,
    required this.isLoadingMore,
    required this.chatService, // Add ChatService
  }) : super(key: key);

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final TextEditingController _searchController = TextEditingController();
  List<ConversationDTO> _filteredConversations = [];

  @override
  void initState() {
    super.initState();
    _filteredConversations = widget.conversations;
    _searchController.addListener(_filterConversations);
  }

  @override
  void didUpdateWidget(covariant MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.conversations != oldWidget.conversations) {
      _filterConversations(); // Re-filter if the original list changes
    }
  }

  void _filterConversations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredConversations = widget.conversations;
      } else {
        _filteredConversations = widget.conversations.where((convo) {
          return convo.title.toLowerCase().contains(query) ||
                 convo.customerName.toLowerCase().contains(query) ||
                 (convo.lastMessage?.content?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterConversations);
    _searchController.dispose();
    super.dispose();
  }
  
  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOfMessage = DateTime(dt.year, dt.month, dt.day);

    if (dateOfMessage == today) {
      return DateFormat.Hm().format(dt); // HH:mm
    } else if (dateOfMessage == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat.MMMd().format(dt); // e.g., Sep 10
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.grey[100],
        elevation: 0.5,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search Conversations',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ),
      body: _filteredConversations.isEmpty && _searchController.text.isEmpty && !widget.isLoadingMore
          ? const Center(child: Text("No conversations yet."))
          : _filteredConversations.isEmpty && _searchController.text.isNotEmpty
              ? const Center(child: Text("No conversations match your search."))
              : ListView.separated(
                  controller: widget.scrollController,
                  itemCount: _filteredConversations.length + (widget.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _filteredConversations.length && widget.isLoadingMore) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ));
                    }
                    final conversation = _filteredConversations[index];
                    final bool isSelected = widget.selectedChatId == conversation.id;
                    
                    // Use FutureBuilder to get the avatar URL
                    return FutureBuilder<String?>(
                      future: widget.chatService.getFullUserAvatarUrl(conversation.customerId),
                      builder: (context, snapshot) {
                        String avatarUrl;
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          // You could use a placeholder image or a loading indicator specific to avatar
                          avatarUrl = 'https://via.placeholder.com/150/cccccc/969696?Text=Loading'; 
                        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                          avatarUrl = 'assets/default_avatar.png'; // Default local asset if fetch fails or no avatar
                        } else {
                          avatarUrl = snapshot.data!;
                        }

                        final chatData = {
                          'id': conversation.id.toString(),
                          'name': conversation.customerName,
                          'message': conversation.lastMessage != null 
                              ? "${conversation.lastMessage!.senderFullName}: ${conversation.lastMessage!.content ?? '[Media]'}" // Changed [Image] to [Media] for generality
                              : "No messages yet.",
                          'time': conversation.lastMessage != null 
                              ? _formatDateTime(conversation.lastMessage!.sendTime.toLocal())
                              : _formatDateTime(conversation.updatedDate.toLocal()),
                          'avatar': avatarUrl, // Use the resolved avatarUrl
                          'isOnline': false, 
                          'unreadCount': conversation.unreadCount,
                        };

                        return MessageListItem(
                          chatData: chatData,
                          isSelected: isSelected,
                          onTap: () => widget.onChatSelected(conversation),
                        );
                      },
                    );
                  },
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 1,
                    indent: 70,
                    color: Colors.grey[200],
                  ),
                ),
    );
  }
}
