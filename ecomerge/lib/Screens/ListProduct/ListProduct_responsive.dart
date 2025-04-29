import 'package:e_commerce_app/Responsive/ResponsiveLayout.dart';
import 'package:e_commerce_app/Screens/ListProduct/ListProduct_desktop.dart';
import 'package:e_commerce_app/Screens/ListProduct/ListProduct_mobile.dart';
import 'package:e_commerce_app/Screens/ListProduct/ListProduct_tablet.dart';
import 'package:flutter/material.dart';

class ResponsiveListProduct extends StatelessWidget {
  const ResponsiveListProduct({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileScaffold: const ListproductMobile(),
      tableScaffold: const ListproductTablet(),
      destopScaffold: const ListproductDesktop(),
    );
  }
}
