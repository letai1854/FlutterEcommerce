import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForTablet.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForMobile.dart';
import 'package:e_commerce_app/widgets/Cart/BodyCart.dart';
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/database/Storage/CartStorage.dart';
import 'package:e_commerce_app/database/models/CartDTO.dart';

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
      await _cartStorage.loadData();
      
      // Initialize selection state for all items (all unselected by default)
      selectedItems.clear();
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
    bool hasEnoughItems = _cartStorage.cartItems.length >= 4;

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
    setState(() {
      if (selectedItems.containsKey(itemId)) {
        selectedItems[itemId] = !(selectedItems[itemId] ?? false);
      }
    });
    _updateStickyPaymentVisibility();
  }

  void increaseQuantity(int itemId) async {
    final index = _cartStorage.cartItems.indexWhere((item) => item.cartItemId == itemId);
    if (index >= 0) {
      final item = _cartStorage.cartItems[index];
      final newQuantity = (item.quantity ?? 0) + 1;
      
      // Update through CartStorage
      final success = await _cartStorage.updateItem(itemId, newQuantity);
      
      if (success) {
        setState(() {}); // Refresh UI
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
          setState(() {}); // Refresh UI
          _updateStickyPaymentVisibility();
        }
      }
    }
  }

  void removeItem(int itemId) async {
    // Remove through CartStorage
    final success = await _cartStorage.removeItem(itemId);
    
    if (success) {
      setState(() {
        // Also remove from selected items
        selectedItems.remove(itemId);
      });
      _updateStickyPaymentVisibility();
    }
  }

  void toggleSelectAll(bool value) {
    setState(() {
      for (var itemId in selectedItems.keys) {
        selectedItems[itemId] = value;
      }
    });
    _updateStickyPaymentVisibility();
  }

  void unselectAllItems() {
    setState(() {
      for (var itemId in selectedItems.keys) {
        selectedItems[itemId] = false;
      }
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
