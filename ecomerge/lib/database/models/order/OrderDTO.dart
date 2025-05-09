import 'package:e_commerce_app/database/Storage/UserInfo.dart'; // For UserInfo access

// Define OrderDetailItemDTO if you need to parse and use orderDetails deeply
class OrderDetailItemDTO {
  final int productVariantId;
  final String? productName;
  final String? variantName;
  final String? imageUrl;
  final int quantity;
  final double priceAtPurchase;
  final double? productDiscountPercentage;
  final double lineTotal;

  OrderDetailItemDTO({
    required this.productVariantId,
    this.productName,
    this.variantName,
    this.imageUrl,
    required this.quantity,
    required this.priceAtPurchase,
    this.productDiscountPercentage,
    required this.lineTotal,
  });

  factory OrderDetailItemDTO.fromJson(Map<String, dynamic> json) {
    return OrderDetailItemDTO(
      productVariantId: json['productVariantId'] as int,
      productName: json['productName'] as String?,
      variantName: json['variantName'] as String?,
      imageUrl: json['imageUrl'] as String?,
      quantity: json['quantity'] as int,
      priceAtPurchase: (json['priceAtPurchase'] as num).toDouble(),
      productDiscountPercentage:
          (json['productDiscountPercentage'] as num?)?.toDouble(),
      lineTotal: (json['lineTotal'] as num).toDouble(),
    );
  }
}

class OrderDTO {
  final int id;
  final DateTime? orderDate;
  final DateTime? updatedDate;
  final String? recipientName;
  final String? recipientPhoneNumber;
  final String? shippingAddress;
  final double? subtotal; // This will map to itemsTotal on success page
  final double? couponDiscount; // This will map to discount on success page
  final double? pointsDiscount;
  final double? shippingFee;
  final double? tax;
  final double? totalAmount;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? orderStatus;
  final int? pointsEarned;
  final String? couponCode;
  final List<OrderDetailItemDTO>? orderDetails;

  OrderDTO({
    required this.id,
    this.orderDate,
    this.updatedDate,
    this.recipientName,
    this.recipientPhoneNumber,
    this.shippingAddress,
    this.subtotal,
    this.couponDiscount,
    this.pointsDiscount,
    this.shippingFee,
    this.tax,
    this.totalAmount,
    this.paymentMethod,
    this.paymentStatus,
    this.orderStatus,
    this.pointsEarned,
    this.couponCode,
    this.orderDetails,
  });

  factory OrderDTO.fromJson(Map<String, dynamic> json) {
    return OrderDTO(
      id: json['id'] as int,
      orderDate: json['orderDate'] != null
          ? DateTime.tryParse(json['orderDate'] as String)
          : null,
      updatedDate: json['updatedDate'] != null
          ? DateTime.tryParse(json['updatedDate'] as String)
          : null,
      recipientName: json['recipientName'] as String?,
      recipientPhoneNumber: json['recipientPhoneNumber'] as String?,
      shippingAddress: json['shippingAddress'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      couponDiscount: (json['couponDiscount'] as num?)?.toDouble(),
      pointsDiscount: (json['pointsDiscount'] as num?)?.toDouble(),
      shippingFee: (json['shippingFee'] as num?)?.toDouble(),
      tax: (json['tax'] as num?)?.toDouble(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      paymentMethod: json['paymentMethod'] as String?,
      paymentStatus: json['paymentStatus'] as String?,
      orderStatus: json['orderStatus'] as String?,
      pointsEarned: json['pointsEarned'] as int?,
      couponCode: json['couponCode'] as String?,
      orderDetails: (json['orderDetails'] as List<dynamic>?)
          ?.map((item) =>
              OrderDetailItemDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMapForPaymentSuccess() {
    // UserInfo().currentUser?.id is added separately in PagePayment
    // This map provides data primarily from the order itself.
    return {
      'orderID': id.toString(),
      // customerID will be added in PagePayment from UserInfo
      'customerName':
          recipientName ?? UserInfo().currentUser?.fullName ?? 'N/A',
      'address': shippingAddress ?? 'N/A',
      'phone': recipientPhoneNumber ?? 'N/A',
      'createdTime': orderDate ?? DateTime.now(),
      'paymentMethod': paymentMethod ?? 'N/A',
      'itemsTotal': subtotal ?? 0.0,
      'shippingFee': shippingFee ?? 0.0,
      'tax': tax ?? 0.0,
      'discount': couponDiscount ?? 0.0, // Primarily coupon discount
      // If you want to show pointsDiscount separately, PaymentSuccess.dart needs an update
      // Or you can sum them: (couponDiscount ?? 0.0) + (pointsDiscount ?? 0.0)
      'totalAmount': totalAmount ?? 0.0,
      'orderStatus': orderStatus ?? 'PENDING',
      // You can add more fields here if PaymentSuccess.dart needs them
      // e.g., 'orderDetails': orderDetails?.map((e) => e.toJsonMap()).toList() // If needed
    };
  }
}
