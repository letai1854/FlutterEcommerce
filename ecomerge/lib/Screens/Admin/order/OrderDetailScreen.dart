import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:e_commerce_app/database/models/order/OrderDTO.dart';
import 'package:e_commerce_app/database/services/order_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  final Map<String, dynamic>? order; // Optional pre-loaded order data

  const OrderDetailScreen({
    Key? key, 
    required this.orderId,
    this.order,
  }) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  OrderDTO? _order;
  final OrderService _orderService = OrderService();
  List<OrderStatusHistoryDTO> _statusHistory = [];
  bool _loadingHistory = false;

  // Add custom currency formatter
  String formatCurrency(double amount) {
    final format = amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    return '$format đ';
  }

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }
  
  @override
  void dispose() {
    _orderService.dispose();
    super.dispose();
  }
  
  Future<void> _loadOrderDetails() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }
    
    try {
      final order = await _orderService.getOrderDetailsForCurrentUser(widget.orderId);
      
      // Also load order status history
      try {
        setState(() {
          _loadingHistory = true;
        });
        final history = await _orderService.getOrderStatusHistoryForCurrentUser(widget.orderId);
        if (mounted) {
          setState(() {
            _statusHistory = history;
            _loadingHistory = false;
          });
        }
      } catch (e) {
        print('Error loading status history: $e');
        if (mounted) {
          setState(() {
            _loadingHistory = false;
          });
        }
      }
      
      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading order details: $e';
        });
      }
    }
  }

  // Helper function to build detail rows
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150, // Adjust width as needed
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // Translation function for order status notes - reusable across the app
  String _translateOrderNote(String? englishNote) {
    if (englishNote == null || englishNote.isEmpty) {
      return '';
    }
    
    String translatedNote = englishNote;
    
    // Extract points information if present
    int? pointsAwarded;
    if (englishNote.contains('Points awarded:')) {
      final pointsMatch = RegExp(r'Points awarded: (\d+)').firstMatch(englishNote);
      if (pointsMatch != null && pointsMatch.groupCount >= 1) {
        pointsAwarded = int.tryParse(pointsMatch.group(1)!);
      }
    }
    
    // Standard message translations
    final Map<String, String> commonPhrases = {
      'Order created successfully': 'Đơn hàng đã được tạo thành công',
      'Order status updated by admin': 'Trạng thái đơn hàng đã được cập nhật bởi quản trị viên',
      'Order status updated by system': 'Trạng thái đơn hàng đã được cập nhật bởi hệ thống',
      'Order cancelled': 'Đơn hàng đã bị hủy',
      'Order processed': 'Đơn hàng đã được xử lý',
      'Order confirmed': 'Đơn hàng đã được xác nhận',
      'Order is being shipped': 'Đơn hàng đang được giao',
      'Order delivered successfully': 'Đơn hàng đã giao thành công',
    };
    
    // Payment status translations
    final Map<String, String> paymentStatuses = {
      'Payment status updated to': 'Trạng thái thanh toán cập nhật thành',
      'da_thanh_toan': 'đã thanh toán',
      'chua_thanh_toan': 'chưa thanh toán',
      'hoan_tien': 'hoàn tiền',
    };
    
    // Apply all translations
    commonPhrases.forEach((english, vietnamese) {
      translatedNote = translatedNote.replaceAll(english, vietnamese);
    });
    
    paymentStatuses.forEach((english, vietnamese) {
      translatedNote = translatedNote.replaceAll(english, vietnamese);
    });
    
    // Format points information separately for better visibility
    if (pointsAwarded != null) {
      translatedNote = translatedNote.replaceAll(
        'Points awarded: $pointsAwarded', 
        'Tặng điểm tích lũy: $pointsAwarded điểm'
      );
    }
    
    return translatedNote;
  }

  // Convert status code to Vietnamese display text - reusable across the app
  String _getOrderStatusDisplay(String status) {
    final Map<String, String> statusDisplay = {
      'cho_xu_ly': 'Chờ xử lý',
      'da_xac_nhan': 'Đã xác nhận',
      'dang_giao': 'Đang giao',
      'da_giao': 'Đã giao',
      'da_huy': 'Đã hủy',
    };
    return statusDisplay[status.toLowerCase()] ?? status;
  }

  // Get appropriate status icon based on status - reusable across the app
  IconData _getStatusIcon(String status) {
    final Map<String, IconData> statusIcons = {
      'cho_xu_ly': Icons.hourglass_empty,
      'da_xac_nhan': Icons.check_circle_outline,
      'dang_giao': Icons.local_shipping,
      'da_giao': Icons.done_all,
      'da_huy': Icons.cancel,
    };
    return statusIcons[status.toLowerCase()] ?? Icons.circle;
  }
  
  // Get appropriate status color based on status - reusable across the app
  Color _getStatusColor(String status) {
    final Map<String, Color> statusColors = {
      'cho_xu_ly': Colors.orange,
      'da_xac_nhan': Colors.blue,
      'dang_giao': Colors.indigo,
      'da_giao': Colors.green,
      'da_huy': Colors.red,
    };
    return statusColors[status.toLowerCase()] ?? Colors.blue;
  }

  Widget _buildStatusHistoryTimeline() {
    if (_loadingHistory) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_statusHistory.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Không có lịch sử trạng thái'),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _statusHistory.length,
      itemBuilder: (context, index) {
        final item = _statusHistory[index];
        final isLast = index == _statusHistory.length - 1;
        final statusColor = _getStatusColor(item.status);
        final statusIcon = _getStatusIcon(item.status);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(left: 16, right: 16),
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, size: 12, color: Colors.white),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getOrderStatusDisplay(item.status), 
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(item.timestamp.toLocal()),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      if (item.notes != null && item.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _translateOrderNote(item.notes!),
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                )
              ],
            ),
            if (!isLast)
              Container(
                height: 30,
                width: 2,
                margin: EdgeInsets.only(left: 24),
                color: Colors.grey[300],
              ),
          ],
        );
      },
    );
  }

  // Enhanced image display widget with better error handling and retry
  Widget _buildImageDisplayWidget(String? imageSource, {double size = 40, double iconSize = 30}) {
    if (imageSource == null || imageSource.isEmpty) {
      return Icon(Icons.image_not_supported, size: iconSize, color: Colors.grey);
    }
    
    // Check if image is already cached
    // final cachedImage = _orderService.getImageFromCache(imageSource);
    // if (cachedImage != null) {
    //   return Image.memory(
    //     cachedImage,
    //     fit: BoxFit.cover,
    //     width: size,
    //     height: size,
    //   );
    // }

    return FutureBuilder<Uint8List?>(
      future: _orderService.getImageFromServer(imageSource, forceReload: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: size,
            height: size,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return GestureDetector(
            onTap: () {
              // Retry loading on tap
              setState(() {}); // Force rebuild to retry
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image, size: iconSize * 0.8, color: Colors.red),
                Text(
                  'Retry',
                  style: TextStyle(fontSize: 8, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }
        
        return Image.memory(
          snapshot.data!,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) {
            print('Error rendering image: $error');
            return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
          },
        );
      },
    );
  }

  // Before building the product list, preload all images
  Future<void> _preloadProductImages() async {
    if (_order == null || _order!.orderDetails == null) return;
    
    for (final item in _order!.orderDetails!) {
      if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
        try {
          await _orderService.getImageFromServer(item.imageUrl);
        } catch (e) {
          print('Failed to preload image ${item.imageUrl}: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Chi tiết đơn hàng #${widget.orderId}'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Chi tiết đơn hàng #${widget.orderId}'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red),
              SizedBox(height: 16),
              Text(_errorMessage, textAlign: TextAlign.center),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadOrderDetails,
                child: Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_order == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Chi tiết đơn hàng #${widget.orderId}'),
        ),
        body: const Center(child: Text('Không tìm thấy thông tin đơn hàng')),
      );
    }
    
    final order = _order!;
    final orderItems = order.orderDetails ?? [];
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết đơn hàng #${order.id}'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrderDetails,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thông tin chung',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              _buildDetailRow('Mã đơn hàng', '#${order.id}'),
              _buildDetailRow('Ngày đặt hàng', order.orderDate != null ? dateFormat.format(order.orderDate!) : 'N/A'),
              _buildDetailRow('Ngày cập nhật', order.updatedDate != null ? dateFormat.format(order.updatedDate!) : 'N/A'),
              _buildDetailRow('Trạng thái đơn hàng', order.orderStatus != null ? _getOrderStatusDisplay(orderStatusToString(order.orderStatus!)) : 'N/A'),
              _buildDetailRow('Trạng thái thanh toán', order.paymentStatus ?? 'N/A'),
              _buildDetailRow('Phương thức thanh toán', order.paymentMethod ?? 'N/A'),
              
              const SizedBox(height: 20),
              
              Text(
                'Thông tin người nhận',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              _buildDetailRow('Tên người nhận', order.recipientName ?? 'N/A'),
              _buildDetailRow('Số điện thoại', order.recipientPhoneNumber ?? 'N/A'),
              _buildDetailRow('Địa chỉ giao hàng', order.shippingAddress ?? 'N/A'),
              
              const SizedBox(height: 20),
              
              Text(
                'Giá trị đơn hàng',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              _buildDetailRow('Tổng tiền hàng', formatCurrency(order.subtotal ?? 0)),
              _buildDetailRow('Tiền giảm giá Coupon', formatCurrency(order.couponDiscount ?? 0)),
              _buildDetailRow('Tiền sử dụng điểm', formatCurrency(order.pointsDiscount ?? 0)),
              _buildDetailRow('Phí vận chuyển', formatCurrency(order.shippingFee ?? 0)),
              _buildDetailRow('Thuế', formatCurrency(order.tax ?? 0)),
              _buildDetailRow('Tổng thanh toán', formatCurrency(order.totalAmount ?? 0)),
              _buildDetailRow('Điểm tích lũy', '${order.pointsEarned ?? 0} điểm'),
              
              const SizedBox(height: 20),
              
              Text(
                'Lịch sử trạng thái',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              _buildStatusHistoryTimeline(),
              
              const SizedBox(height: 20),
              
              Text(
                'Danh sách sản phẩm',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              orderItems.isEmpty
                ? const Text('Chưa có sản phẩm trong đơn hàng này.')
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orderItems.length,
                    itemBuilder: (context, index) {
                      final item = orderItems[index];
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.grey[200],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: _buildImageDisplayWidget(item.imageUrl, size: 60),
                              ),
                              const SizedBox(width: 8),
                              
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (item.productName ?? 'Sản phẩm') + (item.variantName != null ? ' - ${item.variantName}' : ''),
                                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Số lượng: ${item.quantity}', style: TextStyle(fontSize: 13)),
                                    Text('Giá lúc mua: ${formatCurrency(item.priceAtPurchase)}', style: TextStyle(fontSize: 13)),
                                    if (item.productDiscountPercentage != null && item.productDiscountPercentage! > 0)
                                      Text('Giảm giá SP: ${item.productDiscountPercentage!.toStringAsFixed(0)}%', style: TextStyle(fontSize: 13)),
                                    Text('Thành tiền: ${formatCurrency(item.lineTotal)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
