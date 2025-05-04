import 'package:e_commerce_app/Models/ChatMessage.dart';
import 'package:e_commerce_app/widgets/Chat/ChatBubble.dart';
import 'package:flutter/material.dart';

class ChatContent extends StatefulWidget {
  // Nhận dữ liệu và callbacks từ Pagechat
  final List<ChatMessage> messages;
  final TextEditingController textController;
  final ScrollController scrollController;
  final Function(String) onMessageSubmitted;
  final Map<String, dynamic> chatPartnerData; // Dữ liệu của người đang chat cùng

  const ChatContent({
    Key? key,
    required this.messages,
    required this.textController,
    required this.scrollController,
    required this.onMessageSubmitted,
    required this.chatPartnerData,
  }) : super(key: key);

  @override
  State<ChatContent> createState() => _ChatContentState();
}

class _ChatContentState extends State<ChatContent> {

  @override
  void initState() {
    super.initState();
    // Tự động cuộn xuống dưới cùng khi widget được xây dựng lần đầu hoặc khi có tin nhắn mới (Pagechat đã xử lý cuộn khi gửi)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController.hasClients) {
         widget.scrollController.jumpTo(widget.scrollController.position.maxScrollExtent);
      }
    });
  }

   @override
   void didUpdateWidget(covariant ChatContent oldWidget) {
      super.didUpdateWidget(oldWidget);
      // Nếu danh sách tin nhắn thay đổi (ví dụ: nhận tin nhắn mới) -> cuộn xuống
      // Pagechat đã xử lý việc cuộn khi GỬI tin nhắn, phần này có thể dùng khi NHẬN tin nhắn mới
      if (widget.messages.length != oldWidget.messages.length) {
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

  @override
  Widget build(BuildContext context) {
    // Lấy thông tin người đang chat cùng từ widget.chatPartnerData
    final String partnerName = widget.chatPartnerData['name'] ?? 'Người dùng';
    final String partnerAvatar = widget.chatPartnerData['avatar'] ?? 'assets/default_avatar.png';
    // final bool isPartnerOnline = widget.chatPartnerData['isOnline'] ?? false;

    return Scaffold(
      backgroundColor: Colors.white, // Nền trắng cho nội dung chat
      appBar: AppBar(
        automaticallyImplyLeading: false, // Tắt nút back tự động
        elevation: 0.5, // Bóng mờ nhẹ
        backgroundColor: Colors.grey[50], // Màu nền AppBar nhẹ
        titleSpacing: 0, // Xóa khoảng trống
        title: Row(
          children: [
             // --- Nút Back (tùy chọn, chỉ hiển thị trên mobile nếu cần) ---
             if (MediaQuery.of(context).size.width < 768)
                IconButton(
                   icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700], size: 20),
                   onPressed: () {
                      // TODO: Xử lý quay lại danh sách chat trên mobile
                      // Có thể gọi Navigator.pop(context) hoặc callback về Pagechat
                      print("Back pressed");
                   },
                )
             else SizedBox(width: 10), // Khoảng trống nếu không có nút back
            // --- Avatar và Tên người dùng ---
            CircleAvatar(
              backgroundImage: AssetImage(partnerAvatar), // Hoặc NetworkImage
              radius: 18, // Kích thước nhỏ hơn
              backgroundColor: Colors.grey[300],
            ),
            SizedBox(width: 10),
            Expanded( // Cho phép tên dài có thể xuống dòng (dù thường ko cần)
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    partnerName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                   // Optional: Hiển thị trạng thái online
                  // Text(
                  //   isPartnerOnline ? 'Đang hoạt động' : 'Hoạt động ... phút trước',
                  //   style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  // ),
                ],
              ),
            ),
          ],
        ),
        actions: [ // Nút actions ở cuối AppBar
          IconButton(
            onPressed: () { /* TODO: Handle call */ },
            icon: Icon(Icons.call_outlined, color: Colors.deepOrange),
            tooltip: 'Gọi thoại',
          ),
          IconButton(
            onPressed: () { /* TODO: Handle video call */ },
            icon: Icon(Icons.videocam_outlined, color: Colors.deepOrange),
             tooltip: 'Gọi video',
          ),
          IconButton(
            onPressed: () { /* TODO: Handle more options */ },
            icon: Icon(Icons.info_outline, color: Colors.deepOrange),
             tooltip: 'Thông tin',
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // --- Khu vực hiển thị tin nhắn ---
          Expanded(
            child: widget.messages.isEmpty
              ? Center( // Hiển thị khi chưa có tin nhắn
                  child: Text(
                    'Bắt đầu cuộc trò chuyện!',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                )
              : ListView.builder(
                  controller: widget.scrollController, // Sử dụng controller được truyền vào
                  padding: const EdgeInsets.symmetric(vertical: 8.0), // Padding cho danh sách tin nhắn
                  itemCount: widget.messages.length,
                  itemBuilder: (context, index) {
                    final message = widget.messages[index];
                    return ChatBubble(message: message); // Truyền message vào ChatBubble
                  },
                ),
          ),
          // --- Khu vực nhập tin nhắn ---
          _buildChatInput(),
        ],
      ),
    );
  }

  // --- Widget xây dựng khu vực nhập liệu ---
  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[100], // Nền khu vực input
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end, // Căn các nút xuống dưới nếu input nhiều dòng
        children: [
          // --- Các nút chức năng (Tùy chọn) ---
          IconButton( onPressed: () { /* TODO: Handle attach file */ }, icon: Icon( Icons.add_circle_outline, color: Colors.deepOrange, ), tooltip: 'Đính kèm',),
          IconButton( onPressed: () { /* TODO: Handle sticker */ }, icon: Icon( Icons.sticky_note_2_outlined, color: Colors.deepOrange, ), tooltip: 'Sticker',),
          IconButton( onPressed: () { /* TODO: Handle image */ }, icon: Icon( Icons.image_outlined, color: Colors.deepOrange, ), tooltip: 'Gửi ảnh',),

          // --- Ô nhập text ---
          Expanded(
            child: Container(
              constraints: BoxConstraints(maxHeight: 100), // Giới hạn chiều cao khi nhập nhiều dòng
              child: TextField(
                controller: widget.textController, // Sử dụng controller được truyền vào
                decoration: InputDecoration(
                  hintText: 'Nhắn tin...',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
                  filled: true, // Cho phép đổ màu nền
                  fillColor: Colors.white, // Màu nền ô input
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0), // Padding bên trong
                  border: OutlineInputBorder( // Viền bo tròn
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder( // Viền khi không focus
                     borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder( // Viền khi focus
                     borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide(color: Colors.deepOrange, width: 1),
                  ),
                  isDense: true, // Làm cho ô input nhỏ gọn hơn
                ),
                style: TextStyle(fontSize: 15),
                maxLines: null, // Cho phép nhập nhiều dòng
                textInputAction: TextInputAction.send, // Đổi nút enter thành send (trên mobile)
                onSubmitted: widget.onMessageSubmitted, // Gọi callback khi nhấn Enter/Send
                // onChanged: (value){ // Nếu cần xử lý khi đang gõ (vd: typing indicator)
                //   // ...
                // },
              ),
            ),
          ),
          // --- Nút Gửi ---
          IconButton(
            // Chỉ enable nút gửi khi có text
            onPressed: () => widget.textController.text.trim().isNotEmpty
                ? widget.onMessageSubmitted(widget.textController.text)
                : null,
            icon: Icon( Icons.send,
              color: widget.textController.text.trim().isNotEmpty ? Colors.deepOrange : Colors.grey[400], // Màu nút gửi
            ),
             tooltip: 'Gửi',
          ),
        ],
      ),
    );
  }
}
