import 'package:e_commerce_app/database/models/order/OrderDTO.dart';
import 'package:e_commerce_app/database/services/order_service.dart';
import 'package:e_commerce_app/widgets/Order/OrderDetailPage.dart';
import 'package:e_commerce_app/widgets/Order/OrderItem.dart';
import 'package:e_commerce_app/widgets/Order/OrderStatusHistoryPage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:typed_data';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({Key? key}) : super(key: key);

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final OrderService _orderService = OrderService();
  List<OrderDTO> _orders = [];
  final ScrollController _scrollController = ScrollController();
  int _apiCurrentPage = 0;
  final int _apiPageSize = 10; // Number of items to fetch per page
  bool _hasMore = true; // True if there are more items to load
  bool _isLoading = true; // For initial full page load
  bool _isLoadingMore = false; // True when loading more items
  String? _errorMessage;
  bool _childPageCausedChange =
      false; // Flag to indicate refresh needed for parent
  bool _isOfflineMode = false; // Add flag for offline mode

  @override
  void initState() {
    super.initState();
    _checkConnectivity(); // Check connectivity on init
    _fetchInitialOrders();
    _scrollController.addListener(_scrollListener);
    
    // Set up connectivity listener
    _setupConnectivityListener();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _orderService.dispose();
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

  Future<void> _checkConnectivity() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      setState(() {
        _isOfflineMode = connectivityResult == ConnectivityResult.none;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error checking connectivity: $e');
      }
      setState(() {
        _isOfflineMode = false; // Default to assuming online
      });
    }
  }

  void _setupConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      final bool wasOffline = _isOfflineMode;
      final bool isNowOnline = result != ConnectivityResult.none;
      
      if (mounted) {
        setState(() {
          _isOfflineMode = !isNowOnline;
        });
        
        // If we just came back online after being offline, refresh data
        if (wasOffline && isNowOnline && mounted) {
          if (kDebugMode) {
            print("OrderHistoryPage: Network restored - refreshing order data and images");
          }
          _fetchInitialOrders(); // This will load fresh data and images
        }
      }
    });
  }

  Future<void> _fetchInitialOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _orders = []; // Reset orders list
      _apiCurrentPage = 0; // Reset current page
      _hasMore = true; // Assume there's more data initially
    });

    try {
      final orderPage = await _orderService.getCurrentUserOrders(
        page: _apiCurrentPage,
        size: _apiPageSize,
        // No status is passed to fetch all orders
      );
      
      // Get online status BEFORE using setState
      final bool isOnline = await _orderService.isOnline();
      
      if (mounted) {
        setState(() {
          _orders = orderPage.orders;
          _hasMore = !orderPage.isLast;
          if (_hasMore) {
            _apiCurrentPage++;
          }
          _isLoading = false;
          
          // Now use the pre-fetched online status
          _isOfflineMode = !isOnline;
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
        
        // Don't forget to also set the online status here in the error case
        final bool isOnline = await _orderService.isOnline();
        
        setState(() {
          _isLoading = false;
          _errorMessage = displayError;
          _isOfflineMode = !isOnline;
          if (is404) {
            _orders = []; // Ensure orders list is empty
            _hasMore = false; // No more data to fetch
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
      final orderPage = await _orderService.getCurrentUserOrders(
        page: _apiCurrentPage,
        size: _apiPageSize,
      );
      setState(() {
        _orders.addAll(orderPage.orders);
        _hasMore = !orderPage.isLast;
        if (_hasMore) {
          _apiCurrentPage++;
        }
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
        // Optionally set an error message for loading more, or log it
      });
    }
  }

  List<Map<String, dynamic>> _mapOrderDetailsToOrderItemItems(
      List<OrderDetailItemDTO>? details) {
    if (details == null) return [];
    return details.map((d) {
      return {
        "name": d.productName ?? 'N/A',
        "image":
            d.imageUrl ?? "https://via.placeholder.com/80", // Fallback image
        "price": d.priceAtPurchase,
        "quantity": d.quantity,
        "discountPercentage": d.productDiscountPercentage ?? 0.0,
        "isOfflineMode": _isOfflineMode, // Add offline mode flag
      };
    }).toList();
  }

  String _getDisplayStatus(OrderStatus? status) {
    if (status == null) return "Không xác định";
    switch (status) {
      case OrderStatus.cho_xu_ly:
        return "Chờ xử lý";
      case OrderStatus.da_xac_nhan:
        return "Đã xác nhận";
      case OrderStatus.dang_giao:
        return "Đang giao";
      case OrderStatus.da_giao:
        return "Đã giao";
      case OrderStatus.da_huy:
        return "Đã hủy";
      default:
        return "Không xác định";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.grey[100];
    final headingColor = isDarkMode ? Colors.white : Colors.red[800];

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _childPageCausedChange);
        return false; // We've handled the pop, so prevent default system pop.
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context, _childPageCausedChange);
            },
          ),
          title: const Text(
            "Lịch sử đơn hàng",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.red,
          elevation: 4,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            // Show offline banner when in offline mode
           
            
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      backgroundColor!,
                      Colors.white,
                    ],
                    stops: const [0.0, 0.4],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // History info text with decorative elements
                      Container(
                        margin: const EdgeInsets.only(bottom: 20, top: 10),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Colors.red[700]!, width: 5),
                          ),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.history, color: headingColor, size: 24),
                            const SizedBox(width: 10),
                            Text(
                              "Thông tin tất cả đơn hàng của bạn",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: headingColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Orders list with enhanced styling
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _errorMessage != null
                                ? Center(
                                    child: Text(" $_errorMessage",
                                        style: const TextStyle(color: Colors.black)))
                                : _orders.isEmpty && !_hasMore
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.receipt_long_outlined,
                                              size: 80,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              "Không có lịch sử đơn hàng nào",
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.separated(
                                        controller: _scrollController,
                                        itemCount:
                                            _orders.length + (_hasMore ? 1 : 0),
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(height: 16),
                                        itemBuilder: (context, index) {
                                          if (index == _orders.length) {
                                            return _isLoadingMore
                                                ? const Center(
                                                    child: Padding(
                                                    padding: EdgeInsets.all(16.0),
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ))
                                                : const SizedBox.shrink();
                                          }

                                          final order = _orders[index];
                                          final orderItemsForDisplay =
                                              _mapOrderDetailsToOrderItemItems(
                                                  order.orderDetails);
                                          final displayStatus =
                                              _getDisplayStatus(order.orderStatus);

                                          return GestureDetector(
                                            onTap: () async {
                                              final result = await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      OrderDetailPage(
                                                    orderId: order.id.toString(),
                                                  ),
                                                ),
                                              );
                                              if (result == true && mounted) {
                                                _childPageCausedChange =
                                                    true; // Set flag
                                                _fetchInitialOrders();
                                              }
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        Colors.grey.withOpacity(0.2),
                                                    spreadRadius: 1,
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: OrderItem(
                                                orderId: order.id.toString(),
                                                date: order.orderDate
                                                        ?.toIso8601String()
                                                        .split('T')[0] ??
                                                    'N/A',
                                                items: orderItemsForDisplay,
                                                status: displayStatus,
                                                onViewHistory: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          OrderStatusHistoryPage(
                                                        orderId: order.id.toString(),
                                                        currentStatus: displayStatus,
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
                                                isSmallScreen: MediaQuery.of(context)
                                                        .size
                                                        .width <
                                                    600,
                                                isOfflineMode: _isOfflineMode,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
