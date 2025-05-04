import 'package:flutter/material.dart';

class ProductStateProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _loadedProducts = [];
  int _currentIndex = 0;
  bool _isLoading = false;

  List<Map<String, dynamic>> get loadedProducts => _loadedProducts;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;

  Future<void> loadMoreData(
      List<Map<String, dynamic>> sourceData, int itemsPerPage) async {
    if (_currentIndex >= sourceData.length) return;
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    int nextIndex = _currentIndex + itemsPerPage;
    List<Map<String, dynamic>> newProducts = sourceData.sublist(
      _currentIndex,
      nextIndex > sourceData.length ? sourceData.length : nextIndex,
    );

    _loadedProducts.addAll(newProducts);
    _currentIndex = nextIndex;
    _isLoading = false;
    notifyListeners();
  }

  void reset() {
    _loadedProducts = [];
    _currentIndex = 0;
    _isLoading = false;
    notifyListeners();
  }
}
