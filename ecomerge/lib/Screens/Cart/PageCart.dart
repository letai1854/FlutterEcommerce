import 'package:e_commerce_app/widgets/NavbarMobile/NavarFixTablet.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarMobile.dart';
import 'package:e_commerce_app/widgets/Cart/BodyCart.dart';
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';
import 'package:flutter/material.dart';

class PageCart extends StatefulWidget {
  const PageCart({super.key});

  @override
  State<PageCart> createState() => _PageCartState();
}

class _PageCartState extends State<PageCart> {
  // Core cart data
  List<Map<String, dynamic>> cartItems = [
    {
      'id': 1,
      'name': 'Điều Khiển Từ Xa Thay Thế Chuyên Dụng Cho Samsung',
      'image': 'https://i.imgur.com/s10B7s2.png',
      'originalPrice': 456000,
      'price': 42000,
      'quantity': 1,
      'isSelected': false,
    },
    {
      'id': 2,
      'name': 'Điều Khiển Từ Xa Thay Thế Chuyên Dụng Cho Samsung',
      'image': 'https://i.imgur.com/s10B7s2.png',
      'originalPrice': 456000,
      'price': 42000,
      'quantity': 1,
      'isSelected': false,
    },
    {
      'id': 3,
      'name': 'Điều Khiển Từ Xa Thay Thế Chuyên Dụng Cho Samsung',
      'image': 'https://i.imgur.com/s10B7s2.png',
      'originalPrice': 456000,
      'price': 42000,
      'quantity': 1,
      'isSelected': false,
    },
    {
      'id': 4,
      'name': 'Điều Khiển Từ Xa Thay Thế Chuyên Dụng Cho Samsung',
      'image': 'https://i.imgur.com/s10B7s2.png',
      'originalPrice': 456000,
      'price': 42000,
      'quantity': 1,
      'isSelected': false,
    },
    {
      'id': 5,
      'name': 'Điều Khiển Từ Xa Thay Thế Chuyên Dụng Cho Samsung',
      'image': 'https://i.imgur.com/s10B7s2.png',
      'originalPrice': 456000,
      'price': 42000,
      'quantity': 1,
      'isSelected': false,
    },
    {
      'id': 6,
      'name': 'Điều Khiển Từ Xa Thay Thế Chuyên Dụng Cho Samsung',
      'image': 'https://i.imgur.com/s10B7s2.png',
      'originalPrice': 456000,
      'price': 42000,
      'quantity': 1,
      'isSelected': false,
    },
    {
      'id': 7,
      'name': 'Điều Khiển Từ Xa Thay Thế Chuyên Dụng Cho Samsung',
      'image': 'https://i.imgur.com/s10B7s2.png',
      'originalPrice': 456000,
      'price': 42000,
      'quantity': 1,
      'isSelected': false,
    },
  ];
  
  // Constants
  final double taxRate = 0.05; // Thuế 5%
  final double shippingFee = 20000; // Phí vận chuyển 20k
  
  // Controllers and keys
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _paymentInfoKey = GlobalKey();
  late ValueNotifier<bool> _isPaymentInfoBottomVisible;

  @override
  void initState() {
    super.initState();
    _isPaymentInfoBottomVisible = ValueNotifier<bool>(cartItems.length >= 4);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _isPaymentInfoBottomVisible.dispose();
    super.dispose();
  }

  // Scroll handler
  void _onScroll() {
    if (_paymentInfoKey.currentContext != null) {
      final RenderBox paymentInfoRenderBox =
          _paymentInfoKey.currentContext!.findRenderObject() as RenderBox;
      final position = paymentInfoRenderBox.localToGlobal(Offset.zero);
      double paymentInfoOffset = position.dy;
      double screenHeight = MediaQuery.of(context).size.height;

      final isVisible = paymentInfoOffset > screenHeight;
      if (_isPaymentInfoBottomVisible.value != isVisible) {
        _isPaymentInfoBottomVisible.value = isVisible;
      }
    }
  }

  // Cart item handlers
  void toggleSelectItem(int itemId) {
    setState(() {
      for (var item in cartItems) {
        if (item['id'] == itemId) {
          item['isSelected'] = !item['isSelected'];
        }
      }
    });
  }

  void increaseQuantity(int itemId) {
    setState(() {
      for (var item in cartItems) {
        if (item['id'] == itemId) {
          item['quantity']++;
        }
      }
    });
  }

  void decreaseQuantity(int itemId) {
    setState(() {
      for (var item in cartItems) {
        if (item['id'] == itemId && item['quantity'] > 1) {
          item['quantity']--;
        }
      }
    });
  }

  void removeItem(int itemId) {
    setState(() {
      cartItems.removeWhere((item) => item['id'] == itemId);
    });
  }

  void toggleSelectAll(bool value) {
    setState(() {
      for (var item in cartItems) {
        item['isSelected'] = value;
      }
    });
  }

  void unselectAllItems() {
    setState(() {
      for (var item in cartItems) {
        item['isSelected'] = false;
      }
    });
  }

  // Calculation methods
  double calculateSubtotal() {
    double subtotal = 0;
    for (var item in cartItems) {
      if (item['isSelected']) {
        subtotal += item['price'] * item['quantity'];
      }
    }
    return subtotal;
  }

  double calculateTax() {
    return calculateSubtotal() * taxRate;
  }

  double calculateTotal() {
    return calculateSubtotal() + calculateTax() + shippingFee;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        Widget appBar;
        Widget body = BodyCart(
          cartItems: cartItems,
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

        if (screenWidth < 768) {
          // Mobile layout
          return NavbarFixmobile(
            body: body,
          );
        } else if (screenWidth < 1100) {
          // Tablet layout
          return NavbarFixTablet(
            body: body,
          );
        } else {
          // Desktop layout
          appBar = PreferredSize(
            preferredSize: Size.fromHeight(130),
            child: Navbarhomedesktop(),
          );
          return Scaffold(
            appBar: appBar as PreferredSize,
            body: body,
          );
        }
      },
    );
  }
}
