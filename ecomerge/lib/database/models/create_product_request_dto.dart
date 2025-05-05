// lib/database/models/create_product_request_dto.dart
import 'package:flutter/foundation.dart';
import 'package:e_commerce_app/database/models/create_product_variant_dto.dart'; // Import đúng

class CreateProductRequestDTO {
  final String name;
  final String description;
  final int categoryId; // Changed to int based on typical Dart usage for IDs
  final int brandId; // Changed to int
  final String? mainImageUrl;
  final List<String>? imageUrls;
  final double? discountPercentage;
  // variants phải là List, không nullable
  final List<CreateProductVariantDTO> variants;

  CreateProductRequestDTO({
    required this.name,
    required this.description,
    required this.categoryId,
    required this.brandId,
    this.mainImageUrl,
    this.imageUrls,
    this.discountPercentage,
    required this.variants, // Yêu cầu variants khi tạo DTO
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'brandId': brandId,
      'mainImageUrl': mainImageUrl,
      'imageUrls': imageUrls,
      'discountPercentage': discountPercentage,
      // Chuyển đổi danh sách variants sang JSON
      'variants': variants.map((e) => e.toJson()).toList(),
    };
  }
}
