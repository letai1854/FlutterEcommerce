import 'package:e_commerce_app/widgets/Product/CatalogProduct.dart';
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';
import 'package:flutter/material.dart';

class ListproductDesktop extends StatefulWidget {
  const ListproductDesktop({super.key});

  @override
  State<ListproductDesktop> createState() => _ListproductDesktopState();
}

class _ListproductDesktopState extends State<ListproductDesktop> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(130),
        child: Navbarhomedesktop(),
      ),
      body: CatalogProduct(),
    );
  }
}
