class CartItemModel {
  final int productId;
  final String productName;
  final String
      imageUrl; // URL or local path to the product image (will store variant image)
  final int quantity;
  final double price;
  final int variantId; // ID of the selected variant - Changed to non-nullable

  CartItemModel({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.quantity,
    required this.price,
    required this.variantId, // Changed to required and non-nullable
  });

  // Optional: Add toJson and fromJson methods if you need to serialize/deserialize
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'price': price,
      'variantId': variantId, // Remains non-nullable
    };
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      productId: json['productId'] as int,
      productName: json['productName'] as String,
      imageUrl: json['imageUrl'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      variantId: json['variantId'] as int, // Changed to non-nullable cast
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
  }) {
    return CartItemModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      variantId: variantId ?? this.variantId, // Uses existing if not provided
    );
  }
}
