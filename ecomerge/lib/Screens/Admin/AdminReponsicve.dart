import 'package:e_commerce_app/Screens/Admin/Admin_Desktop.dart';
import 'package:flutter/material.dart';

class AdminResponsive extends StatelessWidget {
  const AdminResponsive({super.key});

  @override
  Widget build(BuildContext context) {
    // Directly return AdminDesktop since it's used for all screen sizes
    return const AdminDesktop();
  }
}
