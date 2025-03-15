import 'package:flutter/material.dart';

class Heading extends StatefulWidget {
  final String headingTitle;
  final IconData icon;
  final Color iconColor;
  const Heading(this.icon, this.iconColor, this.headingTitle, {Key? key})
      : super(key: key);

  @override
  State<Heading> createState() => _HeadingState();
}

class _HeadingState extends State<Heading> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Container(
        decoration: BoxDecoration(
          // Bo tròn góc
          borderRadius: BorderRadius.circular(3),
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 234, 29, 7), // Đỏ
              Color.fromARGB(255, 255, 85, 0), // Cam
            ],
            begin: Alignment.topLeft, // Hướng bắt đầu gradient
            end: Alignment.bottomRight, // Hướng kết thúc gradient
          ),
        ),
        padding: EdgeInsets.only(left: 30),
        alignment: Alignment.centerLeft, // Căn giữa văn bản
        child: Row(
          children: [
            Icon(
              widget.icon, // Biểu tượng sấm sét
              color: widget.iconColor, // Màu vàng nổi bật
              size: 40,
            ),
            SizedBox(width: 5),
            Text(
              widget.headingTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                // Để chữ dễ đọc hơn
              ),
            ),
          ],
        ),
      ),
    );
  }
}
