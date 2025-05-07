import 'package:flutter/material.dart';

class SearchStateService extends ChangeNotifier {
  static final SearchStateService _instance = SearchStateService._internal();

  factory SearchStateService() {
    return _instance;
  }

  SearchStateService._internal();

  final TextEditingController searchController = TextEditingController();
  
  // Track current search query that was executed
  String _currentSearchQuery = '';
  String get currentSearchQuery => _currentSearchQuery;
  
  // Track if we're in search mode (to prevent caching)
  bool _isSearchMode = false;
  bool get isSearchMode => _isSearchMode;

  // Execute search with current text
  void executeSearch() {
    _currentSearchQuery = searchController.text.trim();
    _isSearchMode = true;
    notifyListeners();
  }
  
  // Clear search text and state when navigating
  void clearSearchTextOnNavigation() {
    searchController.clear();
    _currentSearchQuery = '';
    _isSearchMode = false;
    print("Search text cleared due to navigation.");
    notifyListeners();
  }
  
  // Method to set search text programmatically
  void setSearchText(String text) {
    searchController.text = text;
    notifyListeners();
  }
}
