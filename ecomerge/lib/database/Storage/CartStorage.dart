import 'package:e_commerce_app/database/models/CartDTO.dart';
import 'package:e_commerce_app/database/services/cart_service.dart';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CartStorage {
  // Singleton instance
  static final CartStorage _instance = CartStorage._internal();
  
  // Private constructor
  CartStorage._internal();
  
  // Factory constructor to return the same instance
  factory CartStorage() {
    return _instance;
  }
  
  // List to store cached cart items
  List<CartItemDTO>? _cartItems;
  
  // Image cache map
  final Map<String, Uint8List> _imgCache = {};
  
  // Service instance
  final CartService _cartService = CartService();
  
  // Check if the cache is available
  bool get hasCache => _cartItems != null;
  
  // Get the cached items
  List<CartItemDTO> get cartItems {
    return _cartItems ?? [];
  }
  
  // Load data from API or local storage
  Future<void> loadData() async {
    try {
      // First try to get data from local storage
      await _loadFromLocalStorage();
      
      // If user is logged in, also try to get data from server
      if (UserInfo().isLoggedIn) {
        try {
          final items = await _cartService.getCart();
          
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
    } catch (e) {
      print('Failed to load cart data: $e');
      if (_cartItems == null) {
        _cartItems = []; // Initialize with empty list if no cache exists
      }
    }
  }
  
  // Add item to cart
  Future<void> addItemToCart(CartProductVariantDTO productVariant, int quantity) async {
    // Create a new cart item
    final cartItem = CartItemDTO(
      productVariant: productVariant,
      quantity: quantity,
      lineTotal: (productVariant.finalPrice ?? productVariant.price ?? 0) * quantity,
      addedDate: DateTime.now(),
      updatedDate: DateTime.now(),
    );
    
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
        await _loadFromLocalStorage();
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
      
      // Process each local item
      for (var localItem in localItems) {
        // Skip already processed server items (those with IDs)
        if (localItem.cartItemId != null) continue;
        
        // Check if this local item exists in server items by product variant ID
        final serverItemIndex = mergedItems.indexWhere(
          (item) => item.productVariant?.id == localItem.productVariant?.id
        );
        
        if (serverItemIndex >= 0) {
          // Item exists in both - merge quantities
          final serverItem = mergedItems[serverItemIndex];
          final newQuantity = (serverItem.quantity ?? 0) + (localItem.quantity ?? 0);
          
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
              final newServerItem = await _cartService.addToCart(
                localItem.productVariant!.id!,
                localItem.quantity ?? 1
              );
              
              // Add the server response to merged list
              if (newServerItem != null) {
                mergedItems.add(newServerItem);
                print('Added local item to server: ${newServerItem.cartItemId}');
              }
            } catch (e) {
              print('Failed to add local item to server: $e');
            }
          }
        }
      }
      
      // Replace local cache with merged items
      _cartItems = mergedItems;
      
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
  
  // Get image from cache or load from server
  Future<Uint8List?> getImage(String imagePath) async {
    // Check if image is in local cache
    if (_imgCache.containsKey(imagePath)) {
      return _imgCache[imagePath];
    }
    
    // If not, use CartService to fetch it
    final imageData = await _cartService.getImageFromServer(imagePath);
    
    // Cache the image if it was successfully fetched
    if (imageData != null) {
      _imgCache[imagePath] = imageData;
    }
    
    return imageData;
  }
  
  // Force reload an image from server
  Future<Uint8List?> reloadImage(String imagePath) async {
    final imageData = await _cartService.getImageFromServer(imagePath, forceReload: true);
    
    if (imageData != null) {
      _imgCache[imagePath] = imageData;
    }
    
    return imageData;
  }
  
  // Clear the image cache
  void clearImageCache() {
    _imgCache.clear();
  }
  
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
      // Update line total
      double price = _cartItems![existingIndex].productVariant?.finalPrice ?? 
                      _cartItems![existingIndex].productVariant?.price ?? 0;
      _cartItems![existingIndex].lineTotal = price * (_cartItems![existingIndex].quantity ?? 1);
    } else {
      // Add new item
      _cartItems!.add(item);
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
}
