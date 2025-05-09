import 'package:e_commerce_app/database/models/order/OrderDetailRequestDTO.dart';

class CreateOrderRequestDTO {
  final int addressId;
  final List<OrderDetailRequestDTO> orderDetails;
  final String? couponCode;
  final String paymentMethod;
  final double? pointsToUse; // BigDecimal maps to double
  final double? shippingFee; // BigDecimal maps to double
  final double? tax; // BigDecimal maps to double

  CreateOrderRequestDTO({
    required this.addressId,
    required this.orderDetails,
    this.couponCode,
    required this.paymentMethod,
    this.pointsToUse,
    this.shippingFee,
    this.tax,
  });

  Map<String, dynamic> toJson() {
    return {
      'addressId': addressId,
      'orderDetails': orderDetails.map((detail) => detail.toJson()).toList(),
      if (couponCode != null) 'couponCode': couponCode,
      'paymentMethod': paymentMethod,
      if (pointsToUse != null) 'pointsToUse': pointsToUse,
      if (shippingFee != null) 'shippingFee': shippingFee,
      if (tax != null) 'tax': tax,
    };
  }
}
