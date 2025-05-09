import 'package:e_commerce_app/Screens/Payment/PagePayment.dart';
import 'package:e_commerce_app/widgets/Payment/AddressDisplay.dart';
import 'package:e_commerce_app/widgets/Payment/AddressSelector.dart';
import 'package:e_commerce_app/widgets/Payment/VoucherSelector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/database/services/user_service.dart';
import 'package:e_commerce_app/database/services/address_service.dart';
import 'package:e_commerce_app/database/services/categories_service.dart'; // Add this import
import 'package:flutter/foundation.dart';
import 'package:e_commerce_app/database/models/address_model.dart'; // Add this import for AddressRequest
import 'package:e_commerce_app/database/models/cart_item_model.dart'; // Add this import
import 'package:e_commerce_app/Screens/ProductDetail/PageProductDetail.dart'; // Add this import for navigation

class BodyPayment extends StatelessWidget {
  final AddressData? currentAddress;
  final List<CartItemModel> products; // Change type here
  final VoucherData? currentVoucher;
  final String selectedPaymentMethod;
  final double subtotal;
  final double shippingFee;
  final double taxAmount;
  final double taxRate;
  final double discountAmount;
  final double totalAmount;
  final bool isProcessingOrder;
  final bool useAccumulatedPoints; // New parameter
  final ValueChanged<bool?> onToggleUseAccumulatedPoints; // New parameter
  final double pointsDiscountAmount; // New parameter for points discount
  final int? sourceProductId; // Add this parameter for navigation back to product
  final bool sourceCartPage; // Add this parameter for navigation back to cart

  final VoidCallback onChangeAddress;
  final VoidCallback onSelectVoucher;
  final Function(String) onChangePaymentMethod;
  final VoidCallback onPlaceOrder;
  final String Function(num) formatCurrency;
  final Function(AddressData) onAddressSelected;

  final CategoriesService _categoriesService =
      CategoriesService(); // Add this line

  BodyPayment({
    Key? key,
    required this.currentAddress,
    required this.products, // Ensure constructor matches
    required this.currentVoucher,
    required this.selectedPaymentMethod,
    required this.subtotal,
    required this.shippingFee,
    required this.taxAmount,
    required this.taxRate,
    required this.discountAmount,
    required this.totalAmount,
    required this.isProcessingOrder,
    required this.onChangeAddress,
    required this.onSelectVoucher,
    required this.onChangePaymentMethod,
    required this.onPlaceOrder,
    required this.formatCurrency,
    required this.onAddressSelected,
    required this.useAccumulatedPoints, // Initialize new parameter
    required this.onToggleUseAccumulatedPoints, // Initialize new parameter
    required this.pointsDiscountAmount, // Initialize new parameter
    this.sourceProductId, // Initialize the source product ID
    this.sourceCartPage = false, // Default to false
  }) : super(key: key);

  // Check if we can navigate back to a product
  bool get canNavigateBackToProduct => sourceProductId != null && !sourceCartPage;
  
  // Check if we can navigate back to cart
  bool get canNavigateBackToCart => sourceCartPage;

