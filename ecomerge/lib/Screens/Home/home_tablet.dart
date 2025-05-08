import 'dart:math';

// Thay đổi: Thêm import với alias thay vì dùng getter null
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/widgets/Product/ProductItem.dart'
    as product_item;
import 'package:e_commerce_app/Constants/productTest.dart';
import 'package:e_commerce_app/constants.dart';
import 'package:e_commerce_app/widgets/Product/CategoriesSection.dart';
import 'package:e_commerce_app/widgets/carousel/carouselDesktop.dart';
import 'package:e_commerce_app/widgets/carousel/carouselTablet.dart';
import 'package:e_commerce_app/widgets/footer.dart';
import 'package:e_commerce_app/widgets/headingbar/HeadingFeturePromotion.dart';
import 'package:e_commerce_app/widgets/navbarHomeTablet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HomeTablet extends StatefulWidget {
  const HomeTablet({super.key});

  @override
  State<HomeTablet> createState() => _HomeTabletState();
}

class _HomeTabletState extends State<HomeTablet> {
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
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(130),
        child: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 130,
          flexibleSpace: NavbarhomeTablet(context),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.red),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/info');
                },
                child: Row(
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Row(
                        // Bọc lại để tránh lỗi
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                            ),
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
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_add_alt),
              title: const Text('Đăng ký'),
              onTap: () {
                Navigator.pushNamed(context, '/signup');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_3_rounded),
              title: const Text('Đăng nhập'),
              onTap: () {
                Navigator.pushNamed(context, '/login');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Nhắn tin'),
              onTap: () {
                Navigator.pushNamed(context, '/chat');
              },
            ),
          ],
        ),
      ),
      body: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _current = 0;
  final List<String> imgList = [
    'assets/bannerMain.jpg',
    'assets/banner2.jpg',
    'assets/banner6.jpg', // Thay thế bằng đường dẫn ảnh thực tế// Thay thế bằng đường dẫn ảnh thực tế
  ];
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _categoriesSectionKey = GlobalKey();
  final GlobalKey _paginatedGridKey =
      GlobalKey(); // Thêm key để theo dõi phần lưới sản phẩm
  final GlobalKey _footerKey = GlobalKey(); // Thêm key cho footer
  bool _showFloatingCategories = false;
  int? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Kiểm tra vị trí của phần CategoriesSection
    final RenderObject? categoryRenderObject =
        _categoriesSectionKey.currentContext?.findRenderObject();
    final RenderObject? gridRenderObject =
        _paginatedGridKey.currentContext?.findRenderObject();
    final RenderObject? footerRenderObject =
        _footerKey.currentContext?.findRenderObject();

    if (categoryRenderObject is RenderBox && gridRenderObject is RenderBox) {
      final RenderBox categoryBox = categoryRenderObject;
      final RenderBox gridBox = gridRenderObject;

      final categoryPosition = categoryBox.localToGlobal(Offset.zero);
      final gridPosition = gridBox.localToGlobal(Offset.zero);

      // Chiều cao của viewport
      final viewportHeight = MediaQuery.of(context).size.height;

      // Kiểm tra nếu CategoriesSection đã bị cuộn ra khỏi tầm nhìn
      final isCategoryVisible =
          categoryPosition.dy + categoryBox.size.height > 0 &&
              categoryPosition.dy < viewportHeight;

      // Kiểm tra nếu đang xem phần lưới sản phẩm
      final isGridVisible = gridPosition.dy < viewportHeight &&
          gridPosition.dy + gridBox.size.height > 0;

      // Kiểm tra có đang đè lên footer không
      bool isOverlappingFooter = false;
      if (footerRenderObject is RenderBox) {
        final footerBox = footerRenderObject;
        final footerPosition = footerBox.localToGlobal(Offset.zero);

        // Vị trí dự kiến của menu nổi
        // (150px từ trên xuống + chiều cao khoảng 200px)
        final floatingMenuBottom = 150 + 200;

        // Nếu footer đang hiển thị trong viewport và menu nổi sẽ đè lên nó
        if (footerPosition.dy < viewportHeight &&
            footerPosition.dy < floatingMenuBottom) {
          isOverlappingFooter = true;
        }
      }

      // Chỉ hiển thị thanh nổi khi:
      // 1. Danh mục gốc bị ẩn VÀ
      // 2. Phần lưới sản phẩm đang hiển thị VÀ
      // 3. Không đè lên footer
      final shouldShowFloating =
          !isCategoryVisible && isGridVisible && !isOverlappingFooter;

      if (_showFloatingCategories != shouldShowFloating) {
        setState(() {
          _showFloatingCategories = shouldShowFloating;
        });
      }
    }
  }

  void _handleCategorySelected(int index) {
    setState(() {
      _selectedCategory = index;
    });

    // Nếu đang hiển thị thanh danh mục nổi, cuộn về vị trí của CategoriesSection gốc
    if (_showFloatingCategories) {
      // Lấy context của phần danh mục gốc
      final BuildContext? categoriesContext =
          _categoriesSectionKey.currentContext;
      if (categoriesContext != null) {
        // Cuộn trang để hiển thị phần danh mục gốc
        Scrollable.ensureVisible(
          categoriesContext,
          duration: Duration(milliseconds: 500), // Thời gian chuyển động
          curve: Curves.easeInOut, // Kiểu chuyển động
          alignment: 0.0, // Căn lề trên của viewport (0.0 = trên cùng)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final carouselHeight = 230.0;
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                CarouselTablet(screenWidth),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
                  child: Column(
                    children: [
                      Heading(Icons.bolt, Colors.yellowAccent,
                          'Sản phẩm khuyến mãi'),
                      SizedBox(height: 10),
                      // product_item.ProductList(
                      //   scroll: Axis.horizontal,

                      //   productData: productData,
                      //   itemsPerPage: 7,
                      //   gridHeight: 320,
                      //   gridWidth: screenWidth, // hoặc giá trị khác tùy ý
                      //   childAspectRatio: 1.59, // hoặc giá trị khác tùy ý
                      //   crossAxisCount: 1, // hoặc giá trị khác tùy ý
                      //   mainSpace: 9, // hoặc giá trị khác tùy ý
                      //   crossSpace: 8.0, // hoặc giá trị khác tùy ý
                      // ),
                      SizedBox(height: 10),
                      Heading(Icons.new_releases, Colors.yellowAccent,
                          'Sản phẩm mới nhất'),
                      SizedBox(height: 10),
                      Container(
                        // banner
                        height: 600,

                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                // Expanded(
                                //   child: product_item.ProductList(
                                //     scroll: Axis.horizontal,

                                //     productData: productData,
                                //     itemsPerPage: 10,
                                //     gridHeight: 600,
                                //     gridWidth: screenWidth *
                                //         0.72, // hoặc giá trị khác tùy ý
                                //     childAspectRatio:
                                //         1.47, // hoặc giá trị khác tùy ý
                                //     crossAxisCount:
                                //         2, // hoặc giá trị khác tùy ý
                                //     mainSpace: 9.7, // hoặc giá trị khác tùy ý
                                //     crossSpace: 10, // hoặc giá trị khác tùy ý
                                //   ),
                                // ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Heading(Icons.local_fire_department, Colors.yellowAccent,
                          'Sản phẩm bán chạy nhất'),
                      SizedBox(height: 10),
                      // product_item.ProductList(
                      //   scroll: Axis.horizontal,
                      //   productData: productData,
                      //   itemsPerPage: 12,
                      //   gridHeight: 600,
                      //   gridWidth: screenWidth, // hoặc giá trị khác tùy ý
                      //   childAspectRatio: 1.47, // hoặc giá trị khác tùy ý
                      //   crossAxisCount: 2, // hoặc giá trị khác tùy ý
                      //   mainSpace: 9.7, // hoặc giá trị khác tùy ý
                      //   crossSpace: 8, // hoặc giá trị khác tùy ý
                      // ),
                      SizedBox(height: 10),
                      // Main categories section with key for position tracking
                      // CategoriesSection(
                      //   key: _categoriesSectionKey,
                      //   selectedIndex: _selectedCategory,
                      //   onCategorySelected: _handleCategorySelected,
                      // ),
                      SizedBox(height: 10),

                      // Add key to the product grid section
                      Column(
                        key: _paginatedGridKey, // Thêm key để theo dõi vị trí
                        children: [
                          // SizedBox(
                          //   width: screenWidth - 2,
                          //   child: ductGrid(
                          //     productData: productData,
                          //     itemsPerPage: screenWidth < 800
                          //         ? 6
                          //         : (screenWidth < 1300 ? 8 : 10),
                          //     gridWidth: screenWidth - 2,
                          //     childAspectRatio: 0.7,
                          //     crossAxisCount: screenWidth < 800
                          //         ? 3
                          //         : (screenWidth < 1470 ? 4 : 5),
                          //     mainSpace: 10,
                          //     crossSpace: 8.0,
                          //   ),
                          // ),
                        ],
                      ),

                      SizedBox(height: 50),
                    ],
                  ),
                ),
                if (kIsWeb) Footer(key: _footerKey),
              ],
            ),
          ),
        ),

        // Floating vertical category list
        if (_showFloatingCategories)
          Positioned(
            right: 0, // Thay đổi từ left: 0 thành right: 0 để đặt ở bên phải
            top: 150, // Position below the navbar
            child: AnimatedOpacity(
              opacity: _showFloatingCategories ? 1.0 : 0.0,
              duration: Duration(milliseconds: 100),
              child: Container(
                width: 139,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, 2),
                    ),
                  ],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(
                        8), // Thay đổi bo góc từ bên phải sang bên trái
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.list,
                            size: 24.0,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Danh mục',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    // _buildVerticalCategoryItem(
                    //     'Laptop', 'assets/banner6.jpg', 0),
                    // _buildVerticalCategoryItem('Ram', 'assets/banner6.jpg', 1),
                    // _buildVerticalCategoryItem(
                    //     'Card đồ họa', 'assets/banner6.jpg', 2),
                    // _buildVerticalCategoryItem(
                    //     'Màn hình', 'assets/banner6.jpg', 3),
                    // _buildVerticalCategoryItem(
                    //     'Ổ cứng', 'assets/banner6.jpg', 4),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVerticalCategoryItem(String title, String imageUrl, int index) {
    bool isSelected = _selectedCategory == index;

    return GestureDetector(
      onTap: () {
        _handleCategorySelected(index);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(imageUrl),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
