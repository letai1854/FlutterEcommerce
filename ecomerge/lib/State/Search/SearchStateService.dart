import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/database/Storage/ProductStorage.dart';
import 'package:e_commerce_app/widgets/Product/PaginatedProductGrid.dart';

class SearchStateService extends ChangeNotifier {
  // Singleton pattern
  static final SearchStateService _instance = SearchStateService._internal();

  factory SearchStateService() {
    return _instance;
  }

  SearchStateService._internal();

  // Search controller
  final TextEditingController searchController = TextEditingController();

  // Track search state
  bool _isSearchMode = false;
  String _currentSearchQuery = '';
  
  // Keep track of whether this is a new search or subsequent filter
  bool _isInitialSearch = true;
  
  // Filter and sort parameters
  int? _selectedCategoryId;
  String? _selectedBrandName;
  int _minPrice = 0;
  int _maxPrice = 10000000; // Default 10 million VND
  String _sortBy = 'createdDate';
  String _sortDir = 'desc';
  
  // Flag to prevent duplicate searches
  bool _isExecutingSearch = false;

  // Add the isPriceFilterApplied field to the SearchStateService class
  bool _isPriceFilterApplied = false;
  bool get isPriceFilterApplied => _isPriceFilterApplied;

  // Getters
  bool get isSearchMode => _isSearchMode;
  String get currentSearchQuery => _currentSearchQuery;
  int? get selectedCategoryId => _selectedCategoryId;
  String? get selectedBrandName => _selectedBrandName;
  int get minPrice => _minPrice;
  int get maxPrice => _maxPrice;
  String get sortBy => _sortBy;
  String get sortDir => _sortDir;
  bool get isInitialSearch => _isInitialSearch;
  
  // Setters for filter and sort parameters
  void setSort(String sortBy, String sortDir) {
    _sortBy = sortBy;
    _sortDir = sortDir;
    // Setting sort indicates we're past initial search
    _isInitialSearch = false;
    notifyListeners();
  }
  
  // Update the setFilters method to include the isPriceFilterApplied parameter
  void setFilters({
    int? categoryId,
    String? brandName,
    int minPrice = 0,
    int maxPrice = 10000000,
    bool isPriceFilterApplied = false, // Add this parameter
  }) {
    _selectedCategoryId = categoryId;
    _selectedBrandName = brandName;
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _isPriceFilterApplied = isPriceFilterApplied; // Store the flag
    
    // If we're setting filters, we're no longer in an initial search state
    _isInitialSearch = false;
    
    // Notify listeners about the state change
    notifyListeners();
  }

  // Reset all filters and sort to default values
  void resetFiltersAndSort() {
    _selectedCategoryId = null;
    _selectedBrandName = null;
    _minPrice = 0;
    _maxPrice = 10000000;
    _sortBy = 'createdDate';
    _sortDir = 'desc';
    notifyListeners();
  }

  // Execute search and clear all caches
  Future<void> executeSearch({bool forceRefresh = false, bool isNewSearch = false}) async {
    final query = searchController.text.trim();
    if (query.isEmpty) return;
    
    // If this is a new search from user input, reset filters and mark as initial search
    if (isNewSearch) {
      if (kDebugMode) {
        print('New search initiated - resetting all filters');
      }
      resetFiltersAndSort();
      _isInitialSearch = true;
    }
    
    // Skip if already executing search
    if (_isExecutingSearch && !forceRefresh) {
      if (kDebugMode) {
        print('Skip search - already executing another search');
      }
      return;
    }
    
    _isExecutingSearch = true;
    
    if (kDebugMode) {
      print('Executing search for: "$query"');
      if (!_isInitialSearch) {
        print('With filters:');
        print('Category ID: $_selectedCategoryId');
        print('Brand Name: $_selectedBrandName');
        print('Price Range: $_minPrice - $_maxPrice');
        print('Sort: $_sortBy $_sortDir');
      } else {
        print('Initial search - NO FILTERS APPLIED');
      }
    }

    // Set search state
    _isSearchMode = true;
    
    // Clear the current search query to force detection of changes
    final String oldQuery = _currentSearchQuery;
    _currentSearchQuery = '';
    
    // IMPORTANT: Clear BOTH caches to ensure fresh search results
    
    // 1. Clear PaginatedProductGrid's search cache first
    // This ensures widgets will be rebuilt for new search results
    PaginatedProductGrid.clearSearchCache();
    
    // 2. Clear ProductStorage's search data
    final ProductStorageSingleton productStorage = ProductStorageSingleton();
    productStorage.clearSearchCache();
    
    // 3. Set the new query and notify listeners
    _currentSearchQuery = query;
    notifyListeners();
    
    // 4. Perform the search with all parameters
    try {
      // Only force clear cache if query changed or force refresh is requested
      final bool shouldClearCache = forceRefresh || oldQuery != query;
      
      // For initial searches, don't include ANY filters or sorting or price ranges
      if (_isInitialSearch) {
        if (kDebugMode) {
          print('Performing initial search with query ONLY - no filters and NO PRICE RANGE');
        }
        await productStorage.performSearch(
          query,
          clearCache: shouldClearCache,
          skipPriceFilter: true // <-- ADD THIS FLAG to skip price filtering!
          // No other parameters passed for initial search
        );
      } else {
        // For subsequent searches/filtering, include all parameters
        if (kDebugMode) {
          print('Performing filtered search with all parameters including price range');
        }
        await productStorage.performSearch(
          query,
          categoryId: _selectedCategoryId,
          brandName: _selectedBrandName,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
          sortBy: _sortBy,
          sortDir: _sortDir,
          clearCache: shouldClearCache,
          skipPriceFilter: false, // Explicitly apply price filters
          isPriceFilterApplied: _isPriceFilterApplied, // Pass the flag
        );
      }
    } finally {
      _isExecutingSearch = false;
    }
  }

  // Reset search state
  void resetSearch() {
    _isSearchMode = false;
    _currentSearchQuery = '';
    _isExecutingSearch = false;
    resetFiltersAndSort();
    _isInitialSearch = true;
    searchController.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
