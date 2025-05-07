import 'dart:async'; // Import for Timer
import 'package:e_commerce_app/database/models/product_dto.dart';
import 'package:e_commerce_app/database/services/product_service.dart';
import 'package:e_commerce_app/widgets/Product/ProductItem.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class PaginatedProductGrid extends StatefulWidget {
  final List<ProductDTO> productData;
  final int itemsPerPage;
  final double gridWidth;
  final double childAspectRatio;
  final int crossAxisCount;
  final double mainSpace;
  final double crossSpace;
  final bool isProductsLoading; // This prop signals when the grid is fetching more data
  final bool canLoadMoreProducts;
  final bool isShowingCachedContent; // Add this flag

  const PaginatedProductGrid({
    Key? key,
    required this.productData,
    required this.itemsPerPage,
    required this.gridWidth,
    required this.childAspectRatio,
    required this.crossAxisCount,
    required this.mainSpace,
    required this.crossSpace,
    required this.isProductsLoading,
    required this.canLoadMoreProducts,
    required this.isShowingCachedContent, // Add this parameter
  }) : super(key: key);

  @override
  _PaginatedProductGridState createState() => _PaginatedProductGridState();
}

class _PaginatedProductGridState extends State<PaginatedProductGrid> with AutomaticKeepAliveClientMixin {
  // Static cache for all product items across all instances
  // This prevents rebuilding products even when the widget is recreated
  static final Map<String, Widget> _globalProductCache = {};
  
  // Track the category and sort method to detect real changes vs just loading more
  String? _currentCategory;
  String? _currentSortMethod;
  
  // Track previous length to detect new items
  int _previousDataLength = 0;
  
  // RE-INTRODUCE: Timer and state for delayed loader for the grid itself
  Timer? _gridLoaderTimer;
  bool _showArtificialGridLoader = false;
  bool _wasGridLoadingArtificially = false; 

  // Create and cache product item widgets
  Widget _buildOrGetGridItem(ProductDTO product, int index) {
    final String key = '${product.id}_${product.name}'; // Unique key for each product
    
    // Create ProductService instance to check image cache status
    final productService = ProductService();
    
    // Check if this specific product's image is cached - this is the key fix
    final bool isImageCached = product.mainImageUrl != null && 
                              productService.isImageCached(product.mainImageUrl);
    
    // Return cached widget if available
    if (_globalProductCache.containsKey(key)) {
      if (kDebugMode) print('Using cached widget for product ${product.id}');
      
      // For cached widgets, we still need to update the isFromCache flag
      // Get the existing widget
      final existingWidget = _globalProductCache[key] as ProductItem;
      
      // Create a new widget with updated isFromCache flag if needed
      if (widget.isShowingCachedContent && isImageCached) {
        final updatedWidget = ProductItem(
          key: ValueKey(key),
          productId: product.id ?? 0,
          imageUrl: product.mainImageUrl,
          title: product.name,
          describe: product.description,
          price: product.minPrice ?? 0,
          discount: product.discountPercentage?.toInt(),
          rating: product.averageRating ?? 0,
          isFromCache: true, // Use proper flag based on image cache status
        );
        
        // Update the cache with the new widget
        _globalProductCache[key] = updatedWidget;
        return updatedWidget;
      }
      
      return existingWidget;
    }
    
    // Create and cache new widget
    if (kDebugMode) print('Creating new widget for product ${product.id}');
    final productWidget = ProductItem(
      key: ValueKey(key),
      productId: product.id ?? 0,
      imageUrl: product.mainImageUrl,
      title: product.name,
      describe: product.description,
      price: product.minPrice ?? 0,
      discount: product.discountPercentage?.toInt(),
      rating: product.averageRating ?? 0,
      isFromCache: widget.isShowingCachedContent && isImageCached, // Only true if both category is cached AND image is cached
    );
    
    _globalProductCache[key] = productWidget;
    return productWidget;
  }
  
  // Extract category and sort info from product list
  void _updateCurrentConfig() {
    if (widget.productData.isEmpty) return;
    
    try {
      // Extract info from the parent widget's key if possible
      final parentKey = (context.findAncestorWidgetOfExactType<KeyedSubtree>()?.key as ValueKey?)?.value;
      if (parentKey is String) {
        final parts = parentKey.split('_');
        if (parts.length >= 2) {
          final newCategory = parts[0];
          final newSortMethod = parts[1];
          
          final categoryChanged = _currentCategory != null && _currentCategory != newCategory;
          final sortMethodChanged = _currentSortMethod != null && _currentSortMethod != newSortMethod;
          
          // Clear cache if actual sort or category changed
          if (categoryChanged || sortMethodChanged) {
            if (kDebugMode) print('Category or sort method changed, clearing cache');
            _globalProductCache.clear();
          }
          
          _currentCategory = newCategory;
          _currentSortMethod = newSortMethod;
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error extracting config: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _previousDataLength = widget.productData.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCurrentConfig();
    });
  }

  @override
  void didUpdateWidget(PaginatedProductGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCurrentConfig();
    });

