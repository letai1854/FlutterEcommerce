import 'package:flutter/material.dart';
import 'package:e_commerce_app/services/admin_dashboard_service.dart';
import 'package:intl/intl.dart';

class DashboardStatsRow extends StatefulWidget {
  const DashboardStatsRow({Key? key}) : super(key: key);

  @override
  State<DashboardStatsRow> createState() => _DashboardStatsRowState();
}

class _DashboardStatsRowState extends State<DashboardStatsRow> {
  final AdminDashboardService _dashboardService = AdminDashboardService();
  AdminDashboardSummaryDTO? _summaryData;
  bool _isLoading = true;
  String? _error;

  final _compactFormatter = NumberFormat.compact(locale: 'vi_VN');
  final _percentFormatter = NumberFormat.percentPattern('vi_VN');

  @override
  void initState() {
    super.initState();
    _fetchSummaryData();
  }

  Future<void> _fetchSummaryData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final summary = await _dashboardService.getDashboardSummary();
      if (mounted) {
        setState(() {
          _summaryData = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Lỗi tải dữ liệu tóm tắt';
          _isLoading = false;
        });
      }
      print("Error fetching summary data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }
    if (_summaryData == null) {
      return const Center(child: Text('Không có dữ liệu tóm tắt.'));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 650;
    final isTablet = screenWidth > 650 && screenWidth <= 1100;

    String revenueChangeText = 'N/A';
    if (_summaryData!.revenuePercentageChangeLast7Days != null) {
      final value = _summaryData!.revenuePercentageChangeLast7Days!;
      revenueChangeText = (value > 0 ? '+' : '') + _percentFormatter.format(value);
    }

    // Responsive layout for different screen sizes
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      'Tổng người dùng',
                      _compactFormatter.format(_summaryData!.totalUsers),
                      Colors.blue,
                      Icons.people)),
              Expanded(
                  child: _buildStatCard(
                      'Người dùng mới (7 ngày)',
                      '+${_compactFormatter.format(_summaryData!.newUsersLast7Days)}',
                      Colors.green,
                      Icons.person_add)),
            ],
          ),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      'Tổng đơn hàng',
                       _compactFormatter.format(_summaryData!.totalOrders),
                      Colors.orange,
                      Icons.shopping_cart)),
              Expanded(
                  child: _buildStatCard(
                      'Tăng trưởng DT (7 ngày)',
                      revenueChangeText,
                      Colors.purple,
                      Icons.trending_up)),
            ],
          ),
        ],
      );
    }
    // Tablet layout - 2x2 grid
    else if (isTablet) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      'Tổng người dùng',
                      _compactFormatter.format(_summaryData!.totalUsers),
                      Colors.blue,
                      Icons.people)),
              Expanded(
                  child: _buildStatCard(
                      'Người dùng mới (7 ngày)',
                      '+${_compactFormatter.format(_summaryData!.newUsersLast7Days)}',
                      Colors.green,
                      Icons.person_add)),
            ],
          ),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      'Tổng đơn hàng',
                      _compactFormatter.format(_summaryData!.totalOrders),
                      Colors.orange,
                      Icons.shopping_cart)),
              Expanded(
                  child: _buildStatCard(
                      'Tăng trưởng DT (7 ngày)',
                      revenueChangeText,
                      Colors.purple,
                      Icons.trending_up)),
            ],
          ),
        ],
      );
    }
    // Desktop layout - row of 4 cards
    else {
      return Row(
        children: [
          Expanded(
              child: _buildStatCard(
                  'Tổng người dùng',
                  _compactFormatter.format(_summaryData!.totalUsers),
                  Colors.blue,
                  Icons.people)),
          Expanded(
              child: _buildStatCard(
                  'Người dùng mới (7 ngày)',
                  '+${_compactFormatter.format(_summaryData!.newUsersLast7Days)}',
                  Colors.green,
                  Icons.person_add)),
          Expanded(
              child: _buildStatCard(
                  'Tổng đơn hàng',
                  _compactFormatter.format(_summaryData!.totalOrders),
                  Colors.orange,
                  Icons.shopping_cart)),
          Expanded(
              child: _buildStatCard(
                  'Tăng trưởng DT (7 ngày)',
                  revenueChangeText,
                  Colors.purple,
                  Icons.trending_up)),
        ],
      );
    }
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
