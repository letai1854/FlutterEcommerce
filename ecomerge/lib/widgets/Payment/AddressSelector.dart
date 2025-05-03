import 'package:e_commerce_app/Screens/Payment/PagePayment.dart';
import 'package:flutter/material.dart';
import '../location_selection.dart'; // Giả sử widget này không đổi
// Import model nếu tách file
// import 'models/address_data.dart';

// Enum để track view state bên trong dialog
enum AddressSelectorInternalState { LIST, ADD, EDIT }

class AddressSelector extends StatefulWidget {
  // --- Dữ liệu và Callbacks nhận từ PagePayment ---
  final List<AddressData> addresses;          // Danh sách địa chỉ hiện có
  final AddressData? selectedAddress;         // Địa chỉ đang được chọn bên ngoài
  final Function(AddressData) onAddressSelected; // Callback khi xác nhận chọn
  final Function(AddressData) onAddNewAddress;    // Callback khi bấm hoàn thành thêm mới
  final Function(int, AddressData) onUpdateAddress; // Callback khi bấm cập nhật sửa
  final Function(int) onDeleteAddress;       // Callback khi xóa địa chỉ
  final Function(int) onSetDefaultAddress;   // Callback khi đặt làm mặc định

  const AddressSelector({
    Key? key,
    required this.addresses,
    required this.selectedAddress,
    required this.onAddressSelected,
    required this.onAddNewAddress,
    required this.onUpdateAddress,
     required this.onDeleteAddress,
     required this.onSetDefaultAddress,
  }) : super(key: key);

  @override
  State<AddressSelector> createState() => _AddressSelectorState();
}

class _AddressSelectorState extends State<AddressSelector> {
  // --- State nội bộ của Dialog ---
  late int _currentlySelectedIndex; // Index của địa chỉ đang được chọn TRONG dialog
  AddressSelectorInternalState _currentState = AddressSelectorInternalState.LIST; // Trạng thái view nội bộ
  int _editingIndex = -1; // Index của địa chỉ đang sửa (-1 nếu không sửa)

  // Controllers cho form thêm/sửa (state nội bộ)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // Key cho validation

  // Location data cho form (state nội bộ)
  String _selectedProvince = '';
  String _selectedDistrict = '';
  String _selectedWard = '';
  // Key để reset LocationSelection widget khi cần
  Key _locationSelectionKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    // Tìm index của địa chỉ được chọn từ bên ngoài để khởi tạo radio button
    _currentlySelectedIndex = widget.addresses.indexWhere((addr) => addr == widget.selectedAddress);
    // Nếu không tìm thấy (ví dụ selectedAddress là null hoặc không có trong list), mặc định là 0 hoặc -1
    if (_currentlySelectedIndex == -1 && widget.addresses.isNotEmpty) {
       // Tìm cái mặc định nếu có
        _currentlySelectedIndex = widget.addresses.indexWhere((addr) => addr.isDefault);
        if (_currentlySelectedIndex == -1) _currentlySelectedIndex = 0; // Chọn cái đầu tiên nếu ko có default
    } else if (widget.addresses.isEmpty) {
       _currentlySelectedIndex = -1; // Không có gì để chọn
    }
     print("AddressSelector initState: Initial selected index: $_currentlySelectedIndex");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // --- Logic xử lý nội bộ của Dialog ---

  void _handleLocationSelected(String province, String district, String ward) {
    // Chỉ cập nhật state nội bộ cho form
    setState(() {
      _selectedProvince = province;
      _selectedDistrict = district;
      _selectedWard = ward;
    });
     print("AddressSelector: Location selected in form - P:$_selectedProvince, D:$_selectedDistrict, W:$_selectedWard");
  }

  void _resetFormControllers() {
    _formKey.currentState?.reset(); // Reset trạng thái validation
    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _selectedProvince = '';
    _selectedDistrict = '';
    _selectedWard = '';
    _locationSelectionKey = UniqueKey(); // Tạo key mới để reset LocationSelection
    print("AddressSelector: Form controllers reset.");
  }

