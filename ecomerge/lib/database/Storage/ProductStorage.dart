import 'package:flutter/foundation.dart';
import 'package:e_commerce_app/database/models/product_dto.dart';
import 'package:e_commerce_app/database/PageResponse.dart';
import 'package:e_commerce_app/database/services/product_service.dart';

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
}

class ProductStorageSingleton extends ChangeNotifier {
  static final ProductStorageSingleton _instance = ProductStorageSingleton._internal();

  factory ProductStorageSingleton() {
    return _instance;
  }

  ProductStorageSingleton._internal();

  final CachedConfigData _cache = CachedConfigData();
  final ProductService _productService = ProductService();

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
    return _cache.products;
  }

  bool isConfigInitialized({
    required int categoryId,
    required String sortBy,
    required String sortDir,
  }) {
    return _isSameConfig(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir) && _cache.isInitialized;
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
    return _isSameConfig(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir) && _cache.canLoadMore;
  }

  Future<void> loadInitialProducts({
    required int categoryId,
    required String sortBy,
    required String sortDir,
  }) async {
    final cacheKey = _getCacheKey(categoryId: categoryId, sortBy: sortBy, sortDir: sortDir);

    // If we're already loading initial data for this config, don't start another load
    if (_cache.isLoadingInitial && _cache.isValid(cacheKey)) {
      return;
    }

    // If config changed, clear cache
    if (!_cache.isValid(cacheKey)) {
      _cache.clear();
      _cache.currentCacheKey = cacheKey;
    }

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
      _cache.isLoadingInitial = false;

    } catch (e) {
      print('Error loading initial products: $e');
      _cache.isLoadingInitial = false;
    }

    notifyListeners();
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
    // Immediately notify listeners when loading state changes
    notifyListeners();

    try {
      // Add artificial delay to ensure loading indicator is visible
      await Future.delayed(Duration(milliseconds: 1000));
      
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
      }
    } catch (e) {
      print('Error loading more products: $e');
    } finally {
      // Ensure we reset loading state and notify listeners
      _cache.isLoadingMore = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _productService.dispose();
    super.dispose();
  }
}
