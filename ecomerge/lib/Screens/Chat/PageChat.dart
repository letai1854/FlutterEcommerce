import 'package:e_commerce_app/Models/ChatMessage.dart';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/database/models/user_model.dart';
import 'package:e_commerce_app/widgets/Chat/chat_content.dart';
import 'package:e_commerce_app/widgets/Chat/message_list.dart';
import 'package:e_commerce_app/widgets/navbarAdmin.dart'; // Giả sử Navbar này phù hợp
import 'package:flutter/material.dart';

class Pagechat extends StatefulWidget {
  const Pagechat({super.key});

  @override
  State<Pagechat> createState() => _PagechatState();
}

class _PagechatState extends State<Pagechat> {
  // --- Dữ liệu danh sách các cuộc trò chuyện (ví dụ) ---
  // Trong ứng dụng thực tế, bạn sẽ tải dữ liệu này từ API hoặc cơ sở dữ liệu
  final List<Map<String, dynamic>> _chatConversations = [
    {
      'id': 'chat1', // Thêm ID để xác định cuộc trò chuyện
      'name': 'Dory Family',
      'message': 'Tân: import java.io.*; import java.... 2 giờ',
      'avatar': 'assets/logoS.jpg',
      'isOnline': true,
    },
    {
      'id': 'chat2',
      'name': 'GAME 2D/3D JOBS',
      'message': 'Anh: Em nhắn roi ạ - 2 giờ',
      'avatar': 'assets/logoS.jpg',
      'isOnline': false,
    },
    {
      'id': 'chat3',
      'name': 'Da banh ko???',
      'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
      'avatar': 'assets/logoS.jpg',
      'isOnline': true,
    },
    // ... thêm các cuộc trò chuyện khác
  ];

  // --- Dữ liệu tin nhắn cho cuộc trò chuyện ĐANG ĐƯỢC CHỌN (ví dụ) ---
  // Trong ứng dụng thực tế, bạn sẽ tải danh sách này dựa trên _selectedChatConversation
  final List<ChatMessage> _currentChatMessages = [
    ChatMessage(text: 'Hello!', isMe: true, timestamp: DateTime.now().subtract(const Duration(minutes: 5))),
    ChatMessage(text: 'Hi there!', isMe: false, timestamp: DateTime.now().subtract(const Duration(minutes: 4))),
    ChatMessage(text: 'How are you?', isMe: true, timestamp: DateTime.now().subtract(const Duration(minutes: 3))),
    ChatMessage(text: 'I\'m good, how about you?', isMe: false, timestamp: DateTime.now().subtract(const Duration(minutes: 2))),
    ChatMessage(text: 'Doing great!', isMe: true, timestamp: DateTime.now().subtract(const Duration(minutes: 1))),
    // ... thêm tin nhắn khác
  ];

  // --- State cho cuộc trò chuyện đang được chọn ---
  Map<String, dynamic>? _selectedChatConversation;

  // --- Controllers ---
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // Scroll cho nội dung chat

  // --- Hàm tải danh sách cuộc trò chuyện (ví dụ Future) ---
  Future<List<Map<String, dynamic>>> _loadConversations() async {
    // Giả lập việc tải dữ liệu
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: Thay thế bằng logic tải dữ liệu thật
    return _chatConversations;
  }

