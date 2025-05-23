import 'dart:typed_data';

import 'package:e_commerce_app/Screens/ChatbotAI/PageChatbotAI.dart';
import 'package:e_commerce_app/constants.dart';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/database/services/user_service.dart';
import 'package:e_commerce_app/widgets/navbarHomeTablet.dart';
import 'package:flutter/material.dart';

class NavbarForTablet extends StatefulWidget {
  final Widget? body; // Add body parameter to display content

  const NavbarForTablet({super.key, this.body});

  @override
  State<NavbarForTablet> createState() => _NavbarForTabletState();
}

class _NavbarForTabletState extends State<NavbarForTablet> {
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
    // Determine if device is mobile by screen width
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 130,
        backgroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              bottom: 0,
              child: NavbarhomeTablet(context),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.red),
              child: GestureDetector(
                onTap: () {
                  if (isWeb) {
                    // For web platform, check login status
                    if (UserInfo().currentUser == null) {
                      Navigator.pushNamed(context, '/login');
                    } else {
                      Navigator.pushNamed(context, '/info');
                    }
                  } else {
                    // For non-web platforms (mobile/desktop)
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
            // Add AI Chatbox ListTile - available on all platforms
            if(!isMobile) ...[
              ListTile(
              leading: const Icon(Icons.smart_toy),
              title: const Text('AI Chatbot'),
              onTap: () {
                // Close drawer first
                Navigator.pop(context);
                // Show as popup instead of navigation
                Pagechatbotai.showAsPopup(context);
              },
            ),
            ],
            
          ],
        ),
      ),
      body: widget.body, // Use the body parameter passed to the widget
    );
  }
}
