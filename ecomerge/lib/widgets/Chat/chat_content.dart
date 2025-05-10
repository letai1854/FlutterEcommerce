import 'package:e_commerce_app/models/chat/chat_message_ui.dart';
import 'package:e_commerce_app/services/chat_service.dart';
import 'package:e_commerce_app/widgets/Chat/ChatBubble.dart';
import 'package:flutter/material.dart';

class ChatContent extends StatefulWidget {
  final List<ChatMessageUI> messages;
  final TextEditingController textController;
  final ScrollController scrollController;
  final Function(String) onMessageSubmitted;
  final Map<String, dynamic> chatPartnerData;
  final int currentUserId;
  final ChatService chatService;
  final Future<void> Function() onImagePickerRequested;
  final bool isLoadingMoreMessages;
  final VoidCallback? onAppBarBackButtonPressed;

  const ChatContent({
    Key? key,
    required this.messages,
    required this.textController,
    required this.scrollController,
    required this.onMessageSubmitted,
    required this.chatPartnerData,
    required this.currentUserId,
    required this.chatService,
    required this.onImagePickerRequested,
    required this.isLoadingMoreMessages,
    this.onAppBarBackButtonPressed,
  }) : super(key: key);

  @override
  State<ChatContent> createState() => _ChatContentState();
}

class _ChatContentState extends State<ChatContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController.hasClients) {
        widget.scrollController.jumpTo(widget.scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void didUpdateWidget(covariant ChatContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length && !widget.isLoadingMoreMessages) {
      bool isNewMessageAddedAtEnd = widget.messages.length > oldWidget.messages.length;
      if (isNewMessageAddedAtEnd) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (widget.scrollController.hasClients) {
            widget.scrollController.animateTo(
              widget.scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String partnerName = widget.chatPartnerData['name'] ?? 'Người dùng';
    final String partnerAvatar = widget.chatPartnerData['avatar'] ?? 'assets/default_avatar.png';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0.5,
        backgroundColor: Colors.grey[50],
        titleSpacing: 0,
        title: Row(
          children: [
            if (MediaQuery.of(context).size.width < 768 && widget.onAppBarBackButtonPressed != null)
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700], size: 20),
                onPressed: widget.onAppBarBackButtonPressed,
              )
            else
              SizedBox(width: MediaQuery.of(context).size.width < 768 ? 0 : 10),
            CircleAvatar(
              backgroundImage: AssetImage(partnerAvatar),
              radius: 18,
              backgroundColor: Colors.grey[300],
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    partnerName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.messages.isEmpty && !widget.isLoadingMoreMessages
                ? Center(
                    child: Text(
                      'Bắt đầu cuộc trò chuyện!',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView.builder(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    itemCount: widget.messages.length + (widget.isLoadingMoreMessages ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (widget.isLoadingMoreMessages && index == 0) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final messageIndex = widget.isLoadingMoreMessages ? index - 1 : index;
                      final message = widget.messages[messageIndex]; // message is ChatMessageUI
                      final bool isMe = message.senderId == widget.currentUserId.toString();
                      return ChatBubble(
                        message: message, // This is ChatMessageUI, ChatBubble needs to accept this type
                        isMe: isMe,
                        chatService: widget.chatService,
                      );
                    },
                  ),
          ),
          _buildChatInput(),
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            onPressed: widget.onImagePickerRequested,
            icon: Icon(Icons.image_outlined, color: Colors.deepOrange),
            tooltip: 'Gửi ảnh',
          ),
          Expanded(
            child: Container(
              constraints: BoxConstraints(maxHeight: 100),
              child: TextField(
                controller: widget.textController,
                decoration: InputDecoration(
                  hintText: 'Nhắn tin...',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide(color: Colors.deepOrange, width: 1),
                  ),
                  isDense: true,
                ),
                style: TextStyle(fontSize: 15),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: widget.onMessageSubmitted,
              ),
            ),
          ),
          IconButton(
            onPressed: () => widget.textController.text.trim().isNotEmpty
                ? widget.onMessageSubmitted(widget.textController.text)
                : null,
            icon: Icon(
              Icons.send,
              color: widget.textController.text.trim().isNotEmpty ? Colors.deepOrange : Colors.grey[400],
            ),
            tooltip: 'Gửi',
          ),
        ],
      ),
    );
  }
}
