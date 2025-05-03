import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:e_commerce_app/Constants/productTest.dart';
import 'package:e_commerce_app/Provider/UserProvider.dart';
import 'package:e_commerce_app/constants.dart';
import 'package:e_commerce_app/widgets/BottomNavigation.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarMobile.dart';
import 'package:e_commerce_app/widgets/Product/PaginatedProductGrid.dart';
import 'package:e_commerce_app/widgets/Product/ProductItem.dart';
import 'package:e_commerce_app/widgets/Search/FilterPanel.dart';
import 'package:e_commerce_app/widgets/SortingBar.dart';
import 'package:e_commerce_app/widgets/footer.dart';
import 'package:e_commerce_app/widgets/navbarHomeMobile.dart';
import 'package:e_commerce_app/widgets/navbarHomeTablet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Testsearch extends StatefulWidget {
  const Testsearch({super.key});

  @override
  State<Testsearch> createState() => _TestsearchState();
}

class _TestsearchState extends State<Testsearch> {
  // Carousel state
  int _current = 0;

  // Product data state
  List<Map<String, dynamic>> productData = Productest.productData;
  List<Map<String, dynamic>> filteredProducts = [];
  
  // Pagination state
  List<Widget> _displayedProducts = [];
  bool _isLoading = false;
  bool _isNearBottom = false;
  final int itemsPerPage = 10;

  // Controllers
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Banner images
  final List<String> imgList = [
    'assets/bannerMain.jpg',
    'assets/banner2.jpg',
    'assets/banner6.jpg',
  ];

