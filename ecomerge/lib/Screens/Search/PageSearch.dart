import 'dart:math';
import 'package:e_commerce_app/database/Storage/BrandCategoryService.dart';
import 'package:e_commerce_app/database/Storage/ProductStorage.dart';
import 'package:flutter/foundation.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:e_commerce_app/Constants/productTest.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForTablet.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForMobile.dart';
import 'package:e_commerce_app/widgets/Product/PaginatedProductGrid.dart';
import 'package:e_commerce_app/widgets/Search/FilterPanel.dart';
import 'package:e_commerce_app/widgets/Search/SearchProduct.dart';
import 'package:e_commerce_app/widgets/SortingBar.dart';
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';
import 'package:flutter/material.dart';

// Import needed services
import 'package:e_commerce_app/state/Search/SearchStateService.dart';
import 'package:e_commerce_app/database/models/product_dto.dart';

class PageSearch extends StatefulWidget {
  const PageSearch({super.key});

  @override
  State<PageSearch> createState() => _PageSearchState();
}

class _PageSearchState extends State<PageSearch> {
  int _current = 0;

  // Using real singletons for state management
  final ProductStorageSingleton _productStorage = ProductStorageSingleton();
  final SearchStateService _searchService = SearchStateService();

  // Scrolling and scaffolding
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Banner images
  final List<String> imgList = [
    'assets/bannerMain.jpg',
    'assets/banner2.jpg',
    'assets/banner6.jpg',
  ];

  // Single selection for category and brand
  int? selectedCategoryId;
  String? selectedBrandName;

  // Price range state
  TextEditingController minPriceController = TextEditingController();
  TextEditingController maxPriceController = TextEditingController();
  int minPrice = 0;
  int maxPrice = 10000000; // 10 million VND default max
  final int priceStep = 1000000; // Step by 1 million VND
  
  // Add a flag to track if price filter has been explicitly applied
  bool isPriceFilterApplied = false;

  // Sort settings
  String currentSortMethod = 'createdDate'; // Default sort method
  String currentSortDir = 'desc'; // Default sort direction

  // Initialize missing variables required for proper functioning
  bool get _isAppDataLoading => AppDataService().isLoading;
  bool get _isAppDataInitialized => AppDataService().isInitialized;