    // Enhanced loading state detection
    final bool isCurrentlyLoadingGridData = widget.isProductsLoading;
    final bool wasLoadingGridData = oldWidget.isProductsLoading;
    final bool hasGridProducts = widget.productData.isNotEmpty;
    
    // Don't show loading indicator if we are showing cached products
    if (widget.isShowingCachedContent && hasGridProducts) {
      // If showing cached content, ensure no loading spinner
      if (_showArtificialGridLoader) {
        if (mounted) {
          setState(() {
            _showArtificialGridLoader = false;
            _wasGridLoadingArtificially = false;
          });
        }
      }
      _gridLoaderTimer?.cancel();
      return;
    }
    
    // Only show loading indicator when:
    // 1. We're loading AND we already have products
    // 2. AND the loading is for more products (not just showing cached data)
    // 3. AND we have more products now than before (indicating new data is being added)
    final bool shouldShowLoadingIndicator = 
        isCurrentlyLoadingGridData && 
        hasGridProducts && 
        (widget.productData.length > _previousDataLength || 
         (isCurrentlyLoadingGridData != wasLoadingGridData && !_showArtificialGridLoader));

    // Loading state has changed
    if (shouldShowLoadingIndicator) {
      // Loading just started - show loader immediately only for new data
      if (mounted) {
        setState(() {
          _showArtificialGridLoader = true;
          _wasGridLoadingArtificially = true;
        });
      }
      
      // Ensure minimum display time of 2 seconds for better visibility
      _gridLoaderTimer?.cancel();
      _gridLoaderTimer = Timer(const Duration(milliseconds: 2000), () {
        if (mounted) {
          setState(() {
            // Only hide if loading has finished by then
            if (!widget.isProductsLoading) {
              _showArtificialGridLoader = false;
              _wasGridLoadingArtificially = false;
            }
          });
        }
      });
    } else if (!isCurrentlyLoadingGridData && _wasGridLoadingArtificially) {
      // Loading just finished
      // If less than minimum time passed, keep showing loader until timer completes
      if (_gridLoaderTimer == null || !_gridLoaderTimer!.isActive) {
        if (mounted) {
          setState(() {
            _showArtificialGridLoader = false;
            _wasGridLoadingArtificially = false;
          });
        }
      }
    }
    
    // Track product data changes - only when product count increases
    final newItemsCount = widget.productData.length - _previousDataLength;
    if (newItemsCount > 0) {
      if (kDebugMode) print('Added $newItemsCount new products to the grid');
    }
    
    _previousDataLength = widget.productData.length;
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

    // Show loader only when:
    // 1. We've manually activated it via _showArtificialGridLoader
    // 2. OR We're actively loading more products (not just showing cached data)
    final bool showGridLoader = _showArtificialGridLoader && !widget.isShowingCachedContent;
    
    return Container(
      width: widget.gridWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.productData.isEmpty && !widget.isProductsLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Text(
                  'Không có sản phẩm nào trong danh mục này',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.crossAxisCount,
                childAspectRatio: widget.childAspectRatio,
                mainAxisSpacing: widget.mainSpace,
                crossAxisSpacing: widget.crossSpace,
              ),
              itemCount: widget.productData.length,
              itemBuilder: (context, index) {
                final product = widget.productData[index];
                return _buildOrGetGridItem(product, index);
              },
              // This prevents the grid from rebuilding when scrolling:
              addRepaintBoundaries: true,
              addAutomaticKeepAlives: true,
            ),

          // Make the loading indicator more prominent
          if (showGridLoader) 
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Đang tải thêm sản phẩm...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // "No more products" message - only show when not loading and canLoadMoreProducts is false
          if (!widget.isProductsLoading && !_showArtificialGridLoader && 
              !widget.canLoadMoreProducts && widget.productData.isNotEmpty) 
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Không còn sản phẩm nào để hiển thị',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _gridLoaderTimer?.cancel(); // Cancel grid loader timer on dispose
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true; // Keep this widget alive when scrolling
}
