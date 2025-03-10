import 'package:e_commerce_app/Models/ChatMessage.dart';
import 'package:e_commerce_app/widgets/ChatBubble.dart';
import 'package:flutter/material.dart';

class ChatContent extends StatefulWidget {
  const ChatContent({Key? key}) : super(key: key);

  @override
  State<ChatContent> createState() => _ChatContentState();
}

class _ChatContentState extends State<ChatContent> {
  // List to store chat messages
  final List<ChatMessage> _messages = [
    ChatMessage(
        text: 'Hello!',
        isMe: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5))),
    ChatMessage(
        text: 'Hi there!',
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 4))),
    ChatMessage(
        text: 'How are you?',
        isMe: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 3))),
    ChatMessage(
        text: 'I\'m good, how about you?',
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2))),
    ChatMessage(
        text: 'Doing great!',
        isMe: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 1))),
    ChatMessage(
        text: 'Awesome!',
        isMe: false,
        timestamp: DateTime.now()),
    ChatMessage(
        text:
            'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.',
        isMe: false,
        timestamp: DateTime.now()),
    ChatMessage(
        text: 'dfkasjdf', isMe: false, timestamp: DateTime.now()),
    ChatMessage(
        text: 'dfjaskjdfk', isMe: true, timestamp: DateTime.now()),
    ChatMessage(
        text: 'ljdkfaskldfjklks', isMe: false, timestamp: DateTime.now()),
    ChatMessage(
        text: 'akjdfkasjf;ldf', isMe: true, timestamp: DateTime.now()),
    ChatMessage(
        text: 'jalkdfjs;ljfasdf', isMe: false, timestamp: DateTime.now()),
  ];

  // Controller for the text input field
  final TextEditingController _textController = TextEditingController();

  // ScrollController for ListView
  final ScrollController _scrollController = ScrollController();

  // Function to handle sending messages
  void _handleSubmitted(String text) {
    if (text.isNotEmpty) {
      setState(() {
        _messages.add(ChatMessage(
          text: text,
          isMe: true, // Assume the user is sending the message
          timestamp: DateTime.now(),
        ));
        _textController.clear(); // Clear the input field

        // Scroll to the bottom after a new message is added
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title:  Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage('assets/logoS.jpg'),
              radius: 20,
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dory Family',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            Spacer(),
            IconButton(onPressed: () {}, icon: Icon(Icons.call)),
          ],
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController, // Assign the ScrollController
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ChatBubble(message: message);
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
      padding: const EdgeInsets.all(8.0),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey)),
      ),
      child: Row(
        children: [
          IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.add,
                color: Colors.red,
              )),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(25)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: TextField(
                  controller: _textController, // Associate the controller
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Aa',
                  ),
                  onSubmitted:
                      _handleSubmitted, // Call when the user presses Enter
                ),
              ),
            ),
          ),
          IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.camera_alt,
                color: Colors.red,
              )),
          IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.mic,
                color: Colors.red,
              )),
          IconButton(
              onPressed: () => _handleSubmitted(_textController.text),
              icon: const Icon(
                Icons.send,
                color: Colors.red,
              )),
        ],
      ),
    );
  }
}
