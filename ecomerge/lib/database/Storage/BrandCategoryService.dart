
// lib/database/Storage/BrandCategoryService.dart
import 'package:e_commerce_app/database/models/brand.dart';
import 'package:e_commerce_app/database/models/categories.dart'; // Assuming CategoryDTO is here
import 'package:e_commerce_app/database/services/categories_service.dart'; // Import CategoriesService
import 'package:e_commerce_app/database/services/product_service.dart'; // Import ProductService (if brands/products handled here)
// Import PageResponse if fetchCategoriesPaginated returns it
import 'package:e_commerce_app/database/PageResponse.dart'; // Assuming PageResponse exists

import 'package:flutter/foundation.dart'; // For kDebugMode, ChangeNotifier


// --- Singleton Setup ---
// AppDataService extends ChangeNotifier to notify listeners when data changes
class AppDataService extends ChangeNotifier {
  static final AppDataService _instance = AppDataService._internal();

  factory AppDataService() {
    return _instance;
  }

  AppDataService._internal();

  // --- Data Storage ---
  // *** CHANGE: These lists are now the source of truth for the UI after loading/updates ***
  List<CategoryDTO> _categories = [];
  List<BrandDTO> _brands = []; // Assuming brands are also managed by this service
  bool _isInitialized = false; // Flag indicates if initial load is complete
  bool _isLoading = false;     // Flag indicates if a load operation is currently in progress

  // --- Dependencies (Service instances) ---
  // Need instances of necessary services to fetch/update data
  final CategoriesService _categoriesService = CategoriesService(); // Use CategoriesService for category APIs
  final ProductService _productService = ProductService(); // Use ProductService for other APIs like brands/products


  // --- Getters ---
  List<CategoryDTO> get categories => _categories;
  List<BrandDTO> get brands => _brands; // Getter for brands list
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading; // Getter for loading state


  // --- Initialization Method ---
  // Fetches all initial data from backend APIs
Future<void> loadData() async {
  if (_isInitialized || _isLoading) {
     if (kDebugMode) print('AppDataService already initialized or is loading.');
     return;
  }

  _isLoading = true;
  if (kDebugMode) print('Initializing AppDataService...');

  try {
    // === Fetch Categories (Handling Pagination) ===
    if (kDebugMode) print('Fetching categories...');
    _categories.clear();

    int currentPage = 0;
    int totalPages = 1;
    const int pageSize = 100;

    while (currentPage < totalPages) {
      if (kDebugMode) print('Fetching category page $currentPage...');
      final categoryPageResponse = await _productService.fetchCategoriesPaginated(
         page: currentPage,
         size: pageSize,
         sortBy: 'name',
         sortDir: 'asc'
      );

      _categories.addAll(categoryPageResponse.content);
      totalPages = categoryPageResponse.totalPages;
      currentPage++;
       if (kDebugMode) print('Fetched ${categoryPageResponse.content.length} categories on page $currentPage. Total pages: $totalPages. Total accumulated: ${_categories.length}');
    }

    if (kDebugMode) print('Finished fetching all categories. Total: ${_categories.length}');


    // === Fetch Brands (Non-Paginated) ===
    if (kDebugMode) print('Fetching brands...');
    _brands = await _productService.getAllBrands();
    if (kDebugMode) print('Fetched ${_brands.length} brands.');


    // Đánh dấu đã khởi tạo thành công
    _isInitialized = true;
    if (kDebugMode) print('AppDataService initialization complete.');

    // *** THÊM DÒNG NÀY: Thông báo cho các listener khi dữ liệu đã sẵn sàng ***
    notifyListeners();
    if (kDebugMode) print('AppDataService notified listeners.');


  } catch (e) {
    if (kDebugMode) print('Error initializing AppDataService: $e');
    _categories = [];
    _brands = [];
     _isInitialized = false; // Đánh dấu khởi tạo thất bại
    rethrow;
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
      if (kDebugMode) print('AppDataService: Added category "${newCategory.name}". New total: ${_categories.length}');
      // Notify listeners that the data has changed
       notifyListeners();
  }

  // *** ADD: Method to update an existing category in the list ***
  void updateCategory(CategoryDTO updatedCategory) {
     // Find the category by ID and replace it in the list
     final index = _categories.indexWhere((cat) => cat.id == updatedCategory.id);
     if (index != -1) {
        _categories[index] = updatedCategory;
        if (kDebugMode) print('AppDataService: Updated category "${updatedCategory.name}" (ID: ${updatedCategory.id}).');
         // Optional: Sort the list after updating if order matters
         // _categories.sort((a, b) => a.name?.compareTo(b.name ?? '') ?? 0); // Example sort by name
         // Notify listeners that the data has changed
         notifyListeners();
     } else {
        if (kDebugMode) print('AppDataService: Could not find category with ID ${updatedCategory.id} to update.');
     }
  }

  // *** ADD: Method to delete a category from the list ***
  // Although delete UI is removed, keep this for completeness if backend delete is implemented
  void deleteCategory(int categoryId) {
      final initialLength = _categories.length;
      _categories.removeWhere((cat) => cat.id == categoryId);
      if (_categories.length < initialLength) {
         if (kDebugMode) print('AppDataService: Deleted category with ID $categoryId. New total: ${_categories.length}');
          // Notify listeners that the data has changed
         notifyListeners();
      } else {
         if (kDebugMode) print('AppDataService: Could not find category with ID $categoryId to delete.');
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
}
