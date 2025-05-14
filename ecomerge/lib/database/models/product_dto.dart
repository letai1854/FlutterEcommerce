import 'package:flutter/foundation.dart';
import 'package:e_commerce_app/database/models/product_variant_dto.dart';
import 'package:intl/intl.dart'; // Assuming you'll use intl for date formatting if needed

// New ProductReviewDTO class
class ProductReviewDTO {
  final int? id;
  final String? reviewerName;
  final int? rating; // Dart uses int for Byte
  final String? comment;
  final DateTime? reviewTime;
  final int?
      userId; // Dart uses int for Long if values are within int range, otherwise BigInt or String
  final int? productId; // Dart uses int for Long
  final String? reviewerAvatarUrl; // Added reviewerAvatarUrl

  ProductReviewDTO({
    this.id,
    this.reviewerName,
    this.rating,
    this.comment,
    this.reviewTime,
    this.userId,
    this.productId,
    this.reviewerAvatarUrl, // Added to constructor
  });

  factory ProductReviewDTO.fromJson(Map<String, dynamic> json) {
    return ProductReviewDTO(
      id: json['id'] as int?,
      reviewerName: json['reviewerName'] as String?,
      rating: json['rating'] as int?, // Assuming Byte maps to int
      comment: json['comment'] as String?,
      reviewTime: json['reviewTime'] != null
          ? DateTime.parse(json['reviewTime'])
          : null,
      userId: json['userId'] as int?, // Assuming Long maps to int
      productId: json['productId'] as int?, // Assuming Long maps to int
      reviewerAvatarUrl: json['reviewerAvatarUrl']
          as String?, // Added parsing for reviewerAvatarUrl
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reviewerName': reviewerName,
      'rating': rating,
      'comment': comment,
      'reviewTime': reviewTime?.toIso8601String(),
      'userId': userId,
      'productId': productId,
      'reviewerAvatarUrl':
          reviewerAvatarUrl, // Added serialization for reviewerAvatarUrl
    };
  }
}

class ProductDTO {
  final int? id;
  final String name;
  final String description;
  final String? categoryName;
  final String? brandName;
  final String? mainImageUrl;
  final List<String>? imageUrls;
  final double? discountPercentage;
  final DateTime? createdDate;
  final DateTime? updatedDate;
  final double? averageRating;
  final double? minPrice;
  final double? maxPrice;
  final int? variantCount;
  final List<ProductVariantDTO>? variants;
  final List<ProductReviewDTO>? reviews; // Added reviews field

  ProductDTO({
    this.id,
    required this.name,
    required this.description,
    this.categoryName,
    this.brandName,
    this.mainImageUrl,
    this.imageUrls,
    this.discountPercentage,
    this.createdDate,
    this.updatedDate,
    this.averageRating,
    this.minPrice,
    this.maxPrice,
    this.variantCount,
    this.variants,
    this.reviews, // Added to constructor
  });

  factory ProductDTO.fromJson(Map<String, dynamic> json) {
    try {
      // Create safer parsing of nested objects and lists
      List<ProductVariantDTO>? variants;
      if (json['variants'] != null) {
        try {
          variants = (json['variants'] as List)
              .map((e) => ProductVariantDTO.fromJson(e))
              .toList();
        } catch (e) {
          print('Error parsing product variants: $e');
        }
      }

      List<ProductReviewDTO>? reviews;
      if (json['reviews'] != null) {
        try {
          reviews = (json['reviews'] as List)
              .map((e) => ProductReviewDTO.fromJson(e))
              .toList();
        } catch (e) {
          print('Error parsing product reviews: $e');
        }
      }

      // Parse the rest of the fields safely
      return ProductDTO(
        id: json['id'],
        name: json['name'] ?? 'Unknown Product',
        description: json['description'] ?? '',
        // Extract categoryName and brandName fields properly
        categoryName: json['categoryName'],
        brandName: json['brandName'],
        mainImageUrl: json['mainImageUrl'],
        imageUrls: json['imageUrls'] != null
            ? List<String>.from(json['imageUrls'])
            : null,
        variants: variants,
        reviews: reviews,
        averageRating: json['averageRating']?.toDouble(),
        minPrice: json['minPrice']?.toDouble(),
        maxPrice: json['maxPrice']?.toDouble(),
        discountPercentage: json['discountPercentage']?.toDouble(),
        createdDate: json['createdDate'] != null
            ? DateTime.parse(json['createdDate'])
            : null,
        updatedDate: json['updatedDate'] != null
            ? DateTime.parse(json['updatedDate'])
            : null,
        variantCount: json['variantCount'],
      );
    } catch (e) {
      print('Error in ProductDTO.fromJson: $e');
      // Return a minimal valid object instead of throwing
      return ProductDTO(
        name: 'Error Loading Product',
        description: 'There was an error parsing this product data.',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'categoryName': categoryName,
      'brandName': brandName,
      'mainImageUrl': mainImageUrl,
      'imageUrls': imageUrls,
      'discountPercentage': discountPercentage,
      'createdDate': createdDate?.toIso8601String(),
      'updatedDate': updatedDate?.toIso8601String(),
      'averageRating': averageRating,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'variantCount': variantCount,
      'variants': variants?.map((e) => e.toJson()).toList(),
      'reviews': reviews
          ?.map((e) => e.toJson())
          .toList(), // Added serialization for reviews
    };
  }
}
