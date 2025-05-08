import 'dart:async'; // Import for Timer
import 'package:e_commerce_app/database/Storage/ProductStorage.dart';
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
  final bool isSearchMode; // Add this new flag to distinguish search vs category mode

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

  // Add a public static method for external components to clear search cache
  static void clearSearchCache() {
    if (kDebugMode) print('External call to clear PaginatedProductGrid search cache');
    // Clear all cached widgets
    _PaginatedProductGridState._searchProductCache.clear();
    // Reset query to force detection of changes
    _PaginatedProductGridState._currentSearchQuery = '';
  }

  @override
  _PaginatedProductGridState createState() => _PaginatedProductGridState();
}

class _PaginatedProductGridState extends State<PaginatedProductGrid> with AutomaticKeepAliveClientMixin {
  // Static cache for all product items across all instances
  // This prevents rebuilding products even when the widget is recreated
  static final Map<String, Widget> _globalProductCache = {};
  
  // Separate cache for search results (not persisted between searches)
  static final Map<String, Widget> _searchProductCache = {};
  
  // Track the current search query
  static String _currentSearchQuery = '';
  
  // Force clear search cache when a new search is detected
  static void clearSearchCache() {
    if (kDebugMode) print('Internal call to clear widget search cache');
    _searchProductCache.clear();
    _currentSearchQuery = '';
  }
  
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
    
    // For search mode, use the separate search cache for the CURRENT search session
    if (widget.isSearchMode) {
      final ProductStorageSingleton storage = ProductStorageSingleton();
      final searchQuery = storage.currentSearchQuery;
      
      // Only clear cache if search query changed - this preserves cached widgets
      // during a single search session while loading more results
      if (_currentSearchQuery != searchQuery) {
        if (kDebugMode) print('Search query changed from "$_currentSearchQuery" to "$searchQuery", clearing search widget cache');
        _searchProductCache.clear();
        _currentSearchQuery = searchQuery;
      }
      
      // Create search-specific key that includes the search query 
      // but NOT timestamp - so we can reuse widgets in the same search
      final String searchKey = '${searchQuery}_${product.id}_${product.name}';
      
      // Check if we have this item cached for current search session
      if (_searchProductCache.containsKey(searchKey)) {
        if (kDebugMode) print('Using cached search widget for product ${product.id}');
        return _searchProductCache[searchKey]!;
      }
      
      // Create new widget for this product in current search session
      if (kDebugMode) print('Creating new search widget for product ${product.id}');
      final productWidget = ProductItem(
        key: ValueKey(searchKey),
        productId: product.id ?? 0,
        imageUrl: product.mainImageUrl,
        title: product.name,
        describe: product.description,
        price: product.minPrice ?? 0,
        discount: product.discountPercentage?.toInt(),
        rating: product.averageRating ?? 0,
        isFromCache: false,
        isSearchMode: true,
      );
      
      // Cache the widget for THIS search session only
      _searchProductCache[searchKey] = productWidget;
      return productWidget;
    }
    
    // For category browsing, use the existing global cache logic
    // Check if this specific product's image is cached
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

  // Add this method to ensure search cache is always cleared
  void _ensureSearchCacheIsCleared() {
    if (widget.isSearchMode) {
      // Only clear the cache if the query has changed or we're entering search mode
      final ProductStorageSingleton storage = ProductStorageSingleton();
      final searchQuery = storage.currentSearchQuery;
      
      if (_currentSearchQuery != searchQuery) {
        if (kDebugMode) print('Search query changed: "$_currentSearchQuery" -> "$searchQuery", clearing search widget cache');
        _searchProductCache.clear();
        _currentSearchQuery = searchQuery;
      } else {
        if (kDebugMode) print('Same search query detected, preserving widget cache');
      }
    }
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
    
    // Clear search cache in init if in search mode
    _ensureSearchCacheIsCleared();
    
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

    // Always clear search cache when in search mode
    _ensureSearchCacheIsCleared();

    // If switching between search mode and category mode, update accordingly
    if (widget.isSearchMode != oldWidget.isSearchMode) {
      if (kDebugMode) print('Switching between search mode (${widget.isSearchMode}) and category mode (${!widget.isSearchMode})');
      if (widget.isSearchMode) {
        // When entering search mode, clear the search cache
        _searchProductCache.clear();
      }
    }

    // Force check for search query changes when in search mode
    if (widget.isSearchMode) {
      final ProductStorageSingleton storage = ProductStorageSingleton();
      final searchQuery = storage.currentSearchQuery;
      
      // If search query changed or this is a new search session, clear the cache
      if (_currentSearchQuery != searchQuery) {
        if (kDebugMode) print('Search query changed from "$_currentSearchQuery" to "$searchQuery", clearing search widget cache');
        _searchProductCache.clear();
        _currentSearchQuery = searchQuery;
      }
    }

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    });

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
