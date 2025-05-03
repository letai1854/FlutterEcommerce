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

  // Sample data for demonstration - updated to include multiple images and variants
  final List<Map<String, dynamic>> _productData = List.generate(
    25,
    (index) => {
      'id': index + 1,
      'name':
          'Sản phẩm rất dài để kiểm tra cuộn ngang của bảng dữ liệu số ${index + 1}',
      'images': [
        'assets/product${(index % 3) + 1}.jpg',
        'assets/product${((index + 1) % 3) + 1}.jpg',
        'assets/product${((index + 2) % 3) + 1}.jpg',
      ],
      'brand': 'Thương hiệu ${index % 5 + 1}',
      'category': 'Danh mục ${index % 3 + 1}',
      'description':
          'Mô tả chi tiết cho sản phẩm số ${index + 1}. Đây là một đoạn mô tả dài hơn để kiểm tra hiển thị.',
      'createdDate': DateTime.now().subtract(Duration(days: index)),
      'updatedDate': DateTime.now()
          .subtract(Duration(days: index % 5)), // Added updated date
      'discount': index % 2 == 0 ? (index % 5) * 5 : 0,
      'variants': List.generate(
        2 + (index % 3),
        (varIndex) => {
          'id': varIndex + 1,
          'name':
              'Biến thể ${varIndex + 1} - ${index % 2 == 0 ? "Màu Đen" : "Màu Trắng"}, RAM ${8 + (varIndex * 8)}GB',
          // Make SKU optional - only add for some variants
          if ((index + varIndex) % 3 != 0)
            'sku': 'SKU-${index + 1}-${varIndex + 1}',
          'price': ((index + 1) * 1000000) + (varIndex * 500000),
          'quantity': (index + 5) + (varIndex * 3),
          'image': 'assets/product${((index + varIndex) % 3) + 1}.jpg',
          'created_date': DateTime.now()
              .subtract(Duration(days: index))
              .toString()
              .split(' ')[0],
          'updated_date': DateTime.now()
              .subtract(Duration(days: index % 3))
              .toString()
              .split(' ')[0],
        },
      ),
    },
  );

  // State variable to control visibility of product list and add/update screen
  bool _showProductList = true;
  Map<String, dynamic>? _productToEdit;

  // Method to navigate to Add/Update screen
  void _navigateToAddUpdateScreen({Map<String, dynamic>? product}) {
    setState(() {
      _productToEdit = product;
      _showProductList = false; // Hide product list, show add/update screen
    });
  }

  // Method to return from Add/Update screen
  void _returnToProductList() {
    setState(() {
      _productToEdit = null;
      _showProductList = true; // Show product list again
    });
  }

  int _currentPage = 0;
  final int _rowsPerPage = 10;

  List<Map<String, dynamic>> get _paginatedData {
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = min(startIndex + _rowsPerPage, _productData.length);

    if (startIndex >= _productData.length) return [];
    return _productData.sublist(startIndex, endIndex);
  }

  int get _pageCount => (_productData.length / _rowsPerPage).ceil();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _deleteProduct(int index) {
    setState(() {
      _productData.removeAt(index);
      if (_currentPage > 0 &&
          _paginatedData.isEmpty &&
          _productData.isNotEmpty) {
        _currentPage--;
      }
      if (_currentPage > 0 && _paginatedData.isEmpty && _productData.isEmpty) {
        _currentPage = 0;
      }
    });
    print('Deleted product at index $index');
  }

  Widget _buildInfoRow(String label, String value, {int maxLength = 80}) {
    String displayValue = value;
    if (value.length > maxLength) {
      displayValue = value.substring(0, maxLength) + '...';
    }

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
              displayValue,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _showVariantsDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Biến thể của ${product['name']}',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        softWrap: true,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  ],
                ),
                Divider(),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: product['variants'].length,
                    itemBuilder: (context, index) {
                      final variant = product['variants'][index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(variant['image']),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          title: Text(variant['name'],
                              style: TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (variant.containsKey('sku') &&
                                  variant['sku'] != null &&
                                  variant['sku'].toString().isNotEmpty)
                                Text('Mã sự kiện: ${variant['sku']}'),
                              Text(
                                  'Giá: ${variant['price'].toStringAsFixed(0)} VNĐ'),
                              Text('Tồn kho: ${variant['quantity']}'),
                              Text('Ngày tạo: ${variant['created_date']}'),
                              Text('Cập nhật: ${variant['updated_date']}'),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageGallery(List<String> images) {
    return Container(
      height: 120,
      width: 80,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, i) {
          return Container(
            width: 80,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: AssetImage(images[i]),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double availableWidth = MediaQuery.of(context).size.width - 2 * 16.0;

    return Scaffold(
      body: _showProductList
          ? SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildSmallScreenLayout(availableWidth),
              ),
            )
          : AddUpdateProductScreen(
              product: _productToEdit,
              key: ValueKey(
                  _productToEdit != null ? _productToEdit!['id'] : 'new'),
            ),
    );
  }

  Widget _buildSmallScreenLayout(double availableWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quản lý sản phẩm',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: availableWidth,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
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
              ElevatedButton(
                onPressed: () {
                  _navigateToAddUpdateScreen();
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                  textStyle: const TextStyle(fontSize: 14),
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('Thêm sản phẩm'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Danh sách sản phẩm',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImageGallery(product['images']),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                product['name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              _buildInfoRow('Thương hiệu:', product['brand']),
                              _buildInfoRow('Danh mục:', product['category']),
                              _buildInfoRow('Mô tả:', product['description'],
                                  maxLength: 80),
                              _buildInfoRow('Ngày tạo:',
                                  '${product['createdDate'].toLocal().toString().split(' ')[0]}'),
                              _buildInfoRow('Ngày cập nhật:',
                                  '${product['updatedDate'].toLocal().toString().split(' ')[0]}'),
                              _buildInfoRow(
                                  'Giảm giá:', '${product['discount']}%'),
                              _buildInfoRow('Số biến thể:',
                                  '${product['variants'].length}'),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () {
                                _showVariantsDialog(product);
                              },
                              child: Text('Xem biến thể'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                minimumSize: Size(0, 30),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                _navigateToAddUpdateScreen(product: product);
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              tooltip: 'Chỉnh sửa',
                              constraints: const BoxConstraints(
                                  minWidth: 36, minHeight: 36),
                              padding: EdgeInsets.zero,
                            ),
                            IconButton(
                              onPressed: () {
                                final actualIndex =
                                    (_currentPage * _rowsPerPage) + index;
                                _deleteProduct(actualIndex);
                              },
                              icon: const Icon(Icons.delete, size: 18),
                              tooltip: 'Xóa',
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
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                'Hiển thị ${_paginatedData.isEmpty ? 0 : (_currentPage * _rowsPerPage) + 1} - ${(_currentPage * _rowsPerPage) + _paginatedData.length} trên ${_productData.length}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
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
