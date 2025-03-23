import 'package:e_commerce_app/widgets/Payment/bodyPayment.dart';
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';
import 'package:e_commerce_app/widgets/Payment/AddressSelector.dart';
import 'package:e_commerce_app/widgets/Payment/VoucherSelector.dart'; // Đảm bảo đường dẫn import chính xác
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import the intl package

class Paymentdesktop extends StatefulWidget {
  const Paymentdesktop({Key? key}) : super(key: key);

  @override
  State<Paymentdesktop> createState() => _PaymentdesktopState();
}

class _PaymentdesktopState extends State<Paymentdesktop> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Adding light gray background to the page
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(130),
        child: Navbarhomedesktop(),
      ),
      body: bodyPayment(),
    );
  }
}
