import 'package:e_commerce_app/Provider/UserProvider.dart';
import 'package:e_commerce_app/state/Search/SearchStateService.dart';
// --- DÒNG 1: THÊM IMPORT SINGLETON ---
import 'package:flutter/material.dart';

class Navbarhomedesktop extends StatefulWidget {
  // --- Giữ nguyên constructor gốc của bạn ---
   const Navbarhomedesktop({Key? key}) : super(key: key); // Thêm const nếu được

  @override
  _NavbarhomedesktopState createState() => _NavbarhomedesktopState();
}

class _NavbarhomedesktopState extends State<Navbarhomedesktop> {
  // --- Giữ nguyên các biến state hover của bạn ---
  bool _isHoveredDK = false;
  bool _isHoveredDN = false;
  bool _isHoveredTK = false;
  bool _isHoveredGH = false;

  @override
  Widget build(BuildContext context) {
    // --- DÒNG 2: LẤY INSTANCE SINGLETON ---
    final searchService = SearchStateService();
    // --- Giữ nguyên toàn bộ cấu trúc Container và code gốc của bạn ---
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
                      onTap: () => Navigator.pushNamed(context, '/catalog_product'),
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
                      // --- Giữ nguyên logic onPressed gốc của bạn ---
                      // onPressed: UserProvider().currentUser != null
                      //   ? () => Navigator.pushNamed(context, '/chat')
                      //   : null,
                      onPressed: () => Navigator.pushNamed(context, '/chat'),
                    ),
                  ),
                  SizedBox(width: 10),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() {
                      _isHoveredDK = true;
                    }), // Set hover state on enter
                    onExit: (_) => setState(() {
                      _isHoveredDK = false;
                    }), // Clear hover state on exit
                    child: GestureDetector(
                      onTap: () {
                        // Chuyển hướng đến trang đăng ký
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: DecoratedBox( // --- Giữ nguyên DecoratedBox ---
                        decoration: BoxDecoration(
                          color:
                              _isHoveredDK // Conditional color based on hover state
                                  ? const Color.fromARGB(
                                      255, 255, 48, 1) // Orange on hover
                                  : Colors.red, // Original orange
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
                  DecoratedBox( // --- Giữ nguyên Đường kẻ ---
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 255, 98, 0),
                    ),
                    child: SizedBox(
                      width: 2,
                      height: 23,
                    ),
                  ),
                  SizedBox(width: 5),
                  MouseRegion( // --- Giữ nguyên Nút Đăng nhập ---
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() {
                      _isHoveredDN = true;
                    }), // Set hover state on enter
                    onExit: (_) => setState(() {
                      _isHoveredDN = false;
                    }), // Clear hover state on exit
                    child: GestureDetector(
                      onTap: () {
                        // Chuyển hướng đến trang đăng nhập
                        Navigator.pushNamed(context, '/login');
                      },
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color:
                              _isHoveredDN // Conditional color based on hover state
                                  ? const Color.fromARGB(
                                      255, 255, 48, 1) // Orange on hover
                                  : Colors.red, // Original orange
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
                  Row( // --- Giữ nguyên User Info ---
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
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.person,
                                    color: Colors.black),
                                onPressed: () {
                                  Navigator.pushNamed(context, '/info');
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Le Van Tai',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  )
                  // --- Hết User Info ---
                ],
              ),
            ],
          ),
          // --- Hàng dưới ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset( // --- Logo ---
                '/logoSNew.png',
                height: 70,
                width: 70,
              ),
              SizedBox(width: 10),
              SizedBox( // --- Thanh tìm kiếm ---
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
                            // --- Giữ nguyên decoration gốc của bạn ---
                            decoration: InputDecoration(
                              hintText:'Shopii đảm bảo chất lượng, giao hàng tận nơi - Đăng ký ngay!',
                              border: InputBorder.none,
                              hintStyle: TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                      MouseRegion( // --- Nút tìm kiếm ---
                        cursor: SystemMouseCursors.click,
                        onEnter: (_) => setState(() {
                          _isHoveredTK = true;
                        }),
                        onExit: (_) => setState(() {
                          _isHoveredTK = false;
                        }),
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/search'),
                          child: Container( // Giữ nguyên style nút search
                            width: 45,
                            height: 40, // Sửa height=40 cho bằng container cha
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
              MouseRegion( // --- Icon giỏ hàng ---
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() {
                  _isHoveredGH = true;
                }),
                onExit: (_) => setState(() {
                  _isHoveredGH = false;
                }),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/cart'),
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

  // --- KHÔNG THÊM HELPER FUNCTIONS NẾU CODE GỐC KHÔNG CÓ ---
}
