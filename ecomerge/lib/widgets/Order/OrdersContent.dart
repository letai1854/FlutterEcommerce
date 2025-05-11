// Orders Content widget
import 'package:e_commerce_app/database/models/order/OrderDTO.dart';
import 'package:e_commerce_app/database/services/order_service.dart';
import 'package:e_commerce_app/widgets/Order/OrderDetailPage.dart';
import 'package:e_commerce_app/widgets/Order/OrderHistoryPage.dart';
import 'package:e_commerce_app/widgets/Order/OrderItem.dart';
import 'package:e_commerce_app/widgets/Order/OrderStatusHistoryPage.dart';
import 'package:flutter/material.dart';

// Define the animation wrapper widget
class AnimatedListItemWrapper extends StatefulWidget {
  final Widget child;
  final int index;
  final int pageSize; // To calculate stagger relative to page

  const AnimatedListItemWrapper({
    Key? key,
    required this.child,
    required this.index,
    required this.pageSize,
  }) : super(key: key);

  @override
  _AnimatedListItemWrapperState createState() =>
      _AnimatedListItemWrapperState();
}

class _AnimatedListItemWrapperState extends State<AnimatedListItemWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400), // Animation duration
      vsync: this,
    );

    // Staggered delay: items in the same "page" load will animate sequentially
    final staggerIndex = widget.index % widget.pageSize;
    final delay =
        Duration(milliseconds: staggerIndex * 75); // Stagger delay per item

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    Future.delayed(delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

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
  bool _isLoading = true; // For initial full page load
  String? _errorMessage;

  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  final int _pageSize = 10; // Number of items to fetch per page
  bool _hasMore = true; // True if there are more items to load
  bool _isLoadingMore = false; // True when loading more items

  @override
  void initState() {
    super.initState();
    _orderService = OrderService();
    _fetchOrders(); // Initial fetch
    _scrollController.addListener(_scrollListener);
  }

  @override
  void didUpdateWidget(covariant OrdersContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTab != oldWidget.selectedTab) {
      _fetchOrders(); // Reset and fetch for the new tab
    }
  }

  @override
  void dispose() {
    _orderService.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // Trigger load more when near the bottom (e.g., 200 pixels from the end)
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
      _orders = []; // Reset orders list
      _currentPage = 0; // Reset current page
      _hasMore = true; // Assume there's more data initially
      _isLoadingMore = false; // Not loading more during a full refresh
    });

    try {
      final status = _mapTabIndexToOrderStatus(widget.selectedTab);
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
          displayError = "Chưa có đơn hàng nào.";
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
      final status = _mapTabIndexToOrderStatus(widget.selectedTab);
      final orderPage = await _orderService.getCurrentUserOrders(
        status: status,
        page: _currentPage,
        size: _pageSize,
      );
      setState(() {
        _orders.addAll(orderPage.orders);
        _hasMore = !orderPage.isLast;
        if (_hasMore) {
          _currentPage++;
        }
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
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
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const OrderHistoryPage()),
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
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _isLoading // Handles initial loading state
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Text(" $_errorMessage", // Kept "Lỗi: " prefix
                        style: const TextStyle(
                            color: Colors.black))) // Changed to Colors.black
                // After initial load, if orders list is empty and no more data expected
                : _orders.isEmpty && !_hasMore && !_isLoadingMore
                    ? Center(
                        child: Text(
                            "Không có đơn hàng nào trong mục '${_getShortStatusName(widget.selectedTab)}'."))
                    : ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.6,
                        ),
                        child: ListView.separated(
                          controller: _scrollController,
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: _orders.length + (_hasMore ? 1 : 0),
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            if (index == _orders.length) {
                              return _isLoadingMore
                                  ? const Center(
                                      child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ))
                                  : const SizedBox.shrink();
                            }

                            final order = _orders[index];

                            return AnimatedListItemWrapper(
                              index: index,
                              pageSize: _pageSize,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrderDetailPage(
                                          orderId: order.id.toString(),
                                        ),
                                      ),
                                    );
                                    if (result == true && mounted) {
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
                                        _getShortStatusName(widget.selectedTab),
                                    isClickable: true,
                                    onViewHistory: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              OrderStatusHistoryPage(
                                            orderId: order.id.toString(),
                                            currentStatus: _getShortStatusName(
                                                widget.selectedTab),
                                          ),
                                        ),
                                      );
                                    },
                                    isSmallScreen: isSmallScreen,
                                    subtotal: order.subtotal ?? 0.0,
                                    shippingFee: order.shippingFee ?? 0.0,
                                    tax: order.tax ?? 0.0,
                                    totalAmount: order.totalAmount ?? 0.0,
                                    couponDiscount: order.couponDiscount,
                                    pointsDiscount:
                                        order.pointsDiscount?.toDouble(),
                                    pointsEarned:
                                        order.pointsEarned?.toDouble(),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
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
