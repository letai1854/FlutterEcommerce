import 'package:e_commerce_app/widgets/Cart/CartItemList.dart';
import 'package:e_commerce_app/widgets/Cart/PaymentInfo.dart';
import 'package:e_commerce_app/widgets/footer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BodyCart extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems;
  final double taxRate;
  final double shippingFee;
  final ScrollController scrollController;
  final ValueNotifier<bool> isPaymentInfoBottomVisible;
  final GlobalKey paymentInfoKey;
  final Function(int) toggleSelectItem;
  final Function(int) increaseQuantity;
  final Function(int) decreaseQuantity;
  final Function(int) removeItem;
  final Function(bool) toggleSelectAll;
  final Function() unselectAllItems;
  final double Function() calculateSubtotal;
  final double Function() calculateTax;
  final double Function() calculateTotal;

  const BodyCart({
    Key? key,
    required this.cartItems,
    required this.taxRate,
    required this.shippingFee,
    required this.scrollController,
    required this.isPaymentInfoBottomVisible,
    required this.paymentInfoKey,
    required this.toggleSelectItem,
    required this.increaseQuantity,
    required this.decreaseQuantity,
    required this.removeItem,
    required this.toggleSelectAll,
    required this.unselectAllItems,
    required this.calculateSubtotal,
    required this.calculateTax,
    required this.calculateTotal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CartItemList(
                        cartItems: cartItems,
                        toggleSelectItem: toggleSelectItem,
                        increaseQuantity: increaseQuantity,
                        decreaseQuantity: decreaseQuantity,
                        removeItem: removeItem,
                      ),
                      PaymentInfo(
                        key: paymentInfoKey,
                        cartItems: cartItems,
                        calculateTax: calculateTax,
                        calculateTotal: calculateTotal,
                        calculateSubtotal: calculateSubtotal,
                        shippingFee: shippingFee,
                        taxRate: taxRate,
                        toggleSelectAll: toggleSelectAll,
                        unselectAllItems: unselectAllItems,
                      ),

                      SizedBox(
                        height: cartItems.length <= 1
                            ? MediaQuery.of(context).size.height - 500
                            : 0,
                      ),

                      if (kIsWeb) const Footer(),
                    ],
                  ),
                ),
              ),
            ],
          ),

          ValueListenableBuilder<bool>(
            valueListenable: isPaymentInfoBottomVisible,
            builder: (context, isVisible, child) {
              return Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Visibility(
                  visible: isVisible,
                  child: PaymentInfo(
                    cartItems: cartItems,
                    calculateTax: calculateTax,
                    calculateTotal: calculateTotal,
                    calculateSubtotal: calculateSubtotal,
                    shippingFee: shippingFee,
                    taxRate: taxRate,
                    toggleSelectAll: toggleSelectAll,
                    unselectAllItems: unselectAllItems,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
