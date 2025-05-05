import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:math';
import 'dart:io'; // Keep dart:io for File on non-web platforms
import 'package:flutter/foundation.dart'; // Import for kIsWeb


// Import AddUpdateProductScreen - make sure the path is correct
import 'Add_Update_Product.dart'; // <-- Ensure this path is correct

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

  // This function is kept but might not be used directly by the sample data filter
  DateTime _getStartDate() {
    switch (_selectedFilter) {
      case 'Hôm nay':
        // Filter logic for today (start of day to end of day)
        return DateTime.now().subtract(const Duration(days: 1)); // Example: Start of yesterday
      case 'Hôm qua':
         // Filter logic for yesterday
        return DateTime.now().subtract(const Duration(days: 2)); // Example: Start of the day before yesterday
      case 'Tuần này':
        // Filter logic for this week
        return DateTime.now().subtract(const Duration(days: 7)); // Example: Start of 7 days ago
      case 'Tháng này':
         // Filter logic for this month
        return DateTime.now().subtract(const Duration(days: 30)); // Example: Start of 30 days ago
      case 'Khoảng thời gian cụ thể':
        return _customDateRange?.start ?? DateTime.now();
      default: // 'Tất cả'
        return DateTime(2020); // A date far in the past
    }
  }


  // Sample data for demonstration - Includes full variant data for DISPLAY
  // IMPORTANT: Ensure that the paths in 'images' and 'defaultImage' actually exist
  // in your project's assets folder and are configured in pubspec.yaml.
  // For simplicity in the sample data, we're only using asset paths.
  final List<Map<String, dynamic>> _productData = List.generate(
    25,
    (index) => {
      'id': index + 1,
      'name':
          'Sản phẩm rất dài để kiểm tra cuộn ngang của bảng dữ liệu số ${index + 1}',
      'images': [
        // Using dummy asset paths - REPLACE with actual image handling in a real app
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
        // Ensure at least 1 variant, add more based on index
        max(1, 2 + (index % 2)), // At least 1, maybe 2 or 3 variants
        (varIndex) => {
          'id': varIndex + 1,
          'name':
              'Biến thể ${varIndex + 1} - ${index % 2 == 0 ? "Màu Đen" : "Màu Trắng"}', // Removed RAM part for simplicity
          // Include variant fields needed for DISPLAY
          'sku': 'SKU-${index + 1}-${varIndex + 1}', // SKU is back
          'price': ((index + 1) * 100000) + (varIndex * 50000), // Adjusted price scale
          'quantity': (index + 5) + (varIndex * 3),
          // Using dummy asset path for variant image - REPLACE with actual image path (asset or file/network)
          'defaultImage': 'assets/variant${((index + varIndex) % 3) + 1}.jpg',
          'created_date': DateTime.now() // Created date back
              .subtract(Duration(days: index))
              .toString()
              .split(' ')[0],
          'updated_date': DateTime.now() // Updated date back
              .subtract(Duration(days: index % 3))
              .toString()
              .split(' ')[0],
           // Note: Discount, Brand, Category are NOT in sample variant data here
        },
      ),
    },
  );

  // Removed _showProductList and _productToEdit state variables

  // Method to navigate to Add/Update screen using Navigator
  void _navigateToAddUpdateScreen({Map<String, dynamic>? product}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddUpdateProductScreen( product: product),
      ),
      // The .then() block is called when the pushed screen (AddUpdateProductScreen)
      // is popped (when Navigator.pop() is called in AddUpdateProductScreen).
      // This is the correct place to refresh the UI if needed after adding/editing.
      // In a real app, you would likely refetch the data here.
    ).then((_) {
      print('Returned from Add/Update Screen. Refreshing Product List.');
      // For this sample, just rebuild the UI
      setState(() {});
    });
  }

  // Removed _returnToProductList method

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
      // Adjust current page if the last item on the page was deleted
      if (_currentPage > 0 &&
          _paginatedData.isEmpty && // Check if the current page is now empty after removal
          _productData.isNotEmpty // Ensure there are still products left
          ) {
        _currentPage--;
      } else if (_productData.isEmpty) {
         _currentPage = 0; // Reset to page 0 if all products are gone
      }
      // Trigger a rebuild to reflect the deletion
      setState(() {}); // Redundant but harmless after removeAt
    });
    print('Deleted product at actual index $index');
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
            width: 100, // Increased width for labels
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

  // Helper to build image widget from path (Handles Asset, File, and Network based on platform)
  Widget _buildImageWidget(String? imageSource, {double size = 40, double iconSize = 40, BoxFit fit = BoxFit.cover}) {
    if (imageSource == null || imageSource.isEmpty) {
      return Icon(Icons.image, size: iconSize, color: Colors.grey); // Placeholder icon
    }

    // Check if it's an asset path (simple check)
    if (imageSource.startsWith('assets/')) {
       return Image.asset(
            imageSource,
            fit: fit,
             errorBuilder: (context, error, stackTrace) {
                 // Show placeholder if asset fails to load
                 print('Error loading asset: $imageSource, Error: $error'); // Debugging
                 return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
             },
       );
    } else if (imageSource.startsWith('http') || imageSource.startsWith('https')) {
        // Assume it's a network URL
         return Image.network(
             imageSource,
             fit: fit,
              errorBuilder: (context, error, stackTrace) {
                 // Show placeholder if network image fails
                 print('Error loading network image: $imageSource, Error: $error'); // Debugging
                 return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
             },
         );
    }
    else if (kIsWeb) {
        // On web, if not asset or http, assume it's a web-specific path like a blob URL from image_picker
         return Image.network( // Treat blob URLs like network images on web
             imageSource,
             fit: fit,
              errorBuilder: (context, error, stackTrace) {
                 // Show placeholder if blob URL fails
                 print('Error loading web path (blob/file): $imageSource, Error: $error'); // Debugging
                 return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
             },
         );
    }
    else {
      // On non-web, if not asset or http, assume it's a file path
       try {
         return Image.file(
             File(imageSource),
             fit: fit,
              errorBuilder: (context, error, stackTrace) {
                 // Show placeholder if file fails to load
                 print('Error loading file: $imageSource, Error: $error'); // Debugging
                 return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
             },
         );
       } catch (e) {
         // Handle potential errors during file creation
         print('Exception creating File from path: $imageSource, Exception: $e'); // Debugging
         return Icon(Icons.error_outline, size: iconSize, color: Colors.red);
       }
    }
  }


  // Displays full variant details in a dialog
  void _showVariantsDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Ensure variants list is not null
        final List<Map<String, dynamic>> variants = List<Map<String, dynamic>>.from(product['variants'] ?? []);

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            width: double.maxFinite,
             constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6, // Limit dialog height
                  ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Biến thể của ${product['name'] ?? '[Không tên sản phẩm]'}',
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
                Expanded( // Use Expanded for the ListView
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: variants.length,
                    itemBuilder: (context, index) {
                      final variant = variants[index];
                      // Determine the image widget for the variant
                      final String? imagePath = variant['defaultImage'];

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                clipBehavior: Clip.antiAlias, // Apply border radius to the image
                                child: _buildImageWidget(imagePath, size: 50, iconSize: 30), // Use helper
                              ),
                          title: Text(variant['name'] ?? 'Biến thể [Không tên]',
                              style: TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Display variant details from data
                              if (variant.containsKey('sku') && variant['sku'] != null && variant['sku'].toString().isNotEmpty)
                                Text('Mã sự kiện: ${variant['sku']}'),
                               // Display price, handling potential null/non-numeric
                              Text(
                                  'Giá: ${variant['price'] != null ? (variant['price'] as num).toStringAsFixed(0) : 'N/A'} VNĐ'),
                                // Display quantity, handling potential null/non-numeric
                              Text('Tồn kho: ${variant['quantity'] != null ? (variant['quantity'] as num).toString() : 'N/A'}'),
                              if (variant.containsKey('created_date') && variant['created_date'] != null)
                                Text('Ngày tạo: ${variant['created_date']}'),
                              if (variant.containsKey('updated_date') && variant['updated_date'] != null)
                                Text('Cập nhật: ${variant['updated_date']}'),
                            ],
                          ),
                          isThreeLine: true, // Set to true because there are multiple subtitle lines
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

   // Handles displaying main product images (assets or files/network)
   Widget _buildImageGallery(List<dynamic> images) { // Accept List<dynamic> to be flexible
    // Filter out nulls and ensure they are strings
    final validImages = images.where((img) => img != null && img is String).cast<String>().toList();

    if (validImages.isEmpty) {
      return Container(
        width: 80,
        height: 120,
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
      );
    }
    return Container(
      height: 120,
      width: 80,
      child: PageView.builder(
        itemCount: validImages.length,
        itemBuilder: (context, i) {
           final imagePath = validImages[i];

          return Container(
            width: 80,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias, // Apply border radius to the image
            child: _buildImageWidget(imagePath, size: 80, iconSize: 40), // Use helper
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final double availableWidth = MediaQuery.of(context).size.width - 2 * 16.0;

    return Scaffold(
      body: SingleChildScrollView( // Use SingleChildScrollView to handle overflow
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildSmallScreenLayout(availableWidth), // Keep the layout function
              ),
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
                width: 250, // Example width
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
                 width: 250, // Adjusted width
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
                         // TODO: Implement filter logic based on selected interval
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
                  // Use Navigator.push to go to the Add screen
                  _navigateToAddUpdateScreen();
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                  textStyle: const TextStyle(fontSize: 14),
                  minimumSize: const Size(0, 48), // Match height of dropdown/textfield
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
          physics: const NeverScrollableScrollPhysics(), // Disable scrolling for this list inside SingleChildScrollView
          itemCount: _paginatedData.length,
          itemBuilder: (context, index) {
            final product = _paginatedData[index];
             // Cast images to List<dynamic> to be safe, then pass to gallery builder
            final List<dynamic> productImages = product['images'] ?? [];

            return Column(
              children: [
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImageGallery(productImages), // Use helper
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                product['name'] ?? '[Không tên]',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              _buildInfoRow('Thương hiệu:', product['brand'] ?? 'N/A'),
                              _buildInfoRow('Danh mục:', product['category'] ?? 'N/A'),
                              _buildInfoRow('Mô tả:', product['description'] ?? 'N/A',
                                  maxLength: 80),
                              _buildInfoRow('Ngày tạo:',
                                  '${(product['createdDate'] as DateTime?)?.toLocal().toString().split(' ')[0] ?? 'N/A'}'),
                              _buildInfoRow('Ngày cập nhật:',
                                  '${(product['updatedDate'] as DateTime?)?.toLocal().toString().split(' ')[0] ?? 'N/A'}'),
                              _buildInfoRow(
                                  'Giảm giá:', '${product['discount'] ?? 0}%'),
                              _buildInfoRow('Số biến thể:',
                                  '${(product['variants'] as List?)?.length ?? 0}'),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Only show "Xem biến thể" button if variants exist
                            if ((product['variants'] as List? ?? []).isNotEmpty)
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
                                // Use Navigator.push to go to the Edit screen
                                // Pass the specific product data
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
                                // Calculate the actual index in the full list
                                final actualIndex = (_currentPage * _rowsPerPage) + index;
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
              ],
            );
          },
        ),
         const SizedBox(height: 20),
        // Pagination controls
         if (_productData.isNotEmpty)
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
                      '${_currentPage + 1} / ${_pageCount > 0 ? _pageCount : 1}',
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
         const SizedBox(height: 24),
      ],
    );
  }
}
