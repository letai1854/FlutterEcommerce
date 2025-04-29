import 'package:e_commerce_app/widgets/NavbarMobile/NavbarMobile.dart';
import 'package:e_commerce_app/widgets/Search/SearchProduct.dart';
import 'package:flutter/material.dart';
class SearchMobile extends StatefulWidget {
  const SearchMobile({super.key});

  @override
  State<SearchMobile> createState() => _SearchMobileState();
}

class _SearchMobileState extends State<SearchMobile> {
  @override
    Widget build(BuildContext context) {
        return NavbarFixmobile(
      body: SearchProduct(), // Truyền body vào NavbarFixmobile
    );
}
}
