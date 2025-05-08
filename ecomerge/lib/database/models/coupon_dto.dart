import 'dart:convert';

class CouponResponseDTO {
  final int? id;
  final String code;
  final double discountValue; // Using double for BigDecimal
  final int maxUsageCount;
  final int usageCount;
  final DateTime? createdDate;

  CouponResponseDTO({
    this.id,
    required this.code,
    required this.discountValue,
    required this.maxUsageCount,
    required this.usageCount,
    this.createdDate,
  });

  factory CouponResponseDTO.fromJson(Map<String, dynamic> json) {
    return CouponResponseDTO(
      id: json['id'] as int?,
      code: json['code'] as String,
      discountValue: (json['discountValue'] as num).toDouble(),
      maxUsageCount: json['maxUsageCount'] as int,
      usageCount: json['usageCount'] as int,
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'] as String)
          : null,
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
