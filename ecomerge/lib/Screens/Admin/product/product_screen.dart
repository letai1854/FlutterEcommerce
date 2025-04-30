import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // Import for debugging if needed
import 'dart:math'; // Add this import for using max function
class ProductScreen extends StatefulWidget {
  const ProductScreen({Key? key}) : super(key: key);

  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
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
        print('Selected date range: ${picked.start} - ${picked.end}');
      });
    }
  }

  // This method is not strictly necessary for the layout fix,
  // but kept as it was in the original code.
  // It needs to be integrated with the actual filtering logic.
  DateTime _getStartDate() {
    switch (_selectedFilter) {
      case 'Hôm nay':
        // This calculation seems off for "Hôm nay". Should likely be start of today.
        // Returning a dummy date for now as filtering isn't fully implemented.
        return DateTime.now().subtract(const Duration(days: 1));
      case 'Hôm qua':
         // Returning a dummy date for now
        return DateTime.now().subtract(const Duration(days: 2));
      case 'Tuần này':
        // Returning a dummy date for now
        return DateTime.now().subtract(const Duration(days: 7));
      case 'Tháng này':
        // Returning a dummy date for now
        return DateTime.now().subtract(const Duration(days: 30));
      case 'Khoảng thời gian cụ thể':
        return _customDateRange?.start ?? DateTime.now(); // Use start date from picker
      default:
        return DateTime(2020); // Default or earliest possible date
    }
  }

  // Sample data for demonstration
  final List<Map<String, dynamic>> _productData = List.generate(
    25, // More data to potentially exceed screen width/height
    (index) => {
      // Sử dụng tên sản phẩm dài hơn để đảm bảo cuộn ngang hoạt động
      'name': 'Sản phẩm rất dài để kiểm tra cuộn ngang của bảng dữ liệu số ${index + 1}',
      'price': '${(index + 1) * 1000000} VNĐ',
      'quantity': '${index + 10}',
      'category': 'Danh mục ${index % 3 + 1}',
    },
  );

  // The DataTableSource needs to be recreated if the _data list changes due to filtering
  // For now, we just use the full sample data.
  late ProductDataSource _productDataSource;

  // Thêm các biến cần thiết cho phân trang trên màn hình nhỏ
  int _currentPage = 0;
  final int _rowsPerPage = 10;
  
  // Lấy danh sách sản phẩm cho trang hiện tại
  List<Map<String, dynamic>> get _paginatedData {
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = min(startIndex + _rowsPerPage, _productData.length);
    
    if (startIndex >= _productData.length) return [];
    return _productData.sublist(startIndex, endIndex);
  }
  
  // Tính số trang dựa trên dữ liệu và số hàng mỗi trang
  int get _pageCount => (_productData.length / _rowsPerPage).ceil();

  @override
  void initState() {
    super.initState();
    _productDataSource = ProductDataSource(_productData);
  }

  @override
  void dispose() {
    // Dispose any controllers if added (e.g., for search)
    super.dispose();
  }

  // Add the _buildInfoRow method here inside _ProductScreenState
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // To debug layout issues, uncomment the following line:
    // debugPaintSizeEnabled = true; // Helps visualize layout bounds

    // Calculate the available width for the controls area
    // This is the total screen width minus the horizontal padding (16.0 on both sides)
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
          'Quản lý sản phẩm',
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

              // Add Product Button
              ElevatedButton(
                onPressed: () {
                  print('Thêm sản phẩm Pressed');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                  textStyle: const TextStyle(fontSize: 14),
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('Thêm sản phẩm'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Header for the table section
        Text(
          'Danh sách sản phẩm',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        // Danh sách sản phẩm
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Disable ListView scrolling
          itemCount: _paginatedData.length,
          itemBuilder: (context, index) {
            final product = _paginatedData[index];
            return Column(
              children: [
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Phần thông tin sản phẩm
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                product['name'].toString(),
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
                                      'Giá: ${product['price']}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'SL: ${product['quantity']}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              
                              Text(
                                'Danh mục: ${product['category']}',
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
                                print('Chỉnh sửa ${product['name']}');
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              tooltip: 'Chỉnh sửa',
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              padding: EdgeInsets.zero,
                            ),
                            IconButton(
                              onPressed: () {
                                print('Xóa ${product['name']}');
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
                'Hiển thị ${_paginatedData.isEmpty ? 0 : (_currentPage * _rowsPerPage) + 1} - ${(_currentPage * _rowsPerPage) + _paginatedData.length} trên ${_productData.length}',
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
            'Quản lý sản phẩm',
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
                  width: 250, // Thay đổi từ 200 thành 250 để khớp với màn hình nhỏ
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
                  width: 250, // Thay đổi từ 180 thành 250 để khớp với màn hình nhỏ
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

                // Add Product Button
                ElevatedButton(
                  onPressed: () {
                    print('Thêm sản phẩm Pressed');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                    textStyle: const TextStyle(fontSize: 14),
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('Thêm sản phẩm'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Header for the table section
          Text(
            'Danh sách sản phẩm',
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
                        key: ValueKey(_productData.length),
                        columnSpacing: 20,
                        horizontalMargin: 10,
                        columns: const [
                          DataColumn(label: Text('Tên sản phẩm')),
                          DataColumn(label: Text('Giá')),
                          DataColumn(label: Text('Số lượng')),
                          DataColumn(label: Text('Danh mục')),
                          DataColumn(label: Text('Chức năng')),
                        ],
                        source: _productDataSource,
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

class ProductDataSource extends DataTableSource {
  List<Map<String, dynamic>> _data; // Made list mutable for potential updates

  ProductDataSource(this._data);

  // Example method to update data and notify listeners
  void updateData(List<Map<String, dynamic>> newData) {
     _data = newData;
     notifyListeners(); // Important! Call this after data changes
  }

  // Example method to delete an item and notify listeners
  void deleteItem(int index) {
     if (index < _data.length) {
        _data.removeAt(index);
        notifyListeners(); // Important! Call this after data changes
     }
  }


  @override
  DataRow? getRow(int index) {
    if (index >= _data.length) return null;
    final product = _data[index];
    return DataRow(cells: [
      DataCell(Text(product['name'].toString())), // Ensure text is String
      DataCell(Text(product['price'].toString())),
      DataCell(Text(product['quantity'].toString())),
      DataCell(Text(product['category'].toString())),
      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min, // Ensure the row doesn't take full width
          children: [
            IconButton(
              onPressed: () {
                // TODO: Implement Edit logic (e.g., show edit dialog)
                print('Chỉnh sửa ${product['name']}');
                // Example: showEditDialog(_data[index]);
              },
              icon: const Icon(Icons.edit),
              tooltip: 'Chỉnh sửa', // Add tooltips for better UX
              padding: EdgeInsets.zero, // Remove default padding
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40), // Ensure tappable area
            ),
            IconButton(
              onPressed: () {
                // TODO: Implement Delete logic (e.g., show confirmation dialog)
                 print('Xóa ${product['name']}');
                 // Example: confirmAndDelete(index);
                 // In a real app, you'd likely call a method like deleteItem(index);
              },
              icon: const Icon(Icons.delete),
              tooltip: 'Xóa', // Add tooltips
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

  // Methods to update the data source (examples)
  // void addProduct(Map<String, dynamic> newProduct) {
  //   _data.add(newProduct);
  //   notifyListeners(); // Call this after data changes
  // }
}
