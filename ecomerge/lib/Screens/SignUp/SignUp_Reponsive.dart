import 'package:e_commerce_app/Responsive/ResponsiveLayout.dart';
import 'package:e_commerce_app/Screens/SignUp/SIgnUp_Tablet.dart';
import 'package:e_commerce_app/Screens/SignUp/SignUp_DeskTop.dart';
import 'package:e_commerce_app/Screens/SignUp/SignUp_Mobile.dart';
import 'package:flutter/material.dart';

class ReponsiveSignUp extends StatelessWidget {
  const ReponsiveSignUp({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileScaffold: const SignupMobile(),
      tableScaffold: const SignupTablet(),
      destopScaffold: const SignUpDesktop(),
    );
  }
}
