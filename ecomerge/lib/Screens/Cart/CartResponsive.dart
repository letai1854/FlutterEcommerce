import 'package:e_commerce_app/Responsive/ResponsiveLayout.dart';
import 'package:e_commerce_app/Screens/Cart/CartDeskTop.dart';
import 'package:e_commerce_app/Screens/Cart/CartMobile.dart';
import 'package:e_commerce_app/Screens/Cart/CartTablet.dart';

import 'package:flutter/material.dart';

class ResponsiveCart extends StatelessWidget {
  const ResponsiveCart({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileScaffold: const Cartmobile(),
      tableScaffold: const Carttablet(),
      destopScaffold: const Cartdesktop(),
    );
  }
}
