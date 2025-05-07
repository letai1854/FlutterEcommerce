import 'package:e_commerce_app/Screens/Payment/PagePayment.dart';
import 'package:e_commerce_app/widgets/location_selection.dart';
import 'package:flutter/material.dart';

class GuestAddressSelector extends StatefulWidget {
  final List<AddressData> addresses;
  final AddressData? selectedAddress;
  final Function(AddressData) onAddressSelected;
  final Function(AddressData) onAddNewAddress;
  final Function(int, AddressData) onUpdateAddress;
  final Function(int) onDeleteAddress;

  const GuestAddressSelector({
    Key? key,
    required this.addresses,
    this.selectedAddress,
    required this.onAddressSelected,
    required this.onAddNewAddress,
    required this.onUpdateAddress,
    required this.onDeleteAddress,
  }) : super(key: key);

  @override
  State<GuestAddressSelector> createState() => _GuestAddressSelectorState();
}

class _GuestAddressSelectorState extends State<GuestAddressSelector> {
  // View states
  int? _selectedIndex;
  bool _isInAddMode = false;
  bool _isInEditMode = false;
  int _editingIndex = -1;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Location selection data
  String _selectedProvince = '';
  String _selectedDistrict = '';
  String _selectedWard = '';

  // Key to reset the location selection widget
  Key _locationSelectionKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _initSelectedIndex();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _initSelectedIndex() {
    if (widget.addresses.isEmpty) {
      _selectedIndex = null;
      return;
    }

    if (widget.selectedAddress != null) {
      for (int i = 0; i < widget.addresses.length; i++) {
        if (widget.addresses[i].name == widget.selectedAddress!.name &&
            widget.addresses[i].phone == widget.selectedAddress!.phone &&
            widget.addresses[i].fullAddress ==
                widget.selectedAddress!.fullAddress) {
          _selectedIndex = i;
          return;
        }
      }
    }

    // If no match found, find default address or use first one
    for (int i = 0; i < widget.addresses.length; i++) {
      if (widget.addresses[i].isDefault) {
        _selectedIndex = i;
        return;
      }
    }

    // If no default and no selected, use first address
    if (widget.addresses.isNotEmpty) {
      _selectedIndex = 0;
    }
  }

  void _handleLocationSelected(String province, String district, String ward) {
    setState(() {
      _selectedProvince = province;
      _selectedDistrict = district;
      _selectedWard = ward;
    });
  }

  void _resetForm() {
    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _selectedProvince = '';
    _selectedDistrict = '';
    _selectedWard = '';
    _locationSelectionKey = UniqueKey();
  }

  void _populateFormForEdit(int index) {
    final address = widget.addresses[index];
    _nameController.text = address.name;
    _phoneController.text = address.phone;
    _addressController.text = address.address;
    _selectedProvince = address.province;
    _selectedDistrict = address.district;
    _selectedWard = address.ward;
    _locationSelectionKey = UniqueKey();
  }

