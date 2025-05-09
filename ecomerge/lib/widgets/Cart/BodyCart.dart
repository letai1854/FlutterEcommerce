import 'package:e_commerce_app/database/models/CartDTO.dart';
import 'package:e_commerce_app/widgets/Cart/CartItemList.dart';
import 'package:e_commerce_app/widgets/Cart/PaymentInfo.dart';
import 'package:e_commerce_app/widgets/footer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BodyCart extends StatelessWidget {
  // Data and State
  final List<CartItemDTO> cartItems;
  final Map<int?, bool> selectedItems; // Track selection state
  final double taxRate;
  final double shippingFee;
  final ScrollController scrollController;
  final ValueNotifier<bool> isPaymentInfoBottomVisible;
  final GlobalKey paymentInfoKey;

  // Callbacks for Cart Actions
  final Function(int) toggleSelectItem;
  final Function(int) increaseQuantity;
  final Function(int) decreaseQuantity;
  final Function(int) removeItem;
  final Function(bool) toggleSelectAll;
  final Function() unselectAllItems;

  // Calculation Functions
  final double Function() calculateSubtotal;
  final double Function() calculateTax;
  final double Function() calculateTotal;

  const BodyCart({
    Key? key,
    required this.cartItems,
    required this.selectedItems,
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
          // --- Main Scrollable Content ---
          CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Cart item list ---
                    CartItemList(
                      cartItems: cartItems,
                      selectedItems: selectedItems,
                      toggleSelectItem: toggleSelectItem,
                      increaseQuantity: increaseQuantity,
                      decreaseQuantity: decreaseQuantity,
                      removeItem: removeItem,
                    ),

                    // --- Scrollable payment info ---
                    if (cartItems.isNotEmpty)
                       PaymentInfo(
                          key: paymentInfoKey,
                          cartItems: cartItems,
                          selectedItems: selectedItems,
                          calculateTax: calculateTax,
                          calculateTotal: calculateTotal,
                          calculateSubtotal: calculateSubtotal,
                          shippingFee: shippingFee,
                          taxRate: taxRate,
                          toggleSelectAll: toggleSelectAll,
                          unselectAllItems: unselectAllItems,
                          isSticky: false,
                       ),

                     // --- Footer or bottom spacing ---
                     if (kIsWeb && cartItems.isNotEmpty)
                       const Footer()
                     else if (cartItems.isEmpty)
                       Container(height: MediaQuery.of(context).size.height * 0.3)
                     else
                       const SizedBox(height: 90),
                  ],
                ),
              ),
            ],
          ),

          // --- Sticky payment info at bottom ---
          ValueListenableBuilder<bool>(
            valueListenable: isPaymentInfoBottomVisible,
            builder: (context, isVisible, child) {
              if (!isVisible || cartItems.isEmpty) {
                 return const SizedBox.shrink();
              }
              return Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: child!,
              );
            },
            child: PaymentInfo(
              cartItems: cartItems,
              selectedItems: selectedItems,
              calculateTax: calculateTax,
              calculateTotal: calculateTotal,
              calculateSubtotal: calculateSubtotal,
              shippingFee: shippingFee,
              taxRate: taxRate,
              toggleSelectAll: toggleSelectAll,
              unselectAllItems: unselectAllItems,
              isSticky: true,
            ),
          ),
        ],
      ),
    );
  }
}
