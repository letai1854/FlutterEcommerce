// lib/database/Storage/BrandCategoryService.dart
import 'dart:async';

import 'package:e_commerce_app/database/models/brand.dart';
import 'package:e_commerce_app/database/models/categories.dart'; // Assuming CategoryDTO is here
import 'package:e_commerce_app/database/services/categories_service.dart'; // Import CategoriesService
import 'package:e_commerce_app/database/services/product_service.dart'; // Import ProductService (if brands/products handled here)
// Import PageResponse if fetchCategoriesPaginated returns it
import 'package:e_commerce_app/database/PageResponse.dart'; // Assuming PageResponse exists

import 'package:flutter/foundation.dart'; // For kDebugMode, ChangeNotifier
// Add imports for connectivity and storage
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:crypto/crypto.dart'; // For sha256

// --- Singleton Setup ---
// AppDataService extends ChangeNotifier to notify listeners when data changes
class AppDataService extends ChangeNotifier {
  static final AppDataService _instance = AppDataService._internal();

  factory AppDataService() {
    return _instance;
  }

  AppDataService._internal() {
    // Initialize connectivity monitoring when the service is created
    _initConnectivityMonitoring();
  }

  // --- Data Storage ---
  // *** CHANGE: These lists are now the source of truth for the UI after loading/updates ***
  List<CategoryDTO> _categories = [];
  List<BrandDTO> _brands =
      []; // Assuming brands are also managed by this service
  bool _isInitialized = false; // Flag indicates if initial load is complete
  bool _isLoading =
      false; // Flag indicates if a load operation is currently in progress
  bool _isOnline = true; // Track current connectivity status

  // --- Dependencies (Service instances) ---
  // Need instances of necessary services to fetch/update data
  final CategoriesService _categoriesService =
      CategoriesService(); // Use CategoriesService for category APIs
  final ProductService _productService =
      ProductService(); // Use ProductService for other APIs like brands/products
  final Connectivity _connectivity =
      Connectivity(); // For connectivity monitoring

  // Image cache for category images
  final Map<String, Uint8List> _imageCache = {};

  // --- Getters ---
  List<CategoryDTO> get categories => _categories;
  List<BrandDTO> get brands => _brands; // Getter for brands list
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading; // Getter for loading state
  bool get isOnline => _isOnline; // Getter for online status

  // --- Connectivity Monitoring ---
  void _initConnectivityMonitoring() {
    if (kIsWeb) return; // Skip connectivity monitoring on web

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

      // If we just went from offline to online and data is already initialized,
      // refresh data from server in the background
      if (_isInitialized && wasOffline && _isOnline) {
        _refreshDataFromServer();
      }
    });
  }

  // Check current connectivity status
