import 'package:e_commerce_app/database/models/order/OrderDTO.dart';
import 'package:e_commerce_app/database/services/order_service.dart';
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

  late OrderService _orderService;
  List<OrderDTO> _allFetchedOrders = [];
  List<OrderDTO> _displayedOrders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedOrderTab = widget.initialTab < 0 ? 0 : widget.initialTab;
    _orderService = OrderService();
    _fetchOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _orderService.dispose();
    super.dispose();
  }

  OrderStatus? _mapTabIndexToOrderStatus(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return OrderStatus.cho_xu_ly;
      case 1:
        return OrderStatus.da_xac_nhan;
      case 2:
        return OrderStatus.dang_giao;
      case 3:
        return OrderStatus.da_giao;
      case 4:
        return OrderStatus.da_huy;
      default:
        return null;
    }
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _allFetchedOrders = [];
      _displayedOrders = [];
    });
    try {
      final status = _mapTabIndexToOrderStatus(_selectedOrderTab);
      final orderPage =
          await _orderService.getCurrentUserOrders(status: status);
      setState(() {
        _allFetchedOrders = orderPage.orders;
        _displayedOrders = _allFetchedOrders;
        _isLoading = false;
        _filterOrdersForDisplay();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _filterOrdersForDisplay() {
    if (_searchQuery.isEmpty) {
      _displayedOrders = List.from(_allFetchedOrders);
    } else {
      _displayedOrders = _allFetchedOrders.where((order) {
        final query = _searchQuery.toLowerCase();
        bool matches = order.id.toString().toLowerCase().contains(query);
        if (matches) return true;

        if (order.orderDetails != null) {
          for (var item in order.orderDetails!) {
            if (item.productName != null &&
                item.productName!.toLowerCase().contains(query)) {
              matches = true;
              break;
            }
          }
        }
        return matches;
      }).toList();
    }
    setState(() {});
  }

  List<Map<String, dynamic>> _mapOrderDetailsToItems(
      List<OrderDetailItemDTO>? details) {
    if (details == null) return [];
    return details.map((d) {
      return {
        "name": d.productName ?? 'N/A',
        "image": d.imageUrl ?? "https://via.placeholder.com/80",
        "price": d.priceAtPurchase,
        "quantity": d.quantity,
      };
    }).toList();
  }

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
                    _filterOrdersForDisplay();
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
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchQuery = '';
                  _searchController.clear();
                  _filterOrdersForDisplay();
                }
              });
            },
          ),
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
                      // _buildMobileTab(_getShortStatusName(5), 5),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Text("Lỗi: $_errorMessage",
                              style: const TextStyle(color: Colors.red)))
                      : _displayedOrders.isEmpty
                          ? Center(
                              child: Text(_searchQuery.isNotEmpty
                                  ? "Không tìm thấy đơn hàng nào với từ khóa \"$_searchQuery\" trong mục '${_getShortStatusName(_selectedOrderTab)}'."
                                  : "Không có đơn hàng nào trong mục '${_getShortStatusName(_selectedOrderTab)}'."))
                          : ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: _displayedOrders.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final order = _displayedOrders[index];
                                final items =
                                    _mapOrderDetailsToItems(order.orderDetails);
                                final statusText =
                                    _getShortStatusName(_selectedOrderTab);

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrderDetailPage(
                                          orderId: order.id.toString(),
                                          orderDate: order.orderDate
                                                  ?.toIso8601String()
                                                  .split('T')[0] ??
                                              'N/A',
                                          items: items,
                                          status: statusText,
                                        ),
                                      ),
                                    );
                                  },
                                  child: OrderItem(
                                    orderId: order.id.toString(),
                                    date: order.orderDate
                                            ?.toIso8601String()
                                            .split('T')[0] ??
                                        'N/A',
                                    items: items,
                                    status: statusText,
                                    isClickable: true,
                                    onViewHistory: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              OrderStatusHistoryPage(
                                            orderId: order.id.toString(),
                                            currentStatus: statusText,
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

  Widget _buildMobileTab(String title, int index) {
    final isSelected = _selectedOrderTab == index;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 500;
    double tabWidth = isSmallScreen ? (title.length > 8 ? 100 : 80) : 120;
    if (title == "Trả hàng" && isSmallScreen) tabWidth = 90;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOrderTab = index;
          _searchQuery = '';
          _searchController.clear();
          _fetchOrders();
        });
      },
      child: Container(
        width: tabWidth,
        padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 6 : 10, vertical: 12),
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
          overflow: TextOverflow.visible,
        ),
      ),
    );
  }
}
