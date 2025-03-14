import 'package:e_commerce_app/constants.dart';
import 'package:e_commerce_app/widgets/navbarHomeMobile.dart';
import 'package:flutter/material.dart';
class NavbarFixmobile extends StatefulWidget {
  final Widget? body; // Thêm body để hiển thị nội dung bên trong Scaffold

  const NavbarFixmobile({super.key, this.body});

  @override
  State<NavbarFixmobile> createState() => _NavbarmobileDrawerState();
}

class _NavbarmobileDrawerState extends State<NavbarFixmobile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 90,
        backgroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              bottom: 0,
              child: NavbarHomeMobile(context),
            ),
          ],
        ),
      ),
      drawer: !isMobile
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(color: Colors.red),
                    child: GestureDetector(
                      onTap: () {
                        print("Nhấn vào thông tin người dùng");
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            child: const Icon(Icons.person),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Le Van Tai',
                            style: TextStyle(fontSize: 25, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_add_alt),
                    title: const Text('Đăng ký'),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_3_rounded),
                    title: const Text('Đăng nhập'),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.chat),
                    title: const Text('Nhắn tin'),
                    onTap: () {},
                  ),
                ],
              ),
            )
          : null,
      body: widget.body, // Thêm body vào đây
    );
  }
}
