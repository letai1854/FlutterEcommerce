import 'dart:async';
import 'package:e_commerce_app/models/chat/last_message_info.dart'; // Standardized to lowercase 'models'
import 'package:e_commerce_app/database/PageResponse.dart';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/database/models/user_model.dart';
import 'package:e_commerce_app/models/chat/conversation_dto.dart';
import 'package:e_commerce_app/models/chat/create_conversation_request_dto.dart';
import 'package:e_commerce_app/models/chat/join_notification.dart';
import 'package:e_commerce_app/models/chat/message_dto.dart';
import 'package:e_commerce_app/models/chat/send_message_request_dto.dart';
import 'package:e_commerce_app/services/chat_service.dart';
import 'package:e_commerce_app/widgets/Chat/chat_content.dart';
import 'package:e_commerce_app/widgets/Chat/message_list.dart';
import 'package:e_commerce_app/widgets/navbarAdmin.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:e_commerce_app/models/chat/chat_message_ui.dart';
import 'package:e_commerce_app/models/chat/conversation_dto_extensions.dart'; // This import should now be recognized as used

class Pagechat extends StatefulWidget {
  const Pagechat({super.key});

  @override
  State<Pagechat> createState() => _PagechatState();
}

class _PagechatState extends State<Pagechat> {
  final ChatService _chatService = ChatService();
  final UserInfo _userInfo = UserInfo();
  final ImagePicker _imagePicker = ImagePicker();

  int? _currentUserId;
  bool _isAdmin = false;

  List<ConversationDTO> _adminConversations = [];
  ConversationDTO? _userConversationWithAdmin;
  ConversationDTO? _selectedConversation;

  Map<int, List<MessageDTO>> _messagesMap = {}; // conversationId -> messages
  Map<int, PageResponse<MessageDTO>> _messagesPageMap = {};
  Map<int, bool> _isLoadingMoreMessagesMap = {};
  Map<int, ScrollController> _messageScrollControllersMap = {};

  bool _isLoadingConversations = true;
  bool _isLoadingInitialMessages = false;
  String? _errorLoadingData;

  bool _stompClientConnected = false;
  Map<int, StompUnsubscribe?> _conversationSubscriptions = {};
  StompUnsubscribe? _errorSubscription;
  StompUnsubscribe? _newAdminConversationSubscription; // Added for the new subscription

  final TextEditingController _textController = TextEditingController();
  final ScrollController _adminConversationListScrollController = ScrollController();
  PageResponse<ConversationDTO>? _adminConversationsPage;
  bool _isLoadingMoreAdminConversations = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = _userInfo.currentUser?.id;
    _isAdmin = _userInfo.currentUser?.role.toString() == UserRole.quan_tri.name;

    _connectAndLoadInitialData();

    if (_isAdmin) {
      _adminConversationListScrollController.addListener(_onAdminConversationScroll);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _adminConversationListScrollController.removeListener(_onAdminConversationScroll);
    _adminConversationListScrollController.dispose();
    _messageScrollControllersMap.values.forEach((controller) => controller.dispose());

    _errorSubscription?.call();
    _newAdminConversationSubscription?.call(); // Unsubscribe here
    _conversationSubscriptions.values.forEach((unsubscribe) => unsubscribe?.call());
    _chatService.disconnectWebSocket();
    _chatService.dispose();
    super.dispose();
  }

  void _onAdminConversationScroll() {
    if (_adminConversationListScrollController.position.pixels ==
            _adminConversationListScrollController.position.maxScrollExtent &&
        !_isLoadingMoreAdminConversations &&
        _adminConversationsPage?.last == false) {
      _fetchAdminConversations(page: (_adminConversationsPage?.number ?? 0) + 1);
    }
  }

  Future<void> _connectAndLoadInitialData() async {
    if (_currentUserId == null) {
      setState(() {
        _isLoadingConversations = false;
        _errorLoadingData = "User not logged in.";
      });
      return;
    }
    _chatService.connectWebSocket(
      onConnect: (StompFrame frame) {
        if (!mounted) return;
        setState(() {
          _stompClientConnected = true;
        });
        _errorSubscription = _chatService.subscribeToErrors(_handleErrorNotification);

        if (_isAdmin) {
          _fetchAdminConversations();
          // Subscribe to new admin conversations
          _newAdminConversationSubscription = _chatService.subscribeToNewAdminConversations(
            _onNewAdminConversationReceived,
            (error) => print("Error subscribing to new admin conversations: $error"),
          );
        } else {
          _fetchOrCreateUserConversationWithAdmin();
        }
      },
      onError: (dynamic error) {
        if (!mounted) return;
        setState(() {
          _isLoadingConversations = false;
          _errorLoadingData = "WebSocket connection error: $error";
        });
      },
      onWebSocketError: (StompFrame frame) {
        if (!mounted) return;
        setState(() {
          _isLoadingConversations = false;
          _errorLoadingData = "WebSocket error: ${frame.body ?? frame.headers}";
        });
      },
    );
  }

