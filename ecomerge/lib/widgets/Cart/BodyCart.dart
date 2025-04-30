import 'package:e_commerce_app/widgets/Cart/CartItemList.dart';
import 'package:e_commerce_app/widgets/Cart/PaymentInfo.dart';
import 'package:e_commerce_app/widgets/footer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
class BodyCart extends StatefulWidget {
  const BodyCart({Key? key}) : super(key: key);

  @override
  State<BodyCart> createState() => _BodyCartState();
}

class _BodyCartState extends State<BodyCart> {
  List<Map<String, dynamic>> cartItems = [
    // Thêm hoặc xóa sản phẩm ở đây để thử nghiệm các trường hợp
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

  double taxRate = 0.05; // Thuế 5%
  double shippingFee = 20000; // Phí vận chuyển
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _paymentInfoKey = GlobalKey();
  late ValueNotifier<bool> _isPaymentInfoBottomVisible; // Khai báo late

  @override
  void initState() {
    super.initState();
    // Kiểm tra số lượng sản phẩm và đặt giá trị ban đầu cho _isPaymentInfoBottomVisible
    _isPaymentInfoBottomVisible = ValueNotifier<bool>(cartItems.length >= 4);
    _scrollController.addListener(_onScroll);

    // Gọi _onScroll sau khi frame đầu tiên được vẽ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onScroll();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _isPaymentInfoBottomVisible.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_paymentInfoKey.currentContext != null) {
      final RenderBox paymentInfoRenderBox =
          _paymentInfoKey.currentContext!.findRenderObject() as RenderBox;
      final position = paymentInfoRenderBox.localToGlobal(Offset.zero);
      double paymentInfoOffset = position.dy;
      double screenHeight = MediaQuery.of(context).size.height;

      // Ẩn thanh mép dưới khi thanh chính trên màn hình, hiện lại khi thanh chính khuất màn hình
      final isVisible = paymentInfoOffset > screenHeight;
      if (_isPaymentInfoBottomVisible.value != isVisible) {
        _isPaymentInfoBottomVisible.value = isVisible;
      }
    }
  }

  // Hàm tính tổng giá trị các sản phẩm đã chọn
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

  // Hàm cập nhật trạng thái chọn sản phẩm
  void toggleSelectItem(int itemId) {
    setState(() { // SỬA ĐỔI: Thêm setState để cập nhật UI
      for (var item in cartItems) {
        if (item['id'] == itemId) {
          item['isSelected'] = !item['isSelected'];
        }
      }
    });
  }

  // Hàm tăng số lượng sản phẩm
  void increaseQuantity(int itemId) {
    setState(() { // SỬA ĐỔI: Thêm setState để cập nhật UI
      for (var item in cartItems) {
        if (item['id'] == itemId) {
          item['quantity']++;
        }
      }
    });
  }

  // Hàm giảm số lượng sản phẩm
  void decreaseQuantity(int itemId) {
    setState(() { // SỬA ĐỔI: Thêm setState để cập nhật UI
      for (var item in cartItems) {
        if (item['id'] == itemId && item['quantity'] > 1) {
          item['quantity']--;
        }
      }
    });
  }

  // Hàm xóa sản phẩm khỏi giỏ hàng
  void removeItem(int itemId) {
    setState(() { // SỬA ĐỔI: Thêm setState để cập nhật UI
      cartItems.removeWhere((item) => item['id'] == itemId);
    });
  }

  // Hàm chọn/bỏ chọn tất cả sản phẩm
  void toggleSelectAll(bool value) {
    setState(() { // SỬA ĐỔI: Thêm setState để cập nhật UI
      for (var item in cartItems) {
        item['isSelected'] = value;
      }
    });
  }

  // Hàm bỏ chọn các sản phẩm đã chọn
  void unselectAllItems() {
    setState(() { // SỬA ĐỔI: Thêm setState để cập nhật UI
      for (var item in cartItems) {
        item['isSelected'] = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Nội dung cuộn (danh sách sản phẩm, thanh "chính", Footer)
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề các cột
                      CartItemList(cartItems: cartItems, toggleSelectItem: toggleSelectItem, increaseQuantity: increaseQuantity, decreaseQuantity: decreaseQuantity, removeItem: removeItem),
                      // Thanh "chính" (PaymentInfo)
                      PaymentInfo(
                        key: _paymentInfoKey,
                        cartItems: cartItems,
                        calculateTax: calculateTax,
                        calculateTotal: calculateTotal,
                        calculateSubtotal: calculateSubtotal,
                        shippingFee: shippingFee,
                        taxRate: taxRate,
                        toggleSelectAll: toggleSelectAll,
                        unselectAllItems: unselectAllItems,
                      ),

                      // Add spacer that will expand to fill available space
                      SizedBox(
                        height: cartItems.length <= 1
                            ? MediaQuery.of(context).size.height - 500
                            : 0,
                      ),

                      // Footer
                      if (kIsWeb) const Footer(),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 2. Thanh "mép dưới" (PaymentInfo)
          ValueListenableBuilder<bool>(
            valueListenable: _isPaymentInfoBottomVisible,
            builder: (context, isVisible, child) {
              return Positioned(
                left: 0,
                right: 0,
                bottom: 0, // Dính vào bottom edge
                child: Visibility(
                  visible: isVisible,
                  child: PaymentInfo(
                    cartItems: cartItems,
                    calculateTax: calculateTax,
                    calculateTotal: calculateTotal,
                    calculateSubtotal: calculateSubtotal,
                    shippingFee: shippingFee,
                    taxRate: taxRate,
                    toggleSelectAll: toggleSelectAll,
                    unselectAllItems: unselectAllItems,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
