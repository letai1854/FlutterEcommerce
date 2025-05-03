import 'package:e_commerce_app/Constants/productTest.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavarFixTablet.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarMobile.dart';
import 'package:e_commerce_app/widgets/Product/CatalogProduct.dart';
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';
import 'package:flutter/material.dart';

class PageListProduct extends StatefulWidget {
  const PageListProduct({super.key});

  @override
  State<PageListProduct> createState() => _PageListProductState();
}

class _PageListProductState extends State<PageListProduct> {
  // Core product data and filters
  List<Map<String, dynamic>> productData = Productest.productData;
  List<Map<String, dynamic>> filteredProducts = [];
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Sort state
  String currentSortMethod = '';
  int selectedCategoryId = 1;

  // Category data
  final List<Map<String, dynamic>> catalog = [
    {'name': 'Laptop', 'id': 1, 'image': 'https://dlcdnwebimgs.asus.com/gain/28BC0310-AD69-4C0D-9DE7-C27974A50B96'},
    {'name': 'Bàn phím', 'id': 2, 'image': 'https://bizweb.dktcdn.net/100/438/322/products/k1-black-1.jpg?v=1702469045657'},
    {'name': 'Chuột', 'id': 3, 'image': 'https://lh3.googleusercontent.com/NP_cA_KiUpZi0D1QAiu8s5k3PiEWqO0SOgyLH99MPgR1VhsUPyVKL737pqRjq_yXjHaEjEK9pbVI2V0quyiAE2NhVg'},
    {'name': 'Hub', 'id': 4, 'image': 'https://vn.canon/media/image/2021/07/12/fe2cb6c6e86145899db11898c8492482_EOS+R5_FrontSlantLeft_RF24-105mmF4LISUSM.png'},
    {'name': 'Tai nghe', 'id': 5, 'image': 'https://researchstore.vn/uploads/2023/10/hinh-anh-thuong-hieu-logitech.jpg'},
    {'name': 'Bàn', 'id': 6, 'image': 'https://tinhocngoisao.cdn.vccloud.vn/wp-content/uploads/2021/09/asus-gaming-rog.jpg'},
  ];

  @override
  void initState() {
    super.initState();
    filteredProducts = List.from(productData);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Update category selection
  void updateSelectedCategory(int categoryId) {
    setState(() {
      selectedCategoryId = categoryId;
      // Filter products based on category
      filteredProducts = productData.where((product) =>
        product['category_id'] == categoryId
      ).toList();
    });
  }

  // Update sort method
  void updateSortMethod(String method) {
    setState(() {
      currentSortMethod = method;
      // Products will be sorted in CatalogProduct widget
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        Widget appBar;
        Widget body = CatalogProduct(
          filteredProducts: filteredProducts,
          scaffoldKey: _scaffoldKey,
          scrollController: _scrollController,
          currentSortMethod: currentSortMethod,
          selectedCategoryId: selectedCategoryId,
          catalog: catalog,
          updateSelectedCategory: updateSelectedCategory,
          updateSortMethod: updateSortMethod,
        );

        if (screenWidth < 768) {
          // Mobile layout
          return NavbarFixmobile(
            body: body,
          );
        } else if (screenWidth < 1100) {
          // Tablet layout
          return NavbarFixTablet(
            body: body,
          );
        } else {
          // Desktop layout
          appBar = PreferredSize(
            preferredSize: Size.fromHeight(130),
            child: Navbarhomedesktop(),
          );
          return Scaffold(
            appBar: appBar as PreferredSize,
            body: body,
          );
        }
      },
    );
  }
}
