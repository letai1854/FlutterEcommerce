import 'package:e_commerce_app/database/models/address_model.dart';
import 'package:e_commerce_app/database/services/address_service.dart';
import 'package:e_commerce_app/widgets/Address/AddressItem.dart';
import 'package:e_commerce_app/widgets/Address/address_form_dialog.dart';
import 'package:flutter/material.dart';

class AddressManagement extends StatefulWidget {
  const AddressManagement({Key? key}) : super(key: key);

  @override
  State<AddressManagement> createState() => _AddressManagementState();
}

class _AddressManagementState extends State<AddressManagement> {
  final AddressService _addressService = AddressService();
  List<AddressData> _addresses = [];
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
      final List<Address> addresses = await _addressService.getUserAddresses();

      // Check for and delete addresses with "null" specificAddress
      bool deletedNullAddresses = false;
      for (final address in List<Address>.from(addresses)) {
        if (address.specificAddress == "null" && address.id != null) {
          print("Found address with 'null' value. Deleting ID: ${address.id}");
          await _addressService.deleteAddress(address.id!);
          deletedNullAddresses = true;
        }
      }

      // If any null addresses were deleted, refresh the list
      if (deletedNullAddresses) {
        print("Refreshing address list after deleting null addresses");
        final updatedAddresses = await _addressService.getUserAddresses();
        addresses.clear();
        addresses.addAll(updatedAddresses);
      }

      setState(() {
        // Convert server Address model to AddressData for UI display
        // And filter out any address that has "null" as the specific address (as backup)
        _addresses = addresses
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

  // Extract detailed address from specific address (e.g. "104, Xã Quảng Lâm, Huyện Bảo Lâm, Tỉnh Cao Bằng")
  String _extractDetailedAddress(String specificAddress) {
    if (specificAddress == "null") return "";

    final parts = specificAddress.split(',');
    return parts.isNotEmpty ? parts[0].trim() : '';
  }

  // Extract ward from specific address
  String _extractWard(String specificAddress) {
    if (specificAddress == "null") return "";

    final parts = specificAddress.split(',');
    return parts.length > 1 ? parts[1].trim() : '';
  }

  // Extract district from specific address
  String _extractDistrict(String specificAddress) {
    if (specificAddress == "null") return "";

    final parts = specificAddress.split(',');
    return parts.length > 2 ? parts[2].trim() : '';
  }

  // Extract province from specific address
  String _extractProvince(String specificAddress) {
    if (specificAddress == "null") return "";

    final parts = specificAddress.split(',');
    return parts.length > 3 ? parts[3].trim() : '';
  }

  // Modified to avoid duplicate API calls
  void _addNewAddress(AddressData address) async {
    // Just update the UI with the new address from the form dialog
    // The API call is already handled in address_form_dialog.dart
    setState(() {
      _addresses.add(address);
    });
  }

  // Modified to avoid duplicate API calls
  void _updateAddress(int index, AddressData updatedAddress) async {
    // Just update the UI with the updated address from the form dialog
    // The API call is already handled in address_form_dialog.dart
    if (index >= 0 && index < _addresses.length) {
      setState(() {
        _addresses[index] = updatedAddress;
      });
    }
  }

  // Delete address using the API
  Future<void> _deleteAddress(int index) async {
    try {
      // Get the address ID from the API
      final List<Address> serverAddresses =
          await _addressService.getUserAddresses();
      if (index >= serverAddresses.length) {
        throw Exception('Không tìm thấy địa chỉ cần xóa');
      }

      int addressId = serverAddresses[index].id ?? -1;
      if (addressId == -1) {
        throw Exception('Địa chỉ không có ID hợp lệ');
      }

      final result = await _addressService.deleteAddress(addressId);
      if (result) {
        setState(() {
          _addresses.removeAt(index); // Remove from local list
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi xóa địa chỉ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Set default address using the API
  Future<void> _setDefaultAddress(int index) async {
    try {
      // Get the address ID from the API
      final List<Address> serverAddresses =
          await _addressService.getUserAddresses();
      if (index >= serverAddresses.length) {
        throw Exception('Không tìm thấy địa chỉ để đặt làm mặc định');
      }

      int addressId = serverAddresses[index].id ?? -1;
      if (addressId == -1) {
        throw Exception('Địa chỉ không có ID hợp lệ');
      }

      final result = await _addressService.setDefaultAddress(addressId);
      if (result) {
        _loadAddresses(); // Reload to get updated default status
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi đặt địa chỉ mặc định: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Địa chỉ của tôi",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // Show address form dialog
                showAddressFormDialog(
                  context: context,
                  mode: AddressFormMode.add,
                  onSave: _addNewAddress,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Thêm địa chỉ mới"),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Show loading indicator or error message if needed
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          )
        else if (_errorMessage != null)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadAddresses,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          )
        // List of addresses
        else if (_addresses.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Bạn chưa có địa chỉ nào.\nHãy thêm địa chỉ mới để tiếp tục.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _addresses.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final address = _addresses[index];
              return AddressItem(
                name: address.name,
                phone: address.phone,
                address: address.fullAddress,
                isDefault: address.isDefault,
                onEdit: () {
                  // Show edit dialog
                  showAddressFormDialog(
                    context: context,
                    mode: AddressFormMode.edit,
                    initialAddress: address,
                    onSave: (updatedAddress) =>
                        _updateAddress(index, updatedAddress),
                    addressId:
                        address.id, // You're correctly passing address.id here
                  );
                },
                onDelete: () => _deleteAddress(index),
                onSetDefault: () => _setDefaultAddress(index),
              );
            },
          ),
      ],
    );
  }
}
