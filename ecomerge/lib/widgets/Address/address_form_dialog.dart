import 'package:flutter/material.dart';
import 'package:e_commerce_app/widgets/Address/AddressItem.dart';
import 'package:e_commerce_app/widgets/location_selection.dart';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/database/models/address_model.dart';
import 'package:e_commerce_app/database/services/address_service.dart';

// Define address data model (matching AddressSelector structure)
class AddressData {
  final int? id; // ID for editing existing address
  final String name;
  final String phone;
  final String address;
  final String province;
  final String district;
  final String ward;
  final bool isDefault;

  AddressData({
    this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.province,
    required this.district,
    required this.ward,
    this.isDefault = false,
  });

  // Computed property to get full address
  String get fullAddress => '$address, $ward, $district, $province';
}

// Modes for the form dialog
enum AddressFormMode { add, edit }

class AddressFormDialog extends StatefulWidget {
  final AddressFormMode mode;
  final AddressData? initialAddress; // Used when editing
  final Function(AddressData) onSave; // Callback when form is saved
  final int? addressId; // Used for editing existing address

  const AddressFormDialog({
    Key? key,
    this.mode = AddressFormMode.add,
    this.initialAddress,
    required this.onSave,
    this.addressId,
  }) : super(key: key);

  @override
  State<AddressFormDialog> createState() => _AddressFormDialogState();
}

