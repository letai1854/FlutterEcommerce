import 'package:e_commerce_app/Responsive/ResponsiveLayout.dart';
import 'package:e_commerce_app/Screens/Search/Search_Desktop.dart';
import 'package:e_commerce_app/Screens/Search/Search_Mobile.dart';
import 'package:e_commerce_app/Screens/Search/Search_Tablet.dart';
import 'package:flutter/material.dart';

class SearchResponsive extends StatelessWidget {
  const SearchResponsive({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileScaffold: const SearchMobile(),
      tableScaffold: const SearchTablet(),
      destopScaffold: const SearchDesktop(),
    );
  }
}
