import 'dart:async';

import 'package:e_commerce_app/database/models/CartDTO.dart';
import 'package:e_commerce_app/database/services/cart_service.dart';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';


class CartStorage {
  // Singleton instance
  static final CartStorage _instance = CartStorage._internal();
  
  // Private constructor
  CartStorage._internal() {
    // Initialize image cache
    _initializeImageCache();
  }
  
  // Factory constructor to return the same instance
  factory CartStorage() {
    return _instance;
  }
  
  // List to store cached cart items
  List<CartItemDTO>? _cartItems;
  
  // Image cache map
  // final Map<String, Uint8List> _imgCache = {};
  
  // // Track ongoing image fetch requests to avoid duplicate fetches
  // final Map<String, Future<Uint8List?>> _pendingImageFetches = {};
  
  // Service instance
  final CartService _cartService = CartService();
    bool _isOnline = true;       // Track current connectivity status

  
  // Initialize image cache
  Future<void> _initializeImageCache() async {
    if (kIsWeb) return;
    
    try {
      // Load any persistent cache from storage here if needed
      await _loadImageCacheFromStorage();
    } catch (e) {
      print('Failed to initialize image cache: $e');
    }
  }
  
  // Load images from persistent storage (implement according to your needs)
  Future<void> _loadImageCacheFromStorage() async {
    // This method can be implemented to load previously cached images
    // from persistent storage when the app starts
  }
  
  // Check if the cache is available
  bool get hasCache => _cartItems != null;
  
  // Get the cached items
  List<CartItemDTO> get cartItems {
    return _cartItems ?? [];
  }
  
  
//   


// Giả sử _isOnline là một biến thành viên (member variable) của class chứa hàm này
// ví dụ: bool _isOnline = false;

Future<void> _checkConnectivity() async {
  final ConnectivityResult connectivityResult = await Connectivity().checkConnectivity();
  print("ConnectivityResult: $connectivityResult");

  if (connectivityResult == ConnectivityResult.none) {
    print("Không có kết nối mạng cục bộ (Wi-Fi/Mobile Data).");
    _isOnline = false;
    return;
  }
if(!kIsWeb){
  final InternetConnectionChecker customChecker = InternetConnectionChecker.createInstance(
    checkTimeout: const Duration(milliseconds: 1000),
  );

  print("Đang kiểm tra kết nối internet thực sự (timeout mỗi địa chỉ ~1 giây)...");
  bool hasInternetAccess = false;
  try {
    hasInternetAccess = await customChecker.hasConnection;
  } catch (e) {
    print("Lỗi khi kiểm tra InternetConnectionChecker: $e");
    hasInternetAccess = false;
  }

  if (hasInternetAccess) {
    print("Đã kết nối internet (InternetConnectionChecker).");
  } else {
    print("Mất kết nối internet (InternetConnectionChecker) hoặc kiểm tra timeout.");
  }
  _isOnline = hasInternetAccess;
}
else{
  _isOnline = true;
}
}
  // Load data from API or local storage
  Future<void> loadData() async {
    
    try {
       await _checkConnectivity();
      // First try to get data from local storage
      if(!kIsWeb){
      await _loadFromLocalStorage();
      }
      // If user is logged in, also try to get data from server
      if (UserInfo().isLoggedIn) {

        if(!_isOnline){
        try {
          final items = await _cartService.getCart();
          
          // Enhanced debugging output
          print('========= CART ITEMS FROM SERVER =========');
          print('Total items: ${items.length}');
          for (int i = 0; i < items.length; i++) {
            final item = items[i];
            print('---- Item ${i+1} ----');
            print('CartItemId: ${item.cartItemId}');
            print('Product Variant: ${item.productVariant?.name ?? 'No name'} (ID: ${item.productVariant?.id})');
            print('Product ID: ${item.productVariant?.productId}');
            print('Quantity: ${item.quantity}');
            print('Price: ${item.productVariant?.price}');
            print('Final Price: ${item.productVariant?.finalPrice}');
            print('Line Total: ${item.lineTotal}');
            print('Image URL: ${item.productVariant?.imageUrl}');
          }
          print('=========================================');
          
          // If successfully retrieved from server, update cache
          _cartItems = items;
          print('Cart data loaded from server: ${items.length} items');
          
          // Save to local storage
          await _saveToLocalStorage();
          
          // Preload images for the cart items
          _preloadImages();
        } catch (e) {
          print('Failed to load cart data from server: $e');
          // Keep using data from local storage
        }
        }
      }
    } catch (e) {
      print('Failed to load cart data: $e');
      if (_cartItems == null) {
        _cartItems = []; // Initialize with empty list if no cache exists
      }
    }
  }
  
