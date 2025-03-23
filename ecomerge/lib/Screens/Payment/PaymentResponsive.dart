import 'package:e_commerce_app/Responsive/ResponsiveLayout.dart';
import 'package:e_commerce_app/Screens/Payment/PaymentDesktop.dart';
import 'package:e_commerce_app/Screens/Payment/PaymentMobile.dart';
import 'package:e_commerce_app/Screens/Payment/PaymentTablet.dart';
import 'package:flutter/material.dart';

class ResponsivePayment extends StatelessWidget {
  const ResponsivePayment({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileScaffold: const Paymentmobile(),
      tableScaffold: const Paymenttablet(),
      destopScaffold: const Paymentdesktop(),
    );
  }
}
