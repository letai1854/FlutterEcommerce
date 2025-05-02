import 'package:flutter/material.dart';
import '../location_selection.dart';

// Model class for address data
class AddressData {
  final String name;
  final String phone;
  final String address;
  final String province;
  final String district;
  final String ward;
  final bool isDefault;

  AddressData({
    required this.name,
    required this.phone,
    required this.address,
    this.province = '',
    this.district = '',
    this.ward = '',
    this.isDefault = false,
  });

  String get fullAddress {
    final List<String> parts = [];
    if (address.isNotEmpty) parts.add(address);
    if (ward.isNotEmpty) parts.add(ward);
    if (district.isNotEmpty) parts.add(district);
    if (province.isNotEmpty) parts.add(province);
    return parts.join(', ');
  }
}

// Enum to track the current view state
enum AddressViewState { LIST, ADD, EDIT }

class AddressSelector extends StatefulWidget {
  // Callback function when an address is selected
  final Function(AddressData) onAddressSelected;

  const AddressSelector({
    Key? key,
    required this.onAddressSelected,
  }) : super(key: key);

  @override
  State<AddressSelector> createState() => _AddressSelectorState();
}

class _AddressSelectorState extends State<AddressSelector> {
  // Sample address data
  final List<AddressData> _addresses = [
    AddressData(
      name: 'Tuấn Tú',
      phone: '(+84) 583541716',
      address: 'Gần Nhà Thờ An Phú',
      province: 'An Giang',
      district: 'Huyện An Phú',
      ward: 'Thị Trấn An Phú',
      isDefault: true,
    ),
    AddressData(
      name: 'Nguyễn Văn A',
      phone: '(+84) 987654321',
      address: '123 Đường Lê Lợi',
      province: 'TP Hồ Chí Minh',
      district: 'Quận 1',
      isDefault: false,
    ),
  ];

  // Track the selected address index
  int _selectedIndex = 0;

  // Current view state
  AddressViewState _currentState = AddressViewState.LIST;

  // Index of address being edited (for EDIT state)
  int _editingIndex = -1;

  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Location data
  String _selectedProvince = '';
  String _selectedDistrict = '';
  String _selectedWard = '';

  void _handleLocationSelected(String province, String district, String ward) {
    setState(() {
      _selectedProvince = province;
      _selectedDistrict = district;
      _selectedWard = ward;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Find the default address
    for (int i = 0; i < _addresses.length; i++) {
      if (_addresses[i].isDefault) {
        _selectedIndex = i;
        break;
      }
    }
  }

  // Reset form controllers
  void _resetFormControllers() {
    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
    setState(() {
      _selectedProvince = '';
      _selectedDistrict = '';
      _selectedWard = '';
    });
  }

  // Set form controllers for editing
  void _setFormControllersForEdit(int index) {
    final address = _addresses[index];
    _nameController.text = address.name;
    _phoneController.text = address.phone;
    _addressController.text = address.address;
    setState(() {
      _selectedProvince = address.province;
      _selectedDistrict = address.district;
      _selectedWard = address.ward;
    });
  }

  // Add new address
  void _addNewAddress() {
    if (_nameController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _addressController.text.isNotEmpty) {
      setState(() {
        _addresses.add(AddressData(
          name: _nameController.text,
          phone: _phoneController.text,
          address: _addressController.text,
          province: _selectedProvince,
          district: _selectedDistrict,
          ward: _selectedWard,
          isDefault: false,
        ));
        _currentState = AddressViewState.LIST;
        _resetFormControllers();
      });
    }
  }

  // Update existing address
  void _updateAddress() {
    if (_editingIndex >= 0 &&
        _nameController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _addressController.text.isNotEmpty) {
      setState(() {
        final isDefault = _addresses[_editingIndex].isDefault;
        _addresses[_editingIndex] = AddressData(
          name: _nameController.text,
          phone: _phoneController.text,
          address: _addressController.text,
          province: _selectedProvince,
          district: _selectedDistrict,
          ward: _selectedWard,
          isDefault: isDefault,
        );
        _currentState = AddressViewState.LIST;
        _resetFormControllers();
      });
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _currentState == AddressViewState.ADD
                      ? 'Thêm mới địa chỉ'
                      : _currentState == AddressViewState.EDIT
                          ? 'Cập nhật địa chỉ'
                          : 'Địa chỉ của tôi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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

          // Content based on state
          Expanded(
            child: _buildContent(),
          ),

          Divider(),

          // Bottom buttons area
          _buildBottomArea(),
        ],
      ),
    );
  }

