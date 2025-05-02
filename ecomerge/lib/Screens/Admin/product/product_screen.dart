import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // Import for debugging if needed
import 'dart:math'; // Add this import for using max function
import 'Add_Update_Product.dart'; // Import AddUpdateProductScreen

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
      'name': 'Sản phẩm rất dài để kiểm tra cuộn ngang của bảng dữ liệu số ${index + 1}',
      'image': 'assets/product${(index % 3) + 1}.jpg', // Dummy image
      'brand': 'Thương hiệu ${index % 5 + 1}',
      'category': 'Danh mục ${index % 3 + 1}',
      'description': 'Mô tả chi tiết cho sản phẩm số ${index + 1}. Đây là một đoạn mô tả dài hơn để kiểm tra hiển thị.',
      'price': (index + 1) * 1000000,
      'quantity': index + 10,
      'rating': (index % 5) + 1.0,
      'createdDate': DateTime.now().subtract(Duration(days: index)),
      'discount': index % 2 == 0 ? (index % 5) * 5 : 0, // Dummy discount
    },
  );

  // State variable to control visibility of product list and add/update screen
  bool _showProductList = true;

  // Thêm các biến cần thiết cho phân trang
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
      body: _showProductList
          ? SingleChildScrollView( // Wrap with SingleChildScrollView for overall page scrolling
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: isSmallScreen
                    ? _buildSmallScreenLayout(availableWidth)
                    : _buildLargeScreenLayout(availableWidth),
              ),
            )
          : const AddUpdateProductScreen(), // Assuming AddUpdateProductScreen is a widget
    );
  }

  // Layout cho màn hình nhỏ (mobile, tablet nhỏ)
  Widget _buildSmallScreenLayout(double availableWidth) {
    return Column( // Changed from ListView to Column as it's wrapped by SingleChildScrollView
      crossAxisAlignment: CrossAxisAlignment.start,
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
                  setState(() {
                    _showProductList = false; // Hide product list, show add/update screen
                  });
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
                      crossAxisAlignment: CrossAxisAlignment.start, // Align items to the top
                      children: [
                        // Product Image
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: AssetImage(product['image']),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Product Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                product['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              _buildInfoRow('Thương hiệu:', product['brand']),
                              _buildInfoRow('Danh mục:', product['category']),
                              _buildInfoRow('Mô tả:', product['description']),
                              _buildInfoRow('Giá:', '${product['price']} VNĐ'),
                              _buildInfoRow('Tồn kho:', product['quantity'].toString()),
                              _buildInfoRow('Số sao:', product['rating'].toString()),
                              _buildInfoRow('Ngày tạo:', '${product['createdDate'].toLocal().toString().split(' ')[0]}'),
                              _buildInfoRow('Giảm giá:', '${product['discount']}%'),
                            ],
                          ),
                        ),

                        // Action Buttons
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                print('Chỉnh sửa ${product['name']}');
                                // TODO: Navigate to AddUpdateProductScreen for editing
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              tooltip: 'Chỉnh sửa',
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              padding: EdgeInsets.zero,
                            ),
                            IconButton(
                              onPressed: () {
                                print('Xóa ${product['name']}');
                                // TODO: Implement delete functionality
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
    return Column( // Changed from Padding to Column as it's wrapped by SingleChildScrollView
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
                  setState(() {
                    _showProductList = false; // Hide product list, show add/update screen
                  });
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

        // Product List (using ListView.builder for responsiveness)
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Disable ListView scrolling
          itemCount: _paginatedData.length, // Use paginated data
          itemBuilder: (context, index) {
            final product = _paginatedData[index]; // Use paginated data
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Image
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: AssetImage(product['image']),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Product Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow('Thương hiệu:', product['brand']),
                              _buildInfoRow('Danh mục:', product['category']),
                              _buildInfoRow('Giá:', '${product['price']} VNĐ'),
                              _buildInfoRow('Tồn kho:', product['quantity'].toString()),
                              _buildInfoRow('Số sao:', product['rating'].toString()),
                              _buildInfoRow('Ngày tạo:', '${product['createdDate'].toLocal().toString().split(' ')[0]}'),
                              _buildInfoRow('Giảm giá:', '${product['discount']}%'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Description (full width)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mô tả:', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(product['description']),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            print('Chỉnh sửa ${product['name']}');
                            // TODO: Navigate to AddUpdateProductScreen for editing
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Chỉnh sửa'),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            print('Xóa ${product['name']}');
                            // TODO: Implement delete functionality
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Xóa'),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16), // Add spacing before pagination controls

        // Pagination controls for large screen
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
}
