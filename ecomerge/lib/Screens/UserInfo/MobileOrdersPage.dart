import 'package:flutter/material.dart';
import 'package:e_commerce_app/widgets/Order/OrderDetailPage.dart';
import 'package:e_commerce_app/widgets/Order/OrderHistoryPage.dart';
import 'package:e_commerce_app/widgets/Order/OrderItem.dart';
import 'package:e_commerce_app/widgets/Order/OrderStatusHistoryPage.dart';
import 'package:e_commerce_app/widgets/Order/OrderStatusTab.dart';

class MobileOrdersPage extends StatefulWidget {
  final int initialTab;

  const MobileOrdersPage({Key? key, required this.initialTab})
      : super(key: key);

  @override
  State<MobileOrdersPage> createState() => _MobileOrdersPageState();
}

class _MobileOrdersPageState extends State<MobileOrdersPage> {
  late int _selectedOrderTab;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _selectedOrderTab = widget.initialTab < 0 ? 0 : widget.initialTab;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Add this method to get the short status names
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
    // Detect very small screens for even more compact display
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmallScreen = screenWidth < 360;

    return Scaffold(
      appBar: AppBar(
        title: _isSearchVisible
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: "Tìm kiếm đơn hàng...",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                autofocus: true,
              )
            : const Text(
                "Đơn hàng của tôi",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
        backgroundColor: Colors.red,
        actions: [
          // Toggle search icon
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          // Chat icon
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row with history button - matches OrdersContent.dart
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Đơn hàng của tôi",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrderHistoryPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history),
                  label: const Text("Lịch sử đơn hàng"),
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Order status tabs - fixed to use shorter names and prevent ellipsis
            Container(
              height: 50,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMobileTab(_getShortStatusName(0), 0),
                      _buildMobileTab(_getShortStatusName(1), 1),
                      _buildMobileTab(_getShortStatusName(2), 2),
                      _buildMobileTab(_getShortStatusName(3), 3),
                      _buildMobileTab(_getShortStatusName(4), 4),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Order list - search or default list
            Expanded(
              child: _searchQuery.isNotEmpty
                  ? _buildSearchResults()
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount:
                          2, // Example with 2 orders like in OrdersContent
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        // Create dummy items for the order - same as OrdersContent.dart
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
                        final status =
                            OrderStatusTab.getStatusText(_selectedOrderTab);

                        return GestureDetector(
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
                            onViewHistory: () {
                              // Navigate to order status history
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrderStatusHistoryPage(
                                    orderId: orderId,
                                    currentStatus: status,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Fix the _buildMobileTab method that was missing
  Widget _buildMobileTab(String title, int index) {
    final isSelected = _selectedOrderTab == index;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 500;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOrderTab = index;
        });
      },
      child: Container(
        // Increased width to fit content
        width: isSmallScreen ? (title.length > 8 ? 110 : 90) : null,
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12),
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
            fontSize: isSmallScreen ? 13 : 14,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.visible, // Changed from ellipsis to visible
        ),
      ),
    );
  }

  // Implement the search results builder that was missing
  Widget _buildSearchResults() {
    final allOrders = _generateAllOrders();

    // Filter orders by search query
    final filteredOrders = allOrders.where((order) {
      // Check order ID
      if (order["orderId"]
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase())) {
        return true;
      }

      // Check item names
      for (var item in order["items"] as List<Map<String, dynamic>>) {
        if (item["name"]
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase())) {
          return true;
        }
      }

      return false;
    }).toList();

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "Không tìm thấy đơn hàng nào với từ khóa \"$_searchQuery\"",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: filteredOrders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final order = filteredOrders[index];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDetailPage(
                  orderId: order["orderId"],
                  orderDate: order["date"],
                  items: order["items"],
                  status: order["status"],
                ),
              ),
            );
          },
          child: OrderItem(
            orderId: order["orderId"],
            date: order["date"],
            items: order["items"],
            status: order["status"],
            isClickable: true,
            onViewHistory: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderStatusHistoryPage(
                    orderId: order["orderId"],
                    currentStatus: order["status"],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Implement the orders generator method
  List<Map<String, dynamic>> _generateAllOrders() {
    final List<Map<String, dynamic>> allOrders = [];

    // Add orders for each status type
    for (int statusIndex = 0; statusIndex < 5; statusIndex++) {
      final status = OrderStatusTab.getStatusText(statusIndex);

      // Add 2 orders per status
      for (int i = 0; i < 2; i++) {
        allOrders.add({
          "orderId": "DH${123450 + (statusIndex * 10) + i}",
          "date": "01/05/2023",
          "status": status,
          "items": <Map<String, dynamic>>[
            {
              "name": "Laptop Asus XYZ",
              "image": "https://via.placeholder.com/80",
              "price": 15000000.0,
              "quantity": 1,
            },
            if (i % 2 == 0)
              {
                "name": "Chuột không dây Logitech",
                "image": "https://via.placeholder.com/80",
                "price": 450000.0,
                "quantity": 2,
              },
          ]
        });
      }
    }

    return allOrders;
  }
}
