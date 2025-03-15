import 'package:e_commerce_app/widgets/Payment/AddressSelector.dart';
import 'package:e_commerce_app/widgets/Payment/VoucherSelector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
class bodyPayment extends StatefulWidget {
  const bodyPayment({Key? key}) : super(key: key);

  @override
  State<bodyPayment> createState() => _bodyPaymentDesktopState();
}

class _bodyPaymentDesktopState extends State<bodyPayment> {
  // Mock product data
  final List<Map<String, dynamic>> products = [
    {
      'image': 'https://i.imgur.com/kZTgHwQ.png',
      'name': 'Điều Khiển Từ Xa Thay Thế Chuyên Dụng Cho...',
      'price': 42000,
      'quantity': 1,
    },
  ];

  // Current selected address data
  AddressData _currentAddress = AddressData(
    name: 'Tuấn Tú',
    phone: '(+84) 583541716',
    address: 'Gần Nhà Thờ An Phú An Giang, Thị Trấn An Phú, Huyện An Phú, An Giang',
    isDefault: true,
  );
  
  // Current selected voucher data
  VoucherData? _currentVoucher;

  // Add state to track selected payment method
  String _selectedPaymentMethod = 'Thanh toán khi nhận hàng'; // Default payment method

  // Helper method to format currency
  String _formatCurrency(num amount) {
    final formatter = NumberFormat("#,###", "vi_VN");
    return '₫${formatter.format(amount)}';
  }
  
