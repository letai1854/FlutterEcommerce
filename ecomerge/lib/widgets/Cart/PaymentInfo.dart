import 'package:flutter/material.dart';
// Thanh Payment Info (thanh chính và mép dưới)
class PaymentInfo extends StatelessWidget {
  const PaymentInfo({
    Key? key,
    required this.cartItems,
    required this.calculateTax,
    required this.calculateTotal,
    required this.calculateSubtotal,
    required this.shippingFee,
    required this.taxRate,
    required this.toggleSelectAll,
    required this.unselectAllItems,
  }) : super(key: key);

  final List<Map<String, dynamic>> cartItems;
  final double Function() calculateTax;
  final double Function() calculateTotal;
  final double Function() calculateSubtotal;
  final double shippingFee;
  final double taxRate;
  final Function(bool) toggleSelectAll;
  final VoidCallback unselectAllItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -3), // Shadow phía trên
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Phần chọn tất cả, bỏ chọn
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Checkbox(
                value: cartItems.isNotEmpty &&
                    cartItems.every((item) => item['isSelected']),
                onChanged: cartItems.isNotEmpty
                    ? (bool? value) {
                  toggleSelectAll(value ?? false);
                }
                    : null,
              ),
              Text('Chọn Tất Cả (${cartItems.length})'),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () {
                  unselectAllItems();
                },
                child: const Text('Bỏ chọn sản phẩm'),
              ),
            ],
          ),
          // Thông tin thanh toán và nút mua hàng (căn phải)
          Container(
            padding: const EdgeInsets.only(right: 50),
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Thuế: ${taxRate * 100}%: ₫${calculateTax().toStringAsFixed(0)}',
                  textAlign: TextAlign.end,
                ),
                Text(
                  'Phí vận chuyển: ₫${shippingFee.toString()}',
                  textAlign: TextAlign.end,
                ),
                Text(
                  'Tổng thanh toán: ₫${calculateTotal().toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.end,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Xử lý khi nhấn nút "Mua Hàng"
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Mua Hàng'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



