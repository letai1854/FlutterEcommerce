import 'package:carousel_slider/carousel_slider.dart';
import 'package:e_commerce_app/constants.dart';
import 'package:e_commerce_app/database/models/categories.dart';
import 'package:e_commerce_app/database/models/product_dto.dart';
import 'package:e_commerce_app/widgets/Product/PaginatedProductGrid.dart';
import 'package:e_commerce_app/widgets/Search/FilterPanel.dart';
import 'package:e_commerce_app/widgets/SortingBar.dart';
import 'package:e_commerce_app/widgets/footer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class SearchProduct extends StatefulWidget {
  final int current;
  final List<String> imgList;
  final List<ProductDTO> searchResults;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final ScrollController scrollController;
  final Function({
    required int? categoryId,
    required String? brandName,
    required int minPrice,
    required int maxPrice
  }) onFiltersApplied;
  
  // FilterPanel state variables - updated for single selection
  final int? selectedCategoryId;
  final String? selectedBrandName;
  final int minPrice;
  final int maxPrice;
  final TextEditingController minPriceController;
  final TextEditingController maxPriceController;
  final int priceStep;
  final List<CategoryDTO> catalog;
  final List<String> brands;
  final Function(int) updateMinPrice;
  final Function(int) updateMaxPrice;
  final String Function(int) formatPrice;
  final int Function(String) parsePrice;
  
  // Add flag for price filter application
  final bool isPriceFilterApplied;
  
  // Add search-specific props
  final bool isSearching;
  final bool canLoadMore;
  final String searchQuery;
  
  // Add sort parameters
  final String currentSortMethod;
  final String currentSortDir;
  final Function(String) updateSortMethod;
  
  // App data state
  final bool isAppDataLoading;
  final bool isAppDataInitialized;

  // Add search widget cache
  final Map<String, Widget> searchWidgetCache;

  const SearchProduct({
    super.key,
    required this.current,
    required this.imgList,
    required this.searchResults,
    required this.scaffoldKey,
    required this.scrollController,
    required this.onFiltersApplied,
    required this.selectedCategoryId,
    required this.selectedBrandName,
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
    this.isPriceFilterApplied = false, // Add with default false
    this.isSearching = false,
    this.canLoadMore = false,
    this.searchQuery = '',
    this.currentSortMethod = 'createdDate',
    this.currentSortDir = 'desc',
    required this.updateSortMethod,
    this.isAppDataLoading = false,
    this.isAppDataInitialized = false,
    required this.searchWidgetCache,
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
  
  // Add this method to handle sort direction display
  Widget _buildSortDirectionIndicator(String sortMethod) {
    final bool isCurrentMethod = widget.currentSortMethod == sortMethod;
    
    if (!isCurrentMethod) {
      return const SizedBox.shrink();
    }
    
    // Show up or down arrow based on the current sort direction
    return Icon(
      widget.currentSortDir == 'asc' ? Icons.arrow_upward : Icons.arrow_downward,
      size: 16,
      color: Colors.blue,
    );
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
            selectedCategoryId: widget.selectedCategoryId,
            selectedBrandName: widget.selectedBrandName,
            minPrice: widget.minPrice,
            maxPrice: widget.maxPrice,
            minPriceController: widget.minPriceController,
            maxPriceController: widget.maxPriceController,
            priceStep: widget.priceStep,
            catalog: widget.catalog.map((category) => {
              'id': category.id ?? -1,
              'name': category.name ?? 'Unknown Category',
              'img': category.imageUrl ?? '',
            }).toList(),
            brands: widget.brands,
            updateMinPrice: widget.updateMinPrice,
            updateMaxPrice: widget.updateMaxPrice,
            formatPrice: widget.formatPrice,
            parsePrice: widget.parsePrice,
            isPriceFilterApplied: widget.isPriceFilterApplied, // Pass the flag
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
                    selectedCategoryId: widget.selectedCategoryId,
                    selectedBrandName: widget.selectedBrandName,
                    minPrice: widget.minPrice,
                    maxPrice: widget.maxPrice,
                    minPriceController: widget.minPriceController,
                    maxPriceController: widget.maxPriceController,
                    priceStep: widget.priceStep,
                    catalog: widget.catalog.map((category) => {
                      'id': category.id ?? -1,
                      'name': category.name ?? 'Unknown Category',
                      'img': category.imageUrl ?? '',
                    }).toList(),
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
                      // Search query display
                      if (widget.searchQuery.isNotEmpty)
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(bottom: spacing),
                          padding: EdgeInsets.all(spacing),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kết quả tìm kiếm cho: "${widget.searchQuery}"',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tìm thấy ${widget.searchResults.length} sản phẩm',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        // Carousel Section (only show if no search is active)
                        Container(
                          width: mainContentWidth,
                          height: mainContentWidth * 0.3,
                          margin: EdgeInsets.only(bottom: spacing),
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

                      // Sorting Bar Section
                      Container(
                        width: mainContentWidth,
                        padding: EdgeInsets.all(spacing/2),
                        margin: EdgeInsets.only(bottom: spacing),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: SortingBar(
                                width: mainContentWidth * 0.9,
                                onSortChanged: widget.updateSortMethod,
                                currentSortMethod: widget.currentSortMethod,
                                currentSortDir: widget.currentSortDir,
                                buildSortDirectionIndicator: _buildSortDirectionIndicator,
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

                      // Search results or message
                      if (widget.searchQuery.isNotEmpty && widget.searchResults.isEmpty && !widget.isSearching)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(spacing * 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Không tìm thấy sản phẩm phù hợp',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Vui lòng thử tìm kiếm với từ khóa khác',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (widget.searchQuery.isEmpty && !widget.isSearching)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(spacing * 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Hãy nhập từ khóa để tìm kiếm',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Sản phẩm bạn cần sẽ xuất hiện ở đây',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (widget.isSearching && widget.searchResults.isEmpty)
                        // Loading spinner only for the initial search when results are empty
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(spacing * 2),
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(),
                        )
                      else
                        // Product Grid Section
                        SizedBox(
                          width: mainContentWidth,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final double minItemWidth = isMobile ? 160.0 : 200.0;
                              final int maxColumns = (constraints.maxWidth / minItemWidth).floor();
                              final int columns = max(2, min(maxColumns, isMobile ? 2 : 4));
                              final double itemSpacing = spacing * 0.75;
                              
                              return PaginatedProductGrid(
                                productData: widget.searchResults,
                                itemsPerPage: columns * 2,
                                gridWidth: constraints.maxWidth,
                                childAspectRatio: 0.6,
                                crossAxisCount: columns,
                                mainSpace: itemSpacing,
                                crossSpace: itemSpacing,
                                isProductsLoading: widget.isSearching,
                                canLoadMoreProducts: widget.canLoadMore,
                                isShowingCachedContent: false, // Search doesn't use cached content flag
                                isSearchMode: true, // Essential flag to indicate search mode
                                categoryId: -1, // Use -1 for search mode as it doesn't have a specific category
                                sortMethod: widget.currentSortMethod,
                                sortDir: widget.currentSortDir,
                                productWidgetCache: widget.searchWidgetCache, // Pass the cache from widget property
                              );
                            },
                          ),
                        ),

                      // End of results message can stay
                      if (!widget.isSearching && !widget.canLoadMore && widget.searchResults.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: spacing),
                          child: Text(
                            'Đã hiển thị tất cả kết quả',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

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