  @override
  void initState() {
    super.initState();
    filteredProducts = List.from(productData);
    _loadMoreItems();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupScrollListener();
    });
  }

  void _setupScrollListener() {
    ScrollPosition? scrollPosition = Scrollable.of(context)?.position;
    if (scrollPosition != null) {
      scrollPosition.addListener(() {
        final maxScroll = scrollPosition.maxScrollExtent;
        final currentScroll = scrollPosition.pixels;
        if (currentScroll > maxScroll - 800 && !_isLoading && !_isNearBottom) {
          setState(() {
            _isNearBottom = true;
          });
          _loadMoreItems().then((_) {
            setState(() {
              _isNearBottom = false;
            });
          });
        }
      });
    }
  }

  Future<void> _loadMoreItems() async {
    if (_isLoading || _displayedProducts.length >= productData.length) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(Duration(seconds: 2));

    final int startIndex = _displayedProducts.length;
    final int endIndex = min(startIndex + itemsPerPage, productData.length);

    List<Widget> newProducts = productData
        .sublist(startIndex, endIndex)
        .map((data) => ProductItem(
              imageUrl: data['image'],
              title: data['title'],
              describe: data['describe'],
              price: data['price'],
              discount: data['discount'],
              rating: data['rating'],
            ))
        .toList();

    if (mounted) {
      setState(() {
        _displayedProducts.addAll(newProducts);
        _isLoading = false;
      });
    }
  }

  void onFiltersApplied({
    required List<int> categories,
    required List<String> brands,
    required int minPrice,
    required int maxPrice,
  }) {
    setState(() {
      filteredProducts = productData.where((product) {
        bool matchesCategory = categories.isEmpty || categories.contains(product['category_id']);
        bool matchesBrand = brands.isEmpty || brands.contains(product['brand']);
        bool matchesPrice = product['price'] >= minPrice && product['price'] <= maxPrice;
        return matchesCategory && matchesBrand && matchesPrice;
      }).toList();

      if (MediaQuery.of(context).size.width < 1100) {
        Navigator.of(context).pop();
      }
    });
  }

  void _onCurrentIndexChanged(int index) {
    setState(() {
      _current = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return SearchMobile(
        current: _current,
        productData: productData,
        filteredProducts: filteredProducts,
        scrollController: _scrollController,
        scaffoldKey: _scaffoldKey,
        imgList: imgList,
        onFiltersApplied: onFiltersApplied,
        onCurrentIndexChanged: _onCurrentIndexChanged,
        displayedProducts: _displayedProducts,
        isLoading: _isLoading,
        onLoadMore: _loadMoreItems,
      );
    } else if(screenWidth<1000){
     return SearchTablet(
        current: _current,
        productData: productData,
        filteredProducts: filteredProducts,
        scrollController: _scrollController,
        scaffoldKey: _scaffoldKey,
        imgList: imgList,
        onFiltersApplied: onFiltersApplied,
        onCurrentIndexChanged: _onCurrentIndexChanged,
        displayedProducts: _displayedProducts,
        isLoading: _isLoading,
        onLoadMore: _loadMoreItems,
      );
    }
     else {
      return SearchDesktop(
         current: _current,
        productData: productData,
        filteredProducts: filteredProducts,
        scrollController: _scrollController,
        scaffoldKey: _scaffoldKey,
        imgList: imgList,
        onFiltersApplied: onFiltersApplied,
        onCurrentIndexChanged: _onCurrentIndexChanged,
        displayedProducts: _displayedProducts,
        isLoading: _isLoading,
        onLoadMore: _loadMoreItems,
      ); 
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class SearchMobile extends StatefulWidget {
  final int current;
  final List<Map<String, dynamic>> productData;
  final List<Map<String, dynamic>> filteredProducts;
  final ScrollController scrollController;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<String> imgList;
  final void Function({
    required List<int> categories,
    required List<String> brands,
    required int minPrice,
    required int maxPrice,
  }) onFiltersApplied;
  final ValueChanged<int> onCurrentIndexChanged;
  final List<Widget> displayedProducts;
  final bool isLoading;
  final Function() onLoadMore;

  const SearchMobile({
    super.key,
    required this.current,
    required this.productData,
    required this.filteredProducts,
    required this.scrollController,
    required this.scaffoldKey,
    required this.imgList,
    required this.onFiltersApplied,
    required this.onCurrentIndexChanged,
    required this.displayedProducts,
    required this.isLoading,
    required this.onLoadMore,
  });

  @override
  State<SearchMobile> createState() => _SearchMobileState();
}


class _SearchMobileState extends State<SearchMobile> {
  @override
  Widget build(BuildContext context) {
    return NavbarFixmobile(
      body: SearchProduct(
        current: widget.current,
        productData: widget.productData,
        filteredProducts: widget.filteredProducts,
        scrollController: widget.scrollController,
        scaffoldKey: widget.scaffoldKey,
        imgList: widget.imgList,
        onFiltersApplied: widget.onFiltersApplied,
        onCurrentIndexChanged: widget.onCurrentIndexChanged,
        displayedProducts: widget.displayedProducts,
        isLoading: widget.isLoading,
        onLoadMore: widget.onLoadMore,
      ),
    );
  }
}


class NavbarFixmobile extends StatefulWidget {
  final Widget? body; // Thêm body để hiển thị nội dung bên trong Scaffold

  const NavbarFixmobile({super.key, this.body});

  @override
  State<NavbarFixmobile> createState() => _NavbarmobileDrawerState();
}

class _NavbarmobileDrawerState extends State<NavbarFixmobile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 90,
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer Header
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.red),
              child: GestureDetector(
                  onTap: () {
                  Navigator.pushNamed(context, '/info');
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: const Icon(Icons.person),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Le Van Tai',
                      style: TextStyle(fontSize: 25, color: Colors.white),
                    ),
                  ],
                ),


              ),
            ),
            
            // Conditional ListTiles for Web
            if (!isMobile) ...[
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Trang chủ'),
                onTap: () {
                  Navigator.pushNamed(context, '/');
                },
              ),
              ListTile(
                leading: const Icon(Icons.list_alt),
                title: const Text('Danh sách sản phẩm'),
                onTap: () {
                  Navigator.pushNamed(context, '/catalog_product');
                },
              ),
            ],
            
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
          ],
        ),
      ),
      body: widget.body, 
      bottomNavigationBar: isMobile ? BottomNavBar() : null,
    );
  }
}

class SearchProduct extends StatefulWidget {
  final int current;
  final List<Map<String, dynamic>> productData;
  final List<Map<String, dynamic>> filteredProducts;
  final ScrollController scrollController;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<String> imgList;
  final void Function({
    required List<int> categories,
    required List<String> brands,
    required int minPrice,
    required int maxPrice,
  }) onFiltersApplied;
  final ValueChanged<int> onCurrentIndexChanged;
  final List<Widget> displayedProducts;
  final bool isLoading;
  final Function() onLoadMore;

  const SearchProduct({
    super.key,
    required this.current,
    required this.productData,
    required this.filteredProducts,
    required this.scrollController,
    required this.scaffoldKey,
    required this.imgList,
    required this.onFiltersApplied,
    required this.onCurrentIndexChanged,
    required this.displayedProducts,
    required this.isLoading,
    required this.onLoadMore,
  });

  @override
  State<SearchProduct> createState() => _SearchProductState();
}

