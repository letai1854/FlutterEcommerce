// Orders Content widget
import 'package:e_commerce_app/widgets/Order/OrderDetailPage.dart';
import 'package:e_commerce_app/widgets/Order/OrderHistoryPage.dart';
import 'package:e_commerce_app/widgets/Order/OrderItem.dart';
import 'package:e_commerce_app/widgets/Order/OrderStatusTab.dart';
import 'package:flutter/material.dart';

class OrdersContent extends StatefulWidget {
  final int selectedTab;
  final Function(int) onTabChanged;

  const OrdersContent({
    Key? key,
    required this.selectedTab,
    required this.onTabChanged,
  }) : super(key: key);

  @override
  State<OrdersContent> createState() => _OrdersContentState();
}

class _OrdersContentState extends State<OrdersContent> {
  // Keep the shorter status names as requested
  String _getShortStatusName(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return "Chờ xử lý";
      case 1:
        return "Đã xác nhận";
      case 2:
        return "Đang giao";
      case 3:
        return "Đã giao";
      case 4:
        return "Đã hủy";
      default:
        return "Chờ xử lý";
    }
  }

  @override
  Widget build(BuildContext context) {
    // Improve responsive detection with more granular breakpoints
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmallScreen = screenWidth < 360;
    final isSmallScreen = screenWidth < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Đơn hàng của tôi",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () {
                // Navigate to order history page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const OrderHistoryPage()),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text("Lịch sử đơn hàng"),
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Order status tabs - optimized for mobile with better spacing
        Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                // Add padding to prevent tabs from touching screen edges
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min, // Force row to take minimum space
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildResponsiveTab(
                        _getShortStatusName(0), 0, isSmallScreen),
                    _buildResponsiveTab(
                        _getShortStatusName(1), 1, isSmallScreen),
                    _buildResponsiveTab(
                        _getShortStatusName(2), 2, isSmallScreen),
                    _buildResponsiveTab(
                        _getShortStatusName(3), 3, isSmallScreen),
                    _buildResponsiveTab(
                        _getShortStatusName(4), 4, isSmallScreen),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Order list
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 2, // Example with 2 orders
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            // Create dummy items for the order
            final items = [
              {
                "name": "Laptop Asus XYZ",
                "image": "https://via.placeholder.com/80",
                "price": 15000000.0,
                "quantity": 1,
              },
              if (index == 0)
                {
                  "name": "Chuột không dây Logitech",
                  "image": "https://via.placeholder.com/80",
                  "price": 450000.0,
                  "quantity": 2,
                },
            ];

            final orderId = "DH123${456 + index}";
            final orderDate = "01/05/2023";
            final status = _getShortStatusName(
                widget.selectedTab); // Use short status name

            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  // Navigate to the OrderDetailPage when tapped
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailPage(
                        orderId: orderId,
                        orderDate: orderDate,
                        items: items,
                        status: status,
                      ),
                    ),
                  );
                },
                child: OrderItem(
                  orderId: orderId,
                  date: orderDate,
                  items: items,
                  status: status,
                  isClickable: true,
                  onViewHistory: () {},
                  isSmallScreen:
                      isSmallScreen, // Pass screen size info to OrderItem
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Improved responsive tab with optimized spacing
  Widget _buildResponsiveTab(String title, int index, bool isSmallScreen) {
    final isSelected = widget.selectedTab == index;

    return GestureDetector(
      onTap: () {
        widget.onTabChanged(index);
      },
      child: Container(
        // More compact width calculation
        width: isSmallScreen ? (title.length > 9 ? 90 : 75) : null,
        // Reduced horizontal padding
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 12),
        // Small margin between tabs
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.blue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: isSmallScreen ? 12 : 14, // Slightly smaller font
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.visible,
        ),
      ),
    );
  }
}
