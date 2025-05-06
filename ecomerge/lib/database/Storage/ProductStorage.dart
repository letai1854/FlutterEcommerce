import 'package:flutter/foundation.dart';
import 'package:e_commerce_app/database/models/product_dto.dart';
import 'package:e_commerce_app/database/PageResponse.dart';
import 'package:e_commerce_app/database/services/product_service.dart'; // Import ProductService

// Lớp lưu trữ dữ liệu cache cho MỘT CẤU HÌNH tải cụ thể (category + sort + search + ...)
class CachedProductData {
  List<ProductDTO> products = [];
  int currentPage = -1; // Start at -1 to indicate no page loaded yet for this config
  int totalPages = 0; // Initialize with 0
  bool isLoadingInitial = false; // Flag for loading the first page (page 0)
  bool isLoadingMore = false; // Flag for loading subsequent pages (page > 0)
  bool isInitialized = false; // Has at least one page been successfully loaded for this config?

  // Store the configuration that this cache currently holds
  int? categoryId;
  String? sortBy;
  String? sortDir;
  String? searchTerm;
  // Add other filter parameters here if needed

  // Constructor takes the specific configuration it will cache
  CachedProductData({
    required this.categoryId,
    required this.sortBy,
    required this.sortDir,
    this.searchTerm,
  });

  // Method to add products from a PageResponse
  // This method is called BY the singleton after fetching data
  void addPage(PageResponse<ProductDTO> pageResponse) {
    // IMPORTANT: This method assumes the pageResponse corresponds to the config
    // and the sequential page expected. The singleton should ensure this.

    if (!isInitialized) {
        // This is the first page (page 0) load for this specific config
        products.clear(); // Clear any previous data (important if resetting config)
        currentPage = pageResponse.number; // Should be 0
        totalPages = pageResponse.totalPages;
        products.addAll(pageResponse.content);
        isInitialized = true; // Mark as initialized
        isLoadingInitial = false; // Stop initial loading
        isLoadingMore = false; // Ensure loading more is false
        if (kDebugMode) print("ProductStorageSingleton/CacheData: Initial page ${pageResponse.number} loaded for config cat:$categoryId, sort:$sortBy, dir:$sortDir. Total products: ${products.length}. Total pages: ${totalPages}.");
    } else if (pageResponse.number == currentPage + 1) {
      // Adding the next consecutive page
      currentPage = pageResponse.number; // Update current page (e.g., from 0 to 1, 1 to 2)
      totalPages = pageResponse.totalPages; // Update total pages (might change unexpectedly, though unlikely for a given query)
      products.addAll(pageResponse.content);
      isLoadingMore = false; // Stop loading more
      if (kDebugMode) print("ProductStorageSingleton/CacheData: Page ${pageResponse.number} added for config cat:$categoryId, sort:$sortBy, dir:$sortDir. Total products: ${products.length}. Total pages: ${totalPages}.");
    } else {
       // This case happens if we skip pages or receive a page out of sequence.
       // For this logic, we expect sequential page loads (0, 1, 2...).
       // We will ignore the data and log a warning, resetting loading states.
       if (kDebugMode) print("ProductStorageSingleton/CacheData: Warning - Received non-consecutive page ${pageResponse.number} for config cat:$categoryId, sort:$sortBy, dir:$sortDir (current: $currentPage). Data ignored.");
       isLoadingInitial = false; // Reset loading states in case of unexpected response
       isLoadingMore = false;
    }
  }

  // Check if this cache instance holds data for the requested configuration
  bool matchesConfig({
    required int categoryId,
    required String sortBy,
    required String sortDir,
    String? searchTerm,
    // Add other filters here
  }) {
    return this.categoryId == categoryId &&
           this.sortBy == sortBy &&
           this.sortDir == sortDir &&
           this.searchTerm == searchTerm; // Basic comparison, adjust for complex filters
  }

  // Reset cache data and update the configuration it represents
  void resetConfig({
     required int categoryId,
     required String sortBy,
     required String sortDir,
     String? searchTerm,
     // Add other filters here
  }) {
     if (kDebugMode) print("ProductStorageSingleton/CacheData: Resetting cache for config cat:$categoryId, sort:$sortBy, dir:$sortDir.");
     products.clear();
     currentPage = -1; // Reset to -1 as no page is loaded for this new config
     totalPages = 0;
     isLoadingInitial = false;
     isLoadingMore = false;
     isInitialized = false; // Reset initialization state
     // Update the configuration fields
     this.categoryId = categoryId;
     this.sortBy = sortBy;
     this.sortDir = sortDir;
     this.searchTerm = searchTerm;
     // Update other filters here
  }


