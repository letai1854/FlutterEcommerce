import 'package:e_commerce_app/widgets/NavbarMobile/NavarFixTablet.dart';
import 'package:e_commerce_app/widgets/Search/SearchProduct.dart';
import 'package:e_commerce_app/widgets/navbarHomeTablet.dart';
import'package:flutter/material.dart';
class SearchTablet extends StatefulWidget {
  const SearchTablet({super.key});

  @override
  State<SearchTablet> createState() => _SearchTabletState();
}

class _SearchTabletState extends State<SearchTablet> {
  @override
  Widget build(BuildContext context) {
    //     return Scaffold(
    //   appBar: PreferredSize(
    //     preferredSize: Size.fromHeight(130),
    //     child: NavbarhomeTablet(context),
    //   ),
    //   body: SearchProduct(),
    // );
    return NavbarFixTablet(
      body: SearchProduct(),
    );
  }
  }

