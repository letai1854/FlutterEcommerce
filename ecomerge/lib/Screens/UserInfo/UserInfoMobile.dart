import 'package:e_commerce_app/Screens/UserInfo/UserInfoTypes.dart';
import 'package:e_commerce_app/widgets/Address/AddressManagement.dart';
import 'package:e_commerce_app/widgets/Info/PersonalInfoForm.dart';
import 'package:e_commerce_app/widgets/Order/OrderDetailPage.dart';
import 'package:e_commerce_app/widgets/Order/OrderHistoryPage.dart';
import 'package:e_commerce_app/widgets/Order/OrderItem.dart';
import 'package:e_commerce_app/widgets/Order/OrderStatusHistoryPage.dart';
import 'package:e_commerce_app/widgets/Order/OrderStatusTab.dart';
import 'package:e_commerce_app/widgets/Password/ChangePasswordContent.dart';
import 'package:e_commerce_app/widgets/Points/PointsContent.dart';
import 'package:flutter/material.dart';

class UserInfoMobile extends StatefulWidget {
  const UserInfoMobile({super.key});

  @override
  State<UserInfoMobile> createState() => _UserInfoMobileState();
}

class _UserInfoMobileState extends State<UserInfoMobile> {
  int _selectedOrderTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header section with user info and action buttons
            _buildHeader(),

            // Divider
            Divider(height: 1, thickness: 1, color: Colors.grey.shade300),

            // Main content - scrollable
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildOrdersSection(),
                    const SizedBox(height: 24),
                    _buildFeatureButtons(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header with back button, user info, and action icons
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),

          // User avatar - Using Icon instead of image to prevent asset loading issues
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),

          // Username
          const Expanded(
            child: Text(
              "Nguyễn Văn A",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Action buttons
          Row(
            children: [
              // Rewards - Updated to navigate to points page
              IconButton(
                icon: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.amber[600],
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '5',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                onPressed: () {
                  // Navigate to points page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        appBar: AppBar(
                          title: const Text(
                            "Điểm thưởng",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.red,
                        ),
                        body: const PointsContent(),
                      ),
                    ),
                  );
                },
                tooltip: 'Điểm thưởng',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),

              // Cart
              IconButton(
                icon: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    const Icon(Icons.shopping_cart),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '2',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                onPressed: () {},
                tooltip: 'Giỏ hàng',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),

              // Chat
              IconButton(
                icon: const Icon(Icons.chat),
                onPressed: () {},
                tooltip: 'Chat',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Orders section with status tabs only (no order list)
  Widget _buildOrdersSection() {
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
                overflow: TextOverflow
                    .visible, // Changed from ellipsis to visible to ensure full text shows
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

  // Feature buttons section at the bottom
  Widget _buildFeatureButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tài khoản của tôi",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Feature buttons with icons in a grid
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  spreadRadius: 1,
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              children: [
                _buildFeatureButton(
                  "Thông tin cá nhân",
                  Icons.person,
                  () => _navigateToWidget(const PersonalInfoForm()),
                ),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
                _buildFeatureButton(
                  "Đổi mật khẩu",
                  Icons.lock,
                  () => _navigateToWidget(const ChangePasswordContent()),
                ),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
                _buildFeatureButton(
                  "Địa chỉ giao hàng",
                  Icons.location_on,
                  () => _navigateToWidget(const AddressManagement()),
                ),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
                _buildFeatureButton(
                  "Admin",
                  Icons.admin_panel_settings,
                  () => _navigateToWidget(const AddressManagement()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Individual feature button
  Widget _buildFeatureButton(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.red),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // Helper method for navigation
  void _navigateToWidget(Widget widget) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => Scaffold(
                appBar: AppBar(
                  title:
                      Text("Tài khoản", style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.red,
                  elevation: 0,
                ),
                body: widget,
              )),
    );
  }
}

// New class for showing orders with a specific status - Simplified version of OrdersContent for mobile
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

  // Search results using same layout as order list
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

  // Generate orders with all statuses for search
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

  // Fix the _buildMobileTab method to prevent ellipsis
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
}
