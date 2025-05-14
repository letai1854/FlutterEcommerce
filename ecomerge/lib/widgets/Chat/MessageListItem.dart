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
    final String? avatarUrl = chatData['avatar']; // Can be null or a URL or an asset path
    final String name = chatData['name'] ?? 'Unknown User';
    final String lastMessage = chatData['message'] ?? '';
    final bool isOnline = chatData['isOnline'] ?? false;

    ImageProvider backgroundImage;
    bool isNetwork = false;

    if (avatarUrl != null && (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://'))) {
      backgroundImage = NetworkImage(avatarUrl);
      isNetwork = true;
    } else {
      backgroundImage = AssetImage(avatarUrl ?? 'assets/default_avatar.png'); // Default local asset
    }

    return ListTile(
      onTap: onTap, // Gọi callback khi nhấn vào ListTile
      leading: Stack( // Stack để hiển thị trạng thái online
        children: [
          CircleAvatar(
            backgroundImage: backgroundImage,
            onBackgroundImageError: isNetwork 
              ? (exception, stackTrace) {
                  // This callback is triggered if NetworkImage fails.
                  // The CircleAvatar will use its backgroundColor.
                  // You can log the error if needed:
                  // print('Error loading network avatar: $exception');
                }
              : null, // No specific error handling for AssetImage, it assumes asset exists
            radius: 24, // Kích thước avatar
            backgroundColor: Colors.grey[200], // Màu nền nếu ảnh lỗi hoặc không có ảnh
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
      tileColor: isSelected ? Colors.blue.shade50 : Colors.transparent, // Highlight nếu được chọn
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Padding
    );
  }
}