  void _setFormControllersForEdit(int index) {
    if (index < 0 || index >= widget.addresses.length) return;
    final address = widget.addresses[index];
    _nameController.text = address.name;
    _phoneController.text = address.phone;
    _addressController.text = address.address; // Chỉ phần địa chỉ chi tiết
    _selectedProvince = address.province;
    _selectedDistrict = address.district;
    _selectedWard = address.ward;
     _locationSelectionKey = UniqueKey(); // Key mới để LocationSelection hiển thị đúng giá trị ban đầu
     print("AddressSelector: Set form controllers for editing index $index - P:$_selectedProvince, D:$_selectedDistrict, W:$_selectedWard");
  }

  void _submitAddAddress() {
    if (_formKey.currentState?.validate() ?? false) {
       // Validation thành công
       final newAddress = AddressData(
         name: _nameController.text.trim(),
         phone: _phoneController.text.trim(),
         address: _addressController.text.trim(),
         province: _selectedProvince,
         district: _selectedDistrict,
         ward: _selectedWard,
         isDefault: false, // Địa chỉ mới không bao giờ là default ngay lập tức
       );
        print("AddressSelector: Submitting new address: ${newAddress.name}");
       // Gọi callback báo cho PagePayment xử lý việc thêm
       widget.onAddNewAddress(newAddress);
       // Quay lại màn hình danh sách SAU KHI PagePayment cập nhật xong (state sẽ tự rebuild)
       setState(() {
          _currentState = AddressSelectorInternalState.LIST;
          // Không cần reset form ở đây vì state sẽ rebuild lại từ đầu
       });
       // Hoặc reset ngay nếu muốn form trống khi quay lại
       // _resetFormControllers();
    } else {
       print("AddressSelector: Add form validation failed.");
    }
  }

  void _submitUpdateAddress() {
     if (_editingIndex < 0) return; // Đảm bảo đang ở trạng thái edit hợp lệ

     if (_formKey.currentState?.validate() ?? false) {
        final updatedAddressData = AddressData(
           name: _nameController.text.trim(),
           phone: _phoneController.text.trim(),
           address: _addressController.text.trim(),
           province: _selectedProvince,
           district: _selectedDistrict,
           ward: _selectedWard,
           // isDefault không được sửa ở đây, chỉ PagePayment mới quản lý default
           isDefault: widget.addresses[_editingIndex].isDefault,
        );
         print("AddressSelector: Submitting updated address for index $_editingIndex: ${updatedAddressData.name}");
        // Gọi callback báo cho PagePayment xử lý việc cập nhật
        widget.onUpdateAddress(_editingIndex, updatedAddressData);
        // Quay lại màn hình danh sách
        setState(() {
           _currentState = AddressSelectorInternalState.LIST;
           // editingIndex sẽ được reset khi quay lại LIST hoặc khi build lại
        });
        // _resetFormControllers();
     } else {
        print("AddressSelector: Update form validation failed.");
     }
  }

