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
  final GlobalKey _categoriesSectionKey = GlobalKey();
  final GlobalKey _paginatedGridKey = GlobalKey();
  // Key for the scaffold to access drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  final List<String> imgList = [
    'assets/bannerMain.jpg',
    'assets/banner2.jpg',
    'assets/banner6.jpg',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with all products
    filteredProducts = List.from(productData);
  }

  // Handle filter application
  void onFiltersApplied({
    required List<int> categories,
    required List<String> brands,
    required int minPrice,
    required int maxPrice,
  }) {
    setState(() {
      // Apply filters to product data
      filteredProducts = productData.where((product) {
        bool matchesCategory = categories.isEmpty || categories.contains(product['category_id']);
        bool matchesBrand = brands.isEmpty || brands.contains(product['brand']);
        bool matchesPrice = product['price'] >= minPrice && product['price'] <= maxPrice;
        
        return matchesCategory && matchesBrand && matchesPrice;
      }).toList();
      
      print('Filters applied: ${filteredProducts.length} products match');
      
      // If mobile, close the drawer after applying filters
      if (isMobile(context)) {
        Navigator.of(context).pop();
      }
    });
  }

  // Check if we're on a mobile device based on screen width
  bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 1100;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Updated helper function for main (vertical) spacing with smoother transitions
  double _getMainSpacing(double width, bool isTransition) {
    // Special case for transition points to reduce spacing
    if (isTransition) return 5.0;
    
    if (width < 480) return 5.0;      // Small phone: minimal spacing
    if (width < 600) return 6.0;      // Regular phone
    if (width < 768) return 6.0;      // Small tablet
    if (width < 900) return 7.0;      // Medium tablet
    if (width < 1100) return 8.0;     // Large tablet - reduced from 10
    return 10.0;                      // Desktop
  }

  // Helper function for cross (horizontal) spacing with smoother transitions
  double _getCrossSpacing(double width, bool isTransition) {
    // Special case for transition points
    if (isTransition) return 6.0;
    
    if (width < 480) return 5.0;
    if (width < 600) return 6.0;
    if (width < 1100) return 8.0;
    return 10.0;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final carouselHeight = 230.0;
    final bool isOnMobile = isMobile(context);
    
    // Add a specific transition breakpoint to handle desktop/tablet boundary
    final bool isTransitionWidth = screenWidth >= 1050 && screenWidth < 1150;
    
    // Refined breakpoint definitions with clearer names
    final bool isSmallPhone = screenWidth < 480;
    final bool isPhone = screenWidth >= 480 && screenWidth < 600;
    final bool isSmallTablet = screenWidth >= 600 && screenWidth < 768;
    final bool isMediumTablet = screenWidth >= 768 && screenWidth < 900;
    final bool isLargeTablet = screenWidth >= 900 && screenWidth < 1100;

    // Print screen width and active breakpoint for debugging
    print('Screen width: $screenWidth');
    print('Active breakpoint: ${_getBreakpointName(screenWidth)}');

    // Calculate horizontal padding based on screen size
    final double horizontalPadding = isSmallPhone ? 12 : 
                                    isPhone ? 16 : 
                                    isSmallTablet ? 20 : 
                                    isMediumTablet ? 24 : 
                                    isLargeTablet ? 30 : 40;
    
    // Updated grid columns logic with transition adjustment
    int gridColumns;
    if (screenWidth < 480) {
      gridColumns = 2;      // Small phone: 2 columns
    } else if (screenWidth < 600) {
      gridColumns = 2;      // Regular phone: 2 columns
    } else if (screenWidth < 768) {
      gridColumns = 2;      // Small tablet: 2 columns
    } else if (screenWidth < 900) {
      gridColumns = 3;      // Medium tablet: 3 columns
    } else if (screenWidth < 1100) {
      gridColumns = 3;      // Large tablet: 3 columns (reduced from 4)
    } else if (isTransitionWidth) {
      gridColumns = 3;      // Transition width: 3 columns to prevent overflow
    } else if (screenWidth < 1300) {
      gridColumns = 4;      // Small desktop: 4 columns
    } else if (screenWidth < 1470) {
      gridColumns = 5;      // Medium desktop: 5 columns
    } else {
      gridColumns = 6;      // Large desktop: 6 columns
    }

    // Calculate the safe width for the product grid
    final double safeGridWidth = _calculateSafeGridWidth(
      screenWidth: screenWidth,
      horizontalPadding: horizontalPadding,
      isOnMobile: isOnMobile,
      isTransition: isTransitionWidth
    );

    // Check not only the transition width but also transitions between sizes
    final bool isTabletTransition = (screenWidth >= 590 && screenWidth < 610) || 
                                   (screenWidth >= 760 && screenWidth < 780) ||
                                   (screenWidth >= 890 && screenWidth < 910);
    final bool isAnyTransition = isTransitionWidth || isTabletTransition;

    return Scaffold(
      key: _scaffoldKey,
      // Add endDrawer for mobile view
      endDrawer: isOnMobile ? 
        Drawer(
          width: screenWidth * 0.75,
          child: FilterPanel(
            onFiltersApplied: onFiltersApplied,
          ),
        ) : null,
      body: Container(
        color: Colors.grey[300], // Light gray background
        padding: EdgeInsets.only(top: 16), // Space from navbar
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Only show FilterPanel directly in the layout for desktop
            if (!isOnMobile)
              Padding(
                padding: EdgeInsets.only(left: isTransitionWidth ? 8 : 16),
                child: Container(
                  // Adjust filter panel width at transition point
                  width: isTransitionWidth ? 180 : 200,
                  child: FilterPanel(
                    onFiltersApplied: onFiltersApplied,
                  ),
                ),
              ),
            
            // Main Content Area
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    // Carousel Slider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      child: SizedBox(
                        width: screenWidth * (isOnMobile ? 0.9 : 0.8),
                        height: carouselHeight,
                        child: CarouselSlider(
                          items: imgList.map((item) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(3.0),
                              child: Image.asset(
                                item,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: carouselHeight,
                                alignment: Alignment.center,
                              ),
                            );
                          }).toList(),
                          options: CarouselOptions(
                            autoPlay: true,
                            aspectRatio: 5,
                            enlargeCenterPage: true,
                            viewportFraction: 1.0,
                            height: carouselHeight,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _current = index;
                              });
                            },
                          ),
                        ),
                      ),
                    ),

                    // Sorting Bar with Filter Button for mobile
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        children: [
                          // Sorting bar takes less space on mobile when filter button is visible
                          Expanded(
                            child: SortingBar(
                              width: isOnMobile ? screenWidth * 0.7 : screenWidth * 0.8,
                              onSortChanged: (sortType) {
                                print('Sort by: $sortType');
                              },
                            ),
                          ),
                          
                          // Filter button for mobile
                          if (isOnMobile)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Material(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  onTap: () {
                                    _scaffoldKey.currentState?.openEndDrawer();
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.filter_list,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Lọc',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Product Grid with Pagination - adjust padding and spacing for transitions
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isAnyTransition ? 20 : horizontalPadding,
                        vertical: isAnyTransition ? 12 : 16
                      ),
                      child: Column(
                        key: _paginatedGridKey,
                        children: [
                          SizedBox(
                            width: safeGridWidth,
                            child: PaginatedProductGrid(
                              productData: filteredProducts,
                              itemsPerPage: _getItemsPerPage(screenWidth),
                              gridWidth: safeGridWidth,
                              // Adjust aspect ratio to help with spacing
                              childAspectRatio: isAnyTransition 
                                  ? _getAspectRatio(screenWidth) + 0.03 // Slightly wider aspect ratio at transitions
                                  : _getAspectRatio(screenWidth),
                              crossAxisCount: gridColumns,
                              // Use refined spacing methods with transition awareness
                              mainSpace: _getMainSpacing(screenWidth, isAnyTransition),
                              crossSpace: _getCrossSpacing(screenWidth, isAnyTransition),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (kIsWeb)
                      const Footer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to get breakpoint name for debugging
  String _getBreakpointName(double width) {
    if (width < 480) return 'Small Phone';
    if (width < 600) return 'Phone';
    if (width < 768) return 'Small Tablet';
    if (width < 900) return 'Medium Tablet';
    if (width < 1100) return 'Large Tablet';
    if (width < 1300) return 'Small Desktop';
    if (width < 1470) return 'Medium Desktop';
    return 'Large Desktop';
  }

  // Helper function to get aspect ratio based on screen width
  double _getAspectRatio(double width) {
    if (width < 480) return 0.75;      // Small phone
    if (width < 600) return 0.72;      // Phone
    if (width < 768) return 0.72;      // Small tablet
    if (width < 900) return 0.72;      // Medium tablet
    if (width < 1100) return 0.74;     // Large tablet
    return 0.75;                       // Desktop
  }

  // Helper function to determine items per page
  int _getItemsPerPage(double width) {
    if (width < 480) return 4;
    if (width < 600) return 6;
    if (width < 768) return 6;
    if (width < 900) return 8;
    if (width < 1100) return 8;
    if (width < 1300) return 10;
    if (width < 1470) return 10;
    return 12;
  }

  // Helper method to safely calculate grid width and prevent overflow
  double _calculateSafeGridWidth({
    required double screenWidth,
    required double horizontalPadding,
    required bool isOnMobile,
    required bool isTransition
  }) {
    double availableWidth = screenWidth - (horizontalPadding * 2);
    
    // Account for filter panel width on desktop
    if (!isOnMobile) {
      // Use smaller filter panel width at transition point
      double filterPanelWidth = isTransition ? 200 : 220;
      availableWidth -= filterPanelWidth;
      
      // Add extra safety margin at transition point
      if (isTransition) {
        availableWidth -= 10;  // Extra safety margin
      }
    }
    
    // Add additional safety margin for tablet transitions
    final bool isTabletTransition = (screenWidth >= 590 && screenWidth < 610) || 
                                   (screenWidth >= 760 && screenWidth < 780) ||
                                   (screenWidth >= 890 && screenWidth < 910);
    if (isTabletTransition) {
      availableWidth -= 5;  // Extra safety margin for tablet transitions
    }
    
    // Ensure minimum width and add safety margin
    return max(availableWidth, 300); // At least 300px wide
  }
}
