import 'package:flutter/material.dart';
import 'package:e_commerce_app/services/api_service.dart'; // Import the GeminiChatService

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text, 
    required this.isUser,
    DateTime? timestamp,
  }) : this.timestamp = timestamp ?? DateTime.now();
}

class Pagechatbotai extends StatefulWidget {
  final bool isPopup;
  
  const Pagechatbotai({
    Key? key, 
    this.isPopup = false,
  }) : super(key: key);

  @override
  State<Pagechatbotai> createState() => _PagechatbotaiState();
  
  // Static method to show the chatbot as a popup
  static Future<void> showAsPopup(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.8,
          constraints: BoxConstraints(
            maxWidth: 600,  // Maximum width for larger screens
            maxHeight: 800, // Maximum height for larger screens
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Pagechatbotai(isPopup: true),
        ),
      ),
    );
  }
}

class _PagechatbotaiState extends State<Pagechatbotai> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  
  late final GeminiChatService _chatService;

  @override
  void initState() {
    super.initState();
    _chatService = GeminiChatService(); // Initialize the chat service
    
    // Add welcome message
    _addBotMessage("Xin chào! Tôi là trợ lý AI của E-Commerce. Tôi có thể giúp gì cho bạn?");
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    
    final userMessageText = text.trim();
    _textController.clear();
    
    setState(() {
      _messages.add(ChatMessage(
        text: userMessageText,
        isUser: true,
      ));
      _isTyping = true;
    });
    
    _scrollToBottom();
    
    // Get AI response from Gemini
    final aiResponse = await _chatService.sendMessage(userMessageText);
    
    if (aiResponse != null) {
      _addBotMessage(aiResponse);
    } else {
      _addBotMessage("Xin lỗi, tôi không thể xử lý yêu cầu của bạn lúc này.");
    }
  }
  
  void _addBotMessage(String text) {
    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: text,
          isUser: false,
        ));
      });
    }
    _scrollToBottom();
  }
  
  void _scrollToBottom() {
    // Scroll to bottom with animation after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Handle back button presses to prevent black screen
      onWillPop: () async {
        // Check if this is the root route
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          // Navigate to home if we can't pop (this is a root route)
          Navigator.of(context).pushReplacementNamed('/home');
        }
        return false; // Prevent default back button behavior
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.red,
          title: Row(
            children: [
              Icon(Icons.smart_toy, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Trợ lý AI',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              // Check if this is the root route
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                // Navigate to home if we can't pop (this is a root route)
                Navigator.of(context).pushReplacementNamed('/home');
              }
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                setState(() {
                  _messages.clear();
                  _chatService.resetChatSession(); // Reset Gemini chat session
                  _addBotMessage("Xin chào! Tôi là trợ lý AI của E-Commerce. Tôi có thể giúp gì cho bạn?");
                });
              },
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
          ),
          child: Column(
            children: [
              // Chat messages area
              Expanded(
                child: _buildMessageList(),
              ),
              
              // Typing indicator
              if (_isTyping)
                Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('AI đang trả lời...', 
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Input area
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _buildMessageItem(_messages[index]);
      },
    );
  }
  
  Widget _buildMessageItem(ChatMessage message) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) 
            _buildAvatar(isUser),
          
          const SizedBox(width: 8),
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: isUser ? Colors.red[400] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 2,
                    color: Colors.black.withOpacity(0.1),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          if (isUser) 
            _buildAvatar(isUser),
        ],
      ),
    );
  }
  
  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 34,
      height: 34,
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: isUser ? Colors.blue[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(17),
      ),
      child: Center(
        child: Icon(
          isUser ? Icons.person : Icons.smart_toy,
          size: 18,
          color: isUser ? Colors.blue[800] : Colors.red[800],
        ),
      ),
    );
  }
  
  Widget _buildInputArea() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Nhập câu hỏi của bạn...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: _handleSubmitted,
            ),
          ),
          const SizedBox(width: 8.0),
          Container(
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: () => _handleSubmitted(_textController.text),
            ),
          ),
        ],
      ),
    );
  }
}
