import 'package:e_commerce_app/widgets/ForgotPassword/bodyForgotPassword.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarMobile.dart';
import 'package:flutter/material.dart';
class Forgotpasswordmobile extends StatefulWidget {
  const Forgotpasswordmobile({super.key});

  @override
  State<Forgotpasswordmobile> createState() => _ForgotpasswordmobileState();
}

class _ForgotpasswordmobileState extends State<Forgotpasswordmobile> {
  @override
  Widget build(BuildContext context) {
      return NavbarFixmobile(
      body: bodyForgotPassword(), // Truyền body vào NavbarFixmobile
    );
  }
}