  void _handleErrorNotification(dynamic errorBody) {
    print("Error from /topic/errors: $errorBody");
    // Optionally show a snackbar or toast
  }

  void _onNewAdminConversationReceived(ConversationDTO conversation) {
    if (!mounted) return;
    setState(() {
      // Avoid adding duplicates if already fetched
      if (!_adminConversations.any((c) => c.id == conversation.id)) {
        _adminConversations.add(conversation);
        _adminConversations.sort((a, b) => b.updatedDate.compareTo(a.updatedDate));
        
        // Also subscribe to messages for this new conversation
        _subscribeToLiveMessages(conversation.id);
      }
    });
  }

  void _handleSubscriptionError(dynamic error, int conversationId) {
    print("Error subscribing to conversation $conversationId: $error");
  }

  Future<void> _fetchAdminConversations({int page = 0}) async {
    if (!mounted) return;
    setState(() {
      if (page == 0) _isLoadingConversations = true;
      else _isLoadingMoreAdminConversations = true;
      _errorLoadingData = null;
    });

    try {
      final result = await _chatService.getAdminConversations(page: page, size: 15);
      if (!mounted) return;
      setState(() {
        _adminConversationsPage = result;
        if (page == 0) {
          _adminConversations = result.content;
        } else {
          _adminConversations.addAll(result.content);
        }
        _adminConversations.sort((a, b) => b.updatedDate.compareTo(a.updatedDate));

        if (_stompClientConnected) {
          for (var convo in result.content) {
            _subscribeToLiveMessages(convo.id);
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorLoadingData = "Failed to load admin conversations: $e";
      });
    } finally {
      if (!mounted) return;
      setState(() {
        if (page == 0) _isLoadingConversations = false;
        else _isLoadingMoreAdminConversations = false;
      });
    }
  }

  Future<void> _fetchOrCreateUserConversationWithAdmin() async {
    if (!mounted) return;
    setState(() {
      _isLoadingConversations = true;
      _errorLoadingData = null;
    });
    try {
      // Updated to call getMyConversations without parameters and use the direct result
      _userConversationWithAdmin = await _chatService.getMyConversations();

      if (_userConversationWithAdmin == null) {
        final newConvoRequest = CreateConversationRequestDTO(
          title: "Chat with Support",
        );
        _userConversationWithAdmin = await _chatService.startConversation(newConvoRequest);
      }

      if (_userConversationWithAdmin != null) {
        _selectedConversation = _userConversationWithAdmin;
        if (!mounted) return;
        setState(() {});
        await _fetchMessagesForConversation(_userConversationWithAdmin!.id);
        if (_stompClientConnected) {
          _subscribeToLiveMessages(_userConversationWithAdmin!.id);
        }
      } else {
        if (!mounted) return;
        setState(() {
          _errorLoadingData = "Could not establish a conversation with admin.";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorLoadingData = "Failed to load user conversation: $e";
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingConversations = false;
      });
    }
  }

  Future<void> _fetchMessagesForConversation(int conversationId, {int page = 0}) async {
    if (!mounted) return;
    final isLoadingInitial = page == 0 && (_messagesMap[conversationId]?.isEmpty ?? true);

    setState(() {
      if (isLoadingInitial) _isLoadingInitialMessages = true;
      _isLoadingMoreMessagesMap[conversationId] = page != 0;
      _errorLoadingData = null;
    });

    try {
      final result = await _chatService.getMessagesForConversation(conversationId, page: page, size: 20);
      if (!mounted) return;

      setState(() {
        _messagesPageMap[conversationId] = result;
        final currentMessages = _messagesMap[conversationId] ?? [];
        if (page == 0) {
          _messagesMap[conversationId] = result.content.reversed.toList();
        } else {
          currentMessages.insertAll(0, result.content.reversed.toList());
          _messagesMap[conversationId] = currentMessages;
        }

        if (!_messageScrollControllersMap.containsKey(conversationId)) {
          _messageScrollControllersMap[conversationId] = ScrollController();
          _messageScrollControllersMap[conversationId]!.addListener(() => _onMessageScroll(conversationId));
        }
        if (page == 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_messageScrollControllersMap[conversationId]?.hasClients ?? false) {
              _messageScrollControllersMap[conversationId]!.jumpTo(
                _messageScrollControllersMap[conversationId]!.position.maxScrollExtent,
              );
            }
          });
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorLoadingData = "Failed to load messages: $e";
      });
    } finally {
      if (!mounted) return;
      setState(() {
        if (isLoadingInitial) _isLoadingInitialMessages = false;
        _isLoadingMoreMessagesMap[conversationId] = false;
      });
    }
  }

  void _onMessageScroll(int conversationId) {
    final controller = _messageScrollControllersMap[conversationId];
    if (controller == null) return;

    if (controller.position.pixels == controller.position.minScrollExtent &&
        !(_isLoadingMoreMessagesMap[conversationId] ?? false) &&
        _messagesPageMap[conversationId]?.first == false) {
      _fetchMessagesForConversation(conversationId, page: (_messagesPageMap[conversationId]?.number ?? 0) + 1);
    }
  }

  void _subscribeToLiveMessages(int conversationId) {
    if (!_stompClientConnected || _conversationSubscriptions.containsKey(conversationId)) {
      return;
    }
    final unsubscribe = _chatService.subscribeToConversation(
      conversationId,
      (MessageDTO message) => _onMessageReceived(message, conversationId),
      (dynamic joinNotification) => _onJoinNotificationReceived(joinNotification, conversationId),
      (dynamic error) => _handleSubscriptionError(error, conversationId),
    );
    _conversationSubscriptions[conversationId] = unsubscribe;
    _chatService.joinConversation(conversationId);
  }

  void _onMessageReceived(MessageDTO message, int conversationId) {
    if (!mounted) return;

    // Determine if we should trigger a background fetch for history.
    // This should happen if:
    // 1. The user is an admin.
    // 2. The conversation is not currently selected.
    // 3. The message history for this conversation (page 0) has not been loaded yet (_messagesPageMap[conversationId] == null).
    // 4. No other load operation is currently in progress for this conversation's messages.
    bool shouldBackgroundFetchHistory = _isAdmin &&
                                    _selectedConversation?.id != conversationId &&
                                    _messagesPageMap[conversationId] == null &&
                                    !(_isLoadingMoreMessagesMap[conversationId] ?? false) &&
                                    !(_isLoadingInitialMessages && _selectedConversation?.id == conversationId);

    setState(() {
      final messageList = _messagesMap[conversationId] ?? [];
      bool isNewMessage = !messageList.any((m) => m.id == message.id);

      if (isNewMessage) {
        messageList.add(message);
        _messagesMap[conversationId] = messageList;
      }
      // Always sort, as the new message needs to be in the correct chronological order.
      _messagesMap[conversationId]?.sort((a, b) => a.sendTime.compareTo(b.sendTime));

      // Update conversation metadata (last message, unread count)
      if (_isAdmin) {
        final convoIndex = _adminConversations.indexWhere((c) => c.id == conversationId);
        if (convoIndex != -1) {
          int currentUnreadCount = _adminConversations[convoIndex].unreadCount;
          int newUnreadCount = currentUnreadCount;

          if (_selectedConversation?.id == conversationId) {
            // If current user (admin) is viewing this conversation, set unread count to 0.
            newUnreadCount = 0;
          } else {
            // Conversation is not selected.
            // If message is from another user, increment unread count.
            if (message.senderId.toString() != _currentUserId.toString()) {
              newUnreadCount = currentUnreadCount + 1;
            }
            // If message is from current user (admin) to an unselected chat, unread count remains `currentUnreadCount`.
          }

          _adminConversations[convoIndex] = _adminConversations[convoIndex].copyWith(
            lastMessage: LastMessageInfo(
              id: message.id,
              senderFullName: message.senderFullName,
              content: message.content ?? (message.imageUrl != null ? "[Image]" : null),
              sendTime: message.sendTime,
            ),
            updatedDate: message.sendTime,
            unreadCount: newUnreadCount,
          );
          _adminConversations.sort((a, b) => b.updatedDate.compareTo(a.updatedDate));
        }
      } else if (_userConversationWithAdmin?.id == conversationId) {
        // Logic for user's conversation with admin
        _userConversationWithAdmin = _userConversationWithAdmin?.copyWith(
          lastMessage: LastMessageInfo(
            id: message.id,
            senderFullName: message.senderFullName,
            content: message.content ?? (message.imageUrl != null ? "[Image]" : null),
            sendTime: message.sendTime,
          ),
          updatedDate: message.sendTime,
          // For user, if they receive a message (not from self), increment unread.
          unreadCount: (message.senderId.toString() != _currentUserId.toString())
              ? (_userConversationWithAdmin!.unreadCount) + 1
              : _userConversationWithAdmin!.unreadCount, // Don't increment if I sent it
        );
      }

      // Scroll to bottom if the message is for the currently selected conversation and was newly added.
      if (isNewMessage && _selectedConversation?.id == conversationId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_messageScrollControllersMap[conversationId]?.hasClients ?? false) {
            _messageScrollControllersMap[conversationId]!.animateTo(
              _messageScrollControllersMap[conversationId]!.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    if (shouldBackgroundFetchHistory) {
      print("Initiating background fetch for initial messages of unselected admin conversation $conversationId.");
      _fetchMessagesForConversation(conversationId, page: 0)
        .then((_) {
          if (!mounted) return;
          print("Background fetch for conversation $conversationId completed.");
          // The _fetchMessagesForConversation method itself calls setState to update the UI.
          // The new message (that triggered this) should now be part of the fully loaded history
          // if it was persisted and fetched correctly. The list is sorted within _fetchMessagesForConversation
          // and also in the setState block above.
        })
        .catchError((e) {
          if (!mounted) return;
          print("Error during background fetch for conversation $conversationId: $e");
          // Even if fetch fails, the new message was added to the list in the setState above.
        });
    }
  }

  void _onJoinNotificationReceived(dynamic notificationData, int conversationId) {
    if (notificationData is JoinNotification) {
      print('User ${notificationData.user} joined conversation $conversationId at ${notificationData.timestamp}');
    } else {
      print('Join notification for $conversationId: $notificationData');
    }
  }

  void _handleAdminChatSelected(ConversationDTO conversation) {
    if (!mounted) return;
    setState(() {
      _selectedConversation = conversation;
      _textController.clear();
      if (_selectedConversation!.unreadCount > 0) {
        final convoIndex = _adminConversations.indexWhere((c) => c.id == conversation.id);
        if (convoIndex != -1) {
          // Ensure this 'copyWith' is recognized from the extension
          _adminConversations[convoIndex] = _adminConversations[convoIndex].copyWith(unreadCount: 0);
        }
      }

      if (_messagesMap[conversation.id] == null || _messagesMap[conversation.id]!.isEmpty) {
        _fetchMessagesForConversation(conversation.id);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_messageScrollControllersMap[conversation.id]?.hasClients ?? false) {
            _messageScrollControllersMap[conversation.id]!.jumpTo(
              _messageScrollControllersMap[conversation.id]!.position.maxScrollExtent,
            );
          }
        });
      }
    });
  }

  Future<void> _sendMessage({String? text, String? imageUrl}) async {
    final content = text?.trim();
    if ((content == null || content.isEmpty) && (imageUrl == null || imageUrl.isEmpty)) {
      return;
    }

    final targetConversationId = _selectedConversation?.id;
    if (targetConversationId == null) return;

    final request = SendMessageRequestDTO(
      conversationId: targetConversationId,
      content: content,
      imageUrl: imageUrl,
    );

    _chatService.sendMessageWebSocket(targetConversationId, request);
    _textController.clear();
  }

  Future<void> _pickAndSendImage() async {
    final XFile? pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uploading image...")));

    try {
      final imageBytes = await pickedFile.readAsBytes();
      final fileName = pickedFile.name;
      final imageUrl = await _chatService.uploadImage(imageBytes, fileName);

      if (imageUrl != null) {
        await _sendMessage(imageUrl: imageUrl);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Image sent!")));
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to upload image.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error sending image: $e")));
    }
  }

  Widget _buildChatContent() {
    if (_selectedConversation == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _isAdmin ? "Select a conversation to start" : "Loading your chat...",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    if (_isLoadingInitialMessages && (_messagesMap[_selectedConversation!.id]?.isEmpty ?? true)) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<MessageDTO> messageDTOs = _messagesMap[_selectedConversation!.id] ?? <MessageDTO>[];
    final List<ChatMessageUI> uiMessages = messageDTOs
        .map((dto) => messageDtoToChatMessageUI(dto, _chatService))
        .toList();

    final String chatPartnerName = _isAdmin 
        ? _selectedConversation!.customerName 
        : _selectedConversation!.title;
    
    // chatPartnerAvatarUrl will now be a Future<String?>
    Future<String?> chatPartnerAvatarUrlFuture;
    if (_selectedConversation != null) {
      int partnerId;
      if (_isAdmin) {
        // Admin is chatting with a customer
        partnerId = _selectedConversation!.customerId;
      } else {
        // Customer is chatting with an admin
        // Assuming adminId is always present for user-to-admin chats.
        // If adminId can be null, add a fallback.
        partnerId = _selectedConversation!.adminId ?? 0; // Use a default/invalid ID if null
      }
      if (partnerId != 0) { // Check if partnerId is valid before fetching
        chatPartnerAvatarUrlFuture = _chatService.getFullUserAvatarUrl(partnerId);
      } else {
        // Fallback if partnerId is not available (e.g. system message or unassigned admin)
        chatPartnerAvatarUrlFuture = Future.value(null); // Or Future.value('assets/default_avatar.png') if ChatContent handles local asset strings
      }
    } else {
      chatPartnerAvatarUrlFuture = Future.value(null); // Should not happen if _selectedConversation is not null
    }

    return ChatContent(
      messages: uiMessages,
      textController: _textController,
      scrollController: _messageScrollControllersMap[_selectedConversation!.id] ?? ScrollController(),
      onMessageSubmitted: (text) => _sendMessage(text: text),
      chatPartnerData: {
        'name': chatPartnerName, 
        'avatar': chatPartnerAvatarUrlFuture, // Pass the Future<String?>
        'isOnline': false, // Placeholder for online status
      },
      currentUserId: _currentUserId!,
      chatService: _chatService,
      onImagePickerRequested: _pickAndSendImage,
      isLoadingMoreMessages: _isLoadingMoreMessagesMap[_selectedConversation!.id] ?? false,
      onAppBarBackButtonPressed: _isAdmin && MediaQuery.of(context).size.width < 768
          ? () {
              setState(() {
                _selectedConversation = null;
              });
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null || _errorLoadingData != null && !_isLoadingConversations && !_isLoadingInitialMessages) {
      return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: const NavbarAdmin(),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorLoadingData ?? "User not authenticated or error loading data."),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                },
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoadingConversations && !_isAdmin) {
      return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: const NavbarAdmin(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final bool isMobile = screenWidth < 768;

        if (isMobile) {
          return Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: const NavbarAdmin(),
            ),
            body: _isAdmin
                ? (_selectedConversation == null
                    ? (_isLoadingConversations
                        ? const Center(child: CircularProgressIndicator()) // Add loading indicator here
                        : MessageList(
                            conversations: _adminConversations,
                            onChatSelected: _handleAdminChatSelected,
                            selectedChatId: _selectedConversation?.id,
                            scrollController: _adminConversationListScrollController,
                            isLoadingMore: _isLoadingMoreAdminConversations,
                            chatService: _chatService,
                          ))
                    : _buildChatContent())
                : _buildChatContent(),
          );
        } else {
          return Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: const NavbarAdmin(),
            ),
            body: Row(
              children: [
                if (_isAdmin)
                  Expanded(
                    flex: screenWidth < 1100 ? 3 : 2,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(right: BorderSide(width: 1, color: Colors.grey.shade300)),
                      ),
                      child: _isLoadingConversations
                          ? const Center(child: CircularProgressIndicator()) // Add loading indicator here
                          : MessageList(
                              conversations: _adminConversations,
                              onChatSelected: _handleAdminChatSelected,
                              selectedChatId: _selectedConversation?.id,
                              scrollController: _adminConversationListScrollController,
                              isLoadingMore: _isLoadingMoreAdminConversations,
                              chatService: _chatService, // Pass ChatService instance
                            ),
                    ),
                  ),
                Expanded(
                  flex: _isAdmin ? (screenWidth < 1100 ? 5 : 5) : 1,
                  child: _buildChatContent(),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