Future<void> _checkConnectivity() async {
  final ConnectivityResult connectivityResult = await Connectivity().checkConnectivity();
  print("ConnectivityResult: $connectivityResult");

  if (connectivityResult == ConnectivityResult.none) {
    print("Không có kết nối mạng cục bộ (Wi-Fi/Mobile Data).");
    _isOnline = false;
    return;
  }

  final InternetConnectionChecker customChecker = InternetConnectionChecker.createInstance(
    checkTimeout: const Duration(milliseconds: 1000),
  );

  print("Đang kiểm tra kết nối internet thực sự (timeout mỗi địa chỉ ~1 giây)...");
  bool hasInternetAccess = false;
  try {
    hasInternetAccess = await customChecker.hasConnection;
  } catch (e) {
    print("Lỗi khi kiểm tra InternetConnectionChecker: $e");
  hasInternetAccess = false;
  }

  if (hasInternetAccess) {
    print("Đã kết nối internet (InternetConnectionChecker).");
  } else {
    print("Mất kết nối internet (InternetConnectionChecker) hoặc kiểm tra timeout.");
  }

  _isOnline = hasInternetAccess;
}

  // Refresh data from server when going back online
  Future<void> _refreshDataFromServer() async {
    if (kDebugMode) {
      print('Network restored - refreshing data from server');
    }

    try {
      // Fetch categories
      await _fetchCategoriesFromServer();

      // Fetch brands
      await _fetchBrandsFromServer();

      // Save to local storage
      await _saveDataToLocalStorage();

      // Notify listeners
      notifyListeners();

      if (kDebugMode) {
        print('Data refreshed from server after network restoration');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing data from server: $e');
      }
    }
  }

  // --- Local Storage Methods ---
  // Check if local storage is available (not on web)
  bool get _canUseLocalStorage =>
       (Platform.isAndroid || Platform.isIOS || Platform.isWindows);

  // Save category and brand data to local storage
  Future<void> _saveDataToLocalStorage() async {
    if (!_canUseLocalStorage) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert categories to JSON and save
      final categoriesJson =
          jsonEncode(_categories.map((cat) => cat.toJson()).toList());
      await prefs.setString('cached_categories', categoriesJson);

      // Convert brands to JSON and save
      final brandsJson =
          jsonEncode(_brands.map((brand) => brand.toJson()).toList());
      await prefs.setString('cached_brands', brandsJson);

      // Save timestamp of the cache
      await prefs.setInt(
          'cache_timestamp', DateTime.now().millisecondsSinceEpoch);

      if (kDebugMode) {
        print(
            'Saved to local storage: ${_categories.length} categories, ${_brands.length} brands');
      }

      // Also save category images to local file storage
      await _saveCategoryImagesToLocalStorage();
    } catch (e) {
      if (kDebugMode) {
        print('Error saving data to local storage: $e');
      }
    }
  }

  // Save category images to local file storage
  Future<void> _saveCategoryImagesToLocalStorage() async {
    if (!_canUseLocalStorage) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/category_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Save each cached image
      for (var entry in _imageCache.entries) {
        final imagePath = entry.key;
        final imageData = entry.value;

        // Extract filename from path - handle different formats
        String fileName = imagePath;
        if (imagePath.contains('/')) {
          fileName = imagePath.split('/').last;
        }

        final file = File('${imagesDir.path}/$fileName');
        await file.writeAsBytes(imageData);

        if (kDebugMode) {
          print('Saved image to local storage: $fileName');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving category images to local storage: $e');
      }
    }
  }

  // Load data from local storage
  Future<bool> _loadDataFromLocalStorage() async {
    if (!_canUseLocalStorage) return false;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load categories
      final categoriesJson = prefs.getString('cached_categories');
      if (categoriesJson != null) {
        final List<dynamic> decodedCategories = jsonDecode(categoriesJson);
        _categories = decodedCategories
            .map((json) => CategoryDTO.fromJson(json))
            .toList();
      }

      // Load brands
      final brandsJson = prefs.getString('cached_brands');
      if (brandsJson != null) {
        final List<dynamic> decodedBrands = jsonDecode(brandsJson);
        _brands = decodedBrands.map((json) => BrandDTO.fromJson(json)).toList();
      }

      if (_categories.isNotEmpty || _brands.isNotEmpty) {
        if (kDebugMode) {
          print(
              'Loaded from local storage: ${_categories.length} categories, ${_brands.length} brands');
        }

        // Load category images from local file storage
        await _loadCategoryImagesFromLocalStorage();

        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading data from local storage: $e');
      }
      return false;
    }
  }

  // Load category images from local file storage
  Future<void> _loadCategoryImagesFromLocalStorage() async {
    if (!_canUseLocalStorage) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/category_images');

      if (!await imagesDir.exists()) {
        return;
      }

      // Preload images for categories
      for (var category in _categories) {
        if (category.imageUrl != null && category.imageUrl!.isNotEmpty) {
          // Extract filename from the image URL
          String fileName = category.imageUrl!;
          if (fileName.contains('/')) {
            fileName = fileName.split('/').last;
          }

          final file = File('${imagesDir.path}/$fileName');
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            _imageCache[category.imageUrl!] = bytes;

            if (kDebugMode) {
              print('Loaded image from local storage: $fileName');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading category images from local storage: $e');
      }
    }
  }

  // --- Server Data Fetching Methods ---
  // Fetch categories from server with pagination
  Future<void> _fetchCategoriesFromServer() async {
    if (kDebugMode) print('Fetching categories from server...');
    _categories.clear();

    int currentPage = 0;
    int totalPages = 1;
    const int pageSize = 100;

    while (currentPage < totalPages) {
      if (kDebugMode) print('Fetching category page $currentPage...');
      final categoryPageResponse =
          await _productService.fetchCategoriesPaginated(
              page: currentPage,
              size: pageSize,
              sortBy: 'name',
              sortDir: 'asc');

      _categories.addAll(categoryPageResponse.content);
      totalPages = categoryPageResponse.totalPages;
      currentPage++;

      if (kDebugMode) {
        print(
            'Fetched ${categoryPageResponse.content.length} categories on page $currentPage. Total pages: $totalPages. Total accumulated: ${_categories.length}');
      }
    }

    // Preload category images and cache them
    await _preloadCategoryImages();
  }

  // Preload and cache category images
  Future<void> _preloadCategoryImages() async {
    for (var category in _categories) {
      if (category.imageUrl != null && category.imageUrl!.isNotEmpty) {
        try {
          final imageData =
              await _categoriesService.getImageFromServer(category.imageUrl);
          if (imageData != null) {
            _imageCache[category.imageUrl!] = imageData;

            if (kDebugMode) {
              print('Cached image for category: ${category.name}');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error preloading image for category ${category.id}: $e');
          }
        }
      }
    }
  }

  // Fetch brands from server
  Future<void> _fetchBrandsFromServer() async {
    if (kDebugMode) print('Fetching brands from server...');
    _brands = await _productService.getAllBrands();
    if (kDebugMode) print('Fetched ${_brands.length} brands.');
  }

  // --- Initialization Method ---
  // Fetches all initial data from backend APIs
  Future<void> loadData() async {
    if (_isInitialized || _isLoading) {
      if (kDebugMode)
        print('AppDataService already initialized or is loading.');
      return;
    }

    _isLoading = true;
    if (kDebugMode) print('Initializing AppDataService...');

    try {
      // Check connectivity first
      await _checkConnectivity();

      if (_isOnline) {
        // Online path - fetch from server
        if (kDebugMode) print('Online mode: Fetching data from server');

        // Fetch categories with pagination
        await _fetchCategoriesFromServer();

        // Fetch brands
        await _fetchBrandsFromServer();

        // Save to local storage for offline use
        if (_canUseLocalStorage) {
          await _saveDataToLocalStorage();
        }
      } else {
        // Offline path - try to load from local storage
        if (kDebugMode)
          print('Offline mode: Trying to load from local storage');

        final loaded = await _loadDataFromLocalStorage();
        if (!loaded) {
          if (kDebugMode) {
            print('No data available in local storage while offline');
          }
          // Initialize with empty lists
          _categories = [];
          _brands = [];
        }
      }

      // Đánh dấu đã khởi tạo thành công
      _isInitialized = true;
      if (kDebugMode) print('AppDataService initialization complete.');

      // *** THÊM DÒNG NÀY: Thông báo cho các listener khi dữ liệu đã sẵn sàng ***
      notifyListeners();
      if (kDebugMode) print('AppDataService notified listeners.');
    } catch (e) {
      if (kDebugMode) print('Error initializing AppDataService: $e');

      // Try loading from local storage as fallback if server fetch fails
      if (_canUseLocalStorage) {
        if (kDebugMode)
          print('Trying to load from local storage as fallback...');
        final loaded = await _loadDataFromLocalStorage();
        if (loaded) {
          _isInitialized = true;
          notifyListeners();
          if (kDebugMode)
            print('Successfully loaded data from local storage as fallback');
        } else {
          _categories = [];
          _brands = [];
          _isInitialized = false; // Đánh dấu khởi tạo thất bại
          if (kDebugMode)
            print('Failed to load data from local storage as fallback');
        }
      } else {
        _categories = [];
        _brands = [];
        _isInitialized = false; // Đánh dấu khởi tạo thất bại
      }
    } finally {
      _isLoading = false;
    }
  }

  // --- Methods to Update Singleton Data (Called after Add/Edit/Delete UI actions) ---
  // These methods update the local list and notify listeners.
  // The actual API calls happen in the UI layer (e.g., dialog) before calling these.

  // *** ADD: Method to add a new category to the list ***
  void addCategory(CategoryDTO newCategory) {
    _categories.add(newCategory);
    // Optional: Sort the list after adding if order matters for UI display
    // _categories.sort((a, b) => a.name?.compareTo(b.name ?? '') ?? 0); // Example sort by name
    if (kDebugMode)
      print(
          'AppDataService: Added category "${newCategory.name}". New total: ${_categories.length}');

    // Also update local storage if available
    if (_canUseLocalStorage) {
      _saveDataToLocalStorage();
    }

    // If the category has an image, cache it
    if (newCategory.imageUrl != null && newCategory.imageUrl!.isNotEmpty) {
      _categoriesService
          .getImageFromServer(newCategory.imageUrl)
          .then((imageData) {
        if (imageData != null) {
          _imageCache[newCategory.imageUrl!] = imageData;

          // Also save this individual image to local storage
          if (_canUseLocalStorage) {
            _saveCategoryImagesToLocalStorage();
          }
        }
      });
    }

    // Notify listeners that the data has changed
    notifyListeners();
  }

  // *** ADD: Method to update an existing category in the list ***
  void updateCategory(CategoryDTO updatedCategory) {
    // Find the category by ID and replace it in the list
    final index = _categories.indexWhere((cat) => cat.id == updatedCategory.id);
    if (index != -1) {
      final oldCategory = _categories[index];
      _categories[index] = updatedCategory;
      if (kDebugMode)
        print(
            'AppDataService: Updated category "${updatedCategory.name}" (ID: ${updatedCategory.id}).');

      // Update local storage
      if (_canUseLocalStorage) {
        _saveDataToLocalStorage();
      }

      // If the image URL has changed, cache the new image
      if (updatedCategory.imageUrl != oldCategory.imageUrl) {
        if (updatedCategory.imageUrl != null &&
            updatedCategory.imageUrl!.isNotEmpty) {
          _categoriesService
              .getImageFromServer(updatedCategory.imageUrl)
              .then((imageData) {
            if (imageData != null) {
              _imageCache[updatedCategory.imageUrl!] = imageData;

              // Also save this individual image to local storage
              if (_canUseLocalStorage) {
                _saveCategoryImagesToLocalStorage();
              }
            }
          });
        }
      }

      // Optional: Sort the list after updating if order matters
      // _categories.sort((a, b) => a.name?.compareTo(b.name ?? '') ?? 0); // Example sort by name
      // Notify listeners that the data has changed
      notifyListeners();
    } else {
      if (kDebugMode)
        print(
            'AppDataService: Could not find category with ID ${updatedCategory.id} to update.');
    }
  }

  // *** ADD: Method to delete a category from the list ***
  // Although delete UI is removed, keep this for completeness if backend delete is implemented
  void deleteCategory(int categoryId) {
    final initialLength = _categories.length;

    // Find the category first to get its image URL
    final categoryToDelete = _categories
        .firstWhere((cat) => cat.id == categoryId, orElse: () => CategoryDTO());

    _categories.removeWhere((cat) => cat.id == categoryId);
    if (_categories.length < initialLength) {
      if (kDebugMode)
        print(
            'AppDataService: Deleted category with ID $categoryId. New total: ${_categories.length}');

      // Update local storage
      if (_canUseLocalStorage) {
        _saveDataToLocalStorage();
      }

      // Notify listeners that the data has changed
      notifyListeners();
    } else {
      if (kDebugMode)
        print(
            'AppDataService: Could not find category with ID $categoryId to delete.');
    }
  }

  // Optional: Method to explicitly notify listeners without changing data
  void refreshListeners() {
    notifyListeners();
  }

  // Dispose the httpClients when the service is no longer needed
  void dispose() {
    // Dispose the service instances if they have dispose methods
    _categoriesService.dispose();
    _productService.dispose();
    super.dispose(); // Dispose ChangeNotifier
    if (kDebugMode) print('AppDataService disposed.');
  }

  // Helper method to get image data for a category from cache
  Uint8List? getCategoryImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    return _imageCache[imageUrl];
  }

  // Add these helper methods to make image access consistent

  // Get image from memory cache
  Uint8List? getImageFromCache(String imageUrl) {
    if (_imageCache.containsKey(imageUrl)) {
      return _imageCache[imageUrl];
    }
    return null;
  }

  // Get image from offline storage without trying network
  Future<Uint8List?> getImageFromOfflineStorage(String imageUrl) async {
    // First check memory cache
    final cachedImage = getImageFromCache(imageUrl);
    if (cachedImage != null) {
      return cachedImage;
    }

    // Then try loading from local storage
    try {
      final String fileName = _createImageFileName(imageUrl);
      final file = await _getImageFile(fileName);

      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        // Add to memory cache for faster future access
        _imageCache[imageUrl] = bytes;
        return bytes;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading image from local storage: $e');
      }
    }

    return null;
  }

  // Helper method to create consistent filenames
  String _createImageFileName(String imageUrl) {
    final bytes = utf8.encode(imageUrl);
    final digest = sha256.convert(bytes);
    return digest.toString() + '.png';
  }

  // Helper to get image file
  Future<File> _getImageFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${directory.path}/category_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return File('${imagesDir.path}/$fileName');
  }

  // Refresh images after network is restored
  void refreshImagesAfterNetworkRestoration() {
    if (_categories.isEmpty || _isLoading) return;

    if (kDebugMode) {
      print(
          'AppDataService: Network restored - refreshing all category images');
    }

    // Force reload data from server
    loadData();
  }
}
