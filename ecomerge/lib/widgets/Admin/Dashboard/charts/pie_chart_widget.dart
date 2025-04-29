import 'package:flutter/material.dart';

class PieChartWidget extends StatelessWidget {
  const PieChartWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This is a placeholder for a real pie chart implementation
    // In a real app, you would use a chart library like fl_chart, charts_flutter, etc.
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pie_chart,
              size: 48,
              color: Colors.orange,
            ),
            const SizedBox(height: 8),
            Text(
              'Pie Chart Placeholder',
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Phân bổ sản phẩm sẽ hiển thị ở đây',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