  // Add item to cart
  Future<void> addItemToCart(CartProductVariantDTO productVariant, int quantity) async {
    // Let's see what name is coming in
    print('Adding to cart: ${productVariant.name}, ID: ${productVariant.id}');
    
    // Create a new cart item with a unique ID for non-logged in users
    final cartItem = CartItemDTO(
      cartItemId: UserInfo().isLoggedIn ? null : -DateTime.now().millisecondsSinceEpoch,
      productVariant: productVariant,
      quantity: quantity,
      lineTotal: (productVariant.finalPrice ?? productVariant.price ?? 0) * quantity,
      addedDate: DateTime.now(),
      updatedDate: DateTime.now(),
    );
    if(!UserInfo().isLoggedIn){
        if(cartItem.productVariant?.discountPercentage != null && cartItem.productVariant!.discountPercentage! > 0) {
          cartItem.productVariant?.finalPrice = cartItem.productVariant!.price! * (1 - cartItem.productVariant!.discountPercentage! / 100);
        } 
    }
    // Add to local cache
    addItem(cartItem);
    
    // Save to local storage
    await _saveToLocalStorage();
    
    // If user is logged in, also send to server
    if (UserInfo().isLoggedIn) {
      try {
        // Use the CartService to add to server
        final serverCartItem = await _cartService.addToCart(
          productVariant.id!,
          quantity
        );
        
        // Update the local item with server data (e.g., to get cartItemId)
        if (serverCartItem != null) {
          // Find the item we just added and update it
          final index = _cartItems!.indexWhere((item) => 
            item.productVariant?.id == productVariant.id);
            
          if (index >= 0) {
            _cartItems![index] = serverCartItem;
            await _saveToLocalStorage();
          }
        }
      } catch (e) {
        print('Failed to add item to server cart: $e');
        // Keep the item in local cache even if server call fails
      }
    }
  }
  
  // Load cart data from local storage
  Future<void> _loadFromLocalStorage() async {
    if (kIsWeb) {
      // Web storage handled by browser, not implemented here
      return;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString('cart_data');
      
      if (cartJson != null && cartJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(cartJson);
        _cartItems = decoded.map((item) => CartItemDTO.fromJson(item)).toList();
        print('Cart loaded from local storage: ${_cartItems!.length} items');
      }
    } catch (e) {
      print('Error loading cart from local storage: $e');
      _cartItems = [];
    }
  }
  
  // Save cart data to local storage
  Future<void> _saveToLocalStorage() async {
    if (kIsWeb) {
      // Web storage handled by browser, not implemented here
      return;
    }
    
    try {
      if (_cartItems != null) {
        final prefs = await SharedPreferences.getInstance();
        final cartJson = jsonEncode(_cartItems!.map((item) => item.toJson()).toList());
        await prefs.setString('cart_data', cartJson);
        print('Cart saved to local storage: ${_cartItems!.length} items');
      }
    } catch (e) {
      print('Error saving cart to local storage: $e');
    }
  }
  
  // Preload images for all cart items
  Future<void> _preloadImages() async {
    if (_cartItems == null || _cartItems!.isEmpty) return;
    
    for (var item in _cartItems!) {
      if (item.productVariant?.imageUrl != null) {
        getImage(item.productVariant!.imageUrl!);
      }
    }
  }
  
