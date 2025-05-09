import 'package:e_commerce_app/database/Storage/BrandCategoryService.dart';
import 'package:e_commerce_app/database/models/brand.dart';
import 'package:flutter/foundation.dart';
import 'package:e_commerce_app/database/models/product_dto.dart';
import 'package:e_commerce_app/database/PageResponse.dart';
import 'package:e_commerce_app/database/services/product_service.dart';

// Global cache for product data across categories
class GlobalProductCache {
  // Map from cacheKey (categoryId_sortBy_sortDir) to cached data
  static final Map<String, CachedConfigData> _categoryCache = {};
  
  static CachedConfigData? getConfigCache(String key) {
    return _categoryCache[key];
  }
  
  static void setConfigCache(String key, CachedConfigData cache) {
    final cachedData = CachedConfigData();
    cachedData.products = List.from(cache.products);
    cachedData.currentPage = cache.currentPage;
    cachedData.totalPages = cache.totalPages;
    cachedData.isInitialized = true;
    cachedData.currentCacheKey = key;
    
    _categoryCache[key] = cachedData;
    
    if (kDebugMode) {
      print('Saved to global cache - key: $key, products: ${cachedData.products.length}, page: ${cachedData.currentPage}');
    }
  }
  
  static void clear() {
    _categoryCache.clear();
  }
  
  // For debugging - print all cached categories
  static void printCache() {
    if (kDebugMode) {
      print('--- Global Cache Contents ---');
      _categoryCache.forEach((key, value) {
        print('$key: ${value.products.length} products, page ${value.currentPage}/${value.totalPages}');
      });
      print('---------------------------');
    }
  }
}

class CachedConfigData {
  List<ProductDTO> products = [];
  int currentPage = -1;
  int totalPages = 0;
  bool isInitialized = false;
  bool isLoadingInitial = false;
  bool isLoadingMore = false;

  String? currentCacheKey;
  bool isValid(String cacheKey) => currentCacheKey == cacheKey;

  void clear() {
    products.clear();
    currentPage = -1;
    totalPages = 0;
    isInitialized = false;
    isLoadingInitial = false;
    isLoadingMore = false;
    currentCacheKey = null;
  }

  bool get hasMorePages => isInitialized && currentPage < totalPages - 1;
  bool get canLoadMore => !isLoadingInitial && !isLoadingMore && hasMorePages;
  
  // Create a deep copy of this cache
  CachedConfigData clone() {
    final cloned = CachedConfigData();
    cloned.products = List.from(products);
    cloned.currentPage = currentPage;
    cloned.totalPages = totalPages;
    cloned.isInitialized = isInitialized;
    cloned.isLoadingInitial = isLoadingInitial;
    cloned.isLoadingMore = isLoadingMore;
    cloned.currentCacheKey = currentCacheKey;
    return cloned;
  }
}

class ProductStorageSingleton extends ChangeNotifier {
  static final ProductStorageSingleton _instance = ProductStorageSingleton._internal();

  factory ProductStorageSingleton() {
    return _instance;
  }

  ProductStorageSingleton._internal();

  final CachedConfigData _cache = CachedConfigData();
  final ProductService _productService = ProductService();
  
  // Track if this is a returning visit to a category
  bool _isReturningVisit = false;
  // Flag to track if we're immediately showing cached content
  bool get isShowingCachedContent => _isReturningVisit && !_cache.isLoadingMore;

  String _getCacheKey({
    required int categoryId,
    required String sortBy,
    required String sortDir,
  }) {
    return "${categoryId}_${sortBy}_${sortDir}";
  }

  bool _isSameConfig({
    required int categoryId,
    required String sortBy,
    required String sortDir,
  }) {
    final newKey = _getCacheKey(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir);
    return _cache.isValid(newKey);
  }

