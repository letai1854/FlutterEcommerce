class OrderDetailRequestDTO {
  final int productVariantId;
  final int quantity;

  OrderDetailRequestDTO({
    required this.productVariantId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'productVariantId': productVariantId,
      'quantity': quantity,
    };
  }
}
