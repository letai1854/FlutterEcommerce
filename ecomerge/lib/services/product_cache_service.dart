import 'package:flutter/material.dart';
import 'package:e_commerce_app/widgets/Product/PromotionalProductsList.dart'; // Assuming ProductItem/PromoProductItem is defined or accessible here
// If PromoProductItem is the actual widget, import its definition.
// For this example, we'll assume PromotionalProductsList.dart exports/defines the item type or we use a generic type.
// Let's use PromoProductItem directly as it's the type used in PromotionalProductsList.
// import 'package:e_commerce_app/widgets/Product/ProductItem.dart'; // This was a type alias

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

class ProductCacheService {
  static final ProductCacheService _instance = ProductCacheService._internal();
  factory ProductCacheService() => _instance;
  ProductCacheService._internal();

  final Map<String, CachedProductListData> _cache = {};

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

  void clearCache(String key) {
    _cache.remove(key);
    print('Cache cleared for key: $key');
  }

  void clearAllCache() {
    _cache.clear();
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