  List<ProductDTO> getProductsForConfig({
    required int categoryId,
    required String sortBy,
    required String sortDir,
  }) {
    final cacheKey = _getCacheKey(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir);
    
    // If not current config, check global cache
    if (!_cache.isValid(cacheKey)) {
      final cachedConfig = GlobalProductCache.getConfigCache(cacheKey);
      if (cachedConfig != null && cachedConfig.products.isNotEmpty) {
        // Use the cached data
        if (kDebugMode) {
          print('Found cached data for $cacheKey with ${cachedConfig.products.length} products, page ${cachedConfig.currentPage}');
        }
        
        _isReturningVisit = true;
        
        // Copy cached data to current cache
        _cache.products = List.from(cachedConfig.products);
        _cache.currentPage = cachedConfig.currentPage;
        _cache.totalPages = cachedConfig.totalPages;
        _cache.isInitialized = true;
        _cache.currentCacheKey = cacheKey;
        _cache.isLoadingInitial = false;
        _cache.isLoadingMore = false;
        
        // No notify needed - caller will use returned product list
      }
    }
    
    return _cache.products;
  }

  bool isConfigInitialized({
    required int categoryId,
    required String sortBy,
    required String sortDir,
  }) {
    // Check current cache first
    if (_isSameConfig(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir) && _cache.isInitialized) {
      return true;
    }
    
    // Then check global cache
    final cacheKey = _getCacheKey(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir);
    final cachedConfig = GlobalProductCache.getConfigCache(cacheKey);
    return cachedConfig != null && cachedConfig.isInitialized;
  }

  bool isInitialLoading({
    required int categoryId,
    required String sortBy,
    required String sortDir,
  }) {
    return _isSameConfig(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir) && _cache.isLoadingInitial;
  }

  bool isLoadingMore({
    required int categoryId,
    required String sortBy,
    required String sortDir,
  }) {
    return _isSameConfig(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir) && _cache.isLoadingMore;
  }

  bool canLoadMore({
    required int categoryId,
    required String sortBy,
    required String sortDir,
  }) {
    // Get the cache key for this configuration
    final cacheKey = _getCacheKey(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir);
    
    // Check current cache first
    if (_isSameConfig(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir)) {
      if (kDebugMode && _cache.currentPage >= 0) {
        // Add extra logging to help diagnose loading issues
        print('canLoadMore check: currentPage=${_cache.currentPage}, totalPages=${_cache.totalPages}');
        print('canLoadMore check: isLoadingInitial=${_cache.isLoadingInitial}, isLoadingMore=${_cache.isLoadingMore}');
        print('canLoadMore result: ${_cache.canLoadMore}');
      }
      return _cache.canLoadMore;
    }
    
    // Check if global cache has more pages
    final cachedConfig = GlobalProductCache.getConfigCache(cacheKey);
    if (cachedConfig != null) {
      if (kDebugMode && cachedConfig.currentPage >= 0) {
        print('canLoadMore (global cache): currentPage=${cachedConfig.currentPage}, totalPages=${cachedConfig.totalPages}');
        print('canLoadMore (global cache): hasMorePages=${cachedConfig.hasMorePages}');
      }
      return cachedConfig.hasMorePages;
    }
    
    if (kDebugMode) {
      print('canLoadMore: No cache found for $cacheKey, returning default false');
    }
    return false;
  }

  bool hasDataInCache({
    required int categoryId,
    required String sortBy,
    required String sortDir,
  }) {
    // First check current cache
    if (_isSameConfig(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir) && 
        _cache.isInitialized && 
        _cache.products.isNotEmpty) {
      return true;
    }
    
    // Then check global cache
    final cacheKey = _getCacheKey(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir);
    final cachedConfig = GlobalProductCache.getConfigCache(cacheKey);
    return cachedConfig != null && cachedConfig.isInitialized && cachedConfig.products.isNotEmpty;
  }

  int getCachedPage({
    required int categoryId,
    required String sortBy, 
    required String sortDir,
  }) {
    if (_isSameConfig(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir) && _cache.isInitialized) {
      return _cache.currentPage;
    }
    
    // Check global cache
    final cacheKey = _getCacheKey(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir);
    final cachedConfig = GlobalProductCache.getConfigCache(cacheKey);
    if (cachedConfig != null && cachedConfig.isInitialized) {
      return cachedConfig.currentPage;
    }
    
    return -1;
  }

  int getCachedTotalPages({
    required int categoryId,
    required String sortBy,
    required String sortDir,
  }) {
    if (_isSameConfig(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir) && _cache.isInitialized) {
      return _cache.totalPages;
    }
    
    // Check global cache
    final cacheKey = _getCacheKey(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir);
    final cachedConfig = GlobalProductCache.getConfigCache(cacheKey);
    if (cachedConfig != null && cachedConfig.isInitialized) {
      return cachedConfig.totalPages;
    }
    
    return 0;
  }