   void _confirmSelection() {
      if (_currentlySelectedIndex >= 0 && _currentlySelectedIndex < widget.addresses.length) {
        final selected = widget.addresses[_currentlySelectedIndex];
        print("AddressSelector: Confirming selection - Index: $_currentlySelectedIndex, Name: ${selected.name}");
        widget.onAddressSelected(selected); // Gọi callback báo cho PagePayment địa chỉ đã chọn
        // Navigator.of(context).pop(); // PagePayment sẽ pop dialog
      } else {
         print("AddressSelector: No valid address selected to confirm.");
         // Có thể hiển thị thông báo lỗi nếu cần
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Vui lòng chọn một địa chỉ hợp lệ.')),
         );
      }
   }

   void _requestDeleteAddress(int index) {
      if (index < 0 || index >= widget.addresses.length) return;

       // Hiển thị dialog xác nhận trước khi xóa
       showDialog(
         context: context,
         builder: (ctx) => AlertDialog(
           title: Text('Xác nhận xóa'),
           content: Text('Bạn có chắc chắn muốn xóa địa chỉ "${widget.addresses[index].name}" không?'),
           actions: [
             TextButton(
               onPressed: () => Navigator.of(ctx).pop(),
               child: Text('Hủy'),
             ),
             TextButton(
               onPressed: () {
                  Navigator.of(ctx).pop(); // Đóng dialog xác nhận
                  print("AddressSelector: Requesting delete for index $index");
                  widget.onDeleteAddress(index); // Gọi callback xóa lên PagePayment
                   // Sau khi xóa, cần cập nhật lại _currentlySelectedIndex nếu cần
                   // Ví dụ: nếu địa chỉ bị xóa đang được chọn -> chọn cái đầu tiên
                  // Hoặc đơn giản là để PagePayment rebuild lại dialog
                   setState(() {
                      // Nếu index bị xóa nhỏ hơn index đang chọn -> giảm index chọn đi 1
                      if (index < _currentlySelectedIndex) {
                         _currentlySelectedIndex--;
                      }
                      // Nếu index bị xóa bằng index đang chọn -> chọn cái đầu tiên (hoặc -1 nếu list rỗng)
                      else if (index == _currentlySelectedIndex) {
                          _currentlySelectedIndex = widget.addresses.length > 1 ? 0 : -1; // Tránh lỗi index out of bounds sau khi xóa
                      }
                      // Nếu index bị xóa lớn hơn thì ko ảnh hưởng _currentlySelectedIndex
                   });
               },
               child: Text('Xóa', style: TextStyle(color: Colors.red)),
             ),
           ],
         ),
       );
   }

   void _requestSetDefault(int index) {
      if (index < 0 || index >= widget.addresses.length) return;
      // Kiểm tra xem nó đã là default chưa
      if (widget.addresses[index].isDefault) {
         print("AddressSelector: Address at index $index is already default.");
         return; // Không cần làm gì thêm
      }
      print("AddressSelector: Requesting set default for index $index");
      widget.onSetDefaultAddress(index); // Gọi callback lên PagePayment
      // Sau khi PagePayment xử lý, state sẽ rebuild và hiển thị đúng
      // Cập nhật luôn _currentlySelectedIndex để radio button chỉ đúng địa chỉ mới làm default
       setState(() {
         _currentlySelectedIndex = index;
       });
   }


  // --- Build Methods ---
  @override
  Widget build(BuildContext context) {
     print("AddressSelector build: Current state: $_currentState, Selected index: $_currentlySelectedIndex, Editing index: $_editingIndex");
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: 600, // Giới hạn chiều rộng tối đa
        maxHeight: MediaQuery.of(context).size.height * 0.8, // Giới hạn chiều cao
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Co lại theo nội dung
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(),
          const Divider(height: 1),

          // Content (List hoặc Form)
          Expanded(
            child: AnimatedSwitcher( // Thêm hiệu ứng chuyển đổi mượt mà
              duration: const Duration(milliseconds: 300),
              child: _buildContent(),
            ),
          ),

          const Divider(height: 1),

          // Bottom actions area
          _buildBottomArea(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
     String title;
      Widget? leadingButton;

      switch (_currentState) {
         case AddressSelectorInternalState.LIST:
            title = 'Địa chỉ của tôi';
            leadingButton = null; // Không có nút back ở màn hình list
            break;
         case AddressSelectorInternalState.ADD:
            title = 'Thêm mới địa chỉ';
             leadingButton = IconButton( // Nút Back
               icon: const Icon(Icons.arrow_back_ios, size: 18),
               onPressed: () {
                 setState(() {
                    _currentState = AddressSelectorInternalState.LIST;
                    _resetFormControllers(); // Reset khi quay lại
                 });
               },
               tooltip: 'Trở lại',
               splashRadius: 20,
             );
            break;
         case AddressSelectorInternalState.EDIT:
            title = 'Cập nhật địa chỉ';
            leadingButton = IconButton( // Nút Back
               icon: const Icon(Icons.arrow_back_ios, size: 18),
               onPressed: () {
                 setState(() {
                    _currentState = AddressSelectorInternalState.LIST;
                    _resetFormControllers();
                 });
               },
               tooltip: 'Trở lại',
                splashRadius: 20,
             );
            break;
      }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0), // Giảm padding
      child: Row(
        children: [
           if (leadingButton != null) leadingButton else const SizedBox(width: 40), // Giữ chỗ nếu không có nút back
           Expanded(
             child: Text(
               title,
               textAlign: TextAlign.center, // Canh giữa title
               style: const TextStyle(
                 fontSize: 18,
                 fontWeight: FontWeight.w600, // Đậm hơn
               ),
             ),
           ),
           IconButton( // Nút Close luôn có
             onPressed: () => Navigator.of(context).pop(), // Đóng dialog
             icon: const Icon(Icons.close, color: Colors.grey),
             tooltip: 'Đóng',
             splashRadius: 20,
           ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Key để đảm bảo Widget được rebuild đúng khi chuyển state
    Key contentKey = ValueKey(_currentState);

    switch (_currentState) {
      case AddressSelectorInternalState.LIST:
        return _buildAddressList(key: contentKey);
      case AddressSelectorInternalState.ADD:
      case AddressSelectorInternalState.EDIT:
        return _buildAddressForm(key: contentKey); // Dùng chung form
    }
  }

  Widget _buildAddressList({Key? key}) {
    if (widget.addresses.isEmpty) {
      return Center(
        key: key,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'Bạn chưa có địa chỉ nào.\nHãy nhấn "Thêm địa chỉ mới".',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),
        ),
      );
    }

    return ListView.builder(
      key: key,
      itemCount: widget.addresses.length,
      itemBuilder: (context, index) {
        return _buildAddressItem(index);
      },
       padding: EdgeInsets.zero, // Bỏ padding mặc định của ListView
    );
  }

 Widget _buildAddressItem(int index) {
    final address = widget.addresses[index];
    final isSelected = _currentlySelectedIndex == index;

    return Material( // Thêm Material để InkWell có hiệu ứng ripple
       color: isSelected ? Colors.red.withOpacity(0.05) : Colors.transparent, // Nền nhẹ khi chọn
       child: InkWell(
         onTap: () {
           setState(() {
             _currentlySelectedIndex = index;
             print("AddressSelector: Radio selected index changed to: $_currentlySelectedIndex");
           });
         },
         child: Padding(
           padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
           child: Row(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               // Radio button
               Radio<int>(
                 value: index,
                 groupValue: _currentlySelectedIndex,
                 activeColor: Colors.red,
                 onChanged: (value) {
                   if (value != null) {
                     setState(() {
                       _currentlySelectedIndex = value;
                       print("AddressSelector: Radio selected index changed to: $_currentlySelectedIndex");
                     });
                   }
                 },
                  visualDensity: VisualDensity.compact, // Giảm kích thước radio
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Giảm vùng chạm
               ),
               // const SizedBox(width: 8), // Bỏ SizedBox nếu muốn radio sát lề

               // Address information
               Expanded(
                 child: Padding(
                   padding: const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 8.0), // Padding cho text
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       // Name and phone
                       Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                         children: [
                           Expanded( // Cho tên chiếm hết phần còn lại trừ tag mặc định
                             child: Text(
                               address.name,
                               style: TextStyle(
                                 fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, // Đậm hơn khi chọn
                                 fontSize: 15,
                               ),
                               maxLines: 1,
                               overflow: TextOverflow.ellipsis,
                             ),
                           ),
                            if (address.isDefault)
                             Container(
                               margin: const EdgeInsets.only(left: 8),
                               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                               decoration: BoxDecoration(
                                 border: Border.all(color: Colors.red.shade300, width: 0.8),
                                 borderRadius: BorderRadius.circular(4),
                                  color: Colors.red.withOpacity(0.1)
                               ),
                               child: const Text(
                                 'Mặc định',
                                 style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w500),
                               ),
                             ),
                         ],
                       ),
                       const SizedBox(height: 4),
                        Text(
                         address.phone,
                         style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                       ),
                       const SizedBox(height: 6),

                       // Address text
                       Text(
                         address.fullAddress, // Dùng fullAddress
                         style: TextStyle(
                           fontSize: 14,
                           color: Colors.grey.shade700,
                         ),
                          maxLines: 2, // Giới hạn 2 dòng
                          overflow: TextOverflow.ellipsis,
                       ),

                       // Actions: Edit, Delete, Set Default
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                             mainAxisAlignment: MainAxisAlignment.end, // Đẩy các nút về cuối
                             children: [
                                // Nút Sửa
                                _buildActionButton(
                                   icon: Icons.edit_outlined,
                                   label: 'Sửa',
                                   color: Colors.blue.shade700,
                                   onTap: () {
                                     print("AddressSelector: Edit button tapped for index $index");
                                     setState(() {
                                        _editingIndex = index;
                                        _setFormControllersForEdit(index);
                                        _currentState = AddressSelectorInternalState.EDIT;
                                     });
                                   }
                                ),
                                const SizedBox(width: 12),
                                // Nút Xóa
                                _buildActionButton(
                                   icon: Icons.delete_outline,
                                   label: 'Xóa',
                                   color: Colors.red.shade600,
                                   onTap: () => _requestDeleteAddress(index),
                                ),
                                // Nút Đặt làm mặc định (chỉ hiện nếu chưa phải mặc định)
                                if (!address.isDefault) ...[
                                   const SizedBox(width: 12),
                                   _buildActionButton(
                                      icon: Icons.push_pin_outlined,
                                      label: 'Mặc định',
                                      color: Colors.orange.shade700,
                                      onTap: () => _requestSetDefault(index),
                                   ),
                                ]
                             ],
                          ),
                        )
                     ],
                   ),
                 ),
               ),

               // Update button (Đã chuyển xuống dưới)
               // TextButton(
               //   onPressed: () {
               //     setState(() {
               //       _editingIndex = index;
               //       _setFormControllersForEdit(index);
               //       _currentState = AddressViewState.EDIT;
               //     });
               //   },
               //   child: Text(
               //     'Cập nhật',
               //     style: TextStyle(color: Colors.blue),
               //   ),
               // ),
             ],
           ),
         ),
       ),
    );
 }

 // Helper widget cho các nút action nhỏ (Sửa, Xóa, Mặc định)
 Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
 }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0), // Padding nhỏ
        child: Row(
          mainAxisSize: MainAxisSize.min, // Chỉ chiếm đủ không gian cần thiết
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
 }


  Widget _buildAddressForm({Key? key}) {
    return SingleChildScrollView(
       key: key,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form( // Bọc trong Form widget
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name field
              _buildFormField(
                label: 'Họ và tên',
                hint: 'Nhập họ và tên',
                controller: _nameController,
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone field
              _buildFormField(
                label: 'Số điện thoại',
                hint: 'Nhập số điện thoại',
                controller: _phoneController,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số điện thoại';
                  }
                  // Basic phone validation (Vietnam format - adjust as needed)
                  // Regex for 10-digit numbers starting with 0
                  final phoneRegExp = RegExp(r'^0\d{9}$');
                  if (!phoneRegExp.hasMatch(value.trim())) {
                     return 'Số điện thoại không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20), // Tăng khoảng cách

              // Location Selection
              const Text(
                'Tỉnh/Thành phố, Quận/Huyện, Phường/Xã',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              LocationSelection(
                key: _locationSelectionKey, // Sử dụng key để reset
                onLocationSelected: _handleLocationSelected,
                 // Truyền giá trị ban đầu cho trạng thái EDIT
                 initialProvince: _currentState == AddressSelectorInternalState.EDIT ? _selectedProvince : null,
                 initialDistrict: _currentState == AddressSelectorInternalState.EDIT ? _selectedDistrict : null,
                 initialWard: _currentState == AddressSelectorInternalState.EDIT ? _selectedWard : null,
              ),
              // Thêm validator cho khu vực nếu cần thiết
               ValueListenableBuilder<bool>( // Ví dụ kiểm tra xem đã chọn đủ chưa
                 valueListenable: ValueNotifier(_selectedProvince.isNotEmpty && _selectedDistrict.isNotEmpty && _selectedWard.isNotEmpty),
                 builder: (context, isValid, child) {
                  
                   return const SizedBox.shrink(); // Không hiển thị gì nếu hợp lệ
                 },
               ),
              const SizedBox(height: 16),

              // Address details field
              _buildFormField(
                label: 'Địa chỉ chi tiết',
                hint: 'Số nhà, tên đường, tòa nhà, v.v.',
                controller: _addressController,
                prefixIcon: Icons.home_outlined, // Icon khác
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập địa chỉ chi tiết';
                  }
                  if (value.trim().length < 5) { // Ví dụ kiểm tra độ dài tối thiểu
                      return 'Địa chỉ quá ngắn';
                  }
                  return null;
                },
              ),

               // Checkbox "Đặt làm địa chỉ mặc định" (chỉ hiển thị khi thêm mới?)
               // Logic set default phức tạp hơn, nên để ở màn hình list
               // Hoặc nếu muốn thêm ở đây, cần callback riêng
               // const SizedBox(height: 16),
               // Row(
               //   children: [
               //     Checkbox(value: _setAsDefault, onChanged: (val) => setState(()=> _setAsDefault = val ?? false)),
               //     const Text('Đặt làm địa chỉ mặc định'),
               //   ],
               // )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FormFieldValidator<String> validator, // Thêm validator
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey.shade800),
        ),
        const SizedBox(height: 8),
        TextFormField( // Đổi thành TextFormField
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey.shade600, size: 20,) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder( // Viền khi không focus
               borderRadius: BorderRadius.circular(8),
               borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder( // Viền khi focus
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red.shade300, width: 1.5), // Viền đỏ nhạt khi focus
            ),
            errorBorder: OutlineInputBorder( // Viền khi có lỗi
               borderRadius: BorderRadius.circular(8),
               borderSide: BorderSide(color: Colors.red.shade700, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder( // Viền khi có lỗi và focus
               borderRadius: BorderRadius.circular(8),
               borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
            ),
             contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14), // Padding bên trong
             isDense: true, // Giảm chiều cao mặc định
          ),
          validator: validator, // Gán validator
           autovalidateMode: AutovalidateMode.onUserInteraction, // Validate khi người dùng tương tác
        ),
      ],
    );
  }

  Widget _buildBottomArea() {
    switch (_currentState) {
      case AddressSelectorInternalState.LIST:
        // Nút Thêm mới và nút Xác nhận chọn
        return Column(
          mainAxisSize: MainAxisSize.min, // Co lại
          children: [
            // Nút Thêm mới
            InkWell(
              onTap: () {
                 print("AddressSelector: Add New Address button tapped.");
                setState(() {
                  _resetFormControllers(); // Reset trước khi chuyển sang form add
                  _editingIndex = -1; // Đảm bảo không ở trạng thái edit
                  _currentState = AddressSelectorInternalState.ADD;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6), // Padding nhỏ hơn
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.red, size: 18), // Icon nhỏ hơn
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Thêm địa chỉ mới',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
             const Divider(height: 1), // Ngăn cách 2 nút
            // Nút Xác nhận (chỉ hiện nếu có địa chỉ để chọn)
            if (widget.addresses.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700, // Màu đậm hơn
                    minimumSize: const Size(double.infinity, 48), // Chiều cao cố định, rộng full
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
              ),
          ],
        );
      case AddressSelectorInternalState.ADD:
         // Nút Hoàn thành cho form Add
         return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
               style: ElevatedButton.styleFrom(
                 backgroundColor: Colors.red.shade700,
                 minimumSize: const Size(double.infinity, 48),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
               ),
               onPressed: _submitAddAddress, // Gọi hàm submit add
               child: const Text(
                 'Hoàn thành',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
               ),
            ),
         );
       case AddressSelectorInternalState.EDIT:
         // Nút Cập nhật cho form Edit
         return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
               style: ElevatedButton.styleFrom(
                 backgroundColor: Colors.red.shade700,
                 minimumSize: const Size(double.infinity, 48),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
               ),
               onPressed: _submitUpdateAddress, // Gọi hàm submit update
               child: const Text(
                 'Cập nhật',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
               ),
            ),
         );
       // Case EDIT và ADD đã có nút back ở header, không cần nút "Trở lại" ở dưới
       /*
      case AddressViewState.ADD:
        return _buildActionButtons(
            onCancel: () { // Nút Trở lại (đã chuyển lên header)
              setState(() {
                _currentState = AddressViewState.LIST;
                _resetFormControllers();
              });
            },
            onConfirm: _submitAddAddress, // Nút Hoàn thành
            confirmText: 'Hoàn thành');
      case AddressViewState.EDIT:
        return _buildActionButtons(
            onCancel: () { // Nút Trở lại (đã chuyển lên header)
              setState(() {
                _currentState = AddressViewState.LIST;
                _resetFormControllers();
              });
            },
            onConfirm: _submitUpdateAddress, // Nút Cập nhật
            confirmText: 'Cập nhật');
       */
    }
  }

   /* // Widget này không cần nữa vì nút Trở lại đã đưa lên Header
   Widget _buildActionButtons({
     required VoidCallback onCancel,
     required VoidCallback onConfirm,
     required String confirmText,
   }) {
     // ... (code cũ)
   }
   */

   /* // Widget này đã được tích hợp vào _buildBottomArea
   Widget _buildConfirmButton() {
     // ... (code cũ)
   }
   */
}

