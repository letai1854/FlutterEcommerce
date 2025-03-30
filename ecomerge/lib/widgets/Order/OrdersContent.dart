// Orders Content widget
import 'package:e_commerce_app/widgets/Order/OrderItem.dart';
import 'package:e_commerce_app/widgets/Order/OrderStatusTab.dart';
import 'package:flutter/material.dart';

class OrdersContent extends StatefulWidget {
  const OrdersContent({Key? key}) : super(key: key);

  @override
  State<OrdersContent> createState() => _OrdersContentState();
}

class _OrdersContentState extends State<OrdersContent> {
  int _selectedOrderTab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Đơn hàng của tôi",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.history),
              label: const Text("Lịch sử đơn hàng"),
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Order status tabs
        Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              OrderStatusTab(
                title: "Đang chờ xử lý",
                isSelected: _selectedOrderTab == 0,
                onTap: () {
                  setState(() {
                    _selectedOrderTab = 0;
                  });
                },
              ),
              OrderStatusTab(
                title: "Đã xác nhận",
                isSelected: _selectedOrderTab == 1,
                onTap: () {
                  setState(() {
                    _selectedOrderTab = 1;
                  });
                },
              ),
              OrderStatusTab(
                title: "Đang giao hàng",
                isSelected: _selectedOrderTab == 2,
                onTap: () {
                  setState(() {
                    _selectedOrderTab = 2;
                  });
                },
              ),
              OrderStatusTab(
                title: "Đã giao hàng",
                isSelected: _selectedOrderTab == 3,
                onTap: () {
                  setState(() {
                    _selectedOrderTab = 3;
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Order list
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 2, // Example with 2 orders
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return OrderItem(
              orderId: "DH123456",
              date: "01/05/2023",
              items: [
                {
                  "name": "Laptop Asus XYZ",
                  "image": "https://via.placeholder.com/80",
                  "price": 15000000,
                  "quantity": 1,
                },
                if (index == 0)
                  {
                    "name": "Chuột không dây Logitech",
                    "image": "https://via.placeholder.com/80",
                    "price": 450000,
                    "quantity": 2,
                  },
              ],
              status: _selectedOrderTab == 0
                  ? "Đang chờ xử lý"
                  : (_selectedOrderTab == 1
                      ? "Đã xác nhận"
                      : (_selectedOrderTab == 2
                          ? "Đang giao hàng"
                          : "Đã giao hàng")),
              onViewHistory: () {},
            );
          },
        ),
      ],
    );
  }
}
