import 'package:flutter/material.dart';
import 'dart:math';

class OrderScreen extends StatefulWidget {
  const OrderScreen({Key? key}) : super(key: key);

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  String _selectedFilter = 'Tất cả';
  final List<String> _filterOptions = [
    'Tất cả',
    'Hôm nay',
    'Hôm qua',
    'Tuần này',
    'Tháng này',
    'Khoảng thời gian cụ thể',
  ];

  DateTimeRange? _customDateRange;

  // Thêm các biến cần thiết cho phân trang
  int _currentPage = 0;
  final int _rowsPerPage = 10;
  
  // Lấy danh sách đơn hàng cho trang hiện tại
  List<Map<String, dynamic>> get _paginatedData {
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = min(startIndex + _rowsPerPage, _orderData.length);
    
    if (startIndex >= _orderData.length) return [];
    return _orderData.sublist(startIndex, endIndex);
  }
  
  // Tính số trang dựa trên dữ liệu và số hàng mỗi trang
  int get _pageCount => (_orderData.length / _rowsPerPage).ceil();

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _customDateRange ?? DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
    );
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedFilter = 'Khoảng thời gian cụ thể';
        // TODO: Implement filter logic based on _customDateRange
      });
    }
  }

  DateTime _getStartDate() {
    switch (_selectedFilter) {
      case 'Hôm nay':
        return DateTime.now().subtract(const Duration(days: 1));
      case 'Hôm qua':
        return DateTime.now().subtract(const Duration(days: 2));
      case 'Tuần này':
        return DateTime.now().subtract(const Duration(days: 7));
      case 'Tháng này':
        return DateTime.now().subtract(const Duration(days: 30));
      case 'Khoảng thời gian cụ thể':
        return _customDateRange?.start ?? DateTime.now();
      default:
        return DateTime(2020);
    }
  }

  // Sample data for demonstration
  final List<Map<String, dynamic>> _orderData = List.generate(
      25,
      (index) => {
            'order_id': 'ORDER${index + 1}',
            'customer': 'Khách hàng ${index + 1}',
            'total': '${(index + 1) * 100000} VNĐ',
            'status': index % 2 == 0 ? 'Đang xử lý' : 'Hoàn thành',
            'order_date': '2025-04-${index + 1}',
          });

  late OrderDataSource _orderDataSource;

  @override
  void initState() {
    super.initState();
    _orderDataSource = OrderDataSource(_orderData);
  }

  @override
  Widget build(BuildContext context) {
    final double availableWidth = MediaQuery.of(context).size.width - 2 * 16.0;
    final bool isSmallScreen = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      body: isSmallScreen
        ? _buildSmallScreenLayout(availableWidth)
        : _buildLargeScreenLayout(availableWidth),
    );
  }

  // Layout cho màn hình nhỏ (mobile, tablet nhỏ)
  Widget _buildSmallScreenLayout(double availableWidth) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Tiêu đề trang
        Text(
          'Quản lý đơn hàng',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        // --- Controls Area (Search, Filter, Add Button) ---
        SizedBox(
          width: availableWidth,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Search TextField
              SizedBox(
                width: 250,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    isDense: true,
                  ),
                ),
              ),

              // Filter Dropdown
              SizedBox(
                width: 250,
                child: DropdownButtonFormField<String>(
                  value: _selectedFilter,
                  items: _filterOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedFilter = newValue!;
                      if (newValue == 'Khoảng thời gian cụ thể') {
                        _showDateRangePicker();
                      } else {
                        print('Selected filter: $newValue');
                      }
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    isDense: true,
                  ),
                ),
              ),

              // Add Button
              ElevatedButton(
                onPressed: () {
                  print('Thêm đơn hàng Pressed');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                  textStyle: const TextStyle(fontSize: 14),
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('Thêm đơn hàng'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Header for the table section
        Text(
          'Danh sách đơn hàng',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        // Danh sách đơn hàng
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Disable ListView scrolling
          itemCount: _paginatedData.length,
          itemBuilder: (context, index) {
            final order = _paginatedData[index];
            return Column(
              children: [
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Phần thông tin đơn hàng
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Mã: ${order['order_id']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '${order['customer']}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      order['status'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: order['status'] == 'Hoàn thành' ? Colors.green : Colors.orange,
                                        fontWeight: FontWeight.w500
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              Text(
                                'Tổng tiền: ${order['total']} - Ngày: ${order['order_date']}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        
                        // Các nút chức năng
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                print('Chỉnh sửa ${order['order_id']}');
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              tooltip: 'Chỉnh sửa',
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              padding: EdgeInsets.zero,
                            ),
                            IconButton(
                              onPressed: () {
                                print('Xóa ${order['order_id']}');
                              },
                              icon: const Icon(Icons.delete, size: 18),
                              tooltip: 'Xóa',
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (index < _paginatedData.length - 1)
                  const Divider(height: 1, thickness: 0.5),
              ],
            );
          },
        ),

        // Phần điều khiển phân trang
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Widget hiển thị thông tin phân trang
              Text(
                'Hiển thị ${_paginatedData.isEmpty ? 0 : (_currentPage * _rowsPerPage) + 1} - ${(_currentPage * _rowsPerPage) + _paginatedData.length} trên ${_orderData.length}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              
              // Nút điều hướng phân trang
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_left),
                    onPressed: _currentPage > 0
                        ? () {
                            setState(() {
                              _currentPage--;
                            });
                          }
                        : null,
                    tooltip: 'Trang trước',
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      '${_currentPage + 1} / $_pageCount',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_right),
                    onPressed: _currentPage < _pageCount - 1
                        ? () {
                            setState(() {
                              _currentPage++;
                            });
                          }
                        : null,
                    tooltip: 'Trang tiếp',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Layout cho màn hình lớn (desktop, tablet lớn)
  Widget _buildLargeScreenLayout(double availableWidth) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quản lý đơn hàng',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // --- Controls Area ---
          SizedBox(
            width: availableWidth,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Search TextField
                SizedBox(
                  width: 250,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Tìm kiếm...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      isDense: true,
                    ),
                  ),
                ),

                // Filter Dropdown
                SizedBox(
                  width: 250,
                  child: DropdownButtonFormField<String>(
                    value: _selectedFilter,
                    items: _filterOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedFilter = newValue!;
                        if (newValue == 'Khoảng thời gian cụ thể') {
                          _showDateRangePicker();
                        } else {
                          print('Selected filter: $newValue');
                        }
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      isDense: true,
                    ),
                  ),
                ),

                // Add Button
                ElevatedButton(
                  onPressed: () {
                    print('Thêm đơn hàng Pressed');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                    textStyle: const TextStyle(fontSize: 14),
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('Thêm đơn hàng'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Header for the table section
          Text(
            'Danh sách đơn hàng',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Table Area
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: max(constraints.maxWidth, 800),
                      child: PaginatedDataTable(
                        key: ValueKey(_orderData.length),
                        columnSpacing: 20,
                        horizontalMargin: 10,
                        columns: const [
                          DataColumn(label: Text('Mã đơn hàng')),
                          DataColumn(label: Text('Khách hàng')),
                          DataColumn(label: Text('Tổng tiền')),
                          DataColumn(label: Text('Trạng thái')),
                          DataColumn(label: Text('Ngày đặt')),
                          DataColumn(label: Text('Chức năng')),
                        ],
                        source: _orderDataSource,
                        rowsPerPage: 10,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class OrderDataSource extends DataTableSource {
  final List<Map<String, dynamic>> _data;

  OrderDataSource(this._data);

  @override
  DataRow? getRow(int index) {
    if (index >= _data.length) {
      return null;
    }
    final order = _data[index];
    return DataRow(cells: [
      DataCell(Text(order['order_id'])),
      DataCell(Text(order['customer'])),
      DataCell(Text(order['total'])),
      DataCell(
        Text(
          order['status'],
          style: TextStyle(
            color: order['status'] == 'Hoàn thành' ? Colors.green : Colors.orange,
            fontWeight: FontWeight.w500
          ),
        )
      ),
      DataCell(Text(order['order_date'])),
      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                // TODO: Implement edit logic
                print('Chỉnh sửa ${order['order_id']}');
              },
              icon: const Icon(Icons.edit),
              tooltip: 'Chỉnh sửa',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            IconButton(
              onPressed: () {
                // TODO: Implement delete logic
                print('Xóa ${order['order_id']}');
              },
              icon: const Icon(Icons.delete),
              tooltip: 'Xóa',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ],
        ),
      ),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _data.length;

  @override
  int get selectedRowCount => 0;
}