  // Thêm debug print để kiểm tra xem hàm có được gọi không
  void _openVoucherDialog() {
    print('Opening voucher dialog');
    try {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: VoucherSelector(
              onVoucherSelected: (voucher) {
                setState(() {
                  _currentVoucher = voucher;
                  print('Voucher selected: ${voucher?.code}');
                });
              },
            ),
          );
        },
      ).then((_) {
        print('Dialog closed');
      }).catchError((error) {
        print('Error showing dialog: $error');
      });
    } catch (e) {
      print('Exception occurred: $e');
    }
  }

  // Improve address display with more visual separation
  Widget _buildAddressDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Địa Chỉ Nhận Hàng',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              _currentAddress.name,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14.0
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _currentAddress.phone,
              style: TextStyle(fontSize: 14.0),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          _currentAddress.address,
          style: TextStyle(fontSize: 14.0),
        ),
      ],
    );
  }

  // Method to update the current address that forces UI to refresh
  void _updateAddress(AddressData address) {
    print("Updating address to: ${address.name}");
    setState(() {
      _currentAddress = address;
      print("Address updated in state: ${_currentAddress.name}");
    });
  }

  // Thêm biến tax rate với giá trị rõ ràng hơn
  final double _taxRate = 0.1; // 10% thuế
  
  @override
  Widget build(BuildContext context) {
    // Thêm kiểm tra chiều rộng màn hình để xác định thiết bị
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    
    // Calculate discount amount
    final int discountAmount = _currentVoucher != null 
        ? (_currentVoucher!.isPercent 
            ? ((products.fold<num>(0, (sum, product) => sum + product['price'] * product['quantity']) * _currentVoucher!.discountAmount) ~/ 100) 
            : _currentVoucher!.discountAmount)
        : 0;
    
    // Tính tổng tiền hàng - đảm bảo kết quả là int
    final int itemsTotal = products.fold<int>(0, (int sum, dynamic product) => 
        sum + ((product['price'] as num).toInt() * (product['quantity'] as int)));
        
    // Tính tiền thuế - đảm bảo kết quả không bị làm tròn xuống 0
    final int taxAmount = (itemsTotal * _taxRate).ceil(); // Sử dụng ceil để làm tròn lên
    print('Tax calculation: $itemsTotal * $_taxRate = $taxAmount'); // Debug print
    
    // Calculate final total - bao gồm cả thuế
    final int totalAmount = itemsTotal + 30000 + taxAmount - discountAmount;

    
    return SingleChildScrollView(
      child: Container(
        color: Colors.grey[200], // Match background color with scaffold
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20.0),
            constraints: BoxConstraints(maxWidth: 1000), // Reduced max width
            margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Address Section - Responsive layout
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isMobile ? _buildMobileAddressSection() : _buildDesktopAddressSection(),
                ),
                const SizedBox(height: 20.0),

                // Product Section
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sản phẩm',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      
                      // Header row - chỉ hiện trên desktop
                      if (!isMobile)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Row(
                            children: [
                              SizedBox(width: 60), // Space for image
                              Expanded(
                                flex: 3,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: Text(
                                    'Tên sản phẩm',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Center(
                                  child: Text(
                                    'Đơn giá',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1, 
                                child: Center(
                                  child: Text(
                                    'Số lượng',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Center(
                                  child: Text(
                                    'Thành tiền',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      Divider(),
                      
                      // Product list với layout khác nhau dựa trên kích thước màn hình
                      ...products.map((product) => isMobile
                          ? _buildMobileProductItem(product)
                          : _buildDesktopProductItem(product)
                      ),
                      
                      Divider(),
                      
                      // Voucher row centered - make responsive
                      isMobile 
                      ? _buildMobileVoucherSection()
                      : Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Checkbox(
                                value: _currentVoucher != null,
                                onChanged: (bool? value) {
                                  if (value == false) {
                                    setState(() {
                                      _currentVoucher = null;
                                    });
                                  } else {
                                    _openVoucherDialog();
                                  }
                                },
                                activeColor: Colors.red,
                              ),
                              Text('Voucher của Shop'),
                              const SizedBox(width: 16),
                              TextButton.icon(
                                onPressed: _openVoucherDialog,
                                icon: Icon(Icons.card_giftcard, color: Colors.red), 
                                label: Text(
                                  _currentVoucher != null ? _currentVoucher!.code : 'Chọn Voucher', 
                                  style: TextStyle(color: Colors.red),
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.red.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),

                // Payment Method Section
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Phương thức thanh toán',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      Center(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildPaymentOption(
                              'Ngân hàng', 
                              Icons.credit_card, 
                              _selectedPaymentMethod == 'Ngân hàng'  // Fixed the typo here
                            ),
                            _buildPaymentOption(
                              'Thanh toán khi nhận hàng', 
                              Icons.local_shipping, 
                              _selectedPaymentMethod == 'Thanh toán khi nhận hàng'
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      Text(
                        'Thanh toán khi nhận hàng. Phí thu hộ: 40 VNĐ. Ưu đãi về phí vận chuyển (nếu có) áp dụng cả với phí thu hộ.',
                        style: TextStyle(fontSize: 12.0, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),

                // Order Summary Section
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tổng thanh toán',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      
                      // Right-aligned payment summary
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text('Tổng tiền hàng:', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 16),
                                Text(
                                  _formatCurrency(itemsTotal),
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text('Phí vận chuyển:', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 16),
                                Text(
                                  _formatCurrency(30000),
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            // Thêm dòng thuế với style nổi bật hơn
                            const SizedBox(height: 8.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Thuế VAT (10%):',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  _formatCurrency(taxAmount),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 8.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text('Giảm giá voucher:', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 16),
                                Text(
                                  _formatCurrency(discountAmount),
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16.0),
                            Divider(),
                            const SizedBox(height: 8.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Tổng thanh toán:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  _formatCurrency(totalAmount),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18.0,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            
                            // Thêm chi tiết thuế
                            const SizedBox(height: 4),
                            Text(
                              '(Đã bao gồm thuế VAT)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20.0),
                      
                      // Place Order Button - Right aligned
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {},
                          child: Text(
                            'Đặt hàng',
                            style: TextStyle(
                              color: Colors.white, 
                              fontSize: 16, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 10.0),
                      
                      // Terms and Conditions Text
                      Center(
                        child: Text(
                          'Nhấn "Đặt hàng" đồng nghĩa với việc bạn đồng ý tuân theo Điều khoản Shopii',
                          style: TextStyle(fontSize: 12.0, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Updated method to build payment options with tap detection
  Widget _buildPaymentOption(String title, IconData icon, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = title;
          print('Selected payment method: $_selectedPaymentMethod');
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.red : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
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
                color: isSelected ? Colors.red : Colors.grey.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.red : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Widget cho hiển thị sản phẩm trên màn hình lớn (Desktop)
  Widget _buildDesktopProductItem(Map<String, dynamic> product) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Image.network(
              product['image'],
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                product['name'],
                style: TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                _formatCurrency(product['price']),
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                '${product['quantity']}',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                _formatCurrency(product['price'] * product['quantity']),
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.bold,
                  color: Colors.red
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Widget mới cho hiển thị sản phẩm trên màn hình nhỏ (Mobile)
  Widget _buildMobileProductItem(Map<String, dynamic> product) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phần trên: ảnh và thông tin sản phẩm
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ảnh sản phẩm
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Image.network(
                    product['image'],
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 12),
                
                // Tên sản phẩm
                Expanded(
                  child: Text(
                    product['name'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            Divider(height: 1),
            SizedBox(height: 12),
            
            // Phần dưới: giá, số lượng, thành tiền
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Cột đơn giá
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đơn giá',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatCurrency(product['price']),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                // Cột số lượng
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Số lượng',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${product['quantity']}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                // Cột thành tiền
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Thành tiền',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatCurrency(product['price'] * product['quantity']),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // New method for desktop address section
  Widget _buildDesktopAddressSection() {
    return Row(
      children: [
        Icon(Icons.location_on, color: Colors.red),
        const SizedBox(width: 8.0),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildAddressDisplay(),
          ),
        ),
        TextButton(
          onPressed: () {
            print("Opening address selector dialog");
            showAddressSelectorDialog(
              context, 
              _updateAddress,
            );
          },
          child: Text('Thay Đổi'),
        ),
      ],
    );
  }
  
  // New method for mobile address section
  Widget _buildMobileAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on, color: Colors.red),
            const SizedBox(width: 8.0),
            Text(
              'Địa Chỉ Nhận Hàng',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            Spacer(),
            TextButton(
              onPressed: () {
                print("Opening address selector dialog");
                showAddressSelectorDialog(
                  context, 
                  _updateAddress,
                );
              },
              child: Text('Thay Đổi'),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentAddress.name,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14.0
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currentAddress.phone,
                style: TextStyle(fontSize: 14.0),
              ),
              const SizedBox(height: 4),
              Text(
                _currentAddress.address,
                style: TextStyle(fontSize: 14.0),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // New method for mobile voucher section
  Widget _buildMobileVoucherSection() {
    return Column(
      children: [
        Row(
          children: [
            Checkbox(
              value: _currentVoucher != null,
              onChanged: (bool? value) {
                if (value == false) {
                  setState(() {
                    _currentVoucher = null;
                  });
                } else {
                  _openVoucherDialog();
                }
              },
              activeColor: Colors.red,
            ),
            Text('Voucher của Shop'),
            Spacer(),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 8),
          child: TextButton.icon(
            onPressed: _openVoucherDialog,
            icon: Icon(Icons.card_giftcard, color: Colors.red), 
            label: Text(
              _currentVoucher != null ? _currentVoucher!.code : 'Chọn Voucher', 
              style: TextStyle(color: Colors.red),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(vertical: 12),
              minimumSize: Size(double.infinity, 0), // Full width button
            ),
          ),
        ),
      ],
    );
  }
}
