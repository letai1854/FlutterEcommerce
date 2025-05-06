import 'package:e_commerce_app/database/Storage/BrandCategoryService.dart'; // Import AppDataService
import 'package:e_commerce_app/database/Storage/ProductStorage.dart'; // Import ProductStorageSingleton
import 'package:e_commerce_app/database/models/categories.dart'; // Import CategoryDTO
import 'package:e_commerce_app/database/models/product_dto.dart'; // Import ProductDTO
import 'package:e_commerce_app/database/services/product_service.dart'; // Import ProductService
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForTablet.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForMobile.dart';
import 'package:e_commerce_app/widgets/Product/CatalogProduct.dart';
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';
import 'package:flutter/material.dart';

class PageListProduct extends StatefulWidget {
  const PageListProduct({super.key});

  @override
  State<PageListProduct> createState() => _PageListProductState();
}

class _PageListProductState extends State<PageListProduct> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Sort state
  String currentSortMethod = 'createdDate'; // Default sort method
  String currentSortDir = 'desc'; // Default sort direction
  int selectedCategoryId = -1; // Use -1 to indicate no category selected initially

  // Category data - Access from AppDataService
  List<CategoryDTO> get _allCategories => AppDataService().categories;

  // Product Storage Singleton instance
  final ProductStorageSingleton _productStorage = ProductStorageSingleton();
  final ProductService _productService = ProductService();

  // Listener for AppDataService changes (for categories)
  void _onAppDataServiceChange() {
    print("AppDataService categories updated, rebuilding PageListProduct");
    if (selectedCategoryId == -1 && _allCategories.isNotEmpty) {
      final firstCategoryId = _allCategories.first.id ?? -1;
      if (firstCategoryId != -1) {
        updateSelectedCategory(firstCategoryId);
      }
    }
    setState(() {});
  }

  // Listener for ProductStorageSingleton changes (for products)
  void _onProductStorageChange() {
    print("ProductStorageSingleton data updated, rebuilding PageListProduct");
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // Listen to changes in AppDataService (for categories)
    AppDataService().addListener(_onAppDataServiceChange);
    // Listen to changes in ProductStorageSingleton (for products)
    _productStorage.addListener(_onProductStorageChange);

    // Load AppDataService if not initialized
    if (!AppDataService().isInitialized && !AppDataService().isLoading) {
      print("AppDataService not initialized, calling loadData from PageListProduct initState");
      AppDataService().loadData().catchError((e) {
        print("Error loading data in PageListProduct: $e");
      });
    } else if (AppDataService().isInitialized && _allCategories.isNotEmpty) {
      final firstCategoryId = _allCategories.first.id ?? -1;
      if (firstCategoryId != -1) {
        updateSelectedCategory(firstCategoryId);
      }
    }

    // Add scroll listener to load more products
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    AppDataService().removeListener(_onAppDataServiceChange);
    _productStorage.removeListener(_onProductStorageChange);
    _productService.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (_isConfigInitialized && _canLoadMore) {
        _loadNextPage();
      }
    }
  }

  // Update category selection
  void updateSelectedCategory(int categoryId) {
    if (selectedCategoryId == categoryId) return;

    setState(() {
      selectedCategoryId = categoryId;
      // Reset sort to default when category changes
      currentSortMethod = 'createdDate';
      currentSortDir = 'desc';
    });

    // Load initial products for the new category
    _loadInitialProducts();

    // Scroll to top when category changes
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // Update sort method
  void updateSortMethod(String method) {
    if (currentSortMethod == method) {
      // Toggle sort direction if same method
      setState(() {
        currentSortDir = currentSortDir == 'asc' ? 'desc' : 'asc';
      });
    } else {
      setState(() {
        currentSortMethod = method;
        currentSortDir = 'desc'; // Default to descending for new sort method
      });
    }
    // Reload products with new sort
    _loadInitialProducts();
  }

  // Load initial products for current configuration
  Future<void> _loadInitialProducts() async {
    if (selectedCategoryId == -1) return;

    await _productStorage.loadInitialProducts(
      categoryId: selectedCategoryId,
      sortBy: currentSortMethod,
      sortDir: currentSortDir,
    );
  }

  // Load next page of products
  Future<void> _loadNextPage() async {
    if (selectedCategoryId == -1) return;

    await _productStorage.loadNextPage(
      categoryId: selectedCategoryId,
      sortBy: currentSortMethod,
      sortDir: currentSortDir,
    );
  }

  // Getters for current state
  bool get _isAppDataLoading => AppDataService().isLoading;
  bool get _isAppDataInitialized => AppDataService().isInitialized;

  bool get _isConfigInitialized => _productStorage.isConfigInitialized(
    categoryId: selectedCategoryId,
    sortBy: currentSortMethod,
    sortDir: currentSortDir,
  );

  bool get _isInitialLoading => _productStorage.isInitialLoading(
    categoryId: selectedCategoryId,
    sortBy: currentSortMethod,
    sortDir: currentSortDir,
  );

  bool get _isLoadingMore => _productStorage.isLoadingMore(
    categoryId: selectedCategoryId,
    sortBy: currentSortMethod,
    sortDir: currentSortDir,
  );

  bool get _canLoadMore => _productStorage.canLoadMore(
    categoryId: selectedCategoryId,
    sortBy: currentSortMethod,
    sortDir: currentSortDir,
  );

  List<ProductDTO> get _currentProducts => _productStorage.getProductsForConfig(
    categoryId: selectedCategoryId,
    sortBy: currentSortMethod,
    sortDir: currentSortDir,
  );

  @override
  Widget build(BuildContext context) {
    print('Building PageListProduct...');
    final List<CategoryDTO> currentCategories = _allCategories;
    print('Current categories count from AppDataService: ${currentCategories.length}');

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        Widget appBar;

        Widget body = CatalogProduct(
          filteredProducts: _currentProducts,
          scaffoldKey: _scaffoldKey,
          scrollController: _scrollController,
          currentSortMethod: currentSortMethod,
          selectedCategoryId: selectedCategoryId,
          categories: currentCategories,
          updateSelectedCategory: updateSelectedCategory,
          updateSortMethod: updateSortMethod,
          isAppDataLoading: _isAppDataLoading,
          isAppDataInitialized: _isAppDataInitialized,
          isProductsLoading: _isInitialLoading || _isLoadingMore,
          canLoadMoreProducts: _canLoadMore,
        );

        if (screenWidth < 768) {
          return NavbarFormobile(
            body: body,
          );
        } else if (screenWidth < 1100) {
          return NavbarForTablet(
            body: body,
          );
        } else {
          appBar = PreferredSize(
            preferredSize: Size.fromHeight(130),
            child: Navbarhomedesktop(),
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
