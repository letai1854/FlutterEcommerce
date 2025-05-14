import 'package:e_commerce_app/Screens/Admin/order/OrderDetailScreen.dart';
import 'package:e_commerce_app/database/models/order/OrderDTO.dart';
import 'package:e_commerce_app/database/services/order_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({Key? key}) : super(key: key);

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  String _selectedFilter = 'Tất cả';
  final List<String> _filterOptions = [
    'Tất cả',
    'Hôm nay',
    'Hôm qua',
    'Tuần này',
    'Tháng này',
    'Khoảng thời gian cụ thể',
  ];

  // Add a ScrollController to maintain scroll position
  final ScrollController _scrollController = ScrollController();
  double? _previousScrollOffset;
  
  DateTimeRange? _customDateRange;
  int _currentPage = 0;
  final int _rowsPerPage = 20; // Matches the API page size

  // Replace mock data with API state variables
  bool _isLoading = false;
  String _errorMessage = '';
  List<OrderDTO> _orders = [];
  int _totalElements = 0;
  int _totalPages = 0;
  
  // Add service instance
  final OrderService _orderService = OrderService();

  // Create a mapping from OrderStatus to display names
  final Map<String, String> _orderStatusDisplay = {
    'cho_xu_ly': 'Chờ xử lý',
    'da_xac_nhan': 'Đã xác nhận',
    'dang_giao': 'Đang giao',
    'da_giao': 'Đã giao',
    'da_huy': 'Đã hủy',
  };
  
  // Add mapping from PaymentStatus to display names
  final Map<String, String> _paymentStatusDisplay = {
    'chua_thanh_toan': 'Chưa thanh toán',
    'da_thanh_toan': 'Đã thanh toán',
    'loi_thanh_toan': 'Lỗi thanh toán',
  };

  @override
  void initState() {
    super.initState();
    // Load orders immediately
    _loadOrders();
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose the ScrollController
    _orderService.dispose();
    super.dispose();
  }

  // Convert OrderStatus enum to display name
  String _getOrderStatusDisplay(OrderStatus? status) {
    if (status == null) return 'N/A';
    final statusString = orderStatusToString(status);
    return _orderStatusDisplay[statusString] ?? statusString;
  }
  
  // Add helper method for payment status display
  String _getPaymentStatusDisplay(String? status) {
    if (status == null || status.isEmpty) return 'N/A';
    return _paymentStatusDisplay[status.toLowerCase()] ?? status;
  }

  // Updated method to load orders from API
  Future<void> _loadOrders() async {
    // Save current scroll position if available
    if (_scrollController.hasClients) {
      _previousScrollOffset = _scrollController.offset;
    }
    
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      // Get date range based on filter
      DateTime? startDate;
      DateTime? endDate;

      if (_selectedFilter == 'Khoảng thời gian cụ thể' && _customDateRange != null) {
        startDate = _customDateRange!.start;
        // Set end date to end of day
        endDate = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
      } else if (_selectedFilter != 'Tất cả') {
        final now = DateTime.now();
        final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
        
        if (_selectedFilter == 'Hôm nay') {
          startDate = DateTime(now.year, now.month, now.day);
          endDate = endOfToday;
        } else if (_selectedFilter == 'Hôm qua') {
          final yesterday = now.subtract(const Duration(days: 1));
          startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
          endDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        } else if (_selectedFilter == 'Tuần này') {
          // Get first day of week (assuming Monday is first day)
          startDate = now.subtract(Duration(days: now.weekday - 1));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          endDate = endOfToday;
        } else if (_selectedFilter == 'Tháng này') {
          startDate = DateTime(now.year, now.month, 1);
          endDate = endOfToday;
        }
      }

      // Call API with filters
      final result = await _orderService.getOrdersForAdmin(
        page: _currentPage,
        size: _rowsPerPage,
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        setState(() {
          _orders = result.content;
          _totalElements = result.totalElements;
          _totalPages = result.totalPages;
          _isLoading = false;
        });
        
        // Restore scroll position after the frame is rendered
        if (_previousScrollOffset != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(
                _previousScrollOffset!.clamp(
                  0.0, 
                  _scrollController.position.maxScrollExtent
                )
              );
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  // Method to update order status with API call
  Future<void> _updateOrderStatus(int orderId, OrderStatus newStatus) async {
    try {
      await _orderService.updateOrderStatusByAdmin(orderId, newStatus, null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật trạng thái đơn hàng thành công')),
      );
      // Reload orders to reflect changes
      _loadOrders();
    } catch (e) {
      print('Error updating order status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật trạng thái đơn hàng: $e')),
      );
    }
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _customDateRange ?? DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
      helpText: 'Chọn khoảng thời gian',
      cancelText: 'Hủy',
      confirmText: 'Xác nhận',
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null && picked != _customDateRange) {
      setState(() {
        _customDateRange = picked;
        _selectedFilter = 'Khoảng thời gian cụ thể';
        _currentPage = 0;
      });
      _loadOrders(); // Reload with new date range
    } else if (picked == null && _selectedFilter == 'Khoảng thời gian cụ thể') {
      if (_customDateRange != null) {
        setState(() {
          _selectedFilter = 'Tất cả';
          _customDateRange = null;
          _currentPage = 0;
        });
        _loadOrders(); // Reload with cleared filter
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double availableWidth = MediaQuery.of(context).size.width - 2 * 16.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Đơn hàng'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: SingleChildScrollView(
          controller: _scrollController, // Attach the ScrollController
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildScreenLayout(availableWidth),
          ),
        ),
      ),
    );
  }

  Widget _buildScreenLayout(double availableWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: availableWidth,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 250,
                child: DropdownButtonFormField<String>(
                  value: _selectedFilter,
                  items: _filterOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedFilter = newValue;
                        if (newValue == 'Khoảng thời gian cụ thể') {
                          _showDateRangePicker();
                        } else {
                          _customDateRange = null;
                          _currentPage = 0;
                        }
                      });
                      _loadOrders(); // Reload with new filter
                    }
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Danh sách đơn hàng',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (_selectedFilter == 'Khoảng thời gian cụ thể' && _customDateRange != null)
              Text(
                '${DateFormat('dd/MM/yyyy').format(_customDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_customDateRange!.end)}',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Show loading, error or data
        _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: Colors.red),
                      SizedBox(height: 16),
                      Text("Không có kết nối internet", textAlign: TextAlign.center),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadOrders,
                        child: Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            "Không tìm thấy đơn hàng nào",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        
                        return Card(
                          key: ValueKey(order.id),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: 2,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrderDetailScreen(
                                    orderId: order.id,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Mã ĐH: #${order.id}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Status dropdown
                                      GestureDetector(
                                        onTap: () {},
                                        behavior: HitTestBehavior.opaque,
                                        child: SizedBox(
                                          width: 150,
                                          child: DropdownButtonFormField<OrderStatus>(
                                            isDense: true,
                                            decoration: InputDecoration(
                                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                                              isCollapsed: true,
                                            ),
                                            value: order.orderStatus,
                                            items: OrderStatus.values.map((OrderStatus status) {
                                              return DropdownMenuItem<OrderStatus>(
                                                value: status,
                                                child: Text(
                                                  _getOrderStatusDisplay(status),
                                                  style: TextStyle(fontSize: 13),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (OrderStatus? newValue) {
                                              if (newValue != null) {
                                                _updateOrderStatus(order.id, newValue);
                                              }
                                            },
                                            hint: Text('Trạng thái'),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      if (constraints.maxWidth < 350) {
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Người nhận: ${order.recipientName ?? 'N/A'}', style: TextStyle(fontSize: 13)),
                                            Text('SĐT: ${order.recipientPhoneNumber ?? 'N/A'}', style: TextStyle(fontSize: 13)),
                                          ],
                                        );
                                      } else {
                                        return Row(
                                          children: [
                                            Expanded(
                                              flex: 1,
                                              child: Text('Người nhận: ${order.recipientName ?? 'N/A'}', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Text('SĐT: ${order.recipientPhoneNumber ?? 'N/A'}', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)
                                            ),
                                          ],
                                        );
                                      }
                                    }
                                  ),
                                  const SizedBox(height: 4),

                                  Text('Địa chỉ: ${order.shippingAddress ?? 'N/A'}', style: TextStyle(fontSize: 13)),
                                  const SizedBox(height: 4),

                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      if (constraints.maxWidth < 350) {
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Tổng tiền: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ', decimalDigits: 0).format(order.totalAmount ?? 0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                            Text('TT TT: ${_getPaymentStatusDisplay(order.paymentStatus)}', style: TextStyle(fontSize: 13)),
                                          ],
                                        );
                                      } else {
                                        return Row(
                                          children: [
                                            Expanded(
                                              flex: 1,
                                              child: Text('Tổng tiền: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ', decimalDigits: 0).format(order.totalAmount ?? 0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Text('TT TT: ${_getPaymentStatusDisplay(order.paymentStatus)}', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)
                                            ),
                                          ],
                                        );
                                      }
                                    }
                                  ),
                                  const SizedBox(height: 4),

                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      if (constraints.maxWidth < 350) {
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Đặt hàng: ${order.orderDate != null ? DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate!) : 'N/A'}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                            Text('Cập nhật: ${order.updatedDate != null ? DateFormat('dd/MM/yyyy HH:mm').format(order.updatedDate!) : 'N/A'}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                          ],
                                        );
                                      } else {
                                        return Row(
                                          children: [
                                            Expanded(
                                              flex: 1,
                                              child: Text('Đặt hàng: ${order.orderDate != null ? DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate!) : 'N/A'}', style: TextStyle(fontSize: 12, color: Colors.grey[700]), overflow: TextOverflow.ellipsis)
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Text('Cập nhật: ${order.updatedDate != null ? DateFormat('dd/MM/yyyy HH:mm').format(order.updatedDate!) : 'N/A'}', style: TextStyle(fontSize: 12, color: Colors.grey[700]), overflow: TextOverflow.ellipsis)
                                            ),
                                          ],
                                        );
                                      }
                                    }
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

        const SizedBox(height: 20),

        // Pagination controls
        if (_orders.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'Hiển thị ${_orders.isEmpty ? 0 : (_currentPage * _rowsPerPage) + 1} - ${(_currentPage * _rowsPerPage) + _orders.length} trên $_totalElements',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_left),
                      onPressed: _currentPage > 0 && _totalElements > 0
                          ? () {
                              setState(() {
                                _currentPage--;
                              });
                              _loadOrders();
                            }
                          : null,
                      tooltip: 'Trang trước',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        '${_currentPage + 1} / ${_totalPages > 0 ? _totalPages : 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_right),
                      onPressed: _currentPage < _totalPages - 1 && _totalElements > 0
                          ? () {
                              setState(() {
                                _currentPage++;
                              });
                              _loadOrders();
                            }
                          : null,
                      tooltip: 'Trang tiếp',
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}