  // Build content based on current state
  Widget _buildContent() {
    switch (_currentState) {
      case AddressViewState.LIST:
        return _buildAddressList();
      case AddressViewState.ADD:
        return _buildAddressForm('Thêm mới');
      case AddressViewState.EDIT:
        return _buildAddressForm('Cập nhật');
    }
  }

  // Build address list view
  Widget _buildAddressList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _addresses.length,
      itemBuilder: (context, index) {
        return _buildAddressItem(index);
      },
    );
  }

  // Build address form (for both add and edit)
  Widget _buildAddressForm(String action) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name field
            _buildFormField(
              label: 'Họ và tên',
              hint: 'Nhập họ và tên',
              controller: _nameController,
              prefixIcon: Icons.person,
            ),
            const SizedBox(height: 16),

            // Phone field
            _buildFormField(
              label: 'Số điện thoại',
              hint: 'Nhập số điện thoại',
              controller: _phoneController,
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            Text(
              'Chọn khu vực',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            LocationSelection(
              onLocationSelected: _handleLocationSelected,
            ),
            const SizedBox(height: 16),

            // Address field
            _buildFormField(
              label: 'Địa chỉ chi tiết',
              hint: 'Nhập địa chỉ chi tiết khác',
              controller: _addressController,
              prefixIcon: Icons.location_on,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  // Build a form field
  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // Build bottom area based on current state
  Widget _buildBottomArea() {
    switch (_currentState) {
      case AddressViewState.LIST:
        return Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _resetFormControllers();
                  _currentState = AddressViewState.ADD;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 16.0),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
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
            _buildConfirmButton(),
          ],
        );
      case AddressViewState.ADD:
        return _buildActionButtons(
            onCancel: () {
              setState(() {
                _currentState = AddressViewState.LIST;
                _resetFormControllers();
              });
            },
            onConfirm: _addNewAddress,
            confirmText: 'Hoàn thành');
      case AddressViewState.EDIT:
        return _buildActionButtons(
            onCancel: () {
              setState(() {
                _currentState = AddressViewState.LIST;
                _resetFormControllers();
              });
            },
            onConfirm: _updateAddress,
            confirmText: 'Cập nhật');
    }
  }

  // Build action buttons for form views
  Widget _buildActionButtons({
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
    required String confirmText,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onCancel,
              child: Text(
                'Trở lại',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onConfirm,
              child: Text(
                confirmText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build each address item
  Widget _buildAddressItem(int index) {
    final address = _addresses[index];
    final isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
          print(
              'Selected address changed to index: $_selectedIndex - ${address.name}');
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio button
            Radio(
              value: index,
              groupValue: _selectedIndex,
              activeColor: Colors.red,
              onChanged: (value) {
                setState(() {
                  _selectedIndex = value as int;
                });
              },
            ),
            const SizedBox(width: 8),

            // Address information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and phone
                  Row(
                    children: [
                      Text(
                        address.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        address.phone,
                        style: TextStyle(fontSize: 14),
                      ),
                      if (address.isDefault)
                        Container(
                          margin: EdgeInsets.only(left: 8),
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Mặc định',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Address text
                  Text(
                    address.fullAddress,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // Update button
            TextButton(
              onPressed: () {
                setState(() {
                  _editingIndex = index;
                  _setFormControllersForEdit(index);
                  _currentState = AddressViewState.EDIT;
                });
              },
              child: Text(
                'Cập nhật',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modify the Confirm button to ensure it passes the selected address
  Widget _buildConfirmButton() {
    final selectedAddress = _addresses[_selectedIndex];

    return Padding(
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
          widget.onAddressSelected(selectedAddress);
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
    );
  }
}

Future<void> showAddressSelectorDialog(
    BuildContext context, Function(AddressData) onAddressSelected) async {
  return showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: AddressSelector(
          onAddressSelected: onAddressSelected,
        ),
      );
    },
  );
}
