import 'package:flutter/material.dart';
import 'package:e_commerce_app/widgets/Admin/Dashboard/charts/bar_chart_widget.dart';
import 'package:e_commerce_app/widgets/Admin/Dashboard/charts/line_chart_widget.dart';
import 'package:e_commerce_app/widgets/Admin/Dashboard/charts/pie_chart_widget.dart';
import 'package:e_commerce_app/services/admin_dashboard_service.dart';
import 'package:intl/intl.dart';

class DashboardContent extends StatefulWidget {
  const DashboardContent({Key? key}) : super(key: key);

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final AdminDashboardService _dashboardService = AdminDashboardService();
  String _selectedTimeRange = 'Năm'; // Default time range

  AdminSalesStatisticsDTO? _salesStatistics;
  List<ProductSalesDTO> _topProducts = [];

  bool _isLoadingSales = true;
  bool _isLoadingTopProducts = true;
  String? _salesError;
  String? _topProductsError;

  DateTimeRange? _customDateRange;

  final _currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  final _compactFormatter = NumberFormat.compact(locale: 'vi_VN');

  @override
  void initState() {
    super.initState();
    _fetchTopProducts();
    _fetchSalesDataForSelectedRange();
  }

  Future<void> _fetchTopProducts() async {
    try {
      setState(() {
        _isLoadingTopProducts = true;
        _topProductsError = null;
      });
      final summary = await _dashboardService.getDashboardSummary();
      if (mounted) {
        setState(() {
          _topProducts = summary?.topSellingProductsLast7Days ?? [];
          _isLoadingTopProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _topProductsError = 'Lỗi tải sản phẩm bán chạy';
          _isLoadingTopProducts = false;
        });
      }
      print("Error fetching top products: $e");
    }
  }

  Future<void> _fetchSalesDataForSelectedRange() async {
    setState(() {
      _isLoadingSales = true;
      _salesError = null;
    });

    DateTimeRange range = _getDateTimeRangeForString(_selectedTimeRange);
    if (_selectedTimeRange == 'Tùy chỉnh' && _customDateRange != null) {
      range = _customDateRange!;
    } else if (_selectedTimeRange == 'Tùy chỉnh' && _customDateRange == null) {
      setState(() {
        _isLoadingSales = false;
        _salesStatistics = null;
      });
      return;
    }

    try {
      final stats = await _dashboardService.getSalesStatistics(range.start, range.end);
      if (mounted) {
        setState(() {
          _salesStatistics = stats;
          _isLoadingSales = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _salesError = 'Lỗi tải thống kê doanh thu';
          _isLoadingSales = false;
        });
      }
      print("Error fetching sales statistics: $e");
    }
  }