  Future<void> loadInitialProducts({
    required int categoryId,
    required String sortBy,
    required String sortDir,
  }) async {
    final cacheKey = _getCacheKey(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir);

    // If already loading, don't start another load
    if (_cache.isLoadingInitial && _cache.isValid(cacheKey)) {
      return;
    }
    
    // Reset returning visit flag when loading initial products
    _isReturningVisit = false;

    // Check global cache for this config
    if (!_cache.isValid(cacheKey)) {
      final cachedConfig = GlobalProductCache.getConfigCache(cacheKey);
      if (cachedConfig != null && cachedConfig.products.isNotEmpty) {
        // Use cached data
        if (kDebugMode) {
          print('Using cached data for $cacheKey with ${cachedConfig.products.length} products');
        }
        
        _isReturningVisit = true;
        
        // Copy cached data to current cache
        _cache.products = List.from(cachedConfig.products);
        _cache.currentPage = cachedConfig.currentPage;
        _cache.totalPages = cachedConfig.totalPages;
        _cache.isInitialized = true;
        _cache.currentCacheKey = cacheKey;
        _cache.isLoadingInitial = false;
        _cache.isLoadingMore = false;
        
        notifyListeners();
        return;
      }
      
      // Clear cache if changing config
      _cache.clear();
      _cache.currentCacheKey = cacheKey;
    }

    // Only start loading if we need data
    if (!_cache.isInitialized || _cache.products.isEmpty) {
      _cache.isLoadingInitial = true;
      notifyListeners();

      try {
        final response = await _productService.fetchProducts(
          categoryId: categoryId,
          sortBy: sortBy,
          sortDir: sortDir,
          page: 0,
          size: 3
        );

        _cache.products = response.content;
        _cache.currentPage = response.number;
        _cache.totalPages = response.totalPages;
        _cache.isInitialized = true;
        
        // Preload images for better user experience (do this in background)
        _productService.preloadProductImages(response.content).catchError((e) {
          if (kDebugMode) print('Error preloading product images: $e');
        });
        
        // Save to global cache immediately
        // Save to global cache immediately
        GlobalProductCache.setConfigCache(cacheKey, _cache);
        
        if (kDebugMode) {
          print('Successfully loaded initial products for $cacheKey. Total products: ${_cache.products.length}, Page: ${_cache.currentPage}/${_cache.totalPages}');
        }
        
      } catch (e) {
        if (kDebugMode) print('Error loading initial products for $cacheKey: $e');
      } finally {
        _cache.isLoadingInitial = false;
        // Notify listeners AFTER state is updated
        notifyListeners();
      }
    } else {
       if (kDebugMode) {
          print('Initial products for $cacheKey already loaded or cached.');
       }
    }
  }

  Future<void> loadNextPage({
    required int categoryId,
    required String sortBy,
    required String sortDir,
  }) async {
    final cacheKey = _getCacheKey(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir);
    
    // Enhanced logging to help diagnose loading issues
    if (kDebugMode) {
      print('loadNextPage called for $cacheKey');
      print('Current cache state: isLoadingMore=${_cache.isLoadingMore}, currentPage=${_cache.currentPage}, totalPages=${_cache.totalPages}');
    }
    
    // Only load more if we have the same config and can load more
    if (!_isSameConfig(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir)) {
       if (kDebugMode) {
          print('Cannot load next page: Different config. Current cache key: ${_cache.currentCacheKey}, requested: $cacheKey');
       }
      return;
    }
    
    if (!_cache.canLoadMore) {
       if (kDebugMode) {
          print('Cannot load next page: canLoadMore=false. isLoadingInitial=${_cache.isLoadingInitial}, isLoadingMore=${_cache.isLoadingMore}, hasMorePages=${_cache.hasMorePages}');
       }
      return;
    }

    // Important: When loading more, we're not showing cached content anymore
    // For spinner control purposes
    _cache.isLoadingMore = true;
    
    // Notify to show loading indicator
    notifyListeners(); 

    try {
      // Short delay for loading indicator visibility - increased for better user experience
      await Future.delayed(const Duration(milliseconds: 800));
      
      final response = await _productService.fetchProducts(
        categoryId: categoryId,
        sortBy: sortBy,
        sortDir: sortDir,
        page: _cache.currentPage + 1,
        size: 3
      );

      if (response.number == _cache.currentPage + 1) {
        _cache.products.addAll(response.content);
        _cache.currentPage = response.number;
        _cache.totalPages = response.totalPages;
        
        // Preload images for new products
        _productService.preloadProductImages(response.content).catchError((e) {
          if (kDebugMode) print('Error preloading new page product images: $e');
        });
        
        // Update global cache with new data
        GlobalProductCache.setConfigCache(cacheKey, _cache);
        
        if (kDebugMode) {
          print('Loaded page ${_cache.currentPage} for $cacheKey, total products now: ${_cache.products.length}');
          GlobalProductCache.printCache();
        }
      } else {
         if (kDebugMode) {
            print('Received unexpected page number: ${response.number}. Expected: ${_cache.currentPage + 1}');
         }
      }
    } catch (e) {
      if (kDebugMode) print('Error loading more products for $cacheKey: $e');
    } finally {
      _cache.isLoadingMore = false;
      // Notify listeners AFTER state is updated
      notifyListeners();
    }
  }