class _SearchProductState extends State<SearchProduct> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isWideScreen = size.width >= 1100;

    // Base spacing calculations
    final double minSpacing = 16.0;
    final double maxSpacing = 24.0;
    final double spacing = (size.width * 0.02).clamp(minSpacing, maxSpacing);

    // Calculate filter panel width
    final double filterWidth = isWideScreen ? min(size.width * 0.2, 280.0) : 0;

    // Calculate main content width
    final double mainContentWidth = isWideScreen
        ? size.width - filterWidth - (spacing * 3)
        : size.width - (spacing * 2);

    return Scaffold(
      key: widget.scaffoldKey,
      endDrawer: !isWideScreen ?
        Drawer(
          width: min(size.width * 0.85, 400.0),
          child: FilterPanel(onFiltersApplied: widget.onFiltersApplied),
        ) : null,
      body: Container(
        color: Colors.grey[100],
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isWideScreen)
              Padding(
                padding: EdgeInsets.all(spacing),
                child: SizedBox(
                  width: filterWidth,
                  child: FilterPanel(onFiltersApplied: widget.onFiltersApplied),
                ),
              ),

            Expanded(
              child: Padding(
                padding: EdgeInsets.all(spacing),
                child: SingleChildScrollView(
                  controller: widget.scrollController,
                  child: Column(
                    children: [
                      // Carousel Section
                      SizedBox(
                        width: mainContentWidth,
                        height: mainContentWidth * 0.3,
                        child: CarouselSlider(
                          items: widget.imgList.map((item) => Container(
                            margin: EdgeInsets.symmetric(horizontal: spacing/2),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.asset(
                                item,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          )).toList(),
                          options: CarouselOptions(
                            height: mainContentWidth * 0.3,
                            autoPlay: true,
                            enlargeCenterPage: true,
                            viewportFraction: isWideScreen ? 0.8 : 0.95,
                            onPageChanged: (index, _) => widget.onCurrentIndexChanged(index),
                          ),
                        ),
                      ),

                      SizedBox(height: spacing),

                      // Sorting Bar Section
                      Container(
                        width: mainContentWidth,
                        padding: EdgeInsets.all(spacing/2),
                        child: Row(
                          children: [
                            Expanded(
                              child: SortingBar(
                                width: mainContentWidth * 0.9,
                                onSortChanged: (sortType) {},
                              ),
                            ),
                            if (!isWideScreen)
                              IconButton(
                                onPressed: () => widget.scaffoldKey.currentState?.openEndDrawer(),
                                icon: const Icon(Icons.filter_list),
                                color: Colors.red,
                              ),
                          ],
                        ),
                      ),

                      SizedBox(height: spacing),

                      // Product Grid Section
                      SizedBox(
                        width: mainContentWidth,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double minItemWidth = 200.0;  // Minimum width per item
                            final int maxColumns = (constraints.maxWidth / minItemWidth).floor();
                            final int columns = max(2, min(maxColumns, 5));  // Between 2 and 5 columns

                            final double itemSpacing = spacing * 0.75;

                            return PaginatedProductGrid(
                              productData: widget.filteredProducts,
                              itemsPerPage: columns * 2,
                              gridWidth: constraints.maxWidth,
                              childAspectRatio: 0.7,  // Taller items for better layout
                              crossAxisCount: columns,
                              mainSpace: itemSpacing,
                              crossSpace: itemSpacing,
                              displayedProducts: widget.displayedProducts,
                              isLoading: widget.isLoading,
                              scrollController: widget.scrollController,
                              onLoadMore: widget.onLoadMore,
                            );
                          },
                        ),
                      ),

                      SizedBox(height: spacing),

                      if (kIsWeb) const Footer(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




class SearchTablet extends StatefulWidget {
  final int current;
  final List<Map<String, dynamic>> productData;
  final List<Map<String, dynamic>> filteredProducts;
  final ScrollController scrollController;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<String> imgList;
  final void Function({
    required List<int> categories,
    required List<String> brands,
    required int minPrice,
    required int maxPrice,
  }) onFiltersApplied;
  final ValueChanged<int> onCurrentIndexChanged;
  final List<Widget> displayedProducts;
  final bool isLoading;
  final Function() onLoadMore;

  const SearchTablet({
    super.key,
    required this.current,
    required this.productData,
    required this.filteredProducts,
    required this.scrollController,
    required this.scaffoldKey,
    required this.imgList,
    required this.onFiltersApplied,
    required this.onCurrentIndexChanged,
    required this.displayedProducts,
    required this.isLoading,
    required this.onLoadMore,
  });

  @override
  State<SearchTablet> createState() => _SearchTabletState();
}

class _SearchTabletState extends State<SearchTablet> {
  @override
  Widget build(BuildContext context) {

    return NavbarFixTablet(
        body: SearchProduct(
        current: widget.current,
        productData: widget.productData,
        filteredProducts: widget.filteredProducts,
        scrollController: widget.scrollController,
        scaffoldKey: widget.scaffoldKey,
        imgList: widget.imgList,
        onFiltersApplied: widget.onFiltersApplied,
        onCurrentIndexChanged: widget.onCurrentIndexChanged,
        displayedProducts: widget.displayedProducts,
        isLoading: widget.isLoading,
        onLoadMore: widget.onLoadMore,
      ),
    );
  }
  }

class NavbarFixTablet extends StatefulWidget {
  final Widget? body; // Add body parameter to display content

  const NavbarFixTablet({super.key, this.body});

  @override
  State<NavbarFixTablet> createState() => _NavbarFixTabletState();
}

class _NavbarFixTabletState extends State<NavbarFixTablet> {
  @override
  Widget build(BuildContext context) {
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
                  Navigator.pushNamed(context, '/info');
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: const Icon(Icons.person),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Le Van Tai',
                      style: TextStyle(fontSize: 25, color: Colors.white),
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
          ],
        ),
      ),
      body: widget.body, // Use the body parameter passed to the widget
    );
  }
}



class SearchDesktop extends StatefulWidget {
  final int current;
  final List<Map<String, dynamic>> productData;
  final List<Map<String, dynamic>> filteredProducts;
  final ScrollController scrollController;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<String> imgList;
  final void Function({
    required List<int> categories,
    required List<String> brands,
    required int minPrice,
    required int maxPrice,
  }) onFiltersApplied;
  final ValueChanged<int> onCurrentIndexChanged;
  final List<Widget> displayedProducts;
  final bool isLoading;
  final Function() onLoadMore;

  const SearchDesktop({
    super.key,
    required this.current,
    required this.productData,
    required this.filteredProducts,
    required this.scrollController,
    required this.scaffoldKey,
    required this.imgList,
    required this.onFiltersApplied,
    required this.onCurrentIndexChanged,
    required this.displayedProducts,
    required this.isLoading,
    required this.onLoadMore,
  });


  @override
  State<SearchDesktop> createState() => _SearchDesktopState();
}

class _SearchDesktopState extends State<SearchDesktop> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(130),
        child: Navbarhomedesktop(),
      ),
        body: SearchProduct(
        current: widget.current,
        productData: widget.productData,
        filteredProducts: widget.filteredProducts,
        scrollController: widget.scrollController,
        scaffoldKey: widget.scaffoldKey,
        imgList: widget.imgList,
        onFiltersApplied: widget.onFiltersApplied,
        onCurrentIndexChanged: widget.onCurrentIndexChanged,
        displayedProducts: widget.displayedProducts,
        isLoading: widget.isLoading,
        onLoadMore: widget.onLoadMore,
      ),    );
  }
}
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
                      onTap: () {
                        // Chuyển hướng đến trang đăng ký
                        Navigator.pushNamed(context, '/signup');
                      },
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
                          onTap: () => Navigator.pushNamed(context, '/search'),
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








