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

  late OrderService _orderService;
  List<OrderDTO> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  final int _pageSize = 10;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _selectedOrderTab = widget.initialTab < 0 ? 0 : widget.initialTab;
    _orderService = OrderService();
    _fetchOrders();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _orderService.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreOrders();
    }
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
      _currentPage = 0;
      _hasMore = true;
      _isLoadingMore = false;
    });
    try {
      final status = _mapTabIndexToOrderStatus(_selectedOrderTab);
      final orderPage = await _orderService.getCurrentUserOrders(
        status: status,
        page: _currentPage,
        size: _pageSize,
      );
      if (mounted) {
        setState(() {
          _orders = orderPage.orders;
          _hasMore = !orderPage.isLast;
          if (_hasMore) {
            _currentPage++;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String displayError;
        bool is404 = e.toString().toLowerCase().contains('(status: 404)');
        if (is404) {
          displayError = "Chưa có đơn hàng nào.";
        } else {
          displayError = "Lỗi tải đơn hàng. Vui lòng thử lại.";
        }
        setState(() {
          _isLoading = false;
          _errorMessage = displayError;
          if (is404) {
            _orders = [];
            _hasMore = false;
          }
        });
      }
    }
  }

  Future<void> _loadMoreOrders() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final status = _mapTabIndexToOrderStatus(_selectedOrderTab);
      final orderPage = await _orderService.getCurrentUserOrders(
        status: status,
        page: _currentPage,
        size: _pageSize,
      );
      if (mounted) {
        setState(() {
          _orders.addAll(orderPage.orders);
          _hasMore = !orderPage.isLast;
          if (_hasMore) {
            _currentPage++;
          }
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
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
        "discountPercentage": d.productDiscountPercentage ?? 0.0,
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
        title: const Text(
          "Đơn hàng của tôi",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red,
        actions: [
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
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrderHistoryPage(),
                      ),
                    );
                    if (result == true && mounted) {
                      _fetchOrders();
                    }
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
                              style: const TextStyle(color: Colors.black)))
                      : _orders.isEmpty && !_hasMore
                          ? Center(
                              child: Text(
                                  "Không có đơn hàng nào trong mục '${_getShortStatusName(_selectedOrderTab)}'."))
                          : ListView.separated(
                              controller: _scrollController,
                              padding: EdgeInsets.zero,
                              itemCount: _orders.length + (_hasMore ? 1 : 0),
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                if (index == _orders.length && _hasMore) {
                                  return _isLoadingMore
                                      ? const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                        )
                                      : const SizedBox.shrink();
                                }
                                if (index >= _orders.length) {
                                  return const SizedBox.shrink();
                                }

                                final order = _orders[index];

                                return GestureDetector(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrderDetailPage(
                                          orderId: order.id.toString(),
                                        ),
                                      ),
                                    );
                                    if (result == true) {
                                      _fetchOrders();
                                    }
                                  },
                                  child: OrderItem(
                                    orderId: order.id.toString(),
                                    date: order.orderDate
                                            ?.toIso8601String()
                                            .split('T')[0] ??
                                        'N/A',
                                    items: _mapOrderDetailsToItems(
                                        order.orderDetails),
                                    status:
                                        _getShortStatusName(_selectedOrderTab),
                                    isClickable: true,
                                    onViewHistory: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              OrderStatusHistoryPage(
                                            orderId: order.id.toString(),
                                            currentStatus: _getShortStatusName(
                                                _selectedOrderTab),
                                          ),
                                        ),
                                      );
                                    },
                                    subtotal: order.subtotal ?? 0.0,
                                    shippingFee: order.shippingFee ?? 0.0,
                                    tax: order.tax ?? 0.0,
                                    totalAmount: order.totalAmount ?? 0.0,
                                    couponDiscount: order.couponDiscount,
                                    pointsDiscount:
                                        order.pointsDiscount?.toDouble(),
                                    pointsEarned:
                                        order.pointsEarned?.toDouble(),
                                    isSmallScreen: true,
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
