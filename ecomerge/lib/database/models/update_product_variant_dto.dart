import 'package:flutter/foundation.dart';

class UpdateProductVariantDTO {
  final int? id; // ID của biến thể cần cập nhật (Integer ở server -> int? ở Dart). Null nếu là biến thể mới thêm.
  final String name;
  final String? sku; // SKU có thể null
  final double price; // Changed from BigDecimal to double. Required.
  final int stockQuantity; // Changed from Integer to int. Required.
  final String? variantImageUrl; // URL ảnh biến thể (có thể null)

  UpdateProductVariantDTO({
    this.id, // ID là optional
    required this.name, // Required
    this.sku, // Optional
    required this.price, // Required
    required this.stockQuantity, // Required
    this.variantImageUrl, // Optional
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'price': price,
      'stockQuantity': stockQuantity,
      'variantImageUrl': variantImageUrl,
    };
  }

  factory UpdateProductVariantDTO.fromJson(Map<String, dynamic> json) {
    return UpdateProductVariantDTO(
      id: json['id'] as int?,
      name: json['name'] as String,
      sku: json['sku'] as String?,
      price: (json['price'] as num).toDouble(),
      stockQuantity: json['stockQuantity'] as int,
      variantImageUrl: json['variantImageUrl'] as String?,
    );
  }
}
