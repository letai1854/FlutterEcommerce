import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForTablet.dart'; // Giả sử đường dẫn đúng
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForMobile.dart'; // Giả sử đường dẫn đúng
import 'package:e_commerce_app/widgets/Payment/PaymentSuccess.dart';
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart'; // Giả sử đường dẫn đúng
import 'package:flutter/material.dart';
// import 'package:intl/intl.dart'; // Comment out or remove if not used by other parts of this file

class Pagesuccesspayment extends StatefulWidget {
  const Pagesuccesspayment({super.key});

  @override
  State<Pagesuccesspayment> createState() => _PagesuccesspaymentState();
}

class _PagesuccesspaymentState extends State<Pagesuccesspayment> {
  @override
  Widget build(BuildContext context) {
    // --- Retrieve orderData from arguments ---
    final Map<String, dynamic>? routeArgs =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Provide default empty map or handle error if args are null/incorrect
    final Map<String, dynamic> orderData = routeArgs ?? {};

    // Fallback for critical data if not present, though ideally, they should always be.
    // This is more for robustness during development or unexpected issues.
    orderData.putIfAbsent('customerID', () => 'N/A');
    orderData.putIfAbsent('customerName', () => 'N/A');
    orderData.putIfAbsent('address', () => 'N/A');
    orderData.putIfAbsent('phone', () => 'N/A');
    orderData.putIfAbsent('orderID', () => 'N/A');
    orderData.putIfAbsent('createdTime', () => DateTime.now());
    orderData.putIfAbsent('paymentMethod', () => 'N/A');
    orderData.putIfAbsent('itemsTotal', () => 0.0);
    orderData.putIfAbsent('shippingFee', () => 0.0);
    orderData.putIfAbsent('tax', () => 0.0);
    orderData.putIfAbsent('discount', () => 0.0);
    orderData.putIfAbsent('totalAmount', () => 0.0);

    // --- Currency values will be passed as num; formatting should be done in bodySuccessPayment ---
    // final currencyFormatter = NumberFormat("#,##0", "vi_VN");
    // final List<String> currencyKeys = [
    //   'itemsTotal',
    //   'shippingFee',
    //   'tax',
    //   'discount',
    //   'totalAmount'
    // ];

    // for (String key in currencyKeys) {
    //   if (orderData[key] is num) {
    //     orderData[key] = '${currencyFormatter.format(orderData[key])} VND';
    //   }
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
          return NavbarFormobile(
            // Giả sử NavbarFixmobile là Scaffold chứa AppBar và body
            body: body,
            // title: 'Thanh toán', // Có thể thêm title cho AppBar
          );
        } else if (screenWidth < 1100) {
          // Tablet layout
          return NavbarForTablet(
            // Giả sử NavbarFixTablet tương tự
            body: body,
            // title: 'Thanh toán',
          );
        } else {
          // Desktop layout
          appBar = PreferredSize(
            preferredSize: Size.fromHeight(130),
            child:
                Navbarhomedesktop(), // Giả sử Navbarhomedesktop là widget bạn đã tạo
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
