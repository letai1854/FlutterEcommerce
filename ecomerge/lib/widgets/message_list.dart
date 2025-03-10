import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MessageList extends StatefulWidget {
  const MessageList({Key? key}) : super(key: key);

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final List<Map<String, dynamic>> messages = [
    {
      'name': 'Dory Family',
      'message': 'Tân: import java.io.*; import java.... 2 giờ',
      'avatar': 'assets/logoS.jpg',
      'isOnline': true,
    },
    {
      'name': 'GAME 2D/3D JOBS',
      'message': 'Anh: Em nhắn roi ạ - 2 giờ',
      'avatar': 'assets/logoS.jpg',
      'isOnline': false,
    },
    {
      'name': 'Da banh ko???',
      'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
      'avatar': 'assets/logoS.jpg',
      'isOnline': true,
    },
        {
      'name': 'Da banh ko???',
      'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
      'avatar': 'assets/logoS.jpg',
      'isOnline': true,
    },
        {
      'name': 'Da banh ko???',
      'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
      'avatar': 'assets/logoS.jpg',
      'isOnline': true,
    },
        {
      'name': 'Da banh ko???',
      'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
      'avatar': 'assets/logoS.jpg',
      'isOnline': true,
    },
        {
      'name': 'Da banh ko???',
      'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
      'avatar': 'assets/logoS.jpg',
      'isOnline': true,
    },
        {
      'name': 'Da banh ko???',
      'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
      'avatar': 'assets/logoS.jpg',
      'isOnline': true,
    },
        {
      'name': 'Da banh ko???',
      'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
      'avatar': 'assets/logoS.jpg',
      'isOnline': true,
    },
        {
      'name': 'Da banh ko???',
      'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
      'avatar': 'assets/logoS.jpg',
      'isOnline': true,
    },
        {
      'name': 'Da banh ko???',
      'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
      'avatar': 'assets/logoS.jpg',
      'isOnline': true,
    },
        {
      'name': 'Da banh ko???',
      'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
      'avatar': 'assets/logoS.jpg',
      'isOnline': true,
    },
        {
      'name': 'Da banh ko???',
      'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
      'avatar': 'assets/logoS.jpg',
      'isOnline': true,
    },
        {
      'name': 'Da banh ko???',
      'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
      'avatar': 'assets/logoS.jpg',
      'isOnline': true,
    },
  ];

  Future<List<Map<String, dynamic>>> loadData() async {
    await Future.delayed(const Duration(seconds: 1));
    return messages;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.red,
        elevation: 0,
        title: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: TextField(
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Tìm kiếm trên Messenger',
                icon: Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: loadData(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData && snapshot.data != null) {
            List<Map<String, dynamic>> messages = snapshot.data!;
            return ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) => _buildListItem(messages[index]),
            );
          } else {
            return const Center(child: Text("Không có dữ liệu"));
          }
        },
      ),
    );
  }

  Widget _buildListItem(Map<String, dynamic> message) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: AssetImage(message['avatar']!), // Nếu là URL, dùng CachedNetworkImage
      ),
      title: Text(message['name']!),
      subtitle: Text(message['message']!),
      tileColor: Colors.white,
    );
  }
}
