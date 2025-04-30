import 'package:e_commerce_app/constants.dart';
import 'package:e_commerce_app/widgets/BottomNavigation.dart';
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
                        Navigator.pushNamed(context, '/info');
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
                  // Fix the if statement syntax to properly group the ListTiles
                  if (isWeb) ...[
                    ListTile(
                      leading: const Icon(Icons.home),
                      title: const Text('Trang chủ'),
                      onTap: () {
                        Navigator.pushNamed(context, '/home');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.list_alt),
                      title: const Text('Danh sách sản phẩm'),
                      onTap: () {
                        Navigator.pushNamed(context, '/catalog_product');
                      },
                    ),
                  ],
                  ListTile(
                    leading: const Icon(Icons.person_add_alt),
                    title: const Text('Đăng ký'),
                    onTap: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_3_rounded),
                    title: const Text('Đăng nhập'),
                    onTap: () {
                      Navigator.pushNamed(context, '/login');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.chat),
                    title: const Text('Nhắn tin'),
                    onTap: () {
                      Navigator.pushNamed(context, '/chat');
                    },
                  ),
                ],
              ),
            )
          : null,
      body: widget.body, // Thêm body vào đây
      bottomNavigationBar: isMobile ? BottomNavBar() : null,
    );
  }
}