class _AddressFormDialogState extends State<AddressFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _addressService = AddressService();
  bool _isSubmitting = false;

  // Controllers for form fields
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  // Selected location
  String _selectedProvince = '';
  String _selectedDistrict = '';
  String _selectedWard = '';

  // Key for location selection reset
  Key _locationSelectionKey = UniqueKey();

  @override
  void initState() {
    super.initState();

    // Initialize controllers with values if editing
    if (widget.mode == AddressFormMode.edit && widget.initialAddress != null) {
      _nameController =
          TextEditingController(text: widget.initialAddress!.name);
      _phoneController =
          TextEditingController(text: widget.initialAddress!.phone);

      // Clean up "null" value in address field
      final addressText = widget.initialAddress!.address;
      _addressController =
          TextEditingController(text: addressText == "null" ? "" : addressText);

      _selectedProvince = widget.initialAddress!.province;
      _selectedDistrict = widget.initialAddress!.district;
      _selectedWard = widget.initialAddress!.ward;
    } else {
      _nameController = TextEditingController();
      _phoneController = TextEditingController();
      _addressController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _handleLocationSelected(String province, String district, String ward) {
    setState(() {
      _selectedProvince = province;
      _selectedDistrict = district;
      _selectedWard = ward;
    });
  }

  // Format specific address according to the requirement
  String _formatSpecificAddress() {
    String detailedAddress = _addressController.text.trim();
    String province = _addPrefixIfNeeded(_selectedProvince, 'Tỉnh/TP');
    String district = _addPrefixIfNeeded(_selectedDistrict, 'Quận/Huyện');
    String ward = _addPrefixIfNeeded(_selectedWard, 'Xã/Phường');

    // Format the address as: "104, Xã Quảng Lâm, Huyện Bảo Lâm, Tỉnh Cao Bằng"
    return "$detailedAddress, $ward, $district, $province";
  }

  // Add prefix to location names if needed
  String _addPrefixIfNeeded(String text, String defaultPrefix) {
    // Check if text already has a standard prefix
    List<String> prefixes = [
      'Tỉnh',
      'TP.',
      'Thành phố',
      'Quận',
      'Huyện',
      'Phường',
      'Xã',
      'Thị trấn'
    ];

    for (String prefix in prefixes) {
      if (text.startsWith(prefix)) {
        return text;
      }
    }

    // Add appropriate prefix based on type
    if (defaultPrefix == 'Tỉnh/TP') {
      return text.contains('Thành phố') ? text : 'Tỉnh $text';
    } else if (defaultPrefix == 'Quận/Huyện') {
      return 'Huyện $text';
    } else if (defaultPrefix == 'Xã/Phường') {
      return 'Xã $text';
    }

    return text;
  }

  // Add a new address
  Future<void> _addAddress() async {
    setState(() => _isSubmitting = true);

    try {
      // Clean up the address to prevent storing "null" string
      final cleanedAddress = _addressController.text.trim();

      // Create AddressRequest object with server-compatible field names
      final addressRequest = AddressRequest(
        recipientName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        specificAddress: cleanedAddress.isEmpty ? "" : _formatSpecificAddress(),
        isDefault: widget.initialAddress?.isDefault ?? false,
      );

      // Send request to the server
      final result = await _addressService.addAddress(addressRequest);

      if (result != null) {
        // Convert back to AddressData for the callback
        final addressData = AddressData(
          id: result.id, // Add the server-generated ID here
          name: result.recipientName,
          phone: result.phoneNumber,
          address: _addressController.text.trim(),
          province: _selectedProvince,
          district: _selectedDistrict,
          ward: _selectedWard,
          isDefault: result.isDefault,
        );

        // Call the onSave callback to update the parent widget's UI
        widget.onSave(addressData);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Địa chỉ đã được thêm thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể thêm địa chỉ. Vui lòng thử lại sau'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error adding address: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xảy ra lỗi khi thêm địa chỉ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // Update an existing address
  Future<void> _updateAddress() async {
    if (widget.addressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy ID địa chỉ để cập nhật'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final addressRequest = AddressRequest(
        recipientName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        specificAddress: _formatSpecificAddress(),
        isDefault: widget.initialAddress?.isDefault ?? false,
      );

      final result = await _addressService.updateAddress(
        widget.addressId!,
        addressRequest,
      );

      if (result != null) {
        // Convert back to AddressData for the callback
        final addressData = AddressData(
          id: widget.initialAddress?.id, // Preserve the ID
          name: result.recipientName,
          phone: result.phoneNumber,
          address: _addressController.text.trim(),
          province: _selectedProvince,
          district: _selectedDistrict,
          ward: _selectedWard,
          isDefault: result.isDefault,
        );

        // Call the onSave callback to update parent widget's UI
        widget.onSave(addressData);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Địa chỉ đã được cập nhật thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể cập nhật địa chỉ. Vui lòng thử lại sau'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error updating address: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xảy ra lỗi khi cập nhật địa chỉ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _handleSubmit() async {
    // Check if user is logged in
    if (UserInfo().currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để thêm địa chỉ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate() &&
        _selectedProvince.isNotEmpty &&
        _selectedDistrict.isNotEmpty &&
        _selectedWard.isNotEmpty) {
      // Create temporary address data for widget callback
      final addressData = AddressData(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        province: _selectedProvince,
        district: _selectedDistrict,
        ward: _selectedWard,
        isDefault:
            widget.mode == AddressFormMode.edit && widget.initialAddress != null
                ? widget.initialAddress!.isDefault
                : false,
      );

      // Submit to API based on mode
      if (widget.mode == AddressFormMode.add) {
        await _addAddress();
      } else {
        await _updateAddress();
      }

      // Close dialog after completion
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else if (_selectedProvince.isEmpty ||
        _selectedDistrict.isEmpty ||
        _selectedWard.isEmpty) {
      // Show error for location selection
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Vui lòng chọn đầy đủ địa chỉ (Tỉnh/Thành, Quận/Huyện, Phường/Xã)'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.mode == AddressFormMode.add
        ? 'Thêm địa chỉ mới'
        : 'Chỉnh sửa địa chỉ';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Trở lại',
                    splashRadius: 20,
                  ),
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
            ),
            const Divider(height: 1),

            // Form content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
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
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
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
                ),
              ),
            ),

            // Button area
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  disabledBackgroundColor: Colors.grey.shade400,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                // Disable button if not logged in or if submitting
                onPressed: (UserInfo().currentUser == null || _isSubmitting)
                    ? null
                    : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        UserInfo().currentUser == null
                            ? 'Đăng nhập để thêm địa chỉ'
                            : (widget.mode == AddressFormMode.add
                                ? 'Thêm địa chỉ'
                                : 'Cập nhật'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
              ),
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
}

// Helper function to show dialog
Future<void> showAddressFormDialog({
  required BuildContext context,
  AddressFormMode mode = AddressFormMode.add,
  AddressData? initialAddress,
  required Function(AddressData) onSave,
  int? addressId,
}) {
  // Check if user is logged in
  final bool isLoggedIn = UserInfo().currentUser != null;

  if (!isLoggedIn) {
    // Show a message if not logged in
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vui lòng đăng nhập để quản lý địa chỉ'),
        backgroundColor: Colors.red,
      ),
    );
    // Return a completed future since we're not showing the dialog
    return Future<void>.value();
  }

  return showDialog(
    context: context,
    builder: (context) => AddressFormDialog(
      mode: mode,
      initialAddress: initialAddress,
      onSave: onSave,
      addressId: addressId,
    ),
  );
}
