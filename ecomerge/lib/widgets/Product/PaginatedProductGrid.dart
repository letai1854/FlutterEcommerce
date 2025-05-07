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
  final bool isSearchMode; // Add this flag to avoid caching in search

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
    this.isSearchMode = false, // Default to false for backward compatibility
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

  // Track if we need to check for "load more" after build
  bool _checkLoadMoreAfterBuild = false;

  // Create and cache product item widgets
  Widget _buildOrGetGridItem(ProductDTO product, int index) {
    final String key = '${product.id}_${product.name}'; // Unique key for each product
    
    // Create ProductService instance to check image cache status
    final productService = ProductService();
    
    // Check if this specific product's image is cached - this is the key fix
    final bool isImageCached = product.mainImageUrl != null && 
                              productService.isImageCached(product.mainImageUrl);
    
    // Skip caching for search results
    if (widget.isSearchMode) {
      // Always create a new widget for search results
      return ProductItem(
        key: ValueKey(key),
        productId: product.id ?? 0,
        imageUrl: product.mainImageUrl,
        title: product.name,
        describe: product.description,
        price: product.minPrice ?? 0,
        discount: product.discountPercentage?.toInt(),
        rating: product.averageRating ?? 0,
        isFromCache: isImageCached, // Only set true if image is cached
      );
    }
    
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
      // Check if we should trigger load more after initial build
      if (widget.productData.isNotEmpty && 
          widget.canLoadMoreProducts && 
          !widget.isProductsLoading) {
        _checkLoadMoreAfterBuild = true;
      }
    });
  }

  @override
  void didUpdateWidget(PaginatedProductGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Schedule update for current configuration
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCurrentConfig();
    });
    
    // Check if we should verify loading more after this build
    if (widget.productData.isNotEmpty && 
        widget.canLoadMoreProducts &&
        !widget.isProductsLoading && 
        oldWidget.productData.length == widget.productData.length) {
      // If we have products, can load more, but length hasn't changed,
      // check if we're near the bottom to trigger more loading
      _checkLoadMoreAfterBuild = true;
    }

    // Enhanced loading state detection
    final bool isCurrentlyLoadingGridData = widget.isProductsLoading;
    final bool wasLoadingGridData = oldWidget.isProductsLoading;
    final bool hasGridProducts = widget.productData.isNotEmpty;
    
    // FIXED LOGIC: Only disable spinner for INITIAL cached content 
    // If we're showing more products (length increased), we should show spinner even with cached content
    final bool initialCachedContentLoad = widget.isShowingCachedContent && 
                                          hasGridProducts &&
                                          widget.productData.length <= _previousDataLength;
    
    if (initialCachedContentLoad) {
      // Only suppress spinner for initial load of cached content
      if (_showArtificialGridLoader) {
        if (mounted) {
          setState(() {
            _showArtificialGridLoader = false;
            _wasGridLoadingArtificially = false;
          });
        }
      }
      _gridLoaderTimer?.cancel();
      
      // Don't return here - we need to continue to handle loading more products
    }
    
    // Only show loading indicator when:
    // 1. We're loading AND we already have products
    // 2. AND the loading is for more products (product list grew larger)
    // 3. OR loading state changed from not loading to loading
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
    
    // Check if we should notify parent to load more
    if (_checkLoadMoreAfterBuild) {
      _checkLoadMoreAfterBuild = false;
      
      // Use a post-frame callback to avoid build-phase setState calls
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && 
            widget.productData.isNotEmpty && 
            widget.canLoadMoreProducts &&
            !widget.isProductsLoading) {
          if (kDebugMode) print("Grid suggesting parent should check for load more");
          
          // Send a notification up to PageListProduct via NotificationListener
          // This is more reliable than relying only on scroll listener
          LoadMoreNotification().dispatch(context);
        }
      });
    }

    // FIXED LOGIC: Show loader when explicitly enabled, don't 
    // automatically disable based on cached content status
    final bool showGridLoader = _showArtificialGridLoader;
    
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

// Add a custom notification that will bubble up to trigger loading
class LoadMoreNotification extends Notification {}
