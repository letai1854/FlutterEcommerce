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
  // Track previous scroll position to detect if we're near the bottom
  bool _wasAtBottom = true;
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _previousMessageCount = widget.messages.length;
    // Initial scroll to bottom after first layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animate: false);
    });
  }

  // Helper method to check if scroll is at or near bottom
  bool _isScrollAtBottom() {
    if (!widget.scrollController.hasClients) return true;

    final ScrollPosition position = widget.scrollController.position;
    // Consider "at bottom" if within 20 pixels of the end
    return position.pixels >= position.maxScrollExtent - 20;
  }

  // Helper method to scroll to bottom
  void _scrollToBottom({bool animate = true}) {
    if (!widget.scrollController.hasClients) return;

    final double maxScroll = widget.scrollController.position.maxScrollExtent;
    if (animate) {
      widget.scrollController.animateTo(
        maxScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      widget.scrollController.jumpTo(maxScroll);
    }
  }

  @override
  void didUpdateWidget(covariant ChatContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if we were near the bottom before update
    _wasAtBottom = _isScrollAtBottom();

    // Handle new messages being added
    if (widget.messages.length != _previousMessageCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // If we're loading messages at the top (older messages), don't scroll
        if (widget.isLoadingMoreMessages &&
            widget.messages.length > _previousMessageCount) {
          // Don't scroll when loading older messages
          return;
        }

        // Auto-scroll if:
        // 1. New messages were added AND
        // 2. Either we were already at the bottom OR a message was sent by the current user
        if (widget.messages.length > _previousMessageCount &&
            (_wasAtBottom ||
                (widget.messages.isNotEmpty &&
                    widget.messages.last.senderId ==
                        widget.currentUserId.toString()))) {
          _scrollToBottom();
        }

        // Update count for next comparison
        _previousMessageCount = widget.messages.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String partnerName = widget.chatPartnerData['name'] ?? 'User';
    final Future<String?> partnerAvatarUrlFuture =
        widget.chatPartnerData['avatar'] as Future<String?>;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0.5,
        backgroundColor: Colors.grey[50],
        titleSpacing: 0,
        title: Row(
          children: [
            if (MediaQuery.of(context).size.width < 768 &&
                widget.onAppBarBackButtonPressed != null)
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new,
                    color: Colors.grey[700], size: 20),
                onPressed: widget.onAppBarBackButtonPressed,
              )
            else
              SizedBox(width: MediaQuery.of(context).size.width < 768 ? 0 : 10),
            FutureBuilder<String?>(
              future: partnerAvatarUrlFuture,
              builder: (context, snapshot) {
                ImageProvider partnerAvatarImage;
                bool isPartnerAvatarNetwork = false;
                String? resolvedAvatarUrl;

                if (snapshot.connectionState == ConnectionState.waiting) {
                  partnerAvatarImage =
                      const AssetImage('assets/default_avatar.png');
                } else if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data == null) {
                  partnerAvatarImage =
                      const AssetImage('assets/default_avatar.png');
                } else {
                  resolvedAvatarUrl = snapshot.data!;
                  if (resolvedAvatarUrl.startsWith('http://') ||
                      resolvedAvatarUrl.startsWith('https://')) {
                    partnerAvatarImage = NetworkImage(resolvedAvatarUrl);
                    isPartnerAvatarNetwork = true;
                  } else {
                    partnerAvatarImage = AssetImage(resolvedAvatarUrl);
                  }
                }

                return CircleAvatar(
                  backgroundImage: partnerAvatarImage,
                  onBackgroundImageError: isPartnerAvatarNetwork
                      ? (exception, stackTrace) {
                          // print('Error loading partner network avatar: $exception');
                        }
                      : null,
                  radius: 18,
                  backgroundColor: Colors.grey[300],
                );
              },
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    partnerName,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87),
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
                    itemCount: widget.messages.length +
                        (widget.isLoadingMoreMessages ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (widget.isLoadingMoreMessages && index == 0) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final messageIndex =
                          widget.isLoadingMoreMessages ? index - 1 : index;
                      final message = widget.messages[messageIndex];
                      final bool isMe =
                          message.senderId == widget.currentUserId.toString();

                      // For image messages, add a listener to scroll when loaded
                      if (message.imageUrl != null &&
                          message.imageUrl!.isNotEmpty &&
                          messageIndex == widget.messages.length - 1) {
                        return ChatBubble(
                          message: message,
                          isMe: isMe,
                          chatService: widget.chatService,
                          onImageLoaded: _wasAtBottom
                              ? () {
                                  // Scroll to bottom after image loads
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    _scrollToBottom();
                                  });
                                }
                              : null,
                        );
                      }

                      return ChatBubble(
                        message: message,
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
        border:
            Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            onPressed: () {
              widget.onImagePickerRequested().then((_) {
                // Ensure we scroll after image is sent
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });
              });
            },
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
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300, width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300, width: 0.5),
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
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) {
                    widget.onMessageSubmitted(text);
                    // Ensure we scroll after sending
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });
                  }
                },
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              if (widget.textController.text.trim().isNotEmpty) {
                widget.onMessageSubmitted(widget.textController.text);
                // Ensure we scroll after sending
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });
              }
            },
            icon: Icon(
              Icons.send,
              color: widget.textController.text.trim().isNotEmpty
                  ? Colors.deepOrange
                  : Colors.grey[400],
            ),
            tooltip: 'Gửi',
          ),
        ],
      ),
    );
  }
}
