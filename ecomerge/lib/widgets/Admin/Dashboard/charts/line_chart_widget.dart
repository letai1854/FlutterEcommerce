import 'package:flutter/material.dart';
import 'package:e_commerce_app/services/admin_dashboard_service.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart

class LineChartWidget extends StatelessWidget {
  final List<TimeSeriesDataPointDTO> data;
  final String chartTitle;

  const LineChartWidget({
    Key? key,
    required this.data,
    required this.chartTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'Không có dữ liệu cho "$chartTitle".',
          style: TextStyle(color: Colors.grey[700]),
          textAlign: TextAlign.center,
        ),
      );
    }

    List<FlSpot> spots = data.asMap().entries.map((entry) {
      // Using index for x to simplify, actual date can be shown in tooltip/titles
      // Alternatively, use millisecondsSinceEpoch for x if time scale is critical
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    double minY = 0;
    double maxY = 0;
    if (spots.isNotEmpty) {
      minY = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
      maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
      if (minY > 0) minY = 0; // Ensure Y axis starts from 0 if all values are positive
      maxY = maxY * 1.1; // Add some padding to the top
      if (maxY == 0) maxY = 10; // Handle case where all values are 0
    }


    return Padding(
      padding: const EdgeInsets.only(right: 18.0, top: 10.0, bottom: 10.0),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) {
              return const FlLine(
                color: Colors.grey,
                strokeWidth: 0.2,
              );
            },
            getDrawingVerticalLine: (value) {
              return const FlLine(
                color: Colors.grey,
                strokeWidth: 0.2,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: data.length > 7 ? (data.length / 7).roundToDouble() : 1, // Show fewer labels if too many points
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < data.length) {
                    // Show date for the first, last, and some intermediate points
                    if (index == 0 || index == data.length -1 || (data.length > 7 && index % ((data.length / 5).ceil()) == 0) ) {
                       return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 8.0,
                        child: Text(
                            DateFormat('dd/MM').format(data[index].date),
                            style: const TextStyle(fontSize: 10)
                        ),
                      );
                    }
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    NumberFormat.compact().format(value),
                    style: const TextStyle(fontSize: 10),
                    textAlign: TextAlign.left,
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.2),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final flSpot = barSpot;
                  if (flSpot.spotIndex < 0 || flSpot.spotIndex >= data.length) {
                    return null;
                  }
                  final pointData = data[flSpot.spotIndex];
                  return LineTooltipItem(
                    '${DateFormat('dd/MM/yyyy').format(pointData.date)}\n',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    children: <TextSpan>[
                      TextSpan(
                        text: NumberFormat.decimalPattern().format(pointData.value),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
