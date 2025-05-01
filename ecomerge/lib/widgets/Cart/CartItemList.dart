import 'package:flutter/material.dart';

class CartItemList extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final Function(int) toggleSelectItem;
  final Function(int) increaseQuantity;
  final Function(int) decreaseQuantity;
  final Function(int) removeItem;

  const CartItemList({
    Key? key,
    required this.cartItems,
    required this.toggleSelectItem,
    required this.increaseQuantity,
    required this.decreaseQuantity,
    required this.removeItem,
  }) : super(key: key);

  @override
  State<CartItemList> createState() => _CartItemListState();
}

class _CartItemListState extends State<CartItemList> {
  @override
  Widget build(BuildContext context) {
    // Get screen width to determine layout
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Tăng ngưỡng để bao gồm cả tablet (từ 800 lên 1000)
    // Khi màn hình dưới 1000px, sẽ sử dụng layout mobile
    final isSmallOrMediumScreen = screenWidth < 1200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Empty cart message
        if (widget.cartItems.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Giỏ hàng của bạn đang trống',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to product page
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text('Tiếp tục mua sắm', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),

        // Column headers - only show on desktop view
        if (widget.cartItems.isNotEmpty && !isSmallOrMediumScreen)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              children: [
                SizedBox(width: 48), // Space for checkbox
                Expanded(
                  flex: 3,
                  child: Text(
                    'Sản phẩm',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.start,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Đơn giá',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Số lượng',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Thành tiền',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Thao tác',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

        // Cart items - responsive layout
        if (isSmallOrMediumScreen)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.cartItems.length,
            itemBuilder: (context, index) => _buildMobileItemCard(widget.cartItems[index]),
          )
        else
          // For desktop - horizontal scrollable container to prevent overflow
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: screenWidth < 1200 ? 1200 : screenWidth - 40, // Tăng chiều rộng tối thiểu
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.cartItems.length,
                itemBuilder: (context, index) => _buildDesktopItemCard(widget.cartItems[index]),
              ),
            ),
          ),
      ],
    );
  }

  // Desktop layout item card
  Widget _buildDesktopItemCard(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Card(
        color: Colors.grey[100],
        child: Container(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Checkbox(
                value: item['isSelected'],
                onChanged: (bool? value) {
                  widget.toggleSelectItem(item['id']);
                },
              ),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
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
                          // Additional product info

                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '₫${item['originalPrice']}',
                      style: TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '₫${item['price']}',
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove), 
                      color: Colors.red,
                      onPressed: () {
                        widget.decreaseQuantity(item['id']);
                      },
                    ),
                    Text(item['quantity'].toString()),
                    IconButton(
                      icon: const Icon(Icons.add),
                      color: Colors.green,
                      onPressed: () {
                        widget.increaseQuantity(item['id']);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '₫${(item['price'] * item['quantity']).toString()}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () {
                      widget.removeItem(item['id']);
                    },
                    child: const Text('Xóa'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Mobile layout item card - vertical layout for small screens
  Widget _buildMobileItemCard(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Card(
        color: Colors.grey[100],
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product header with checkbox, image and name
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: item['isSelected'],
                    onChanged: (bool? value) {
                      widget.toggleSelectItem(item['id']);
                    },
                  ),
                  Image.network(
                    item['image'],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'],
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ],
              ),
              
              Divider(height: 24),
              
              // Product details in vertical layout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Đơn giá:', style: TextStyle(fontWeight: FontWeight.w500)),
                      Row(
                        children: [
                          Text(
                            '₫${item['originalPrice']}',
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '₫${item['price']}',
                            style: TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Thành tiền:', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        '₫${(item['price'] * item['quantity']).toString()}',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Quantity controls and delete button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('Số lượng:', style: TextStyle(fontWeight: FontWeight.w500)),
                      SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        color: Colors.red,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          padding: EdgeInsets.zero,
                          minimumSize: Size(32, 32),
                        ),
                        onPressed: () {
                          widget.decreaseQuantity(item['id']);
                        },
                      ),
                      SizedBox(width: 4),
                      Text(
                        item['quantity'].toString(),
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.add),
                        color: Colors.green,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          padding: EdgeInsets.zero,
                          minimumSize: Size(32, 32),
                        ),
                        onPressed: () {
                          widget.increaseQuantity(item['id']);
                        },
                      ),
                    ],
                  ),
                  TextButton.icon(
                    icon: Icon(Icons.delete_outline, color: Colors.white),
                    label: Text('Xóa'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () {
                      widget.removeItem(item['id']);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
