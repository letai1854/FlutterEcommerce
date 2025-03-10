// lib/screens/home/responsive_home.dart
import 'package:e_commerce_app/Responsive/ResponsiveLayout.dart';
import 'package:flutter/material.dart';

import 'Home_DeskTop.dart';
import 'home_moblie.dart';
import 'home_tablet.dart';

class ResponsiveHome extends StatelessWidget {
  const ResponsiveHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileScaffold: const HomeMobile(),
      tableScaffold: const HomeTablet(),
      destopScaffold: const HomeDesktop(),
    );
  }
}
