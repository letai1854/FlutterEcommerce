import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
class bodySuccessPayment extends StatefulWidget {
  const bodySuccessPayment({super.key});

  @override
  State<bodySuccessPayment> createState() => _bodySuccessPaymentState();
}

class _bodySuccessPaymentState extends State<bodySuccessPayment> {
  // Helper method to format currency
  String _formatCurrency(num amount) {
    final formatter = NumberFormat("#,###", "vi_VN");
    return '₫${formatter.format(amount)}';
  }

  // Mock order data
  final Map<String, dynamic> orderData = {
    'customerID': 'KH12345678',
    'customerName': 'Tuấn Tú',
    'address': 'Gần Nhà Thờ An Phú An Giang, Thị Trấn An Phú, Huyện An Phú, An Giang',
    'phone': '(+84) 583541716',
    'orderID': 'SHOP2024061500123',
    'createdTime': DateTime.now(),
    'paymentMethod': 'Thanh toán khi nhận hàng',
    'itemsTotal': 42000,
    'shippingFee': 30000,
    'tax': 4200,
    'discount': 0,
    'totalAmount': 76200,
  };
  
  @override
  Widget build(BuildContext context) {
    // Check if we're on a small screen (mobile)
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    
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
                  _buildOrderInfoSection(isMobile),
                  
                  SizedBox(height: 32),
                  
                  // Payment summary
                  _buildPaymentSummarySection(isMobile),
                  
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
                      Navigator.of(context).pushNamed('/');
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
  Widget _buildOrderInfoSection(bool isMobile) {
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
          _buildInfoRow('Mã khách hàng:', orderData['customerID'], isMobile),
          _buildInfoRow('Họ và tên:', orderData['customerName'], isMobile),
          _buildInfoRow('Địa chỉ:', orderData['address'], isMobile, isMultiLine: true),
          _buildInfoRow('Số điện thoại:', orderData['phone'], isMobile),
          _buildInfoRow('Mã đơn hàng:', orderData['orderID'], isMobile),
          _buildInfoRow(
            'Thời gian tạo:',
            DateFormat('dd/MM/yyyy HH:mm:ss').format(orderData['createdTime']),
            isMobile,
          ),
          _buildInfoRow('Phương thức thanh toán:', orderData['paymentMethod'], isMobile),
        ],
      ),
    );
  }
  
  // Build payment summary section
  Widget _buildPaymentSummarySection(bool isMobile) {
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
          
          // Payment info
          _buildPaymentRow('Tổng tiền hàng:', _formatCurrency(orderData['itemsTotal']), isMobile),
          _buildPaymentRow('Phí vận chuyển:', _formatCurrency(orderData['shippingFee']), isMobile),
          _buildPaymentRow('Thuế VAT (10%):', _formatCurrency(orderData['tax']), isMobile),
          _buildPaymentRow('Giảm giá voucher:', _formatCurrency(orderData['discount']), isMobile),
          
          Divider(height: 32),
          
          // Total amount
          _buildPaymentRow(
            'Tổng thanh toán:',
            _formatCurrency(orderData['totalAmount']),
            isMobile,
            isTotal: true,
          ),
        ],
      ),
    );
  }
  
  // Helper method to build information row
  Widget _buildInfoRow(String label, String value, bool isMobile, {bool isMultiLine = false}) {
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
  Widget _buildPaymentRow(String label, String value, bool isMobile, {bool isTotal = false}) {
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
