import 'package:e_commerce_app/Screens/Payment/PagePayment.dart';
import 'package:flutter/material.dart';
import '../location_selection.dart';

// Enum to track view state inside the dialog
enum AddressSelectorInternalState { LIST, ADD, EDIT }

class AddressSelector extends StatefulWidget {
  // --- Data and callbacks from PagePayment ---
  final List<AddressData> addresses; // List of available addresses
  final AddressData? selectedAddress; // Currently selected address
  final bool isLoggedIn; // Login status
  final Function(AddressData)
      onAddressSelected; // Callback when confirming selection
  final Function(AddressData)
      onAddNewAddress; // Callback when adding new address
  final Function(int, AddressData)
      onUpdateAddress; // Callback when updating address
  final Function(int) onDeleteAddress; // Callback when deleting address
  final Function(int)
      onSetDefaultAddress; // Callback when setting address as default

  const AddressSelector({
    Key? key,
    required this.addresses,
    required this.selectedAddress,
    required this.isLoggedIn,
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
  // --- Internal dialog state ---
  late int _currentlySelectedIndex; // Index of selected address
  AddressSelectorInternalState _currentState =
      AddressSelectorInternalState.LIST;
  int _editingIndex = -1; // Index of address being edited (-1 if not editing)

  // Controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Location data for form
  String _selectedProvince = '';
  String _selectedDistrict = '';
  String _selectedWard = '';
  // Key to reset LocationSelection widget when needed
  Key _locationSelectionKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _initSelectedIndex();
  }

  void _initSelectedIndex() {
    if (widget.addresses.isEmpty) {
      _currentlySelectedIndex = -1;
      return;
    }

    // Find index of currently selected address
    if (widget.selectedAddress != null) {
      _currentlySelectedIndex =
          widget.addresses.indexWhere((addr) => addr == widget.selectedAddress);
    } else {
      _currentlySelectedIndex = -1;
    }

    // If not found, try to find default address or use the first one
    if (_currentlySelectedIndex == -1) {
      _currentlySelectedIndex =
          widget.addresses.indexWhere((addr) => addr.isDefault);

      // If no default, use the first address
      if (_currentlySelectedIndex == -1 && widget.addresses.isNotEmpty) {
        _currentlySelectedIndex = 0;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // --- Internal dialog logic ---

  void _handleLocationSelected(String province, String district, String ward) {
    setState(() {
      _selectedProvince = province;
      _selectedDistrict = district;
      _selectedWard = ward;
    });
  }

  void _resetFormControllers() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _selectedProvince = '';
    _selectedDistrict = '';
    _selectedWard = '';
    _locationSelectionKey = UniqueKey();
  }

  void _setFormControllersForEdit(int index) {
    if (index < 0 || index >= widget.addresses.length) return;

    final address = widget.addresses[index];
    _nameController.text = address.name;
    _phoneController.text = address.phone;
    _addressController.text = address.address;
    _selectedProvince = address.province;
    _selectedDistrict = address.district;
    _selectedWard = address.ward;
    _locationSelectionKey = UniqueKey();
  }

  void _submitAddAddress() {
    if (_formKey.currentState?.validate() ?? false) {
      final newAddress = AddressData(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        province: _selectedProvince,
        district: _selectedDistrict,
        ward: _selectedWard,
        isDefault: false,
      );

      widget.onAddNewAddress(newAddress);
      setState(() {
        _currentState = AddressSelectorInternalState.LIST;
      });
    }
  }

  void _submitUpdateAddress() {
    if (_editingIndex < 0) return;

    if (_formKey.currentState?.validate() ?? false) {
      final updatedAddressData = AddressData(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        province: _selectedProvince,
        district: _selectedDistrict,
        ward: _selectedWard,
        isDefault: widget.addresses[_editingIndex].isDefault,
      );

      widget.onUpdateAddress(_editingIndex, updatedAddressData);
      setState(() {
        _currentState = AddressSelectorInternalState.LIST;
      });
    }
  }

  void _confirmSelection() {
    if (_currentlySelectedIndex >= 0 &&
        _currentlySelectedIndex < widget.addresses.length) {
      final selected = widget.addresses[_currentlySelectedIndex];
      widget.onAddressSelected(selected);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn một địa chỉ hợp lệ.')),
      );
    }
  }

  void _requestDeleteAddress(int index) {
    if (index < 0 || index >= widget.addresses.length) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
            'Bạn có chắc chắn muốn xóa địa chỉ "${widget.addresses[index].name}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onDeleteAddress(index);

              // Update selected index if needed
              setState(() {
                if (index < _currentlySelectedIndex) {
                  _currentlySelectedIndex--;
                } else if (index == _currentlySelectedIndex) {
                  _currentlySelectedIndex =
                      widget.addresses.length > 1 ? 0 : -1;
                }
              });
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _requestSetDefault(int index) {
    if (index < 0 || index >= widget.addresses.length) return;

    if (widget.addresses[index].isDefault) {
      print("Address at index $index is already default.");
      return;
    }

    widget.onSetDefaultAddress(index);
    setState(() {
      _currentlySelectedIndex = index;
    });
  }

  // --- Build methods ---
  Widget _buildHeader() {
    String title;
    Widget? leadingButton;

    switch (_currentState) {
      case AddressSelectorInternalState.LIST:
        title = widget.isLoggedIn ? 'Địa chỉ của tôi' : 'Địa chỉ giao hàng';
        leadingButton = null;
        break;
      case AddressSelectorInternalState.ADD:
        title = 'Thêm mới địa chỉ';
        leadingButton = IconButton(
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
      case AddressSelectorInternalState.EDIT:
        title = 'Cập nhật địa chỉ';
        leadingButton = IconButton(
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

  Widget _buildContent() {
    Key contentKey = ValueKey(_currentState);

    switch (_currentState) {
      case AddressSelectorInternalState.LIST:
        return _buildAddressList(key: contentKey);
      case AddressSelectorInternalState.ADD:
      case AddressSelectorInternalState.EDIT:
        return _buildAddressForm(key: contentKey);
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
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildAddressItem(int index) {
    final address = widget.addresses[index];
    final isSelected = _currentlySelectedIndex == index;

    return Material(
      color: isSelected ? Colors.red.withOpacity(0.05) : Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _currentlySelectedIndex = index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Radio<int>(
                value: index,
                groupValue: _currentlySelectedIndex,
                activeColor: Colors.red,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _currentlySelectedIndex = value;
                    });
                  }
                },
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                  color: Colors.red.withOpacity(0.1)),
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
                      Text(
                        address.phone,
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        address.fullAddress,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                                    _editingIndex = index;
                                    _setFormControllersForEdit(index);
                                    _currentState =
                                        AddressSelectorInternalState.EDIT;
                                  });
                                }),
                            const SizedBox(width: 12),
                            _buildActionButton(
                              icon: Icons.delete_outline,
                              label: 'Xóa',
                              color: Colors.red.shade600,
                              onTap: () => _requestDeleteAddress(index),
                            ),
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

  Widget _buildAddressForm({Key? key}) {
    return SingleChildScrollView(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const Text(
                'Tỉnh/Thành phố, Quận/Huyện, Phường/Xã',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              LocationSelection(
                key: _locationSelectionKey,
                onLocationSelected: _handleLocationSelected,
                initialProvinceName:
                    _currentState == AddressSelectorInternalState.EDIT
                        ? _selectedProvince
                        : '', // Use empty string instead of null
                initialDistrictName:
                    _currentState == AddressSelectorInternalState.EDIT
                        ? _selectedDistrict
                        : '', // Use empty string instead of null
                initialWardName:
                    _currentState == AddressSelectorInternalState.EDIT
                        ? _selectedWard
                        : '', // Use empty string instead of null
              ),
              const SizedBox(height: 16),
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
                ? Icon(
                    prefixIcon,
                    color: Colors.grey.shade600,
                    size: 20,
                  )
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

  Widget _buildBottomArea() {
    switch (_currentState) {
      case AddressSelectorInternalState.LIST:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _resetFormControllers();
                  _editingIndex = -1;
                  _currentState = AddressSelectorInternalState.ADD;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 16.0),
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
      case AddressSelectorInternalState.ADD:
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _submitAddAddress,
            child: const Text(
              'Hoàn thành',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ),
        );
      case AddressSelectorInternalState.EDIT:
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _submitUpdateAddress,
            child: const Text(
              'Cập nhật',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ),
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
          _buildHeader(),
          const Divider(height: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildContent(),
            ),
          ),
          const Divider(height: 1),
          _buildBottomArea(),
        ],
      ),
    );
  }
}
