import 'package:carousel_slider/carousel_slider.dart';
import 'package:e_commerce_app/widgets/Product/PaginatedProductGrid.dart';
import 'package:e_commerce_app/widgets/Search/FilterPanel.dart';
import 'package:e_commerce_app/widgets/SortingBar.dart';
import 'package:e_commerce_app/widgets/footer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class SearchProduct extends StatefulWidget {
  // Pass all required properties from PageSearch
  final int current;
  final List<String> imgList;
  final List<Map<String, dynamic>> filteredProducts;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final ScrollController scrollController;
  final Function({
    required List<int> categories,
    required List<String> brands,
    required int minPrice,
    required int maxPrice
  }) onFiltersApplied;
  
  // FilterPanel state variables
  final Map<int, bool> selectedCategories;
  final Set<String> selectedBrands;
  final int minPrice;
  final int maxPrice;
  final TextEditingController minPriceController;
  final TextEditingController maxPriceController;
  final int priceStep;
  final List<Map<String, dynamic>> catalog;
  final List<String> brands;
  final Function(int) updateMinPrice;
  final Function(int) updateMaxPrice;
  final String Function(int) formatPrice;
  final int Function(String) parsePrice;

  const SearchProduct({
    super.key,
    required this.current,
    required this.imgList,
    required this.filteredProducts,
    required this.scaffoldKey,
    required this.scrollController,
    required this.onFiltersApplied,
    required this.selectedCategories,
    required this.selectedBrands,
    required this.minPrice,
    required this.maxPrice,
    required this.minPriceController,
    required this.maxPriceController,
    required this.priceStep,
    required this.catalog,
    required this.brands,
    required this.updateMinPrice,
    required this.updateMaxPrice,
    required this.formatPrice,
    required this.parsePrice,
  });
  
  @override
  State<SearchProduct> createState() => _SearchProductState();
}

class _SearchProductState extends State<SearchProduct> {
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _current = widget.current;
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
      key: widget.scaffoldKey,
      endDrawer: !isWideScreen ? 
        Drawer(
          width: min(size.width * 0.85, 400.0),
          child: FilterPanel(
            onFiltersApplied: widget.onFiltersApplied,
            selectedCategories: widget.selectedCategories,
            selectedBrands: widget.selectedBrands,
            minPrice: widget.minPrice,
            maxPrice: widget.maxPrice,
            minPriceController: widget.minPriceController,
            maxPriceController: widget.maxPriceController,
            priceStep: widget.priceStep,
            catalog: widget.catalog,
            brands: widget.brands,
            updateMinPrice: widget.updateMinPrice,
            updateMaxPrice: widget.updateMaxPrice,
            formatPrice: widget.formatPrice,
            parsePrice: widget.parsePrice,
          ),
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
                  child: FilterPanel(
                    onFiltersApplied: widget.onFiltersApplied,
                    selectedCategories: widget.selectedCategories,
                    selectedBrands: widget.selectedBrands,
                    minPrice: widget.minPrice,
                    maxPrice: widget.maxPrice,
                    minPriceController: widget.minPriceController,
                    maxPriceController: widget.maxPriceController,
                    priceStep: widget.priceStep,
                    catalog: widget.catalog,
                    brands: widget.brands,
                    updateMinPrice: widget.updateMinPrice,
                    updateMaxPrice: widget.updateMaxPrice,
                    formatPrice: widget.formatPrice,
                    parsePrice: widget.parsePrice,
                  ),
                ),
              ),
            
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(spacing),
                child: SingleChildScrollView(
                  controller: widget.scrollController,
                  child: Column(
                    children: [
                      // Carousel Section
                      SizedBox(
                        width: mainContentWidth,
                        height: mainContentWidth * 0.3,
                        child: CarouselSlider(
                          items: widget.imgList.map((item) => Container(
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
                                onPressed: () => widget.scaffoldKey.currentState?.openEndDrawer(),
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
                              productData: widget.filteredProducts,
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
