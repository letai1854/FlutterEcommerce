import 'package:e_commerce_app/Screens/Admin/discount/AddDiscountScreen.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart'; // For date formatting
import 'package:flutter/foundation.dart'; // For kIsWeb


// Import dart:io if needed for image display (though typically not for discount list/detail)
// import 'dart:io';


class DiscountScreen extends StatefulWidget {
  const DiscountScreen({Key? key}) : super(key: key);

  @override
  _DiscountScreenState createState() => _DiscountScreenState();
}

class _DiscountScreenState extends State<DiscountScreen> {
  String _selectedFilter = 'Tất cả';
  final List<String> _filterOptions = [
    'Tất cả', 'Hôm nay', 'Hôm qua', 'Tuần này', 'Tháng này', 'Khoảng thời gian cụ thể',
  ];

  DateTimeRange? _customDateRange;

  // Variables for pagination
  int _currentPage = 0;
  final int _rowsPerPage = 20; // Set to 20 items per page

  // Sample data matching the schema concepts
  // Includes dummy applied orders data
  late final List<Map<String, dynamic>> _discountData;

  @override
  void initState() {
    super.initState();
    // Initialize sample data here
    _discountData = List.generate(
      35, // Generate enough data to test pagination
      (index) {
        final discountValue = [10000.0, 20000.0, 50000.0, 100000.0][index % 4];
        final maxUsage = (index % 10) + 1; // Max usage 1 to 10
        final usedCount = min(maxUsage, index % 12); // Used count <= max usage

        // Simulate some orders that used this discount
        final appliedOrders = List.generate(
            usedCount,
             (orderIndex) => {
               'order_id': 'ORDER${1000 + index * 10 + orderIndex}',
               'tong_thanh_toan': (discountValue * 5) + (orderIndex * 10000.0), // Dummy total
               'ngay_dat_hang': DateTime.now().subtract(Duration(days: index + orderIndex)),
             }
           );


        return {
          'id': index + 1,
          'ma_code': 'CODE${index.toString().padLeft(3, '0')}', // Simple code
          'gia_tri_giam': discountValue,
          'so_lan_su_dung_toi_da': maxUsage,
          'so_lan_da_su_dung': usedCount,
          'ngay_tao': DateTime.now().subtract(Duration(days: index * 5)), // Older codes first for sorting test
          'applied_orders': appliedOrders, // List of orders that used this discount
        };
      },
    );

    // Sort data by creation date, newest first as requested
    _discountData.sort((a, b) => (b['ngay_tao'] as DateTime).compareTo(a['ngay_tao'] as DateTime));
  }

