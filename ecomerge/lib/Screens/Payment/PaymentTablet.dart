import 'package:e_commerce_app/Screens/Payment/PaymentDesktop.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavarFixTablet.dart';
import 'package:e_commerce_app/widgets/Payment/bodyPayment.dart';
import 'package:e_commerce_app/widgets/navbarHomeTablet.dart';
import 'package:flutter/material.dart';
class Paymenttablet extends StatefulWidget {
  const Paymenttablet({super.key});

  @override
  State<Paymenttablet> createState() => _PaymenttabletState();
}

class _PaymenttabletState extends State<Paymenttablet> {
  @override
  Widget build(BuildContext context) {
    // return Scaffold(
    //   backgroundColor: Colors.grey[100], // Adding light gray background to the page
    //   appBar: PreferredSize(
    //     preferredSize: Size.fromHeight(130),
    //     child: NavbarhomeTablet(context),
    //   ),
    //   body: bodyPayment(),
    // );
    return NavbarFixTablet(
      body: bodyPayment(), // Truyền body vào NavbarhomeTablet
    );
  }
}
