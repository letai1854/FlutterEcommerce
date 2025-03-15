import 'package:e_commerce_app/Responsive/ResponsiveLayout.dart';
import 'package:e_commerce_app/Screens/SuccessPayment/SuccessPaymentDesktop.dart';
import 'package:e_commerce_app/Screens/SuccessPayment/SuccessPaymentMobile.dart';
import 'package:e_commerce_app/Screens/SuccessPayment/SuccessPaymentTablet.dart';
import 'package:flutter/material.dart';


class ResponsiveSuccessPayment extends StatelessWidget {
  const ResponsiveSuccessPayment({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileScaffold: const Successpaymentmobile(),
      tableScaffold: const Successpaymenttablet(),
      destopScaffold: const Successpaymentdesktop(),
    );
  }
}