  // Reset returning visit flag (call when leaving the page)
  void resetReturnVisitFlag() {
    _isReturningVisit = false;
  }

  // Add search-specific state
  final List<ProductDTO> _searchResults = [];
  int _searchCurrentPage = -1;
  int _searchTotalPages = 0;
  bool _isSearchLoading = false;
  bool _canSearchLoadMore = true;
  String _currentSearchQuery = '';
  
  // Search-related getters
  List<ProductDTO> get searchResults => _searchResults;
  bool get isSearchLoading => _isSearchLoading;
  bool get canSearchLoadMore => _canSearchLoadMore && !_isSearchLoading;
  String get currentSearchQuery => _currentSearchQuery;
  
  // Add an explicit method to clear search cache
  void clearSearchCache() {
    if (kDebugMode) print('Explicitly clearing all search-related cache');
    _searchResults.clear();
    _searchCurrentPage = -1;
    _isSearchLoading = false;
    _canSearchLoadMore = true;
    
    // No need to clear _currentSearchQuery here as it will be set in performSearch
    notifyListeners();
  }
  
  // Method to perform initial search
  Future<void> performSearch(
    String query, {
    int? categoryId,
    String? brandName,
    int minPrice = 0,
    int maxPrice = 10000000,
    String sortBy = 'createdDate',
    String sortDir = 'desc',
    bool clearCache = true,
    bool skipPriceFilter = false // <-- ADD THIS PARAMETER
  }) async {
    // Clear all search-related cache if needed
    if (clearCache) {
      if (kDebugMode) print('Explicitly clearing all search-related cache');
      _searchResults.clear();
      _searchCurrentPage = -1;
      _isSearchLoading = false;
      _canSearchLoadMore = true;
    }
    
    // Set the new query
    _currentSearchQuery = query;
    _isSearchLoading = true;
    
    // Store current filter and sort parameters for pagination
    _searchCategoryId = categoryId;
    _searchBrandName = brandName;
    _searchMinPrice = skipPriceFilter ? null : minPrice; // <-- SET TO NULL IF SKIPPING
    _searchMaxPrice = skipPriceFilter ? null : maxPrice; // <-- SET TO NULL IF SKIPPING
    _searchSortBy = sortBy;
    _searchSortDir = sortDir;
    
    notifyListeners();
    
    // Add a small delay to ensure UI updates with cleared state
    await Future.delayed(const Duration(milliseconds: 800));
    
    try {
      if (kDebugMode) {
        print('Performing search with parameters:');
        print('Query: $query');
        print('Category ID: $categoryId');
        print('Brand Name: $brandName');
        if (skipPriceFilter) {
          print('Price Range: NO PRICE FILTER APPLIED (returning ALL prices)');
        } else {
          print('Price Range: $minPrice - $maxPrice');
        }
        print('Sort: $sortBy $sortDir');
      }
      
      // Get brand ID from name if provided
      int? brandId;
      if (brandName != null && brandName.isNotEmpty) {
        final brands = AppDataService().brands;
        final brand = brands.firstWhere(
          (b) => b.name == brandName, 
          orElse: () => BrandDTO()
        );
        brandId = brand.id;
        
        if (kDebugMode) {
          print('Resolved brand name "$brandName" to ID: $brandId');
        }
      }
      
      final response = await _productService.fetchProducts(
        search: query,
        categoryId: categoryId,
        brandId: brandId,
        minPrice: skipPriceFilter ? null : minPrice.toDouble(), // <-- PASS NULL IF SKIPPING
        maxPrice: skipPriceFilter ? null : maxPrice.toDouble(), // <-- PASS NULL IF SKIPPING
        page: 0,
        size: 3, // Explicitly set to load only 3 products initially, matching category behavior
        sortBy: sortBy,
        sortDir: sortDir
      );
      
      _searchResults.clear(); // Clear again in case other search results were added
      _searchResults.addAll(response.content);
      _searchCurrentPage = response.number;
      _searchTotalPages = response.totalPages;
      _canSearchLoadMore = response.number < response.totalPages - 1;
      
      if (kDebugMode) {
        print('Initial search results: ${_searchResults.length} products');
        print('Search pagination: page ${response.number + 1} of ${response.totalPages}');
        print('Can load more search results: $_canSearchLoadMore');
      }
    } catch (e) {
      if (kDebugMode) print('Error performing search: $e');
    } finally {
      _isSearchLoading = false;
      notifyListeners();
    }
  }
  
