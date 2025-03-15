import 'package:e_commerce_app/widgets/Payment/PaymentSuccess.dart';
import 'package:e_commerce_app/widgets/navbarHomeTablet.dart';
import 'package:flutter/material.dart';
class Successpaymenttablet extends StatefulWidget {
  const Successpaymenttablet({super.key});

  @override
  State<Successpaymenttablet> createState() => _SuccesspaymenttabletState();
}

class _SuccesspaymenttabletState extends State<Successpaymenttablet> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(130),
        child: NavbarhomeTablet(context),
      ),
      body: bodySuccessPayment(),
    );
  }
}
