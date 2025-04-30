import 'package:carousel_slider/carousel_slider.dart';
import 'package:e_commerce_app/widgets/CategoryItem.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavarFixTablet.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarMobile.dart';
import 'package:e_commerce_app/widgets/Product/CatalogProduct.dart';
import 'package:e_commerce_app/widgets/ProductGridView.dart';
import 'package:e_commerce_app/widgets/SortingBar.dart';
import 'package:e_commerce_app/widgets/footer.dart';
import 'package:e_commerce_app/widgets/navbarHomeTablet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ListproductTablet extends StatefulWidget {
  const ListproductTablet({super.key});

  @override
  State<ListproductTablet> createState() => _ListproductTabletState();
}

class _ListproductTabletState extends State<ListproductTablet> {
  Widget build(BuildContext context) {
        return NavbarFixTablet(
      body: CatalogProduct(), // Truyền body vào NavbarFixmobile
    );
}
}

