import 'dart:typed_data';

import 'package:e_commerce_app/constants.dart';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/database/services/user_service.dart';
import 'package:e_commerce_app/state/Search/SearchStateService.dart'; // Add this import
import 'package:e_commerce_app/widgets/BottomNavigation.dart';
import 'package:e_commerce_app/widgets/navbarHomeMobile.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/Screens/ChatbotAI/PageChatbotAI.dart';

class NavbarFormobile extends StatefulWidget {
  final Widget? body; // Thêm body để hiển thị nội dung bên trong Scaffold

  const NavbarFormobile({super.key, this.body});

  @override
  State<NavbarFormobile> createState() => _NavbarmobileDrawerState();
}

class _NavbarmobileDrawerState extends State<NavbarFormobile> {
  @override
  void initState() {
    super.initState();
    // Listen for UserInfo changes and trigger rebuild
    UserInfo().addListener(_onUserInfoChanged);
  }

  @override
  void dispose() {
    // Remove listener when disposed
    UserInfo().removeListener(_onUserInfoChanged);
    super.dispose();
  }

  void _onUserInfoChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is logged in
    final bool isLoggedIn = UserInfo().currentUser != null;

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
                  // If not logged in, redirect to login page on web platforms
                  if (isWeb && !isLoggedIn) {
                    Navigator.pushNamed(context, '/login');
                  } else {
                    // Otherwise go to user info page
                    Navigator.pushNamed(context, '/info');
                  }
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

            // Only show Register button if not logged in
            if (!isLoggedIn)
              ListTile(
                leading: const Icon(Icons.person_add_alt),
                title: const Text('Đăng ký'),
                onTap: () {
                  Navigator.pushNamed(context, '/signup');
                },
              ),

            // Login/Logout button (changes based on login status)
            ListTile(
              leading: Icon(isLoggedIn ? Icons.logout : Icons.person_3_rounded),
              title: Text(isLoggedIn ? 'Đăng xuất' : 'Đăng nhập'),
              onTap: () {
                if (isLoggedIn) {
                  // Call logout function from UserInfo
                  UserInfo().logout(context);
                } else {
                  // Navigate to login page
                  Navigator.pushNamed(context, '/login');
                }
              },
            ),

            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Nhắn tin'),
              onTap: () {
                Navigator.pushNamed(context, '/chat');
              },
            ),
            if(!isMobile) ...[
            ListTile(
              leading: const Icon(Icons.smart_toy),
              title: const Text('AI Chatbot'),
              onTap: () {
                // Close drawer first
                Navigator.pop(context);
                // Show chatbot as popup instead of navigation
                Pagechatbotai.showAsPopup(context);
              },
            ),
            ],
            
            
          ],
        ),
      ),
      body: widget.body, // Thêm body vào đây
      bottomNavigationBar: isMobile ? BottomNavBar() : null,
    );
  }
}
