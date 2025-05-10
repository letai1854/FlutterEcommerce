import 'package:e_commerce_app/widgets/Order/OrderDetailPage.dart';
import 'package:e_commerce_app/widgets/Order/OrderItem.dart';
import 'package:e_commerce_app/widgets/Order/OrderStatusHistoryPage.dart';
import 'package:flutter/material.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({Key? key}) : super(key: key);

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  // For pagination
  int _currentPage = 1;
  final int _itemsPerPage = 5;
  final int _totalItems = 15; // Example total, would come from API

  List<Map<String, dynamic>> _getDummyOrders() {
    // This would be replaced with actual data from an API
    return List.generate(
      _totalItems,
      (index) => {
        "orderId": "DH${123450 + index}",
        "date": "${(index % 30) + 1}/05/2023",
        "status": _getRandomStatus(),
        "items": [
          {
            "name": "Laptop Asus XYZ",
            "image": "https://via.placeholder.com/80",
            "price": 15000000,
            "quantity": 1,
            "discountPercentage": 10.0, // Example discount
          },
          if (index % 2 == 0)
            {
              "name": "Chuột không dây Logitech",
              "image": "https://via.placeholder.com/80",
              "price": 450000,
              "quantity": 2,
              "discountPercentage": 0.0, // Example discount
            },
        ],
        "subtotal": (index % 2 == 0) ? 15900000.0 : 15000000.0,
        "shippingFee": 50000.0,
        "tax": ((index % 2 == 0) ? 15900000.0 : 15000000.0) * 0.05, // 5% tax
        "totalAmount": ((index % 2 == 0) ? 15900000.0 : 15000000.0) +
            50000.0 +
            (((index % 2 == 0) ? 15900000.0 : 15000000.0) * 0.05),
        "couponDiscount": (index % 3 == 0) ? 100000.0 : 0.0,
        "pointsDiscount": (index % 4 == 0) ? 20000.0 : 0.0,
        "pointsEarned": (index % 2 == 0) ? 159.0 : 150.0,
      },
    );
  }

  String _getRandomStatus() {
    final statuses = [
      "Chờ xử lý",
      "Đã xác nhận",
      "Đang giao",
      "Đã giao",
      "Đã hủy",
      "Trả hàng"
    ];
    return statuses[DateTime.now().microsecond % statuses.length];
  }

  List<Map<String, dynamic>> _getPaginatedOrders() {
    final allOrders = _getDummyOrders();
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex >= allOrders.length) {
      return [];
    }

    return allOrders.sublist(
      startIndex,
      endIndex > allOrders.length ? allOrders.length : endIndex,
    );
  }

  int get _pageCount => (_totalItems / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    final paginatedOrders = _getPaginatedOrders();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.grey[100];
    final headingColor = isDarkMode ? Colors.white : Colors.red[800];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Lịch sử đơn hàng",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.red,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              backgroundColor!,
              Colors.white,
            ],
            stops: const [0.0, 0.4],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // History info text with decorative elements
              Container(
                margin: const EdgeInsets.only(bottom: 20, top: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.red[700]!, width: 5),
                  ),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.history, color: headingColor, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      "Thông tin tất cả đơn hàng của bạn",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: headingColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Orders list with enhanced styling
              Expanded(
                child: paginatedOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Không có đơn hàng nào",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: paginatedOrders.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final order = paginatedOrders[index];
                          return GestureDetector(
                            onTap: () {
                              // Navigate to the OrderDetailPage when tapped
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrderDetailPage(
                                    orderId: order["orderId"],
                                    orderDate: order["date"],
                                    items: order["items"],
                                    status: order["status"],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: OrderItem(
                                orderId: order["orderId"],
                                date: order["date"],
                                items: order["items"],
                                status: order["status"],
                                onViewHistory: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          OrderStatusHistoryPage(
                                        orderId: order["orderId"],
                                        currentStatus: order["status"],
                                      ),
                                    ),
                                  );
                                },
                                subtotal: order["subtotal"] as double,
                                shippingFee: order["shippingFee"] as double,
                                tax: order["tax"] as double,
                                totalAmount: order["totalAmount"] as double,
                                couponDiscount:
                                    order["couponDiscount"] as double?,
                                pointsDiscount:
                                    order["pointsDiscount"] as double?,
                                pointsEarned: order["pointsEarned"] as double?,
                                isSmallScreen:
                                    MediaQuery.of(context).size.width <
                                        600, // Example, adjust as needed
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Enhanced pagination controls
              if (paginatedOrders.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 18),
                        color: _currentPage > 1 ? Colors.red : Colors.grey[400],
                        onPressed: _currentPage > 1
                            ? () {
                                setState(() {
                                  _currentPage--;
                                });
                              }
                            : null,
                      ),
                      for (int i = 1; i <= _pageCount; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _currentPage == i
                                  ? Colors.red
                                  : Colors.grey[200],
                              foregroundColor: _currentPage == i
                                  ? Colors.white
                                  : Colors.black87,
                              elevation: _currentPage == i ? 4 : 0,
                              minimumSize: const Size(45, 45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _currentPage = i;
                              });
                            },
                            child: Text(
                              i.toString(),
                              style: TextStyle(
                                fontWeight: _currentPage == i
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 18),
                        color: _currentPage < _pageCount
                            ? Colors.red
                            : Colors.grey[400],
                        onPressed: _currentPage < _pageCount
                            ? () {
                                setState(() {
                                  _currentPage++;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
