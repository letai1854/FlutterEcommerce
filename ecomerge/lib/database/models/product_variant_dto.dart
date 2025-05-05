import 'package:flutter/foundation.dart';

class ProductVariantDTO {
  final int? id; // ID biến thể (Integer ở server -> int ở Dart)
  final String? name;
  final String? sku;
  final double? price; // Changed from BigDecimal to double
  final int? stockQuantity; // Changed from Integer to int
  final String? variantImageUrl; // URL ảnh biến thể (có thể null)

  ProductVariantDTO({
    this.id,
    this.name,
    this.sku,
    this.price,
    this.stockQuantity,
    this.variantImageUrl,
  });

  factory ProductVariantDTO.fromJson(Map<String, dynamic> json) {
    return ProductVariantDTO(
      id: json['id'] as int?, // ID biến thể là Integer ở server, map sang int
      name: json['name'] as String?,
      sku: json['sku'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      stockQuantity: json['stockQuantity'] as int?,
      variantImageUrl: json['variantImageUrl'] as String?,
    );
  }

  // toJson method (có thể cần cho mục đích debugging hoặc caching nếu cần)
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
}
