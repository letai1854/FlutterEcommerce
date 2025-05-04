import 'package:e_commerce_app/widgets/Chat/MessageListItem.dart';
import 'package:flutter/material.dart';

class MessageList extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> chatListFuture; // Nhận Future
  final Function(Map<String, dynamic>) onChatSelected; // Nhận callback
  final String? selectedChatId; // Nhận ID chat đang chọn (để highlight, tùy chọn)

  const MessageList({
    Key? key,
    required this.chatListFuture,
    required this.onChatSelected,
    this.selectedChatId, // ID là tùy chọn
  }) : super(key: key);

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final TextEditingController _searchController = TextEditingController(); // Controller cho search bar

  // TODO: Thêm logic lọc danh sách dựa trên _searchController.text nếu cần

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Nền trắng cho danh sách
      appBar: AppBar(
        automaticallyImplyLeading: false, // Không tự thêm nút back
        backgroundColor: Colors.grey[100], // Màu nền nhẹ cho AppBar
        elevation: 0.5, // Bóng mờ nhẹ
        titleSpacing: 0, // Xóa khoảng trống mặc định
        title: Padding( // Thêm padding cho thanh tìm kiếm
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Container(
            height: 40, // Chiều cao thanh tìm kiếm
            decoration: BoxDecoration(
              color: Colors.grey[200], // Màu nền thanh search
              borderRadius: BorderRadius.circular(20), // Bo tròn
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Tìm kiếm trên Messenger',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20), // Icon search
                contentPadding: EdgeInsets.symmetric(vertical: 10), // Căn dọc text
              ),
              style: TextStyle(fontSize: 14),
              onChanged: (value) {
                // TODO: Gọi setState để lọc danh sách khi text thay đổi
                print('Searching for: $value');
              },
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: widget.chatListFuture, // Sử dụng Future được truyền vào
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải danh sách: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Không có cuộc trò chuyện nào."));
          } else {
            // Lấy danh sách cuộc trò chuyện từ snapshot
            final conversations = snapshot.data!;
            // TODO: Lọc 'conversations' dựa trên _searchController.text nếu cần

            return ListView.separated(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final chatData = conversations[index];
                final bool isSelected = widget.selectedChatId == chatData['id']; // Kiểm tra xem có đang được chọn không
                return MessageListItem( // Sử dụng widget MessageListItem
                  chatData: chatData,
                  isSelected: isSelected, // Truyền trạng thái chọn
                  onTap: () => widget.onChatSelected(chatData), // Gọi callback khi nhấn
                );
              },
              separatorBuilder: (context, index) => Divider( // Thêm đường kẻ phân cách
                height: 1,
                thickness: 1,
                indent: 70, // Thụt lề từ vị trí avatar + padding
                color: Colors.grey[200],
              ),
            );
          }
        },
      ),
    );
  }
}
