import 'dart:typed_data';

import 'package:e_commerce_app/constants.dart';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/database/services/user_service.dart';
import 'package:e_commerce_app/widgets/BottomNavigation.dart';
import 'package:e_commerce_app/widgets/navbarHomeMobile.dart';
import 'package:flutter/material.dart';

class NavbarFormobile extends StatefulWidget {
  final Widget? body; // Thêm body để hiển thị nội dung bên trong Scaffold

  const NavbarFormobile({super.key, this.body});

  @override
  State<NavbarFormobile> createState() => _NavbarmobileDrawerState();
}

class _NavbarmobileDrawerState extends State<NavbarFormobile> {
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer Header
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.red),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/info');
                },
                child: Row(
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Row(
                        children: [
                          ClipOval(
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child: UserInfo().currentUser?.avatar != null
                                  ? FutureBuilder<Uint8List?>(
                                      future: UserService().getAvatarBytes(
                                          UserInfo().currentUser?.avatar),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                                ConnectionState.waiting &&
                                            !snapshot.hasData) {
                                          return const Center(
                                              child: SizedBox(
                                                  width: 15,
                                                  height: 15,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2)));
                                        } else if (snapshot.hasData &&
                                            snapshot.data != null) {
                                          // Use cached image if available
                                          return Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                          );
                                        } else {
                                          // Fall back to network image if cache failed
                                          return Image.network(
                                            UserInfo().currentUser!.avatar!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.white,
                                                child: Icon(Icons.person,
                                                    color: Colors.black,
                                                    size: 30),
                                              );
                                            },
                                          );
                                        }
                                      },
                                    )
                                  : CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.white,
                                      child: Icon(Icons.person),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            UserInfo().currentUser?.fullName ?? '',
                            style: TextStyle(
                              fontSize: 25,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Conditional ListTiles for Web
            if (!isMobile) ...[
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Trang chủ'),
                onTap: () {
                  Navigator.pushNamed(context, '/');
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

            // Common ListTiles
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
      ),
      body: widget.body, // Thêm body vào đây
      bottomNavigationBar: isMobile ? BottomNavBar() : null,
    );
  }
}
