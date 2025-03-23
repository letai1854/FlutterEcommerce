import 'package:e_commerce_app/widgets/Payment/PaymentSuccess.dart';
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Successpaymentdesktop extends StatefulWidget {
  const Successpaymentdesktop({super.key});

  @override
  State<Successpaymentdesktop> createState() => _SuccesspaymentdesktopState();
}

class _SuccesspaymentdesktopState extends State<Successpaymentdesktop> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(130),
        child: Navbarhomedesktop(),
      ),
      body: bodySuccessPayment(),
    );
  }
}
