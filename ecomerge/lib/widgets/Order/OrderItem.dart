import 'package:flutter/material.dart';

class OrderItem extends StatefulWidget {
  final String orderId;
  final String date;
  final List<Map<String, dynamic>> items;
  final String status;
  final VoidCallback? onViewHistory;

  const OrderItem({
    Key? key,
    required this.orderId,
    required this.date,
    required this.items,
    required this.status,
    this.onViewHistory,
  }) : super(key: key);

  @override
  State<OrderItem> createState() => _OrderItemState();
}

class _OrderItemState extends State<OrderItem> {
  bool _expanded = false;

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    double total = widget.items
        .fold(0, (sum, item) => sum + (item["price"] * item["quantity"]));

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
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
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: widget.onViewHistory,
                      icon: const Icon(Icons.history, size: 18),
                      label: const Text("Lịch sử trạng thái"),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.status == "Đã giao hàng"
                            ? Colors.green.shade50
                            : (widget.status == "Đang giao hàng"
                                ? Colors.orange.shade50
                                : Colors.blue.shade50),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.status,
                        style: TextStyle(
                          color: widget.status == "Đã giao hàng"
                              ? Colors.green
                              : (widget.status == "Đang giao hàng"
                                  ? Colors.orange
                                  : Colors.blue),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(item["image"]),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(4),
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

          // Price
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
