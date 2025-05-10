import 'package:e_commerce_app/Screens/Payment/PagePayment.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForTablet.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForMobile.dart';
import 'package:e_commerce_app/widgets/Cart/BodyCart.dart';
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/database/Storage/CartStorage.dart';
import 'package:e_commerce_app/database/models/CartDTO.dart';
import 'package:e_commerce_app/database/models/cart_item_model.dart';

class PageCart extends StatefulWidget {
  const PageCart({super.key});

  @override
  State<PageCart> createState() => _PageCartState();
}

class _PageCartState extends State<PageCart> {
  // Cart storage instance
  final CartStorage _cartStorage = CartStorage();
  
  // Selected items tracking
  Map<int?, bool> selectedItems = {};
  
  // List to track selected cart items for payment
  List<CartItemModel> _selectedCartItemsList = [];
  
  // Constants
  final double taxRate = 0.05; // Thuế 5%
  final double shippingFee = 20000; // Phí vận chuyển 20k
  
  // Loading state
  bool _isLoading = true;
  
  // Controllers and keys
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  final GlobalKey _paymentInfoKey = GlobalKey();
  late ValueNotifier<bool> _isPaymentInfoBottomVisible;

  @override
  void initState() {
    super.initState();
    _isPaymentInfoBottomVisible = ValueNotifier<bool>(false);
    _scrollController.addListener(_onScroll);
    
    // Load cart data
     _loadCartData();
    
    // Check visibility after first layout
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateStickyPaymentVisibility());
  }

  Future<void> _loadCartData() async {
    setState(() => _isLoading = true);
    
    try {
      // await _cartStorage.loadData();
      
      // Initialize selection state for all items (all unselected by default)
      selectedItems.clear();
      _selectedCartItemsList.clear(); // Clear selected items list
      for (var item in _cartStorage.cartItems) {
        if (item.cartItemId != null) {
          selectedItems[item.cartItemId] = false;
        }
      }
      
    } catch (e) {
      print('Error loading cart data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _isPaymentInfoBottomVisible.dispose();
    super.dispose();
  }

  void _updateStickyPaymentVisibility() {
    if (!mounted) return;

    // Condition 1: Must have enough items
    bool hasEnoughItems = _cartStorage.cartItems.length >= 5;

    // Condition 2: Payment info must be off-screen
    bool isScrollablePaymentInfoOffScreen = false;
    if (_paymentInfoKey.currentContext != null) {
      final RenderBox? paymentInfoRenderBox =
          _paymentInfoKey.currentContext!.findRenderObject() as RenderBox?;
      if (paymentInfoRenderBox != null) {
         final position = paymentInfoRenderBox.localToGlobal(Offset.zero);
         final bottomEdgePosition = position.dy + paymentInfoRenderBox.size.height;
         final screenHeight = MediaQuery.of(context).size.height;
         isScrollablePaymentInfoOffScreen = bottomEdgePosition > screenHeight;
      }
    }

    // Combine conditions
    final bool shouldBeVisible = hasEnoughItems && isScrollablePaymentInfoOffScreen;

    // Update notifier if value changed
    if (_isPaymentInfoBottomVisible.value != shouldBeVisible) {
      _isPaymentInfoBottomVisible.value = shouldBeVisible;
    }
  }

  // Scroll handler
  void _onScroll() {
    _updateStickyPaymentVisibility();
  }

  // Cart item handlers
  void toggleSelectItem(int itemId) {
    final index = _cartStorage.cartItems.indexWhere((item) => item.cartItemId == itemId);
    if (index >= 0) {
      var item = _cartStorage.cartItems[index];
      
      // Check if the item is out of stock
      final int stockQuantity = item.productVariant?.stockQuantity ?? 0;
      if (stockQuantity <= 0) {
        // Don't allow selection of out-of-stock items
        return;
      }
      
      setState(() {
        // Toggle the selection state
        bool newValue = !(selectedItems[itemId] ?? false);
        selectedItems[itemId] = newValue;
        
        // Update the selected items list
        if (newValue) {
          // Use the productVariant.id as variantId to ensure consistent identification
          final variantId = item.productVariant?.id ?? 0;
          final model = CartItemModel(
            productId: variantId, // Use the variant ID consistently
            productName: item.productVariant?.name ?? 'Unknown product',
            imageUrl: item.productVariant?.imageUrl ?? '',
            quantity: item.quantity ?? 0,
            price: item.productVariant?.finalPrice ?? item.productVariant?.price ?? 0,
            variantId: variantId, // Use the variant ID consistently
            discountPercentage: item.productVariant?.discountPercentage,
          );
          
          // Check if it's already in the list using variantId for consistency
          final existingIndex = _selectedCartItemsList.indexWhere(
            (selectedItem) => selectedItem.variantId == variantId
          );
          
          if (existingIndex >= 0) {
            // Update the existing item instead of adding a new one
            _selectedCartItemsList[existingIndex] = model;
            print('Updated existing item in selection: ${item.productVariant?.name}, quantity: ${item.quantity}');
          } else {
            // Add as new item
            _selectedCartItemsList.add(model);
            print('Added item to selection: ${item.productVariant?.name}, quantity: ${item.quantity}');
          }
        } else {
          // Remove from selected list
          _selectedCartItemsList.removeWhere((selected) => 
              selected.variantId == (item.productVariant?.id ?? 0));
          print('Removed item from selection: ${item.productVariant?.name}');
        }
        
        print('Item $itemId toggled to: ${selectedItems[itemId]}, quantity: ${item.quantity}');
        print('Selected items count: ${_selectedCartItemsList.length}');
      });
      _updateStickyPaymentVisibility();
    }
  }

  void increaseQuantity(int itemId) async {
    final index = _cartStorage.cartItems.indexWhere((item) => item.cartItemId == itemId);
    if (index >= 0) {
      final item = _cartStorage.cartItems[index];
      final newQuantity = (item.quantity ?? 0) + 1;
      
      // Update through CartStorage
      final success = await _cartStorage.updateItem(itemId, newQuantity);
      
      if (success) {
        setState(() {
          // Always update the CartStorage item's quantity locally to ensure it's reflected in the UI
          _cartStorage.cartItems[index].quantity = newQuantity;
          
          // Find and update the corresponding item in _selectedCartItemsList if it exists
          final selectedIndex = _selectedCartItemsList.indexWhere(
            (selectedItem) => selectedItem.variantId == (item.productVariant?.id ?? 0)
          );
          
          if (selectedIndex >= 0) {
            // Create a new CartItemModel instance with the updated quantity
            final updatedItem = CartItemModel(
              productId: _selectedCartItemsList[selectedIndex].productId,
              productName: _selectedCartItemsList[selectedIndex].productName,
              imageUrl: _selectedCartItemsList[selectedIndex].imageUrl,
              quantity: newQuantity,
              price: _selectedCartItemsList[selectedIndex].price,
              variantId: _selectedCartItemsList[selectedIndex].variantId,
              discountPercentage: _selectedCartItemsList[selectedIndex].discountPercentage
            );
            
            // Replace the item in the list
            _selectedCartItemsList[selectedIndex] = updatedItem;
            
            print('Updated quantity in selected items list: ${item.productVariant?.name}, new quantity: $newQuantity');
          }
        });
        _updateStickyPaymentVisibility();
      }
    }
  }

  void decreaseQuantity(int itemId) async {
    final index = _cartStorage.cartItems.indexWhere((item) => item.cartItemId == itemId);
    if (index >= 0) {
      final item = _cartStorage.cartItems[index];
      if ((item.quantity ?? 0) > 1) {
        final newQuantity = (item.quantity ?? 0) - 1;
        
        // Update through CartStorage
        final success = await _cartStorage.updateItem(itemId, newQuantity);
        
        if (success) {
          setState(() {
            // Always update the CartStorage item's quantity locally
            _cartStorage.cartItems[index].quantity = newQuantity;
            
            // Find and update the corresponding item in _selectedCartItemsList if it exists
            final selectedIndex = _selectedCartItemsList.indexWhere(
              (selectedItem) => selectedItem.variantId == (item.productVariant?.id ?? 0)
            );
            
            if (selectedIndex >= 0) {
              // Create a new CartItemModel instance with the updated quantity
              final updatedItem = CartItemModel(
                productId: _selectedCartItemsList[selectedIndex].productId,
                productName: _selectedCartItemsList[selectedIndex].productName,
                imageUrl: _selectedCartItemsList[selectedIndex].imageUrl,
                quantity: newQuantity,
                price: _selectedCartItemsList[selectedIndex].price,
                variantId: _selectedCartItemsList[selectedIndex].variantId,
                discountPercentage: _selectedCartItemsList[selectedIndex].discountPercentage,
              );
              
              // Replace the item in the list
              _selectedCartItemsList[selectedIndex] = updatedItem;
              
              print('Updated quantity in selected items list: ${item.productVariant?.name}, new quantity: $newQuantity');
            }
          });
          _updateStickyPaymentVisibility();
        }
      }
    }
  }

  void removeItem(int itemId) async {
    // Get item reference before removal
    final itemIndex = _cartStorage.cartItems.indexWhere((item) => item.cartItemId == itemId);
    final itemToRemove = itemIndex >= 0 ? _cartStorage.cartItems[itemIndex] : null;
    
    // Remove through CartStorage
    final success = await _cartStorage.removeItem(itemId);
    
    if (success && itemToRemove != null) {
      setState(() {
        // Remove from selected items map
        selectedItems.remove(itemId);
        
        // Remove from selected cart items list if present
        _selectedCartItemsList.removeWhere((selectedItem) => 
          selectedItem.variantId == (itemToRemove.productVariant?.id ?? 0)
        );
        
        print('Removed item from selected items list: ${itemToRemove.productVariant?.name}');
        print('Remaining selected items: ${_selectedCartItemsList.length}');
      });
      _updateStickyPaymentVisibility();
    }
  }

  void toggleSelectAll(bool value) {
    setState(() {
      _selectedCartItemsList.clear(); // Clear the current selection list
      
      for (var item in _cartStorage.cartItems) {
        final int stockQuantity = item.productVariant?.stockQuantity ?? 0;
        final bool hasStock = stockQuantity > 0;
        
        if (item.cartItemId != null) {
          // Only set checkboxes for in-stock items
          selectedItems[item.cartItemId] = hasStock ? value : false;
          
          // If selecting all and the item has stock, add it to the selected list
          if (value && hasStock) {
            final model = CartItemModel(
              productId: item.productVariant?.id ?? 0,
              productName: item.productVariant?.name ?? 'Unknown product',
              imageUrl: item.productVariant?.imageUrl ?? '',
              quantity: item.quantity ?? 0,
              price: item.productVariant?.finalPrice ?? item.productVariant?.price ?? 0,
              variantId: item.productVariant?.id ?? 0,
              discountPercentage: item.productVariant?.discountPercentage
            );
            _selectedCartItemsList.add(model);
          }
        }
      }
      
      if (value) {  
        print('Selected all in-stock items: ${_selectedCartItemsList.length}');
      } else {  
        print('Cleared all selections');
      }
    });
    _updateStickyPaymentVisibility();
  }

  void unselectAllItems() {
    setState(() {
      for (var itemId in selectedItems.keys) {
        selectedItems[itemId] = false;
      }
      _selectedCartItemsList.clear(); // Clear the selected items list
      print('Unselected all items');
    });
    _updateStickyPaymentVisibility();
  }

  double calculateSubtotal() {
    double subtotal = 0;
    for (var item in _cartStorage.cartItems) {
      if (item.cartItemId != null && selectedItems[item.cartItemId] == true) {
        double price = item.productVariant?.finalPrice ?? 
                       item.productVariant?.price ?? 0;
        subtotal += price * (item.quantity ?? 1);
      }
    }
    return subtotal;
  }

  double calculateTax() {
    return calculateSubtotal() * taxRate;
  }

  double calculateTotal() {
    final subtotal = calculateSubtotal();
    if (subtotal == 0) return 0;
    return subtotal + calculateTax() + shippingFee;
  }

  // Method to navigate to payment with selected items
  void proceedToPayment() {
    if (_selectedCartItemsList.isEmpty) {
      // If no items are selected, collect all cart items
      if (_cartStorage.cartItems.isNotEmpty) {
        for (var item in _cartStorage.cartItems) {
          if (item.cartItemId != null) {
            final model = CartItemModel(
              productId: item.productVariant?.id ?? 0,
              productName: item.productVariant?.name ?? 'Unknown product',
              imageUrl: item.productVariant?.imageUrl ?? '',
              quantity: item.quantity ?? 0, 
              price: item.productVariant?.finalPrice ?? item.productVariant?.price ?? 0,
              variantId: item.productVariant?.id ?? 0,
              discountPercentage: item.productVariant?.discountPercentage
            );
            _selectedCartItemsList.add(model);
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giỏ hàng của bạn đang trống')),
        );
        return;
      }
    }
    
    // Debug log before navigation
    print('Navigating to payment with ${_selectedCartItemsList.length} items:');
    for (var item in _selectedCartItemsList) {
      print(' - ${item.productName}, Qty: ${item.quantity}, Price: ${item.price}');
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PagePayment(
          cartItems: _selectedCartItemsList,
          sourceCartPage: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        Widget content;
        
        if (_isLoading) {
          content = const Center(child: CircularProgressIndicator());
        } else if (_cartStorage.cartItems.isEmpty) {
          content = Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Giỏ hàng của bạn đang trống',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Thêm sản phẩm vào giỏ để tiến hành mua hàng',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                  child: const Text('Tiếp tục mua sắm'),
                ),
              ],
            ),
          );
        } else {
          content = BodyCart(
            cartItems: _cartStorage.cartItems,
            selectedItems: selectedItems,
            taxRate: taxRate,
            shippingFee: shippingFee,
            scrollController: _scrollController,
            isPaymentInfoBottomVisible: _isPaymentInfoBottomVisible,
            paymentInfoKey: _paymentInfoKey,
            toggleSelectItem: toggleSelectItem,
            increaseQuantity: increaseQuantity,
            decreaseQuantity: decreaseQuantity,
            removeItem: removeItem,
            toggleSelectAll: toggleSelectAll,
            unselectAllItems: unselectAllItems,
            calculateSubtotal: calculateSubtotal,
            calculateTax: calculateTax,
            calculateTotal: calculateTotal,
            onProceedToPayment: proceedToPayment,  // Pass the function to BodyCart
          );
        }

        if (screenWidth < 768) {
          // Mobile layout
          return NavbarFormobile(
            body: content,
          );
        } else if (screenWidth < 1100) {
          // Tablet layout
          return NavbarForTablet(
            body: content,
          );
        } else {
          // Desktop layout
          final appBar = PreferredSize(
            preferredSize: const Size.fromHeight(130),
            child: Navbarhomedesktop(),
          );
          return Scaffold(
            appBar: appBar,
            body: content,
          );
        }
      },
    );
  }
}
