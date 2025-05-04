import 'package:e_commerce_app/Screens/UserInfo/UserInfoTypes.dart';
import 'package:e_commerce_app/constants.dart';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/database/services/user_service.dart';
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

  // Form state for PersonalInfoForm
  String _name = UserInfo().currentUser?.fullName ?? "";
  String _email = UserInfo().currentUser?.email ?? "";
  String _phone = "0123456789";
  String _gender = "male";
  String _birthDate = "01/01/1990";

  // Form controllers for PersonalInfoForm
  final TextEditingController _nameController =
      TextEditingController(text: UserInfo().currentUser?.fullName ?? "");
  final TextEditingController _emailController =
      TextEditingController(text: UserInfo().currentUser?.email ?? "");
  final TextEditingController _phoneController =
      TextEditingController(text: "0123456789");

  // Form state for ChangePasswordContent
  String _currentPassword = "";
  String _newPassword = "";
  String _confirmPassword = "";
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Form controllers for ChangePasswordContent
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Handlers for PersonalInfoForm
  void _handleNameChanged(String value) {
    setState(() {
      _name = value;
    });
  }

  void _handleEmailChanged(String value) {
    setState(() {
      _email = value;
    });
  }

  void _handlePhoneChanged(String value) {
    setState(() {
      _phone = value;
    });
  }

  void _handleGenderChanged(String value) {
    setState(() {
      _gender = value;
    });
  }

  void _handleBirthDateChanged(String value) {
    setState(() {
      _birthDate = value;
    });
  }

  // Handlers for ChangePasswordContent
  void _handleCurrentPasswordChanged(String value) {
    setState(() {
      _currentPassword = value;
    });
  }

  void _handleNewPasswordChanged(String value) {
    setState(() {
      _newPassword = value;
    });
  }

  void _handleConfirmPasswordChanged(String value) {
    setState(() {
      _confirmPassword = value;
    });
  }

  // Toggle password visibility handlers
  void _toggleCurrentPasswordVisibility() {
    setState(() {
      _obscureCurrentPassword = !_obscureCurrentPassword;
    });
  }

  void _toggleNewPasswordVisibility() {
    setState(() {
      _obscureNewPassword = !_obscureNewPassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

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
            onPressed: () => Navigator.pushReplacementNamed(
              context,
              '/home',
              arguments: {'selectedIndex': 0},
            ),
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
                      settings: RouteSettings(
                        arguments: {'selectedIndex': -1},
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
                onPressed: () {
                  Navigator.pushNamed(context, '/cart',
                      arguments: {'selectedIndex': -1});
                },
                tooltip: 'Giỏ hàng',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),

              // Chat
              IconButton(
                icon: const Icon(Icons.chat),
                onPressed: () {
                  Navigator.pushNamed(context, '/chat',
                      arguments: {'selectedIndex': -1});
                },
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

  // Helper method for navigation - completely rewritten
  void _navigateToWidget(Widget widget) {
    if (widget is PersonalInfoForm) {
      // Use mobile-optimized personal info screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _MobilePersonalInfoScreen(
            initialName: _name,
            initialEmail: _email,
            initialPhone: _phone,
            initialGender: _gender,
            initialBirthDate: _birthDate,
            onSave: (name, email, phone, gender, birthDate) {
              setState(() {
                _name = name;
                _email = email;
                _phone = phone;
                _gender = gender;
                _birthDate = birthDate;
              });
            },
          ),
        ),
      );
    } else if (widget is ChangePasswordContent) {
      // Use mobile-optimized password change screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _MobilePasswordChangeScreen(
            onSave: (current, newPw, confirm) {
              setState(() {
                _currentPassword = current;
                _newPassword = newPw;
                _confirmPassword = confirm;
              });
            },
          ),
        ),
      );
    } else {
      // For other widgets, use standard navigation
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text("Tài khoản", style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
              elevation: 0,
            ),
            body: widget,
          ),
        ),
      );
    }
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
                  () => _navigateToWidget(PersonalInfoForm(
                    name: _name,
                    email: _email,
                    phone: _phone,
                    gender: _gender,
                    birthDate: _birthDate,
                    nameController: _nameController,
                    emailController: _emailController,
                    phoneController: _phoneController,
                    onNameChanged: _handleNameChanged,
                    onEmailChanged: _handleEmailChanged,
                    onPhoneChanged: _handlePhoneChanged,
                    onGenderChanged: _handleGenderChanged,
                    onBirthDateChanged: _handleBirthDateChanged,
                    onSave: () {},
                  )),
                ),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
                _buildFeatureButton(
                  "Đổi mật khẩu",
                  Icons.lock,
                  () => _navigateToWidget(ChangePasswordContent(
                    currentPassword: _currentPassword,
                    newPassword: _newPassword,
                    confirmPassword: _confirmPassword,
                    currentPasswordController: _currentPasswordController,
                    newPasswordController: _newPasswordController,
                    confirmPasswordController: _confirmPasswordController,
                    obscureCurrentPassword: _obscureCurrentPassword,
                    obscureNewPassword: _obscureNewPassword,
                    obscureConfirmPassword: _obscureConfirmPassword,
                    onCurrentPasswordChanged: _handleCurrentPasswordChanged,
                    onNewPasswordChanged: _handleNewPasswordChanged,
                    onConfirmPasswordChanged: _handleConfirmPasswordChanged,
                    onToggleCurrentPasswordVisibility:
                        _toggleCurrentPasswordVisibility,
                    onToggleNewPasswordVisibility: _toggleNewPasswordVisibility,
                    onToggleConfirmPasswordVisibility:
                        _toggleConfirmPasswordVisibility,
                  )),
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
                  () => Navigator.pushNamed(context, '/admin'),
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

// Mobile-specific Personal Info Screen implementation
class _MobilePersonalInfoScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final String initialPhone;
  final String initialGender;
  final String initialBirthDate;
  final Function(String, String, String, String, String) onSave;

  const _MobilePersonalInfoScreen({
    Key? key,
    required this.initialName,
    required this.initialEmail,
    required this.initialPhone,
    required this.initialGender,
    required this.initialBirthDate,
    required this.onSave,
  }) : super(key: key);

  @override
  State<_MobilePersonalInfoScreen> createState() =>
      _MobilePersonalInfoScreenState();
}