  // Improved sync cart with server when user logs in
  Future<void> syncCartWithServer() async {
    if (!UserInfo().isLoggedIn) return;
    
    try {
      // Load local cart first if not already loaded
      if (_cartItems == null) {
        if(!kIsWeb){
          await _loadFromLocalStorage();
        }
        if (_cartItems == null) {
          _cartItems = []; // Initialize if still null
        }
      }
      
      // If there are no local items and we're logged in, just load from server
      if (_cartItems!.isEmpty) {
        try {
          final items = await _cartService.getCart();
          _cartItems = items;
          await _saveToLocalStorage();
          return;
        } catch (e) {
          print('Failed to load cart from server: $e');
          return;
        }
      }
      
      // Get latest server cart
      List<CartItemDTO> serverItems = [];
      try {
        serverItems = await _cartService.getCart();
        print('Loaded ${serverItems.length} items from server cart');
      } catch (e) {
        print('Failed to load server cart: $e');
        // Continue with local cart only
        return;
      }
      
      // Make a copy of local items to work with
      final localItems = List<CartItemDTO>.from(_cartItems!);
      
      // Create a new merged list starting with server items
      final mergedItems = List<CartItemDTO>.from(serverItems);
      
      print('Starting cart merge: ${localItems.length} local items, ${serverItems.length} server items');
      
      // Process each local item
      for (var localItem in localItems) {
        // Skip items that already exist on server (positive IDs)
        if (localItem.cartItemId != null && localItem.cartItemId! > 0) {
          print('Skipping local item that came from server: ID=${localItem.cartItemId}');
          continue;
        }
        
        print('Processing local item: variant=${localItem.productVariant?.id}, quantity=${localItem.quantity}');
        
        // Check if this local item exists in server items by product variant ID
        final serverItemIndex = mergedItems.indexWhere(
          (item) => item.productVariant?.id == localItem.productVariant?.id
        );
        
        if (serverItemIndex >= 0) {
          // Item exists in both - merge quantities
          final serverItem = mergedItems[serverItemIndex];
          final newQuantity = (serverItem.quantity ?? 0) + (localItem.quantity ?? 0);
          
          // Preserve local name if it contains variant information (has a dash)
          if (localItem.productVariant?.name != null && 
              localItem.productVariant!.name!.contains('-') && 
              !serverItem.productVariant!.name!.contains('-')) {
            mergedItems[serverItemIndex].productVariant!.name = localItem.productVariant!.name;
            print('Preserved local name with variant info: ${localItem.productVariant!.name}');
          }
          
          print('Found matching server item: ID=${serverItem.cartItemId}, current qty=${serverItem.quantity}, new qty=$newQuantity');
          
          // Update the server item with combined quantity
          try {
            await _cartService.updateCartItem(serverItem.cartItemId!, newQuantity);
            
            // Update the merged list item
            mergedItems[serverItemIndex].quantity = newQuantity;
            mergedItems[serverItemIndex].updatedDate = DateTime.now();
            
            // Update line total
            final price = mergedItems[serverItemIndex].productVariant?.finalPrice ?? 
                        mergedItems[serverItemIndex].productVariant?.price ?? 0;
            mergedItems[serverItemIndex].lineTotal = price * newQuantity;
            
            print('Updated server item ${serverItem.cartItemId} with combined quantity: $newQuantity');
          } catch (e) {
            print('Failed to update server item: $e');
          }
        } else {
          // Item exists only locally - add to server
          if (localItem.productVariant?.id != null) {
            try {
              print('Adding local item to server: variant=${localItem.productVariant?.id}, qty=${localItem.quantity}');
              
              final newServerItem = await _cartService.addToCart(
                localItem.productVariant!.id!,
                localItem.quantity ?? 1
              );
              
              // Add the server response to merged list
              if (newServerItem != null) {
                mergedItems.add(newServerItem);
                print('Added local item to server: New ID=${newServerItem.cartItemId}, variant=${newServerItem.productVariant?.id}');
              }
            } catch (e) {
              print('Failed to add local item to server: $e');
            }
          }
        }
      }
      
      // Replace local cache with merged items
      _cartItems = mergedItems;
      print('Final merged cart has ${_cartItems!.length} items');
      
      // Save merged cart to local storage
      await _saveToLocalStorage();
      
      print('Cart successfully merged and synced with server: ${_cartItems!.length} items');
    } catch (e) {
      print('Error during cart sync after login: $e');
    }
  }
  