// --- Hàm tiện ích để hiển thị Dialog (không đổi) ---
// (Có thể đặt trong PagePayment hoặc file riêng utils.dart)
Future<void> showAddressSelectorDialog(
   BuildContext context, {
   required List<AddressData> addresses,
   required AddressData? selectedAddress,
   required Function(AddressData) onAddressSelected,
   required Function(AddressData) onAddNewAddress,
   required Function(int, AddressData) onUpdateAddress,
    required Function(int) onDeleteAddress,
    required Function(int) onSetDefaultAddress,
}) async {
  return showDialog(
    context: context,
    // barrierDismissible: false, // Có cho phép đóng khi chạm ra ngoài không?
    builder: (BuildContext dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
         insetPadding: EdgeInsets.all(16), // Padding xung quanh dialog
         clipBehavior: Clip.antiAlias, // Chống tràn nội dung nếu bo góc
        child: AddressSelector( // Truyền tất cả props xuống
           addresses: addresses,
           selectedAddress: selectedAddress,
           onAddressSelected: onAddressSelected,
           onAddNewAddress: onAddNewAddress,
           onUpdateAddress: onUpdateAddress,
           onDeleteAddress: onDeleteAddress,
           onSetDefaultAddress: onSetDefaultAddress,
        ),
      );
    },
  );
}


