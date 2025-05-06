import 'package:e_commerce_app/Screens/Payment/PagePayment.dart';
import 'package:e_commerce_app/widgets/Payment/AddressSelector.dart'; // Chỉ cần import model nếu dùng chung
import 'package:e_commerce_app/widgets/Payment/VoucherSelector.dart'; // Chỉ cần import model nếu dùng chung
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import intl nếu hàm formatCurrency chuyển vào đây

// Import Data Models nếu tách file
// import 'models/address_data.dart';
// import 'models/voucher_data.dart';

class BodyPayment extends StatelessWidget {
  // Chuyển thành StatelessWidget
  // --- Dữ liệu nhận từ PagePayment ---
  final AddressData currentAddress;
  final List<Map<String, dynamic>> products;
  final VoucherData? currentVoucher;
  final String selectedPaymentMethod;
  final double subtotal;
  final double shippingFee;
  final double taxAmount;
  final double taxRate; // Giả sử thuế VAT là 10%
  final double discountAmount;
  final double totalAmount;
  final bool isProcessingOrder;

  // --- Callbacks nhận từ PagePayment ---
  final VoidCallback onChangeAddress; // Hàm gọi khi nhấn nút thay đổi địa chỉ
  final VoidCallback onSelectVoucher; // Hàm gọi khi nhấn nút chọn voucher
  final Function(String)
      onChangePaymentMethod; // Hàm gọi khi chọn phương thức TT mới
  final VoidCallback onPlaceOrder; // Hàm gọi khi nhấn nút Đặt hàng
  final String Function(num) formatCurrency; // Hàm định dạng tiền tệ

  const BodyPayment({
    Key? key,
    required this.currentAddress,
    required this.products,
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
    required this.formatCurrency, // Nhận hàm format
  }) : super(key: key);

  // Không cần state, initState, dispose nữa

  // Các hàm build (_buildAddressDisplay, _buildProductItem, ...) giữ nguyên
  // nhưng sử dụng dữ liệu và callbacks đã nhận qua constructor.

