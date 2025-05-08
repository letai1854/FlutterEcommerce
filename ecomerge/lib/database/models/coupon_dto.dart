import 'dart:convert';

class OrderSummaryDTO {
  final int orderId;
  final double orderValue; // Using double for BigDecimal

  OrderSummaryDTO({
    required this.orderId,
    required this.orderValue,
  });

  factory OrderSummaryDTO.fromJson(Map<String, dynamic> json) {
    return OrderSummaryDTO(
      orderId: json['orderId'] as int,
      orderValue: (json['orderValue'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'orderValue': orderValue,
    };
  }
}

class CouponResponseDTO {
  final int? id;
  final String code;
  final double discountValue; // Using double for BigDecimal
  final String? discountType; // Added: e.g., "PERCENTAGE", "FIXED_AMOUNT"
  final double? minOrderValue; // Added
  final String? description; // Added
  final DateTime? startDate; // Added
  final DateTime? endDate; // Added
  final int maxUsageCount;
  final int usageCount;
  final DateTime? createdDate;
  final List<OrderSummaryDTO>? orders;

  CouponResponseDTO({
    this.id,
    required this.code,
    required this.discountValue,
    this.discountType,
    this.minOrderValue,
    this.description,
    this.startDate,
    this.endDate,
    required this.maxUsageCount,
    required this.usageCount,
    this.createdDate,
    this.orders,
  });

  factory CouponResponseDTO.fromJson(Map<String, dynamic> json) {
    var ordersList = json['orders'] as List<dynamic>?;
    List<OrderSummaryDTO>? parsedOrders;
    if (ordersList != null) {
      parsedOrders = ordersList
          .map((i) => OrderSummaryDTO.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    return CouponResponseDTO(
      id: json['id'] as int?,
      code: json['code'] as String,
      discountValue: (json['discountValue'] as num).toDouble(),
      discountType: json['discountType'] as String?,
      minOrderValue: (json['minOrderValue'] as num?)?.toDouble(),
      description: json['description'] as String?,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      maxUsageCount: json['maxUsageCount'] as int,
      usageCount: json['usageCount'] as int,
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'] as String)
          : null,
      orders: parsedOrders,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'discountValue': discountValue,
      'discountType': discountType,
      'minOrderValue': minOrderValue,
      'description': description,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'maxUsageCount': maxUsageCount,
      'usageCount': usageCount,
      'createdDate': createdDate?.toIso8601String(),
      'orders': orders?.map((o) => o.toJson()).toList(),
    };
  }
}

class CreateCouponRequestDTO {
  final String code;
  final double discountValue;
  final int maxUsageCount;
  // Assuming createdDate is set by the server and usageCount starts at 0.

  CreateCouponRequestDTO({
    required this.code,
    required this.discountValue,
    required this.maxUsageCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'discountValue': discountValue,
      'maxUsageCount': maxUsageCount,
    };
  }
}
