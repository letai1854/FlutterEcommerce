import 'package:e_commerce_app/widgets/Order/OrderStatusHistoryPage.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:e_commerce_app/database/services/categories_service.dart';

class OrderItem extends StatefulWidget {
  final String orderId;
  final String date;
  final List<Map<String, dynamic>> items;
  final String status;
  final bool isClickable;
  final VoidCallback? onViewHistory;
  final bool isSmallScreen;

  final double subtotal;
  final double shippingFee;
  final double tax;
  final double totalAmount;
  final double? couponDiscount;
  final double? pointsDiscount;
  final double? pointsEarned;

  const OrderItem({
    Key? key,
    required this.orderId,
    required this.date,
    required this.items,
    required this.status,
    this.isClickable = false,
    this.onViewHistory,
    this.isSmallScreen = false,
    required this.subtotal,
    required this.shippingFee,
    required this.tax,
    required this.totalAmount,
    this.couponDiscount,
    this.pointsDiscount,
    this.pointsEarned,
  }) : super(key: key);

  @override
  State<OrderItem> createState() => _OrderItemState();
}

class _OrderItemState extends State<OrderItem> {
  bool _expanded = false;
  bool _isHovering = false;
  final CategoriesService _categoriesService = CategoriesService();
  final Map<String, Future<Uint8List?>> _imageFutures = {};

