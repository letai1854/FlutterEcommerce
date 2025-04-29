import 'package:carousel_slider/carousel_slider.dart';
import 'package:e_commerce_app/Constants/productTest.dart';
import 'package:e_commerce_app/widgets/Product/PaginatedProductGrid.dart';
import 'package:e_commerce_app/widgets/Search/FilterPanel.dart';
import 'package:e_commerce_app/widgets/SortingBar.dart';
import 'package:e_commerce_app/widgets/footer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class SearchProduct extends StatefulWidget {
  const SearchProduct({super.key});
  
  @override
  State<SearchProduct> createState() => _SearchProductState();
}

class _SearchProductState extends State<SearchProduct> {
  int _current = 0;
  List<Map<String, dynamic>> productData = Productest.productData;
  List<Map<String, dynamic>> filteredProducts = [];
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  final List<String> imgList = [
    'assets/bannerMain.jpg',
    'assets/banner2.jpg',
    'assets/banner6.jpg',
  ];

  @override
  void initState() {
    super.initState();
    filteredProducts = List.from(productData);
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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isWideScreen = size.width >= 1100;
    
    // Base spacing calculations
    final double minSpacing = 16.0;
    final double maxSpacing = 24.0;
    final double spacing = (size.width * 0.02).clamp(minSpacing, maxSpacing);
    
    // Calculate filter panel width
    final double filterWidth = isWideScreen ? min(size.width * 0.2, 280.0) : 0;
    
    // Calculate main content width
    final double mainContentWidth = isWideScreen 
        ? size.width - filterWidth - (spacing * 3)
        : size.width - (spacing * 2);

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: !isWideScreen ? 
        Drawer(
          width: min(size.width * 0.85, 400.0),
          child: FilterPanel(onFiltersApplied: onFiltersApplied),
        ) : null,
      body: Container(
        color: Colors.grey[100],
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isWideScreen)
              Padding(
                padding: EdgeInsets.all(spacing),
                child: SizedBox(
                  width: filterWidth,
                  child: FilterPanel(onFiltersApplied: onFiltersApplied),
                ),
              ),
            
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(spacing),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      // Carousel Section
                      SizedBox(
                        width: mainContentWidth,
                        height: mainContentWidth * 0.3,
                        child: CarouselSlider(
                          items: imgList.map((item) => Container(
                            margin: EdgeInsets.symmetric(horizontal: spacing/2),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.asset(
                                item,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          )).toList(),
                          options: CarouselOptions(
                            height: mainContentWidth * 0.3,
                            autoPlay: true,
                            enlargeCenterPage: true,
                            viewportFraction: isWideScreen ? 0.8 : 0.95,
                            onPageChanged: (index, _) => setState(() => _current = index),
                          ),
                        ),
                      ),

                      SizedBox(height: spacing),

                      // Sorting Bar Section
                      Container(
                        width: mainContentWidth,
                        padding: EdgeInsets.all(spacing/2),
                        child: Row(
                          children: [
                            Expanded(
                              child: SortingBar(
                                width: mainContentWidth * 0.9,
                                onSortChanged: (sortType) {},
                              ),
                            ),
                            if (!isWideScreen)
                              IconButton(
                                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                                icon: const Icon(Icons.filter_list),
                                color: Colors.red,
                              ),
                          ],
                        ),
                      ),

                      SizedBox(height: spacing),

                      // Product Grid Section
                      SizedBox(
                        width: mainContentWidth,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double minItemWidth = 200.0;  // Minimum width per item
                            final int maxColumns = (constraints.maxWidth / minItemWidth).floor();
                            final int columns = max(2, min(maxColumns, 5));  // Between 2 and 5 columns
                            
                            final double itemSpacing = spacing * 0.75;

                            return PaginatedProductGrid(
                              productData: filteredProducts,
                              itemsPerPage: columns * 2,
                              gridWidth: constraints.maxWidth,
                              childAspectRatio: 0.7,  // Taller items for better layout
                              crossAxisCount: columns,
                              mainSpace: itemSpacing,
                              crossSpace: itemSpacing,
                            );
                          },
                        ),
                      ),

                      SizedBox(height: spacing),

                      if (kIsWeb) const Footer(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
