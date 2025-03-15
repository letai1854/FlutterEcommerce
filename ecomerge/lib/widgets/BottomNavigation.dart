import 'package:flutter/material.dart';

class BottomNavBar extends StatefulWidget {
  final int initialIndex;

  const BottomNavBar({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; // Tránh cập nhật nếu nhấn cùng icon

    setState(() {
      _selectedIndex = index;
    });

    // Điều hướng trực tiếp bằng pushReplacementNamed
    Navigator.pushReplacementNamed(
      context,
      _getRoute(index),
      arguments: {'selectedIndex': index}, // Truyền trạng thái index khi điều hướng
    );
  }

  // Hàm lấy đường dẫn tương ứng với index
  String _getRoute(int index) {
    switch (index) {
      case 0:
        return '/home';
      case 1:
        return '/cart';
      case 2:
        return '/product_detail';
      case 3:
        return '/forgot_password';
      default:
        return '/home'; // Mặc định là trang chủ
    }
  }

  @override
  Widget build(BuildContext context) {
    // Đọc arguments trong build method (nếu cần)
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('selectedIndex')) {
      // Cập nhật _selectedIndex nếu có giá trị mới từ route trước
      _selectedIndex = args['selectedIndex'];
    }

    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.red, // ✅ Màu chữ & icon khi được chọn
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      items: [
        _buildNavItem(Icons.home, 'Trang chủ', 0),
        _buildNavItem(Icons.category_rounded, 'Sản phẩm', 1),
        _buildNavItem(Icons.smart_toy, 'AI Chat', 2),
        _buildNavItem(Icons.person, 'Tôi', 3),
      ],
    );
  }

  // Hàm tạo BottomNavigationBarItem với màu sắc phù hợp
  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: Icon(icon, color: _selectedIndex == index ? Colors.red : Colors.grey),
      label: label,
    );
  }
}