  // --- Hàm xử lý khi một cuộc trò chuyện được chọn từ MessageList ---
  void _handleChatSelected(Map<String, dynamic> conversationData) {
    setState(() {
      _selectedChatConversation = conversationData;
      // TODO: Tải _currentChatMessages tương ứng với conversationData['id']
      // Ví dụ đơn giản: Clear text input khi chuyển chat
      _textController.clear();
      // Reset scroll position (tùy chọn)
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
    print("Selected chat: ${conversationData['name']}");
  }

  // --- Hàm xử lý gửi tin nhắn (từ ChatContent) ---
  void _handleSubmitted(String text) {
    if (text.trim().isNotEmpty && _selectedChatConversation != null) {
      final newMessage = ChatMessage(
        text: text.trim(),
        isMe: true, // Giả sử người dùng hiện tại gửi
        timestamp: DateTime.now(),
        // TODO: Thêm senderId, receiverId hoặc chatId nếu cần
      );
      setState(() {
        _currentChatMessages.add(newMessage); // Thêm vào danh sách hiện tại
        _textController.clear(); // Xóa input

        // TODO: Gửi tin nhắn lên server/cơ sở dữ liệu ở đây

        // Cuộn xuống dưới cùng sau khi gửi
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Xác định vai trò người dùng (ví dụ)
    // Bạn nên lấy thông tin này từ Provider hoặc service xác thực
    final userProvider = UserInfo(); // Giả sử bạn có thể truy cập trực tiếp
    // final bool isAdmin = userProvider.currentUser?.role == UserRole.admin;
    final bool isAdmin = userProvider.currentUser?.role.toString() == UserRole.quan_tri.name;

    // Hoặc final bool isAdmin = Provider.of<UserProvider>(context).currentUser?.role == UserRole.admin;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        // --- Logic Responsive Layout ---
        if (screenWidth < 768) { // Mobile Layout
          return Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(80), // Chiều cao Navbar
              child: const NavbarAdmin(), // Hoặc NavbarMobile nếu cần
            ),
            // Trên mobile: Admin thấy danh sách, User thường thấy nội dung chat (giả định)
            body: isAdmin? MessageList(
                    // Truyền Future và callback vào MessageList
                    chatListFuture: _loadConversations(),
                    onChatSelected: _handleChatSelected,
                    // Truyền selectedChatId để highlight (tùy chọn)
                    selectedChatId: _selectedChatConversation?['id'],
                  )
                : (_selectedChatConversation != null // Chỉ hiển thị nếu có chat được chọn (quan trọng cho user thường)
                   ? ChatContent(
                      // Truyền dữ liệu và controllers vào ChatContent
                      messages: _currentChatMessages,
                      textController: _textController,
                      scrollController: _scrollController,
                      onMessageSubmitted: _handleSubmitted,
                      chatPartnerData: _selectedChatConversation!, // Phải có dữ liệu ở đây
                    )
                   : Center(child: Text("Chọn một cuộc trò chuyện")) // Hoặc màn hình chào mừng
                  ),
          );
        } else { // Tablet & Desktop Layout
          return Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(80), // Chiều cao Navbar
              child: const NavbarAdmin(), // Hoặc NavbarTablet/Desktop nếu cần
            ),
            body: Row(
              children: [
                // --- Panel danh sách chat (luôn hiển thị hoặc chỉ cho admin) ---
                // Sử dụng Flexible hoặc Expanded với flex hợp lý
                 if (isAdmin || screenWidth >= 1100) // Luôn hiện trên desktop hoặc nếu là admin
                    Expanded(
                       // Điều chỉnh flex dựa trên kích thước màn hình
                      flex: screenWidth < 1100 ? 3 : 2, // Tablet flex 3, Desktop flex 2
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(right: BorderSide(width: 1, color: Colors.grey.shade300))
                        ),
                        child: MessageList(
                          chatListFuture: _loadConversations(),
                          onChatSelected: _handleChatSelected,
                          selectedChatId: _selectedChatConversation?['id'],
                        ),
                      ),
                    ),
                // --- Panel nội dung chat ---
                Expanded(
                  // Điều chỉnh flex
                  flex: screenWidth < 1100 ? 5 : 5, // Tablet flex 5, Desktop flex 5
                  child: _selectedChatConversation != null
                      ? ChatContent(
                          messages: _currentChatMessages,
                          textController: _textController,
                          scrollController: _scrollController,
                          onMessageSubmitted: _handleSubmitted,
                          chatPartnerData: _selectedChatConversation!,
                        )
                      : Center( // Hiển thị khi chưa chọn chat
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text(
                                isAdmin ? "Chọn một cuộc trò chuyện để bắt đầu" : "Bạn chưa có cuộc trò chuyện nào",
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