  // Store current search parameters for pagination - update to use nullable types for price
  int? _searchCategoryId;
  String? _searchBrandName;
  int? _searchMinPrice = 0; // <-- CHANGE TO NULLABLE
  int? _searchMaxPrice = 10000000; // <-- CHANGE TO NULLABLE
  String _searchSortBy = 'createdDate';
  String _searchSortDir = 'desc';
  
  // Method to load next page of search results
  Future<void> loadMoreSearchResults() async {
    if (_isSearchLoading || !_canSearchLoadMore) {
      if (kDebugMode) {
        print('Skip loading more search results: isLoading=$_isSearchLoading, canLoadMore=$_canSearchLoadMore');
      }
      return;
    }
    
    _isSearchLoading = true;
    notifyListeners();
    
    try {
      // Use same loading delay as category browsing for consistency
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Get brand ID from name if provided
      int? brandId;
      if (_searchBrandName != null && _searchBrandName!.isNotEmpty) {
        final brands = AppDataService().brands;
        final brand = brands.firstWhere(
          (b) => b.name == _searchBrandName, 
          orElse: () => BrandDTO()
        );
        brandId = brand.id;
      }
      
      // Check if we're using price filters
      final bool usingPriceFilter = _searchMinPrice != null && _searchMaxPrice != null;
      if (kDebugMode) {
        if (usingPriceFilter) {
          print('Loading more search results with price filter: $_searchMinPrice - $_searchMaxPrice');
        } else {
          print('Loading more search results WITHOUT price filter');
        }
      }
      
      final response = await _productService.fetchProducts(
        search: _currentSearchQuery,
        categoryId: _searchCategoryId,
        brandId: brandId,
        minPrice: _searchMinPrice?.toDouble(), // <-- USE NULL-AWARE OPERATOR
        maxPrice: _searchMaxPrice?.toDouble(), // <-- USE NULL-AWARE OPERATOR
        page: _searchCurrentPage + 1,
        size: 3, // Consistently use 3 products per page to match category browsing
        sortBy: _searchSortBy,
        sortDir: _searchSortDir
      );
      
      _searchResults.addAll(response.content);
      _searchCurrentPage = response.number;
      _searchTotalPages = response.totalPages;
      _canSearchLoadMore = response.number < response.totalPages - 1;
      
      if (kDebugMode) {
        print('Added more search results: ${response.content.length} new products');
        print('Total search results now: ${_searchResults.length}');
        print('Search pagination: page ${_searchCurrentPage + 1} of ${_searchTotalPages}');
        print('Can load more search results: $_canSearchLoadMore');
      }
      
      // Preload images for new items in background, matching category behavior
      _productService.preloadProductImages(response.content).catchError((e) {
        if (kDebugMode) print('Error preloading new search result images: $e');
      });
      
    } catch (e) {
      if (kDebugMode) print('Error loading more search results: $e');
    } finally {
      _isSearchLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _productService.dispose();
    super.dispose();
  }
}
