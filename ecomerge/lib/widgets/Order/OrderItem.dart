import 'package:e_commerce_app/widgets/Order/OrderStatusHistoryPage.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data'; // Add this import
import 'package:e_commerce_app/database/services/categories_service.dart'; // Add this import

class OrderItem extends StatefulWidget {
  final String orderId;
  final String date;
  final List<Map<String, dynamic>> items;
  final String status;
  final bool isClickable;
  final VoidCallback? onViewHistory;
  final bool isSmallScreen; // Added parameter for screen size

  const OrderItem({
    Key? key,
    required this.orderId,
    required this.date,
    required this.items,
    required this.status,
    this.isClickable = false,
    this.onViewHistory,
    this.isSmallScreen = false, // Default to desktop layout
  }) : super(key: key);

  @override
  State<OrderItem> createState() => _OrderItemState();
}

class _OrderItemState extends State<OrderItem> {
  bool _expanded = false;
  bool _isHovering = false;
  final CategoriesService _categoriesService =
      CategoriesService(); // Add this line

  // Modified to handle both int and double types
  String _formatCurrency(dynamic amount) {
    // Convert to double regardless of whether it's an int or double
    final double value = amount is int ? amount.toDouble() : amount;

    return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total - ensure we convert values to double
    double total = widget.items.fold(0.0, (sum, item) {
      final dynamic price = item["price"];
      final int quantity = item["quantity"] as int;
      // Convert price to double if it's an int
      final double priceAsDouble = price is int ? price.toDouble() : price;
      return sum + (priceAsDouble * quantity);
    });

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
                  ? _buildMobileHeader() // Mobile layout
                  : _buildDesktopHeader(), // Desktop layout
            ),

            // First item (always visible)
            _buildOrderItemRow(widget.items[0]),

            // Additional items (collapsible)
            if (widget.items.length > 1) ...[
              // "See more" button if there are multiple items
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

            // Order total
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
                    "${_formatCurrency(total)} đ",
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

  // Desktop header layout - side by side
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
          // For narrower screens, use Column (stacked)
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

  // Mobile header layout - status below history button
  Widget _buildMobileHeader() {
    // Get screen width for better mobile detection
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhoneSize = screenWidth < 450; // More precise phone detection

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Order details
        Text(
          "Mã đơn hàng: ${widget.orderId}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text("Ngày mua: ${widget.date}"),
        const SizedBox(height: 12),

        // For phone-sized screens, force status indicator to appear below history button
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // History button row
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

            // Status indicator always on a separate row

            Align(
              alignment: Alignment.centerRight,
              child: _buildStatusIndicator(),
            ),
          ],
        ),
      ],
    );
  }

  // Extracted status indicator for reuse
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // Product image
          SizedBox(
            width: 80,
            height: 80,
            child: FutureBuilder<Uint8List?>(
              future: _categoriesService
                  .getImageFromServer(item["image"] as String?),
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
                    child: const Icon(Icons.error_outline, color: Colors.grey),
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

          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["name"],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text("Số lượng: x${item["quantity"]}"),
              ],
            ),
          ),

          // Price display - using the updated _formatCurrency method
          Text(
            "${_formatCurrency(item["price"])} đ",
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
