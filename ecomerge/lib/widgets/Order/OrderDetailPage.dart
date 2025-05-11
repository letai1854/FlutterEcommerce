import 'dart:typed_data';
import 'package:e_commerce_app/database/models/order/OrderDTO.dart';
import 'package:e_commerce_app/database/services/categories_service.dart';
import 'package:e_commerce_app/database/services/order_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class OrderDetailPage extends StatefulWidget {
  final String orderId;

  const OrderDetailPage({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  _OrderDetailPageState createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final OrderService _orderService = OrderService();
  final CategoriesService _categoriesService = CategoriesService();
  OrderDTO? _orderData;
  bool _isLoading = true;
  String? _errorMessage;
  final Map<String, Future<Uint8List?>> _imageFutures = {};
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final orderDetails = await _orderService
          .getOrderDetailsForCurrentUser(int.parse(widget.orderId));
      setState(() {
        _orderData = orderDetails;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Lỗi tải chi tiết đơn hàng: ${e.toString()}";
      });
    }
  }

  String _formatCurrency(double? amount) {
    if (amount == null) return "0";
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
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

  Color _getStatusColor(OrderStatus? status) {
    final displayStatus = _getDisplayStatus(status);
    switch (displayStatus) {
      case "Đã giao":
        return Colors.green;
      case "Đang giao":
        return Colors.orange;
      case "Đã hủy":
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Future<void> _cancelOrder() async {
    if (_orderData == null) return;

    setState(() {
      _isCancelling = true;
      _errorMessage = null;
    });

    try {
      final cancelledOrder =
          await _orderService.cancelOrderForCurrentUser(_orderData!.id);
      setState(() {
        _orderData = cancelledOrder; // Update with the new order status
        _isCancelling = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đơn hàng đã được hủy thành công."),
          backgroundColor: Colors.green,
        ),
      );
      // Refresh data without full loading spinner for the current page
      _fetchOrderDetails(showLoading: false);

      // Pop with true to indicate success and trigger refresh on the previous page
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isCancelling = false;
        _errorMessage = "Lỗi hủy đơn hàng: ${e.toString()}";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi hủy đơn hàng: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Chi tiết đơn hàng",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.red,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Chi tiết đơn hàng",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.red,
          elevation: 0,
        ),
        body: Center(
            child: Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
        )),
      );
    }

    if (_orderData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Chi tiết đơn hàng",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.red,
          elevation: 0,
        ),
        body: const Center(child: Text("Không tìm thấy thông tin đơn hàng.")),
      );
    }

    final order = _orderData!;
    final displayStatus = _getDisplayStatus(order.orderStatus);
    final statusColor = _getStatusColor(order.orderStatus);
    final orderDateFormatted = order.orderDate != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate!.toLocal())
        : 'N/A';

    final int totalQuantity = order.orderDetails?.fold<int>(
            0, (int sum, OrderDetailItemDTO item) => sum + item.quantity) ??
        0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Chi tiết đơn hàng",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.red,
              padding: const EdgeInsets.only(
                  left: 20, right: 20, bottom: 30, top: 10),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Mã đơn hàng: ${order.id}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Ngày đặt hàng: $orderDateFormatted",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: statusColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          displayStatus,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              const Text(
                                "Thông tin nhận hàng",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Text(
                            "Người nhận: ${order.recipientName ?? 'N/A'}",
                            style: const TextStyle(fontSize: 15),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Số điện thoại: ${order.recipientPhoneNumber ?? 'N/A'}",
                            style: const TextStyle(fontSize: 15),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Địa chỉ: ${order.shippingAddress ?? 'N/A'}",
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.shopping_bag, color: Colors.red[700]),
                              const SizedBox(width: 8),
                              const Text(
                                "Sản phẩm đã đặt",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          ...(order.orderDetails ?? [])
                              .map((item) => _buildProductItem(item))
                              .toList(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.receipt_long,
                                  color: Colors.green[700]),
                              const SizedBox(width: 8),
                              const Text(
                                "Thông tin thanh toán",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Tổng số lượng:"),
                              Text(
                                "$totalQuantity sản phẩm",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Tạm tính:"),
                              Text("${_formatCurrency(order.subtotal)} đ"),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Phí vận chuyển:"),
                              Text("${_formatCurrency(order.shippingFee)} đ"),
                            ],
                          ),
                          if (order.tax != null && order.tax! > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Thuế:"),
                                Text("${_formatCurrency(order.tax)} đ"),
                              ],
                            ),
                          ],
                          if (order.couponDiscount != null &&
                              order.couponDiscount! > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Giảm giá coupon:"),
                                Text(
                                    "- ${_formatCurrency(order.couponDiscount)} đ",
                                    style:
                                        const TextStyle(color: Colors.green)),
                              ],
                            ),
                          ],
                          if (order.pointsDiscount != null &&
                              order.pointsDiscount! > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Giảm giá điểm:"),
                                Text(
                                    "- ${_formatCurrency(order.pointsDiscount)} đ",
                                    style:
                                        const TextStyle(color: Colors.green)),
                              ],
                            ),
                          ],
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Tổng cộng:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "${_formatCurrency(order.totalAmount)} đ",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Only show cancel button if status is "Chờ xử lý"
                  if (displayStatus == "Chờ xử lý")
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: _isCancelling
                              ? const CircularProgressIndicator()
                              : ElevatedButton.icon(
                                  onPressed: _cancelOrder,
                                  icon: const Icon(Icons.cancel),
                                  label: const Text("Hủy đơn hàng"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24, // Increased padding
                                      vertical: 12,
                                    ),
                                    textStyle: const TextStyle(
                                        fontSize: 16), // Larger text
                                  ),
                                ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(OrderDetailItemDTO item) {
    final String? imageUrl = item.imageUrl;
    Future<Uint8List?>? imageFuture;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (!_imageFutures.containsKey(imageUrl)) {
        _imageFutures[imageUrl] =
            _categoriesService.getImageFromServer(imageUrl);
      }
      imageFuture = _imageFutures[imageUrl];
    }

    double originalPricePerUnit = item.priceAtPurchase;
    double? finalDiscountedPricePerUnit;

    if (item.productDiscountPercentage != null &&
        item.productDiscountPercentage! > 0) {
      finalDiscountedPricePerUnit = originalPricePerUnit *
          (1 - (item.productDiscountPercentage! / 100.0));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (imageUrl == null ||
                      imageUrl.isEmpty ||
                      imageFuture == null)
                  ? Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported,
                          color: Colors.grey),
                    )
                  : FutureBuilder<Uint8List?>(
                      future: imageFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2));
                        } else if (snapshot.hasError ||
                            !snapshot.hasData ||
                            snapshot.data == null) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image,
                                color: Colors.grey),
                          );
                        } else {
                          return Image.memory(
                            snapshot.data!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          );
                        }
                      },
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName ?? 'N/A',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.variantName != null &&
                    item.variantName!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    "Phân loại: ${item.variantName}",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 4),
                if (finalDiscountedPricePerUnit != null) ...[
                  Text(
                    "${_formatCurrency(originalPricePerUnit)} đ",
                    style: TextStyle(
                      color: Colors.grey[500],
                      decoration: TextDecoration.lineThrough,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    "${_formatCurrency(finalDiscountedPricePerUnit)} đ",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ] else ...[
                  Text(
                    "${_formatCurrency(originalPricePerUnit)} đ",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  "Số lượng: ${item.quantity}",
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
