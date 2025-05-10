class CartItemModel {
  final int productId;
  final String productName;
  final String
      imageUrl; // URL or local path to the product image (will store variant image)
  final int quantity;
  final double
      price; // This should be the original price before product-specific discount
  final int variantId; // ID of the selected variant - Changed to non-nullable
  final double? discountPercentage; // Product-specific discount percentage

  CartItemModel({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.quantity,
    required this.price,
    required this.variantId, // Changed to required and non-nullable
    this.discountPercentage, // Optional
  });

  // Optional: Add toJson and fromJson methods if you need to serialize/deserialize
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'price': price,
      'variantId': variantId, // Ensure variantId is included
      'discountPercentage': discountPercentage,
    };
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      productId: json['productId'] as int,
      productName: json['productName'] as String,
      imageUrl: json['imageUrl'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      variantId: json['variantId'] as int, // Ensure variantId is parsed
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble(),
    );
  }

  // Optional: Add copyWith method for easy updates
  CartItemModel copyWith({
    int? productId,
    String? productName,
    String? imageUrl,
    int? quantity,
    double? price,
    int? variantId, // Parameter can be nullable for optional update
    double? discountPercentage,
  }) {
    return CartItemModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      variantId: variantId ?? this.variantId,
      discountPercentage: discountPercentage ?? this.discountPercentage,
    );
  }
}
