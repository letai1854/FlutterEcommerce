import 'package:e_commerce_app/constants.dart';
import 'package:e_commerce_app/state/Search/SearchStateService.dart';
import 'package:flutter/material.dart';

class NavbarHomeMobile extends StatefulWidget {
  final BuildContext scaffoldContext;
  const NavbarHomeMobile(this.scaffoldContext, {Key? key}) : super(key: key);

  @override
  State<NavbarHomeMobile> createState() => _NavbarHomeMobileState();
}

class _NavbarHomeMobileState extends State<NavbarHomeMobile> {
  bool _isHoveredTK = false;
  bool _isHoveredGH = false;
  bool _isHoveredChat = false;
  
  // Create a class-level singleton instance of SearchStateService
  final SearchStateService _searchService = SearchStateService();

  @override
  Widget build(BuildContext context) {
    // Remove any local instance creation of SearchStateService and use the class-level one instead
    
    return Container(
      color: const Color.fromARGB(255, 234, 29, 7),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          // Thanh tìm kiếm
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 13),
                      child: TextField(
                        controller: _searchService.searchController,  // Use the class-level singleton controller
                        decoration: InputDecoration(
                          hintText: 'Thanh tìm kiếm',
                          border: InputBorder.none,
                          hintStyle: TextStyle(fontSize: 14),
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            // Use the centralized executeSearch method
                            _searchService.executeSearch().then((_) {
                              Navigator.pushNamed(context, '/search');
                            });
                          }
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
                        if (_searchService.searchController.text.trim().isNotEmpty) {
                          // Use the centralized executeSearch method
                          _searchService.executeSearch().then((_) {
                            Navigator.pushNamed(context, '/search');
                          });
                        }
                      },
                      child: Container(
                        width: 45,
                        height: 53, // Giữ nguyên height gốc
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

          // Biểu tượng giỏ hàng
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
                Navigator.pushNamed(context, '/cart',
                    arguments: {'selectedIndex': -1});
              },
              child: Container( // Giữ nguyên Container gốc
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
          ),

          SizedBox(width: 10),

          // Biểu tượng nhắn tin/menu
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() {
              _isHoveredChat = true;
            }),
            onExit: (_) => setState(() {
              _isHoveredChat = false;
            }),
            child: GestureDetector( // Giữ nguyên GestureDetector gốc
              onTap: () {
                // Giữ nguyên logic tap gốc (dù là chat hay menu)
                // Nếu là chat:
                // Navigator.pushNamed(context, '/chat');
                // Nếu là menu (như code gốc):
                // Scaffold.of(context).openDrawer(); // Dùng context này hay widget.scaffoldContext? Giữ nguyên của bạn
                 Scaffold.of(context).openDrawer(); // Dùng context được truyền vào
              },
              child: Container( // Giữ nguyên Container gốc
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _isHoveredChat
                      ? const Color.fromARGB(255, 255, 48, 1)
                      : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                // Giữ nguyên IconButton gốc bên trong
                child: IconButton(
                  icon: Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                     // Giữ nguyên onPressed gốc của bạn
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
