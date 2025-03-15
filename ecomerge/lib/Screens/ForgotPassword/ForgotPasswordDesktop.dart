import 'package:e_commerce_app/widgets/ForgotPassword/bodyForgotPassword.dart';
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';
import 'package:flutter/material.dart';

class Forgotpassworddesktop extends StatefulWidget {
  const Forgotpassworddesktop({super.key});

  @override
  State<Forgotpassworddesktop> createState() => _ForgotpassworddesktopState();
}

class _ForgotpassworddesktopState extends State<Forgotpassworddesktop> {
  @override
  Widget build(BuildContext context) {
      return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(130),
        child: Navbarhomedesktop(),
      ),
      body: bodyForgotPassword(),
    );
  }
}
