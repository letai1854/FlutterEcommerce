import 'package:e_commerce_app/Screens/Admin/order/OrderDetailScreen.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';


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

  final List<String> _orderStatuses = const [
    'cho_xac_nhan', 'da_xac_nhan', 'dang_dong_goi',
    'dang_giao', 'da_giao', 'da_huy',
    'yeu_cau_tra_hang', 'da_tra_hang',
  ];

   final Map<String, String> _orderStatusDisplay = const {
      'cho_xac_nhan': 'Chờ xác nhận', 'da_xac_nhan': 'Đã xác nhận',
      'dang_dong_goi': 'Đang đóng gói', 'dang_giao': 'Đang giao',
      'da_giao': 'Đã giao', 'da_huy': 'Đã hủy',
      'yeu_cau_tra_hang': 'Yêu cầu trả hàng', 'da_tra_hang': 'Đã trả hàng',
   };

  DateTimeRange? _customDateRange;
  int _currentPage = 0;
  final int _rowsPerPage = 20; // 20 items per page

  late final List<Map<String, dynamic>> _orderData;

  @override
  void initState() {
    super.initState();
     _orderData = List.generate(
        55, (index) {
           final basePrice = (index + 1) * 50000.0;
           final itemQty1 = max(1, index % 4);
           final itemQty2 = max(1, (index + 1) % 3);
           final itemQty3 = max(1, (index + 2) % 2);
           final itemPrice1 = basePrice;
           final itemPrice2 = basePrice * 1.1;
           final itemPrice3 = basePrice * 0.9;
           final itemDiscountPercent1 = (index % 5) * 2.0;
           final itemDiscountPercent2 = ((index+1) % 5) * 2.0;
           final itemDiscountPercent3 = ((index+2) % 5) * 2.0;
           final itemSubtotal1 = itemPrice1 * itemQty1 * (1 - itemDiscountPercent1 / 100.0);
           final itemSubtotal2 = itemPrice2 * itemQty2 * (1 - itemDiscountPercent2 / 100.0);
           final itemSubtotal3 = itemPrice3 * itemQty3 * (1 - itemDiscountPercent3 / 100.0);
           final coupon = index % 5 == 0 ? 50000.0 : 0.0;
           final points = index % 7 == 0 ? 20000.0 : 0.0;
           final shipping = index % 4 == 0 ? 30000.0 : 0.0;
           final totalBeforeDiscountsAndFees = itemSubtotal1 + itemSubtotal2 + itemSubtotal3;
           final taxAmount = totalBeforeDiscountsAndFees > 0 ? totalBeforeDiscountsAndFees * 0.1 : 0.0;
           final orderTotal = totalBeforeDiscountsAndFees - coupon - points + shipping + taxAmount;

          return {
              'id': index + 1, 'order_id': 'ORDER${1000 + index + 1}',
              'nguoi_dung_id': (index % 10) + 1, 'ma_giam_gia_id': index % 5 == 0 ? (index ~/ 5) + 1 : null,
              'ten_nguoi_nhan': 'Người nhận ${index + 1}', 'so_dien_thoai_nguoi_nhan': '09${index.toString().padLeft(8, '0')}',
              'dia_chi_giao_hang': 'Số nhà ${index * 7}, Đường ${String.fromCharCode(65 + index % 26)}, Phường ${index % 10}, Quận ${index % 5 + 1}, TP. Hồ Chí Minh. Đây là một địa chỉ rất dài để kiểm tra xuống dòng.',
              'tong_tien_hang_goc': itemPrice1 * itemQty1 + itemPrice2 * itemQty2 + itemPrice3 * itemQty3,
              'tien_giam_gia_coupon': coupon, 'tien_su_dung_diem': points,
              'phi_van_chuyen': shipping, 'thue': max(0.0, taxAmount),
              'tong_thanh_toan': max(0.0, orderTotal),
              'phuong_thuc_thanh_toan': index % 3 == 0 ? 'Chuyển khoản' : (index % 3 == 1 ? 'Tiền mặt' : 'Ví điện tử'),
              'trang_thai_thanh_toan': index % 4 == 0 ? 'da_thanh_toan' : (index % 4 == 1 ? 'loi_thanh_toan' : 'chua_thanh_toan'),
              'trang_thai_don_hang': _orderStatuses[index % _orderStatuses.length],
              'diem_tich_luy': max(0.0, orderTotal > 0 ? orderTotal * 0.1 : 0.0),
              'ngay_dat_hang': DateTime.now().subtract(Duration(days: index * 2, minutes: index)),
              'ngay_cap_nhat': DateTime.now().subtract(Duration(days: index * 2, minutes: index % 3)),

              'chi_tiet': [
                  {
                      'bien_the_san_pham_id': (index % 100) + 1, 'ten_bien_the': 'Sản phẩm ${index % 5 + 1} - Biến thể ${index % 3 + 1}',
                      'so_luong': itemQty1, 'gia_tai_thoi_diem_mua': itemPrice1,
                      'phan_tram_giam_gia_san_pham': itemDiscountPercent1, 'thanh_tien': itemSubtotal1,
                      'anh_bien_the': 'assets/variant${((index + 0) % 3) + 1}.jpg',
                  }, {
                      'bien_the_san_pham_id': (index % 100) + 2, 'ten_bien_the': 'Sản phẩm ${index % 5 + 2} - Biến thể ${index % 3 + 2}',
                      'so_luong': itemQty2, 'gia_tai_thoi_diem_mua': itemPrice2,
                      'phan_tram_giam_gia_san_pham': itemDiscountPercent2, 'thanh_tien': itemSubtotal2,
                      'anh_bien_the': 'assets/variant${((index + 1) % 3) + 1}.jpg',
                  }, if (index % 2 == 0) {
                      'bien_the_san_pham_id': (index % 100) + 3, 'ten_bien_the': 'Sản phẩm ${index % 5 + 3} - Biến thể ${index % 3 + 3}',
                      'so_luong': itemQty3, 'gia_tai_thoi_diem_mua': itemPrice3,
                      'phan_tram_giam_gia_san_pham': itemDiscountPercent3, 'thanh_tien': itemSubtotal3,
                      'anh_bien_the': 'assets/variant${((index + 2) % 3) + 1}.jpg',
                  },
              ].where((item) => (item['so_luong'] as num? ?? 0) > 0).toList(),
          };
        }
      );

     _orderData.sort((a, b) => (b['ngay_dat_hang'] as DateTime).compareTo(a['ngay_dat_hang'] as DateTime));
  }


   List<Map<String, dynamic>> get _filteredAndPaginatedData {
        List<Map<String, dynamic>> filteredData = _orderData;
        if (_selectedFilter == 'Khoảng thời gian cụ thể' && _customDateRange != null) {
            filteredData = _orderData.where((order) {
                final orderDate = order['ngay_dat_hang'] as DateTime;
                return orderDate.isAfter(_customDateRange!.start.subtract(const Duration(seconds: 1)))
                       && orderDate.isBefore(_customDateRange!.end.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)));
            }).toList();
        } else if (_selectedFilter != 'Tất cả') {
            final now = DateTime.now();
            filteredData = _orderData.where((order) {
                 final orderDate = order['ngay_dat_hang'] as DateTime;
                 final startOfToday = DateTime(now.year, now.month, now.day);
                 final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

                 if (_selectedFilter == 'Hôm nay') {
                      return orderDate.isAfter(startOfToday.subtract(const Duration(seconds: 1))) && orderDate.isBefore(endOfToday.add(const Duration(seconds: 1)));
                 } else if (_selectedFilter == 'Hôm qua') {
                      final yesterday = now.subtract(const Duration(days: 1));
                      final startOfYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day);
                      final endOfYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59, 999);
                      return orderDate.isAfter(startOfYesterday.subtract(const Duration(seconds: 1))) && orderDate.isBefore(endOfYesterday.add(const Duration(seconds: 1)));
                 } else if (_selectedFilter == 'Tuần này') {
                     final startOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
                     final startOfThisWeekMidnight = DateTime(startOfThisWeek.year, startOfThisWeek.month, startOfThisWeek.day);
                     return orderDate.isAfter(startOfThisWeekMidnight.subtract(const Duration(seconds: 1))) && orderDate.isBefore(endOfToday.add(const Duration(seconds: 1)));
                 } else if (_selectedFilter == 'Tháng này') {
                     final startOfThisMonth = DateTime(now.year, now.month, 1);
                     return orderDate.isAfter(startOfThisMonth.subtract(const Duration(seconds: 1))) && orderDate.isBefore(endOfToday.add(const Duration(seconds: 1)));
                 }
                 return true;
             }).toList();
        }

        final startIndex = _currentPage * _rowsPerPage;
        if (startIndex >= filteredData.length) {
             if (filteredData.isNotEmpty) {
                 WidgetsBinding.instance.addPostFrameCallback((_) {
                     setState(() {
                         _currentPage = max(0, (filteredData.length / _rowsPerPage).ceil() - 1);
                     });
                 });
             } else {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                     setState(() {
                        _currentPage = 0;
                     });
                  });
             }
             return [];
        }

        final endIndex = min(startIndex + _rowsPerPage, filteredData.length);
        return filteredData.sublist(startIndex, endIndex);
   }


   int get _totalFilteredItems {
       return _orderData.where((order) {
           if (_selectedFilter == 'Khoảng thời gian cụ thể' && _customDateRange != null) {
               final orderDate = order['ngay_dat_hang'] as DateTime;
                return orderDate.isAfter(_customDateRange!.start.subtract(const Duration(seconds: 1)))
                       && orderDate.isBefore(_customDateRange!.end.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)));
           } else if (_selectedFilter != 'Tất cả') {
               final now = DateTime.now();
               if (_selectedFilter == 'Hôm nay') {
                    final startOfToday = DateTime(now.year, now.month, now.day);
                    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
                    final orderDate = order['ngay_dat_hang'] as DateTime;
                    return orderDate.isAfter(startOfToday.subtract(const Duration(seconds: 1))) && orderDate.isBefore(endOfToday.add(const Duration(seconds: 1)));
               } else if (_selectedFilter == 'Hôm qua') {
                    final yesterday = now.subtract(const Duration(days: 1));
                    final startOfYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day);
                    final endOfYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59, 999);
                     final orderDate = order['ngay_dat_hang'] as DateTime;
                    return orderDate.isAfter(startOfYesterday.subtract(const Duration(seconds: 1))) && orderDate.isBefore(endOfYesterday.add(const Duration(seconds: 1)));
               } else if (_selectedFilter == 'Tuần này') {
                   final startOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
                   final startOfThisWeekMidnight = DateTime(startOfThisWeek.year, startOfThisWeek.month, startOfThisWeek.day);
                   final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
                    final orderDate = order['ngay_dat_hang'] as DateTime;
                   return orderDate.isAfter(startOfThisWeekMidnight.subtract(const Duration(seconds: 1))) && orderDate.isBefore(endOfToday.add(const Duration(seconds: 1)));
               } else if (_selectedFilter == 'Tháng này') {
                   final startOfThisMonth = DateTime(now.year, now.month, 1);
                   final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
                    final orderDate = order['ngay_dat_hang'] as DateTime;
                   return orderDate.isAfter(startOfThisMonth.subtract(const Duration(seconds: 1))) && orderDate.isBefore(endOfToday.add(const Duration(seconds: 1)));
               }
               return true;
           }
           return true;
       }).length;
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
      initialDateRange: _customDateRange ?? DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
       helpText: 'Chọn khoảng thời gian',
       cancelText: 'Hủy',
       confirmText: 'Xác nhận',
       locale: const Locale('vi', 'VN'), // Locale is set here
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

  void _updateOrderStatus(String orderId, String newStatus) {
      final order = _orderData.firstWhere((order) => order['order_id'] == orderId, orElse: () => {});
      if (order.isNotEmpty && order['trang_thai_don_hang'] == newStatus) {
           print('Status for order $orderId is already $newStatus');
           return;
      }

      setState(() {
          try {
              final orderIndex = _orderData.indexWhere((order) => order['order_id'] == orderId);
              if (orderIndex != -1) {
                  Map<String, dynamic> updatedOrder = Map.from(_orderData[orderIndex]);
                  updatedOrder['trang_thai_don_hang'] = newStatus;
                  updatedOrder['ngay_cap_nhat'] = DateTime.now();

                  _orderData[orderIndex] = updatedOrder;

                   print('Updated status for order $orderId to $newStatus');
                   ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Cập nhật trạng thái đơn hàng $orderId thành "${_orderStatusDisplay[newStatus] ?? newStatus}"')),
                   );
              }
          } catch (e) {
              print('Error updating order status locally: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Lỗi cập nhật trạng thái đơn hàng $orderId')),
                   );
          }
      });
  }


  @override
  Widget build(BuildContext context) {
    final double availableWidth = MediaQuery.of(context).size.width - 2 * 16.0;

    return Scaffold(
       appBar: AppBar(
         title: const Text('Quản lý Đơn hàng'),
         automaticallyImplyLeading: false,
       ),
      body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildScreenLayout(availableWidth),
              ),
            ),
    );
  }

  Widget _buildScreenLayout(double availableWidth) {
    final paginatedFilteredData = _filteredAndPaginatedData;
    final totalFilteredItems = _totalFilteredItems;
    final totalFilteredPages = _filteredPageCount;


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

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
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
                    if (newValue != null) {
                       setState(() {
                          _selectedFilter = newValue;
                          if (newValue == 'Khoảng thời gian cụ thể') {
                            _showDateRangePicker();
                          } else {
                            _customDateRange = null;
                            _currentPage = 0;
                          }
                       });
                    }
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Danh sách đơn hàng',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

         paginatedFilteredData.isEmpty && _totalFilteredItems > 0
             ? const Center(child: Text('Không có đơn hàng nào trên trang này.'))
             : paginatedFilteredData.isEmpty && _totalFilteredItems == 0
                 ? const Center(child: Text('Không có đơn hàng nào được tìm thấy.'))
                 : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: paginatedFilteredData.length,
                      itemBuilder: (context, index) {
                        final order = paginatedFilteredData[index];
                        final orderDate = order['ngay_dat_hang'] as DateTime?;
                        final updatedDate = order['ngay_cap_nhat'] as DateTime?;
                        final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

                        final currentStatus = order['trang_thai_don_hang']?.toString() ?? 'N/A';


                        return Card(
                          key: ValueKey(order['order_id']),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: 2,
                          child: InkWell(
                             onTap: () {
                                if (order.isNotEmpty) {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => OrderDetailScreen(order: order),
                                        ),
                                    );
                                }
                             },
                             child: Padding(
                               padding: const EdgeInsets.all(12.0),
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Mã ĐH: ${order['order_id'] ?? 'N/A'}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                         // --- BỌC DropdownButtonFormField BẰNG GestureDetector ---
                                         GestureDetector(
                                            onTap: () {},
                                            behavior: HitTestBehavior.opaque,
                                            child: SizedBox(
                                              width: 150,
                                              child: DropdownButtonFormField<String>(
                                                isDense: true,
                                                decoration: InputDecoration(
                                                   contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                                                   isCollapsed: true,
                                                ),
                                                value: _orderStatuses.contains(currentStatus) ? currentStatus : null,
                                                items: _orderStatuses.map((String statusValue) {
                                                  return DropdownMenuItem<String>(
                                                    value: statusValue,
                                                    child: Text(
                                                      _orderStatusDisplay[statusValue] ?? statusValue,
                                                      style: TextStyle(fontSize: 13),
                                                       overflow: TextOverflow.ellipsis,
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: (String? newValue) {
                                                  if (newValue != null && order['order_id'] != null) {
                                                    _updateOrderStatus(order['order_id'], newValue);
                                                  }
                                                },
                                                validator: (value) {
                                                   if (value == null || value.isEmpty) {
                                                        return 'Chọn trạng thái';
                                                   }
                                                   return null;
                                                },
                                                hint: Text('Trạng thái'),
                                             ),
                                           ),
                                         ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    LayoutBuilder(
                                       builder: (context, constraints) {
                                           if (constraints.maxWidth < 350) {
                                               return Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                      Text('Người nhận: ${order['ten_nguoi_nhan'] ?? 'N/A'}', style: TextStyle(fontSize: 13)),
                                                      Text('SĐT: ${order['so_dien_thoai_nguoi_nhan'] ?? 'N/A'}', style: TextStyle(fontSize: 13)),
                                                  ],
                                               );
                                           } else {
                                               return Row(
                                                 children: [
                                                    Expanded(
                                                        flex: 1,
                                                        child: Text('Người nhận: ${order['ten_nguoi_nhan'] ?? 'N/A'}', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                                                    Expanded(
                                                       flex: 1,
                                                       child: Text('SĐT: ${order['so_dien_thoai_nguoi_nhan'] ?? 'N/A'}', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                                                 ],
                                               );
                                           }
                                       }
                                    ),
                                    const SizedBox(height: 4),

                                     Text('Địa chỉ: ${order['dia_chi_giao_hang'] ?? 'N/A'}', style: TextStyle(fontSize: 13)),
                                     const SizedBox(height: 4),

                                     LayoutBuilder(
                                        builder: (context, constraints) {
                                           if (constraints.maxWidth < 350) {
                                                return Column(
                                                   crossAxisAlignment: CrossAxisAlignment.start,
                                                   children: [
                                                       Text('Tổng tiền: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ', decimalDigits: 0).format(order['tong_thanh_toan'] ?? 0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                                       Text('TT TT: ${order['trang_thai_thanh_toan'] ?? 'N/A'}', style: TextStyle(fontSize: 13)),
                                                   ],
                                                );
                                           } else {
                                               return Row(
                                                 children: [
                                                     Expanded(
                                                         flex: 1,
                                                          child: Text('Tổng tiền: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ', decimalDigits: 0).format(order['tong_thanh_toan'] ?? 0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                                                     Expanded(
                                                          flex: 1,
                                                          child: Text('TT TT: ${order['trang_thai_thanh_toan'] ?? 'N/A'}', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                                                 ],
                                               );
                                           }
                                        }
                                     ),
                                     const SizedBox(height: 4),

                                     LayoutBuilder(
                                        builder: (context, constraints) {
                                           if (constraints.maxWidth < 350) {
                                                return Column(
                                                   crossAxisAlignment: CrossAxisAlignment.start,
                                                   children: [
                                                       Text('Đặt hàng: ${orderDate != null ? dateFormat.format(orderDate.toLocal()) : 'N/A'}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                                        Text('Cập nhật: ${updatedDate != null ? dateFormat.format(updatedDate.toLocal()) : 'N/A'}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                                   ],
                                                );
                                           } else {
                                               return Row(
                                                 children: [
                                                     Expanded(
                                                         flex: 1,
                                                          child: Text('Đặt hàng: ${orderDate != null ? dateFormat.format(orderDate.toLocal()) : 'N/A'}', style: TextStyle(fontSize: 12, color: Colors.grey[700]), overflow: TextOverflow.ellipsis)),
                                                     Expanded(
                                                          flex: 1,
                                                         child: Text('Cập nhật: ${updatedDate != null ? dateFormat.format(updatedDate.toLocal()) : 'N/A'}', style: TextStyle(fontSize: 12, color: Colors.grey[700]), overflow: TextOverflow.ellipsis)),
                                                 ],
                                               );
                                           }
                                        }
                                     ),

                                 ],
                               ),
                             ),
                          ),
                        );
                      },
                   ),

        const SizedBox(height: 20),

         if (_orderData.isNotEmpty)
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
                'Hiển thị ${paginatedFilteredData.isEmpty ? 0 : (_currentPage * _rowsPerPage) + 1} - ${(_currentPage * _rowsPerPage) + paginatedFilteredData.length} trên ${totalFilteredItems}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_left),
                    onPressed: _currentPage > 0 && totalFilteredItems > 0
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
                      '${_currentPage + 1} / ${totalFilteredPages > 0 ? totalFilteredPages : 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_right),
                    onPressed: _currentPage < totalFilteredPages - 1 && totalFilteredItems > 0
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
