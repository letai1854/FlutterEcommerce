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
      initialDateRange: _customDateRange ??
          DateTimeRange(
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
      'id': index + 1,
      'ho_ten': 'Người dùng ${index + 1}',
      'email': 'user${index + 1}@example.com',
      'diem_khach_hang_than_thiet': (index * 10).toDouble(),
      'vai_tro': index % 5 == 0 ? 'quan_tri' : 'khach_hang',
      'trang_thai': index % 3 == 0 ? 'khoa' : 'kich_hoat',
      'ngay_tao': DateTime.now().subtract(Duration(days: index)).toString(),
      'ngay_cap_nhat': DateTime.now().toString(),
    },
  )
      .where((user) => user['vai_tro'] == 'khach_hang')
      .toList(); // Filter out admin users

  void _showEditDialog(Map<String, dynamic> user) {
    final TextEditingController nameController = TextEditingController(
      text: user['ho_ten'],
    );
    final TextEditingController emailController = TextEditingController(
      text: user['email'],
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Chỉnh sửa thông tin',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Họ tên',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng nhập họ tên'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      setState(() {
                        final index = _userData
                            .indexWhere((item) => item['id'] == user['id']);
                        if (index != -1) {
                          // Update user data
                          _userData[index]['ho_ten'] =
                              nameController.text.trim();
                          _userData[index]['email'] =
                              emailController.text.trim();
                          _userData[index]['ngay_cap_nhat'] =
                              DateTime.now().toString();

                          // Refresh data sources
                          _userDataSource = UserDataSource(_userData, this);
                          // Force rebuild of list view
                          _paginatedData.clear();
                          _paginatedData.addAll(_userData.sublist(
                            _currentPage * _rowsPerPage,
                            min((_currentPage + 1) * _rowsPerPage,
                                _userData.length),
                          ));
                        }
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      backgroundColor: Colors.purple,
                    ),
                    child: const Text(
                      'Lưu thay đổi',
                      style: TextStyle(color: Colors.white),
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

  void _toggleUserStatus(Map<String, dynamic> user) {
    final bool willLock = user['trang_thai'] == 'kich_hoat';
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    willLock ? Icons.lock : Icons.lock_open,
                    size: 24,
                    color: willLock ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    willLock
                        ? 'Xác nhận khóa tài khoản'
                        : 'Xác nhận kích hoạt tài khoản',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                willLock
                    ? 'Bạn có chắc chắn muốn khóa tài khoản của ${user['ho_ten']}?'
                    : 'Bạn có chắc chắn muốn kích hoạt tài khoản của ${user['ho_ten']}?',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Update status and trigger UI refresh
                      setState(() {
                        final index = _userData
                            .indexWhere((item) => item['id'] == user['id']);
                        if (index != -1) {
                          _userData[index]['trang_thai'] =
                              willLock ? 'khoa' : 'kich_hoat';
                          _userData[index]['ngay_cap_nhat'] =
                              DateTime.now().toString();
                          // Refresh both data sources
                          _userDataSource = UserDataSource(_userData, this);
                          // Force rebuild of list view
                          _paginatedData.clear();
                          _paginatedData.addAll(_userData.sublist(
                            _currentPage * _rowsPerPage,
                            min((_currentPage + 1) * _rowsPerPage,
                                _userData.length),
                          ));
                        }
                      });
                      Navigator.pop(context);

                      // Show confirmation snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            willLock
                                ? 'Đã khóa tài khoản của ${user['ho_ten']}'
                                : 'Đã kích hoạt tài khoản của ${user['ho_ten']}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: willLock ? Colors.red : Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: willLock ? Colors.red : Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      willLock ? 'Khóa tài khoản' : 'Kích hoạt tài khoản',
                      style: const TextStyle(color: Colors.white),
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

  late UserDataSource _userDataSource;

  @override
  void initState() {
    super.initState();
    _userDataSource = UserDataSource(_userData, this);
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
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    isDense: true,
                  ),
                ),
              ),

              // Removed Add Button
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
          physics:
              const NeverScrollableScrollPhysics(), // Disable ListView scrolling
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
                                user['ho_ten'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: user['trang_thai'] == 'kich_hoat'
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  user['trang_thai'] == 'kich_hoat'
                                      ? 'Đã kích hoạt'
                                      : 'Đã khóa',
                                  style: TextStyle(
                                    color: user['trang_thai'] == 'kich_hoat'
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                              onPressed: () => _showEditDialog(user),
                              icon: const Icon(Icons.edit, size: 18),
                              tooltip: 'Chỉnh sửa',
                              constraints: const BoxConstraints(
                                  minWidth: 36, minHeight: 36),
                              padding: EdgeInsets.zero,
                            ),
                            IconButton(
                              onPressed: () => _toggleUserStatus(user),
                              icon: Icon(
                                user['trang_thai'] == 'kich_hoat'
                                    ? Icons.lock
                                    : Icons.lock_open,
                                size: 18,
                                color: user['trang_thai'] == 'kich_hoat'
                                    ? Colors.red
                                    : Colors.green,
                              ),
                              tooltip: user['trang_thai'] == 'kich_hoat'
                                  ? 'Khóa tài khoản'
                                  : 'Kích hoạt tài khoản',
                              constraints: const BoxConstraints(
                                  minWidth: 36, minHeight: 36),
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
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      isDense: true,
                    ),
                  ),
                ),

                // Removed Add Button
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
                          DataColumn(label: Text('Họ tên')),
                          DataColumn(label: Text('Trạng thái')),
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
  final _UserScreenState _state;

  UserDataSource(this._data, this._state);

  @override
  DataRow? getRow(int index) {
    if (index >= _data.length) {
      return null;
    }
    final user = _data[index];
    return DataRow(cells: [
      DataCell(Text(user['ho_ten'])),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: user['trang_thai'] == 'kich_hoat'
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            user['trang_thai'] == 'kich_hoat' ? 'Đã kích hoạt' : 'Đã khóa',
            style: TextStyle(
              color:
                  user['trang_thai'] == 'kich_hoat' ? Colors.green : Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _state._showEditDialog(user),
              icon: const Icon(Icons.edit),
              tooltip: 'Chỉnh sửa',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            IconButton(
              onPressed: () => _state._toggleUserStatus(user),
              icon: Icon(
                user['trang_thai'] == 'kich_hoat'
                    ? Icons.lock
                    : Icons.lock_open,
                color: user['trang_thai'] == 'kich_hoat'
                    ? Colors.red
                    : Colors.green,
              ),
              tooltip: user['trang_thai'] == 'kich_hoat'
                  ? 'Khóa tài khoản'
                  : 'Kích hoạt tài khoản',
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
