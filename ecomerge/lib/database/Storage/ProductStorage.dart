import 'dart:async' show TimeoutException;
import 'dart:io';

import 'package:e_commerce_app/database/Storage/BrandCategoryService.dart';
import 'package:e_commerce_app/database/models/brand.dart';
import 'package:flutter/foundation.dart';
import 'package:e_commerce_app/database/models/product_dto.dart';
import 'package:e_commerce_app/database/PageResponse.dart';
import 'package:e_commerce_app/database/services/product_service.dart';
// Add imports for offline support
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';

// Global cache for product data across categories
class GlobalProductCache {
  // Map from cacheKey (categoryId_sortBy_sortDir) to cached data
  static final Map<String, CachedConfigData> _categoryCache = {};
  
  static CachedConfigData? getConfigCache(String key) {
    return _categoryCache[key];
  }
  
  // Enhanced setConfigCache to also save to local storage
  static Future<void> setConfigCache(String key, CachedConfigData cache) async {
    // Update in-memory cache first
    final cachedData = CachedConfigData();
    cachedData.products = List.from(cache.products);
    cachedData.currentPage = cache.currentPage;
    cachedData.totalPages = cache.totalPages;
    cachedData.isInitialized = true;
    cachedData.currentCacheKey = key;
    
    _categoryCache[key] = cachedData;
    
    // Now also save to local storage for offline access
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert products list to JSON
      final productsJson = jsonEncode(cache.products.map((product) => product.toJson()).toList());
      
      // Create a metadata object for additional cache info
      final cacheMetadata = {
        'currentPage': cache.currentPage,
        'totalPages': cache.totalPages,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      // Save both pieces of data with the same key prefix
      await prefs.setString('products_data_$key', productsJson);
      await prefs.setString('products_metadata_$key', jsonEncode(cacheMetadata));
      
      if (kDebugMode) {
        print('Saved to global cache AND local storage - key: $key, products: ${cachedData.products.length}, page: ${cachedData.currentPage}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving product cache to local storage: $e');
      }
    }
  }
  
