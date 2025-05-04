
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForTablet.dart'; // Giả sử đường dẫn đúng
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForMobile.dart'; // Giả sử đường dẫn đúng
import 'package:e_commerce_app/widgets/Payment/PaymentSuccess.dart';
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart'; // Giả sử đường dẫn đúng
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import intl ở đây nếu cần format trước khi truyền (không cần nữa)

class Pagesuccesspayment extends StatefulWidget {
  const Pagesuccesspayment({super.key});

  @override
  State<Pagesuccesspayment> createState() => _PagesuccesspaymentState();
}

class _PagesuccesspaymentState extends State<Pagesuccesspayment> {
  // --- Di chuyển orderData ra ngoài build để có thể truy cập dễ dàng ---
  // Dữ liệu đơn hàng giả lập
  final Map<String, dynamic> orderData = {
    'customerID': 'KH12345678',
    'customerName': 'Tuấn Tú',
    'address': 'Gần Nhà Thờ An Phú An Giang, Thị Trấn An Phú, Huyện An Phú, An Giang',
    'phone': '(+84) 583541716',
    'orderID': 'SHOP2024061500123',
    'createdTime': DateTime.now(),
    'paymentMethod': 'Thanh toán khi nhận hàng',
    'itemsTotal': 42000,
    'shippingFee': 30000,
    'tax': 4200, // 10% của itemsTotal
    'discount': 0,
    'totalAmount': 76200, // itemsTotal + shippingFee + tax - discount
  };

  @override
  Widget build(BuildContext context) {
    // --- Không cần _formatCurrency ở đây nữa ---
    // String _formatCurrency(num amount) {
    //   final formatter = NumberFormat("#,###", "vi_VN");
    //   return '₫${formatter.format(amount)}';
    // }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        Widget appBar;
        // *** Truyền orderData vào bodySuccessPayment ***
        Widget body = bodySuccessPayment(
          orderData: orderData, // Truyền dữ liệu vào đây
        );

        if (screenWidth < 768) {
          // Mobile layout
          return NavbarFormobile( // Giả sử NavbarFixmobile là Scaffold chứa AppBar và body
            body: body,
            // title: 'Thanh toán', // Có thể thêm title cho AppBar
          );
        } else if (screenWidth < 1100) {
          // Tablet layout
          return NavbarForTablet( // Giả sử NavbarFixTablet tương tự
            body: body,
             // title: 'Thanh toán',
          );
        } else {
          // Desktop layout
          appBar = PreferredSize(
            preferredSize: Size.fromHeight(130),
            child: Navbarhomedesktop(), // Giả sử Navbarhomedesktop là widget bạn đã tạo
          );
          return Scaffold(
            appBar: appBar as PreferredSize,
            body: body,
          );
        }
      },
    );
  }
}


