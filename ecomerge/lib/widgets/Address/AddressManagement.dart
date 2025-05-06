import 'package:e_commerce_app/widgets/Address/AddressItem.dart';
import 'package:e_commerce_app/widgets/Address/address_form_dialog.dart';
import 'package:flutter/material.dart';

class AddressManagement extends StatefulWidget {
  const AddressManagement({Key? key}) : super(key: key);

  @override
  State<AddressManagement> createState() => _AddressManagementState();
}

class _AddressManagementState extends State<AddressManagement> {
  // List to store addresses
  List<AddressData> _addresses = [
    AddressData(
        name: "Lê Văn Tài",
        phone: "0123456789",
        address: "123 Đường ABC",
        province: "TP Hồ Chí Minh",
        district: "Quận 1",
        ward: "P. Bến Nghé",
        isDefault: true),
    AddressData(
        name: "Nguyễn Văn A",
        phone: "0987654321",
        address: "456 Đường XYZ",
        province: "Hà Nội",
        district: "Quận Ba Đình",
        ward: "P. Phúc Xá",
        isDefault: false),
  ];

  void _addNewAddress(AddressData address) {
    setState(() {
      _addresses.add(address);
    });
  }

  void _updateAddress(int index, AddressData updatedAddress) {
    if (index >= 0 && index < _addresses.length) {
      setState(() {
        _addresses[index] = updatedAddress;
      });
    }
  }

  void _deleteAddress(int index) {
    if (index >= 0 && index < _addresses.length) {
      setState(() {
        _addresses.removeAt(index);
      });
    }
  }

  void _setDefaultAddress(int index) {
    if (index >= 0 && index < _addresses.length) {
      setState(() {
        // Remove default from all addresses
        for (var i = 0; i < _addresses.length; i++) {
          if (i == index) {
            // Create a new address with isDefault = true
            _addresses[i] = AddressData(
                name: _addresses[i].name,
                phone: _addresses[i].phone,
                address: _addresses[i].address,
                province: _addresses[i].province,
                district: _addresses[i].district,
                ward: _addresses[i].ward,
                isDefault: true);
          } else if (_addresses[i].isDefault) {
            // Create a new address with isDefault = false
            _addresses[i] = AddressData(
                name: _addresses[i].name,
                phone: _addresses[i].phone,
                address: _addresses[i].address,
                province: _addresses[i].province,
                district: _addresses[i].district,
                ward: _addresses[i].ward,
                isDefault: false);
          }
        }
      });
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

        // List of addresses
        _addresses.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Bạn chưa có địa chỉ nào.\nHãy thêm địa chỉ mới để tiếp tục.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  ),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _addresses.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
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
