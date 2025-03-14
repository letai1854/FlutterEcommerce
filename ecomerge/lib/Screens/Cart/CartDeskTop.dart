import 'package:e_commerce_app/widgets/footer.dart';
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Cartdesktop extends StatefulWidget {
  const Cartdesktop({super.key});

  @override
  State<Cartdesktop> createState() => _CartdesktopState();
}

class _CartdesktopState extends State<Cartdesktop> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(130),
        child: Navbarhomedesktop(),
      ),
      body: BodyCartDesktop(),
    );
  }

}




class BodyCartDesktop extends StatefulWidget {
  const BodyCartDesktop({Key? key}) : super(key: key);

  @override
  State<BodyCartDesktop> createState() => _BodyCartDesktopState();
}

class _BodyCartDesktopState extends State<BodyCartDesktop> {
  // Dữ liệu giả lập cho sản phẩm trong giỏ hàng
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
    // {
    //   'id': 4,
    //   'name': 'Điều Khiển Từ Xa Thay Thế Chuyên Dụng Cho Samsung',
    //   'image': 'https://i.imgur.com/s10B7s2.png',
    //   'originalPrice': 456000,
    //   'price': 42000,
    //   'quantity': 1,
    //   'isSelected': false,
    // },
    // {
    //   'id': 5,
    //   'name': 'Điều Khiển Từ Xa Thay Thế Chuyên Dụng Cho Samsung',
    //   'image': 'https://i.imgur.com/s10B7s2.png',
    //   'originalPrice': 456000,
    //   'price': 42000,
    //   'quantity': 1,
    //   'isSelected': false,
    // },
    // {
    //   'id': 6,
    //   'name': 'Điều Khiển Từ Xa Thay Thế Chuyên Dụng Cho Samsung',
    //   'image': 'https://i.imgur.com/s10B7s2.png',
    //   'originalPrice': 456000,
    //   'price': 42000,
    //   'quantity': 1,
    //   'isSelected': false,
    // },
    // {
    //   'id': 7,
    //   'name': 'Điều Khiển Từ Xa Thay Thế Chuyên Dụng Cho Samsung',
    //   'image': 'https://i.imgur.com/s10B7s2.png',
    //   'originalPrice': 456000,
    //   'price': 42000,
    //   'quantity': 1,
    //   'isSelected': false,
    // },
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
    setState(() {
      for (var item in cartItems) {
        if (item['id'] == itemId) {
          item['isSelected'] = !item['isSelected'];
        }
      }
    });
  }

  // Hàm tăng số lượng sản phẩm
  void increaseQuantity(int itemId) {
    setState(() {
      for (var item in cartItems) {
        if (item['id'] == itemId) {
          item['quantity']++;
        }
      }
    });
  }

  // Hàm giảm số lượng sản phẩm
  void decreaseQuantity(int itemId) {
    setState(() {
      for (var item in cartItems) {
        if (item['id'] == itemId && item['quantity'] > 1) {
          item['quantity']--;
        }
      }
    });
  }

  // Hàm xóa sản phẩm khỏi giỏ hàng
  void removeItem(int itemId) {
    setState(() {
      cartItems.removeWhere((item) => item['id'] == itemId);
    });
  }

  // Hàm chọn/bỏ chọn tất cả sản phẩm
  void toggleSelectAll(bool value) {
    setState(() {
      for (var item in cartItems) {
        if (item['isSelected']) {
          item['isSelected'] = value;
        }
      }
    });
  }

  // Hàm bỏ chọn các sản phẩm đã chọn
  void unselectAllItems() {
    setState(() {
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
                      // Danh sách sản phẩm
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          return Card(
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: item['isSelected'],
                                    onChanged: (bool? value) {
                                      toggleSelectItem(item['id']);
                                    },
                                  ),
                                  Image.network(
                                    item['image'],
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'],
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        // Thêm thông tin sản phẩm (ví dụ: màu sắc, kích thước)
                                        const Text('Màu: Đen'),
                                        const Text('Kích thước: L'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    children: [
                                      Text('₫${item['originalPrice']}'),
                                      Text('₫${item['price'].toString()}'),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: () {
                                          decreaseQuantity(item['id']);
                                        },
                                      ),
                                      Text(item['quantity'].toString()),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () {
                                          increaseQuantity(item['id']);
                                        },
                                      ),
                                    ],
                                  ),
                                  Text(
                                      '₫${(item['price'] * item['quantity']).toString()}'),
                                  TextButton(
                                    onPressed: () {
                                      removeItem(item['id']);
                                    },
                                    child: const Text('Xóa'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

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

// Thanh Payment Info (thanh chính và mép dưới)
class PaymentInfo extends StatelessWidget {
  const PaymentInfo({
    Key? key,
    required this.cartItems,
    required this.calculateTax,
    required this.calculateTotal,
    required this.calculateSubtotal,
    required this.shippingFee,
    required this.taxRate,
    required this.toggleSelectAll,
    required this.unselectAllItems,
  }) : super(key: key);

  final List<Map<String, dynamic>> cartItems;
  final double Function() calculateTax;
  final double Function() calculateTotal;
  final double Function() calculateSubtotal;
  final double shippingFee;
  final double taxRate;
  final Function(bool) toggleSelectAll;
  final VoidCallback unselectAllItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -3), // Shadow phía trên
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Phần chọn tất cả, bỏ chọn
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Checkbox(
                value: cartItems.isNotEmpty &&
                    cartItems.every((item) => item['isSelected']),
                onChanged: cartItems.isNotEmpty
                    ? (bool? value) {
                  toggleSelectAll(value ?? false);
                }
                    : null,
              ),
              Text('Chọn Tất Cả (${cartItems.length})'),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () {
                  unselectAllItems();
                },
                child: const Text('Bỏ chọn sản phẩm'),
              ),
            ],
          ),
          // Thông tin thanh toán và nút mua hàng (căn phải)
          Container(
            padding: const EdgeInsets.only(right: 50),
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Thuế: ${taxRate * 100}%: ₫${calculateTax().toStringAsFixed(0)}',
                  textAlign: TextAlign.end,
                ),
                Text(
                  'Phí vận chuyển: ₫${shippingFee.toString()}',
                  textAlign: TextAlign.end,
                ),
                Text(
                  'Tổng thanh toán: ₫${calculateTotal().toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.end,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Xử lý khi nhấn nút "Mua Hàng"
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Mua Hàng'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