  // Ví dụ sửa đổi hàm build address display:
  Widget _buildAddressDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Địa Chỉ Nhận Hàng',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
            color: Colors.grey.shade800, // Thêm màu cho dễ đọc
          ),
        ),
        const SizedBox(height: 8), // Tăng khoảng cách
        Row(
          children: [
            Text(
              currentAddress.name, // Sử dụng currentAddress từ props
              style: const TextStyle(
                  fontWeight: FontWeight.w500, // Đậm hơn chút
                  fontSize: 15.0 // To hơn chút
                  ),
            ),
            const SizedBox(width: 12),
            Text(
              currentAddress.phone, // Sử dụng currentAddress từ props
              style: TextStyle(
                  fontSize: 14.0, color: Colors.grey.shade700), // Màu nhạt hơn
            ),
          ],
        ),
        const SizedBox(height: 4), // Giảm khoảng cách
        Text(
          currentAddress.fullAddress, // Sử dụng phương thức getter
          style: TextStyle(
              fontSize: 14.0, color: Colors.grey.shade700), // Màu nhạt hơn
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Ví dụ sửa đổi nút thay đổi địa chỉ:
  Widget _buildDesktopAddressSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Canh trên cho Icon
      children: [
        Padding(
          padding:
              const EdgeInsets.only(top: 2.0), // Dịch icon xuống chút nếu cần
          child: Icon(Icons.location_on_outlined,
              color: Colors.red.shade700, size: 20),
        ), // Icon khác
        const SizedBox(width: 12.0), // Tăng khoảng cách
        Expanded(
          child: _buildAddressDisplay(), // Sử dụng hàm đã sửa
        ),
        TextButton(
          onPressed: onChangeAddress, // Gọi callback từ props
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue.shade700, // Màu chữ
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text('Thay Đổi',
              style: TextStyle(fontWeight: FontWeight.w600) // Đậm hơn
              ),
        ),
      ],
    );
  }

  // Ví dụ sửa đổi nút chọn voucher:
  Widget _buildDesktopVoucherSection() {
    final bool hasVoucher = currentVoucher != null;
    final currencyFormatter =
        NumberFormat("#,###", "vi_VN"); // Tạo formatter nếu cần trong này

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0), // Thêm padding
      child: Row(
        children: [
          Icon(Icons.local_offer_outlined,
              color: Colors.orange.shade700, size: 20), // Icon khác
          const SizedBox(width: 12),
          const Text(
            'Shop Voucher',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const Spacer(), // Đẩy sang phải
          if (hasVoucher)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                '-${formatCurrency(discountAmount)}', // Hiển thị số tiền giảm giá đã tính
                style: TextStyle(
                    color: Colors.green.shade700, fontWeight: FontWeight.w500),
              ),
            ),
          TextButton(
            onPressed: onSelectVoucher, // Gọi callback từ props
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue.shade700, // Màu chữ
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(hasVoucher ? 'Xem / Đổi Voucher' : 'Chọn Voucher',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // Sửa đổi _buildPaymentOption để gọi callback
  Widget _buildPaymentOption(String title, IconData icon, bool isSelected) {
    return InkWell(
      onTap: () {
        onChangePaymentMethod(title); // Gọi callback khi nhấn
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.withOpacity(0.05) : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.red : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1, // Độ dày viền
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
              const SizedBox(width: 10), // Tăng khoảng cách
              Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? Colors.red.shade700
                      : Colors.black87, // Màu chữ
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14, // Giảm cỡ chữ chút
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Sửa đổi nút Đặt hàng
  Widget _buildPlaceOrderButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        // Sử dụng ElevatedButton.icon nếu muốn thêm icon
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade700, // Màu đậm hơn
          foregroundColor: Colors.white, // Màu chữ/icon
          padding: const EdgeInsets.symmetric(
              horizontal: 30, vertical: 14), // Padding lớn hơn
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: isProcessingOrder ? 0 : 2, // Bỏ shadow khi đang xử lý
        ),
        // Vô hiệu hóa nút và hiển thị loading khi isProcessingOrder là true
        onPressed: isProcessingOrder ? null : onPlaceOrder,
        icon: isProcessingOrder
            ? Container(
                // Thay bằng SizedBox để không làm thay đổi layout
                width: 18,
                height: 18,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.shopping_cart_checkout,
                size: 18), // Icon đặt hàng
        label: Text(
          isProcessingOrder ? 'Đang xử lý...' : 'Đặt hàng',
          style: const TextStyle(
            // color: Colors.white, // Đã set ở foregroundColor
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final currencyFormatter =
        NumberFormat("#,###", "vi_VN"); // Tạo formatter ở đây nếu cần

    return SingleChildScrollView(
      child: Container(
        color: Colors.grey[100], // Màu nền nhạt hơn
        padding: const EdgeInsets.symmetric(
            vertical: 16.0), // Padding dọc cho cả trang
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20.0),
            constraints: const BoxConstraints(maxWidth: 1000),
            margin: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 24), // Margin nhỏ hơn trên mobile
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15), // Shadow rõ hơn chút
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Address Section ---
                Container(
                  padding: const EdgeInsets.all(16.0),
                  margin: const EdgeInsets.only(bottom: 20), // Khoảng cách dưới
                  decoration: BoxDecoration(
                      // Thêm viền nhẹ hoặc nền khác biệt nếu muốn
                      border: Border(
                          bottom: BorderSide(
                              color: Colors.grey.shade200, width: 1.0))
                      // borderRadius: BorderRadius.circular(8),
                      // color: Colors.grey.shade50,
                      ),
                  child: isMobile
                      ? _buildMobileAddressSection()
                      : _buildDesktopAddressSection(),
                ),
                // const SizedBox(height: 20.0), // Bỏ SizedBox nếu dùng margin

                // --- Product Section ---
                _buildSectionContainer(
                  title: 'Sản phẩm',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row (chỉ hiện trên desktop)
                      if (!isMobile) _buildDesktopProductHeader(),
                      if (!isMobile) const Divider(height: 1),

                      // Product list
                      ...products.map((product) => isMobile
                          ? _buildMobileProductItem(product)
                          : _buildDesktopProductItem(product)),

                      const Divider(height: 20), // Khoảng cách trước voucher

                      // Voucher row
                      isMobile
                          ? _buildMobileVoucherSection()
                          : _buildDesktopVoucherSection(), // Sử dụng hàm đã sửa
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),

                // --- Payment Method Section ---
                _buildSectionContainer(
                    title: 'Phương thức thanh toán',
                    child: Column(
                      children: [
                        const SizedBox(height: 10), // Khoảng cách trên
                        Wrap(
                          // Dùng Wrap để tự xuống hàng
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            // Truyền selectedPaymentMethod từ props
                            _buildPaymentOption(
                              'Ngân hàng',
                              Icons
                                  .account_balance_wallet_outlined, // Icon khác
                              selectedPaymentMethod == 'Ngân hàng',
                            ),
                            _buildPaymentOption(
                              'Thanh toán khi nhận hàng',
                              Icons.local_shipping_outlined, // Icon khác
                              selectedPaymentMethod ==
                                  'Thanh toán khi nhận hàng',
                            ),
                            // Thêm các phương thức khác nếu có
                            _buildPaymentOption(
                              'Ví điện tử',
                              Icons.wallet_giftcard,
                              selectedPaymentMethod == 'Ví điện tử',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        Text(
                          // Thông tin về phí thu hộ có thể lấy từ config hoặc tính toán
                          selectedPaymentMethod == 'Thanh toán khi nhận hàng'
                              ? 'Thanh toán khi nhận hàng. Phí thu hộ: ${formatCurrency(0)}. Ưu đãi vận chuyển (nếu có) áp dụng cả với phí thu hộ.' // Ví dụ phí thu hộ 0
                              : 'Chọn phương thức thanh toán phù hợp với bạn.',
                          style: TextStyle(
                              fontSize: 12.0, color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )),
                const SizedBox(height: 20.0),

                // --- Order Summary Section ---
                _buildSectionContainer(
                    title: 'Chi tiết thanh toán', // Đổi title
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start, // Canh trái mặc định
                      children: [
                        const SizedBox(height: 10),
                        _buildSummaryRow(
                            'Tổng tiền hàng:',
                            formatCurrency(
                                subtotal)), // Sử dụng giá trị từ props
                        _buildSummaryRow(
                            'Phí vận chuyển:', formatCurrency(shippingFee)),
                        if (taxAmount > 0)
                          _buildSummaryRow(
                              'Thuế VAT (${(taxRate * 100).toStringAsFixed(0)}%):',
                              formatCurrency(taxAmount)),
                        if (discountAmount > 0)
                          _buildSummaryRow('Giảm giá voucher:',
                              '-${formatCurrency(discountAmount)}',
                              isDiscount: true), // Thêm isDiscount

                        const Divider(height: 24, thickness: 1), // Dày hơn

                        // Tổng thanh toán cuối cùng
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng thanh toán:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17.0, // To hơn
                              ),
                            ),
                            Text(
                              formatCurrency(
                                  totalAmount), // Sử dụng giá trị từ props
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 19.0, // To hơn nữa
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        // if (taxAmount > 0) // Chỉ hiển thị nếu có thuế
                        //   Padding(
                        //     padding: const EdgeInsets.only(top: 4.0, left: 0), // Canh phải
                        //     child: Text(
                        //       '(Đã bao gồm thuế VAT)',
                        //       style: TextStyle(
                        //         fontSize: 12,
                        //         color: Colors.grey.shade600,
                        //         fontStyle: FontStyle.italic,
                        //       ),
                        //        textAlign: TextAlign.right,
                        //     ),
                        //   ),

                        const SizedBox(height: 24.0),

                        // Place Order Button
                        _buildPlaceOrderButton(), // Sử dụng hàm đã sửa

                        const SizedBox(height: 16.0),

                        // Terms and Conditions Text
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

  // --- Helper Widgets ---

  // Helper widget để tạo các container section đồng nhất
  Widget _buildSectionContainer(
      {required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin:
          const EdgeInsets.only(bottom: 0), // Bỏ margin nếu section liền nhau
      decoration: BoxDecoration(
        color: Colors.white, // Nền trắng cho các section bên trong
        // border: Border.all(color: Colors.grey.shade200), // Bỏ viền nếu không muốn
        borderRadius: BorderRadius.circular(8), // Bo góc nhẹ
        // Thêm shadow nhẹ cho từng section nếu muốn
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.grey.withOpacity(0.08),
        //     spreadRadius: 0,
        //     blurRadius: 4,
        //     offset: Offset(0, 2),
        //   ),
        // ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17.0, // Cỡ chữ title section
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16.0), // Khoảng cách dưới title
          child,
        ],
      ),
    );
  }

  // Helper widget cho header bảng sản phẩm desktop
  Widget _buildDesktopProductHeader() {
    return Padding(
      padding: const EdgeInsets.only(
          bottom: 10.0, left: 8, right: 8), // Thêm padding ngang
      child: Row(
        children: const [
          SizedBox(width: 60 + 16), // Image width + padding
          Expanded(
            flex: 4, // Tăng flex cho tên SP
            child: Text(
              'Sản phẩm', // Đổi thành "Sản phẩm"
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey), // Đậm vừa, màu xám
            ),
          ),
          Expanded(
            flex: 2, // Giảm flex
            child: Center(
              child: Text(
                'Đơn giá',
                style:
                    TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            flex: 1, // Giảm flex
            child: Center(
              child: Text(
                'SL', // Viết tắt Số lượng
                style:
                    TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            flex: 2, // Tăng flex
            child: Align(
              // Canh phải
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

  // Helper widget cho dòng tổng kết
  Widget _buildSummaryRow(String label, String value,
      {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0), // Giảm padding dọc
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Canh đều 2 bên
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 14, color: Colors.grey.shade700), // Màu nhạt hơn
          ),
          // const SizedBox(width: 16), // Không cần SizedBox nếu dùng SpaceBetween
          Text(
            value,
            style: TextStyle(
              fontSize: 14.5, // To hơn chút
              fontWeight: FontWeight.w500, // Đậm vừa
              color: isDiscount
                  ? Colors.green.shade700
                  : Colors.black87, // Màu xanh cho giảm giá
            ),
          ),
        ],
      ),
    );
  }

  // Giữ nguyên các hàm build item sản phẩm (Desktop/Mobile) và address (Mobile)
  // Chỉ cần đảm bảo chúng sử dụng dữ liệu từ props (`currentAddress`, `products`, `formatCurrency`)
  // và gọi đúng callbacks (`onChangeAddress`, `onSelectVoucher`).

  // --- Widget cho hiển thị sản phẩm trên màn hình lớn (Desktop) ---
  Widget _buildDesktopProductItem(Map<String, dynamic> product) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 12.0, horizontal: 8.0), // Thêm padding ngang
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ảnh
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(4),
                image: DecorationImage(
                  image: NetworkImage(product['image']),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) =>
                      Icon(Icons.error), // Xử lý lỗi tải ảnh
                )),
            // child: Image.network(
            //   product['image'],
            //   fit: BoxFit.cover,
            //   errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, color: Colors.grey), // Placeholder khi lỗi ảnh
            // ),
          ),
          const SizedBox(width: 16), // Tăng padding

          // Tên sản phẩm
          Expanded(
            flex: 4, // Bằng flex header
            child: Text(
              product['name'],
              style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Đơn giá
          Expanded(
            flex: 2, // Bằng flex header
            child: Center(
              child: Text(
                formatCurrency(
                    product['price']), // Sử dụng formatCurrency từ props
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),

          // Số lượng
          Expanded(
            flex: 1, // Bằng flex header
            child: Center(
              child: Text(
                '${product['quantity']}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),

          // Thành tiền
          Expanded(
            flex: 2, // Bằng flex header
            child: Align(
              // Canh phải
              alignment: Alignment.centerRight,
              child: Text(
                formatCurrency(product['price'] *
                    product['quantity']), // Sử dụng formatCurrency
                style: TextStyle(
                  fontSize: 14.5, // To hơn chút
                  fontWeight: FontWeight.w500, // Đậm vừa
                  color: Colors.red.shade700, // Màu đỏ đậm hơn
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget cho hiển thị sản phẩm trên màn hình nhỏ (Mobile) ---
  Widget _buildMobileProductItem(Map<String, dynamic> product) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0.5, // Thêm shadow nhẹ
      shape: RoundedRectangleBorder(
        side: BorderSide(
            color: Colors.grey.shade200, width: 0.5), // Viền mỏng hơn
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Phần trên: Ảnh và Tên
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 65, // To hơn chút
                  height: 65,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(4),
                      image: DecorationImage(
                        image: NetworkImage(product['image']),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) => Icon(Icons.error),
                      )),
                  // child: Image.network(
                  //    product['image'],
                  //    fit: BoxFit.cover,
                  //    errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, color: Colors.grey),
                  //  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    product['name'],
                    style: const TextStyle(
                      fontSize: 14.5, // To hơn chút
                      fontWeight: FontWeight.w500, // Đậm vừa
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

            // Phần dưới: Giá, Số lượng, Thành tiền
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMobilePriceColumn(
                    'Đơn giá', formatCurrency(product['price'])),
                _buildMobilePriceColumn('Số lượng', 'x ${product['quantity']}'),
                _buildMobilePriceColumn('Thành tiền',
                    formatCurrency(product['price'] * product['quantity']),
                    isTotal: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper cho cột giá/sl/tổng tiền trên mobile
  Widget _buildMobilePriceColumn(String label, String value,
      {bool isTotal = false}) {
    return Column(
      crossAxisAlignment:
          isTotal ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5, // Nhỏ hơn chút
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.5, // To hơn chút
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? Colors.red.shade700 : Colors.black87,
          ),
        ),
      ],
    );
  }

  // --- Widget cho phần địa chỉ trên Mobile ---
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
                color: Color.fromARGB(255, 201, 201, 201),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onChangeAddress, // Gọi callback
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
                padding: EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4), // Padding nhỏ hơn
              ),
              child: const Text('Thay Đổi',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8), // Thêm khoảng cách
        Padding(
          padding:
              const EdgeInsets.only(left: 28.0), // Thụt lề bằng icon + SizedBox
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${currentAddress.name} | ${currentAddress.phone}', // Gộp tên và SĐT
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 14.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                currentAddress.fullAddress, // Sử dụng fullAddress
                style: TextStyle(fontSize: 14.0, color: Colors.grey.shade700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Widget cho phần voucher trên Mobile ---
  Widget _buildMobileVoucherSection() {
    final bool hasVoucher = currentVoucher != null;
    final currencyFormatter = NumberFormat("#,###", "vi_VN");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Canh trái
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
              // Hiển thị tiền giảm nếu có voucher
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
          // Để nút chiếm full width
          width: double.infinity,
          child: OutlinedButton.icon(
            // Dùng OutlinedButton cho khác biệt
            onPressed: onSelectVoucher, // Gọi callback
            icon: Icon(Icons.search,
                size: 18, color: Colors.blue.shade700), // Icon tìm kiếm
            label: Text(
              hasVoucher ? 'Xem / Đổi Voucher' : 'Chọn hoặc nhập mã',
              style: TextStyle(
                  color: Colors.blue.shade700, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.blue.shade200), // Viền xanh nhạt
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
