import 'package:e_commerce_app/Responsive/ResponsiveLayout.dart';
import 'package:e_commerce_app/Screens/Login/Login_DeskTop.dart';
import 'package:e_commerce_app/Screens/Login/Login_Mobile.dart';
import 'package:e_commerce_app/Screens/Login/Login_tablet.dart';
import 'package:flutter/material.dart';

class ResponsiveLogin extends StatelessWidget {
  const ResponsiveLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileScaffold: const LoginMobile(),
      tableScaffold: const LoginTablet(),
      destopScaffold: const LoginDesktop(),
    );
  }
}
