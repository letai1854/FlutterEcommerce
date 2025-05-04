import 'package:e_commerce_app/Screens/Payment/PagePayment.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import để dùng NumberFormat
// Import model nếu tách file
// import 'models/voucher_data.dart';

class VoucherSelector extends StatefulWidget {
  // --- Dữ liệu và Callbacks nhận từ PagePayment ---
  final List<VoucherData> availableVouchers; // Danh sách voucher hợp lệ
  final VoucherData? currentVoucher;         // Voucher đang được chọn bên ngoài
  final Function(VoucherData?) onVoucherSelected; // Callback khi xác nhận chọn

  // Optional: Callback nếu muốn xử lý áp mã trực tiếp từ dialog
  // final Function(String)? onApplyCode;

  const VoucherSelector({
    Key? key,
    required this.availableVouchers,
    required this.currentVoucher,
    required this.onVoucherSelected,
    // this.onApplyCode,
  }) : super(key: key);

  @override
  State<VoucherSelector> createState() => _VoucherSelectorState();
}

class _VoucherSelectorState extends State<VoucherSelector> {
  // --- State nội bộ của Dialog ---
  final TextEditingController _codeController = TextEditingController(); // Cho ô nhập mã
  VoucherData? _selectedVoucherInDialog; // Voucher đang được chọn TRONG dialog (có thể khác currentVoucher ban đầu)
  String? _errorMessage; // Thông báo lỗi khi nhập mã

  final NumberFormat _currencyFormatter = NumberFormat("#,###", "vi_VN"); // Formatter tiền tệ