  // Clear local storage cart data
  Future<void> clearLocalCart() async {
    if (kIsWeb) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cart_data');
      print('Local cart data cleared');
    } catch (e) {
      print('Error clearing local cart data: $e');
    }
  }
  
  // Get image from cache or load from server with deduplication
  Future<Uint8List?> getImage(String imagePath) async {
    // Check if image path is empty
    if (imagePath.isEmpty) {
      return null;
    }
    
    // Check if image is in local cache
    // if (_imgCache.containsKey(imagePath)) {
    //   return _imgCache[imagePath];
    // }
    
    // // Check if a fetch is already in progress for this image
    // if (_pendingImageFetches.containsKey(imagePath)) {
    //   return _pendingImageFetches[imagePath];
    // }
    
    // If not, use CartService to fetch it (with deduplication)
    try {
      final fetchFuture = _cartService.getImageFromServer(imagePath);
      // _pendingImageFetches[imagePath] = fetchFuture;
      
      final imageData = await fetchFuture;
      
      // Cache the image if it was successfully fetched
      // if (imageData != null) {
      //   _imgCache[imagePath] = imageData;
      // }
      
      // // Remove from pending fetches
      // _pendingImageFetches.remove(imagePath);
      
      return imageData;
    } catch (e) {
      print('Error fetching image: $e');
      // _pendingImageFetches.remove(imagePath);
      return null;
    }
  }
  
  // Force reload an image from server
  Future<Uint8List?> reloadImage(String imagePath) async {
    // Clear any pending fetch for this image
    // _pendingImageFetches.remove(imagePath);
    
    final imageData = await _cartService.getImageFromServer(imagePath, forceReload: true);
    
    // if (imageData != null) {
    //   _imgCache[imagePath] = imageData;
    // }
    
    return imageData;
  }
  
  // Clear the image cache
  void clearImageCache() {
    // _imgCache.clear();
    // _pendingImageFetches.clear();
  }
  
  // Check if image is cached
  // bool isImageCached(String imagePath) {
  //   return _imgCache.containsKey(imagePath);
  // }
  
  // Set cart items (replace the entire cache)
  void setCartItems(List<CartItemDTO> items) {
    _cartItems = List.from(items);
    _saveToLocalStorage();
  }
  
  // Clear the cache
  void clearCache() {
    _cartItems = null;
    clearLocalCart();
  }
  
  // Add a new item to the cache
  void addItem(CartItemDTO item) {
    _cartItems ??= [];
    
    // Check if the item already exists in the cart
    final existingIndex = _cartItems!.indexWhere(
      (cartItem) => cartItem.productVariant?.id == item.productVariant?.id
    );
    
    if (existingIndex >= 0) {
      // Update existing item instead
      _cartItems![existingIndex].quantity = ((_cartItems![existingIndex].quantity ?? 0) + (item.quantity ?? 0));
      _cartItems![existingIndex].updatedDate = DateTime.now();
      _cartItems![existingIndex].productVariant?.discountPercentage = item.productVariant?.discountPercentage;
      // ALWAYS preserve the formatted name with variant info from the new item
      if (item.productVariant?.name != null && item.productVariant!.name!.contains('-')) {
        _cartItems![existingIndex].productVariant!.name = item.productVariant!.name;
        print('Preserved formatted name when updating: ${item.productVariant!.name}');
      }
      
      // Get base price (fix duplicate fallback)
      double price = _cartItems![existingIndex].productVariant?.price ?? 0;
      double finalPrice = price;
      
      // Apply discount if present
      if(item.productVariant?.discountPercentage != null && item.productVariant!.discountPercentage! > 0) {
        finalPrice = price * (1 - item.productVariant!.discountPercentage! / 100);
        _cartItems![existingIndex].productVariant?.finalPrice = finalPrice;
      }
      
      // Use finalPrice for line total calculation to ensure discounts are applied
      _cartItems![existingIndex].lineTotal = finalPrice * (_cartItems![existingIndex].quantity ?? 1);
    } else {
      // Add new item - make sure the name is properly displayed
      print('Adding new cart item with name: ${item.productVariant?.name}');
      _cartItems!.add(item);
    }
    for(var item in _cartItems!) {
      print('Item added to cart: ${item.productVariant?.id}, Quantity: ${item.quantity}');
    }
    // Preload the image if available
    if (item.productVariant?.imageUrl != null) {
      getImage(item.productVariant!.imageUrl!);
    }
  }
  
  // Update an item in the cache and on server if logged in
  Future<bool> updateItem(int cartItemId, int quantity) async {
    if (_cartItems == null) return false;
    
    final index = _cartItems!.indexWhere(
      (item) => item.cartItemId == cartItemId
    );
    
    if (index < 0) return false;
    
    _cartItems![index].quantity = quantity;
    _cartItems![index].updatedDate = DateTime.now();
    
    // Recalculate line total
    double price = _cartItems![index].productVariant?.finalPrice ?? 
                   _cartItems![index].productVariant?.price ?? 0;
    _cartItems![index].lineTotal = price * quantity;
    
    // Save to local storage
    await _saveToLocalStorage();
    
    // If logged in, update on server
    if (UserInfo().isLoggedIn) {
      try {
        await _cartService.updateCartItem(cartItemId, quantity);
      } catch (e) {
        print('Failed to update cart item on server: $e');
        // Keep local changes even if server update fails
      }
    }
    
    return true;
  }
  
  // Remove an item from the cache
  Future<bool> removeItem(int cartItemId) async {
    if (_cartItems == null) return false;
    
    final initialLength = _cartItems!.length;
    _cartItems!.removeWhere((item) => item.cartItemId == cartItemId);
    
    // Save to local storage if changed
    if (_cartItems!.length < initialLength) {
      await _saveToLocalStorage();
      
      // If logged in, remove from server
      if (UserInfo().isLoggedIn) {
        try {
          await _cartService.removeFromCart(cartItemId);
        } catch (e) {
          print('Failed to remove cart item from server: $e');
          // Keep local changes even if server removal fails
        }
      }
      
      return true;
    }
    
    return false;
  }
  
  // Comprehensive method to clear all cart data (memory, local storage, and images)
  Future<void> clearAllCart() async {
    try {
      // Clear in-memory cart items
      _cartItems = [];
      
      // Clear local storage cart data
      await clearLocalCart();
      
      // Clear image cache
      clearImageCache();
      
      print('All cart data cleared successfully');
    } catch (e) {
      print('Error clearing all cart data: $e');
    }
  }
}