  // Back button to return to product
  Widget _buildBackToProductButton(BuildContext context) {
    if (!canNavigateBackToProduct) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade100,
          foregroundColor: Colors.orange.shade800,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          alignment: Alignment.centerLeft,
        ),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Quay lại sản phẩm'),
        onPressed: () {
          // Navigate back to product detail page
          Navigator.of(context).pop(); // First pop current page
          
          // If we need to ensure navigation to product page (in case we came through multiple pages)
          // we can use this more direct approach:
          /*
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => Pageproductdetail(
                productId: sourceProductId!,
              ),
            ),
          );
          */
        },
      ),
    );
  }
  
  // Back button to return to cart
  Widget _buildBackToCartButton(BuildContext context) {
    if (!canNavigateBackToCart) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade100,
          foregroundColor: Colors.orange.shade800,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          alignment: Alignment.centerLeft,
        ),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Quay lại giỏ hàng'),
        onPressed: () {
          // Navigate back to cart page
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Widget _buildAddressDisplay() {
    return AddressDisplay(
      currentAddress: currentAddress,
      onAddressSelected: onAddressSelected,
    );
  }

  Widget _buildDesktopAddressSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Icon(Icons.location_on_outlined,
              color: Colors.red.shade700, size: 20),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: _buildAddressDisplay(),
        ),
        TextButton(
          onPressed: onChangeAddress,
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue.shade700,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text('Thay Đổi',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildDesktopVoucherSection() {
    final bool hasVoucher = currentVoucher != null;
    final currencyFormatter = NumberFormat("#,###", "vi_VN");

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(Icons.local_offer_outlined,
              color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 12),
          const Text(
            'Shop Voucher',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          if (hasVoucher)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                '-${formatCurrency(discountAmount)}',
                style: TextStyle(
                    color: Colors.green.shade700, fontWeight: FontWeight.w500),
              ),
            ),
          TextButton(
            onPressed: onSelectVoucher,
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue.shade700,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(hasVoucher ? 'Xem / Đổi Voucher' : 'Chọn Voucher',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopAccumulatedPointsSection() {
    final double customerPoints = UserInfo().currentUser?.customerPoints ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(Icons.star_outline, color: Colors.deepPurple.shade700, size: 20),
          const SizedBox(width: 12),
          const Text(
            'Điểm tích lũy',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Text(
            '(Hiện có: ${customerPoints.toStringAsFixed(0)})',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const Spacer(),
          Text(
            'Sử dụng điểm:',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          Checkbox(
            value: useAccumulatedPoints,
            // Disable checkbox if no points, but allow PagePayment to handle message
            onChanged: customerPoints > 0 ? onToggleUseAccumulatedPoints : null,
            activeColor: Colors.red.shade700,
            fillColor: customerPoints == 0
                ? MaterialStateProperty.all(Colors.grey.shade300)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileAccumulatedPointsSection() {
    final double customerPoints = UserInfo().currentUser?.customerPoints ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star_outline,
                color: Colors.deepPurple.shade700, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Điểm tích lũy',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '(Hiện có: ${customerPoints.toStringAsFixed(0)})',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Sử dụng điểm tích lũy của bạn:',
              style: TextStyle(fontSize: 14),
            ),
            Checkbox(
              value: useAccumulatedPoints,
              onChanged:
                  customerPoints > 0 ? onToggleUseAccumulatedPoints : null,
              activeColor: Colors.red.shade700,
              fillColor: customerPoints == 0
                  ? MaterialStateProperty.all(Colors.grey.shade300)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String title, IconData icon, bool isSelected) {
    return InkWell(
      onTap: () {
        onChangePaymentMethod(title);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.withOpacity(0.05) : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.red : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.red.shade700 : Colors.grey.shade700,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.red.shade700 : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceOrderButton(BuildContext context) {
    bool isLoggedIn = UserInfo().isLoggedIn;
    bool canPlaceOrder = currentAddress != null && !isProcessingOrder;

    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: isProcessingOrder ? 0 : 2,
          disabledBackgroundColor: Colors.grey.shade400,
        ),
        onPressed: canPlaceOrder
            ? () {
                if (UserInfo().currentUser != null) {
                  onPlaceOrder();
                } else {
                  _showEmailLoginDialog(context);
                }
              }
            : null,
        icon: isProcessingOrder
            ? Container(
                width: 18,
                height: 18,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.shopping_cart_checkout, size: 18),
        label: Text(
          isProcessingOrder
              ? 'Đang xử lý...'
              : (currentAddress == null ? 'Vui lòng thêm địa chỉ' : 'Đặt hàng'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showEmailLoginDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nhập email để tiếp tục',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    enabled: !isProcessing,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Nhập địa chỉ email của bạn',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      final emailRegex =
                          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng thanh toán:',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        formatCurrency(totalAmount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isProcessing
                            ? null
                            : () => Navigator.pop(dialogContext),
                        child: const Text('Hủy'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: isProcessing
                            ? null
                            : () async {
                                if (formKey.currentState!.validate()) {
                                  final email = emailController.text.trim();
                                  setDialogState(() => isProcessing = true);
                                  final success =
                                      await _registerGuestUserAndSetAddress(
                                          email);

                                  if (success) {
                                    Navigator.pop(dialogContext);
                                    onPlaceOrder();
                                  } else {
                                    setDialogState(() => isProcessing = false);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Không thể tiếp tục với email này. Vui lòng thử lại.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                        ),
                        child: isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ))
                            : const Text('Tiếp tục'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _registerGuestUserAndSetAddress(String email) async {
    try {
      final userService = UserService();
      // userService.registerGuestUser should handle:
      // 1. Registration with a placeholder address (e.g., "null").
      // 2. Automatic login (setting auth token).
      // 3. Cleanup of the placeholder address by the user_service logic.
      final registrationSuccess = await userService.registerGuestUser(email);

      if (registrationSuccess) {
        // User is now registered and logged in.
        // Auth token should be available for AddressService calls.

        if (currentAddress != null) {
          // If guest had entered an address, save it to their account.
          final addressService = AddressService();
          final addressRequest = AddressRequest(
            recipientName: currentAddress!.name,
            phoneNumber: currentAddress!.phone,
            specificAddress:
                "${currentAddress!.address}, ${currentAddress!.ward}, ${currentAddress!.district}, ${currentAddress!.province}",
            isDefault: true, // Make this newly added address the default.
          );

          final Address? newlyAddedAddressModel =
              await addressService.addAddress(addressRequest);

          if (newlyAddedAddressModel != null &&
              newlyAddedAddressModel.id != null) {
            // Address successfully added to the backend.
            // Create an updated AddressData object with the new ID and default status.
            final AddressData newAddressDataWithId = currentAddress!.copyWith(
              id: newlyAddedAddressModel.id,
              isDefault: newlyAddedAddressModel.isDefault,
            );

            // Update PagePayment's _currentAddress with this new AddressData.
            // This ensures that when onPlaceOrder() is called, it uses the address with the backend ID.
            onAddressSelected(newAddressDataWithId);

            print(
                'Guest address successfully added to backend and PagePayment updated.');
            return true;
          } else {
            // Failed to add the address to the backend.
            // Registration was successful, but address saving failed.
            print(
                'Guest registration successful, but failed to save their address to backend.');
            // Return false because the full process of setting address failed.
            return false;
          }
        } else {
          // Registration successful, but no currentAddress was provided by the guest.
          print('Guest registration successful, no address to save.');
          return true; // Registration itself was successful.
        }
      } else {
        // Guest registration failed.
        print('Guest registration failed.');
        return false;
      }
    } catch (e) {
      print('Error in _registerGuestUserAndSetAddress process: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final currencyFormatter = NumberFormat("#,###", "vi_VN");

    // Debug output of received products in BodyPayment
    print('BodyPayment: Received ${products.length} products');
    for (var item in products) {
      print(' - Showing product: ${item.productName}, Quantity: ${item.quantity}, Price: ${item.price}');
    }

    return SingleChildScrollView(
      child: Container(
        color: Colors.grey[100],
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20.0),
            constraints: const BoxConstraints(maxWidth: 1000),
            margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add appropriate back button based on navigation source
                if (canNavigateBackToProduct)
                  _buildBackToProductButton(context)
                else if (canNavigateBackToCart)
                  _buildBackToCartButton(context),
                
                Container(
                  padding: const EdgeInsets.all(16.0),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: Colors.grey.shade200, width: 1.0))),
                  child: isMobile
                      ? _buildMobileAddressSection()
                      : _buildDesktopAddressSection(),
                ),
                _buildSectionContainer(
                  title: 'Sản phẩm',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMobile) _buildDesktopProductHeader(),
                      if (!isMobile) const Divider(height: 1),
                      if (products.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(
                            child: Text(
                              'Không có sản phẩm nào được chọn',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final productItem =
                              products[index]; // productItem is CartItemModel
                          print('Rendering product at index $index: ${productItem.productName}');
                          return isMobile
                              ? _buildMobileProductItem(productItem)
                              : _buildDesktopProductItem(productItem);
                        },
                        separatorBuilder: (context, index) => isMobile
                            ? const SizedBox.shrink()
                            : const Divider(height: 1),
                      ),
                      const Divider(height: 20),
                      isMobile
                          ? _buildMobileVoucherSection()
                          : _buildDesktopVoucherSection(),
                      const SizedBox(
                          height: 12.0), // Spacing before points section
                      isMobile
                          ? _buildMobileAccumulatedPointsSection()
                          : _buildDesktopAccumulatedPointsSection(),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),
                _buildSectionContainer(
                    title: 'Phương thức thanh toán',
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            // _buildPaymentOption(
                            //   'Ngân hàng',
                            //   Icons.account_balance_wallet_outlined,
                            //   selectedPaymentMethod == 'Ngân hàng',
                            // ),
                            _buildPaymentOption(
                              'Thanh toán khi nhận hàng',
                              Icons.local_shipping_outlined,
                              selectedPaymentMethod ==
                                  'Thanh toán khi nhận hàng',
                            ),
                            // _buildPaymentOption(
                            //   'Ví điện tử',
                            //   Icons.wallet_giftcard,
                            //   selectedPaymentMethod == 'Ví điện tử',
                            // ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        Text(
                          selectedPaymentMethod == 'Thanh toán khi nhận hàng'
                              ? 'Thanh toán khi nhận hàng. Phí thu hộ: ${formatCurrency(0)}. Ưu đãi vận chuyển (nếu có) áp dụng cả với phí thu hộ.'
                              : 'Chọn phương thức thanh toán phù hợp với bạn.',
                          style: TextStyle(
                              fontSize: 12.0, color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )),
                const SizedBox(height: 20.0),
                _buildSectionContainer(
                    title: 'Chi tiết thanh toán',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _buildSummaryRow(
                            'Tổng tiền hàng:', formatCurrency(subtotal)),
                        _buildSummaryRow(
                            'Phí vận chuyển:', formatCurrency(shippingFee)),
                        if (taxAmount > 0)
                          _buildSummaryRow(
                              'Thuế VAT (${(taxRate * 100).toStringAsFixed(0)}%):',
                              formatCurrency(taxAmount)),
                        if (discountAmount > 0)
                          _buildSummaryRow('Giảm giá voucher:',
                              '-${formatCurrency(discountAmount)}',
                              isDiscount: true),
                        if (pointsDiscountAmount > 0) // Display points discount
                          _buildSummaryRow('Giảm giá điểm tích lũy:',
                              '-${formatCurrency(pointsDiscountAmount)}',
                              isDiscount: true),
                        const Divider(height: 24, thickness: 1),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng thanh toán:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17.0,
                              ),
                            ),
                            Text(
                              formatCurrency(totalAmount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 19.0,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24.0),
                        _buildPlaceOrderButton(context),
                        const SizedBox(height: 16.0),
                        const Center(
                          child: Text(
                            'Nhấn "Đặt hàng" đồng nghĩa với việc bạn đồng ý tuân theo Điều khoản Shopii',
                            style:
                                TextStyle(fontSize: 12.0, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContainer(
      {required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17.0,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16.0),
          child,
        ],
      ),
    );
  }

  Widget _buildDesktopProductHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, left: 8, right: 8),
      child: Row(
        children: const [
          SizedBox(width: 60 + 16),
          Expanded(
            flex: 4,
            child: Text(
              'Sản phẩm',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                'Đơn giá',
                style:
                    TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                'SL',
                style:
                    TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Thành tiền',
                style:
                    TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: isDiscount ? Colors.green.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopProductItem(CartItemModel product) {
    // Change parameter type
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: FutureBuilder<Uint8List?>(
              future: _categoriesService.getImageFromServer(product.imageUrl),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2));
                } else if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data == null) {
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.error_outline, color: Colors.grey),
                  );
                } else {
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(4),
                      image: DecorationImage(
                        image: MemoryImage(snapshot.data!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: Text(
              product.productName, // Use product.productName
              style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                formatCurrency(product.price), // Use product.price
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                '${product.quantity}', // Use product.quantity
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                formatCurrency(product.price *
                    product.quantity), // Use product.price and product.quantity
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileProductItem(CartItemModel product) {
    // Change parameter type
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200, width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 65,
                  height: 65,
                  child: FutureBuilder<Uint8List?>(
                    future:
                        _categoriesService.getImageFromServer(product.imageUrl),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2));
                      } else if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data == null) {
                        return Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.error_outline,
                              color: Colors.grey),
                        );
                      } else {
                        return Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(4),
                            image: DecorationImage(
                              image: MemoryImage(snapshot.data!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    product.productName, // Use product.productName
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMobilePriceColumn('Đơn giá',
                    formatCurrency(product.price)), // Use product.price
                _buildMobilePriceColumn('Số lượng',
                    'x ${product.quantity}'), // Use product.quantity
                _buildMobilePriceColumn(
                    'Thành tiền',
                    formatCurrency(product.price *
                        product
                            .quantity), // Use product.price and product.quantity
                    isTotal: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobilePriceColumn(String label, String value,
      {bool isTotal = false}) {
    return Column(
      crossAxisAlignment:
          isTotal ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? Colors.red.shade700 : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on_outlined,
                color: Colors.red.shade700, size: 20),
            const SizedBox(width: 8.0),
            const Text(
              'Địa Chỉ Nhận Hàng',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
                color:
                    Color.fromARGB(255, 201, 201, 201), // Kept original color
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onChangeAddress,
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: const Text('Thay Đổi',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 28.0),
          // Pass the currentAddress from BodyPayment to AddressDisplay
          child: AddressDisplay(
            currentAddress:
                currentAddress, // Changed from null to currentAddress
            onAddressSelected: onAddressSelected,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileVoucherSection() {
    final bool hasVoucher = currentVoucher != null;
    final currencyFormatter = NumberFormat("#,###", "vi_VN");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_offer_outlined,
                color: Colors.orange.shade700, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Shop Voucher',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            if (hasVoucher) ...[
              const Spacer(),
              Text(
                '-${formatCurrency(discountAmount)}',
                style: TextStyle(
                    color: Colors.green.shade700, fontWeight: FontWeight.w500),
              ),
            ]
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onSelectVoucher,
            icon: Icon(Icons.search, size: 18, color: Colors.blue.shade700),
            label: Text(
              hasVoucher ? 'Xem / Đổi Voucher' : 'Chọn hoặc nhập mã',
              style: TextStyle(
                  color: Colors.blue.shade700, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.blue.shade200),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
