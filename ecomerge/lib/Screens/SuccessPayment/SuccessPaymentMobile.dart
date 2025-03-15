import 'package:e_commerce_app/widgets/NavbarMobile/NavbarMobile.dart';
import 'package:e_commerce_app/widgets/Payment/PaymentSuccess.dart';
import 'package:flutter/material.dart';
class Successpaymentmobile extends StatefulWidget {
  const Successpaymentmobile({super.key});

  @override
  State<Successpaymentmobile> createState() => _SuccesspaymentmobileState();
}

class _SuccesspaymentmobileState extends State<Successpaymentmobile> {
  @override
  Widget build(BuildContext context) {
        return NavbarFixmobile(
      body: bodySuccessPayment(), // Truyền body vào NavbarFixmobile
    );
  }
}
