import 'package:flutter/material.dart';
// import 'constants.dart'; // Bỏ nếu không dùng

class NavbarForgotPassword extends StatelessWidget implements PreferredSizeWidget { // Implement PreferredSizeWidget
  const NavbarForgotPassword({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Không cần screenWidth hay isTablet ở đây nữa
    return AppBar( // Sử dụng AppBar làm widget gốc
      backgroundColor: const Color.fromARGB(255, 255, 76, 76), // Màu nền trắng
      elevation: 1.0, // Bóng mờ nhẹ
      automaticallyImplyLeading: false, // Tắt nút back tự động
      titleSpacing: 0, // Xóa khoảng trống tiêu đề mặc định
      title: Padding( // Padding cho toàn bộ nội dung title
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Căn 2 bên
          children: [
            // --- Logo và Tên Shop (nhấn để về home) ---
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => Navigator.pushReplacementNamed(context, '/'), // Dùng pushReplacementNamed nếu về home
                child: Row(
                  children: [
                    Image.asset(
                      '/logoS.jpg', // Đảm bảo đường dẫn đúng
                      height: 40, // Chiều cao logo trong AppBar
                       errorBuilder: (context, error, stackTrace) => Icon(Icons.store, size: 40, color: const Color.fromARGB(255, 255, 255, 255)),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Shopii', // Tên shop
                      style: TextStyle(
                        fontSize: 24, // Cỡ chữ
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 255, 255, 255), // Màu chữ
                      ),
                    ),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  // --- Xác định chiều cao mong muốn cho AppBar ---
  @override
  Size get preferredSize => Size.fromHeight(60.0); // Chiều cao AppBar chuẩn, bạn có thể thay đổi
}
