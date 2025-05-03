import 'package:e_commerce_app/Responsive/ResponsiveLayout.dart';
import 'package:e_commerce_app/Screens/Admin/Admin_Desktop.dart';
import 'package:e_commerce_app/Screens/Admin/Admin_Mobile.dart';
import 'package:e_commerce_app/Screens/Admin/Admin_Tablet.dart';


import 'package:flutter/material.dart';

class AdminResponsive extends StatelessWidget {
  const AdminResponsive({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileScaffold: const AdminDesktop(),
      tableScaffold: const AdminDesktop(),
      destopScaffold: const AdminDesktop(),
    );
  }
}
