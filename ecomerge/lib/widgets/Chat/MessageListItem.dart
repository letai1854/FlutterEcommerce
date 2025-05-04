import 'package:flutter/material.dart';

class MessageListItem extends StatelessWidget {
  final Map<String, dynamic> chatData; // Nhận dữ liệu chat
  final VoidCallback onTap;           // Nhận callback khi nhấn
  final bool isSelected;              // Nhận trạng thái được chọn

  const MessageListItem({
    Key? key,
    required this.chatData,
    required this.onTap,
    this.isSelected = false, // Mặc định là không được chọn
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Lấy dữ liệu từ map, có kiểm tra null hoặc giá trị mặc định
    final String avatarUrl = chatData['avatar'] ?? 'assets/default_avatar.png'; // Ảnh mặc định nếu null
    final String name = chatData['name'] ?? 'Unknown User';
    final String lastMessage = chatData['message'] ?? '';
    final bool isOnline = chatData['isOnline'] ?? false;

    return ListTile(
      onTap: onTap, // Gọi callback khi nhấn vào ListTile
      leading: Stack( // Stack để hiển thị trạng thái online
        children: [
          CircleAvatar(
            backgroundImage: AssetImage(avatarUrl), // Sử dụng AssetImage nếu là local asset
            // backgroundImage: NetworkImage(avatarUrl), // Hoặc NetworkImage nếu là URL
            radius: 24, // Kích thước avatar
            backgroundColor: Colors.grey[200], // Màu nền nếu ảnh lỗi
          ),
          if (isOnline) // Chỉ hiển thị chấm xanh nếu isOnline là true
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 14, // Kích thước chấm online
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.greenAccent[400], // Màu xanh lá cây sáng
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2), // Viền trắng
                ),
              ),
            ),
        ],
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: FontWeight.w600, // Đậm hơn một chút
          fontSize: 15,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        lastMessage,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 13,
        ),
        maxLines: 1, // Chỉ hiển thị 1 dòng
        overflow: TextOverflow.ellipsis, // Thêm dấu ... nếu quá dài
      ),
      // trailing: Column( // Ví dụ thêm thời gian và biểu tượng đọc/chưa đọc
      //   mainAxisAlignment: MainAxisAlignment.center,
      //   crossAxisAlignment: CrossAxisAlignment.end,
      //   children: [
      //     Text("10:30", style: TextStyle(fontSize: 11, color: Colors.grey)),
      //     SizedBox(height: 4),
      //     Icon(Icons.done_all, color: Colors.blue, size: 16), // Ví dụ đã đọc
      //   ],
      // ),
      tileColor: isSelected ? Colors.blue.shade50 : Colors.transparent, // Highlight nếu được chọn
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Padding
    );
  }
}