  void _addNewAddress() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedProvince.isEmpty ||
          _selectedDistrict.isEmpty ||
          _selectedWard.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Vui lòng chọn đầy đủ Tỉnh/Thành phố, Quận/Huyện, Phường/Xã'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final newAddress = AddressData(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        province: _selectedProvince,
        district: _selectedDistrict,
        ward: _selectedWard,
        isDefault: widget.addresses.isEmpty, // First address is default
      );

      widget.onAddNewAddress(newAddress);

      setState(() {
        _isInAddMode = false;
        _resetForm();
      });
    }
  }

  void _updateAddress() {
    if (_editingIndex < 0 || !(_formKey.currentState?.validate() ?? false))
      return;

    if (_selectedProvince.isEmpty ||
        _selectedDistrict.isEmpty ||
        _selectedWard.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Vui lòng chọn đầy đủ Tỉnh/Thành phố, Quận/Huyện, Phường/Xã'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updatedAddress = AddressData(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      province: _selectedProvince,
      district: _selectedDistrict,
      ward: _selectedWard,
      isDefault: widget.addresses[_editingIndex].isDefault,
    );

    widget.onUpdateAddress(_editingIndex, updatedAddress);

    setState(() {
      _isInEditMode = false;
      _editingIndex = -1;
      _resetForm();
    });
  }

  void _deleteAddress(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc muốn xóa địa chỉ này?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDeleteAddress(index);
              setState(() {
                if (_selectedIndex == index) {
                  _selectedIndex = widget.addresses.isNotEmpty ? 0 : null;
                } else if (_selectedIndex != null && _selectedIndex! > index) {
                  _selectedIndex = _selectedIndex! - 1;
                }
              });
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _setAsDefault(int index) {
    if (widget.addresses[index].isDefault) return;

    final updatedAddresses = List<AddressData>.from(widget.addresses);

    // Remove default status from current default address
    for (int i = 0; i < updatedAddresses.length; i++) {
      if (i != index && updatedAddresses[i].isDefault) {
        widget.onUpdateAddress(
            i, updatedAddresses[i].copyWith(isDefault: false));
      }
    }

    // Set new default address
    widget.onUpdateAddress(
        index, updatedAddresses[index].copyWith(isDefault: true));

    setState(() {
      _selectedIndex = index;
    });
  }

  void _confirmSelection() {
    if (_selectedIndex != null &&
        _selectedIndex! >= 0 &&
        _selectedIndex! < widget.addresses.length) {
      widget.onAddressSelected(widget.addresses[_selectedIndex!]);
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn một địa chỉ hợp lệ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: 600,
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(),
          const Divider(height: 1),

          // Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isInAddMode
                  ? _buildAddressForm(isEdit: false)
                  : _isInEditMode
                      ? _buildAddressForm(isEdit: true)
                      : _buildAddressList(),
            ),
          ),

          // Footer
          const Divider(height: 1),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    String title;
    Widget? leadingButton;

    if (_isInAddMode) {
      title = 'Thêm địa chỉ mới';
      leadingButton = IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 18),
        onPressed: () => setState(() {
          _isInAddMode = false;
          _resetForm();
        }),
        tooltip: 'Trở lại',
        splashRadius: 20,
      );
    } else if (_isInEditMode) {
      title = 'Chỉnh sửa địa chỉ';
      leadingButton = IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 18),
        onPressed: () => setState(() {
          _isInEditMode = false;
          _editingIndex = -1;
          _resetForm();
        }),
        tooltip: 'Trở lại',
        splashRadius: 20,
      );
    } else {
      title = 'Địa chỉ nhận hàng';
      leadingButton = null;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
      child: Row(
        children: [
          if (leadingButton != null)
            leadingButton
          else
            const SizedBox(width: 40),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.grey),
            tooltip: 'Đóng',
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList() {
    if (widget.addresses.isEmpty) {
      return Center(
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

    return ListView.separated(
      itemCount: widget.addresses.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) => _buildAddressItem(index),
    );
  }

  Widget _buildAddressItem(int index) {
    final address = widget.addresses[index];
    final isSelected = _selectedIndex == index;

    return Material(
      color: isSelected ? Colors.red.withOpacity(0.05) : Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Radio button for selection
              Radio<int>(
                value: index,
                groupValue: _selectedIndex,
                activeColor: Colors.red,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedIndex = value;
                    });
                  }
                },
              ),

              // Address content
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and default badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              address.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (address.isDefault)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.red.shade300, width: 0.8),
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.red.withOpacity(0.1),
                              ),
                              child: const Text(
                                'Mặc định',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Phone number
                      Text(
                        address.phone,
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 6),

                      // Full address
                      Text(
                        address.fullAddress,
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Action buttons
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildActionButton(
                              icon: Icons.edit_outlined,
                              label: 'Sửa',
                              color: Colors.blue.shade700,
                              onTap: () {
                                setState(() {
                                  _isInEditMode = true;
                                  _editingIndex = index;
                                  _populateFormForEdit(index);
                                });
                              },
                            ),
                            const SizedBox(width: 12),
                            _buildActionButton(
                              icon: Icons.delete_outline,
                              label: 'Xóa',
                              color: Colors.red.shade600,
                              onTap: () => _deleteAddress(index),
                            ),
                            if (!address.isDefault) ...[
                              const SizedBox(width: 12),
                              _buildActionButton(
                                icon: Icons.push_pin_outlined,
                                label: 'Mặc định',
                                color: Colors.orange.shade700,
                                onTap: () => _setAsDefault(index),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                  fontSize: 13, color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressForm({required bool isEdit}) {
    final title = isEdit ? 'Chỉnh sửa địa chỉ' : 'Thêm địa chỉ mới';
    final buttonText = isEdit ? 'Cập nhật' : 'Hoàn thành';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
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
                final phoneRegExp = RegExp(r'^0\d{9}$');
                if (!phoneRegExp.hasMatch(value.trim())) {
                  return 'Số điện thoại không hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Location selection
            const Text(
              'Tỉnh/Thành phố, Quận/Huyện, Phường/Xã',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            LocationSelection(
              key: _locationSelectionKey,
              onLocationSelected: _handleLocationSelected,
              initialProvinceName: _selectedProvince,
              initialDistrictName: _selectedDistrict,
              initialWardName: _selectedWard,
            ),
            const SizedBox(height: 16),

            // Address details field
            _buildFormField(
              label: 'Địa chỉ chi tiết',
              hint: 'Số nhà, tên đường, tòa nhà, v.v.',
              controller: _addressController,
              prefixIcon: Icons.home_outlined,
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập địa chỉ chi tiết';
                }
                if (value.trim().length < 5) {
                  return 'Địa chỉ quá ngắn';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FormFieldValidator<String> validator,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: Colors.grey.shade600, size: 20)
                : null,
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            isDense: true,
          ),
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    if (_isInAddMode || _isInEditMode) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            minimumSize: const Size(double.infinity, 48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _isInAddMode ? _addNewAddress : _updateAddress,
          child: Text(
            _isInAddMode ? 'Hoàn thành' : 'Cập nhật',
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Add new address button
        InkWell(
          onTap: () => setState(() {
            _isInAddMode = true;
            _resetForm();
          }),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.red, size: 18),
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
        const Divider(height: 1),

        // Confirm button
        if (widget.addresses.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _confirmSelection,
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
  }
}
