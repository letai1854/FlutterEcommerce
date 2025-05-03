import 'package:flutter/material.dart';
class SearchStateService {

  static final SearchStateService _instance = SearchStateService._internal();

  factory SearchStateService() {
    return _instance;
  }

  SearchStateService._internal();

  final TextEditingController searchController = TextEditingController();


  void clearSearchTextOnNavigation() {
    searchController.clear();
    print("Search text cleared due to navigation."); 
  }

}
