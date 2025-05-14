import 'dart:convert';
import 'dart:io';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/database/database_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:intl/intl.dart';

// DTOs
class ProductSalesDTO {
  final String productName;
  final int quantitySold;

  ProductSalesDTO({
    required this.productName,
    required this.quantitySold,
  });

  factory ProductSalesDTO.fromJson(Map<String, dynamic> json) {
    return ProductSalesDTO(
      productName: json['productName'] ?? 'Unknown Product',
      quantitySold: (json['quantitySold'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminDashboardSummaryDTO {
  final int totalUsers;
  final int newUsersLast7Days;
  final int totalOrders;
  final double? revenuePercentageChangeLast7Days;
  final List<ProductSalesDTO> topSellingProductsLast7Days;

  AdminDashboardSummaryDTO({
    required this.totalUsers,
    required this.newUsersLast7Days,
    required this.totalOrders,
    this.revenuePercentageChangeLast7Days,
    required this.topSellingProductsLast7Days,
  });

  factory AdminDashboardSummaryDTO.fromJson(Map<String, dynamic> json) {
    return AdminDashboardSummaryDTO(
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      newUsersLast7Days: (json['newUsersLast7Days'] as num?)?.toInt() ?? 0,
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      revenuePercentageChangeLast7Days: (json['revenuePercentageChangeLast7Days'] as num?)?.toDouble(),
      topSellingProductsLast7Days: (json['topSellingProductsLast7Days'] as List<dynamic>?)
              ?.map((e) => ProductSalesDTO.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class AdminSalesStatisticsDTO {
  final int totalOrdersInRange;
  final double totalRevenueInRange;
  final int totalItemsSoldInRange;

  AdminSalesStatisticsDTO({
    required this.totalOrdersInRange,
    required this.totalRevenueInRange,
    required this.totalItemsSoldInRange,
  });

  factory AdminSalesStatisticsDTO.fromJson(Map<String, dynamic> json) {
    return AdminSalesStatisticsDTO(
      totalOrdersInRange: (json['totalOrdersInRange'] as num?)?.toInt() ?? 0,
      totalRevenueInRange: (json['totalRevenueInRange'] as num?)?.toDouble() ?? 0.0,
      totalItemsSoldInRange: (json['totalItemsSoldInRange'] as num?)?.toInt() ?? 0,
    );
  }
}

class TimeSeriesDataPointDTO {
  final DateTime date;
  final double value;

  TimeSeriesDataPointDTO({required this.date, required this.value});

  factory TimeSeriesDataPointDTO.fromJson(Map<String, dynamic> json) {
    return TimeSeriesDataPointDTO(
      date: DateTime.parse(json['date'] as String),
      value: (json['value'] as num).toDouble(),
    );
  }
}

class ChartDataDTO {
  final List<TimeSeriesDataPointDTO> revenueOverTime;
  final List<TimeSeriesDataPointDTO> ordersOverTime;
  final List<TimeSeriesDataPointDTO> productsSoldOverTime;

  ChartDataDTO({
    required this.revenueOverTime,
    required this.ordersOverTime,
    required this.productsSoldOverTime,
  });

  factory ChartDataDTO.fromJson(Map<String, dynamic> json) {
    return ChartDataDTO(
      revenueOverTime: (json['revenueOverTime'] as List)
          .map((item) => TimeSeriesDataPointDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
      ordersOverTime: (json['ordersOverTime'] as List)
          .map((item) => TimeSeriesDataPointDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
      productsSoldOverTime: (json['productsSoldOverTime'] as List)
          .map((item) => TimeSeriesDataPointDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AdminDashboardService {
  final String _baseUrl = baseurl;
  late final http.Client _httpClient;

  AdminDashboardService() {
    _httpClient = _createSecureClient();
  }

  http.Client _createSecureClient() {
    if (kIsWeb) {
      return http.Client();
    } else {
      final HttpClient ioClient = HttpClient()
        ..badCertificateCallback =
            ((X509Certificate cert, String host, int port) => true);
      return IOClient(ioClient);
    }
  }

  Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    final userInfo = UserInfo();
    if (userInfo.authToken != null) {
      headers['Authorization'] = 'Bearer ${userInfo.authToken}';
    }
    return headers;
  }

  Future<AdminDashboardSummaryDTO?> getDashboardSummary() async {
    final url = Uri.parse('$_baseUrl/api/admin/dashboard/summary');
    try {
      final response = await _httpClient.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        return AdminDashboardSummaryDTO.fromJson(jsonDecode(response.body));
      } else {
        print('Failed to load dashboard summary: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching dashboard summary: $e');
      return null;
    }
  }

  Future<AdminSalesStatisticsDTO?> getSalesStatistics(
      DateTime startDate, DateTime endDate) async {
    final url = Uri.parse('$_baseUrl/api/admin/dashboard/sales').replace(queryParameters: {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    });
    try {
      final response = await _httpClient.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        return AdminSalesStatisticsDTO.fromJson(jsonDecode(response.body));
      } else {
        print('Failed to load sales statistics: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching sales statistics: $e');
      return null;
    }
  }

  Future<ChartDataDTO?> getChartData(DateTime startDate, DateTime endDate) async {
    final url = Uri.parse('$_baseUrl/api/admin/dashboard/chart-data').replace(queryParameters: {
      'startDate': DateFormat('yyyy-MM-dd').format(startDate),
      'endDate': DateFormat('yyyy-MM-dd').format(endDate),
    });

    print("Fetching chart data from $url");

    try {
      final response = await _httpClient.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return ChartDataDTO.fromJson(decoded);
      } else {
        print('Failed to load chart data: ${response.statusCode} ${response.body}');
        return null; // Or throw an exception
      }
    } catch (e) {
      print('Error fetching chart data: $e');
      return null; // Or throw an exception
    }
  }
}
