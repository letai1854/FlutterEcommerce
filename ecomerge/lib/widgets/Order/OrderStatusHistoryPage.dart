import 'package:e_commerce_app/database/models/order/OrderDTO.dart';
import 'package:e_commerce_app/database/services/order_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

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
  late List<OrderStatusHistoryDTO> _statusHistory;
  bool _isLoadingHistory = true;
  String? _historyErrorMsg;
  final OrderService _orderService = OrderService();

  @override
  void initState() {
    super.initState();
    _statusHistory = [];
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoadingHistory = true;
      _historyErrorMsg = null;
    });
    try {
      final history = await _orderService
          .getOrderStatusHistoryForCurrentUser(int.parse(widget.orderId));
      history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      setState(() {
        _statusHistory = history;
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingHistory = false;
        _historyErrorMsg = "Lỗi tải lịch sử: ${e.toString()}";
      });
    }
  }

  @override
  void dispose() {
    _orderService.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    String normalizedStatus = status.toLowerCase().replaceAll('_', ' ');

    if (normalizedStatus == "da giao" || normalizedStatus == "đã giao") {
      return Colors.green;
    } else if (normalizedStatus == "dang giao" ||
        normalizedStatus == "đang giao") {
      return Colors.orange;
    } else if (normalizedStatus == "da huy" || normalizedStatus == "đã hủy") {
      return Colors.red;
    } else if (normalizedStatus == "tra hang" ||
        normalizedStatus == "trả hàng") {
      return Colors.purple;
    } else if (normalizedStatus == "da xac nhan" ||
        normalizedStatus == "đã xác nhận") {
      return Colors.blueAccent;
    } else if (normalizedStatus == "cho xu ly" ||
        normalizedStatus == "chờ xử lý") {
      return Colors.blue;
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 650;

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

  Widget _buildVerticalLayout() {
    return ListView(
      physics: const ClampingScrollPhysics(),
      children: [
        _buildShippingInfoCard(),
        const SizedBox(height: 16),
        Container(
          height: 400,
          child: _isLoadingHistory
              ? Center(child: CircularProgressIndicator())
              : _historyErrorMsg != null
                  ? Center(
                      child: Text(_historyErrorMsg!,
                          style: TextStyle(color: Colors.red)))
                  : _statusHistory.isEmpty
                      ? Center(child: Text("Không có lịch sử trạng thái."))
                      : _buildTimelineCardContent(),
        ),
      ],
    );
  }

  Widget _buildHorizontalLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildShippingInfoCard(),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: _isLoadingHistory
              ? Center(child: CircularProgressIndicator())
              : _historyErrorMsg != null
                  ? Center(
                      child: Text(_historyErrorMsg!,
                          style: TextStyle(color: Colors.red)))
                  : _statusHistory.isEmpty
                      ? Center(child: Text("Không có lịch sử trạng thái."))
                      : _buildTimelineCard(),
        ),
      ],
    );
  }

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
            mainAxisSize: MainAxisSize.min,
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

  Widget _buildTimelineCardContent() {
    final int itemsToShow = _showAllHistory
        ? _statusHistory.length
        : (_statusHistory.length > 3 ? 3 : _statusHistory.length);

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
        Expanded(
          child: ListView.builder(
            physics: const ClampingScrollPhysics(),
            itemCount: itemsToShow +
                (_statusHistory.length > 3 &&
                        !_showAllHistory &&
                        itemsToShow < _statusHistory.length
                    ? 1
                    : 0),
            itemBuilder: (context, index) {
              if (!_showAllHistory &&
                  index == itemsToShow &&
                  _statusHistory.length > 3) {
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

              if (index >= _statusHistory.length) {
                return SizedBox.shrink();
              }

              final statusItem = _statusHistory[index];
              final isLast = index == _statusHistory.length - 1;
              final String formattedTime = DateFormat('dd/MM/yyyy HH:mm')
                  .format(statusItem.timestamp.toLocal());

              return TimelineEntry(
                status: statusItem.status,
                time: formattedTime,
                description: statusItem.notes ?? "Không có ghi chú",
                isLast: isLast,
                color: _getStatusColor(statusItem.status),
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

  String _formatStatusString(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Column(
            children: [
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
                  _formatStatusString(status),
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
