import 'package:e_commerce_app/widgets/Cart/CartItemList.dart';
import 'package:e_commerce_app/widgets/Cart/PaymentInfo.dart';
import 'package:e_commerce_app/widgets/footer.dart'; // Đảm bảo import Footer nếu bạn có
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';

class BodyCart extends StatelessWidget {
  // Data and State
  final List<Map<String, dynamic>> cartItems;
  final double taxRate;
  final double shippingFee;
  final ScrollController scrollController; // Controls the main scroll view
  final ValueNotifier<bool> isPaymentInfoBottomVisible; // Controls sticky bar visibility
  final GlobalKey paymentInfoKey; // Key to track the scrollable PaymentInfo

  // Callbacks for Cart Actions
  final Function(int) toggleSelectItem;
  final Function(int) increaseQuantity;
  final Function(int) decreaseQuantity;
  final Function(int) removeItem;
  final Function(bool) toggleSelectAll;
  final Function() unselectAllItems; // Callback to unselect all

  // Calculation Functions
  final double Function() calculateSubtotal;
  final double Function() calculateTax;
  final double Function() calculateTotal;

  const BodyCart({
    Key? key,
    required this.cartItems,
    required this.taxRate,
    required this.shippingFee,
    required this.scrollController,
    required this.isPaymentInfoBottomVisible,
    required this.paymentInfoKey,
    required this.toggleSelectItem,
    required this.increaseQuantity,
    required this.decreaseQuantity,
    required this.removeItem,
    required this.toggleSelectAll,
    required this.unselectAllItems,
    required this.calculateSubtotal,
    required this.calculateTax,
    required this.calculateTotal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Đặt màu nền chung nếu muốn, ví dụ: màu xám nhạt
      // backgroundColor: Colors.grey.shade100,
      body: Stack(
        children: [
          // --- Main Scrollable Content ---
          CustomScrollView( // Sử dụng CustomScrollView để linh hoạt hơn
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Danh sách sản phẩm trong giỏ hàng ---
                    CartItemList(
                      cartItems: cartItems,
                      toggleSelectItem: toggleSelectItem,
                      increaseQuantity: increaseQuantity,
                      decreaseQuantity: decreaseQuantity,
                      removeItem: removeItem,
                    ),

                    // --- Thanh PaymentInfo cuộn theo nội dung ---
                    // Chỉ hiển thị khi giỏ hàng không trống
                    if (cartItems.isNotEmpty)
                       PaymentInfo(
                          key: paymentInfoKey, // Gắn key để theo dõi vị trí
                          cartItems: cartItems,
                          calculateTax: calculateTax,
                          calculateTotal: calculateTotal,
                          calculateSubtotal: calculateSubtotal,
                          shippingFee: shippingFee,
                          taxRate: taxRate,
                          toggleSelectAll: toggleSelectAll,
                          unselectAllItems: unselectAllItems,
                          isSticky: false, // Đánh dấu đây là bản cuộn
                       ),

                     // --- Footer hoặc Khoảng trống dưới cùng ---
                     // Hiển thị Footer trên web khi có item, hoặc thêm khoảng trống
                     if (kIsWeb && cartItems.isNotEmpty)
                       const Footer() // Giả sử bạn có widget Footer
                     else if (cartItems.isEmpty)
                       // Nếu giỏ hàng trống, tạo khoảng trống đủ để nội dung không bị quá ngắn
                       Container(height: MediaQuery.of(context).size.height * 0.3) // Ví dụ: 30% chiều cao màn hình
                     else
                       // Nếu có item, tạo khoảng trống đủ để không bị che bởi thanh sticky
                       SizedBox(height: 90), // Chiều cao đủ lớn hơn thanh sticky dự kiến
                  ],
                ),
              ),
            ],
          ),

          // --- Thanh PaymentInfo Sticky ở dưới cùng ---
          ValueListenableBuilder<bool>(
            valueListenable: isPaymentInfoBottomVisible, // Lắng nghe thay đổi visibility
            builder: (context, isVisible, child) {
              // Chỉ hiển thị nếu isVisible là true VÀ giỏ hàng không trống
              if (!isVisible || cartItems.isEmpty) {
                 return const SizedBox.shrink(); // Không hiển thị gì cả
              }
              // Nếu điều kiện thỏa mãn, hiển thị child (là PaymentInfo sticky)
              return Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: child!,
              );
            },
            // Widget PaymentInfo sticky được tạo một lần và truyền vào builder
            child: PaymentInfo(
              // Không cần key cho bản sticky
              cartItems: cartItems,
              calculateTax: calculateTax,
              calculateTotal: calculateTotal,
              calculateSubtotal: calculateSubtotal,
              shippingFee: shippingFee,
              taxRate: taxRate,
              toggleSelectAll: toggleSelectAll,
              unselectAllItems: unselectAllItems,
              isSticky: true, // Đánh dấu đây là bản sticky
            ),
          ),
        ],
      ),
    );
  }
}
