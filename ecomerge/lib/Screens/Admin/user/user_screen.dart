import 'package:flutter/material.dart';
import 'dart:math';

class UserScreen extends StatefulWidget {
  const UserScreen({Key? key}) : super(key: key);

  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
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
  
  // Lấy danh sách người dùng cho trang hiện tại
  List<Map<String, dynamic>> get _paginatedData {
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = min(startIndex + _rowsPerPage, _userData.length);
    
    if (startIndex >= _userData.length) return [];
    return _userData.sublist(startIndex, endIndex);
  }
  
  // Tính số trang dựa trên dữ liệu và số hàng mỗi trang
  int get _pageCount => (_userData.length / _rowsPerPage).ceil();

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
  final List<Map<String, dynamic>> _userData = List.generate(
      25,
      (index) => {
            'name': 'Người dùng ${index + 1}',
            'email': 'user${index + 1}@example.com',
            'role': index % 2 == 0 ? 'Người dùng' : 'Admin',
          });

  late UserDataSource _userDataSource;

  @override
  void initState() {
    super.initState();
    _userDataSource = UserDataSource(_userData);
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
          'Quản lý người dùng',
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
                  print('Thêm người dùng Pressed');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                  textStyle: const TextStyle(fontSize: 14),
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('Thêm người dùng'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Header for the table section
        Text(
          'Danh sách người dùng',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        // Danh sách người dùng
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Disable ListView scrolling
          itemCount: _paginatedData.length,
          itemBuilder: (context, index) {
            final user = _paginatedData[index];
            return Column(
              children: [
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Phần thông tin người dùng
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                user['name'].toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      user['email'].toString(),
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              
                              Text(
                                'Vai trò: ${user['role']}',
                                style: TextStyle(
                                  fontSize: 12, 
                                  color: user['role'] == 'Admin' ? Colors.blue : Colors.grey,
                                  fontWeight: user['role'] == 'Admin' ? FontWeight.w500 : FontWeight.normal,
                                ),
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
                                print('Chỉnh sửa ${user['name']}');
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              tooltip: 'Chỉnh sửa',
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              padding: EdgeInsets.zero,
                            ),
                            IconButton(
                              onPressed: () {
                                print('Xóa ${user['name']}');
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
                'Hiển thị ${_paginatedData.isEmpty ? 0 : (_currentPage * _rowsPerPage) + 1} - ${(_currentPage * _rowsPerPage) + _paginatedData.length} trên ${_userData.length}',
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
            'Quản lý người dùng',
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
                    print('Thêm người dùng Pressed');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                    textStyle: const TextStyle(fontSize: 14),
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('Thêm người dùng'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Header for the table section
          Text(
            'Danh sách người dùng',
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
                        key: ValueKey(_userData.length),
                        columnSpacing: 20,
                        horizontalMargin: 10,
                        columns: const [
                          DataColumn(label: Text('Tên người dùng')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Vai trò')),
                          DataColumn(label: Text('Chức năng')),
                        ],
                        source: _userDataSource,
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

class UserDataSource extends DataTableSource {
  final List<Map<String, dynamic>> _data;

  UserDataSource(this._data);

  @override
  DataRow? getRow(int index) {
    if (index >= _data.length) {
      return null;
    }
    final user = _data[index];
    return DataRow(cells: [
      DataCell(Text(user['name'])),
      DataCell(Text(user['email'])),
      DataCell(
        Text(
          user['role'],
          style: TextStyle(
            color: user['role'] == 'Admin' ? Colors.blue : Colors.black87,
            fontWeight: user['role'] == 'Admin' ? FontWeight.w500 : FontWeight.normal,
          ),
        )
      ),
      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                // TODO: Implement edit logic
                print('Chỉnh sửa ${user['name']}');
              },
              icon: const Icon(Icons.edit),
              tooltip: 'Chỉnh sửa',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            IconButton(
              onPressed: () {
                // TODO: Implement delete logic
                print('Xóa ${user['name']}');
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
