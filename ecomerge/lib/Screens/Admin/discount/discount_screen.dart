import 'package:e_commerce_app/Screens/Admin/discount/AddDiscountScreen.dart';
import 'package:e_commerce_app/database/models/coupon_dto.dart';
import 'package:e_commerce_app/database/services/coupon_service.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class DiscountScreen extends StatefulWidget {
  const DiscountScreen({Key? key}) : super(key: key);

  @override
  _DiscountScreenState createState() => _DiscountScreenState();
}

class _DiscountScreenState extends State<DiscountScreen> {
  final CouponService _couponService = CouponService();
  List<CouponResponseDTO> _allDiscounts = [];
  bool _isLoading = true;
  String _errorMessage = '';

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
  final int _rowsPerPage = 20;

  @override
  void initState() {
    super.initState();
    _fetchDiscounts();
  }

  @override
  void dispose() {
    _couponService.dispose();
    super.dispose();
  }

  Future<void> _fetchDiscounts(
      {String? code, DateTime? startDate, DateTime? endDate}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final coupons = await _couponService.getCoupons(
          code: code, startDate: startDate, endDate: endDate);
      if (!mounted) return;
      setState(() {
        _allDiscounts = coupons;
        _allDiscounts.sort((a, b) {
          if (a.createdDate == null && b.createdDate == null) return 0;
          if (a.createdDate == null) return 1;
          if (b.createdDate == null) return -1;
          return b.createdDate!.compareTo(a.createdDate!);
        });
        _isLoading = false;
        _currentPage = 0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi tải mã giảm giá: ${e.toString()}';
      });
    }
  }

  List<CouponResponseDTO> get _filteredAndPaginatedData {
    List<CouponResponseDTO> filteredData = _allDiscounts;

    if (_selectedFilter == 'Khoảng thời gian cụ thể' &&
        _customDateRange != null) {
      filteredData = _allDiscounts.where((discount) {
        final createDate = discount.createdDate;
        if (createDate == null) return false;
        return createDate.isAfter(
                _customDateRange!.start.subtract(const Duration(seconds: 1))) &&
            createDate.isBefore(_customDateRange!.end
                .add(const Duration(days: 1))
                .subtract(const Duration(seconds: 1)));
      }).toList();
    } else if (_selectedFilter != 'Tất cả') {
      final now = DateTime.now();
      filteredData = _allDiscounts.where((discount) {
        final createDate = discount.createdDate;
        if (createDate == null) return false;
        final startOfToday = DateTime(now.year, now.month, now.day);
        final endOfToday =
            DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

        if (_selectedFilter == 'Hôm nay') {
          return createDate
                  .isAfter(startOfToday.subtract(const Duration(seconds: 1))) &&
              createDate.isBefore(endOfToday.add(const Duration(seconds: 1)));
        } else if (_selectedFilter == 'Hôm qua') {
          final yesterday = now.subtract(const Duration(days: 1));
          final startOfYesterday =
              DateTime(yesterday.year, yesterday.month, yesterday.day);
          final endOfYesterday = DateTime(
              yesterday.year, yesterday.month, yesterday.day, 23, 59, 59, 999);
          return createDate.isAfter(
                  startOfYesterday.subtract(const Duration(seconds: 1))) &&
              createDate
                  .isBefore(endOfYesterday.add(const Duration(seconds: 1)));
        } else if (_selectedFilter == 'Tuần này') {
          final startOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
          final startOfThisWeekMidnight = DateTime(
              startOfThisWeek.year, startOfThisWeek.month, startOfThisWeek.day);
          return createDate.isAfter(startOfThisWeekMidnight
                  .subtract(const Duration(seconds: 1))) &&
              createDate.isBefore(endOfToday.add(const Duration(seconds: 1)));
        } else if (_selectedFilter == 'Tháng này') {
          final startOfThisMonth = DateTime(now.year, now.month, 1);
          return createDate.isAfter(
                  startOfThisMonth.subtract(const Duration(seconds: 1))) &&
              createDate.isBefore(endOfToday.add(const Duration(seconds: 1)));
        }
        return true;
      }).toList();
    }

    final startIndex = _currentPage * _rowsPerPage;
    if (startIndex >= filteredData.length) {
      if (filteredData.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _currentPage =
                  max(0, (filteredData.length / _rowsPerPage).ceil() - 1);
            });
          }
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _currentPage = 0;
            });
          }
        });
      }
      return [];
    }
    final endIndex = min(startIndex + _rowsPerPage, filteredData.length);
    return filteredData.sublist(startIndex, endIndex);
  }

  int get _totalFilteredItems {
    if (_selectedFilter == 'Khoảng thời gian cụ thể' &&
        _customDateRange != null) {
      return _allDiscounts.where((discount) {
        final createDate = discount.createdDate;
        if (createDate == null) return false;
        return createDate.isAfter(
                _customDateRange!.start.subtract(const Duration(seconds: 1))) &&
            createDate.isBefore(_customDateRange!.end
                .add(const Duration(days: 1))
                .subtract(const Duration(seconds: 1)));
      }).length;
    } else if (_selectedFilter != 'Tất cả') {
      final now = DateTime.now();
      return _allDiscounts.where((discount) {
        final createDate = discount.createdDate;
        if (createDate == null) return false;
        final startOfToday = DateTime(now.year, now.month, now.day);
        final endOfToday =
            DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        if (_selectedFilter == 'Hôm nay') {
          return createDate
                  .isAfter(startOfToday.subtract(const Duration(seconds: 1))) &&
              createDate.isBefore(endOfToday.add(const Duration(seconds: 1)));
        } else if (_selectedFilter == 'Hôm qua') {
          final yesterday = now.subtract(const Duration(days: 1));
          final startOfYesterday =
              DateTime(yesterday.year, yesterday.month, yesterday.day);
          final endOfYesterday = DateTime(
              yesterday.year, yesterday.month, yesterday.day, 23, 59, 59, 999);
          return createDate.isAfter(
                  startOfYesterday.subtract(const Duration(seconds: 1))) &&
              createDate
                  .isBefore(endOfYesterday.add(const Duration(seconds: 1)));
        } else if (_selectedFilter == 'Tuần này') {
          final startOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
          final startOfThisWeekMidnight = DateTime(
              startOfThisWeek.year, startOfThisWeek.month, startOfThisWeek.day);
          return createDate.isAfter(startOfThisWeekMidnight
                  .subtract(const Duration(seconds: 1))) &&
              createDate.isBefore(endOfToday.add(const Duration(seconds: 1)));
        } else if (_selectedFilter == 'Tháng này') {
          final startOfThisMonth = DateTime(now.year, now.month, 1);
          return createDate.isAfter(
                  startOfThisMonth.subtract(const Duration(seconds: 1))) &&
              createDate.isBefore(endOfToday.add(const Duration(seconds: 1)));
        }
        return true;
      }).length;
    }
    return _allDiscounts.length;
  }

  int get _filteredPageCount {
    final totalItems = _totalFilteredItems;
    if (totalItems == 0) return 1;
    return (totalItems / _rowsPerPage).ceil();
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
      helpText: 'Chọn khoảng thời gian',
      cancelText: 'Hủy',
      confirmText: 'Xác nhận',
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null && picked != _customDateRange) {
      setState(() {
        _customDateRange = picked;
        _selectedFilter = 'Khoảng thời gian cụ thể';
        _currentPage = 0;
      });
    } else if (picked == null && _selectedFilter == 'Khoảng thời gian cụ thể') {
      if (_customDateRange != null) {
        setState(() {
          _selectedFilter = 'Tất cả';
          _customDateRange = null;
          _currentPage = 0;
        });
      }
    }
  }

  void _showDiscountDetailsDialog(CouponResponseDTO discount) {
    final creationDate = discount.createdDate;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormat =
        NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Chi tiết Mã giảm giá: ${discount.code}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Mã code: ${discount.code}',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(
                    'Giá trị giảm: ${currencyFormat.format(discount.discountValue)}'),
                Text(
                    'Đã sử dụng: ${discount.usageCount} / ${discount.maxUsageCount} lần'),
                Text(
                    'Ngày tạo: ${creationDate != null ? dateFormat.format(creationDate.toLocal()) : 'N/A'}'),
                SizedBox(height: 16),
                Text('Đơn hàng đã áp dụng:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Divider(),
                Text('Thông tin đơn hàng áp dụng không có sẵn.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Đóng'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double availableWidth = MediaQuery.of(context).size.width - 2 * 16.0;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: availableWidth,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddDiscountScreen(),
                          ),
                        );
                        if (result == true) {
                          _fetchDiscounts();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 16),
                        textStyle: const TextStyle(fontSize: 14),
                        minimumSize: const Size(0, 48),
                      ),
                      child: const Text('Thêm mã giảm giá'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Danh sách mã giảm giá',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_errorMessage.isNotEmpty)
                Center(
                    child: Text(_errorMessage,
                        style: TextStyle(color: Colors.red)))
              else if (_filteredAndPaginatedData.isEmpty &&
                  _totalFilteredItems > 0)
                const Center(
                    child: Text('Không có mã giảm giá nào trên trang này.'))
              else if (_filteredAndPaginatedData.isEmpty &&
                  _totalFilteredItems == 0)
                const Center(
                    child: Text('Không có mã giảm giá nào được tìm thấy.'))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredAndPaginatedData.length,
                  itemBuilder: (context, index) {
                    final discount = _filteredAndPaginatedData[index];
                    final creationDate = discount.createdDate;
                    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
                    final currencyFormat = NumberFormat.currency(
                        locale: 'vi_VN', symbol: 'VNĐ', decimalDigits: 0);

                    return Card(
                      key: ValueKey(discount.id ?? discount.code),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      elevation: 2,
                      child: InkWell(
                        onTap: () {
                          _showDiscountDetailsDialog(discount);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mã: ${discount.code}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Giá trị: ${currencyFormat.format(discount.discountValue)}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Đã sử dụng: ${discount.usageCount} / ${discount.maxUsageCount} lần',
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ngày tạo: ${creationDate != null ? dateFormat.format(creationDate.toLocal()) : 'N/A'}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),
              if (!_isLoading && _allDiscounts.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Hiển thị ${_filteredAndPaginatedData.isEmpty ? 0 : (_currentPage * _rowsPerPage) + 1} - ${(_currentPage * _rowsPerPage) + _filteredAndPaginatedData.length} trên ${_totalFilteredItems}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_left),
                            onPressed:
                                _currentPage > 0 && _totalFilteredItems > 0
                                    ? () {
                                        setState(() {
                                          _currentPage--;
                                        });
                                      }
                                    : null,
                            tooltip: 'Trang trước',
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              '${_currentPage + 1} / ${_filteredPageCount > 0 ? _filteredPageCount : 1}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_right),
                            onPressed: _currentPage < _filteredPageCount - 1 &&
                                    _totalFilteredItems > 0
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
          ),
        ),
      ),
    );
  }
}