  String _formatCurrency(dynamic amount) {
    final double value = amount is int ? amount.toDouble() : amount;
    if (value == 0.0 && amount is double && value.isNegative) {
      return "0";
    }
    return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  Widget _buildDetailRow(String label, dynamic value,
      {String unit = "đ",
      bool isDiscount = false,
      bool alwaysShowZero = false}) {
    if (value == null) return const SizedBox.shrink();
    double numericValue = 0.0;
    if (value is int) {
      numericValue = value.toDouble();
    } else if (value is double) {
      numericValue = value;
    } else {
      return const SizedBox.shrink();
    }

    if (!alwaysShowZero && numericValue == 0.0 && !isDiscount)
      return const SizedBox.shrink();
    if (isDiscount && numericValue == 0.0) return const SizedBox.shrink();

    String formattedValue;
    if (unit == "điểm") {
      // Divide by 1000 and then convert to int for display
      formattedValue = (numericValue / 1000).toInt().toString();
    } else {
      formattedValue = _formatCurrency(numericValue);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          Text(
            "${isDiscount ? '-' : ''}$formattedValue $unit",
            style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: widget.isClickable ? SystemMouseCursors.click : MouseCursor.defer,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isHovering ? Colors.grey.shade50 : Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          boxShadow: _isHovering
              ? [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: widget.isSmallScreen
                  ? _buildMobileHeader()
                  : _buildDesktopHeader(),
            ),
            _buildOrderItemRow(widget.items[0]),
            if (widget.items.length > 1) ...[
              ExpansionTile(
                title: const Text(
                  "Xem thêm sản phẩm",
                  style: TextStyle(fontSize: 14),
                ),
                onExpansionChanged: (value) {
                  setState(() {
                    _expanded = value;
                  });
                },
                children: [
                  for (int i = 1; i < widget.items.length; i++)
                    _buildOrderItemRow(widget.items[i]),
                ],
              ),
            ],
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  _buildDetailRow("Tạm tính:", widget.subtotal,
                      alwaysShowZero: true),
                  _buildDetailRow("Phí vận chuyển:", widget.shippingFee,
                      alwaysShowZero: true),
                  _buildDetailRow("Thuế:", widget.tax, alwaysShowZero: true),
                  if (widget.couponDiscount != null &&
                      widget.couponDiscount! > 0)
                    _buildDetailRow("Giảm giá coupon:", widget.couponDiscount,
                        isDiscount: true),
                  if (widget.pointsDiscount != null &&
                      widget.pointsDiscount! > 0)
                    _buildDetailRow("Giảm giá điểm:", widget.pointsDiscount,
                        isDiscount: true),
                  if (widget.pointsDiscount != null &&
                      widget.pointsDiscount! > 0)
                    _buildDetailRow("Điểm tích lũy:", widget.pointsDiscount,
                        unit: "điểm", isDiscount: true),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
                color: Colors.grey.shade50,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    "Thành tiền: ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${_formatCurrency(widget.totalAmount)} đ",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopHeader() {
    final screenWidth = MediaQuery.of(context).size.width;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Mã đơn hàng: ${widget.orderId}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text("Ngày mua: ${widget.date}"),
          ],
        ),
        if (screenWidth > 450)
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderStatusHistoryPage(
                        orderId: widget.orderId,
                        currentStatus: widget.status,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.history, size: 18),
                label: const Text("Lịch sử trạng thái"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 16),
              _buildStatusIndicator(),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderStatusHistoryPage(
                        orderId: widget.orderId,
                        currentStatus: widget.status,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.history, size: 18),
                label: const Text("Lịch sử trạng thái"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 8),
              _buildStatusIndicator(),
            ],
          ),
      ],
    );
  }

  Widget _buildMobileHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhoneSize = screenWidth < 450;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Mã đơn hàng: ${widget.orderId}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text("Ngày mua: ${widget.date}"),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderStatusHistoryPage(
                          orderId: widget.orderId,
                          currentStatus: widget.status,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text("Lịch sử trạng thái"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: _buildStatusIndicator(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.status == "Đã giao"
            ? Colors.green.shade50
            : (widget.status == "Đang giao"
                ? Colors.orange.shade50
                : Colors.blue.shade50),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        widget.status,
        style: TextStyle(
          color: widget.status == "Đã giao"
              ? Colors.green
              : (widget.status == "Đang giao" ? Colors.orange : Colors.blue),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOrderItemRow(Map<String, dynamic> item) {
    final String? imageUrl = item["image"] as String?;
    Future<Uint8List?>? imageFuture;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (!_imageFutures.containsKey(imageUrl)) {
        _imageFutures[imageUrl] =
            _categoriesService.getImageFromServer(imageUrl);
      }
      imageFuture = _imageFutures[imageUrl];
    }

    final dynamic priceAtPurchase = item["price"];
    final double productDiscountPercentage =
        (item["discountPercentage"] as num?)?.toDouble() ?? 0.0;
    final int quantity = item["quantity"] as int;

    double originalSinglePrice = 0.0;
    double discountedSinglePrice = 0.0;

    if (priceAtPurchase is num) {
      originalSinglePrice = priceAtPurchase.toDouble();
      if (productDiscountPercentage > 0) {
        discountedSinglePrice =
            originalSinglePrice * (1 - productDiscountPercentage / 100);
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: (imageUrl == null || imageUrl.isEmpty)
                ? Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.image_not_supported,
                        color: Colors.grey),
                  )
                : FutureBuilder<Uint8List?>(
                    future: imageFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2));
                      } else if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data == null) {
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.error_outline,
                              color: Colors.grey),
                        );
                      } else {
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(4),
                            image: DecorationImage(
                              image: MemoryImage(snapshot.data!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      }
                    },
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["name"],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text("Số lượng: x$quantity"),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (productDiscountPercentage > 0 &&
                  originalSinglePrice > 0 &&
                  discountedSinglePrice > 0) ...[
                Text(
                  "${_formatCurrency(originalSinglePrice)} đ",
                  style: TextStyle(
                    color: Colors.grey[600],
                    decoration: TextDecoration.lineThrough,
                    fontSize: 12,
                  ),
                ),
                Text(
                  "${_formatCurrency(discountedSinglePrice)} đ",
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ] else if (originalSinglePrice > 0) ...[
                Text(
                  "${_formatCurrency(originalSinglePrice)} đ",
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ] else ...[
                Text(
                  "N/A",
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ]
            ],
          )
        ],
      ),
    );
  }
}
