import 'package:flutter/material.dart';

abstract class BaseStateProvider with ChangeNotifier {
  Map<String, dynamic> _state = {};
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  Map<String, dynamic> get state => Map.unmodifiable(_state);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // State management
  @protected
  T? getState<T>(String key) => _state[key] as T?;

  @protected
  void setState(String key, dynamic value) {
    _state[key] = value;
    notifyListeners();
  }

  @protected
  void setMultipleStates(Map<String, dynamic> updates) {
    _state.addAll(updates);
    notifyListeners();
  }

  @protected
  void clearState() {
    _state.clear();
    notifyListeners();
  }

  @protected
  void removeState(String key) {
    _state.remove(key);
    notifyListeners();
  }

  // Loading state
  @protected
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Error handling
  @protected
  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  @protected
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // State persistence helpers
  Map<String, dynamic> exportState() {
    return {
      'state': Map<String, dynamic>.from(_state),
      'isLoading': _isLoading,
      'errorMessage': _errorMessage,
    };
  }

  void importState(Map<String, dynamic> importedState) {
    if (importedState.containsKey('state')) {
      _state = Map<String, dynamic>.from(importedState['state']);
    }
    _isLoading = importedState['isLoading'] ?? false;
    _errorMessage = importedState['errorMessage'];
    notifyListeners();
  }

  // Reset all state
  void resetState() {
    _state.clear();
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  // State validation
  bool hasState(String key) => _state.containsKey(key);
  bool hasValue(String key) => _state[key] != null;
  bool isEmpty(String key) => _state[key]?.isEmpty ?? true;
  bool isNotEmpty(String key) => _state[key]?.isNotEmpty ?? false;

  // State type checking
  bool isString(String key) => _state[key] is String;
  bool isNum(String key) => _state[key] is num;
  bool isBool(String key) => _state[key] is bool;
  bool isList(String key) => _state[key] is List;
  bool isMap(String key) => _state[key] is Map;

  // State manipulation helpers
  void updateList<T>(String key, List<T> Function(List<T>) update) {
    if (_state[key] is List<T>) {
      final list = List<T>.from(_state[key] as List);
      _state[key] = update(list);
      notifyListeners();
    }
  }

  void updateMap<K, V>(String key, Map<K, V> Function(Map<K, V>) update) {
    if (_state[key] is Map<K, V>) {
      final map = Map<K, V>.from(_state[key] as Map);
      _state[key] = update(map);
      notifyListeners();
    }
  }

  // Clean up resources
  @override
  void dispose() {
    _state.clear();
    super.dispose();
  }
}