  @override
  void initState() {
    super.initState();
    // Khởi tạo voucher đang chọn trong dialog bằng voucher từ PagePayment
    _selectedVoucherInDialog = widget.currentVoucher;
     print("VoucherSelector initState: Initial selected voucher: ${_selectedVoucherInDialog?.code}");
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // --- Logic xử lý nội bộ ---

  // Xử lý khi người dùng nhập mã và nhấn Áp dụng
  void _applyEnteredCode() {
    final code = _codeController.text.trim();
    setState(() {
      _errorMessage = null; // Xóa lỗi cũ
    });

    if (code.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập mã voucher');
      return;
    }

    // Tìm voucher trong danh sách được truyền vào
    try {
       // Tìm chính xác mã, không phân biệt hoa thường
      final voucher = widget.availableVouchers.firstWhere(
        (v) => v.code.toLowerCase() == code.toLowerCase(),
      );

      // Nếu tìm thấy, chọn voucher này trong dialog
      setState(() {
        _selectedVoucherInDialog = voucher;
        _errorMessage = null; // Xóa lỗi nếu trước đó có
        print("VoucherSelector: Code '$code' applied successfully, selected voucher: ${voucher.code}");
         // Có thể đóng bàn phím nếu đang mở
        FocusScope.of(context).unfocus();
        _codeController.clear(); // Xóa ô input sau khi áp dụng
      });
       // Optional: Gọi callback báo PagePayment nếu cần xử lý ngay lập tức
       // if (widget.onApplyCode != null) {
       //   widget.onApplyCode!(voucher.code);
       // }

    } catch (e) { // firstWhere ném lỗi nếu không tìm thấy
      setState(() {
         // Không thay đổi _selectedVoucherInDialog hiện tại
        _errorMessage = 'Mã không hợp lệ hoặc không áp dụng được.';
        print("VoucherSelector: Code '$code' not found in available vouchers.");
      });
    }
  }

  // Xử lý khi người dùng chọn/bỏ chọn voucher từ danh sách
  void _toggleVoucherSelection(VoucherData voucher) {
    setState(() {
      if (_selectedVoucherInDialog == voucher) {
        // Nếu nhấn vào voucher đang chọn -> Bỏ chọn
        _selectedVoucherInDialog = null;
         print("VoucherSelector: Deselected voucher: ${voucher.code}");
      } else {
        // Nếu nhấn vào voucher khác -> Chọn voucher đó
        _selectedVoucherInDialog = voucher;
         print("VoucherSelector: Selected voucher from list: ${voucher.code}");
      }
       _errorMessage = null; // Xóa lỗi khi chọn từ list
    });
  }

  // Xác nhận lựa chọn và đóng dialog
  void _confirmSelection() {
     print("VoucherSelector: Confirming selection: ${_selectedVoucherInDialog?.code}");
    widget.onVoucherSelected(_selectedVoucherInDialog); // Gọi callback báo PagePayment
    // Navigator.of(context).pop(); // PagePayment sẽ pop dialog
  }


  // --- Build Methods ---
  @override
  Widget build(BuildContext context) {
    print("VoucherSelector build: Selected voucher in dialog: ${_selectedVoucherInDialog?.code}");
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: 550, // Tăng chiều rộng tối đa chút
        maxHeight: MediaQuery.of(context).size.height * 0.7, // Giới hạn chiều cao
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(),
          const Divider(height: 1),

          // Voucher code input row
          _buildCodeInputRow(),

          // Error message
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ),

          // List of available vouchers
          Expanded(
            child: _buildVoucherList(),
          ),

          // Divider and confirm button
          const Divider(height: 1),
          _buildConfirmButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
     return Padding(
       padding: const EdgeInsets.fromLTRB(16.0, 8.0, 8.0, 8.0),
       child: Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           const Text(
             'Chọn Shop Voucher', // Đổi tiêu đề
             style: TextStyle(
               fontSize: 18,
               fontWeight: FontWeight.w600, // Đậm hơn
               color: Colors.black87, // Màu chữ
             ),
           ),
           IconButton(
             onPressed: () => Navigator.of(context).pop(), // Đóng dialog
             icon: const Icon(Icons.close, color: Colors.grey),
             tooltip: 'Đóng',
             splashRadius: 20,
           ),
         ],
       ),
     );
  }

  Widget _buildCodeInputRow() {
     return Padding(
       padding: const EdgeInsets.all(16.0),
       child: Row(
         children: [
           // Input field
           Expanded(
             child: TextField(
               controller: _codeController,
               decoration: InputDecoration(
                 hintText: 'Nhập mã Shop Voucher',
                 hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                 contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Giảm padding dọc
                 border: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                 ),
                  enabledBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(8),
                     borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(8),
                     borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
                  ),
                 isDense: true,
                 // Thêm icon vào đầu nếu muốn
                 // prefixIcon: Icon(Icons.local_offer_outlined, size: 18, color: Colors.grey),
               ),
                textCapitalization: TextCapitalization.characters, // Tự viết hoa
                onSubmitted: (_) => _applyEnteredCode(), // Cho phép nhấn Enter để áp dụng
             ),
           ),
           const SizedBox(width: 12),

           // Apply button
           ElevatedButton(
             onPressed: _applyEnteredCode, // Gọi hàm xử lý nội bộ
             style: ElevatedButton.styleFrom(
               backgroundColor: Colors.red.shade600, // Màu nền nút
               foregroundColor: Colors.white, // Màu chữ
               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Padding
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
               elevation: 1, // Giảm shadow
             ),
             child: const Text('Áp dụng'),
           ),
         ],
       ),
     );
  }

  Widget _buildVoucherList() {
    if (widget.availableVouchers.isEmpty) {
       return Center(
         child: Padding(
           padding: const EdgeInsets.all(20.0),
           child: Text(
             'Không có voucher nào khả dụng cho bạn.',
             textAlign: TextAlign.center,
             style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
           ),
         ),
       );
    }

    return ListView.builder(
       itemCount: widget.availableVouchers.length,
       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Padding cho list
       itemBuilder: (context, index) {
          final voucher = widget.availableVouchers[index];
          final isSelected = _selectedVoucherInDialog == voucher;
          return _buildVoucherItem(voucher, isSelected);
       },
    );
 }

 Widget _buildVoucherItem(VoucherData voucher, bool isSelected) {
    // Sử dụng Card hoặc Container tùy ý
    return Card(
       elevation: 0.8, // Shadow nhẹ
       margin: const EdgeInsets.only(bottom: 12.0), // Khoảng cách giữa các item
       shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(8.0),
         side: BorderSide( // Viền đỏ nếu được chọn
            color: isSelected ? Colors.red.shade400 : Colors.grey.shade200,
            width: isSelected ? 1.5 : 0.8,
         ),
       ),
       clipBehavior: Clip.antiAlias, // Đảm bảo nội dung không tràn viền
       child: InkWell(
         onTap: () => _toggleVoucherSelection(voucher), // Gọi hàm toggle
         child: Padding(
           padding: const EdgeInsets.all(12.0),
           child: Row(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
                // Phần icon và mã giảm giá (bên trái)
                Container(
                   width: 90, // Chiều rộng cố định cho phần bên trái
                   padding: const EdgeInsets.symmetric(vertical: 8.0),
                   decoration: BoxDecoration(
                     // Màu nền hoặc hình ảnh cho voucher
                      color: Colors.red.withOpacity(0.05),
                      // border: Border(right: BorderSide(color: Colors.red.shade100, style: BorderStyle.dotted)) // Viền đứt nếu muốn
                   ),
                   child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // Canh giữa dọc
                      children: [
                         Icon(
                           voucher.isPercent ? Icons.percent : Icons.local_offer, // Icon khác nhau
                           color: Colors.red.shade600,
                           size: 30,
                         ),
                         const SizedBox(height: 6),
                         Text(
                           voucher.displayDiscount(_currencyFormatter), // Hiển thị giá trị giảm
                           textAlign: TextAlign.center,
                           style: TextStyle(
                             fontWeight: FontWeight.bold,
                             fontSize: 14,
                             color: Colors.red.shade700,
                           ),
                         ),
                      ],
                   ),
                ),
                // Phần thông tin chi tiết (bên phải)
                Expanded(
                   child: Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                            Text(
                               voucher.code, // Hiển thị mã voucher
                               style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black87,
                                  letterSpacing: 0.5, // Giãn cách chữ
                               ),
                               maxLines: 1,
                               overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                               voucher.description, // Mô tả
                               style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700),
                               maxLines: 2,
                               overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // Điều kiện và HSD
                            Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                  Text(
                                     voucher.displayCondition(), // Điều kiện đơn tối thiểu
                                     style: TextStyle(fontSize: 12, color: Colors.orange.shade800, fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                     voucher.displayExpiry(), // Hạn sử dụng
                                     style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                               ],
                            ),
                         ],
                      ),
                   ),
                ),
                // Radio button hoặc Checkbox (bên phải cùng)
                Radio<VoucherData?>( // Dùng Radio với kiểu VoucherData?
                   value: voucher,
                   groupValue: _selectedVoucherInDialog,
                   activeColor: Colors.red,
                   onChanged: (VoucherData? value) {
                       // Khi nhấn radio, cũng gọi hàm toggle
                      if (value != null) {
                         _toggleVoucherSelection(value);
                      }
                   },
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
             ],
           ),
         ),
       ),
    );
 }

 Widget _buildConfirmButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade700, // Màu nền
          minimumSize: const Size(double.infinity, 48), // Kích thước nút
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2, // Shadow
        ),
        onPressed: _confirmSelection, // Gọi hàm xác nhận
        child: const Text(
          'Xác nhận',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
 }
}


// --- Hàm tiện ích để hiển thị Dialog ---
// (Có thể đặt trong PagePayment hoặc file riêng utils.dart)
Future<void> showVoucherSelectorDialog(
  BuildContext context, {
  required List<VoucherData> availableVouchers,
  required VoucherData? currentVoucher,
  required Function(VoucherData?) onVoucherSelected,
}) async {
   print("PagePayment (caller): Opening Voucher Selector Dialog...");
  return showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        child: VoucherSelector( // Truyền props xuống
          availableVouchers: availableVouchers,
          currentVoucher: currentVoucher,
          onVoucherSelected: onVoucherSelected,
        ),
      );
    },
  ).then((_) => print("PagePayment (caller): Voucher Selector Dialog closed."));
}
