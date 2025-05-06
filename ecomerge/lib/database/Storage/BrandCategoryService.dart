
// Import ProductService đã sửa (đảm bảo import đúng đường dẫn)
import 'package:e_commerce_app/database/models/brand.dart';
import 'package:e_commerce_app/database/models/categories.dart';
import 'package:e_commerce_app/database/services/product_service.dart';
// Import PageResponse
import 'package:e_commerce_app/database/PageResponse.dart'; // <-- Import PageResponse
import 'package:flutter/foundation.dart';

// --- Singleton Setup ---
class AppDataService {
  static final AppDataService _instance = AppDataService._internal();

  factory AppDataService() {
    return _instance;
  }

  AppDataService._internal();

  // --- Data Storage ---
  List<CategoryDTO> _categories = [];
  List<BrandDTO> _brands = [];
  bool _isInitialized = false;
  bool _isLoading = false;

  // --- Dependencies ---
  final ProductService _productService = ProductService();

  // --- Getters ---
  List<CategoryDTO> get categories => _categories;
  List<BrandDTO> get brands => _brands;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;

  // --- Initialization Method ---
  Future<void> loadData() async {
    // Chỉ load data nếu chưa được khởi tạo VÀ hiện tại không đang load
    if (_isInitialized || _isLoading) {
       if (kDebugMode) print('AppDataService already initialized or is loading.');
       return;
    }

    _isLoading = true; // Bắt đầu load
    if (kDebugMode) print('Initializing AppDataService...');

    try {
      // === Fetch Categories (Handling Pagination) ===
      if (kDebugMode) print('Fetching categories...');
      _categories.clear(); // Clear previous data before fetching

      int currentPage = 0;
      int totalPages = 1; // Start with 1 to enter the loop at least once
      const int pageSize = 50; // Define a suitable page size for fetching categories

      while (currentPage < totalPages) {
        if (kDebugMode) print('Fetching category page $currentPage...');
        final categoryPageResponse = await _productService.fetchCategoriesPaginated(
           page: currentPage,
           size: pageSize,
           sortBy: 'name', // Sort by name for consistent order
           sortDir: 'asc'
           // Omit startDate, endDate unless needed during app init
        );

        _categories.addAll(categoryPageResponse.content); // Add categories from the current page
        totalPages = categoryPageResponse.totalPages; // Update total pages
        currentPage++; // Move to the next page
         if (kDebugMode) print('Fetched ${categoryPageResponse.content.length} categories on page $currentPage. Total pages: $totalPages. Total accumulated: ${_categories.length}');
      }

      if (kDebugMode) print('Finished fetching all categories. Total: ${_categories.length}');


      // === Fetch Brands (Non-Paginated) ===
      if (kDebugMode) print('Fetching brands...');
      _brands = await _productService.getAllBrands(); // This still returns List<BrandDTO>
      if (kDebugMode) print('Fetched ${_brands.length} brands.');


      // Đánh dấu đã khởi tạo thành công
      _isInitialized = true;  
      if (kDebugMode) print('AppDataService initialization complete.');

    } catch (e) {
      // Xử lý lỗi trong quá trình load dữ liệu
      if (kDebugMode) print('Error initializing AppDataService: $e');
      // Reset lists về rỗng nếu có lỗi nghiêm trọng
       _categories = [];
       _brands = [];
      // Tùy chọn: Re-throw lỗi để hàm gọi (initApp) xử lý
      rethrow;
    } finally {
        _isLoading = false; // Kết thúc load
    }
  }

  // Optional: Phương thức để giải phóng tài nguyên
  void dispose() {
     _productService.dispose();
  }
}
