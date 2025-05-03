import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  final String currentPage;
  final Function(String) onPageSelected;
  final bool isMobile;

  const AdminSidebar({
    Key? key,
    required this.currentPage,
    required this.onPageSelected,
    required this.isMobile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the device screen width and calculate sidebar width
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = isMobile ? screenWidth * 0.7 : 250.0;

    return Container(
      width: sidebarWidth,
      color: Colors.blueGrey[800],
      child: Column(
        children: [
          const SizedBox(height: 50),
          // Admin logo or title
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            child: const Text(
              'ADMIN DASHBOARD',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 10),

          // Navigation Items
          _buildNavItem(context, 'Dashboard', Icons.dashboard),
          _buildNavItem(context, 'Quản lý sản phẩm', Icons.inventory),
          _buildNavItem(context, 'Quản lý danh mục', Icons.category),
          _buildNavItem(context, 'Quản lý người dùng', Icons.people),
          _buildNavItem(context, 'Quản lý đơn hàng', Icons.shopping_cart),
          _buildNavItem(context, 'Quản lý mã giảm giá', Icons.discount),

          const Spacer(),

          // Logout option at the bottom
        ],
      ),
    );
  }

  // Build individual navigation items
  Widget _buildNavItem(BuildContext context, String title, IconData icon,
      {bool isLogout = false}) {
    final isSelected = title == currentPage;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? Colors.white
              : (isLogout ? Colors.redAccent : Colors.white70),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isLogout ? Colors.redAccent : Colors.white70),
            fontSize: 16,
          ),
        ),
        selected: isSelected,
        selectedColor: Colors.white,
        selectedTileColor: Colors.black26,
        onTap: () {
          if (isLogout) {
            // Handle logout action
          } else {
            onPageSelected(title);
          }
        },
      ),
    );
  }
}
