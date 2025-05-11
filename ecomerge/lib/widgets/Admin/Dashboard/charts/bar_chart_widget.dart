import 'package:flutter/material.dart';

class BarChartWidget extends StatelessWidget {
  final List<(String, int)> data;

  const BarChartWidget({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'Không có dữ liệu để hiển thị.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      );
    }

    // Find the max value for scaling
    final maxValue =
        data.map((item) => item.$2).reduce((a, b) => a > b ? a : b);

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth / (data.length * 2);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: data.map((item) {
            final barHeight =
                constraints.maxHeight * (item.$2 / maxValue) * 0.8;

            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Value on top of the bar
                Text(
                  item.$2.toString(),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                // The bar itself
                Container(
                  width: barWidth,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                // Product name below the bar
                SizedBox(
                  width: barWidth * 1.5,
                  child: Text(
                    item.$1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}