  // Load cached data from local storage
  static Future<CachedConfigData?> loadFromLocalStorage(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if we have data for this key
      final productsJson = prefs.getString('products_data_$key');
      final metadataJson = prefs.getString('products_metadata_$key');
      
      if (productsJson == null || metadataJson == null) {
        return null; // No data found
      }
      
      // Parse metadata
      final metadata = jsonDecode(metadataJson);
      
      // Parse products
      final List<dynamic> productsData = jsonDecode(productsJson);
      final List<ProductDTO> products = productsData
          .map((json) => ProductDTO.fromJson(json))
          .toList();
      
      // Create and return cache object
      final cachedData = CachedConfigData();
      cachedData.products = products;
      cachedData.currentPage = metadata['currentPage'] ?? 0;
      cachedData.totalPages = metadata['totalPages'] ?? 0;
      cachedData.isInitialized = true;
      cachedData.currentCacheKey = key;
      
      if (kDebugMode) {
        print('Loaded from local storage - key: $key, products: ${cachedData.products.length}, page: ${cachedData.currentPage}');
      }
      
      // Also update in-memory cache
      _categoryCache[key] = cachedData;
      
      return cachedData;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading product cache from local storage: $e');
      }
      return null;
    }
  }
  
  // Clear both in-memory cache and local storage
  static Future<void> clear() async {
    _categoryCache.clear();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      // Remove all product cache keys
      for (final key in keys) {
        if (key.startsWith('products_data_') || key.startsWith('products_metadata_')) {
          await prefs.remove(key);
        }
      }
      
      if (kDebugMode) {
        print('Cleared product cache from both memory and local storage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing product cache from local storage: $e');
      }
    }
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

  ProductStorageSingleton._internal() {
    // Initialize connectivity monitoring
    _initConnectivityMonitoring();
  }

  final CachedConfigData _cache = CachedConfigData();
  final ProductService _productService = ProductService();
  
  // Add connectivity monitoring
  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;
  bool get isOnline => _isOnline;
  
  // Track if this is a returning visit to a category
  bool _isReturningVisit = false;
  // Flag to track if we're immediately showing cached content
  bool get isShowingCachedContent => _isReturningVisit && !_cache.isLoadingMore;
  
  // Initialize connectivity monitoring
  void _initConnectivityMonitoring() {
    // Check initial connectivity
    _checkConnectivity();
    
    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      final wasOffline = !_isOnline;
      _isOnline = (result != ConnectivityResult.none);
      
      if (kDebugMode) {
        print('Connectivity changed: ${result.toString()}');
        print('Is online: $_isOnline');
      }
      
      // If we just went from offline to online, refresh data from server
      if (wasOffline && _isOnline) {
        if (kDebugMode) {
          print('Network restored - immediately refreshing current data');
        }
        
        // Automatically refresh current category's data if available
        if (_cache.isInitialized && _cache.currentCacheKey != null) {
          // Parse the current cache key to get category, sort info
          final keyParts = _cache.currentCacheKey!.split('_');
          if (keyParts.length >= 3) {
            try {
              final categoryId = int.parse(keyParts[0]);
              final sortBy = keyParts[1];
              final sortDir = keyParts[2];
              
              if (kDebugMode) {
                print('Auto-refreshing category $categoryId data with sort $sortBy,$sortDir');
              }
              
              // Force refresh current category data immediately
              _refreshDataIfOnline(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir);
            } catch (e) {
              if (kDebugMode) {
                print('Error parsing cache key for auto-refresh: $e');
              }
            }
          }
        }
      }
    });
  }
  
  // New private method for internal auto-refresh with no UI blocking
  Future<void> _refreshDataIfOnline({
    required int categoryId,
    required String sortBy,
    required String sortDir,
  }) async {
    if (!_isOnline) return;
    
    final cacheKey = _getCacheKey(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir);
    
    // Don't set loading flags - we'll refresh quietly in background
    if (kDebugMode) print('Auto-refreshing data from server for $cacheKey');
    
    try {
      final response = await _productService.fetchProducts(
        categoryId: categoryId,
        sortBy: sortBy,
        sortDir: sortDir,
        page: 0,
        size: 4
      );
      
      // Create a temporary cache object to avoid UI flickering
      final tempCache = CachedConfigData();
      tempCache.products = response.content;
      tempCache.currentPage = response.number;
      tempCache.totalPages = response.totalPages;
      tempCache.isInitialized = true;
      tempCache.currentCacheKey = cacheKey;
      
      // Save to both global cache and local storage
      await GlobalProductCache.setConfigCache(cacheKey, tempCache);
      
      // Only update current cache if it's still the same category being viewed
      if (_cache.isValid(cacheKey)) {
        _cache.products = response.content;
        _cache.currentPage = response.number;
        _cache.totalPages = response.totalPages;
        
        // Notify listeners of the updated data
        notifyListeners();
      }
      
      // Preload images in background
      _productService.preloadProductImages(response.content).catchError((e) {
        if (kDebugMode) print('Error preloading refreshed product images: $e');
      });
      
      if (kDebugMode) {
        print('Successfully auto-refreshed data from server for $cacheKey');
      }
    } catch (e) {
      if (kDebugMode) print('Error auto-refreshing data from server: $e');
    }
  }

  // Update the existing manual refresh method to reuse our new private method
  Future<void> refreshDataIfOnline({
    required int categoryId,
    required String sortBy,
    required String sortDir,
  }) async {
    await _checkConnectivity();
    
    if (!_isOnline) {
      if (kDebugMode) print('Cannot refresh data: Device is offline');
      return;
    }
    
    final cacheKey = _getCacheKey(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir);
    
    if (kDebugMode) print('Manually refreshing data from server for $cacheKey');
    
    // Clear cache for this configuration
    _cache.clear();
    _cache.currentCacheKey = cacheKey;
    _cache.isLoadingInitial = true;
    
    notifyListeners();
    
    // Reuse our shared refresh logic
    await _refreshDataIfOnline(
      categoryId: categoryId, 
      sortBy: sortBy, 
      sortDir: sortDir
    );
    
    _cache.isLoadingInitial = false;
    notifyListeners();
  }

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
    // Always return current cache products, don't check global cache
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
    // Always return false to prevent using cached data
    return false;
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

  // Load initial products for current configuration - enhanced with offline support
  Future<void> loadInitialProducts({
    required int categoryId,
    required String sortBy,
    required String sortDir,
  }) async {
    final cacheKey = _getCacheKey(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir);

    if (kDebugMode) {
      print('loadInitialProducts called for $cacheKey');
    }

    // If already loading, don't start another load
    if (_cache.isLoadingInitial && _cache.isValid(cacheKey)) {
      if (kDebugMode) {
        print('Already loading initial products for $cacheKey, skipping duplicate request');
      }
      return;
    }
    
    // Reset returning visit flag when loading initial products
    _isReturningVisit = false;

    // REMOVE GLOBAL CACHE CHECK - Always clear cache to fetch fresh data
    // Clear cache regardless of whether config changed
    _cache.clear();
    _cache.currentCacheKey = cacheKey;

    // Only start loading if we need data 
    _cache.isLoadingInitial = true;
    notifyListeners();

    try {
      // Check online status first
      await _checkConnectivity();
      
      if (_isOnline) {
        // ONLINE: Always fetch from server
        if (kDebugMode) {
          print('ONLINE: Always fetching fresh data from server for $cacheKey');
        }
        
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
        
        if (kDebugMode) {
          print('Product load success! Total: ${response.content.length} products from server.');
          print('Category: $categoryId, Page: ${response.number}/${response.totalPages}');
        }
        
        // Preload images for better user experience (do this in background)
        _productService.preloadProductImages(response.content).catchError((e) {
          if (kDebugMode) print('Error preloading product images: $e');
        });
        
        // Still save to local storage for offline fallback only
        await GlobalProductCache.setConfigCache(cacheKey, _cache);
        
        if (kDebugMode) {
          print('Successfully loaded fresh products from SERVER for $cacheKey. Total products: ${_cache.products.length}, Page: ${_cache.currentPage}/${_cache.totalPages}');
        }
      } else {
        // OFFLINE: Try to load from local storage
        if (kDebugMode) {
          print('Device is OFFLINE - attempting to load products from local storage for $cacheKey');
        }
        
        final localData = await GlobalProductCache.loadFromLocalStorage(cacheKey);
        
        if (localData != null && localData.products.isNotEmpty) {
          // Use local data
          _cache.products = localData.products;
          _cache.currentPage = localData.currentPage;
          _cache.totalPages = localData.totalPages;
          _cache.isInitialized = true;
          _isReturningVisit = true; // Consider it a returning visit when loading from local storage
          
          if (kDebugMode) {
            print('Successfully loaded initial products from LOCAL STORAGE for $cacheKey. Total products: ${_cache.products.length}, Page: ${_cache.currentPage}/${_cache.totalPages}');
          }
        } else {
          // No local data available
          if (kDebugMode) {
            print('No local data available for $cacheKey while offline');
          }
          _cache.products = [];
          _cache.currentPage = 0;
          _cache.totalPages = 0;
          _cache.isInitialized = true;
        }
      }
      
    } catch (e) {
      if (kDebugMode) print('Error loading initial products for $cacheKey: $e');
      
      // Try loading from local storage as fallback if server request fails
      try {
        final localData = await GlobalProductCache.loadFromLocalStorage(cacheKey);
        
        if (localData != null && localData.products.isNotEmpty) {
          // Use local data as fallback
          _cache.products = localData.products;
          _cache.currentPage = localData.currentPage;
          _cache.totalPages = localData.totalPages;
          _cache.isInitialized = true;
          _isReturningVisit = true;
          
          if (kDebugMode) {
            print('Fallback: loaded initial products from LOCAL STORAGE after server error for $cacheKey');
          }
        }
      } catch (localError) {
        if (kDebugMode) {
          print('Error loading from local storage after server error: $localError');
        }
      }
    } finally {
      _cache.isLoadingInitial = false;
      notifyListeners();
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
      // Check connectivity status
      await _checkConnectivity();

      // Short delay for loading indicator visibility
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (_isOnline) {
        // ONLINE: Fetch from server
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
          await GlobalProductCache.setConfigCache(cacheKey, _cache);
          
          if (kDebugMode) {
            print('Loaded page ${_cache.currentPage} from SERVER for $cacheKey, total products now: ${_cache.products.length}');
            GlobalProductCache.printCache();
          }
        } else {
          if (kDebugMode) {
            print('Received unexpected page number: ${response.number}. Expected: ${_cache.currentPage + 1}');
          }
        }
      } else {
        // OFFLINE: Try to load more from local storage
        if (kDebugMode) {
          print('Device is OFFLINE - attempting to load next page from local storage for $cacheKey');
        }
        
        // When offline and trying to load more, we check if local storage has more data than current cache
        final localData = await GlobalProductCache.loadFromLocalStorage(cacheKey);
        
        if (localData != null && 
            localData.products.length > _cache.products.length && 
            localData.currentPage >= _cache.currentPage + 1) {
          
          // Local storage has more data - add the additional items
          final nextPageItems = localData.products.sublist(_cache.products.length);
          
          _cache.products.addAll(nextPageItems);
          _cache.currentPage = localData.currentPage;
          _cache.totalPages = localData.totalPages;
          
          if (kDebugMode) {
            print('Loaded additional ${nextPageItems.length} products from LOCAL STORAGE for $cacheKey, total products now: ${_cache.products.length}');
          }
        } else {
          if (kDebugMode) {
            print('No additional products available in local storage for $cacheKey while offline');
          }
          // No additional data available in local storage
        }
      }
      
    } catch (e) {
      if (kDebugMode) print('Error loading more products for $cacheKey: $e');
      
      // Try to load next page from local storage as fallback if server request fails
      try {
        final localData = await GlobalProductCache.loadFromLocalStorage(cacheKey);
        
        if (localData != null && 
            localData.products.length > _cache.products.length && 
            localData.currentPage >= _cache.currentPage + 1) {
          
          // Local storage has more data - add the additional items
          final nextPageItems = localData.products.sublist(_cache.products.length);
          
          _cache.products.addAll(nextPageItems);
          _cache.currentPage = localData.currentPage;
          _cache.totalPages = localData.totalPages;
          
          if (kDebugMode) {
            print('Fallback: Loaded additional ${nextPageItems.length} products from LOCAL STORAGE after server error for $cacheKey');
          }
        }
      } catch (localError) {
        if (kDebugMode) {
          print('Error loading next page from local storage after server error: $localError');
        }
      }
    } finally {
      _cache.isLoadingMore = false;
      notifyListeners();
    }
  }
  void resetReturnVisitFlag() {
    _isReturningVisit = false;
  }
 
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
    int maxPrice = 100000000,
    String sortBy = 'createdDate',
    String sortDir = 'desc',
    bool clearCache = true,
    bool skipPriceFilter = false, // <-- EXISTING PARAMETER 
    bool isPriceFilterApplied = false, // <-- NEW PARAMETER
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
    
    // Make sure we use the correct price filter values - very important!
    // Only apply price filter if explicitly requested OR if skipPriceFilter is false and isPriceFilterApplied is true
    bool shouldApplyPriceFilter = !skipPriceFilter && isPriceFilterApplied;
    
    if (kDebugMode) {
      print('Price filter settings:');
      print('skipPriceFilter: $skipPriceFilter');
      print('isPriceFilterApplied: $isPriceFilterApplied');
      print('shouldApplyPriceFilter: $shouldApplyPriceFilter');
      print('minPrice: $minPrice');
      print('maxPrice: $maxPrice');
    }
    
    // Store the price values for future pagination, but only if filter should be applied
    _searchMinPrice = shouldApplyPriceFilter ? minPrice : null;
    _searchMaxPrice = shouldApplyPriceFilter ? maxPrice : null;
    
    _searchSortBy = sortBy;
    _searchSortDir = sortDir;
    
    // Store the price filter application state for future reference
    _isPriceFilterApplied = isPriceFilterApplied;
    
    notifyListeners();
    
    // Add a small delay to ensure UI updates with cleared state
    await Future.delayed(const Duration(milliseconds: 800));
    
    try {
      if (kDebugMode) {
        print('Performing search with parameters:');
        print('Query: $query');
        print('Category ID: $categoryId');
        print('Brand Name: $brandName');
        if (shouldApplyPriceFilter) {
          print('Price Range: $minPrice - $maxPrice (FILTER APPLIED)');
        } else {
          print('Price Range: FILTER NOT APPLIED');
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
      
      // Special handling for price sorting direction
      // For price, we might want ascending (low to high) as default behavior
      String effectiveSortDir = sortDir;
      if (sortBy == 'price') {
        // Log the price sorting direction for debugging
        if (kDebugMode) {
          print('Price sorting requested with direction: $sortDir');
        }
      }
      
      // Make sure to use the determined shouldApplyPriceFilter for API call
      final response = await _productService.fetchProducts(
        search: query,
        categoryId: categoryId,
        brandId: brandId,
        minPrice: shouldApplyPriceFilter ? minPrice.toDouble() : null,
        maxPrice: shouldApplyPriceFilter ? maxPrice.toDouble() : null,
        page: 0,
        size: 4,
        sortBy: sortBy,
        sortDir: effectiveSortDir
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
  int? _searchMinPrice = null; // <-- CHANGE DEFAULT TO NULL 
  int? _searchMaxPrice = null; // <-- CHANGE DEFAULT TO NULL
  String _searchSortBy = 'createdDate';
  String _searchSortDir = 'desc';
  bool _isPriceFilterApplied = false; // <-- ADD THIS FIELD
  
  // Add getter for price filter applied state
  bool get isPriceFilterApplied => _isPriceFilterApplied;
  
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
      
      // Check if we're using price filters - use the stored flag for consistency
      final bool shouldApplyPriceFilter = _isPriceFilterApplied && _searchMinPrice != null && _searchMaxPrice != null;
      
      if (kDebugMode) {
        if (shouldApplyPriceFilter) {
          print('Loading more search results with price filter: $_searchMinPrice - $_searchMaxPrice');
        } else {
          print('Loading more search results WITHOUT price filter');
        }
      }
      
      final response = await _productService.fetchProducts(
        search: _currentSearchQuery,
        categoryId: _searchCategoryId,
        brandId: brandId,
        minPrice: shouldApplyPriceFilter ? _searchMinPrice?.toDouble() : null,
        maxPrice: shouldApplyPriceFilter ? _searchMaxPrice?.toDouble() : null,
        page: _searchCurrentPage + 1,
        size: 4,
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




   Future<void> _checkConnectivity() async {
 
  if(!kIsWeb){

  
  try {
    // Kiểm tra xem thiết bị có phần cứng kết nối đang hoạt động không
    final result = await _connectivity.checkConnectivity();

    // Chỉ kiểm tra sâu hơn nếu có giao diện mạng đang hoạt động
    if (result == ConnectivityResult.none) {
      _isOnline = false;
    } else {
      // *** THAY ĐỔI CHÍNH: Sử dụng InternetAddress.lookup thay vì Socket.connect ***
      try {
        // Chọn một tên miền đáng tin cậy
        const String lookupHost = 'google.com';
        // Thêm timeout cho lookup để tránh treo quá lâu trên mạng rất tệ
        final lookupResult = await InternetAddress.lookup(lookupHost)
                                     .timeout(const Duration(seconds: 1)); // Timeout ngắn cho lookup

        // Nếu lookup thành công và trả về ít nhất một địa chỉ IP hợp lệ
        if (lookupResult.isNotEmpty && lookupResult[0].rawAddress.isNotEmpty) {
          _isOnline = true;
          if (kDebugMode) {
            print('DNS lookup successful for $lookupHost');
          }
        } else {
           // Trường hợp hiếm: lookup thành công nhưng không có địa chỉ?
           _isOnline = false;
           if (kDebugMode) {
             print('DNS lookup for $lookupHost returned empty result.');
           }
        }
      } on SocketException catch (e) {
          // Lỗi phổ biến khi không phân giải được DNS (không có mạng, DNS lỗi)
          _isOnline = false;
          if (kDebugMode) {
            print('DNS lookup failed for: $e');
          }
      } on TimeoutException catch (_) {
          // Lookup mất quá nhiều thời gian
          _isOnline = false;
          if (kDebugMode) {
            print('DNS lookup for  timed out.');
          }
      } catch (e) {
        // Các lỗi không mong muốn khác
        _isOnline = false;
        if (kDebugMode) {
          print('Unexpected error during DNS lookup: $e');
        }
      }
    }

    if (kDebugMode) {
      print('Connectivity check result: $_isOnline (Device interface: $result)');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error checking basic connectivity: $e');
    }
    _isOnline = false; // Mặc định là offline nếu kiểm tra cơ bản thất bại
  }
  }
  else{
    final result = await _connectivity.checkConnectivity();

    // Chỉ kiểm tra sâu hơn nếu có giao diện mạng đang hoạt động
    if (result == ConnectivityResult.none) {
      _isOnline = false;
      return;
    }
    _isOnline = true;
  }
}
}
