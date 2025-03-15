import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:e_commerce_app/constants.dart';
import 'package:e_commerce_app/widgets/BottomNavigation.dart';
import 'package:e_commerce_app/widgets/CategoryItem.dart';
import 'package:e_commerce_app/widgets/ProductGridView.dart';
import 'package:e_commerce_app/widgets/SortingBar.dart';
import 'package:e_commerce_app/widgets/footer.dart';
import 'package:e_commerce_app/widgets/navbarHomeMobile.dart';

class ListproductMobile extends StatefulWidget {
  const ListproductMobile({super.key});

  @override
  State<ListproductMobile> createState() => _ListproductMobileState();
}

class _ListproductMobileState extends State<ListproductMobile> {
  int _current = 0;
  bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  final ScrollController _scrollController = ScrollController();

  final List<String> imgList = [
    'assets/bannerMain.jpg',
    'assets/banner2.jpg',
    'assets/banner2.jpg',
    'assets/banner6.jpg',
  ];

  final List<Map<String, dynamic>> catalog = [
    {
      'name': 'Laptop',
      'img': 'https://anhnail.com/wp-content/uploads/2024/11/son-goku-ngau-nhat.jpg',
      'id': 1,
    },
    {
      'name': 'Bàn phím',
      'img': 'https://hoangtuan.vn/media/product/844_ban_phim_co_geezer_gs2_rgb_blue_switch.jpg',
      'id': 2,
    },
    {
      'name': 'Chuột',
      'img': 'https://png.pngtree.com/png-vector/20240626/ourlar…n-transparent-background-a-png-image_12849468.png',
      'id': 3,
    },
    {
      'name': 'Hub',
      'img': 'https://vienthongxanh.vn/wp-content/uploads/2022/12/hinh-anh-minh-hoa-thiet-bi-switch.png',
      'id': 4,
    },
    {
      'name': 'Tai nghe',
      'img': 'https://img.lovepik.com/free-png/20211120/lovepik-headset-png-image_401058941_wh1200.png',
      'id': 5,
    }
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 90, // Adjusted height to account for status bar
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
    drawer: !isMobile ? Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.red),
            child: GestureDetector(
              onTap: () {
                print("Nhấn vào thông tin người dùng");
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Le Van Tai',
                    style: TextStyle(
                      fontSize: 25,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_add_alt),
            title: const Text('Đăng ký'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.person_3_rounded),
            title: const Text('Đăng nhập'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Nhắn tin'),
            onTap: () {},
          ),
        ],
      ),
    ) : null,
      body: Container(
        color: Colors.grey[300],
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed Category Sidebar
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 16),
              child: Container(
                width: 70,
                height: MediaQuery.of(context).size.height - 130,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ListView.builder(
                  itemCount: catalog.length,
                  itemBuilder: (context, index) {
                    return CategoryItem(
                      name: catalog[index]['name'],
                      imageUrl: catalog[index]['img'],
                      id: catalog[index]['id'],
                      width: 120,
                      onTap: () {
                        print('Selected category: ${catalog[index]['name']}');
                      },
                    );
                  },
                ),
              ),
            ),

            // Main Content Area
            // Main Content Area
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16), // Match sidebar padding
                    child: SortingBar(
                      width: double.infinity, // Use full width within padding
                      onSortChanged: (sortType) {
                        print('Sort by: $sortType');
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: SizedBox(
                      child: ProductListView(
                        width: double.infinity,
                        scrollController: _scrollController,
                      ),
                    ),
                  ),
                  if (kIsWeb) const Footer(),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
      // bottomNavigationBar: isMobile ?  BottomNavBar() : null,
    );
  }
}
