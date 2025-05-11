import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Cần import intl ở đây

class bodySuccessPayment extends StatefulWidget {
  // *** Thêm trường final để lưu trữ orderData ***
  final Map<String, dynamic> orderData;
  final double totalDiscount; // Change from nullable to non-nullable

  // *** Sửa đổi constructor để yêu cầu orderData và totalDiscount ***
  const bodySuccessPayment({
    super.key,
    required this.orderData,
    required this.totalDiscount,
  });

  @override
  State<bodySuccessPayment> createState() => _bodySuccessPaymentState();
}

class _bodySuccessPaymentState extends State<bodySuccessPayment> {
  // --- Thêm hàm _formatCurrency vào đây vì nó được sử dụng ở đây ---
  String _formatCurrency(num amount) {
    final formatter = NumberFormat("#,##0 đ", "en_US"); 
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're on a small screen (mobile)
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    // *** Truy cập orderData thông qua widget.orderData ***
    final orderData = widget.orderData; // Lấy dữ liệu từ widget

    // Kiểm tra null an toàn hơn cho các giá trị trong orderData nếu cần
    final String customerID = orderData['customerID'] ?? 'N/A';
    final String customerName = orderData['customerName'] ?? 'N/A';
    final String address = orderData['address'] ?? 'N/A';
    final String phone = orderData['phone'] ?? 'N/A';
    final String orderID = orderData['orderID'] ?? 'N/A';
    final DateTime createdTime = orderData['createdTime'] ?? DateTime.now();
    final String paymentMethod = orderData['paymentMethod'] ?? 'N/A';
    final num itemsTotal = orderData['itemsTotal'] ?? 0;
    final num shippingFee = orderData['shippingFee'] ?? 0;
    final num tax = orderData['tax'] ?? 0;
    final num discount = orderData['discount'] ?? 0;
    final num totalAmount = orderData['totalAmount'] ?? 0;

    return SingleChildScrollView(
      child: Container(
        color: Colors.grey[100],
        width: double.infinity,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 800),
            child: Container(
              margin: EdgeInsets.all(24),
              padding: EdgeInsets.all(isMobile ? 16 : 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Success icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Colors.green,
                    ),
                  ),

                  SizedBox(height: 24),

                  // Success message
                  Text(
                    'Đặt hàng thành công!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    'Cảm ơn bạn đã mua hàng tại Topick Global',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),

                  SizedBox(height: 32),

                  // Order information
                  _buildOrderInfoSection(
                      isMobile, orderData), // Truyền orderData vào hàm helper

                  SizedBox(height: 32),

                  // Payment summary
                  _buildPaymentSummarySection(
                      isMobile, orderData), // Truyền orderData vào hàm helper

                  SizedBox(height: 32),

                  // Back to home button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 32 : 48,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () {
                      // Navigate back to home or order history
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          '/',
                          (Route<dynamic> route) =>
                              false); // Quay về home và xóa các trang trước đó
                    },
                    child: Text(
                      'Quay về trang chủ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build order information section
  // *** Sửa đổi hàm để nhận orderData ***
  Widget _buildOrderInfoSection(bool isMobile, Map<String, dynamic> orderData) {
    // Lấy dữ liệu từ tham số, thêm kiểm tra null nếu cần
    final String customerID = orderData['customerID'] ?? 'N/A';
    final String customerName = orderData['customerName'] ?? 'N/A';
    final String address = orderData['address'] ?? 'N/A';
    final String phone = orderData['phone'] ?? 'N/A';
    final String orderID = orderData['orderID'] ?? 'N/A';
    final DateTime createdTime = orderData['createdTime'] ?? DateTime.now();
    final String paymentMethod = orderData['paymentMethod'] ?? 'N/A';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin đơn hàng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 16),

          // Order information items
          _buildInfoRow('Mã khách hàng:', customerID, isMobile),
          _buildInfoRow('Họ và tên:', customerName, isMobile),
          _buildInfoRow('Địa chỉ:', address, isMobile, isMultiLine: true),
          _buildInfoRow('Số điện thoại:', phone, isMobile),
          _buildInfoRow('Mã đơn hàng:', orderID, isMobile),
          _buildInfoRow(
            'Thời gian tạo:',
            // Đảm bảo createdTime không null trước khi format
            createdTime != null
                ? DateFormat('dd/MM/yyyy HH:mm:ss').format(createdTime)
                : 'N/A',
            isMobile,
          ),
          _buildInfoRow('Phương thức thanh toán:', paymentMethod, isMobile),
        ],
      ),
    );
  }

  // Build payment summary section
  // *** Sửa đổi hàm để nhận orderData ***
  Widget _buildPaymentSummarySection(
      bool isMobile, Map<String, dynamic> orderData) {
    // Get data from orderData with proper defaults
    final num originalItemsTotal = orderData['sumOriginalItemPrices'] ?? orderData['itemsTotal'] ?? 0;
    final num shippingFee = orderData['shippingFee'] ?? 0;
    final num tax = orderData['tax'] ?? 0;
    final num discount = orderData['discount'] ?? 0;
    final num pointsDiscount = orderData['pointsDiscount'] ?? 0;
    final num usedPoints = orderData['usedPoints'] ?? 0;
    final num productDiscount = widget.totalDiscount;
    final num updatedPointsBalance = orderData['updatedPointsBalance'] ?? UserInfo().currentUser?.customerPoints ?? 0;
    
    // Make sure we correctly calculate the true original total by adding back the product discount
    final num trueOriginalTotal = originalItemsTotal + productDiscount;
    
    // Recalculate the total amount correctly with all discounts
    final num calculatedTotal = trueOriginalTotal - productDiscount + shippingFee + tax - discount - pointsDiscount;
    
    // Use our calculated total instead of the one from orderData which might not include all discounts
    final num displayTotal = calculatedTotal > 0 ? calculatedTotal : 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin thanh toán',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 16),

          // Show the TRUE original price before ANY discounts
          _buildPaymentRow(
              'Tổng tiền hàng:', _formatCurrency(trueOriginalTotal), isMobile),
              
          // Show product discount (if any)
          if (productDiscount > 0)
            _buildPaymentRow('Giảm giá sản phẩm:', _formatCurrency(-productDiscount), isMobile, 
                isDiscount: true),
                
          _buildPaymentRow(
              'Phí vận chuyển:', _formatCurrency(shippingFee), isMobile),
              
          _buildPaymentRow('Thuế VAT (10%):', _formatCurrency(tax), isMobile),
          
          // Format voucher discount with negative sign
          if (discount > 0)
            _buildPaymentRow(
                'Giảm giá voucher:', _formatCurrency(-discount), isMobile,
                isDiscount: true),
                
          // Add points discount row
          if (pointsDiscount > 0)
            _buildPaymentRow(
                'Sử dụng điểm tích lũy (${usedPoints.toInt()} điểm):', 
                _formatCurrency(-pointsDiscount), isMobile,
                isDiscount: true),
                
          // Show updated points balance if points were used
          if (pointsDiscount > 0)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                'Điểm tích lũy còn lại: ${updatedPointsBalance.toStringAsFixed(0)} điểm',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          Divider(height: 32),

          // Total amount - use our recalculated total
          _buildPaymentRow(
            'Tổng thanh toán:',
            _formatCurrency(displayTotal),
            isMobile,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  // Helper method to build information row
  Widget _buildInfoRow(String label, String value, bool isMobile,
      {bool isMultiLine = false}) {
    // Đảm bảo value không null
    value = value ?? 'N/A';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: isMobile || isMultiLine
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 180,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // Helper method to build payment row
  Widget _buildPaymentRow(String label, String value, bool isMobile,
      {bool isTotal = false, bool isDiscount = false}) {
    // Đảm bảo value không null
    value = value ?? '₫0';
    final TextStyle labelStyle = isTotal
        ? TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black,
          )
        : TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          );

    final TextStyle valueStyle = isTotal
        ? TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.red,
          )
        : TextStyle(
            fontSize: 15,
            // Thêm màu xanh lá cây cho các dòng giảm giá
            color: isDiscount ? Colors.green : null,
          );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: labelStyle),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
