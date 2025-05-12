import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // Import for kIsWeb
import 'package:e_commerce_app/database/models/categories.dart';
import 'package:e_commerce_app/services/product_cache_service.dart'; // For CachedCategoryProductData
import 'package:e_commerce_app/database/models/product_dto.dart'; // For ProductDTO
import 'package:e_commerce_app/database/models/user_model.dart'; // Ensure User model is imported if needed for context

class SharedPreferencesService {
  static SharedPreferencesService? _instance;
  static SharedPreferences? _preferences;

  // --- Keys for SharedPreferences ---
  // Prefix for product list data to avoid collision and allow dynamic list keys
  static const String _productListDataPrefix = 'product_list_data_';
  // Key for the global image cache map (stores imageURL -> base64ImageData)
  static const String _imageCacheKey = 'image_cache_map';

  // Specific keys for different product lists as requested
  static const String newProductsKey = 'new_products';
  static const String bestSellerProductsKey = 'best_seller_products';
  static const String promotionalProductsKey =
      'promotional_products'; // For discounted products

  // Key for the displayed category list (e.g., first 5)
  static const String _displayedCategoryListKey = 'displayed_category_list';
  // Prefix for category-specific product lists
  static const String _categoryProductListDataPrefix =
      'category_product_list_data_';

  // Key for the main list of categories (used by AppDataService)
  static const String _allCategoriesListKey = 'all_categories_list';

  // Key for categories with images (for ResponsiveHome offline display)
  static const String _cachedCategoriesWithImagesKey =
      'cached_categories_with_images';

  // Key for displayed categories (DTOs only) for ResponsiveHome fallback
  static const String _displayedCategoriesKey = 'displayed_categories_key';

  // New key for storing the complete current user object
  static const String _persistedCompleteUserKey =
      'persisted_complete_user_data';

  SharedPreferencesService._(); // Private constructor

  static Future<SharedPreferencesService> getInstance() async {
    if (_instance == null) {
      _preferences = await SharedPreferences.getInstance();
      _instance = SharedPreferencesService._();
    }
    return _instance!;
  }

  String _getActualProductListKey(String dynamicListKey) {
    return '$_productListDataPrefix$dynamicListKey';
  }

  String _getActualCategoryProductListKey(String categoryCacheKey) {
    return '$_categoryProductListDataPrefix$categoryCacheKey';
  }

  // --- Product List Caching (for PromotionalProductsList) ---

