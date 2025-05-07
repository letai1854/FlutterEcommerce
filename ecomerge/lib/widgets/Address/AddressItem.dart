import 'package:flutter/material.dart';

class AddressItem extends StatelessWidget {
  final String name;
  final String phone;
  final String address;
  final bool isDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const AddressItem({
    Key? key,
    required this.name,
    required this.phone,
    required this.address,
    required this.isDefault,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Don't display "null" text in address
    final displayAddress = address == "null" ? "" : address;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Address details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 12),
                    Text(phone),
                    if (isDefault) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: const Text(
                          "Mặc định",
                          style: TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  // Display cleaned address text
                  displayAddress,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),

          // Action buttons
          Column(
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text("Cập nhật"),
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
              ),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, size: 18),
                label: const Text("Xóa"),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
              TextButton.icon(
                onPressed: onSetDefault,
                icon: const Icon(Icons.all_inbox, size: 18),
                label: const Text("Mặc định"),
                style: TextButton.styleFrom(foregroundColor: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