  // Check if there are more pages to load for this configuration
  // Returns true only if already initialized and currentPage is not the last page
  bool get hasMorePages => isInitialized && currentPage < totalPages - 1 && totalPages > 0;

  // Check if we are able to trigger loading the next page
  // Requires being initialized, not currently loading (initial or more), and having more pages
  bool get canLoadMore => !isLoadingInitial && !isLoadingMore && hasMorePages;

  // Start loading state (specify if it's the initial load or loading more)
  void startLoading({bool isInitial = false}) {
     if (isInitial) {
        if (kDebugMode) print("ProductStorageSingleton/CacheData: Started initial loading state.");
        isLoadingInitial = true;
        isLoadingMore = false; // Cannot be loading more if doing initial
     } else {
         if (kDebugMode) print("ProductStorageSingleton/CacheData: Started loading more state.");
        isLoadingInitial = false; // Cannot be loading initial if loading more
        isLoadingMore = true;
     }
  }

  // Stop any loading state
  void stopLoading() {
     if (kDebugMode) print("ProductStorageSingleton/CacheData: Stopped loading state.");
     isLoadingInitial = false;
     isLoadingMore = false;
  }

   // Clear this specific cache data completely
   void clear() {
       products.clear();
       currentPage = -1;
       totalPages = 0;
       isLoadingInitial = false;
       isLoadingMore = false;
       isInitialized = false;
       categoryId = null; // Clear config
       sortBy = null;
       sortDir = null;
       searchTerm = null;
       if (kDebugMode) print("ProductStorageSingleton/CacheData: Data cleared.");
   }
}


// Singleton chính để quản lý cache, fetching, và trạng thái loading cho CÁC CẤU HÌNH khác nhau
class ProductStorageSingleton extends ChangeNotifier {
  static final ProductStorageSingleton _instance = ProductStorageSingleton._internal();

  factory ProductStorageSingleton() {
    return _instance;
  }

  ProductStorageSingleton._internal();

  // Map để lưu trữ cache cho từng CẤU HÌNH tải
  // Key: String representing the unique config (categoryId_sortBy_sortDir_searchTerm...)
  // Value: CachedProductData for that config
  final Map<String, CachedProductData> _cache = {};

  final ProductService _productService = ProductService(); // Instance of ProductService

  // Helper to generate a unique cache key for a given configuration
  String _getCacheKey({
    required int categoryId,
    required String sortBy,
    required String sortDir,
    String? searchTerm,
    // Add other filter parameters here
  }) {
    // Create a unique string key from all relevant filter/sort parameters
    // Make sure the order is consistent
    return "${categoryId}_${sortBy}_${sortDir}_${searchTerm ?? ''}";
    // Add other filters to the key if they affect the result
    // e.g., "_min${minPrice}_max${maxPrice}_minRating${minRating}";
  }

  // Get or create CachedProductData for a specific configuration
  CachedProductData _getCacheForConfig({
    required int categoryId,
    required String sortBy,
    required String sortDir,
    String? searchTerm,
    // Add other filter parameters here
  }) {
     final key = _getCacheKey(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir, searchTerm: searchTerm);
     return _cache.putIfAbsent(key, () {
        if (kDebugMode) print("ProductStorageSingleton: Creating new cache entry for config key: $key");
        return CachedProductData(
           categoryId: categoryId,
           sortBy: sortBy,
           sortDir: sortDir,
           searchTerm: searchTerm,
           // Pass other filters here
        );
     });
  }

  // --- Public API for Widgets to interact with ---

  // Get products for a specific configuration
  List<ProductDTO> getProductsForConfig({
    required int categoryId,
    required String sortBy,
    required String sortDir,
    String? searchTerm,
    // Add other filter parameters here
  }) {
    final key = _getCacheKey(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir, searchTerm: searchTerm);
    // Return the product list from the cache for this config, or an empty list if not found
    return _cache[key]?.products ?? [];
  }

