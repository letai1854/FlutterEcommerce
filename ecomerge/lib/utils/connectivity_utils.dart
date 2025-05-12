// import 'dart:async';
// import 'dart:io';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;

// class ConnectivityUtils {
//   static final ConnectivityUtils _instance = ConnectivityUtils._internal();
  
//   factory ConnectivityUtils() {
//     return _instance;
//   }
  
//   ConnectivityUtils._internal();
  
//   final Connectivity _connectivity = Connectivity();
//   bool _isOnline = true;
//   bool _wasOffline = false;
  
//   // Stream controller to broadcast connectivity status changes
//   final StreamController<bool> _onlineStatusController = StreamController<bool>.broadcast();
  
//   // Get the stream of online status changes
//   Stream<bool> get onlineStatusStream => _onlineStatusController.stream;
  
//   // Current online status
//   bool get isOnline => _isOnline;
  
//   // Initialize connectivity monitoring
//   void initialize() {
//     // Check initial connectivity
//     _checkConnectivity();
    
//     // Listen for connectivity changes
//     _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
//       _checkActualConnectivity(result);
//     });
//   }
  
//   // Check current connectivity status including actual internet connection
//   Future<bool> _checkActualConnectivity(ConnectivityResult result) async {
//     // First check if device is connected to any network
//     bool isConnected = result != ConnectivityResult.none;
    
//     // If connected to network, verify actual internet connectivity
//     if (isConnected) {
//       isConnected = await _hasActualInternetConnectivity();
//     }
    
//     bool previousOnlineStatus = _isOnline;
//     _wasOffline = !_isOnline;
//     _isOnline = isConnected;
    
//     if (kDebugMode) {
//       print('ConnectivityUtils: Network status check - Connected to ${result.toString()}, Has internet: $_isOnline');
//     }
    
//     // Notify listeners only if status changed
//     if (previousOnlineStatus != _isOnline) {
//       _onlineStatusController.add(_isOnline);
      
//       if (kDebugMode) {
//         print('ConnectivityUtils: Status changed - Now ${_isOnline ? "ONLINE" : "OFFLINE"}');
//       }
//     }
    
//     return _isOnline;
//   }
  
//   // Check current connectivity status
//   Future<bool> _checkConnectivity() async {
//     try {
//       final result = await _connectivity.checkConnectivity();
//       return await _checkActualConnectivity(result);
//     } catch (e) {
//       if (kDebugMode) {
//         print('ConnectivityUtils: Error checking connectivity: $e');
//       }
//       _isOnline = false;
//       return false;
//     }
//   }
  
//   // Verify actual internet connectivity by making a DNS lookup request
//   Future<bool> _hasActualInternetConnectivity() async {
//     try {
//       // Try to resolve a reliable DNS server
//       if (kIsWeb) {
//         // For web, make a simple HTTP request
//         try {
//           final response = await http.get(Uri.parse('https://www.google.com')).timeout(
//             const Duration(seconds: 5),
//             onTimeout: () => http.Response('Error', 408),
//           );
//           return response.statusCode == 200;
//         } catch (e) {
//           return false;
//         }
//       } else {
//         // For non-web platforms, use a socket connection to DNS server
//         final result = await InternetAddress.lookup('google.com').timeout(
//           const Duration(seconds: 2),
//           onTimeout: () => throw TimeoutException('Lookup timeout'),
//         );
//         return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
//       }
//     } on SocketException catch (_) {
//       return false;
//     } on TimeoutException catch (_) {
//       return false;
//     } catch (e) {
//       if (kDebugMode) {
//         print('ConnectivityUtils: Error checking internet: $e');
//       }
//       return false;
//     }
//   }
  
//   // Public method to check current online status
//   Future<bool> checkOnline() async {
//     return await _checkConnectivity();
//   }
  
//   // Dispose resources
//   void dispose() {
//     _onlineStatusController.close();
//   }
// }
