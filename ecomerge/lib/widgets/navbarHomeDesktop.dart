import 'dart:typed_data';

import 'package:e_commerce_app/Provider/UserProvider.dart';
import 'package:e_commerce_app/constants.dart';
import 'package:e_commerce_app/database/services/user_service.dart';
import 'package:e_commerce_app/state/Search/SearchStateService.dart';
import 'package:e_commerce_app/database/Storage/UserInfo.dart'; // Add import for UserInfo
import 'package:flutter/material.dart';

class Navbarhomedesktop extends StatefulWidget {
  const Navbarhomedesktop({Key? key}) : super(key: key);

  @override
  _NavbarhomedesktopState createState() => _NavbarhomedesktopState();
}

class _NavbarhomedesktopState extends State<Navbarhomedesktop> {
  bool _isHoveredDK = false;
  bool _isHoveredDN = false;
  bool _isHoveredTK = false;
  bool _isHoveredGH = false;

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
    final searchService = SearchStateService();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: const Color.fromARGB(255, 234, 29, 7),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/'),
                      child: const Text(
                        'Trang chủ',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, '/catalog_product'),
                      child: const Text(
                        'Danh sách sản phẩm',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: IconButton(
                      icon: const Icon(Icons.chat, color: Colors.white),
                      onPressed: () => Navigator.pushNamed(context, '/chat'),
                    ),
                  ),
                  SizedBox(width: 10),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() {
                      _isHoveredDK = true;
                    }),
                    onExit: (_) => setState(() {
                      _isHoveredDK = false;
                    }),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _isHoveredDK
                              ? const Color.fromARGB(255, 255, 48, 1)
                              : Colors.red,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            'Đăng ký',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 5),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 255, 98, 0),
                    ),
                    child: SizedBox(
                      width: 2,
                      height: 23,
                    ),
                  ),
                  SizedBox(width: 5),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() {
                      _isHoveredDN = true;
                    }),
                    onExit: (_) => setState(() {
                      _isHoveredDN = false;
                    }),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _isHoveredDN
                              ? const Color.fromARGB(255, 255, 48, 1)
                              : Colors.red,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            'Đăng nhập',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: ClipOval(
                          child: SizedBox(
                            width: 33,
                            height: 33,
                            child: Material(
                              color: Colors.transparent,
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
                                          return GestureDetector(
                                            onTap: () {
                                              if (isWeb) {
                                                // For web platform, check login status
                                                if (UserInfo().currentUser ==
                                                    null) {
                                                  Navigator.pushNamed(
                                                      context, '/login');
                                                } else {
                                                  Navigator.pushNamed(
                                                      context, '/info');
                                                }
                                              } else {
                                                // For non-web platforms (mobile/desktop)
                                                Navigator.pushNamed(
                                                    context, '/info');
                                              }
                                            },
                                            child: Image.memory(
                                              snapshot.data!,
                                              fit: BoxFit.cover,
                                            ),
                                          );
                                        } else {
                                          // Fall back to network image if cache failed
                                          return GestureDetector(
                                            onTap: () {
                                              if (isWeb) {
                                                // For web platform, check login status
                                                if (UserInfo().currentUser ==
                                                    null) {
                                                  Navigator.pushNamed(
                                                      context, '/login');
                                                } else {
                                                  Navigator.pushNamed(
                                                      context, '/info');
                                                }
                                              } else {
                                                // For non-web platforms (mobile/desktop)
                                                Navigator.pushNamed(
                                                    context, '/info');
                                              }
                                            },
                                            child: Image.network(
                                              UserInfo().currentUser!.avatar!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return IconButton(
                                                  padding: EdgeInsets.zero,
                                                  icon: const Icon(Icons.person,
                                                      color: Colors.black),
                                                  onPressed: () =>
                                                      Navigator.pushNamed(
                                                          context, '/info'),
                                                );
                                              },
                                            ),
                                          );
                                        }
                                      },
                                    )
                                  : IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.person,
                                          color: Colors.black),
                                      onPressed: () {
                                        if (isWeb) {
                                          // For web platform, check login status
                                          if (UserInfo().currentUser == null) {
                                            Navigator.pushNamed(
                                                context, '/login');
                                          } else {
                                            Navigator.pushNamed(
                                                context, '/info');
                                          }
                                        } else {
                                          // For non-web platforms (mobile/desktop)
                                          Navigator.pushNamed(context, '/info');
                                        }
                                      },
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        UserInfo().currentUser?.fullName ?? '',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  )
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logoSNew.png', // Remove leading slash
                height: 70,
                width: 70,
              ),
              SizedBox(width: 10),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.61,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: TextField(
                            controller: searchService.searchController,
                            decoration: InputDecoration(
                              hintText:
                                  'Shopii đảm bảo chất lượng, giao hàng tận nơi - Đăng ký ngay!',
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
                          onTap: () => Navigator.pushNamed(context, '/search'),
                          child: Container(
                            width: 45,
                            height: 40,
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
              MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() {
                  _isHoveredGH = true;
                }),
                onExit: (_) => setState(() {
                  _isHoveredGH = false;
                }),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/cart'),
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
              )
            ],
          ),
        ],
      ),
    );
  }
}
