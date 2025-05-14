import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

/// A singleton utility class for monitoring network connectivity
/// and providing a centralized way to access connectivity status.
class NetworkUtil {
  // Singleton instance
  static final NetworkUtil _instance = NetworkUtil._internal();
  factory NetworkUtil() => _instance;
  
  // Private constructor
  NetworkUtil._internal();
  
  // Connection state
  bool _isConnected = true;
  bool get isConnected => _isConnected;
  
  // Initialization flag
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  // Stream controllers for notifying listeners
  final StreamController<bool> _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionStateController.stream;
  
  // Dependencies
  final Connectivity _connectivity = Connectivity();
  
  /// Initialize the network utility and start monitoring connectivity.
  /// Call this method once, typically in main.dart.
  void init() {
    if (_isInitialized) return;
    
    if (kDebugMode) {
      print('NetworkUtil: Initializing network monitoring');
    }
    
    // Initial connectivity check
    checkConnectivity().then((isConnected) {
      _isConnected = isConnected;
      _connectionStateController.add(_isConnected);
      
      if (kDebugMode) {
        print('NetworkUtil: Initial connectivity status: $_isConnected');
      }
    });
    
    // Start listening to connectivity changes
    _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
    
    _isInitialized = true;
  }
  
  /// Handle connectivity change events
  void _handleConnectivityChange(ConnectivityResult result) {
    if (kDebugMode) {
      print('NetworkUtil: Connectivity changed: ${result.toString()}');
    }
    
    // If no network interface available, definitely offline
    if (result == ConnectivityResult.none) {
      _updateConnectionState(false);
      return;
    }
    
    // Otherwise, do deeper checking on non-web platforms
    if (!kIsWeb) {
      _checkActualConnectivity();
    } else {
      // For web, assume online if there's any network interface
      _updateConnectionState(true);
    }
  }
  
  /// Perform a deeper check to confirm actual internet connectivity
  Future<void> _checkActualConnectivity() async {
    try {
      // Use InternetConnectionChecker for more reliable checks on mobile/desktop
      final hasConnection = await InternetConnectionChecker().hasConnection;
      
      _updateConnectionState(hasConnection);
      
      if (kDebugMode) {
        print('NetworkUtil: Deep connectivity check: $hasConnection');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NetworkUtil: Error checking actual connectivity: $e');
      }
      // In case of error checking, assume same as last known state
    }
  }
  
  /// Update internal state and notify all listeners
  void _updateConnectionState(bool isConnected) {
    final wasConnected = _isConnected;
    _isConnected = isConnected;
    
    // Only notify if state actually changed
    if (wasConnected != _isConnected) {
      _connectionStateController.add(_isConnected);
      
      if (kDebugMode) {
        print('NetworkUtil: Connection state changed to: $_isConnected');
      }
    }
  }
  
  /// Check current connectivity status
  /// Returns true if connected, false otherwise
  Future<bool> checkConnectivity() async {
    if (kIsWeb) {
       final connectivityResult = await _connectivity.checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        _updateConnectionState(false);
        return false;
      }
      return true; // Always assume online for web applications
    }
    
    try {
      // First check if any network interface is active
      final connectivityResult = await _connectivity.checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        _updateConnectionState(false);
        return false;
      }
      
      // Then verify actual internet connectivity
      final hasInternet = await InternetConnectionChecker().hasConnection;
      _updateConnectionState(hasInternet);
      return hasInternet;
    } catch (e) {
      if (kDebugMode) {
        print('NetworkUtil: Error checking connectivity: $e');
      }
      return _isConnected; // Return last known state in case of error
    }
  }
  
  /// Dispose resources
  void dispose() {
    _connectionStateController.close();
    if (kDebugMode) {
      print('NetworkUtil: Resources disposed');
    }
  }
}
