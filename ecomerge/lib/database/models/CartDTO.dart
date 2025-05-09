class CartItemDTO {
  int? cartItemId;
  CartProductVariantDTO? productVariant;
  int? quantity;
  double? lineTotal; // Calculated: finalPrice * quantity
  DateTime? addedDate;
  DateTime? updatedDate;
  
  CartItemDTO({
    this.cartItemId,
    this.productVariant,
    this.quantity,
    this.lineTotal,
    this.addedDate,
    this.updatedDate
  });
  
  // For JSON serialization
  factory CartItemDTO.fromJson(Map<String, dynamic> json) {
    return CartItemDTO(
      cartItemId: json['cartItemId'],
      productVariant: json['productVariant'] != null 
          ? CartProductVariantDTO.fromJson(json['productVariant']) 
          : null,
      quantity: json['quantity'],
      lineTotal: json['lineTotal']?.toDouble(),
      addedDate: json['addedDate'] != null 
          ? DateTime.parse(json['addedDate']) 
          : null,
      updatedDate: json['updatedDate'] != null 
          ? DateTime.parse(json['updatedDate']) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'cartItemId': cartItemId,
      'productVariant': productVariant?.toJson(),
      'quantity': quantity,
      'lineTotal': lineTotal,
      'addedDate': addedDate?.toIso8601String(),
      'updatedDate': updatedDate?.toIso8601String(),
    };
  }
}

class CartProductVariantDTO {
  int? id;            // variantId on server
  int? productId;     // productId on server
  String? name;       // productName on server
  String? description; // variantDescription on server
  String? imageUrl;
  double? price;
  double? discountPercentage;
  double? finalPrice;
  int? stockQuantity;
  
  CartProductVariantDTO({
    this.id,
    this.productId,
    this.name,
    this.description,
    this.imageUrl,
    this.price,
    this.discountPercentage,
    this.finalPrice,
    this.stockQuantity,
  });
  
  // Deserialize from server JSON
  factory CartProductVariantDTO.fromJson(Map<String, dynamic> json) {
    // Extract the product name, ensuring we keep the combined format
    String? productName = json['productName'];
    
    // // Log what we're getting from server/local storage
    // print('CartDTO fromJson - Name from JSON: $productName, variantName: ${json['variantName']}');
    
    // // If there's a variantName in the JSON and it's not already included in productName
    // if (json['variantName'] != null && json['variantName'].toString().isNotEmpty && 
    //     productName != null && !productName.contains(json['variantName'].toString())) {
    //   productName = "$productName - ${json['variantName']}";
    //   print('Combined name in fromJson: $productName');
    // }
    
    return CartProductVariantDTO(
      id: json['variantId'],
      productId: json['productId'],
      name: productName,
      description: json['variantDescription'],
      imageUrl: json['imageUrl'],
      price: json['price']?.toDouble(),
      discountPercentage: json['discountPercentage']?.toDouble(),
      finalPrice: json['finalPrice']?.toDouble(),
      stockQuantity: json['stockQuantity'],
    );
  }
  
  // Serialize to send to server
  Map<String, dynamic> toJson() {
    // If name contains a dash, try to split it into product and variant names
    String? productName = name;
    String? variantName;
    
    if (name != null && name!.contains(' - ')) {
      final parts = name!.split(' - ');
      productName = parts[0];
      variantName = parts.length > 1 ? parts[1] : null;
    }
    
    return {
      'variantId': id,
      'productId': productId,
      'productName': productName,
      'variantName': variantName,  // Add this to help server side
      'variantDescription': description,
      'imageUrl': imageUrl,
      'price': price,
      'discountPercentage': discountPercentage,
      'finalPrice': finalPrice,
      'stockQuantity': stockQuantity,
    };
  }
}
