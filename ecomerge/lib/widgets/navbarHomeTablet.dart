import 'dart:typed_data';

import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/database/services/user_service.dart';
import 'package:e_commerce_app/state/Search/SearchStateService.dart';
import 'package:flutter/material.dart';

class NavbarhomeTablet extends StatefulWidget {
  final BuildContext scaffoldContext;
  const NavbarhomeTablet(this.scaffoldContext, {Key? key}) : super(key: key);
  @override
  _NavbarhomeTabletState createState() => _NavbarhomeTabletState();
}

class _NavbarhomeTabletState extends State<NavbarhomeTablet> {
  bool _isHoveredTK = false;
  bool _isHoveredGH = false;

  @override
  Widget build(BuildContext context) {
    final searchService = SearchStateService();
    final bool isLoggedIn = UserInfo().currentUser != null;

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
                      onTap: () {
                        Navigator.pushNamed(context, '/home');
                      },
                      child: const Text(
                        'Trang chủ',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/catalog_product');
                      },
                      child: const Text(
                        'Danh sách sản phẩm',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
              // Row(
              //   children: [
              //     MouseRegion(
              //       cursor: SystemMouseCursors.click,
              //       child: IconButton(
              //         icon: const Icon(Icons.chat, color: Colors.white),
              //         onPressed: () => Navigator.pushNamed(context, '/chat'),
              //       ),
              //     ),
              //     SizedBox(width: 10),
              //     if (!isLoggedIn) ...[
              //       MouseRegion(
              //         cursor: SystemMouseCursors.click,
              //         child: GestureDetector(
              //           onTap: () {
              //             Navigator.pushNamed(context, '/signup');
              //           },
              //           child: Text(
              //             'Đăng ký',
              //             style: TextStyle(
              //               fontSize: 14,
              //               color: Colors.white,
              //             ),
              //           ),
              //         ),
              //       ),
              //       SizedBox(width: 5),
              //       Container(
              //         height: 16,
              //         width: 1,
              //         color: Colors.white54,
              //       ),
              //       SizedBox(width: 5),
              //     ],
              //     MouseRegion(
              //       cursor: SystemMouseCursors.click,
              //       child: GestureDetector(
              //         onTap: () {
              //           if (isLoggedIn) {
              //             UserInfo().logout(context);
              //           } else {
              //             Navigator.pushNamed(context, '/login');
              //           }
              //         },
              //         child: Text(
              //           isLoggedIn ? 'Đăng xuất' : 'Đăng nhập',
              //           style: TextStyle(
              //             fontSize: 14,
              //             color: Colors.white,
              //           ),
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
              IconButton(
                icon: Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                '/logoSNew.png',
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
                                  'Shopii đảm bảo chất lượng, giao hàng tận nơi - Đăng ký ngay!',
                              border: InputBorder.none,
                              hintStyle: TextStyle(fontSize: 14),
                            ),
                            onSubmitted: (value) {
                              // Execute search when Enter is pressed
                              searchService.executeSearch();
                              Navigator.pushNamed(context, '/search');
                            },
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
                          onTap: () {
                            // Execute search and navigate
                            searchService.executeSearch();
                            Navigator.pushNamed(context, '/search');
                          },
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
                  onTap: () {
                    Navigator.pushNamed(context, '/cart');
                  },
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
