import 'package:e_commerce_app/Screens/Payment/PagePayment.dart' as payment;
import 'package:e_commerce_app/database/models/address_model.dart';
import 'package:e_commerce_app/database/services/address_service.dart';
import 'package:e_commerce_app/widgets/Address/address_form_dialog.dart';
import 'package:flutter/material.dart';

class LoggedInAddressSelector extends StatefulWidget {
  // Data and callbacks
  final List<payment.AddressData> addresses;
  final payment.AddressData? selectedAddress;
  final Function(payment.AddressData) onAddressSelected;

  const LoggedInAddressSelector({
    Key? key,
    required this.addresses,
    this.selectedAddress,
    required this.onAddressSelected,
  }) : super(key: key);

  @override
  State<LoggedInAddressSelector> createState() =>
      _LoggedInAddressSelectorState();
}

class _LoggedInAddressSelectorState extends State<LoggedInAddressSelector> {
  final AddressService _addressService = AddressService();
  List<AddressData> _addresses = [];
  int? _selectedIndex;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  // Load addresses from the server
  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get all addresses from the server
      final List<Address> serverAddresses =
          await _addressService.getUserAddresses();

      setState(() {
        // Convert server Address model to AddressData for UI
        _addresses = serverAddresses
            .where((address) =>
                address.specificAddress != "null" &&
                address.specificAddress.trim().isNotEmpty)
            .map((address) => AddressData(
                  id: address.id,
                  name: address.recipientName,
                  phone: address.phoneNumber,
                  address: _extractDetailedAddress(address.specificAddress),
                  province: _extractProvince(address.specificAddress),
                  district: _extractDistrict(address.specificAddress),
                  ward: _extractWard(address.specificAddress),
                  isDefault: address.isDefault,
                ))
            .toList();

        // Find and select default address or currently selected address
        _initSelectedIndex();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải danh sách địa chỉ: $e';
        _isLoading = false;
      });
      print('Error loading addresses: $e');
    }
  }

  // Initialize the selected index based on default address or provided selected address
  void _initSelectedIndex() {
    // If we have a selected address, use that
    if (widget.selectedAddress != null) {
      for (int i = 0; i < _addresses.length; i++) {
        // Compare by all relevant fields since we might not have ids
        if (_addresses[i].name == widget.selectedAddress!.name &&
            _addresses[i].phone == widget.selectedAddress!.phone &&
            _addresses[i].fullAddress == widget.selectedAddress!.fullAddress) {
          _selectedIndex = i;
          return;
        }
      }
    }

    // Otherwise, find default address
    for (int i = 0; i < _addresses.length; i++) {
      if (_addresses[i].isDefault) {
        _selectedIndex = i;
        return;
      }
    }

    // If no default and no selected, use first address
    if (_addresses.isNotEmpty && _selectedIndex == null) {
      _selectedIndex = 0;
    }
  }

  // Helper methods to extract address parts
  String _extractDetailedAddress(String specificAddress) {
    if (specificAddress == "null") return "";

    final parts = specificAddress.split(',');
    return parts.isNotEmpty ? parts[0].trim() : '';
  }

  String _extractWard(String specificAddress) {
    if (specificAddress == "null") return "";

    final parts = specificAddress.split(',');
    return parts.length > 1 ? parts[1].trim() : '';
  }

  String _extractDistrict(String specificAddress) {
    if (specificAddress == "null") return "";

    final parts = specificAddress.split(',');
    return parts.length > 2 ? parts[2].trim() : '';
  }

  String _extractProvince(String specificAddress) {
    if (specificAddress == "null") return "";

    final parts = specificAddress.split(',');
    return parts.length > 3 ? parts[3].trim() : '';
  }

  // Add new address
  void _addNewAddress() {
    showAddressFormDialog(
      context: context,
      mode: AddressFormMode.add,
      onSave: (newAddress) {
        setState(() {
          _addresses.add(newAddress);
          _selectedIndex = _addresses.length - 1; // Select the new address
        });
        _loadAddresses(); // Reload to refresh with server data
      },
    );
  }

  // Edit address
  void _editAddress(int index) {
    if (index < 0 || index >= _addresses.length) return;

    final address = _addresses[index];
    showAddressFormDialog(
      context: context,
      mode: AddressFormMode.edit,
      initialAddress: address,
      addressId: address.id,
      onSave: (updatedAddress) {
        setState(() {
          _addresses[index] = updatedAddress;
        });
        _loadAddresses(); // Reload to refresh with server data
      },
    );
  }

  // Delete address
  Future<void> _deleteAddress(int index) async {
    if (index < 0 || index >= _addresses.length) return;

    // Show confirmation dialog
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: Text(
                'Bạn có chắc chắn muốn xóa địa chỉ "${_addresses[index].name}" không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      final addressId = _addresses[index].id;
      if (addressId != null) {
        final result = await _addressService.deleteAddress(addressId);
        if (result) {
          setState(() {
            _addresses.removeAt(index);
            // Update selected index if needed
            if (_selectedIndex == index) {
              _selectedIndex = _addresses.isNotEmpty ? 0 : null;
            } else if (_selectedIndex != null && _selectedIndex! > index) {
              _selectedIndex = _selectedIndex! - 1;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Địa chỉ đã được xóa thành công')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể xóa địa chỉ'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi xóa địa chỉ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Set address as default
  Future<void> _setDefaultAddress(int index) async {
    if (index < 0 || index >= _addresses.length) return;
    if (_addresses[index].isDefault) return;

    try {
      final addressId = _addresses[index].id;
      if (addressId != null) {
        final result = await _addressService.setDefaultAddress(addressId);
        if (result) {
          await _loadAddresses(); // Reload addresses to update default status
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã đặt địa chỉ mặc định')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể đặt địa chỉ mặc định'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi đặt địa chỉ mặc định: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Confirm address selection
  void _confirmSelection() {
    if (_selectedIndex != null &&
        _selectedIndex! >= 0 &&
        _selectedIndex! < _addresses.length) {
      final selectedAddress = _addresses[_selectedIndex!];

      // Convert from local AddressData to payment.AddressData
      final paymentAddress = payment.AddressData(
        name: selectedAddress.name,
        phone: selectedAddress.phone,
        address: selectedAddress.address,
        province: selectedAddress.province,
        district: selectedAddress.district,
        ward: selectedAddress.ward,
        isDefault: selectedAddress.isDefault,
      );

      widget.onAddressSelected(paymentAddress);
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
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
            child: Row(
              children: [
                const SizedBox(width: 40),
                const Expanded(
                  child: Text(
                    'Địa chỉ của tôi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorView()
                    : _addresses.isEmpty
                        ? _buildEmptyView()
                        : _buildAddressList(),
          ),

          // Footer
          const Divider(height: 1),
          _buildBottomArea(),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAddresses,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
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

  Widget _buildAddressList() {
    return ListView.separated(
      itemCount: _addresses.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) => _buildAddressItem(index),
    );
  }

  Widget _buildAddressItem(int index) {
    final address = _addresses[index];
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
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
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
                              onTap: () => _editAddress(index),
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
                                onTap: () => _setDefaultAddress(index),
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

  Widget _buildBottomArea() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Add new address button
        InkWell(
          onTap: _addNewAddress,
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
        if (_addresses.isNotEmpty)
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
