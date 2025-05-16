import 'package:e_commerce_app/database/Storage/BrandCategoryService.dart'; // Import AppDataService
import 'package:e_commerce_app/database/Storage/ProductStorage.dart'; // Import ProductStorageSingleton
import 'package:e_commerce_app/database/models/categories.dart'; // Import CategoryDTO
import 'package:e_commerce_app/database/models/product_dto.dart'; // Import ProductDTO
import 'package:e_commerce_app/database/services/product_service.dart'; // Import ProductService
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForTablet.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForMobile.dart';
import 'package:e_commerce_app/widgets/Product/CatalogProduct.dart';
import 'package:e_commerce_app/widgets/Product/PaginatedProductGrid.dart';
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Import kDebugMode

import 'package:connectivity_plus/connectivity_plus.dart'; // Import Connectivity

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
  int selectedCategoryId =
      -1; // Use -1 to indicate no category selected initially

  // Category data - Access from AppDataService
  List<CategoryDTO> get _allCategories => AppDataService().categories;

  // Product Storage Singleton instance
  final ProductStorageSingleton _productStorage = ProductStorageSingleton();
  final ProductService _productService = ProductService();

  // --- Add this flag ---
  bool _isCurrentlyLoadingNextPage = false;
  // --------------------

  // Thêm Map cache cho widget sản phẩm ở cấp độ PageList
  final Map<String, Widget> _productWidgetCache = {};

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

    // Add connectivity listener
    _setupConnectivityListener();

    // Load AppDataService if not initialized
    if (!AppDataService().isInitialized && !AppDataService().isLoading) {
      print(
          "AppDataService not initialized, calling loadData from PageListProduct initState");
      AppDataService().loadData().then((_) {
        // Ensure first category is selected after data loads if nothing is selected
        if (selectedCategoryId == -1 && _allCategories.isNotEmpty) {
          final firstCategoryId = _allCategories.first.id ?? -1;
          if (firstCategoryId != -1) {
            // Check mounted before calling setState after async operation
            if (mounted) {
              updateSelectedCategory(firstCategoryId);
            }
          }
        }
      }).catchError((e) {
        print("Error loading data in PageListProduct: $e");
      });
    } else if (AppDataService().isInitialized && _allCategories.isNotEmpty) {
      // If already initialized, ensure a category is selected
      if (selectedCategoryId == -1) {
        final firstCategoryId = _allCategories.first.id ?? -1;
        if (firstCategoryId != -1) {
          updateSelectedCategory(firstCategoryId);
        }
      } else {
        // If a category is already selected, ensure its products are loaded
        _loadInitialProducts();
      }
    }

    // Add scroll listener to load more products
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    // Reset flag when leaving this page
    _productStorage.resetReturnVisitFlag();
    _scrollController.removeListener(_onScroll); // Ensure listener is removed
    _scrollController.dispose();
    AppDataService().removeListener(_onAppDataServiceChange);
    _productStorage.removeListener(_onProductStorageChange);
    
    // Xóa cache khi thoát khỏi trang
    _productWidgetCache.clear();
    _productService.dispose();
    
    super.dispose();
  }

  void _onScroll() {
    // First check if ScrollController has attached clients to avoid errors
    if (!_scrollController.hasClients) return;

    try {
      // More reliable scroll detection with proper bounds checking
      if (mounted &&
          AppDataService().isInitialized &&
          _scrollController.position.maxScrollExtent > 0 &&
          _scrollController.position.extentAfter < 350) {
        if (_isConfigInitialized &&
            _canLoadMore &&
            !_isCurrentlyLoadingNextPage) {
          if (kDebugMode)
            print(
                "Scroll near bottom (extentAfter < 250.0), attempPting to load next page.");
          _loadNextPage();
        } else {
          if (kDebugMode) {
            print(
                "Scroll near bottom, but cannot load next page. Config Initialized: $_isConfigInitialized, Can Load More: $_canLoadMore, Currently Loading: $_isCurrentlyLoadingNextPage");
          }
        }
      }
    } catch (e) {
      // Catch any scrolling-related errors that might occur
      if (kDebugMode) print("Error in scroll detection: $e");
    }
  }

  // Add a getter to check if we have cached data for current configuration
  bool get _hasDataInCache => _productStorage.hasDataInCache(
        categoryId: selectedCategoryId,
        sortBy: currentSortMethod,
        sortDir: currentSortDir,
      );

  // Add a getter to check if we're showing cached content immediately
  bool get _isShowingCachedContent => _productStorage.isShowingCachedContent;

  // Update category selection
  void updateSelectedCategory(int categoryId) {
    if (selectedCategoryId == categoryId) return;

    // Xóa cache khi chuyển sang category mới
    _clearCacheForCategory(categoryId);

    // Check if we already have cached data for this category
    final bool hasCachedData = _productStorage.hasDataInCache(
      categoryId: categoryId,
      sortBy: currentSortMethod,
      sortDir: currentSortDir,
    );

    if (hasCachedData) {
      if (kDebugMode) print('Using cached data for category $categoryId');
    }

    setState(() {
      selectedCategoryId = categoryId;
      // Don't reset sort method when using cached data
      if (!hasCachedData) {
        currentSortMethod = 'createdDate';
        currentSortDir = 'desc';
      }
    });

    // Load products for the new category
    // Will automatically use cached data if available
    _loadInitialProducts();

    // Safely scroll to top when category changes - use post-frame callback
    // to ensure the scroll view is built and controller is attached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else if (kDebugMode) {
        print('ScrollController not attached yet, skipping scroll to top');
      }
    });
  }

  // Xóa cache cho category được chọn
  void _clearCacheForCategory(int categoryId) {
    final String categoryPrefix = 'category_${categoryId}_';
    
    // Tìm và xóa tất cả cache liên quan đến category này
    final keysToRemove = _productWidgetCache.keys
        .where((key) => key.startsWith(categoryPrefix))
        .toList();
        
    if (kDebugMode && keysToRemove.isNotEmpty) {
      print('Clearing ${keysToRemove.length} cached items for category $categoryId');
    }
    
    for (final key in keysToRemove) {
      _productWidgetCache.remove(key);
    }
  }

  // Modify isInitialLoading to respect cache status
  bool get _isInitialLoading {
    // Don't show loading if we have cached data and are showing it immediately
    if (_hasDataInCache && _isShowingCachedContent) {
      return false;
    }
    return _productStorage.isInitialLoading(
      categoryId: selectedCategoryId,
      sortBy: currentSortMethod,
      sortDir: currentSortDir,
    );
  }

  // Update sort method
  void updateSortMethod(String method) {
    String newSortDir;
    if (currentSortMethod == method) {
      // Toggle sort direction if same method
      newSortDir = currentSortDir == 'asc' ? 'desc' : 'asc';
    } else {
      newSortDir = 'desc'; // Default to descending for new sort method
    }

    // Xóa cache cho category hiện tại khi thay đổi sort
    final String categoryPrefix = 'category_${selectedCategoryId}_${currentSortMethod}_${currentSortDir}';
    final String newPrefix = 'category_${selectedCategoryId}_${method}_${newSortDir}';
    
    if (kDebugMode) {
      print('Sort changing from $categoryPrefix to $newPrefix, clearing related cache');
    }
    
    // Tìm và xóa tất cả cache liên quan đến category với sort method cũ
    final keysToRemove = _productWidgetCache.keys
        .where((key) => key.startsWith(categoryPrefix))
        .toList();
    
    for (final key in keysToRemove) {
      _productWidgetCache.remove(key);
    }
    
    setState(() {
      currentSortMethod = method;
      currentSortDir = newSortDir;
    });
    
    // Reload products with new sort
    _loadInitialProducts();
  }

  // Load initial products for current configuration
  Future<void> _loadInitialProducts() async {
    if (selectedCategoryId == -1) return;
    // Prevent loading if AppData is still loading, to avoid race conditions with category selection
    if (AppDataService().isLoading && !AppDataService().isInitialized) {
      if (kDebugMode)
        print("Skipping initial product load as AppData is still loading.");
      return;
    }

    // Reset the loading flag before starting, useful if a previous load was interrupted.
    if (mounted) {
      setState(() {
        _isCurrentlyLoadingNextPage = false;
      });
    }

    await _productStorage.loadInitialProducts(
      categoryId: selectedCategoryId,
      sortBy: currentSortMethod,
      sortDir: currentSortDir,
    );
  }

  // Load next page of products
  Future<void> _loadNextPage() async {
    // Ensure a category is selected, more products can be loaded, and not already loading
    if (selectedCategoryId == -1 ||
        !_canLoadMore ||
        _isCurrentlyLoadingNextPage) {
      if (kDebugMode) {
        print(
            "Skipping loadNextPage. Category: $selectedCategoryId, Can Load More: $_canLoadMore, Currently Loading: $_isCurrentlyLoadingNextPage");
      }
      return;
    }

    // Set local loading state flag
    if (mounted) {
      setState(() {
        _isCurrentlyLoadingNextPage = true;
      });
    }

    try {
      // Load next page of products
      await _productStorage.loadNextPage(
        categoryId: selectedCategoryId,
        sortBy: currentSortMethod,
        sortDir: currentSortDir,
      );
    } catch (e) {
      if (kDebugMode) print('Error in _loadNextPage: $e');
    } finally {
      // Reset the flag after the loading operation is complete (successful or not)
      if (mounted) {
        setState(() {
          _isCurrentlyLoadingNextPage = false;
        });
      }
    }
  }

  // Getters for current state
  bool get _isAppDataLoading => AppDataService().isLoading;
  bool get _isAppDataInitialized => AppDataService().isInitialized;

  bool get _isConfigInitialized => _productStorage.isConfigInitialized(
        categoryId: selectedCategoryId,
        sortBy: currentSortMethod,
        sortDir: currentSortDir,
      );

  // Explicitly handle both local and storage loading state for better visibility
  bool get _isLoadingMore {
    final storageIsLoading = _productStorage.isLoadingMore(
      categoryId: selectedCategoryId,
      sortBy: currentSortMethod,
      sortDir: currentSortDir,
    );

    // Either our local flag or the storage flag can indicate loading
    return _isCurrentlyLoadingNextPage || storageIsLoading;
  }

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
    if (kDebugMode) print('Building PageListProduct...');
    final List<CategoryDTO> currentCategories = _allCategories;
    if (kDebugMode)
      print(
          'Current categories count from AppDataService: ${currentCategories.length}');
    // If no category is selected yet and categories are available, select the first one.
    // This can happen if initial loadData completes after first build.
    if (selectedCategoryId == -1 &&
        currentCategories.isNotEmpty &&
        AppDataService().isInitialized &&
        !AppDataService().isLoading) {
      final firstCategoryId = currentCategories.first.id;
      if (firstCategoryId != null) {
        // Call updateSelectedCategory in a post-frame callback to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && selectedCategoryId == -1) {
            // Double check selection hasn't changed
            updateSelectedCategory(firstCategoryId);
          }
        });
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        Widget appBar;

        // Determine the combined loading state to pass to CatalogProduct
        // Only show loading if we're actually loading new data, not using cached data
        bool currentProductsLoadingState = (_isInitialLoading ||
                _isLoadingMore) &&
            (!_isShowingCachedContent || (_isLoadingMore && !_hasDataInCache));

        Widget body = CatalogProduct(
          filteredProducts: _currentProducts,
          scaffoldKey: _scaffoldKey,
          scrollController: _scrollController,
          currentSortMethod: currentSortMethod,
          currentSortDir: currentSortDir, // Pass sort direction
          selectedCategoryId: selectedCategoryId,
          categories: currentCategories,
          updateSelectedCategory: updateSelectedCategory,
          updateSortMethod: updateSortMethod,
          isAppDataLoading: _isAppDataLoading,
          isAppDataInitialized: _isAppDataInitialized,
          isProductsLoading:
              currentProductsLoadingState, // Pass the combined state
          canLoadMoreProducts: _canLoadMore,
          isShowingCachedContent: _isShowingCachedContent,
          isOnline: _productStorage.isOnline, // Pass online status
          productWidgetCache: _productWidgetCache, // Truyền cache xuống CatalogProduct
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

  // Check for connectivity changes when returning to this page
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if we need to refresh data when coming back online
    if (_productStorage.isOnline && selectedCategoryId != -1) {
      // When we return to this page and are online, check if we should refresh data
      // But don't do it immediately - wait for route transitions to complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && selectedCategoryId != -1) {
          // If we're coming back online, refresh data
          _productStorage.refreshDataIfOnline(
            categoryId: selectedCategoryId,
            sortBy: currentSortMethod,
            sortDir: currentSortDir,
          );
        }
      });
    }
  }

  // Add this method to listen for connectivity changes
  void _setupConnectivityListener() {
    // Get initial connectivity status
    final Connectivity _connectivity = Connectivity();
    bool _previousOnlineStatus = _productStorage.isOnline;

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      final bool isNowOnline = result != ConnectivityResult.none;
      final bool wasOffline = !_previousOnlineStatus;

      if (wasOffline && isNowOnline && mounted) {
        // Network restored - refresh data
        if (kDebugMode) {
          print("Network restored in PageListProduct - refreshing data");
        }

        // Refresh both categories and current products
        if (selectedCategoryId != -1) {
          // Refresh current category data (will be done automatically by Storage now)
          // Just make sure UI updates
          setState(() {});
        }
      }

      _previousOnlineStatus = isNowOnline;
    });
  }
}
