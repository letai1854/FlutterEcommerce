import 'package:e_commerce_app/constants.dart';
import 'package:flutter/material.dart';

class NavbarHomeMobile extends StatefulWidget {
  final BuildContext scaffoldContext;
  const NavbarHomeMobile(this.scaffoldContext, {Key? key}) : super(key: key);

  @override
  State<NavbarHomeMobile> createState() => _NavbarHomeMobileState();
}

class _NavbarHomeMobileState extends State<NavbarHomeMobile> {
  bool _isHoveredTK = false;
  bool _isHoveredGH = false;
  bool _isHoveredChat = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 234, 29, 7), // Màu nền giống ảnh
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          // Thanh tìm kiếm
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 13),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Thanh tìm kiếm',
                          border: InputBorder.none,
                          hintStyle: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() {
                      _isHoveredTK = true;
                    }),
                    onExit: (_) => setState(() {
                      _isHoveredTK = false;
                    }),
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 45,
                        height: 53,
                        decoration: BoxDecoration(
                          color: _isHoveredTK
                              ? const Color.fromARGB(255, 255, 48, 1)
                              : Colors.red,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: Icon(Icons.search, color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),

          SizedBox(width: 15),

          // Biểu tượng giỏ hàng
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() {
              _isHoveredGH = true;
            }),
            onExit: (_) => setState(() {
              _isHoveredGH = false;
            }),
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _isHoveredGH
                      ? const Color.fromARGB(255, 255, 48, 1)
                      : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.shopping_cart, color: Colors.white),
              ),
            ),
          ),

          SizedBox(width: 10),

          // Biểu tượng nhắn tin
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() {
              _isHoveredChat = true;
            }),
            onExit: (_) => setState(() {
              _isHoveredChat = false;
            }),
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _isHoveredChat
                      ? const Color.fromARGB(255, 255, 48, 1)
                      : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: !isWeb
                    ? Icon(Icons.chat, color: Colors.white)
                    : IconButton(
                        icon: Icon(Icons.menu, color: Colors.white),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
