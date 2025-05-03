import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForTablet.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForMobile.dart';
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
    _isPaymentInfoBottomVisible = ValueNotifier<bool>(false);
    _scrollController.addListener(_onScroll);
    // --- Kiểm tra visibility lần đầu sau khi layout ---
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateStickyPaymentVisibility());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _isPaymentInfoBottomVisible.dispose();
    super.dispose();
  }
void _updateStickyPaymentVisibility() {
    if (!mounted) return; // Đảm bảo widget còn tồn tại

    // Điều kiện 1: Số lượng sản phẩm phải đủ lớn
    bool hasEnoughItems = cartItems.length >= 4;

    // Điều kiện 2: Thanh PaymentInfo cuộn phải đi ra khỏi màn hình
    bool isScrollablePaymentInfoOffScreen = false;
    if (_paymentInfoKey.currentContext != null) {
      final RenderBox? paymentInfoRenderBox =
          _paymentInfoKey.currentContext!.findRenderObject() as RenderBox?;
      if (paymentInfoRenderBox != null) {
         final position = paymentInfoRenderBox.localToGlobal(Offset.zero);
         final bottomEdgePosition = position.dy + paymentInfoRenderBox.size.height;
         final screenHeight = MediaQuery.of(context).size.height;
         // Coi là off-screen nếu cạnh dưới của nó vượt quá chiều cao màn hình
         isScrollablePaymentInfoOffScreen = bottomEdgePosition > screenHeight;
      }
    }

    // Kết hợp 2 điều kiện
    final bool shouldBeVisible = hasEnoughItems && isScrollablePaymentInfoOffScreen;

    // Chỉ cập nhật notifier nếu giá trị thay đổi
    if (_isPaymentInfoBottomVisible.value != shouldBeVisible) {
      _isPaymentInfoBottomVisible.value = shouldBeVisible;
    }
  }

  // Scroll handler
  void _onScroll() {
    // if (_paymentInfoKey.currentContext != null) {
    //   final RenderBox paymentInfoRenderBox =
    //       _paymentInfoKey.currentContext!.findRenderObject() as RenderBox;
    //   final position = paymentInfoRenderBox.localToGlobal(Offset.zero);
    //   double paymentInfoOffset = position.dy;
    //   double screenHeight = MediaQuery.of(context).size.height;

    //   final isVisible = paymentInfoOffset > screenHeight;
    //   if (_isPaymentInfoBottomVisible.value != isVisible) {
    //     _isPaymentInfoBottomVisible.value = isVisible;
    //   }
    // }
    _updateStickyPaymentVisibility();
  }

  // Cart item handlers
void toggleSelectItem(int itemId) {
    setState(() {
      final itemIndex = cartItems.indexWhere((item) => item['id'] == itemId);
      if (itemIndex != -1) {
        cartItems[itemIndex]['isSelected'] = !cartItems[itemIndex]['isSelected'];
      }
    });
    _updateStickyPaymentVisibility(); // Cập nhật sau khi thay đổi trạng thái chọn
  }

  void increaseQuantity(int itemId) {
    setState(() {
      final itemIndex = cartItems.indexWhere((item) => item['id'] == itemId);
      if (itemIndex != -1) {
        cartItems[itemIndex]['quantity']++;
      }
    });
     _updateStickyPaymentVisibility(); // Cập nhật sau khi thay đổi số lượng (ít ảnh hưởng hơn)
  }

 void decreaseQuantity(int itemId) {
    setState(() {
      final itemIndex = cartItems.indexWhere((item) => item['id'] == itemId);
      if (itemIndex != -1 && cartItems[itemIndex]['quantity'] > 1) {
        cartItems[itemIndex]['quantity']--;
      }
    });
    _updateStickyPaymentVisibility(); // Cập nhật sau khi thay đổi số lượng
  }
void removeItem(int itemId) {
    setState(() {
      cartItems.removeWhere((item) => item['id'] == itemId);
    });
    _updateStickyPaymentVisibility(); // --- Cập nhật sau khi xóa item ---
  }

  void toggleSelectAll(bool value) {
    setState(() {
      for (var item in cartItems) {
        item['isSelected'] = value;
      }
    });
    _updateStickyPaymentVisibility(); // Cập nhật sau khi thay đổi trạng thái chọn
  }

  void unselectAllItems() {
    setState(() {
      for (var item in cartItems) {
        item['isSelected'] = false;
      }
    });
     _updateStickyPaymentVisibility(); // Cập nhật sau khi thay đổi trạng thái chọn
  }
   double calculateSubtotal() {
    double subtotal = 0;
    for (var item in cartItems) {
      if (item['isSelected'] == true) { // Kiểm tra rõ ràng true
        subtotal += (item['price'] ?? 0) * (item['quantity'] ?? 1);
      }
    }
    return subtotal;
  }

  double calculateTax() {
    return calculateSubtotal() * taxRate;
  }

  double calculateTotal() {
    final subtotal = calculateSubtotal();
    if (subtotal == 0) return 0; // Nếu không chọn gì thì tổng là 0
    return subtotal + calculateTax() + shippingFee;
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
          return NavbarFormobile(
            body: body,
          );
        } else if (screenWidth < 1100) {
          // Tablet layout
          return NavbarForTablet(
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
