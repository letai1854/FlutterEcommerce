import 'package:flutter/material.dart';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class CatalogProductScreen extends StatefulWidget {
  const CatalogProductScreen({Key? key}) : super(key: key);

  @override
  _CatalogProductScreenState createState() => _CatalogProductScreenState();
}

class _CatalogProductScreenState extends State<CatalogProductScreen> {
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

  int _currentPage = 0;
  final int _rowsPerPage = 10;

  List<Map<String, dynamic>> get _paginatedData {
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = min(startIndex + _rowsPerPage, _catalogProductData.length);

    if (startIndex >= _catalogProductData.length) return [];
    return _catalogProductData.sublist(startIndex, endIndex);
  }

  int get _pageCount => (_catalogProductData.length / _rowsPerPage).ceil();

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

  final List<Map<String, dynamic>> _catalogProductData = List.generate(
      25,
      (index) => {
            'id': index + 1,
            'ten_danh_muc': 'Danh mục ${index + 1}',
            'hinh_anh': 'https://picsum.photos/seed/${index + 100}/200/200',
            'ngay_tao':
                DateTime.now().subtract(Duration(days: index)).toString(),
            'ngay_cap_nhat': DateTime.now().toString(),
          });

  late CatalogProductDataSource _catalogProductDataSource;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  XFile? _selectedImage;

  void _showCategoryDialog([Map<String, dynamic>? category]) {
    final bool isEditing = category != null;
    final TextEditingController nameController = TextEditingController(
      text: isEditing ? category['ten_danh_muc'] : '',
    );
    _selectedImage = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(isEditing ? 'Chỉnh sửa danh mục' : 'Thêm danh mục mới'),
          content: SingleChildScrollView(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên danh mục',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  await _pickImage();
                  setStateDialog(() {}); // Refresh dialog UI
                },
                icon: const Icon(Icons.image),
                label: const Text('Chọn ảnh'),
              ),
              const SizedBox(height: 16),
              if (_selectedImage != null ||
                  (isEditing && category['hinh_anh'] != null)) ...[
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _selectedImage != null
                      ? kIsWeb
                          ? Image.network(_selectedImage!.path,
                              fit: BoxFit.cover)
                          : Image.file(File(_selectedImage!.path),
                              fit: BoxFit.cover)
                      : Image.network(
                          category?['hinh_anh'] ?? '',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                                child: Icon(Icons.image_not_supported));
                          },
                        ),
                ),
              ],
            ],
          )),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tên danh mục')),
                  );
                  return;
                }

                if (!isEditing && _selectedImage == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng chọn hình ảnh')),
                  );
                  return;
                }

                String imagePath = '';
                if (_selectedImage != null) {
                  imagePath = _selectedImage!.path;
                } else if (isEditing) {
                  imagePath = category!['hinh_anh'];
                }

                if (isEditing) {
                  final index = _catalogProductData.indexWhere(
                    (item) => item['id'] == category['id'],
                  );
                  if (index != -1) {
                    setState(() {
                      _catalogProductData[index]['ten_danh_muc'] =
                          nameController.text;
                      _catalogProductData[index]['hinh_anh'] = imagePath;
                      _catalogProductData[index]['ngay_cap_nhat'] =
                          DateTime.now().toString();
                      _catalogProductDataSource =
                          CatalogProductDataSource(_catalogProductData, this);
                    });
                  }
                } else {
                  setState(() {
                    _catalogProductData.add({
                      'id': _catalogProductData.length + 1,
                      'ten_danh_muc': nameController.text,
                      'hinh_anh': imagePath,
                      'ngay_tao': DateTime.now().toString(),
                      'ngay_cap_nhat': DateTime.now().toString(),
                    });
                    _catalogProductDataSource =
                        CatalogProductDataSource(_catalogProductData, this);
                  });
                }
                Navigator.pop(context);
              },
              child: Text(isEditing ? 'Cập nhật' : 'Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
            'Bạn có chắc chắn muốn xóa danh mục "${category['ten_danh_muc']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _catalogProductData
                    .removeWhere((item) => item['id'] == category['id']);
                _catalogProductDataSource =
                    CatalogProductDataSource(_catalogProductData, this);
              });
              Navigator.pop(context);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _catalogProductDataSource =
        CatalogProductDataSource(_catalogProductData, this);
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

  Widget _buildSmallScreenLayout(double availableWidth) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Quản lý danh mục sản phẩm',
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
                  _showCategoryDialog();
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                  textStyle: const TextStyle(fontSize: 14),
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('Thêm danh mục sản phẩm'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Danh sách danh mục sản phẩm',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _paginatedData.length,
          itemBuilder: (context, index) {
            final category = _paginatedData[index];
            return Column(
              children: [
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: (category['hinh_anh'] != null &&
                                  category['hinh_anh'].toString().isNotEmpty)
                              ? Image.network(
                                  category['hinh_anh'].toString(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.image_not_supported,
                                          color: Colors.grey),
                                    );
                                  },
                                )
                              : const Center(
                                  child: Icon(Icons.image_not_supported,
                                      color: Colors.grey),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            category['ten_danh_muc'].toString(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                _showCategoryDialog(category);
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              tooltip: 'Chỉnh sửa',
                              constraints: const BoxConstraints(
                                  minWidth: 36, minHeight: 36),
                              padding: EdgeInsets.zero,
                            ),
                            IconButton(
                              onPressed: () {
                                _showDeleteConfirmation(category);
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
                'Hiển thị ${_paginatedData.isEmpty ? 0 : (_currentPage * _rowsPerPage) + 1} - ${(_currentPage * _rowsPerPage) + _paginatedData.length} trên ${_catalogProductData.length}',
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

  Widget _buildLargeScreenLayout(double availableWidth) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quản lý danh mục sản phẩm',
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
                    _showCategoryDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 16),
                    textStyle: const TextStyle(fontSize: 14),
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('Thêm danh mục sản phẩm'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Danh sách danh mục sản phẩm',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
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
                        key: ValueKey(_catalogProductData.length),
                        columnSpacing: 20,
                        horizontalMargin: 10,
                        columns: const [
                          DataColumn(label: Text('Tên danh mục')),
                          DataColumn(label: Text('Hình ảnh')),
                          DataColumn(label: Text('Chức năng')),
                        ],
                        source: _catalogProductDataSource,
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

class CatalogProductDataSource extends DataTableSource {
  final List<Map<String, dynamic>> _data;
  final _CatalogProductScreenState _state;

  CatalogProductDataSource(this._data, this._state);

  @override
  DataRow? getRow(int index) {
    if (index >= _data.length) {
      return null;
    }
    final category = _data[index];
    return DataRow(cells: [
      DataCell(Text(category['ten_danh_muc'])),
      DataCell(
        (category['hinh_anh'] != null &&
                category['hinh_anh'].toString().isNotEmpty)
            ? SizedBox(
                width: 60,
                height: 60,
                child: Image.network(
                  category['hinh_anh'].toString(),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.image_not_supported));
                  },
                ),
              )
            : const Center(child: Icon(Icons.image_not_supported)),
      ),
      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                _state._showCategoryDialog(category);
              },
              icon: const Icon(Icons.edit),
              tooltip: 'Chỉnh sửa',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            IconButton(
              onPressed: () {
                _state._showDeleteConfirmation(category);
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
