import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:e_commerce_app/Constants/productTest.dart';
import 'package:e_commerce_app/constants.dart';
import 'package:e_commerce_app/widgets/Product/PaginatedProductGrid.dart';
import 'package:e_commerce_app/widgets/Product/ProductItem.dart'
    as product_item;
import 'package:e_commerce_app/widgets/Product/featured_product_item.dart'
    as featured_product;
import 'package:e_commerce_app/widgets/headingbar/HeadingFeturePromotion.dart';
import 'package:e_commerce_app/widgets/carousel/carouselDesktop.dart';
import 'package:e_commerce_app/widgets/footer.dart';
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HomeDesktop extends StatefulWidget {
  const HomeDesktop({super.key});

  @override
  State<HomeDesktop> createState() => _HomeDesktopState();
}

class _HomeDesktopState extends State<HomeDesktop> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(130),
        child: Navbarhomedesktop(),
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
  List<Map<String, dynamic>> productData = Productest.productData;
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
                Carouseldesktop(screenWidth),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 140, vertical: 0),
                  child: Column(
                    children: [
                      Heading(Icons.bolt, Colors.yellowAccent,
                          'Sản phẩm khuyến mãi'),
                      SizedBox(height: 10),
                      product_item.ProductList(
                        scroll: Axis.horizontal,

                        productData: productData,
                        itemsPerPage: 7,
                        gridHeight: 320,
                        gridWidth: screenWidth, // hoặc giá trị khác tùy ý
                        childAspectRatio: 1.59, // hoặc giá trị khác tùy ý
                        crossAxisCount: 1, // hoặc giá trị khác tùy ý
                        mainSpace: 9, // hoặc giá trị khác tùy ý
                        crossSpace: 8.0, // hoặc giá trị khác tùy ý
                      ),
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
                                SizedBox(
                                  width: screenWidth * 0.27,
                                  height: 600,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      // Bo tròn góc
                                      image: DecorationImage(
                                        image:
                                            AssetImage('assets/bannerMain.jpg'),
                                        fit: BoxFit.cover,
                                        alignment: Alignment.center,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: product_item.ProductList(
                                    scroll: Axis.horizontal,

                                    productData: productData,
                                    itemsPerPage: 8,
                                    gridHeight: 600,
                                    gridWidth: screenWidth *
                                        0.72, // hoặc giá trị khác tùy ý
                                    childAspectRatio:
                                        1.47, // hoặc giá trị khác tùy ý
                                    crossAxisCount:
                                        2, // hoặc giá trị khác tùy ý
                                    mainSpace: 9.7, // hoặc giá trị khác tùy ý
                                    crossSpace: 10, // hoặc giá trị khác tùy ý
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Heading(Icons.local_fire_department, Colors.yellowAccent,
                          'Sản phẩm bán chạy nhất'),
                      SizedBox(height: 10),
                      product_item.ProductList(
                        scroll: Axis.horizontal,
                        productData: productData,
                        itemsPerPage: 12,
                        gridHeight: 600,
                        gridWidth: screenWidth, // hoặc giá trị khác tùy ý
                        childAspectRatio: 1.47, // hoặc giá trị khác tùy ý
                        crossAxisCount: 2, // hoặc giá trị khác tùy ý
                        mainSpace: 9.7, // hoặc giá trị khác tùy ý
                        crossSpace: 8, // hoặc giá trị khác tùy ý
                      ),
                      SizedBox(height: 10),
                      // Main categories section with key for position tracking
                      CategoriesSection(
                        key: _categoriesSectionKey,
                        selectedIndex: _selectedCategory,
                        onCategorySelected: _handleCategorySelected,
                      ),
                      SizedBox(height: 10),

                      // Add key to the product grid section
                      Column(
                        key: _paginatedGridKey, // Thêm key để theo dõi vị trí
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
                    _buildVerticalCategoryItem(
                        'Laptop', 'assets/banner6.jpg', 0),
                    _buildVerticalCategoryItem('Ram', 'assets/banner6.jpg', 1),
                    _buildVerticalCategoryItem(
                        'Card đồ họa', 'assets/banner6.jpg', 2),
                    _buildVerticalCategoryItem(
                        'Màn hình', 'assets/banner6.jpg', 3),
                    _buildVerticalCategoryItem(
                        'Ổ cứng', 'assets/banner6.jpg', 4),
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

class CategoriesSection extends StatefulWidget {
  final int? selectedIndex;
  final Function(int)? onCategorySelected;

  const CategoriesSection({
    Key? key,
    this.selectedIndex,
    this.onCategorySelected,
  }) : super(key: key);

  @override
  _CategoriesSectionState createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<CategoriesSection> {
  Widget _buildCategoryItem(String title, String imageUrl, int index) {
    bool isSelected = widget.selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (widget.onCategorySelected != null) {
            widget.onCategorySelected!(index);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 28.0),
            child: Row(children: [
              Icon(
                Icons.list,
                size: 35.0,
              ),
              SizedBox(width: 1),
              Text(
                'Danh mục',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ]),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCategoryItem('Laptop', 'assets/banner6.jpg', 0),
              _buildCategoryItem('Ram', 'assets/banner6.jpg', 1),
              _buildCategoryItem('Card đồ họa', 'assets/banner6.jpg', 2),
              _buildCategoryItem('Màn hình', 'assets/banner6.jpg', 3),
              _buildCategoryItem('Ổ cứng', 'assets/banner6.jpg', 4),
            ],
          ),
        ],
      ),
    );
  }
}
