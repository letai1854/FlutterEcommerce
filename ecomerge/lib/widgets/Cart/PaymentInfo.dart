import 'package:e_commerce_app/database/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import để định dạng tiền tệ
import 'package:e_commerce_app/database/Storage/UserInfo.dart'; // Add import for UserInfo
import 'package:e_commerce_app/database/models/CartDTO.dart';

// Thanh Payment Info (có thể là bản cuộn hoặc bản sticky)
class PaymentInfo extends StatelessWidget {
  // Dữ liệu và hàm tính toán
  final List<CartItemDTO> cartItems;
  final Map<int?, bool> selectedItems;
  final double Function() calculateSubtotal;
  final double Function() calculateTax;
  final double Function() calculateTotal;
  final double shippingFee;
  final double taxRate;

  // Callbacks
  final Function(bool) toggleSelectAll;
  final VoidCallback unselectAllItems; // Callback để bỏ chọn tất cả
  final VoidCallback onProceedToPayment; // Add this parameter

  // Trạng thái
  final bool isSticky; // Xác định đây là bản sticky hay bản cuộn

  const PaymentInfo({
    Key? key,
    required this.cartItems,
    required this.selectedItems,
    required this.calculateSubtotal,
    required this.calculateTax,
    required this.calculateTotal,
    required this.shippingFee,
    required this.taxRate,
    required this.toggleSelectAll,
    required this.unselectAllItems,
    required this.onProceedToPayment, // Add this parameter
    this.isSticky = false, // Mặc định là bản cuộn
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Tính toán các giá trị cần thiết
    final bool isAllSelected = selectedItems.isNotEmpty && 
                               selectedItems.values.every((isSelected) => isSelected == true);
    final int selectedItemCount = selectedItems.values.where((isSelected) => isSelected).length;
    final int totalItems = cartItems.length;
    final double taxAmount = calculateTax();
    final double totalAmount = calculateTotal();
    // Định dạng tiền tệ Việt Nam
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    // Định dạng phần trăm
    final formatPercent = NumberFormat.percentPattern(); // Ví dụ: 0.05 -> 5%

    // --- Styles ---
    // Padding mặc định cho nội dung bên trong
    const EdgeInsets contentPadding =
        EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
    // Style cho tổng thanh toán
    const TextStyle totalAmountStyle = TextStyle(
        fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange);
    // Style cho các dòng text thông thường
    final TextStyle defaultTextStyle =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle(fontSize: 14);

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
            border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 0.5)),
          )
        : null;

    // --- Widget chính ---
    return Container(
      decoration: stickyDecoration,
      // Padding ngoài chỉ áp dụng cho bản cuộn
      padding: isSticky
          ? EdgeInsets.zero
          : const EdgeInsets.only(
              left: 16.0, right: 16.0, top: 8.0, bottom: 8.0),
      child: Material(
        color: isSticky ? Colors.transparent : Colors.white,
        borderRadius: isSticky ? null : BorderRadius.circular(8.0),
        elevation: isSticky ? 0 : 1.0,
        child: Padding(
          padding: contentPadding,
          child: Column(
            // Giữ cấu trúc Column gốc
            // crossAxisAlignment: CrossAxisAlignment.end, // Bỏ căn phải ở đây vì Row bên trong sẽ xử lý
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Hàng trên: Chọn tất cả / Bỏ chọn ---
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // Căn đều 2 bên
                children: [
                  Row(
                    // Nhóm Checkbox và Text "Chọn tất cả"
                    children: [
                      Checkbox(
                        value: isAllSelected,
                        onChanged: cartItems.isEmpty
                            ? null
                            : (value) => toggleSelectAll(value ?? false),
                        activeColor: Colors.deepOrange,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      GestureDetector(
                        onTap: cartItems.isEmpty
                            ? null
                            : () => toggleSelectAll(!isAllSelected),
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
                        style:
                            defaultTextStyle.copyWith(color: Colors.blueAccent),
                      ),
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size(0, 30)),
                    )
                  else // Placeholder để giữ khoảng trống nếu không có nút bỏ chọn
                    SizedBox(width: 80), // Điều chỉnh width nếu cần
                ],
              ),
              Divider(height: 16), // Thêm Divider giữa 2 phần

              // --- Hàng dưới: Thông tin thanh toán và nút (căn phải) ---
              // Sử dụng Row để căn phải nội dung bên trong nó
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.end, // Căn toàn bộ nội dung sang phải
                children: [
                  Container(
                    // Giữ Container và padding gốc
                    // padding: const EdgeInsets.only(right: 0), // Có thể bỏ padding này nếu Row đã căn phải
                    // alignment: Alignment.centerRight, // Row đã căn phải rồi
                    child: Column(
                      // Giữ cấu trúc Column hiển thị thông tin
                      crossAxisAlignment: CrossAxisAlignment
                          .end, // Căn phải text trong Column này
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
                          onPressed: selectedItemCount > 0 
                              ? onProceedToPayment // Use the callback
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 10), // Điều chỉnh padding nút
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            textStyle: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
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

  // Helper method for email login dialog
  void _showEmailLoginDialog(
      BuildContext context, double totalAmount, NumberFormat formatCurrency) {
    final TextEditingController emailController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  'Nhập email để tiếp tục',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Email input field with validation
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Nhập địa chỉ email của bạn',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    // Regular expression for email validation
                    final emailRegex =
                        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 24),

                // Total amount display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng thanh toán:',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      formatCurrency.format(totalAmount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        // Validate form before proceeding
                        if (formKey.currentState!.validate()) {
                          final email = emailController.text.trim();
                          // Close the dialog
                          Navigator.pop(context);

                          // Register the user as a guest with random credentials
                          // _registerGuestUser(context, email).then((success) {
                          //   if (success) {
                          // If registration successful, navigate to payment
                          Navigator.pushNamed(
                            context, '/payment',
                            arguments: {'email': email},
                            // } else {
                            //   // If registration failed, show error
                            //   ScaffoldMessenger.of(context).showSnackBar(
                            //     const SnackBar(
                            //       content: Text(
                            //           'Không thể tiếp tục với email này. Vui lòng thử lại.'),
                            //       backgroundColor: Colors.red,
                            //     ),
                            //   );
                            // }
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Tiếp tục'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Add method to register guest user
  Future<bool> _registerGuestUser(BuildContext context, String email) async {
    final userService = UserService();

    try {
      // Register the guest user with random credentials
      final result = await userService.registerGuestUser(email);

      if (result) {
        // Show success message
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text('Đã tạo tài khoản tạm thời để mua hàng'),
        //     backgroundColor: Colors.green,
        //   ),
        // );
      }

      return result;
    } catch (e) {
      print('Error registering guest user: $e');
      return false;
    }
  }
}
