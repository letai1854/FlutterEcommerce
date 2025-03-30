import 'package:carousel_slider/carousel_slider.dart';
import 'package:e_commerce_app/Constants/productTest.dart';
import 'package:e_commerce_app/widgets/CategoryItem.dart';
import 'package:e_commerce_app/widgets/ProductGridView.dart';
import 'package:e_commerce_app/widgets/Search/FilterPanel.dart';
import 'package:e_commerce_app/widgets/Search/SearchProduct.dart';
import 'package:e_commerce_app/widgets/SortingBar.dart';
import 'package:e_commerce_app/widgets/footer.dart';
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';
import 'package:e_commerce_app/widgets/Product/PaginatedProductGrid.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SearchDesktop extends StatefulWidget {
  const SearchDesktop({super.key});

  @override
  State<SearchDesktop> createState() => _SearchDesktopState();
}

class _SearchDesktopState extends State<SearchDesktop> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(130),
        child: Navbarhomedesktop(),
      ),
      body: SearchProduct(),
    );
  }
}
