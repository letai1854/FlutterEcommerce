// lib/database/models/update_product_request_dto.dart
import 'dart:convert';
import 'package:e_commerce_app/database/models/update_product_variant_dto.dart';
import 'package:flutter/foundation.dart';

class UpdateProductRequestDTO {
  final String name;
  final String description;
  final int categoryId;
  final int brandId;
  final String? mainImageUrl;
  final List<String>? imageUrls;
  final double? discountPercentage;
  final List<UpdateProductVariantDTO> variants;

  UpdateProductRequestDTO({
    required this.name,
    required this.description,
    required this.categoryId,
    required this.brandId,
    this.mainImageUrl,
    this.imageUrls,
    this.discountPercentage,
    required this.variants,
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
      'variants': variants.map((variant) => variant.toJson()).toList(),
    };
  }

  factory UpdateProductRequestDTO.fromJson(Map<String, dynamic> json) {
    return UpdateProductRequestDTO(
      name: json['name'] as String,
      description: json['description'] as String,
      categoryId: json['categoryId'] as int,
      brandId: json['brandId'] as int,
      mainImageUrl: json['mainImageUrl'] as String?,
      imageUrls: (json['imageUrls'] as List<dynamic>?)?.map((e) => e as String).toList(),
      discountPercentage: json['discountPercentage'] != null ? (json['discountPercentage'] as num).toDouble() : null,
      variants: (json['variants'] as List<dynamic>)
          .map((e) => UpdateProductVariantDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