class PaginatedProductGrid extends StatefulWidget {
  final List<Map<String, dynamic>> productData;
  final int itemsPerPage;
  final double gridWidth;
  final double childAspectRatio;
  final int crossAxisCount;
  final double mainSpace;
  final double crossSpace;
  final List<Widget> displayedProducts;
  final bool isLoading;
  final ScrollController scrollController;
  final Function() onLoadMore;

  const PaginatedProductGrid({
    Key? key,
    required this.productData,
    required this.itemsPerPage,
    required this.gridWidth,
    required this.childAspectRatio,
    required this.crossAxisCount,
    required this.mainSpace,
    required this.crossSpace,
    required this.displayedProducts,
    required this.isLoading,
    required this.scrollController,
    required this.onLoadMore,
  }) : super(key: key);

  @override
  _PaginatedProductGridState createState() => _PaginatedProductGridState();
}

class _PaginatedProductGridState extends State<PaginatedProductGrid> {


  @override
  Widget build(BuildContext context) {
    // Calculate how many rows we need based on items and column count
    int totalRows = (widget.displayedProducts.length / widget.crossAxisCount).ceil();
    // Estimate height of grid based on item aspect ratio and spacing
    // This allows for dynamic height calculation
    double estimatedItemHeight = 180; // Base height estimate for a product item
    double estimatedGridHeight =
        totalRows * (estimatedItemHeight + widget.mainSpace);

    return Container(
      width: widget.gridWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min, // Use minimum space needed
        children: [
          GridView.builder(
            physics:
                NeverScrollableScrollPhysics(), // Disable GridView scrolling
            shrinkWrap: true, // Make grid only as tall as its content
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.crossAxisCount,
              childAspectRatio: widget.childAspectRatio,
              mainAxisSpacing: widget.mainSpace,
              crossAxisSpacing: widget.crossSpace,
            ),
            itemCount: widget.displayedProducts.length,
            itemBuilder: (context, index) {
              return widget.displayedProducts[index];
            },
          ),
          if (widget.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Đang tải thêm sản phẩm...'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