  Future<void> saveProductListData(
      String dynamicListKey,
      List<Map<String, dynamic>> productDataList,
      int nextPageToRequest,
      bool hasMorePages) async {
    if (_preferences == null || kIsWeb) return; // Only for non-web

    final dataToSave = {
      'products': productDataList,
      'nextPageToRequest': nextPageToRequest,
      'hasMorePages': hasMorePages,
    };
    try {
      final jsonString = jsonEncode(dataToSave);
      await _preferences!
          .setString(_getActualProductListKey(dynamicListKey), jsonString);
      if (kDebugMode) {
        print(
            'Saved product list data to SharedPreferences for key: $dynamicListKey');
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            'Error saving product list data to SharedPreferences for key $dynamicListKey: $e');
      }
    }
  }

  Map<String, dynamic>? getProductListData(String dynamicListKey) {
    if (_preferences == null || kIsWeb) return null; // Only for non-web

    final jsonString =
        _preferences!.getString(_getActualProductListKey(dynamicListKey));
    if (jsonString != null) {
      try {
        final decodedData = jsonDecode(jsonString);
        if (decodedData is Map<String, dynamic> &&
            decodedData.containsKey('products') &&
            decodedData.containsKey('nextPageToRequest') &&
            decodedData.containsKey('hasMorePages')) {
          return decodedData;
        }
      } catch (e) {
        if (kDebugMode) {
          print(
              'Error decoding product list data from SharedPreferences for key $dynamicListKey: $e');
        }
      }
    }
    return null;
  }

  Future<bool> removeProductListData(String dynamicListKey) async {
    if (_preferences == null || kIsWeb) return false; // Only for non-web
    if (kDebugMode) {
      print(
          'Removing product list data from SharedPreferences for key: $dynamicListKey');
    }
    return _preferences!.remove(_getActualProductListKey(dynamicListKey));
  }

  // --- Category List Caching ---
  Future<void> saveCategories(List<CategoryDTO> categories) async {
    if (kIsWeb || _preferences == null) return;
    try {
      final String encodedData =
          jsonEncode(categories.map((c) => c.toJson()).toList());
      await _preferences!.setString(_allCategoriesListKey, encodedData);
      if (kDebugMode) {
        print('Saved ${categories.length} categories to SharedPreferences.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving categories to SharedPreferences: $e');
      }
    }
  }

  Future<List<CategoryDTO>?> loadCategories() async {
    if (kIsWeb || _preferences == null) return null;
    try {
      final String? encodedData =
          _preferences!.getString(_allCategoriesListKey);
      if (encodedData != null) {
        final List<dynamic> decodedData = jsonDecode(encodedData);
        final categories =
            decodedData.map((json) => CategoryDTO.fromJson(json)).toList();
        if (kDebugMode) {
          print(
              'Loaded ${categories.length} categories from SharedPreferences.');
        }
        return categories;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading categories from SharedPreferences: $e');
      }
    }
    return null;
  }

  // --- Displayed Category List Caching (for ResponsiveHome fallback) ---
  Future<void> saveDisplayedCategories(List<CategoryDTO> categories) async {
    if (kIsWeb || _preferences == null) return;
    try {
      final String encodedData =
          jsonEncode(categories.map((c) => c.toJson()).toList());
      await _preferences!.setString(_displayedCategoriesKey, encodedData);
      if (kDebugMode) {
        print(
            'Saved ${categories.length} displayed categories to SharedPreferences.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving displayed categories to SharedPreferences: $e');
      }
    }
  }

  Future<List<CategoryDTO>?> loadDisplayedCategories() async {
    if (kIsWeb || _preferences == null) return null;
    try {
      final String? encodedData =
          _preferences!.getString(_displayedCategoriesKey);
      if (encodedData != null) {
        final List<dynamic> decodedData = jsonDecode(encodedData);
        final categories =
            decodedData.map((json) => CategoryDTO.fromJson(json)).toList();
        if (kDebugMode) {
          print(
              'Loaded ${categories.length} displayed categories from SharedPreferences.');
        }
        return categories;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading displayed categories from SharedPreferences: $e');
      }
    }
    return null;
  }

  // --- Category List with Images Caching (for ResponsiveHome) ---
  Future<void> saveCategoriesWithImages(
      List<Map<String, dynamic>> categoriesData) async {
    if (kIsWeb || _preferences == null) return;
    try {
      final String encodedData = jsonEncode(categoriesData);
      await _preferences!
          .setString(_cachedCategoriesWithImagesKey, encodedData);
      if (kDebugMode) {
        print(
            'Saved ${categoriesData.length} categories with images to SharedPreferences.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving categories with images to SharedPreferences: $e');
      }
    }
  }

  Future<List<Map<String, dynamic>>?> loadCategoriesWithImages() async {
    if (kIsWeb || _preferences == null) return null;
    try {
      final String? encodedData =
          _preferences!.getString(_cachedCategoriesWithImagesKey);
      if (encodedData != null) {
        final List<dynamic> decodedData = jsonDecode(encodedData);
        // Ensure all items are Map<String, dynamic>
        final categories =
            decodedData.map((item) => item as Map<String, dynamic>).toList();
        if (kDebugMode) {
          print(
              'Loaded ${categories.length} categories with images from SharedPreferences.');
        }
        return categories;
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            'Error loading categories with images from SharedPreferences: $e');
      }
    }
    return null;
  }

  // --- Category-Specific Product Caching ---
  Future<void> saveCategoryProductData(
      String cacheKey, CachedCategoryProductData data) async {
    if (kIsWeb || _preferences == null) return;
    try {
      final List<Map<String, dynamic>> productsJson =
          data.products.map((p) => p.toJson()).toList();
      final Map<String, dynamic> dataToSave = {
        'products': productsJson,
        'currentPage': data.currentPage,
        'hasMore': data.hasMore,
        'lastFetched': data.lastFetched.toIso8601String(),
      };
      final String encodedData = jsonEncode(dataToSave);
      await _preferences!.setString(cacheKey, encodedData);
      if (kDebugMode) {
        print(
            'Saved category product data to SharedPreferences for key: $cacheKey');
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            'Error saving category product data to SharedPreferences for key $cacheKey: $e');
      }
    }
  }

  Future<CachedCategoryProductData?> loadCategoryProductData(
      String cacheKey) async {
    if (kIsWeb || _preferences == null) return null;
    try {
      final String? encodedData = _preferences!.getString(cacheKey);
      if (encodedData != null) {
        final Map<String, dynamic> decodedData = jsonDecode(encodedData);
        final List<dynamic> productsJson = decodedData['products'];
        final List<ProductDTO> products =
            productsJson.map((json) => ProductDTO.fromJson(json)).toList();

        final data = CachedCategoryProductData(
          products: products,
          currentPage: decodedData['currentPage'],
          hasMore: decodedData['hasMore'],
          lastFetched: DateTime.parse(decodedData['lastFetched']),
        );
        if (kDebugMode) {
          print(
              'Loaded category product data from SharedPreferences for key: $cacheKey');
        }
        return data;
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            'Error loading category product data from SharedPreferences for key $cacheKey: $e');
      }
    }
    return null;
  }

  Future<bool> removeCategoryProductData(String cacheKey) async {
    if (kIsWeb || _preferences == null) return false;
    try {
      final success = await _preferences!.remove(cacheKey);
      if (success) {
        if (kDebugMode) {
          print(
              'Removed category product data from SharedPreferences for key: $cacheKey');
        }
      } else {
        if (kDebugMode) {
          print(
              'Key not found or failed to remove category product data from SharedPreferences for key: $cacheKey');
        }
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        print(
            'Error removing category product data from SharedPreferences for key $cacheKey: $e');
      }
      return false;
    }
  }

  // --- Image Caching (Common for all images) ---
  Future<void> saveImageData(String imageUrl, Uint8List imageData) async {
    if (_preferences == null || imageUrl.isEmpty || kIsWeb) {
      return; // Only for non-web
    }

    try {
      final imageMapString = _preferences!.getString(_imageCacheKey);
      Map<String, String> imageMap = {};
      if (imageMapString != null) {
        try {
          imageMap = Map<String, String>.from(jsonDecode(imageMapString));
        } catch (e) {
          if (kDebugMode) {
            print('Error decoding existing image map, creating new one: $e');
          }
        }
      }
      imageMap[imageUrl] = base64Encode(imageData);
      await _preferences!.setString(_imageCacheKey, jsonEncode(imageMap));
    } catch (e) {
      if (kDebugMode) {
        print(
            'Error saving image data to SharedPreferences for URL $imageUrl: $e');
      }
    }
  }

  Uint8List? getImageData(String imageUrl) {
    if (_preferences == null || imageUrl.isEmpty || kIsWeb) {
      return null; // Only for non-web
    }

    final imageMapString = _preferences!.getString(_imageCacheKey);
    if (imageMapString != null) {
      try {
        final imageMap = Map<String, String>.from(jsonDecode(imageMapString));
        if (imageMap.containsKey(imageUrl)) {
          final base64String = imageMap[imageUrl]!;
          return base64Decode(base64String);
        }
      } catch (e) {
        if (kDebugMode) {
          print(
              'Error decoding image data from SharedPreferences for URL $imageUrl: $e');
        }
      }
    }
    return null;
  }

  Future<bool> removeImageData(String imageUrl) async {
    if (_preferences == null || imageUrl.isEmpty || kIsWeb) {
      return false; // Only for non-web
    }
    final imageMapString = _preferences!.getString(_imageCacheKey);
    if (imageMapString != null) {
      try {
        Map<String, String> imageMap =
            Map<String, String>.from(jsonDecode(imageMapString));
        if (imageMap.containsKey(imageUrl)) {
          imageMap.remove(imageUrl);
          await _preferences!.setString(_imageCacheKey, jsonEncode(imageMap));
          if (kDebugMode) {
            print(
                'Removed image data from SharedPreferences for URL: $imageUrl');
          }
          return true;
        }
      } catch (e) {
        if (kDebugMode) {
          print(
              'Error removing image data from SharedPreferences for URL $imageUrl: $e');
        }
      }
    }
    return false;
  }

  Future<bool> clearAllImageData() async {
    if (_preferences == null || kIsWeb) return false; // Only for non-web
    if (kDebugMode) {
      print('Clearing all image data from SharedPreferences.');
    }
    return _preferences!.remove(_imageCacheKey);
  }

  // --- Persisted Complete User Data Caching ---
  Future<void> savePersistedCompleteUserData(String userJson) async {
    if (_preferences == null || kIsWeb) return; // Only for non-web
    try {
      await _preferences!.setString(_persistedCompleteUserKey, userJson);
      if (kDebugMode) {
        print('Saved complete user data to SharedPreferences.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving complete user data to SharedPreferences: $e');
      }
    }
  }

  Future<String?> loadPersistedCompleteUserData() async {
    if (_preferences == null || kIsWeb) return null; // Only for non-web
    try {
      final String? userJson =
          _preferences!.getString(_persistedCompleteUserKey);
      if (userJson != null) {
        if (kDebugMode) {
          print('Loaded complete user data from SharedPreferences.');
        }
        return userJson;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading complete user data from SharedPreferences: $e');
      }
    }
    return null;
  }

  Future<bool> removePersistedCompleteUserData() async {
    if (_preferences == null || kIsWeb) return false; // Only for non-web
    if (kDebugMode) {
      print('Removing complete user data from SharedPreferences.');
    }
    return _preferences!.remove(_persistedCompleteUserKey);
  }
  // --- End of Persisted Complete User Data Caching ---

  Future<bool> clearAllUserPreferences() async {
    if (_preferences == null) return false;
    if (kDebugMode) {
      print('Clearing all SharedPreferences data.');
    }
    final keys = _preferences!.getKeys();
    for (String key in keys) {
      if (key.startsWith(_productListDataPrefix) ||
          key.startsWith(_categoryProductListDataPrefix) ||
          key == _displayedCategoryListKey ||
          key == _allCategoriesListKey ||
          key == _cachedCategoriesWithImagesKey ||
          key == _displayedCategoriesKey || // Added new key
          key == _persistedCompleteUserKey || // Added new key for complete user
          key == _imageCacheKey) {
        await _preferences!.remove(key);
      }
    }
    return true;
  }

  bool containsKey(String key) {
    if (key == newProductsKey ||
        key == bestSellerProductsKey ||
        key == promotionalProductsKey) {
      return _preferences?.containsKey(_getActualProductListKey(key)) ?? false;
    }
    if (key == _imageCacheKey ||
        key == _allCategoriesListKey ||
        key == _displayedCategoriesKey || // Added new key
        key == _persistedCompleteUserKey || // Added new key for complete user
        key == _cachedCategoriesWithImagesKey) {
      return _preferences?.containsKey(key) ?? false;
    }
    return _preferences?.containsKey(key) ?? false;
  }
}