   // Get filtered and paginated data
   List<Map<String, dynamic>> get _filteredAndPaginatedData {
        // First, apply filtering based on creation date
        List<Map<String, dynamic>> filteredData = _discountData;

        if (_selectedFilter == 'Khoảng thời gian cụ thể' && _customDateRange != null) {
            filteredData = _discountData.where((discount) {
                final createDate = discount['ngay_tao'] as DateTime;
                 // Check if createDate is within the selected range (inclusive of start and end days)
                return createDate.isAfter(_customDateRange!.start.subtract(const Duration(seconds: 1)))
                       && createDate.isBefore(_customDateRange!.end.add(const Duration(days: 1)).subtract(const Duration(seconds: 1))); // Check before start of NEXT day
            }).toList();
        } else if (_selectedFilter != 'Tất cả') {
            final now = DateTime.now();

            filteredData = _discountData.where((discount) {
                 final createDate = discount['ngay_tao'] as DateTime;
                 final startOfToday = DateTime(now.year, now.month, now.day);
                 final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999); // End of today

                 if (_selectedFilter == 'Hôm nay') {
                      return createDate.isAfter(startOfToday.subtract(const Duration(seconds: 1))) && createDate.isBefore(endOfToday.add(const Duration(seconds: 1)));
                 } else if (_selectedFilter == 'Hôm qua') {
                      final yesterday = now.subtract(const Duration(days: 1));
                      final startOfYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day);
                      final endOfYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59, 999);
                      return createDate.isAfter(startOfYesterday.subtract(const Duration(seconds: 1))) && createDate.isBefore(endOfYesterday.add(const Duration(seconds: 1)));
                 } else if (_selectedFilter == 'Tuần này') {
                     final startOfThisWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday
                     final startOfThisWeekMidnight = DateTime(startOfThisWeek.year, startOfThisWeek.month, startOfThisWeek.day);
                     return createDate.isAfter(startOfThisWeekMidnight.subtract(const Duration(seconds: 1))) && createDate.isBefore(endOfToday.add(const Duration(seconds: 1)));
                 } else if (_selectedFilter == 'Tháng này') {
                     final startOfThisMonth = DateTime(now.year, now.month, 1);
                     return createDate.isAfter(startOfThisMonth.subtract(const Duration(seconds: 1))) && createDate.isBefore(endOfToday.add(const Duration(seconds: 1)));
                 }
                 return true;
             }).toList();
        }

        // Then, apply pagination to the filtered data
        final startIndex = _currentPage * _rowsPerPage;
        // Ensure startIndex is within bounds of filtered data
        if (startIndex >= filteredData.length) {
             // If current page is now out of bounds after filtering/deletion, go to the last possible page
             if (filteredData.isNotEmpty) {
                 WidgetsBinding.instance.addPostFrameCallback((_) {
                     setState(() {
                         _currentPage = max(0, (_totalFilteredItems / _rowsPerPage).ceil() - 1); // Correctly calculate page based on total filtered items
                     });
                 });
             } else {
                 // If no filtered data, ensure page is 0
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                     setState(() {
                        _currentPage = 0;
                     });
                  });
             }
             return []; // Return empty list for now, setState will rebuild with correct page
        }

        final endIndex = min(startIndex + _rowsPerPage, filteredData.length);
        return filteredData.sublist(startIndex, endIndex);
   }

    // Get total number of items in the filtered data
   int get _totalFilteredItems {
       return _discountData.where((discount) {
           // Re-apply filter logic for the total count BEFORE pagination
           if (_selectedFilter == 'Khoảng thời gian cụ thể' && _customDateRange != null) {
               final createDate = discount['ngay_tao'] as DateTime;
                return createDate.isAfter(_customDateRange!.start.subtract(const Duration(seconds: 1)))
                       && createDate.isBefore(_customDateRange!.end.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)));
           } else if (_selectedFilter != 'Tất cả') {
               final now = DateTime.now();
               final createDate = discount['ngay_tao'] as DateTime;
               final startOfToday = DateTime(now.year, now.month, now.day);
               final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

               if (_selectedFilter == 'Hôm nay') {
                    return createDate.isAfter(startOfToday.subtract(const Duration(seconds: 1))) && createDate.isBefore(endOfToday.add(const Duration(seconds: 1)));
               } else if (_selectedFilter == 'Hôm qua') {
                    final yesterday = now.subtract(const Duration(days: 1));
                    final startOfYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day);
                    final endOfYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59, 999);
                    return createDate.isAfter(startOfYesterday.subtract(const Duration(seconds: 1))) && createDate.isBefore(endOfYesterday.add(const Duration(seconds: 1)));
               } else if (_selectedFilter == 'Tuần này') {
                   final startOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
                   final startOfThisWeekMidnight = DateTime(startOfThisWeek.year, startOfThisWeek.month, startOfThisWeek.day);
                   return createDate.isAfter(startOfThisWeekMidnight.subtract(const Duration(seconds: 1))) && createDate.isBefore(endOfToday.add(const Duration(seconds: 1)));
               } else if (_selectedFilter == 'Tháng này') {
                   final startOfThisMonth = DateTime(now.year, now.month, 1);
                   return createDate.isAfter(startOfThisMonth.subtract(const Duration(seconds: 1))) && createDate.isBefore(endOfToday.add(const Duration(seconds: 1)));
               }
               return true;
           }
           return true;
       }).length;
   }

  // Get total number of pages for filtered data
  int get _filteredPageCount {
       final totalItems = _totalFilteredItems;
       if (totalItems == 0) return 1;
       return (totalItems / _rowsPerPage).ceil();
   }


  void _showDateRangePicker() async {
    // Ensure locale is set in MaterialApp for this to work
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
       locale: const Locale('vi', 'VN'), // Set locale explicitly for clarity (though MaterialApp locale should apply)
    );
    if (picked != null && picked != _customDateRange) {
      setState(() {
        _customDateRange = picked;
        _selectedFilter = 'Khoảng thời gian cụ thể';
        _currentPage = 0; // Reset to first page on filter change
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

  // Function to show discount details in a dialog
  void _showDiscountDetailsDialog(Map<String, dynamic> discount) {
      final creationDate = discount['ngay_tao'] as DateTime?;
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
      final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ', decimalDigits: 0);

      showDialog(
          context: context,
          builder: (BuildContext context) {
              // Ensure applied_orders list is not null
              final List<Map<String, dynamic>> appliedOrders = List<Map<String, dynamic>>.from(discount['applied_orders'] ?? []);

              return AlertDialog(
                  title: Text('Chi tiết Mã giảm giá: ${discount['ma_code'] ?? 'N/A'}'),
                  content: SingleChildScrollView(
                      child: ListBody(
                          children: <Widget>[
                              Text('Mã code: ${discount['ma_code'] ?? 'N/A'}', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              Text('Giá trị giảm: ${currencyFormat.format(discount['gia_tri_giam'] ?? 0)}'),
                              Text('Đã sử dụng: ${discount['so_lan_da_su_dung'] ?? 0} / ${discount['so_lan_su_dung_toi_da'] ?? 'N/A'} lần'),
                              Text('Ngày tạo: ${creationDate != null ? dateFormat.format(creationDate.toLocal()) : 'N/A'}'),
                              SizedBox(height: 16),
                              Text('Đơn hàng đã áp dụng:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Divider(),
                              appliedOrders.isEmpty
                                  ? Text('Chưa có đơn hàng nào áp dụng mã này.')
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: appliedOrders.length,
                                      itemBuilder: (context, index) {
                                          final order = appliedOrders[index];
                                          final orderDate = order['ngay_dat_hang'] as DateTime?;
                                          return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                                              child: Text(
                                                  '- ĐH ${order['order_id'] ?? 'N/A'} (${currencyFormat.format(order['tong_thanh_toan'] ?? 0)}) - ${orderDate != null ? DateFormat('dd/MM/yyyy').format(orderDate.toLocal()) : 'N/A'}',
                                                   style: TextStyle(fontSize: 13),
                                              ),
                                          );
                                      },
                                  ),
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
                       // TODO: Add Edit button here if editing from dialog is desired
                       /*
                       TextButton(
                          child: Text('Sửa'),
                          onPressed: () {
                               Navigator.of(context).pop(); // Close dialog
                               // Navigate to AddDiscountScreen for editing
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => AddDiscountScreen(discount: discount),
                                    ),
                                    // .then() to refresh list after edit
                                ).then((_) => setState(() {}));
                          },
                       ),
                       */
                  ],
              );
          },
      );
  }


  @override
  Widget build(BuildContext context) {
    // No separate small/large layout function needed, build adapts responsively
    final double availableWidth = MediaQuery.of(context).size.width - 2 * 16.0; // Assuming padding 16 on both sides

    return Scaffold(
      // AppBar is usually provided by the AdminDesktop/AdminResponsive parent
      // If this screen is a standalone route, you might add an AppBar here.
      // Assuming it's part of the admin dashboard and doesn't need its own AppBar:
      // appBar: AppBar(title: Text('Quản lý mã giảm giá')), // Uncomment if standalone

      body: SingleChildScrollView( // Use SingleChildScrollView for the whole page content area
         child: Padding(
            padding: const EdgeInsets.all(16.0), // Add padding to the content area
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 // Title (if not in AppBar)
                 /*
                 Text(
                    'Quản lý mã giảm giá',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                 ),
                 const SizedBox(height: 20),
                 */

                 // --- Controls Area (Search, Filter, Add Button) ---
                 SizedBox( // Wrap controls in SizedBox to manage overall width if needed
                   width: availableWidth, // Or use a specific max width
                   child: Wrap( // Use Wrap for responsive layout of controls
                     spacing: 10,
                     runSpacing: 10,
                     crossAxisAlignment: WrapCrossAlignment.center,
                     children: [
                       // Search TextField
                       SizedBox( // Constrain search width
                         width: 250, // Example width
                         child: TextField(
                           decoration: const InputDecoration(
                             hintText: 'Tìm kiếm...',
                             border: OutlineInputBorder(),
                             contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                             isDense: true, // Reduce vertical space
                           ),
                           // TODO: Implement search logic based on user input
                         ),
                       ),

                       // Filter Dropdown
                       SizedBox( // Constrain filter width
                         width: 200, // Adjusted width
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
                                     _customDateRange = null; // Clear custom range if another filter is selected
                                     _currentPage = 0; // Reset to first page on filter change
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

                       // Add Button (Navigate to AddDiscountScreen)
                        ElevatedButton(
                           onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const AddDiscountScreen(), // Navigate to add screen
                                  ),
                              ).then((_) {
                                 // Optional: Refresh data after returning from add/edit screen
                                 // In a real app, you'd refetch data from backend here
                                 // For this sample, just trigger a rebuild
                                  setState(() {
                                      // Re-sort after potential new data
                                      _discountData.sort((a, b) => (b['ngay_tao'] as DateTime).compareTo(a['ngay_tao'] as DateTime));
                                      _currentPage = 0; // Go back to first page
                                  });
                              });
                           },
                           style: ElevatedButton.styleFrom(
                             padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                             textStyle: const TextStyle(fontSize: 14),
                             minimumSize: const Size(0, 48), // Match height of dropdown/textfield
                           ),
                           child: const Text('Thêm mã giảm giá'),
                        ),
                     ],
                   ),
                 ),
                 const SizedBox(height: 20),

                 // Header for the list section
                 Text(
                   'Danh sách mã giảm giá',
                   style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                 ),
                 const SizedBox(height: 10),

                 // Discount List (Responsive Rows)
                 _filteredAndPaginatedData.isEmpty && _totalFilteredItems > 0
                     ? const Center(child: Text('Không có mã giảm giá nào trên trang này.')) // Message for empty current page but items exist after filtering
                     : _filteredAndPaginatedData.isEmpty && _totalFilteredItems == 0
                         ? const Center(child: Text('Không có mã giảm giá nào được tìm thấy.')) // Message for no items after filtering
                         : ListView.builder(
                              shrinkWrap: true, // Make ListView only take needed space
                              physics: const NeverScrollableScrollPhysics(), // Disable ListView scrolling as SingleChildScrollView handles it
                              itemCount: _filteredAndPaginatedData.length,
                              itemBuilder: (context, index) {
                                final discount = _filteredAndPaginatedData[index];
                                final creationDate = discount['ngay_tao'] as DateTime?;
                                final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
                                final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ', decimalDigits: 0);


                                return Card(
                                   // Add a unique key for list items
                                   key: ValueKey(discount['id']),
                                   margin: const EdgeInsets.symmetric(vertical: 4),
                                   elevation: 2, // Add subtle shadow
                                   // Make the entire card tappable to view details
                                   child: InkWell(
                                      onTap: () {
                                          // Show details dialog
                                          _showDiscountDetailsDialog(discount);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0), // Add padding inside the card
                                        child: Column( // Use a Column for the main content of the card item
                                          crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start
                                          children: [
                                              // Mã giảm giá code
                                             Text(
                                               'Mã: ${discount['ma_code'] ?? 'N/A'}',
                                               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                             ),
                                             const SizedBox(height: 4), // Space between lines

                                              // Giá trị giảm
                                             Text(
                                               'Giá trị: ${currencyFormat.format(discount['gia_tri_giam'] ?? 0)}',
                                               style: const TextStyle(fontSize: 13),
                                             ),
                                             const SizedBox(height: 4),

                                              // Số lần sử dụng
                                             Text(
                                               'Đã sử dụng: ${discount['so_lan_da_su_dung'] ?? 0} / ${discount['so_lan_su_dung_toi_da'] ?? 'N/A'} lần',
                                               style: const TextStyle(fontSize: 13),
                                             ),
                                             const SizedBox(height: 4),

                                              // Ngày tạo
                                             Text(
                                                'Ngày tạo: ${creationDate != null ? dateFormat.format(creationDate.toLocal()) : 'N/A'}',
                                                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                             ),
                                             // Note: List of applied orders is shown in the details dialog
                                          ],
                                        ),
                                      ),
                                   ),
                                 );
                              },
                         ),

                 const SizedBox(height: 20), // Space before pagination

                 // Pagination controls
                 if (_discountData.isNotEmpty) // Only show pagination if there are any discounts initially
                   Container(
                     padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                     margin: const EdgeInsets.only(top: 8),
                     decoration: BoxDecoration(
                       color: Colors.grey[100],
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Column(
                       children: [
                         // Info text uses counts from the CURRENT FILTERED & PAGINATED list
                         Text(
                           // Correctly display range within the *filtered* dataset
                           'Hiển thị ${_filteredAndPaginatedData.isEmpty ? 0 : (_currentPage * _rowsPerPage) + 1} - ${(_currentPage * _rowsPerPage) + _filteredAndPaginatedData.length} trên ${_totalFilteredItems}', // Total items in the filtered data
                           style: TextStyle(color: Colors.grey[600]),
                         ),
                         const SizedBox(height: 8),

                         // Pagination buttons
                         Row(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             IconButton(
                               icon: const Icon(Icons.keyboard_arrow_left),
                               // Disable if on the first page (index 0) or no filtered items
                               onPressed: _currentPage > 0 && _totalFilteredItems > 0
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
                                 // Show page number and total pages (based on filtered items)
                                 '${_currentPage + 1} / ${_filteredPageCount > 0 ? _filteredPageCount : 1}', // Avoid division by zero
                                 style: const TextStyle(fontWeight: FontWeight.bold),
                               ),
                             ),
                             IconButton(
                               icon: const Icon(Icons.keyboard_arrow_right),
                               // Disable if on the last page or no filtered items
                               onPressed: _currentPage < _filteredPageCount - 1 && _totalFilteredItems > 0
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
                 const SizedBox(height: 24), // Space at the very bottom
              ],
            ),
         ),
      ),
    );
  }
}

// Removed DiscountDataSource class as DataTable is no longer used
