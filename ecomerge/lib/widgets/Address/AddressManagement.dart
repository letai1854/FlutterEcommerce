import 'package:e_commerce_app/widgets/Address/AddressItem.dart';
import 'package:flutter/material.dart';

class AddressManagement extends StatefulWidget {
  const AddressManagement({Key? key}) : super(key: key);

  @override
  State<AddressManagement> createState() => _AddressManagementState();
}

class _AddressManagementState extends State<AddressManagement> {
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
              onPressed: () {},
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
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 2, // Example with 2 addresses
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return AddressItem(
              name: "Lê Văn Tài",
              phone: "0123456789",
              address: "123 Đường ABC, Phường XYZ, Quận 1, TP.HCM",
              isDefault: index == 0,
              onEdit: () {},
              onDelete: () {},
              onSetDefault: () {},
            );
          },
        ),
      ],
    );
  }
}
