import 'package:flutter/material.dart';
// Import necessary libraries for handling different image sources on different platforms
import 'dart:io'; // Required for Image.file
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:intl/intl.dart'; // Required for currency formatting


class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({Key? key, required this.order}) : super(key: key);

  // Helper function to build detail rows
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150, // Adjust width as needed
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build image widget from source (Handles Asset, File, Network based on platform)
  // This function is reusable for displaying images from various sources.
  Widget _buildImageDisplayWidget(String? imageSource, {double size = 40, double iconSize = 30, BoxFit fit = BoxFit.cover}) {
      if (imageSource == null || imageSource.isEmpty) {
        return Icon(Icons.image_not_supported, size: iconSize, color: Colors.grey); // Placeholder if no image source
      }

      // Check if it's an asset path (simple check)
      if (imageSource.startsWith('assets/')) {
         return Image.asset(
              imageSource,
              fit: fit,
               errorBuilder: (context, error, stackTrace) {
                   print('Error loading asset: $imageSource, Error: $error'); // Debugging
                   return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
               },
         );
      } else if (imageSource.startsWith('http') || imageSource.startsWith('https')) {
          // Assume it's a network URL
           return Image.network(
               imageSource,
               fit: fit,
                errorBuilder: (context, error, stackTrace) {
                   print('Error loading network image: $imageSource, Error: $error'); // Debugging
                   return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
               },
           );
      }
      else if (kIsWeb) {
          // On web, if not asset or http, assume it's a web-specific path like a blob URL or file name
           return Image.network( // On web, try network as a fallback for non-http paths too
               imageSource,
               fit: fit,
                errorBuilder: (context, error, stackTrace) {
                   print('Error loading web path (fallback): $imageSource, Error: $error'); // Debugging
                   return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
               },
           );
      }
      else {
        // On non-web, if not asset or http, assume it's a file path
         try {
           return Image.file(
               File(imageSource),
               fit: fit,
                errorBuilder: (context, error, stackTrace) {
                   print('Error loading file: $imageSource, Error: $error'); // Debugging
                   return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
               },
           );
         } catch (e) {
           print('Exception creating File from path: $imageSource, Exception: $e'); // Debugging
           return Icon(Icons.error_outline, size: iconSize, color: Colors.red);
         }
      }
    }


  @override
  Widget build(BuildContext context) {
    // Extract data from the order map with null checks
    final String orderId = order['order_id'] ?? 'N/A';
    final String customerName = order['ten_nguoi_nhan'] ?? order['customer'] ?? 'N/A'; // Fallback to 'customer' if 'ten_nguoi_nhan' is missing
    final String phoneNumber = order['so_dien_thoai_nguoi_nhan'] ?? 'N/A';
    final String shippingAddress = order['dia_chi_giao_hang'] ?? 'N/A';
    final double originalTotal = (order['tong_tien_hang_goc'] as num?)?.toDouble() ?? 0.0;
    final double couponDiscount = (order['tien_giam_gia_coupon'] as num?)?.toDouble() ?? 0.0;
    final double pointsUsed = (order['tien_su_dung_diem'] as num?)?.toDouble() ?? 0.0;
    final double shippingFee = (order['phi_van_chuyen'] as num?)?.toDouble() ?? 0.0;
    final double tax = (order['thue'] as num?)?.toDouble() ?? 0.0;
    final double grandTotal = (order['tong_thanh_toan'] as num?)?.toDouble() ?? 0.0;
    final String paymentMethod = order['phuong_thuc_thanh_toan'] ?? 'N/A';
    final String paymentStatus = order['trang_thai_thanh_toan'] ?? 'N/A';
    final String orderStatus = order['trang_thai_don_hang'] ?? 'N/A';
    final double earnedPoints = (order['diem_tich_luy'] as num?)?.toDouble() ?? 0.0;
    // Dates might be DateTime objects or Strings depending on how you loaded them
    // Assuming DateTimes might be passed from OrderScreen, format them here
    final DateTime? orderDate = order['ngay_dat_hang'] is DateTime ? order['ngay_dat_hang'] : null;
    final DateTime? updatedDate = order['ngay_cap_nhat'] is DateTime ? order['ngay_cap_nhat'] : null;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');


    // Assuming 'chi_tiet' is the key for order items list in the passed map
    final List<Map<String, dynamic>> orderItems = List<Map<String, dynamic>>.from(order['chi_tiet'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết Đơn hàng: $orderId'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin chung',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildDetailRow('Mã đơn hàng', orderId),
            _buildDetailRow('Ngày đặt hàng', orderDate != null ? dateFormat.format(orderDate.toLocal()) : 'N/A'), // Format date
            _buildDetailRow('Ngày cập nhật', updatedDate != null ? dateFormat.format(updatedDate.toLocal()) : 'N/A'), // Format date
            _buildDetailRow('Trạng thái đơn hàng', orderStatus),
            _buildDetailRow('Trạng thái thanh toán', paymentStatus),
            _buildDetailRow('Phương thức thanh toán', paymentMethod),
            const SizedBox(height: 20),

            Text(
              'Thông tin người nhận',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildDetailRow('Tên người nhận', customerName),
            _buildDetailRow('Số điện thoại', phoneNumber),
            _buildDetailRow('Địa chỉ giao hàng', shippingAddress),
             const SizedBox(height: 20),

            Text(
              'Giá trị đơn hàng',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
             // Use NumberFormat for currency display
            _buildDetailRow('Tổng tiền hàng gốc', NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ', decimalDigits: 0).format(originalTotal)),
            _buildDetailRow('Tiền giảm giá Coupon', NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ', decimalDigits: 0).format(couponDiscount)),
            _buildDetailRow('Tiền sử dụng điểm', NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ', decimalDigits: 0).format(pointsUsed)),
            _buildDetailRow('Phí vận chuyển', NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ', decimalDigits: 0).format(shippingFee)),
            _buildDetailRow('Thuế', NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ', decimalDigits: 0).format(tax)),
            _buildDetailRow('Tổng thanh toán', NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ', decimalDigits: 0).format(grandTotal)),
            _buildDetailRow('Điểm tích lũy', '${earnedPoints.toStringAsFixed(0)} điểm'), // Points usually not currency
            const SizedBox(height: 20),

            Text(
              'Danh sách sản phẩm',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            orderItems.isEmpty
                ? const Text('Chưa có sản phẩm trong đơn hàng này.')
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orderItems.length,
                    itemBuilder: (context, index) {
                      final item = orderItems[index];
                      final itemPriceAtPurchase = (item['gia_tai_thoi_diem_mua'] as num?)?.toDouble() ?? 0.0;
                      final itemDiscountPercent = (item['phan_tram_giam_gia_san_pham'] as num?)?.toDouble() ?? 0.0;
                      final itemSubtotal = (item['thanh_tien'] as num?)?.toDouble() ?? 0.0;
                      final itemImage = item['anh_bien_the']?.toString(); // Get image path/URL


                      return Card(
                         margin: const EdgeInsets.symmetric(vertical: 4),
                         child: Padding(
                           padding: const EdgeInsets.all(8.0),
                           child: Row( // Use Row to place image next to text details
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               // Add image here
                               Container(
                                   width: 60, // Set image size
                                   height: 60,
                                   decoration: BoxDecoration(
                                       borderRadius: BorderRadius.circular(4),
                                        color: Colors.grey[200], // Background if image fails
                                   ),
                                   clipBehavior: Clip.antiAlias,
                                   child: _buildImageDisplayWidget(itemImage, size: 60, iconSize: 30), // Use helper to display image
                               ),
                               const SizedBox(width: 8), // Spacing between image and text

                               Expanded( // Allow text details to take remaining space
                                   child: Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       Text(
                                         item['ten_bien_the'] ?? 'Sản phẩm [Không tên]',
                                         style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                       ),
                                       const SizedBox(height: 4),
                                       Text('Số lượng: ${item['so_luong'] ?? 'N/A'}', style: TextStyle(fontSize: 13)),
                                       Text('Giá lúc mua: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ', decimalDigits: 0).format(itemPriceAtPurchase)}', style: TextStyle(fontSize: 13)),
                                       if (itemDiscountPercent > 0) // Only show discount if > 0
                                         Text('Giảm giá SP: ${itemDiscountPercent.toStringAsFixed(0)}%', style: TextStyle(fontSize: 13)),
                                       Text('Thành tiền: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ', decimalDigits: 0).format(itemSubtotal)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                     ],
                                   ),
                               ),
                             ],
                           ),
                         ),
                       );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
