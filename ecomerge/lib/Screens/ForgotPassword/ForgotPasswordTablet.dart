import 'package:e_commerce_app/widgets/ForgotPassword/bodyForgotPassword.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForTablet.dart';
import 'package:e_commerce_app/widgets/navbarHomeTablet.dart';
import 'package:flutter/material.dart';
class Forgotpasswordtablet extends StatefulWidget {
  const Forgotpasswordtablet({super.key});

  @override
  State<Forgotpasswordtablet> createState() => _ForgotpasswordtabletState();
}

class _ForgotpasswordtabletState extends State<Forgotpasswordtablet> {
  @override
  Widget build(BuildContext context) {
    return NavbarForTablet(
      body: bodyForgotPassword(), // Truyền body vào NavbarFixmobile;

    );
    //       return Scaffold(
    //   appBar: PreferredSize(
    //     preferredSize: Size.fromHeight(130),
    //     child: NavbarhomeTablet(context)
    //   ),
    //   body: bodyForgotPassword(),
    // );
  }
}
