import 'package:e_commerce_app/state/Search/SearchStateService.dart';
import 'package:flutter/material.dart';

class NavbarhomeTablet extends StatefulWidget {
  final BuildContext scaffoldContext;
  const NavbarhomeTablet(this.scaffoldContext, {Key? key}) : super(key: key);
  @override
  _NavbarhomeTabletState createState() => _NavbarhomeTabletState();
}

class _NavbarhomeTabletState extends State<NavbarhomeTablet> {
  // --- Giữ nguyên state hover của bạn ---
  bool _isHoveredTK = false;
  bool _isHoveredGH = false;

  @override
  Widget build(BuildContext context) {
    // --- DÒNG 2: LẤY INSTANCE SINGLETON ---
    final searchService = SearchStateService();
    // --- Giữ nguyên code gốc của bạn ---
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: const Color.fromARGB(255, 234, 29, 7),
      child: Column(
        children: [
          Row( // --- Hàng trên ---
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row( // Links
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
              IconButton( // Icon Menu
                icon: Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  // --- Sửa lại để dùng scaffoldContext ---
                  Scaffold.of(context).openDrawer();
                },
              ),
            ],
          ),
          // --- Hàng dưới ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset( // Logo
                '/logoSNew.png',
                height: 70,
                width: 70,
              ),
              SizedBox(width: 10),
              SizedBox( // Thanh tìm kiếm
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
                            // --- DÒNG 3: GÁN CONTROLLER ---
                            controller: searchService.searchController,
                            // --- Giữ nguyên decoration gốc ---
                            decoration: InputDecoration(
                              hintText:'Shopii đảm bảo chất lượng, giao hàng tận nơi - Đăng ký ngay!',
                              border: InputBorder.none,
                              hintStyle: TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                      MouseRegion( // Nút tìm kiếm
                        cursor: SystemMouseCursors.click,
                        onEnter: (_) => setState(() {
                          _isHoveredTK = true;
                        }),
                        onExit: (_) => setState(() {
                          _isHoveredTK = false;
                        }),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/search');
                          },
                          child: Container( // Giữ nguyên style nút search
                            width: 45,
                            height: 40, // Nên bằng height container cha
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
              MouseRegion( // Icon giỏ hàng
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
                  child: Container( // Giữ nguyên style icon giỏ hàng
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
