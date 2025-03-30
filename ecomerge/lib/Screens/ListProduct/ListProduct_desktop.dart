import 'package:carousel_slider/carousel_slider.dart';
import 'package:e_commerce_app/Constants/productTest.dart';
import 'package:e_commerce_app/constants.dart';
import 'package:e_commerce_app/widgets/CategoryItem.dart';
import 'package:e_commerce_app/widgets/Product/PaginatedProductGrid.dart';
import 'package:e_commerce_app/widgets/ProductGridView.dart';
import 'package:e_commerce_app/widgets/SortingBar.dart';
import 'package:e_commerce_app/widgets/footer.dart';
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ListproductDesktop extends StatefulWidget {
  const ListproductDesktop({super.key});

  @override
  State<ListproductDesktop> createState() => _ListproductDesktopState();
}

class _ListproductDesktopState extends State<ListproductDesktop> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(130),
        child: Navbarhomedesktop(),
      ),
      body: catalogProduct(),
    );
  }
}



class catalogProduct extends StatefulWidget {
  const catalogProduct({super.key});
  
  @override
  State<catalogProduct> createState() => _catalogProductState();
}

class _catalogProductState extends State<catalogProduct> {
  int _current = 0;
  List<Map<String, dynamic>> productData = Productest.productData;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _categoriesSectionKey = GlobalKey();
  final GlobalKey _paginatedGridKey = GlobalKey();
    final List<Map<String, dynamic>> catalog = [
    {
      'name': 'Laptop',
      'img': 'https://anhnail.com/wp-content/uploads/2024/11/son-goku-ngau-nhat.jpg',
      'id':1,
      
    },
    {
      'name': 'Bàn phím',
      'img': '	https://hoangtuan.vn/media/product/844_ban_phim_co_geezer_gs2_rgb_blue_switch.jpg',
      'id':2,
    },
    {
      'name': 'Chuột',
      'img': '	https://png.pngtree.com/png-vector/20240626/ourlar…n-transparent-background-a-png-image_12849468.png',
      'id':3,
    },
    {
      'name': 'Hub',
      'img': ':	https://vienthongxanh.vn/wp-content/uploads/2022/12/hinh-anh-minh-hoa-thiet-bi-switch.png',
      'id':4,
    },
        {
      'name': 'Tai nghe',
      'img': 'https://img.lovepik.com/free-png/20211120/lovepik-headset-png-image_401058941_wh1200.png',
      'id':5,
    }
    ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  final List<String> imgList = [
    'assets/bannerMain.jpg',
    'assets/banner2.jpg',
    'assets/banner6.jpg',
  ];

  @override
 Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final carouselHeight = 230.0;

    return Container(
      color: Colors.grey[300], // Light gray background
      padding: EdgeInsets.only(top: 16), // Space from navbar
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed Category Sidebar with padding
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Container(
              width: 200,
              height: MediaQuery.of(context).size.height - 146, // Account for navbar and top padding
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: ClipRRect( // Clip the ListView to match container's border radius
                borderRadius: BorderRadius.circular(12),
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
          ),
          
          // Main Content Area
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  // Carousel Slider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    child: SizedBox(
                      width: screenWidth * 0.8,
                      height: carouselHeight,
                      child: CarouselSlider(
                        items: imgList.map((item) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(3.0),
                            child: Image.asset(
                              item,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: carouselHeight,
                              alignment: Alignment.center,
                            ),
                          );
                        }).toList(),
                        options: CarouselOptions(
                          autoPlay: true,
                          aspectRatio: 5,
                          enlargeCenterPage: true,
                          viewportFraction: 1.0,
                          height: carouselHeight,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _current = index;
                            });
                          },
                        ),
                      ),
                    ),
                  ),

                  // Sorting Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: SortingBar(
                      width: screenWidth * 0.8,
                      onSortChanged: (sortType) {
                        // Handle sort change
                        print('Sort by: $sortType');
                      },
                    ),
                  ),

                  // Product Grid with Pagination
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      key: _paginatedGridKey,
                      children: [
                        SizedBox(
                          width: screenWidth - 280,
                          child: PaginatedProductGrid(
                            productData: productData,
                            itemsPerPage: screenWidth < 1300
                                ? 8
                                : (screenWidth < 1470 ? 10 : 12),
                            gridWidth: screenWidth - 280,
                            childAspectRatio: 0.7,
                            crossAxisCount: screenWidth < 1300
                                ? 4
                                : (screenWidth < 1470 ? 5 : 6),
                            mainSpace: 10,
                            crossSpace: 8.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (kIsWeb)
                    const Footer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

