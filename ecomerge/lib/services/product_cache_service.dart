import 'package:flutter/material.dart';
import 'package:e_commerce_app/widgets/Product/PromotionalProductsList.dart'; // Assuming ProductItem/PromoProductItem is defined or accessible here
import 'package:e_commerce_app/database/models/product_dto.dart'; // Added for ProductDTO

// Define a class to hold cached data
class CachedProductListData {
  List<PromoProductItem> products;
  int nextPageToRequest;
  bool hasMorePages;
  DateTime lastFetched;

  CachedProductListData({
    required this.products,
    required this.nextPageToRequest,
    required this.hasMorePages,
    required this.lastFetched,
  });
}

// Define a class to hold cached category-specific product data
class CachedCategoryProductData {
  List<ProductDTO> products;
  int currentPage; // Corresponds to 'number' from PageResponse
  bool hasMore; // Corresponds to '!last' from PageResponse
  DateTime lastFetched;

  CachedCategoryProductData({
    required this.products,
    required this.currentPage,
    required this.hasMore,
    required this.lastFetched,
  });
}

class ProductCacheService {
  static final ProductCacheService _instance = ProductCacheService._internal();
  factory ProductCacheService() => _instance;
  ProductCacheService._internal();

  final Map<String, CachedProductListData> _cache = {};
  final Map<String, CachedCategoryProductData> _categoryProductCache =
      {}; // New cache for category products

  CachedProductListData? getData(String key) {
    // Optional: Implement cache expiry logic if needed
    // e.g., if (_cache[key]!.lastFetched.isBefore(DateTime.now().subtract(Duration(minutes: 5)))) {
    //   _cache.remove(key);
    //   return null;
    // }
    return _cache[key];
  }

  void storeData(String key, List<PromoProductItem> products,
      int nextPageToRequest, bool hasMorePages) {
    _cache[key] = CachedProductListData(
      products: List.from(products), // Store a copy
      nextPageToRequest: nextPageToRequest,
      hasMorePages: hasMorePages,
      lastFetched: DateTime.now(),
    );
    print(
        'Cache stored for key: $key. Items: ${products.length}, NextPage: $nextPageToRequest, HasMore: $hasMorePages');
  }

  void appendData(String key, List<PromoProductItem> additionalProducts,
      int nextPageToRequest, bool hasMorePages) {
    if (_cache.containsKey(key)) {
      _cache[key]!.products.addAll(additionalProducts);
      _cache[key]!.nextPageToRequest = nextPageToRequest;
      _cache[key]!.hasMorePages = hasMorePages;
      _cache[key]!.lastFetched = DateTime.now();
      print(
          'Cache appended for key: $key. Total Items: ${_cache[key]!.products.length}, NextPage: $nextPageToRequest, HasMore: $hasMorePages');
    } else {
      storeData(key, additionalProducts, nextPageToRequest, hasMorePages);
    }
  }

  // --- Methods for Category Product Cache ---

  String getCategoryCacheKey(int? categoryId) {
    return "category_products_${categoryId ?? 'all'}";
  }

  CachedCategoryProductData? getCategoryProducts(String key) {
    // Optional: Implement cache expiry logic if needed
    // e.g., if (_categoryProductCache[key]!.lastFetched.isBefore(DateTime.now().subtract(Duration(minutes: 5)))) {
    //   _categoryProductCache.remove(key);
    //   return null;
    // }
    return _categoryProductCache[key];
  }

  void storeCategoryProducts(
      String key, List<ProductDTO> products, int currentPage, bool hasMore) {
    _categoryProductCache[key] = CachedCategoryProductData(
      products: List.from(products), // Store a copy
      currentPage: currentPage,
      hasMore: hasMore,
      lastFetched: DateTime.now(),
    );
    print(
        'Category Product Cache stored for key: $key. Items: ${products.length}, CurrentPage: $currentPage, HasMore: $hasMore');
  }

  void appendCategoryProducts(String key, List<ProductDTO> additionalProducts,
      int currentPage, bool hasMore) {
    if (_categoryProductCache.containsKey(key)) {
      _categoryProductCache[key]!.products.addAll(additionalProducts);
      _categoryProductCache[key]!.currentPage = currentPage;
      _categoryProductCache[key]!.hasMore = hasMore;
      _categoryProductCache[key]!.lastFetched = DateTime.now();
      print(
          'Category Product Cache appended for key: $key. Total Items: ${_categoryProductCache[key]!.products.length}, CurrentPage: $currentPage, HasMore: $hasMore');
    } else {
      storeCategoryProducts(key, additionalProducts, currentPage, hasMore);
    }
  }

  void clearCategoryProductCacheEntry(String key) {
    _categoryProductCache.remove(key);
    print('Category Product Cache cleared for key: $key');
  }

  void clearCache(String key) {
    _cache.remove(key);
    print('Cache cleared for key: $key');
  }

  void clearAllCache() {
    _cache.clear();
    _categoryProductCache.clear(); // Clear the new cache as well
    print('All product caches cleared.');
  }

  String getKeyFromProductListKey(Key? productListKey) {
    if (productListKey == null) return "default_promo_products";

    final String keyString = productListKey.toString();
    // Examples: "[GlobalKey#xxxxx newProducts]", "[GlobalKey#yyyyy promoProducts]", "[GlobalKey#zzzzz bestSeller]"
    if (keyString.contains('newProducts')) return 'newProducts';
    if (keyString.contains('bestSeller')) return 'bestSeller';
    if (keyString.contains('promoProducts')) return 'promoProducts';

    // Fallback for other keys, sanitize it
    final saneKey = keyString.replaceAll(RegExp(r'[^\w-]'), '');
    print(
        "Warning: Could not derive specific cache key from productListKey '$keyString', using sanitized key: '$saneKey'");
    return saneKey.isNotEmpty ? saneKey : "unknown_promo_products";
  }
}