  DateTimeRange _getDateTimeRangeForString(String rangeLabel) {
    final now = DateTime.now();
    switch (rangeLabel) {
      case 'Năm':
        return DateTimeRange(
            start: DateTime(now.year, 1, 1),
            end: DateTime(now.year, 12, 31, 23, 59, 59));
      case 'Quý':
        int currentQuarter = ((now.month - 1) / 3).floor() + 1;
        DateTime quarterStart;
        DateTime quarterEnd;
        if (currentQuarter == 1) {
          quarterStart = DateTime(now.year, 1, 1);
          quarterEnd = DateTime(now.year, 3, 31, 23, 59, 59);
        } else if (currentQuarter == 2) {
          quarterStart = DateTime(now.year, 4, 1);
          quarterEnd = DateTime(now.year, 6, 30, 23, 59, 59);
        } else if (currentQuarter == 3) {
          quarterStart = DateTime(now.year, 7, 1);
          quarterEnd = DateTime(now.year, 9, 30, 23, 59, 59);
        } else {
          quarterStart = DateTime(now.year, 10, 1);
          quarterEnd = DateTime(now.year, 12, 31, 23, 59, 59);
        }
        return DateTimeRange(start: quarterStart, end: quarterEnd);
      case 'Tháng':
        return DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: DateTime(now.year, now.month + 1, 0, 23, 59, 59));
      case 'Tuần':
        return DateTimeRange(
            start: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6)),
            end: DateTime(now.year, now.month, now.day, 23, 59, 59));
      default:
        return DateTimeRange(
            start: DateTime(now.year, 1, 1),
            end: DateTime(now.year, 12, 31, 23, 59, 59));
    }
  }

  Future<void> _showCustomDateRangePicker() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
    );
    if (picked != null) {
      setState(() {
        _customDateRange = DateTimeRange(
          start: DateTime(picked.start.year, picked.start.month, picked.start.day),
          end: DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
        );
        _selectedTimeRange = 'Tùy chỉnh';
      });
      _fetchSalesDataForSelectedRange();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 650;
    final isTablet = screenWidth > 650 && screenWidth <= 1100;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top products chart
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sản phẩm bán chạy nhất (7 ngày qua)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
                    child: _isLoadingTopProducts
                        ? const Center(child: CircularProgressIndicator())
                        : _topProductsError != null
                            ? Center(
                                child: Text(
                                  _topProductsError!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              )
                            : BarChartWidget(
                                data: _topProducts
                                    .map((p) => (p.productName, p.quantitySold))
                                    .toList(),
                              ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Time range selector
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thống kê theo thời gian',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filter chips
                  Wrap(
                    spacing: 8.0,
                    children: [
                      _buildFilterChip('Năm'),
                      _buildFilterChip('Quý'),
                      _buildFilterChip('Tháng'),
                      _buildFilterChip('Tuần'),
                      ActionChip(
                        avatar: const Icon(Icons.date_range, size: 16),
                        label: Text(
                          _customDateRange != null &&
                                  _selectedTimeRange == 'Tùy chỉnh'
                              ? '${DateFormat('dd/MM/yy').format(_customDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_customDateRange!.end)}'
                              : 'Tùy chỉnh',
                        ),
                        onPressed: _showCustomDateRangePicker,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Sales statistics cards
          _buildSalesStatsCards(isMobile, isTablet),

          const SizedBox(height: 20),

          // Charts - responsive layout
          _buildChartsSection(isMobile, isTablet),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedTimeRange == label;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedTimeRange = label;
            if (label != 'Tùy chỉnh') {
              _customDateRange = null;
            }
          });
          if (label == 'Tùy chỉnh' && _customDateRange == null) {
            _showCustomDateRangePicker();
          } else {
            _fetchSalesDataForSelectedRange();
          }
        }
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.blue[100],
    );
  }

  Widget _buildSalesStatsCards(bool isMobile, bool isTablet) {
    Widget content;
    if (_isLoadingSales) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_salesError != null) {
      content = Center(
          child: Text(_salesError!, style: const TextStyle(color: Colors.red)));
    } else if (_salesStatistics == null) {
      content = const Center(
          child: Text('Không có dữ liệu doanh thu cho khoảng thời gian này.'));
    } else {
      final stats = _salesStatistics!;
      final cards = [
        Expanded(
            child: _buildSalesStatCard(
                'Đơn hàng đã bán',
                _compactFormatter.format(stats.totalOrdersInRange))),
        Expanded(
            child: _buildSalesStatCard(
                'Tổng doanh thu',
                _currencyFormatter.format(stats.totalRevenueInRange))),
        Expanded(
            child: _buildSalesStatCard(
                'Sản phẩm đã bán',
                _compactFormatter.format(stats.totalItemsSoldInRange))),
      ];

      if (isMobile) {
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: cards
              .map((e) => SizedBox(width: double.infinity, child: e.child))
              .toList(),
        );
      } else {
        content = Row(children: cards);
      }
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      child: content,
    );
  }

  Widget _buildSalesStatCard(String title, String value) {
    final isMobile = MediaQuery.of(context).size.width <= 650;

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 2.0 : 8.0,
        vertical: 8.0,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(bool isMobile, bool isTablet) {
    if (isMobile) {
      return Column(
        children: [
          _buildChartCard('Doanh thu theo thời gian', const LineChartWidget()),
          _buildChartCard('Lợi nhuận theo thời gian', const LineChartWidget()),
          _buildChartCard('Phân bổ sản phẩm', const PieChartWidget()),
        ],
      );
    } else if (isTablet) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildChartCard(
                      'Doanh thu theo thời gian', const LineChartWidget())),
              Expanded(
                  child: _buildChartCard(
                      'Lợi nhuận theo thời gian', const LineChartWidget())),
            ],
          ),
          _buildChartCard('Phân bổ sản phẩm', const PieChartWidget()),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
              child: _buildChartCard(
                  'Doanh thu theo thời gian', const LineChartWidget())),
          Expanded(
              child: _buildChartCard(
                  'Lợi nhuận theo thời gian', const LineChartWidget())),
          Expanded(
              child:
                  _buildChartCard('Phân bổ sản phẩm', const PieChartWidget())),
        ],
      );
    }
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: chart,
            ),
          ],
        ),
      ),
    );
  }
}
