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
  final int maxUsageCount;
  final int usageCount;
  final DateTime? createdDate;
  final List<OrderSummaryDTO>? orders; // Added orders list

  CouponResponseDTO({
    this.id,
    required this.code,
    required this.discountValue,
    required this.maxUsageCount,
    required this.usageCount,
    this.createdDate,
    this.orders, // Added to constructor
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
      maxUsageCount: json['maxUsageCount'] as int,
      usageCount: json['usageCount'] as int,
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'] as String)
          : null,
      orders: parsedOrders, // Assign parsed orders
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'discountValue': discountValue,
      'maxUsageCount': maxUsageCount,
      'usageCount': usageCount,
      'createdDate': createdDate?.toIso8601String(),
      'orders': orders?.map((o) => o.toJson()).toList(), // Serialize orders
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
