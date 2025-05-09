import 'package:e_commerce_app/database/Storage/UserInfo.dart'; // For UserInfo access

class OrderDTO {
  final int id;
  final double? totalAmount;
  final DateTime? orderDate;
  final String? paymentMethod;
  final String? orderStatus;
  // Add other fields as returned by your backend, for example:
  // final int addressId;
  // final List<dynamic> orderDetails; // Define an OrderDetailDTO if needed

  OrderDTO({
    required this.id,
    this.totalAmount,
    this.orderDate,
    this.paymentMethod,
    this.orderStatus,
  });

  factory OrderDTO.fromJson(Map<String, dynamic> json) {
    return OrderDTO(
      id: json['id'] as int,
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      // Ensure orderDate is parsed correctly, handle potential nulls
      orderDate: json['orderDate'] != null
          ? DateTime.tryParse(json['orderDate'] as String)
          : null,
      paymentMethod: json['paymentMethod'] as String?,
      orderStatus: json['orderStatus'] as String?,
    );
  }

  Map<String, dynamic> toMapForPaymentSuccess() {
    return {
      'orderID': id.toString(),
      'customerID': UserInfo().currentUser?.id?.toString() ?? 'N/A',
      // customerName, address, phone will be overridden by PagePayment using _currentAddress
      'customerName': UserInfo().currentUser?.fullName ?? 'N/A',
      'address': 'N/A',
      'phone': 'N/A',
      'createdTime':
          orderDate ?? DateTime.now(), // Fallback to now if not available
      'totalAmount': totalAmount ?? 0.0,
      'paymentMethod': paymentMethod ?? 'N/A',
      'orderStatus': orderStatus ?? 'PENDING',
      // Add other fields as needed by PaymentSuccess
    };
  }
}
