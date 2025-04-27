import 'package:flutter/material.dart';

class OrderStatusHistoryPage extends StatefulWidget {
  final String orderId;
  final String currentStatus;
  final Map<String, dynamic>? shippingInfo;

  const OrderStatusHistoryPage({
    Key? key,
    required this.orderId,
    required this.currentStatus,
    this.shippingInfo,
  }) : super(key: key);

  @override
  State<OrderStatusHistoryPage> createState() => _OrderStatusHistoryPageState();
}

class _OrderStatusHistoryPageState extends State<OrderStatusHistoryPage> {
  bool _showAllHistory = false;
  late List<Map<String, dynamic>> _statusHistory;

  @override
  void initState() {
    super.initState();
    // Generate dummy status history with updated status names
    _statusHistory = [
      {
        "status": "Đã giao",
        "time": "12/05/2023 14:25",
        "description": "Đơn hàng đã được giao thành công"
      },
      {
        "status": "Đang giao",
        "time": "11/05/2023 08:15",
        "description": "Đơn hàng đang được giao đến bạn"
      },
      {
        "status": "Đã xác nhận",
        "time": "10/05/2023 17:30",
        "description": "Đơn hàng đã được xác nhận và đóng gói"
      },
      {
        "status": "Chờ xử lý",
        "time": "09/05/2023 22:45",
        "description": "Đơn hàng của bạn đang được xử lý"
      },
      {
        "status": "Đã đặt hàng",
        "time": "09/05/2023 22:40",
        "description": "Đơn hàng đã được đặt thành công"
      },
      {
        "status": "Thêm vào giỏ hàng",
        "time": "09/05/2023 21:30",
        "description": "Sản phẩm đã được thêm vào giỏ hàng"
      },
    ];
  }

  // Updated status color method to match new status names
  Color _getStatusColor(String status) {
    switch (status) {
      case "Đã giao":
        return Colors.green;
      case "Đang giao":
        return Colors.orange;
      case "Đã hủy":
        return Colors.red;
      case "Trả hàng":
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen width to determine layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 650;

    final int itemsToShow = _showAllHistory
        ? _statusHistory.length
        : (_statusHistory.length > 3 ? 3 : _statusHistory.length);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.grey[100];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "Chi tiết đơn hàng ${widget.orderId}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
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
              // Order ID and Status card - same for all screen sizes
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.grey.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.shopping_bag,
                                    color: Colors.red),
                                const SizedBox(width: 8),
                                Text(
                                  "Mã đơn hàng: ${widget.orderId}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(widget.currentStatus)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _getStatusColor(widget.currentStatus)
                                      .withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                widget.currentStatus,
                                style: TextStyle(
                                  color: _getStatusColor(widget.currentStatus),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Main content area with responsive layout
              Expanded(
                child: isSmallScreen
                    ? _buildVerticalLayout()
                    : _buildHorizontalLayout(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Vertical layout for small screens (stacked columns)
  Widget _buildVerticalLayout() {
    // Use a ListView instead of SingleChildScrollView for better handling of children
    return ListView(
      // Remove physics if you want to keep the parent scroll behavior
      physics: const ClampingScrollPhysics(),
      children: [
        // Shipping information section - full width, no Expanded
        _buildShippingInfoCard(),

        const SizedBox(height: 16),

        // Timeline section - with fixed height instead of Expanded
        Container(
          // Provide a fixed height for the timeline on mobile
          height: 400, // Adjust based on your needs
          child: _buildTimelineCardContent(),
        ),
      ],
    );
  }

  // Horizontal layout for larger screens (side-by-side columns)
  Widget _buildHorizontalLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column: Shipping information
        Expanded(
          flex: 2,
          child: _buildShippingInfoCard(),
        ),

        const SizedBox(width: 16),

        // Right column: Status timeline
        Expanded(
          flex: 3,
          child: _buildTimelineCard(),
        ),
      ],
    );
  }

  // Shipping information card - used in both layouts
  Widget _buildShippingInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize:
                MainAxisSize.min, // Important for scrolling in vertical layout
            children: [
              Row(
                children: [
                  Icon(Icons.local_shipping, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  const Text(
                    "Thông tin nhận hàng",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.indigo,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // User info with icons
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.person, color: Colors.blue[400], size: 18),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Người nhận:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text("Nguyễn Văn A"),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.phone, color: Colors.blue[400], size: 18),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Số điện thoại:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text("0987654321"),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, color: Colors.blue[400], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Địa chỉ:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "123 Đường Nguyễn Văn Linh, Phường Tân Phú, Quận 7, TP. Hồ Chí Minh",
                          style: TextStyle(
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Timeline card - used in horizontal layout with Expanded
  Widget _buildTimelineCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.red.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildTimelineCardContent(),
        ),
      ),
    );
  }

  // Extract timeline content to avoid duplication
  Widget _buildTimelineCardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timeline, color: Colors.red[700]),
            const SizedBox(width: 8),
            const Text(
              "Dòng thời gian đặt hàng",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const Divider(height: 24),

        // Timeline entries - take remaining space
        Expanded(
          child: ListView.builder(
            // Use proper physics for nested scrolling
            physics: const ClampingScrollPhysics(),
            itemCount: (_showAllHistory
                    ? _statusHistory.length
                    : (_statusHistory.length > 3 ? 3 : _statusHistory.length)) +
                (_statusHistory.length > 3 && !_showAllHistory ? 1 : 0),
            itemBuilder: (context, index) {
              if (!_showAllHistory &&
                  index ==
                      (_statusHistory.length > 3 ? 3 : _statusHistory.length) &&
                  _statusHistory.length > 3) {
                // "See more" button
                return Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showAllHistory = true;
                      });
                    },
                    icon: const Icon(Icons.expand_more),
                    label: const Text("Xem thêm lịch sử"),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      backgroundColor: Colors.red[50],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                );
              }

              final statusItem = _statusHistory[index];
              final isLast = index == _statusHistory.length - 1;

              return TimelineEntry(
                status: statusItem["status"],
                time: statusItem["time"],
                description: statusItem["description"],
                isLast: isLast,
                color: _getStatusColor(statusItem["status"]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class TimelineEntry extends StatelessWidget {
  final String status;
  final String time;
  final String description;
  final bool isLast;
  final Color color;

  const TimelineEntry({
    Key? key,
    required this.status,
    required this.time,
    required this.description,
    this.isLast = false,
    this.color = Colors.blue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline dot and line with enhanced styling
        SizedBox(
          width: 24,
          child: Column(
            children: [
              // Dot with shadow
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              // Line
              if (!isLast)
                Container(
                  width: 2,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [color, Colors.grey.shade300],
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Content with enhanced styling
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16.0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
