import 'package:e_commerce_app/Responsive/ResponsiveLayout.dart';
import 'package:e_commerce_app/Screens/UserInfo/UserInfoDesktop.dart';
import 'package:e_commerce_app/Screens/UserInfo/UserInfoMobile.dart';
import 'package:e_commerce_app/Screens/UserInfo/UserInfoTablet.dart';
import 'package:flutter/material.dart';

class ResponsiveUserInfo extends StatefulWidget {
  const ResponsiveUserInfo({super.key});

  @override
  State<ResponsiveUserInfo> createState() => _ResponsiveUserInfoState();
}

class _ResponsiveUserInfoState extends State<ResponsiveUserInfo> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileScaffold: const UserInfoMobile(),
      tableScaffold: const UserInfoTablet(),
      destopScaffold: const UserInfoDesktop(),
    );
  }
}
