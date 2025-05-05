import 'package:e_commerce_app/Screens/UserInfo/MobileOrdersPage.dart';
import 'package:e_commerce_app/Screens/UserInfo/UserInfoMobile.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/widgets/Order/OrderHistoryPage.dart';

class OrdersSection extends StatefulWidget {
  const OrdersSection({Key? key}) : super(key: key);

  @override
  State<OrdersSection> createState() => _OrdersSectionState();
}

class _OrdersSectionState extends State<OrdersSection> {
  int _selectedOrderTab = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with order history button
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              // Navigate to a page showing only orders with this status
              _navigateToOrdersPage(-1);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_bag, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text(
                      "Đơn mua",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const OrderHistoryPage()),
                    );
                  },
                  child: const Text("Lịch sử đơn hàng"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Order status tabs with scroll view for overflow - CENTERED
          Container(
            height: 85,
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            alignment: Alignment.center, // Center the row content
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // Center the tabs
                children: [
                  _buildOrderStatusButton(
                      0, Icons.pending_actions, "Chờ xử lý"),
                  _buildOrderStatusButton(
                      1, Icons.check_circle_outline, "Đã xác nhận"),
                  _buildOrderStatusButton(2, Icons.local_shipping, "Đang giao"),
                  _buildOrderStatusButton(3, Icons.inventory, "Đã giao"),
                  _buildOrderStatusButton(4, Icons.cancel, "Đã hủy"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Order status tab with icon and text for mobile layout
  Widget _buildOrderStatusButton(int index, IconData icon, String title) {
    final isSelected = _selectedOrderTab == index;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedOrderTab = index;
          });
          // Navigate to a page showing only orders with this status
          _navigateToOrdersPage(index);
        },
        child: Container(
          // Use dynamic width based on text length to ensure no truncation
          width: title.length > 8
              ? 85
              : 75, // Increased from 70 to ensure text fits
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.blue : Colors.grey.shade600,
                  size: 22,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.visible,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Navigate to orders page showing orders with specific status
  void _navigateToOrdersPage(int tabIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MobileOrdersPage(initialTab: tabIndex),
      ),
    );
  }
}
