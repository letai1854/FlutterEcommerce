import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import để định dạng tiền tệ

// Thanh Payment Info (có thể là bản cuộn hoặc bản sticky)
class PaymentInfo extends StatelessWidget {
  // Dữ liệu và hàm tính toán
  final List<Map<String, dynamic>> cartItems;
  final double Function() calculateSubtotal; // Mặc dù không hiển thị trực tiếp, có thể cần cho tính toán khác
  final double Function() calculateTax;
  final double Function() calculateTotal;
  final double shippingFee;
  final double taxRate;

  // Callbacks
  final Function(bool) toggleSelectAll;
  final VoidCallback unselectAllItems; // Callback để bỏ chọn tất cả

  // Trạng thái
  final bool isSticky; // Xác định đây là bản sticky hay bản cuộn

  const PaymentInfo({
    Key? key,
    required this.cartItems,
    required this.calculateSubtotal, // Vẫn nhận vào dù không hiển thị trực tiếp
    required this.calculateTax,
    required this.calculateTotal,
    required this.shippingFee,
    required this.taxRate,
    required this.toggleSelectAll,
    required this.unselectAllItems,
    this.isSticky = false, // Mặc định là bản cuộn
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Tính toán các giá trị cần thiết
    final bool isAllSelected = cartItems.isNotEmpty && cartItems.every((item) => item['isSelected'] == true);
    final int selectedItemCount = cartItems.where((item) => item['isSelected'] == true).length;
    final double taxAmount = calculateTax();
    final double totalAmount = calculateTotal();
    // Định dạng tiền tệ Việt Nam
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    // Định dạng phần trăm
    final formatPercent = NumberFormat.percentPattern(); // Ví dụ: 0.05 -> 5%

    // --- Styles ---
    // Padding mặc định cho nội dung bên trong
    const EdgeInsets contentPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
    // Style cho tổng thanh toán
    const TextStyle totalAmountStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange);
    // Style cho các dòng text thông thường
    final TextStyle defaultTextStyle = Theme.of(context).textTheme.bodyMedium ?? const TextStyle(fontSize: 14);

    // --- Decoration cho thanh Sticky ---
    BoxDecoration? stickyDecoration = isSticky
        ? BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: Offset(0, -1),
              ),
            ],
            border: Border(top: BorderSide(color: Colors.grey.shade200, width: 0.5)),
          )
        : null;

    // --- Widget chính ---
    return Container(
      decoration: stickyDecoration,
      // Padding ngoài chỉ áp dụng cho bản cuộn
      padding: isSticky ? EdgeInsets.zero : const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 8.0),
      child: Material(
        color: isSticky ? Colors.transparent : Colors.white,
        borderRadius: isSticky ? null : BorderRadius.circular(8.0),
        elevation: isSticky ? 0 : 1.0,
        child: Padding(
          padding: contentPadding,
          child: Column( // Giữ cấu trúc Column gốc
            // crossAxisAlignment: CrossAxisAlignment.end, // Bỏ căn phải ở đây vì Row bên trong sẽ xử lý
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Hàng trên: Chọn tất cả / Bỏ chọn ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Căn đều 2 bên
                children: [
                  Row( // Nhóm Checkbox và Text "Chọn tất cả"
                    children: [
                      Checkbox(
                        value: isAllSelected,
                        onChanged: cartItems.isEmpty ? null : (value) => toggleSelectAll(value ?? false),
                        activeColor: Colors.deepOrange,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      GestureDetector(
                        onTap: cartItems.isEmpty ? null : () => toggleSelectAll(!isAllSelected),
                        child: Text(
                           'Chọn Tất Cả (${cartItems.length})',
                           style: defaultTextStyle, // Sử dụng style mặc định
                        ),
                      ),
                    ],
                  ),
                  // Nút Bỏ chọn (Chỉ hiển thị khi có item được chọn)
                  // Thay TextButton gốc bằng cái này để chỉ hiện khi cần
                  if (selectedItemCount > 0)
                    TextButton(
                      onPressed: unselectAllItems,
                      child: Text(
                        'Bỏ chọn (${selectedItemCount})', // Hiển thị số lượng đang chọn
                        style: defaultTextStyle.copyWith(color: Colors.blueAccent),
                      ),
                      style: TextButton.styleFrom(
                         padding: EdgeInsets.symmetric(horizontal: 8),
                         minimumSize: Size(0, 30)
                      ),
                    )
                  else // Placeholder để giữ khoảng trống nếu không có nút bỏ chọn
                    SizedBox(width: 80), // Điều chỉnh width nếu cần
                ],
              ),
              Divider(height: 16), // Thêm Divider giữa 2 phần

              // --- Hàng dưới: Thông tin thanh toán và nút (căn phải) ---
              // Sử dụng Row để căn phải nội dung bên trong nó
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // Căn toàn bộ nội dung sang phải
                children: [
                   Container( // Giữ Container và padding gốc
                      // padding: const EdgeInsets.only(right: 0), // Có thể bỏ padding này nếu Row đã căn phải
                      // alignment: Alignment.centerRight, // Row đã căn phải rồi
                      child: Column( // Giữ cấu trúc Column hiển thị thông tin
                        crossAxisAlignment: CrossAxisAlignment.end, // Căn phải text trong Column này
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // --- Các dòng thông tin ---
                          Text(
                            // Hiển thị cả % và số tiền thuế
                            'Thuế (${formatPercent.format(taxRate)}): ${formatCurrency.format(taxAmount)}',
                            style: defaultTextStyle,
                            textAlign: TextAlign.end,
                          ),
                          SizedBox(height: 4), // Khoảng cách nhỏ giữa các dòng
                          Text(
                            'Phí vận chuyển: ${formatCurrency.format(shippingFee)}',
                            style: defaultTextStyle,
                            textAlign: TextAlign.end,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tổng thanh toán: ${formatCurrency.format(totalAmount)}',
                            style: totalAmountStyle, // Style riêng cho tổng tiền
                            textAlign: TextAlign.end,
                          ),
                          const SizedBox(height: 12), // Khoảng cách trước nút

                          // --- Nút Mua Hàng ---
                          ElevatedButton(
                            onPressed: selectedItemCount > 0 ? () { // Chỉ enable khi có item được chọn
                              print('Proceed to Checkout');
                              print('Selected items: ${cartItems.where((i) => i['isSelected'] == true).map((i) => i['id']).toList()}');
                              print('Total: ${formatCurrency.format(totalAmount)}');
                              Navigator.pushNamed(context, '/payment');
                            } : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10), // Điều chỉnh padding nút
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            // Hiển thị số lượng item được chọn trên nút
                            child: Text('Mua Hàng (${selectedItemCount})'),
                          ),
                        ],
                      ),
                   ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
