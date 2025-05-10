// Orders Content widget
import 'package:e_commerce_app/database/models/order/OrderDTO.dart';
import 'package:e_commerce_app/database/services/order_service.dart';
import 'package:e_commerce_app/widgets/Order/OrderDetailPage.dart';
import 'package:e_commerce_app/widgets/Order/OrderHistoryPage.dart';
import 'package:e_commerce_app/widgets/Order/OrderItem.dart';
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
  late OrderService _orderService;
  List<OrderDTO> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _orderService = OrderService();
    _fetchOrders();
  }

  @override
  void didUpdateWidget(covariant OrdersContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTab != oldWidget.selectedTab) {
      _fetchOrders();
    }
  }

  @override
  void dispose() {
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
      _orders = [];
    });
    try {
      final status = _mapTabIndexToOrderStatus(widget.selectedTab);
      final orderPage =
          await _orderService.getCurrentUserOrders(status: status);
      setState(() {
        _orders = orderPage.orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
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
        Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                    // _buildResponsiveTab(
                    //     _getShortStatusName(5), 5, isSmallScreen),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Text("Lỗi: $_errorMessage",
                        style: const TextStyle(color: Colors.red)))
                : _orders.isEmpty
                    ? Center(
                        child: Text(
                            "Không có đơn hàng nào trong mục '${_getShortStatusName(widget.selectedTab)}'."))
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _orders.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          final items =
                              _mapOrderDetailsToItems(order.orderDetails);

                          return MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
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
                                      status: _getShortStatusName(
                                          widget.selectedTab),
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
                                status: _getShortStatusName(widget.selectedTab),
                                isClickable: true,
                                onViewHistory: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderHistoryPage(),
                                    ),
                                  );
                                },
                                isSmallScreen: isSmallScreen,
                              ),
                            ),
                          );
                        },
                      ),
      ],
    );
  }

  Widget _buildResponsiveTab(String title, int index, bool isSmallScreen) {
    final isSelected = widget.selectedTab == index;

    return GestureDetector(
      onTap: () {
        widget.onTabChanged(index);
      },
      child: Container(
        width: isSmallScreen ? (title.length > 9 ? 90 : 75) : null,
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 12),
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
            fontSize: isSmallScreen ? 12 : 14,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.visible,
        ),
      ),
    );
  }
}
