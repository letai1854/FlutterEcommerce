import 'package:e_commerce_app/Constants/productTest.dart';
import 'package:e_commerce_app/database/Storage/BrandCategoryService.dart'; // Import AppDataService
import 'package:e_commerce_app/database/models/categories.dart'; // Import CategoryDTO
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForTablet.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForMobile.dart';
import 'package:e_commerce_app/widgets/Product/CatalogProduct.dart';
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';
import 'package:flutter/material.dart';

// Đảm bảo CategoryDTO được định nghĩa hoặc import đúng

class PageListProduct extends StatefulWidget {
  const PageListProduct({super.key});

  @override
  State<PageListProduct> createState() => _PageListProductState();
}

class _PageListProductState extends State<PageListProduct> {
  // Core product data and filters (using dummy data Productest for now)
  List<Map<String, dynamic>> productData = Productest.productData;
  List<Map<String, dynamic>> filteredProducts = [];
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Sort state
  String currentSortMethod = '';
  // Initial selected category might default to the first category ID loaded,
  // or an 'All' category ID if you have one. Using 1 as a placeholder.
  int selectedCategoryId = 1;

  // Category data - Access from AppDataService
  // *** Đảm bảo AppDataService đã được khởi tạo và load data ở đâu đó trước khi hiển thị trang này ***
  List<CategoryDTO> get _allCategories => AppDataService().categories;

  // *** THÊM: Listener để cập nhật UI khi AppDataService thay đổi (khi data load xong) ***
  void _onAppDataServiceChange() {
     print("AppDataService categories updated, rebuilding PageListProduct");
    // Khi data trong AppDataService thay đổi, gọi setState để rebuild widget
    // và CatalogProduct sẽ nhận danh sách categories mới
    setState(() {
        // Có thể cần cập nhật lại filteredProducts nếu category ID 1 không còn tồn tại
        // hoặc nếu bạn muốn mặc định hiển thị sản phẩm của danh mục đầu tiên sau khi load.
        // Hiện tại giữ nguyên logic filter cũ dựa trên selectedCategoryId và productData dummy.
    });
  }


  @override
  void initState() {
    super.initState();
    // Initialize filteredProducts with dummy data (or an empty list if fetching real products)
    //filteredProducts = List.from(productData);

     // *** THÊM: Đăng ký listener cho AppDataService ***
     AppDataService().addListener(_onAppDataServiceChange);

      // *** Quan trọng: Load data nếu chưa được load ***
      // Bạn cần đảm bảo AppDataService().loadData() được gọi. Tốt nhất là ở main()
      // hoặc trên màn hình khởi động/splash screen. Nhưng nếu chưa chắc chắn,
      // bạn có thể gọi ở đây, xử lý loading state.
       if (!AppDataService().isInitialized && !AppDataService().isLoading) {
          print("AppDataService not initialized, calling loadData from PageListProduct initState");
          AppDataService().loadData().catchError((e) {
             print("Error loading data in PageListProduct: $e");
             // Hiển thị lỗi cho người dùng nếu cần
          });
       } else {
          print("AppDataService already initialized or loading in PageListProduct initState");
           // Nếu đã initialized, bạn có thể muốn lọc lại sản phẩm ngay
            if (_isAppDataInitialized) {
                 // Find the first category ID if 1 doesn't exist, or keep 1
                 final firstCategoryId = _allCategories.isNotEmpty ? (_allCategories.first.id ?? 1) : 1;
                 // Ensure selectedCategoryId is valid if categories loaded
                 if (_allCategories.any((cat) => cat.id == selectedCategoryId)) {
                    // selected ID is valid, keep it
                 } else if (_allCategories.isNotEmpty) {
                    // selected ID invalid, default to first loaded category
                    selectedCategoryId = _allCategories.first.id ?? 1;
                 } else {
                    // No categories loaded, potentially show no products
                     selectedCategoryId = -1; // Use an invalid ID if no categories
                 }

                 // Filter products based on the (potentially updated) selected category ID
                 filteredProducts = productData.where((product) =>
                   product['category_id'] == selectedCategoryId
                 ).toList();
                  print("Initial filtering done based on selectedCategoryId: $selectedCategoryId. Products: ${filteredProducts.length}");
             } else {
                // If loading but not initialized, filteredProducts remains empty or from dummy initial state
                 filteredProducts = List.from(productData); // Keep initial dummy products if not yet initialized
             }
       }

  }

  @override
  void dispose() {
    _scrollController.dispose();
    // *** THÊM: Hủy đăng ký listener khi widget bị dispose ***
    AppDataService().removeListener(_onAppDataServiceChange);
    super.dispose();
  }

  // Update category selection
  void updateSelectedCategory(int categoryId) {
    setState(() {
      selectedCategoryId = categoryId;
      // Filter products based on category
      // *** LƯU Ý: Chỗ này vẫn đang dùng productData dummy. ***
      // Nếu bạn fetch sản phẩm thật từ API, logic filter sẽ khác.
      filteredProducts = productData.where((product) =>
        product['category_id'] == categoryId
      ).toList();
      print('Selected category ID: $categoryId. Filtered products count: ${filteredProducts.length}');

       // Optional: Scroll to top of the product list when category changes
       _scrollController.animateTo(
           0,
           duration: const Duration(milliseconds: 300),
           curve: Curves.easeOut,
       );
    });
  }

  // Update sort method
  void updateSortMethod(String method) {
    setState(() {
      currentSortMethod = method;
      // Products will be sorted in CatalogProduct widget
    });
  }

  bool get _isAppDataLoading => AppDataService().isLoading;
  bool get _isAppDataInitialized => AppDataService().isInitialized;


  @override
  Widget build(BuildContext context) {
     print('Building PageListProduct...');
     // Lấy danh sách category hiện tại từ AppDataService
     final List<CategoryDTO> currentCategories = _allCategories;
     print('Current categories count from AppDataService: ${currentCategories.length}');


    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        Widget appBar;

        // *** TRUYỀN categories (List<CategoryDTO>) ĐÚNG VÀO CatalogProduct ***
        Widget body = CatalogProduct(
          filteredProducts: filteredProducts, // vẫn dùng filteredProducts từ state này
          scaffoldKey: _scaffoldKey,
          scrollController: _scrollController,
          currentSortMethod: currentSortMethod,
          selectedCategoryId: selectedCategoryId,
          categories: currentCategories, // <<< TRUYỀN DANH SÁCH List<CategoryDTO> TỪ AppDataService
          updateSelectedCategory: updateSelectedCategory,
          updateSortMethod: updateSortMethod,
           // Truyền trạng thái loading/initialized xuống để CatalogProduct hiển thị UI phù hợp
           isAppDataLoading: _isAppDataLoading,
           isAppDataInitialized: _isAppDataInitialized,
        );

        if (screenWidth < 768) {
          // Mobile layout
          return NavbarFormobile(
            body: body,
          );
        } else if (screenWidth < 1100) {
          // Tablet layout
          return NavbarForTablet(
            body: body,
          );
        } else {
          // Desktop layout
          appBar = PreferredSize(
            preferredSize: Size.fromHeight(130),
            child: Navbarhomedesktop(), // Đảm bảo Navbarhomedesktop không gây lỗi layout
          );
          return Scaffold(
            appBar: appBar as PreferredSize,
            body: body,
          );
        }
      },
    );
  }
}
