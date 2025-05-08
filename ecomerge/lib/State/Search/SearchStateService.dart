import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/database/Storage/ProductStorage.dart';
import 'package:e_commerce_app/widgets/Product/PaginatedProductGrid.dart'; // Add this import

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
  
  // Flag to prevent duplicate searches
  bool _isExecutingSearch = false;

  // Getters
  bool get isSearchMode => _isSearchMode;
  String get currentSearchQuery => _currentSearchQuery;

  // Execute search and clear all caches
  Future<void> executeSearch() async {
    final query = searchController.text.trim();
    if (query.isEmpty) return;
    
    // Skip if already executing search
    if (_isExecutingSearch) {
      if (kDebugMode) {
        print('Skip search - already executing another search');
      }
      return;
    }
    
    _isExecutingSearch = true;
    
    if (kDebugMode) {
      print('Executing search for: "$query" - clearing ALL caches');
    }

    // Set search state
    _isSearchMode = true;
    
    // Clear the current search query to force detection of changes
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
    
    // 4. Perform the search
    try {
      await productStorage.performSearch(query);
    } finally {
      _isExecutingSearch = false;
    }
  }

  // Reset search state
  void resetSearch() {
    _isSearchMode = false;
    _currentSearchQuery = '';
    _isExecutingSearch = false;
    searchController.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
