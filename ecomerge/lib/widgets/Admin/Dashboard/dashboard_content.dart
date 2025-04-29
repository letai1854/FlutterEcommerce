import 'package:flutter/material.dart';
import 'package:e_commerce_app/widgets/Admin/Dashboard/charts/bar_chart_widget.dart';
import 'package:e_commerce_app/widgets/Admin/Dashboard/charts/line_chart_widget.dart';
import 'package:e_commerce_app/widgets/Admin/Dashboard/charts/pie_chart_widget.dart';

class DashboardContent extends StatefulWidget {
  const DashboardContent({Key? key}) : super(key: key);

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  String _selectedTimeRange = 'Năm';

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
                    'Sản phẩm bán chạy nhất',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
                    child: BarChartWidget(
                      // Sample data - in production this would be passed in
                      data: const [
                        ('Sản phẩm A', 150),
                        ('Sản phẩm B', 120),
                        ('Sản phẩm C', 100),
                        ('Sản phẩm D', 80),
                        ('Sản phẩm E', 70),
                        ('Sản phẩm F', 50),
                        ('Sản phẩm G', 30),
                      ],
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
                      // Date range picker button
                      ActionChip(
                        avatar: const Icon(Icons.date_range, size: 16),
                        label: const Text('Tùy chỉnh'),
                        onPressed: () {
                          // Show date range picker
                        },
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

  // Build filter chip widget
  Widget _buildFilterChip(String label) {
    final isSelected = _selectedTimeRange == label;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        setState(() {
          _selectedTimeRange = label;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.blue[100],
    );
  }

  // Build sales statistics cards
  Widget _buildSalesStatsCards(bool isMobile, bool isTablet) {
    if (isMobile) {
      return Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch, // Make children stretch to full width
        children: [
          SizedBox(
            width: double.infinity, // Ensure full width
            child: _buildSalesStatCard('Đơn hàng đã bán', '2,543'),
          ),
          SizedBox(
            width: double.infinity, // Ensure full width
            child: _buildSalesStatCard('Tổng doanh thu', '₫1,256,000,000'),
          ),
          SizedBox(
            width: double.infinity, // Ensure full width
            child: _buildSalesStatCard('Tổng lợi nhuận', '₫358,000,000'),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(child: _buildSalesStatCard('Đơn hàng đã bán', '2,543')),
          Expanded(
              child: _buildSalesStatCard('Tổng doanh thu', '₫1,256,000,000')),
          Expanded(
              child: _buildSalesStatCard('Tổng lợi nhuận', '₫358,000,000')),
        ],
      );
    }
  }

  // Modify the card to use minimal horizontal margin when in mobile view
  Widget _buildSalesStatCard(String title, String value) {
    final isMobile = MediaQuery.of(context).size.width <= 650;

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 2.0 : 8.0, // Reduce horizontal margins on mobile
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

  // Build charts section
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

  // Build individual chart card
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
