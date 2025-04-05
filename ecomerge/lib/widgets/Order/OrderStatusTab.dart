import 'package:flutter/material.dart';

class OrderStatusTab extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const OrderStatusTab({
    Key? key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  // Static utility method to get status text from tab index
  static String getStatusText(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return "Đang chờ xử lý";
      case 1:
        return "Đã xác nhận";
      case 2:
        return "Đang giao hàng";
      case 3:
        return "Đã giao hàng";
      case 4:
        return "Đã hủy";
      case 5:
        return "Trả hàng";
      default:
        return "Đang chờ xử lý";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
