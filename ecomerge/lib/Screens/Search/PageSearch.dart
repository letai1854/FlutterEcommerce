import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:e_commerce_app/Constants/productTest.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForTablet.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForMobile.dart';
import 'package:e_commerce_app/widgets/Product/PaginatedProductGrid.dart';
import 'package:e_commerce_app/widgets/Search/FilterPanel.dart';
import 'package:e_commerce_app/widgets/Search/SearchProduct.dart';
import 'package:e_commerce_app/widgets/SortingBar.dart';
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';
import 'package:flutter/material.dart';

class PageSearch extends StatefulWidget {
  const PageSearch({super.key});

  @override
  State<PageSearch> createState() => _PageSearchState();
}

class _PageSearchState extends State<PageSearch> {
  // Core product data and filters
  int _current = 0;
  List<Map<String, dynamic>> productData = Productest.productData;
  List<Map<String, dynamic>> filteredProducts = [];
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Banner images
  final List<String> imgList = [
    'assets/bannerMain.jpg',
    'assets/banner2.jpg',
    'assets/banner6.jpg',
  ];
  
  // Category selection state
  Map<int, bool> selectedCategories = {};
  Set<String> selectedBrands = {};
  
  // Price range state
  TextEditingController minPriceController = TextEditingController();
  TextEditingController maxPriceController = TextEditingController();
  int minPrice = 0;
  int maxPrice = 10000000; // 10 million VND default max
  final int priceStep = 1000000; // Step by 1 million VND
  
  // Category and brand data
  final List<Map<String, dynamic>> catalog = [
    {
      'name': 'Laptop',
      'img': 'https://anhnail.com/wp-content/uploads/2024/11/son-goku-ngau-nhat.jpg',
      'id': 1,
    },
    {
      'name': 'Bàn phím',
      'img': 'https://hoangtuan.vn/media/product/844_ban_phim_co_geezer_gs2_rgb_blue_switch.jpg',
      'id': 2,
    },
    {
      'name': 'Chuột',
      'img': 'https://png.pngtree.com/png-vector/20240626/ourlar…n-transparent-background-a-png-image_12849468.png',
      'id': 3,
    },
    {
      'name': 'Hub',
      'img': 'https://vienthongxanh.vn/wp-content/uploads/2022/12/hinh-anh-minh-hoa-thiet-bi-switch.png',
      'id': 4,
    },
    {
      'name': 'Tai nghe',
      'img': 'https://img.lovepik.com/free-png/20211120/lovepik-headset-png-image_401058941_wh1200.png',
      'id': 5,
    }
  ];
  
  // List of brands
  final List<String> brands = [
    'Apple',
    'Samsung',
    'Dell',
    'HP',
    'Asus',
  ];

  @override
  void initState() {
    super.initState();
    filteredProducts = List.from(productData);
    // Initialize the text controllers with formatted values
    minPriceController.text = formatPrice(minPrice);
    maxPriceController.text = formatPrice(maxPrice);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    minPriceController.dispose();
    maxPriceController.dispose();
    super.dispose();
  }

  // Format price with commas
  String formatPrice(int price) {
    return price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},');
  }
  
  // Parse price from formatted string
  int parsePrice(String text) {
    if (text.isEmpty) return 0;
    return int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }
  
  // Update min price with validation
  void updateMinPrice(int newValue) {
    if (newValue < 0) newValue = 0;
    if (newValue > maxPrice) newValue = maxPrice;
    
    setState(() {
      minPrice = newValue;
      minPriceController.text = formatPrice(newValue);
    });
  }
  
  // Update max price with validation
  void updateMaxPrice(int newValue) {
    if (newValue < minPrice) newValue = minPrice;
    
    setState(() {
      maxPrice = newValue;
      maxPriceController.text = formatPrice(newValue);
    });
  }

  void onFiltersApplied({
    required List<int> categories,
    required List<String> brands,
    required int minPrice,
    required int maxPrice,
  }) {
    setState(() {
      filteredProducts = productData.where((product) {
        bool matchesCategory = categories.isEmpty || categories.contains(product['category_id']);
        bool matchesBrand = brands.isEmpty || brands.contains(product['brand']);
        bool matchesPrice = product['price'] >= minPrice && product['price'] <= maxPrice;
        return matchesCategory && matchesBrand && matchesPrice;
      }).toList();
      
      if (MediaQuery.of(context).size.width < 1100) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        Widget appBar;
        Widget body = SearchProduct(
          current: _current,
          imgList: imgList,
          filteredProducts: filteredProducts,
          scaffoldKey: _scaffoldKey,
          scrollController: _scrollController,
          onFiltersApplied: onFiltersApplied,
          // Pass the state variables needed for FilterPanel
          selectedCategories: selectedCategories,
          selectedBrands: selectedBrands,
          minPrice: minPrice,
          maxPrice: maxPrice,
          minPriceController: minPriceController,
          maxPriceController: maxPriceController,
          priceStep: priceStep,
          catalog: catalog,
          brands: brands,
          updateMinPrice: updateMinPrice,
          updateMaxPrice: updateMaxPrice,
          formatPrice: formatPrice,
          parsePrice: parsePrice,
        );

        if (screenWidth < 768) {
          // Mobile layout
          return NavbarFormobile(
            body: body,
          );
        } else if (screenWidth < 1100) {
          // Tablet layout
          return NavbarForTablet(
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
