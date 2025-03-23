import 'package:flutter/material.dart';

// Model class for voucher data
class VoucherData {
  final String code;
  final String description;
  final int discountAmount;
  final DateTime expiryDate;
  final bool isPercent;

  VoucherData({
    required this.code,
    required this.description,
    required this.discountAmount,
    required this.expiryDate,
    this.isPercent = false,
  });

  String get displayValue {
    return isPercent ? '$discountAmount%' : '₫$discountAmount';
  }
}

class VoucherSelector extends StatefulWidget {
  // Callback function when a voucher is selected
  final Function(VoucherData?) onVoucherSelected;
  
  const VoucherSelector({
    Key? key, 
    required this.onVoucherSelected,
  }) : super(key: key);

  @override
  State<VoucherSelector> createState() => _VoucherSelectorState();
}

class _VoucherSelectorState extends State<VoucherSelector> {
  // Controller for voucher code input
  final TextEditingController _codeController = TextEditingController();
  
  // Selected voucher
  VoucherData? _selectedVoucher;
  
  // Error message
  String? _errorMessage;
  
  // Sample available vouchers
  final List<VoucherData> _availableVouchers = [
    VoucherData(
      code: 'WELCOME10',
      description: 'Giảm 10% cho đơn hàng đầu tiên',
      discountAmount: 10,
      expiryDate: DateTime.now().add(Duration(days: 30)),
      isPercent: true,
    ),
    VoucherData(
      code: 'FREESHIP',
      description: 'Miễn phí vận chuyển cho đơn hàng từ 200K',
      discountAmount: 30000,
      expiryDate: DateTime.now().add(Duration(days: 7)),
    ),
    VoucherData(
      code: 'SALE50K',
      description: 'Giảm 50K cho đơn hàng từ 500K',
      discountAmount: 50000,
      expiryDate: DateTime.now().add(Duration(days: 15)),
    ),
  ];

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // Apply voucher code
  void _applyVoucher() {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập mã voucher';
      });
      return;
    }
    
    // Find voucher with matching code
    final voucher = _availableVouchers.firstWhere(
      (v) => v.code == code,
      orElse: () => throw Exception('Không tìm thấy voucher'),
    );
    
    try {
      setState(() {
        _selectedVoucher = voucher;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Mã voucher không hợp lệ hoặc đã hết hạn';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: 500,
        maxHeight: 400,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Topick Global Voucher',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: Icon(Icons.close),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
          
          Divider(),
          
          // Voucher code input row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Label
                Text(
                  'Mã voucher:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Input field
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      hintText: 'Nhập mã voucher',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _applyVoucher(),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Apply button
                ElevatedButton(
                  onPressed: _applyVoucher,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text(
                    'Áp dụng',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          
          // Error message
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                ),
              ),
            ),
          
          // Selected voucher display
          if (_selectedVoucher != null)
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
                color: Colors.red.withOpacity(0.05),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.discount, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        _selectedVoucher!.code,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _selectedVoucher!.displayValue,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_selectedVoucher!.description),
                  const SizedBox(height: 4),
                  Text(
                    'Hạn sử dụng: ${_selectedVoucher!.expiryDate.day}/${_selectedVoucher!.expiryDate.month}/${_selectedVoucher!.expiryDate.year}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ],
              ),
            ),
          
          Spacer(),
          
          // Divider and confirm button
          Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 3,
                shadowColor: Colors.red.withOpacity(0.4),
              ),
              onPressed: () {
                widget.onVoucherSelected(_selectedVoucher);
                Navigator.of(context).pop();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Xác nhận',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Dialog builder function
Future<void> showVoucherSelectorDialog(BuildContext context, Function(VoucherData?) onVoucherSelected) async {
  print("Showing voucher selector dialog");
  
  try {
    return await showDialog(  // Thay đổi thành showDialog thông thường
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: VoucherSelector(onVoucherSelected: onVoucherSelected),
        );
      },
    );
  } catch (e) {
    print("Dialog error: $e");
    return;
  }
}