// --- LocationSelection Widget (Giả sử không đổi) ---
// Cần đảm bảo nó có các tham số initialXXX để nhận giá trị ban đầu khi edit
class LocationSelection extends StatefulWidget {
   final Function(String province, String district, String ward) onLocationSelected;
   final String? initialProvince;
   final String? initialDistrict;
   final String? initialWard;

   const LocationSelection({
     Key? key,
     required this.onLocationSelected,
     this.initialProvince,
     this.initialDistrict,
     this.initialWard,
   }) : super(key: key);

   @override
   _LocationSelectionState createState() => _LocationSelectionState();
}

class _LocationSelectionState extends State<LocationSelection> {
   // Mock data - Thay thế bằng API call hoặc dữ liệu thực tế
   final List<String> _provinces = ['An Giang', 'TP Hồ Chí Minh', 'Hà Nội'];
   final Map<String, List<String>> _districts = {
     'An Giang': ['Huyện An Phú', 'TP Long Xuyên', 'TP Châu Đốc'],
     'TP Hồ Chí Minh': ['Quận 1', 'Quận 3', 'Quận Bình Thạnh'],
     'Hà Nội': ['Quận Ba Đình', 'Quận Hoàn Kiếm', 'Quận Hai Bà Trưng'],
   };
   final Map<String, List<String>> _wards = {
     'Huyện An Phú': ['Thị Trấn An Phú', 'Xã Vĩnh Lộc', 'Xã Đa Phước'],
     'Quận 1': ['P. Bến Nghé', 'P. Tân Định', 'P. Cầu Ông Lãnh'],
     'Quận Ba Đình': ['P. Phúc Xá', 'P. Trúc Bạch', 'P. Điện Biên'],
     // Thêm dữ liệu cho các quận/huyện/phường/xã khác
   };

