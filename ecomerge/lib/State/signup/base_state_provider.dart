import 'package:flutter/material.dart';

abstract class BaseStateProvider extends ChangeNotifier {
  Map<String, dynamic> _state = {};
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  Map<String, dynamic> get state => Map.unmodifiable(_state);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // State management
  void setState(String key, dynamic value) {
    _state[key] = value;
    notifyListeners();
  }

  T? getState<T>(String key) => _state[key] as T?;

  void setMultipleStates(Map<String, dynamic> updates) {
    _state.addAll(updates);
    notifyListeners();
  }

  void clearState() {
    _state.clear();
    notifyListeners();
  }

  // Loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Error handling
  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // State persistence
  Map<String, dynamic> exportState() {
    return {
      'state': Map<String, dynamic>.from(_state),
      'isLoading': _isLoading,
      'errorMessage': _errorMessage,
    };
  }

  void importState(Map<String, dynamic> importedState) {
    _state = Map<String, dynamic>.from(importedState['state'] ?? {});
    _isLoading = importedState['isLoading'] ?? false;
    _errorMessage = importedState['errorMessage'];
    notifyListeners();
  }
}
