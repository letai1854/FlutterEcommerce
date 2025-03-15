import 'package:e_commerce_app/Screens/Payment/PaymentDesktop.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarMobile.dart';
import 'package:e_commerce_app/widgets/Payment/bodyPayment.dart';
import 'package:flutter/material.dart';
class Paymentmobile extends StatefulWidget {
  const Paymentmobile({super.key});

  @override
  State<Paymentmobile> createState() => _PaymentmobileState();
}

class _PaymentmobileState extends State<Paymentmobile> {
  @override
  Widget build(BuildContext context) {
    return NavbarFixmobile(
      body: bodyPayment(), // Truyền body vào NavbarFixmobile
      
    );
  }
}
