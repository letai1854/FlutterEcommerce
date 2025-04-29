import 'package:e_commerce_app/Responsive/ResponsiveLayout.dart';
import 'package:e_commerce_app/Screens/ForgotPassword/ForgotPasswordDesktop.dart';
import 'package:e_commerce_app/Screens/ForgotPassword/ForgotPasswordMobile.dart';
import 'package:e_commerce_app/Screens/ForgotPassword/ForgotPasswordTablet.dart';
import 'package:flutter/material.dart';

class ResponsiveForgotPassword extends StatelessWidget {
  const ResponsiveForgotPassword({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileScaffold: const Forgotpasswordmobile(),
      tableScaffold: const Forgotpasswordtablet(),
      destopScaffold: const Forgotpassworddesktop(),
    );
  }
}
