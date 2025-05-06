import 'package:flutter/foundation.dart';

class CreateProductVariantDTO {
  final String name;
  final String? sku;
  final double price; // Changed from BigDecimal to double
  final int stockQuantity; // Changed from Integer to int
  final String? variantImageUrl;

  CreateProductVariantDTO({
    required this.name,
    this.sku,
    required this.price,
    required this.stockQuantity,
    this.variantImageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sku': sku,
      'price': price,
      'stockQuantity': stockQuantity,
      'variantImageUrl': variantImageUrl,
    };
  }
}