class _MobilePersonalInfoScreenState extends State<_MobilePersonalInfoScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late String _gender;
  late String _birthDate;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _gender = widget.initialGender;
    _birthDate = widget.initialBirthDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Thông tin cá nhân", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile picture
                Stack(
                  children: [
                    const CircleAvatar(
                      radius: 60,
                      backgroundImage:
                          NetworkImage('https://via.placeholder.com/150'),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text("Đổi ảnh đại diện"),
                const SizedBox(height: 32),

                // Form fields - vertical layout for mobile
                _buildFormField(
                  label: "Họ và tên",
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập họ và tên';
                    }
                    return null;
                  },
                ),
                _buildFormField(
                  label: "Email",
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email';
                    } else if (!value.contains('@') || !value.contains('.')) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // Save button - full width
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        widget.onSave(
                            _nameController.text,
                            _emailController.text,
                            _phoneController.text,
                            _gender,
                            _birthDate);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Thông tin đã được lưu"),
                            backgroundColor: Colors.green,
                          ),
                        );

                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Lưu thay đổi",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red),
              ),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }
}

// Mobile-specific Password Change Screen implementation
class _MobilePasswordChangeScreen extends StatefulWidget {
  final Function(String, String, String) onSave;

  const _MobilePasswordChangeScreen({
    Key? key,
    required this.onSave,
  }) : super(key: key);

  @override
  State<_MobilePasswordChangeScreen> createState() =>
      _MobilePasswordChangeScreenState();
}

class _MobilePasswordChangeScreenState
    extends State<_MobilePasswordChangeScreen> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Đổi mật khẩu", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info text
                Text(
                  "Để bảo mật tài khoản, vui lòng không chia sẻ mật khẩu cho người khác",
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 24),

                // Password fields
                _buildPasswordField(
                  "Mật khẩu hiện tại",
                  _currentPasswordController,
                  _obscureCurrentPassword,
                  () {
                    setState(() {
                      _obscureCurrentPassword = !_obscureCurrentPassword;
                    });
                  },
                ),

                _buildPasswordField(
                  "Mật khẩu mới",
                  _newPasswordController,
                  _obscureNewPassword,
                  () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu mới';
                    } else if (value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                    }
                    return null;
                  },
                ),

                _buildPasswordField(
                  "Xác nhận mật khẩu mới",
                  _confirmPasswordController,
                  _obscureConfirmPassword,
                  () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng xác nhận mật khẩu mới';
                    } else if (value != _newPasswordController.text) {
                      return 'Mật khẩu xác nhận không khớp';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 40),

                // Submit button - full width
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Add async keyword here
                      if (_formKey.currentState!.validate()) {
                        widget.onSave(
                          _currentPasswordController.text,
                          _newPasswordController.text,
                          _confirmPasswordController.text,
                        );
                        final userService = UserService();
                        // userService.testRegistration();
                        final loginResult = await userService.loginUser(
                            "letai1854@gmail.com", "123456");
                        // bool checkChangePass = false;
                        bool checkChangePass =
                            await userService.changeCurrentUserPassword(
                          _currentPasswordController.text,
                          _newPasswordController.text,
                        );

                        if (checkChangePass) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Mật khẩu đã được đổi thành công"),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Không thể đổi mật khẩu. Vui lòng thử lại."),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Xác nhận thay đổi",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool obscureText,
    VoidCallback toggleVisibility, {
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[600],
                ),
                onPressed: toggleVisibility,
              ),
            ),
            validator: validator ??
                (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập $label';
                  }
                  return null;
                },
          ),
        ],
      ),
    );
  }
}