   String? _selectedProvince;
   String? _selectedDistrict;
   String? _selectedWard;

   List<String> _currentDistricts = [];
   List<String> _currentWards = [];

   @override
   void initState() {
      super.initState();
       // Khởi tạo giá trị ban đầu nếu có
       _selectedProvince = widget.initialProvince;
       if (_selectedProvince != null && _districts.containsKey(_selectedProvince)) {
          _currentDistricts = _districts[_selectedProvince]!;
          _selectedDistrict = widget.initialDistrict;
          if (_selectedDistrict != null && _wards.containsKey(_selectedDistrict)) {
             _currentWards = _wards[_selectedDistrict]!;
             _selectedWard = widget.initialWard;
          } else {
              _selectedDistrict = null; // Reset nếu district ban đầu không hợp lệ
              _currentWards = [];
              _selectedWard = null;
          }
       } else {
           _selectedProvince = null; // Reset nếu province ban đầu không hợp lệ
           _currentDistricts = [];
           _selectedDistrict = null;
           _currentWards = [];
           _selectedWard = null;
       }
        print("LocationSelection initState: P:$_selectedProvince, D:$_selectedDistrict, W:$_selectedWard");
   }

  void _notifySelection() {
      if (_selectedProvince != null && _selectedDistrict != null && _selectedWard != null) {
         widget.onLocationSelected(_selectedProvince!, _selectedDistrict!, _selectedWard!);
      }
   }