  // Check if a configuration is currently loading its initial page (page 0)
  bool isInitialLoading({
    required int categoryId,
    required String sortBy,
    required String sortDir,
    String? searchTerm,
    // Add other filter parameters here
  }) {
     final key = _getCacheKey(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir, searchTerm: searchTerm);
     // Return the isLoadingInitial flag from the cache for this config, default to false if not found
     return _cache[key]?.isLoadingInitial ?? false;
  }

  // Check if a configuration is currently loading more pages (page > 0)
  bool isLoadingMore({
    required int categoryId,
    required String sortBy,
    required String sortDir,
    String? searchTerm,
    // Add other filter parameters here
  }) {
     final key = _getCacheKey(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir, searchTerm: searchTerm);
      // Return the isLoadingMore flag from the cache for this config, default to false if not found
     return _cache[key]?.isLoadingMore ?? false;
  }

   // Check if a configuration has been initialized (at least one page loaded successfully)
  bool isConfigInitialized({
     required int categoryId,
     required String sortBy,
     required String sortDir,
     String? searchTerm,
     // Add other filter parameters here
  }) {
     final key = _getCacheKey(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir, searchTerm: searchTerm);
     // Return the isInitialized flag from the cache for this config, default to false if not found
     return _cache[key]?.isInitialized ?? false;
  }


  // Check if there are more pages to load for a configuration
  bool canLoadMore({
    required int categoryId,
    required String sortBy,
    required String sortDir,
    String? searchTerm,
    // Add other filter parameters here
  }) {
     final key = _getCacheKey(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir, searchTerm: searchTerm);
     // Return the canLoadMore getter result from the cache for this config, default to false if not found
     return _cache[key]?.canLoadMore ?? false;
  }

  // Trigger the initial load for a configuration (category/sort/search)
  // This should be called when category/sort/search changes, or initially
  Future<void> loadInitialProducts({
    required int categoryId,
    String sortBy = 'createdDate', // Default sort property for API
    String sortDir = 'desc', // Default sort direction for API
    String? searchTerm,
    // Add other filter parameters here
  }) async {
    final key = _getCacheKey(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir, searchTerm: searchTerm);
    final cache = _getCacheForConfig(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir, searchTerm: searchTerm); // Ensure cache exists for this config

    // IMPORTANT: Check if the cache already has data for this EXACT config and is initialized.
    // If so, we just need to notify listeners so the UI knows the selected config changed,
    // but no API call or loading spinner is needed (as per requirement).
    if (cache.matchesConfig(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir, searchTerm: searchTerm) && cache.isInitialized && !cache.isLoadingInitial && !cache.isLoadingMore) {
        if (kDebugMode) print("ProductStorageSingleton: Cache already initialized for config key: $key. Not reloading.");
        // Notify listeners so UI can rebuild with the cached data immediately
        notifyListeners();
        return;
    }

    // If the cache does NOT match the config (means user changed category/sort/search)
    // or if it's not yet initialized, we must reset it and start loading page 0.
     if (!cache.matchesConfig(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir, searchTerm: searchTerm)) {
         cache.resetConfig(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir, searchTerm: searchTerm);
         // Update the cache key in the map if the config changed and it was putIfAbsent previously with a partial config.
         // This scenario is avoided by always using the full key in _getCacheForConfig.
         // So just ensure the cache object itself is reset for the new config.
     }


    // Prevent duplicate initial loads for the same config
    if (cache.isLoadingInitial) {
        if (kDebugMode) print("ProductStorageSingleton: Initial load already in progress for config key: $key. Skipping.");
        return;
    }

    cache.startLoading(isInitial: true); // Set initial loading state
    notifyListeners(); // Notify to show the initial loading indicator (e.g., full screen)

    try {
      if (kDebugMode) print("ProductStorageSingleton: Fetching initial products (page 0) for config key: $key");
      final pageResponse = await _productService.fetchProducts(
        categoryId: categoryId,
        sortBy: sortBy,
        sortDir: sortDir,
        search: searchTerm,
        page: 0, // Always load page 0 for initial load/config change
         // Pass other filters here
      );

      cache.addPage(pageResponse); // This updates cache.products, currentPage, totalPages, isInitialized, and stops loading flags

    } catch (e) {
      if (kDebugMode) print('ProductStorageSingleton: Error loading initial products for config key $key: $e');
      cache.stopLoading(); // Stop loading on error
      // TODO: Handle API error gracefully (e.g., store error message in cache, show to user)
    } finally {
      // Ensure loading flags are false and notify listeners regardless of success or failure
       if (cache.isLoadingInitial || cache.isLoadingMore) {
           cache.stopLoading(); // Redundant if addPage or catch block worked, but safe
       }
      notifyListeners(); // Notify listeners after data update or error
      if (kDebugMode) print("ProductStorageSingleton: Initial load process finished for config key: $key.");
    }
  }

