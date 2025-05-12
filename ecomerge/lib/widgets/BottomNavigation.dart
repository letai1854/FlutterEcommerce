import 'package:flutter/material.dart';

class BottomNavBar extends StatefulWidget {
  final int initialIndex;

  const BottomNavBar({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; // Tránh cập nhật nếu nhấn cùng icon

    setState(() {
      _selectedIndex = index;
    });

    final route = _getRoute(index);
    
    // Special handling for AI chatbot to prevent navigation stack issues
    if (route == '/ai-chat') {
      // Replace the current route instead of pushing a new one
      Navigator.pushReplacementNamed(context, route);
    } else {
      // Normal navigation for other routes
      Navigator.pushNamed(context, route);
    }
  }

  // Hàm lấy đường dẫn tương ứng với index
  String _getRoute(int index) {
    switch (index) {
      case 0:
        return '/home';
      case 1:
        return '/catalog_product';
      case 2:
        return '/ai-chat';
      case 3:
        return '/info';
      default:
        return '/home'; // Mặc định là trang chủ
    }
  }

  @override
  Widget build(BuildContext context) {
    // Đọc arguments trong build method (nếu cần)
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Check for arguments first
    if (args != null && args.containsKey('selectedIndex')) {
      final newIndex = args['selectedIndex'] as int;
      if (newIndex != _selectedIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedIndex = newIndex;
            });
          }
        });
      }
    }
    // Then check the route if no arguments are provided
    else {
      final String currentRoute = ModalRoute.of(context)?.settings.name ?? '';

      // If we're at home route with no arguments (app just started), select home tab
      if (currentRoute == '/' || currentRoute == '/home') {
        if (_selectedIndex != 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedIndex = 0;
              });
            }
          });
        }
      }
      // Handle other main routes
      else if (currentRoute == '/catalog_product' && _selectedIndex != 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedIndex = 1;
            });
          }
        });
      } else if (currentRoute == '/product_detail' && _selectedIndex != 2) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedIndex = 2;
            });
          }
        });
      } else if (currentRoute == '/info' && _selectedIndex != 3) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedIndex = 3;
            });
          }
        });
      }
      // For non-main routes, unselect all tabs
      else if (!['/home', '/', '/catalog_product', '/product_detail', '/info']
              .contains(currentRoute) &&
          _selectedIndex >= 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedIndex = -1;
            });
          }
        });
      }
    }

    return BottomNavigationBar(
      currentIndex: _selectedIndex < 0 ? 0 : _selectedIndex,
      unselectedItemColor: Colors.grey,
      selectedItemColor: _selectedIndex < 0 ? Colors.grey : Colors.red,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      items: [
        _buildNavItem(Icons.home, 'Trang chủ', 0),
        _buildNavItem(Icons.category_rounded, 'Sản phẩm', 1),
        _buildNavItem(Icons.smart_toy, 'AI Chat', 2),
        _buildNavItem(Icons.person, 'Tôi', 3),
      ],
    );
  }

  // Hàm tạo BottomNavigationBarItem với màu sắc phù hợp
  BottomNavigationBarItem _buildNavItem(
      IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    final bool noSelection = _selectedIndex < 0;

    return BottomNavigationBarItem(
      icon: Icon(
        icon,
        color: (noSelection || !isSelected) ? Colors.grey : Colors.red,
      ),
      label: label,
    );
  }
}