   @override
   Widget build(BuildContext context) {
      // Xây dựng UI với 3 DropdownButtonFormField
      return Column(
        children: [
          // Dropdown Tỉnh/Thành
          _buildDropdown(
            hint: 'Chọn Tỉnh/Thành phố',
            value: _selectedProvince,
            items: _provinces,
            onChanged: (value) {
              if (value == null || value == _selectedProvince) return;
              setState(() {
                _selectedProvince = value;
                _selectedDistrict = null; // Reset quận/huyện
                _selectedWard = null;     // Reset phường/xã
                _currentDistricts = _districts[value] ?? [];
                _currentWards = [];
                 print("LocationSelection: Province changed to $value");
              });
               _notifySelection(); // Thông báo thay đổi
            },
             validator: (value) => value == null ? 'Vui lòng chọn Tỉnh/Thành' : null,
          ),
          const SizedBox(height: 12),
          // Dropdown Quận/Huyện
          _buildDropdown(
            hint: 'Chọn Quận/Huyện',
            value: _selectedDistrict,
            items: _currentDistricts, // Sử dụng danh sách quận/huyện hiện tại
             // Vô hiệu hóa nếu chưa chọn tỉnh
            onChanged: _selectedProvince == null ? null : (value) {
              if (value == null || value == _selectedDistrict) return;
              setState(() {
                _selectedDistrict = value;
                _selectedWard = null; // Reset phường/xã
                _currentWards = _wards[value] ?? [];
                 print("LocationSelection: District changed to $value");
              });
               _notifySelection(); // Thông báo thay đổi
            },
            validator: (value) => value == null ? 'Vui lòng chọn Quận/Huyện' : null,
          ),
          const SizedBox(height: 12),
          // Dropdown Phường/Xã
          _buildDropdown(
            hint: 'Chọn Phường/Xã',
            value: _selectedWard,
            items: _currentWards, // Sử dụng danh sách phường/xã hiện tại
             // Vô hiệu hóa nếu chưa chọn quận/huyện
             onChanged: _selectedDistrict == null ? null : (value) {
               if (value == null || value == _selectedWard) return;
               setState(() {
                 _selectedWard = value;
                  print("LocationSelection: Ward changed to $value");
               });
                _notifySelection(); // Thông báo thay đổi
             },
            validator: (value) => value == null ? 'Vui lòng chọn Phường/Xã' : null,
          ),
        ],
      );
   }

   // Helper để tạo DropdownButtonFormField
   Widget _buildDropdown({
      required String hint,
      required String? value,
      required List<String> items,
      required ValueChanged<String?>? onChanged, // Nullable để disable
      required FormFieldValidator<String> validator,
   }) {
      return DropdownButtonFormField<String>(
        value: value,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis), // Chống tràn text
          );
        }).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
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
          errorBorder: OutlineInputBorder(
             borderRadius: BorderRadius.circular(8),
             borderSide: BorderSide(color: Colors.red.shade700, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
             borderRadius: BorderRadius.circular(8),
             borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
          ),
           contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
           isDense: true,
           suffixIcon: onChanged == null ? Icon(Icons.lock, size: 16, color: Colors.grey.shade400) : null, // Icon khóa khi disable
        ),
         isExpanded: true, // Cho phép dropdown chiếm hết chiều rộng
         validator: validator,
         autovalidateMode: AutovalidateMode.onUserInteraction,
         disabledHint: Text(value ?? hint, style: TextStyle(color: Colors.grey.shade400)), // Hiển thị giá trị khi bị disable
      );
   }
}
