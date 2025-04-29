import 'dart:io';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarMobile.dart';
import 'package:e_commerce_app/widgets/Product/CatalogProduct.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:e_commerce_app/constants.dart';
import 'package:e_commerce_app/widgets/BottomNavigation.dart';
import 'package:e_commerce_app/widgets/CategoryItem.dart';
import 'package:e_commerce_app/widgets/ProductGridView.dart';
import 'package:e_commerce_app/widgets/SortingBar.dart';
import 'package:e_commerce_app/widgets/footer.dart';
import 'package:e_commerce_app/widgets/navbarHomeMobile.dart';

class ListproductMobile extends StatefulWidget {
  const ListproductMobile({super.key});

  @override
  State<ListproductMobile> createState() => _ListproductMobileState();
}

class _ListproductMobileState extends State<ListproductMobile> {
  
  @override
     Widget build(BuildContext context) {
        return NavbarFixmobile(
      body: CatalogProduct(), // Truyền body vào NavbarFixmobile
    );
}
}