  @override
  void initState() {
    super.initState();

    // Set up listeners for changes
    _productStorage.addListener(_onProductStorageChange);
    _searchService.addListener(_onSearchServiceChange);

    // Initialize the price filter controllers
    minPriceController.text = formatPrice(minPrice);
    maxPriceController.text = formatPrice(maxPrice);

    // Set up scroll listener for "load more" with a slight delay to ensure proper initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.addListener(_onScroll);
    });

    // Sync with search service state
    _syncWithSearchService();

    // Execute search if there's a query
    _executeInitialSearch();
  }

  // Sync local state with SearchStateService
  void _syncWithSearchService() {
    // Get current values from search service
    selectedCategoryId = _searchService.selectedCategoryId;
    selectedBrandName = _searchService.selectedBrandName;
    minPrice = _searchService.minPrice;
    maxPrice = _searchService.maxPrice;
    currentSortMethod = _searchService.sortBy;
    currentSortDir = _searchService.sortDir;
    
    // Sync our price filter applied flag
    isPriceFilterApplied = _searchService.isPriceFilterApplied;

    // Update controllers
    minPriceController.text = formatPrice(minPrice);
    maxPriceController.text = formatPrice(maxPrice);
  }

  @override
  void dispose() {
    // Clean up resources
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    minPriceController.dispose();
    maxPriceController.dispose();
    _productStorage.removeListener(_onProductStorageChange);
    _searchService.removeListener(_onSearchServiceChange);
    super.dispose();
  }

  // Execute search with current query if there is one
  void _executeInitialSearch() {
    final query = _searchService.currentSearchQuery;
    if (query.isNotEmpty) {
      if (kDebugMode) {
        print('Initial search execution for: "$query"');
        print('isInitialSearch flag: ${_searchService.isInitialSearch}');
      }

      // If this is a brand new search (like coming directly from search bar),
      // we need to execute it as an initial search without filters
      if (_searchService.isInitialSearch) {
        _searchService.executeSearch();
      } else {
        // Otherwise, if we're returning to the page and filters are already set,
        // preserve those filters in the search
        _searchService.executeSearch();
      }
    }
  }

  // Listener for product storage changes
  void _onProductStorageChange() {
    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // Listener for search service changes
  void _onSearchServiceChange() {
    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          // Sync local state with search service
          _syncWithSearchService();
        });
      }
    });
  }

  // Scroll handler for "load more" functionality
  void _onScroll() {
    // First check if ScrollController has attached clients to avoid errors
    if (!_scrollController.hasClients) return;

    // Match the category browsing scroll trigger threshold approach
    if (mounted &&
        _scrollController.position.maxScrollExtent > 0 &&
        _scrollController.position.extentAfter < 50) {
      if (!_productStorage.isSearchLoading &&
          _productStorage.canSearchLoadMore) {
        if (kDebugMode) {
          print(
              'Near bottom of search scroll view, loading more search results');
          print(
              'Position: ${_scrollController.position.pixels}, Max: ${_scrollController.position.maxScrollExtent}');
          print('ExtentAfter: ${_scrollController.position.extentAfter}');
        }

        _productStorage.loadMoreSearchResults();
      }
    }
  }

  // Format price with commas
  String formatPrice(int price) {
    return price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},');
  }

  // Parse price from formatted string
  int parsePrice(String text) {
    if (text.isEmpty) return 0;
    return int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  // Update min price with validation
  void updateMinPrice(int newValue) {
    if (newValue < 0) newValue = 0;
    if (newValue > maxPrice) newValue = maxPrice;

    setState(() {
      minPrice = newValue;
      minPriceController.text = formatPrice(newValue);
    });
  }

  // Update max price with validation
  void updateMaxPrice(int newValue) {
    if (newValue < minPrice) newValue = minPrice;

    setState(() {
      maxPrice = newValue;
      maxPriceController.text = formatPrice(newValue);
    });
  }

  // Apply filters and execute search
  void onFiltersApplied({
    required int? categoryId,
    required String? brandName,
    required int minPrice,
    required int maxPrice,
  }) {
    // Update local state first
    setState(() {
      selectedCategoryId = categoryId;
      selectedBrandName = brandName;
      this.minPrice = minPrice;
      this.maxPrice = maxPrice;
      isPriceFilterApplied = true; // Mark that price filter has been explicitly applied
    });

    // Close drawer on mobile
    if (MediaQuery.of(context).size.width < 1100) {
      Navigator.of(context).pop(); // Close drawer on mobile
    }

    // Update search service state
    _searchService.setFilters(
        categoryId: categoryId,
        brandName: brandName,
        minPrice: minPrice,
        maxPrice: maxPrice,
        isPriceFilterApplied: true); // Tell service price filter is explicitly applied

    // Execute search with current parameters and force refresh
    _searchService.executeSearch(forceRefresh: true);
  }

  // Update sort method and execute search
  void updateSortMethod(String method) {
    setState(() {
      if (currentSortMethod == method) {
        // Toggle direction if same method
        currentSortDir = currentSortDir == 'asc' ? 'desc' : 'asc';
      } else {
        currentSortMethod = method;
        currentSortDir = 'desc'; // Default for new sort
      }
    });

    // Update search service state
    _searchService.setSort(currentSortMethod, currentSortDir);

    // Execute search with current parameters (sort is now included)
    _searchService.executeSearch(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    // Get AppData service state
    final bool isAppDataLoading = AppDataService().isLoading;
    final bool isAppDataInitialized = AppDataService().isInitialized;

    // Get list of all categories
    final categories = AppDataService().categories;

    // Get search results
    final List<ProductDTO> searchResults = _productStorage.searchResults;
    final bool isSearching = _productStorage.isSearchLoading;
    final bool canLoadMore = _productStorage.canSearchLoadMore;

    // Extract brand names from AppDataService - fixed to handle null/empty cases
    final List<String> brandNames = AppDataService().isInitialized
        ? AppDataService()
            .brands
            .where((b) => b.name != null)
            .map((b) => b.name!)
            .toList()
        : [];

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        Widget appBar;
        Widget body = SearchProduct(
          current: _current,
          imgList: imgList,
          searchResults: searchResults,
          scaffoldKey: _scaffoldKey,
          scrollController: _scrollController,
          onFiltersApplied: onFiltersApplied,
          // Filter panel state
          selectedCategoryId: selectedCategoryId,
          selectedBrandName: selectedBrandName,
          minPrice: minPrice,
          maxPrice: maxPrice,
          minPriceController: minPriceController,
          maxPriceController: maxPriceController,
          priceStep: priceStep,
          catalog: categories,
          brands: brandNames,
          updateMinPrice: updateMinPrice,
          updateMaxPrice: updateMaxPrice,
          formatPrice: formatPrice,
          parsePrice: parsePrice,
          isPriceFilterApplied: isPriceFilterApplied, // Pass the flag to SearchProduct
          // Search specific state
          isSearching: isSearching,
          canLoadMore: canLoadMore,
          searchQuery: _searchService.currentSearchQuery,
          // Sort
          currentSortMethod: currentSortMethod,
          currentSortDir: currentSortDir,
          updateSortMethod: updateSortMethod,
          // Additional flags
          isAppDataLoading: isAppDataLoading,
          isAppDataInitialized: isAppDataInitialized,
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