  // Trigger loading the next page for a configuration
  // This should be called when the user scrolls near the end of the list
  Future<void> loadNextPage({
    required int categoryId,
    String sortBy = 'createdDate', // Default sort property for API
    String sortDir = 'desc', // Default sort direction for API
    String? searchTerm,
    // Add other filter parameters here
  }) async {
    final key = _getCacheKey(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir, searchTerm: searchTerm);
    // Get the cache for the CURRENT configuration. It must exist and be initialized.
    final cache = _getCacheForConfig(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir, searchTerm: searchTerm);

    // Check if we are allowed to load more based on cache state
    if (!cache.canLoadMore) {
      if (kDebugMode) print("ProductStorageSingleton: Cannot load more for config key: $key. State: isInitialized=${cache.isInitialized}, currentPage=${cache.currentPage}, totalPages=${cache.totalPages}, isLoadingInitial=${cache.isLoadingInitial}, isLoadingMore=${cache.isLoadingMore}");
      return;
    }

    cache.startLoading(isInitial: false); // Set loading more state
    notifyListeners(); // Notify to show the "loading more" indicator (e.g., at bottom)

    try {
      final nextPage = cache.currentPage + 1; // Calculate the next page number
      if (kDebugMode) print("ProductStorageSingleton: Fetching next page ($nextPage) for config key: $key");
      final pageResponse = await _productService.fetchProducts(
        categoryId: categoryId,
        sortBy: sortBy,
        sortDir: sortDir,
        search: searchTerm,
        page: nextPage, // Request the next page
        // Pass other filters here
      );

      cache.addPage(pageResponse); // This adds products, updates currentPage/totalPages, and stops loading more

    } catch (e) {
      if (kDebugMode) print('ProductStorageSingleton: Error loading next page for config key $key: $e');
      cache.stopLoading(); // Stop loading on error
       // TODO: Handle API error during pagination (e.g., show message, retry button)
    } finally {
      // Ensure loading flags are false and notify listeners regardless of success or failure
      if (cache.isLoadingInitial || cache.isLoadingMore) {
           cache.stopLoading(); // Redundant if addPage or catch block worked, but safe
       }
      notifyListeners(); // Notify listeners after data update or error
      if (kDebugMode) print("ProductStorageSingleton: Load next page process finished for config key: $key.");
    }
  }


  // Clear cache for a specific configuration (e.g., when filters are completely removed or reset)
  void clearCacheForConfig({
    required int categoryId,
    String sortBy = 'createdDate',
    String sortDir = 'desc',
    String? searchTerm,
    // Add other filter parameters here
  }) {
     final key = _getCacheKey(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir, searchTerm: searchTerm);
     if (_cache.containsKey(key)) {
        _cache[key]!.clear(); // Clear the data within the CachedProductData object
        // Keep the empty CachedProductData instance in the map,
        // so loadInitialProducts works consistently (_getCacheForConfig will find it).
        if (kDebugMode) print("ProductStorageSingleton: Cache cleared for config key: $key");
        // notifyListeners(); // Notify if the UI needs to react immediately to a cache clear (unlikely for typical pagination)
     } else {
         if (kDebugMode) print("ProductStorageSingleton: No cache found for config key: $key to clear.");
     }
  }

  // Clear all product cache entries
  void clearAllProductCache() {
    _cache.clear(); // Removes all CachedProductData instances from the map
     notifyListeners(); // Notify if the UI depends on overall cache state (unlikely for this feature)
     if (kDebugMode) print("ProductStorageSingleton: Cleared all product cache entries.");
  }

  // Dispose method to clean up resources (like the http client in ProductService)
  @override
  void dispose() {
    // Dispose resources used by the singleton
    _productService.dispose(); // Dispose the http client
    _cache.clear(); // Clear cache on dispose
    super.dispose();
    if (kDebugMode) print("ProductStorageSingleton disposed.");
  }
}
