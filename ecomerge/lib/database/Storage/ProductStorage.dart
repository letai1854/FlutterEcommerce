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
  bool get isShowingCachedContent => _isReturningVisit;

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
    if (_isSameConfig(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir)) {
      return _cache.canLoadMore;
    }
    
    // Check if global cache has more pages
    final cacheKey = _getCacheKey(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir);
    final cachedConfig = GlobalProductCache.getConfigCache(cacheKey);
    if (cachedConfig != null) {
      return cachedConfig.hasMorePages;
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
          size: 4
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
        GlobalProductCache.setConfigCache(cacheKey, _cache);
        
      } catch (e) {
        if (kDebugMode) print('Error loading initial products: $e');
      } finally {
        _cache.isLoadingInitial = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadNextPage({
    required int categoryId,
    required String sortBy,
    required String sortDir,
  }) async {
    // Only load more if we have the same config and can load more
    if (!_isSameConfig(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir) || !_cache.canLoadMore) {
      return;
    }

    _cache.isLoadingMore = true;
    notifyListeners();

    try {
      // Short delay for loading indicator visibility
      await Future.delayed(const Duration(milliseconds: 500));
      
      final response = await _productService.fetchProducts(
        categoryId: categoryId,
        sortBy: sortBy,
        sortDir: sortDir,
        page: _cache.currentPage + 1,
        size: 4
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
        final cacheKey = _getCacheKey(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir);
        GlobalProductCache.setConfigCache(cacheKey, _cache);
        
        if (kDebugMode) {
          print('Loaded page ${_cache.currentPage}, total products now: ${_cache.products.length}');
          GlobalProductCache.printCache();
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error loading more products: $e');
    } finally {
      _cache.isLoadingMore = false;
      notifyListeners();
    }
  }

  // Reset returning visit flag (call when leaving the page)
  void resetReturnVisitFlag() {
    _isReturningVisit = false;
  }

  @override
  void dispose() {
    _productService.dispose();
    super.dispose();
  }
}
