import 'package:e_commerce_app/Models/User_model.dart';
import 'package:e_commerce_app/Provider/UserProvider.dart';
import 'package:flutter/material.dart';

class Navbarhomedesktop extends StatefulWidget {
  @override
  _NavbarhomedesktopState createState() => _NavbarhomedesktopState();
}

class _NavbarhomedesktopState extends State<Navbarhomedesktop> {
  bool _isHoveredDK = false;
  bool _isHoveredDN = false;
  bool _isHoveredTK = false;
  bool _isHoveredGH = false;
  @override
  Widget build(BuildContext context) {
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
                      onTap: () {},
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
                      onTap: () {},
                      child: const Text(
                        'Danh sách sản phẩm',
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
                      onPressed: UserProvider().currentUser != null 
                        ? () => Navigator.pushNamed(context, '/chat')
                        : null,
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
                      onTap: () {},
                      child: DecoratedBox(
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
                    }), // Set hover state on enter
                    onExit: (_) => setState(() {
                      _isHoveredDN = false;
                    }), // Clear hover state on exit
                    child: GestureDetector(
                      onTap: () {},
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
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.person,
                                    color: Colors.black),
                                onPressed: () {},
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
                ],
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
                          onTap: () {},
                          child: Container(
                            width: 45,
                            height: 45,
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
              )
            ],
          ),
        ],
      ),
    );
  }
}
