import 'dart:typed_data';
import 'package:e_commerce_app/Constants/productTest.dart';
import 'package:e_commerce_app/constants.dart';
import 'package:e_commerce_app/database/Storage/BrandCategoryService.dart';
import 'package:e_commerce_app/database/models/categories.dart';
import 'package:e_commerce_app/widgets/Product/CategoriesSection.dart';
import 'package:e_commerce_app/widgets/Product/CategoryFilteredProductGrid.dart';
import 'package:e_commerce_app/widgets/Product/ProductItem.dart'
    as product_item;
import 'package:e_commerce_app/widgets/Product/PromotionalProductsList.dart';
import 'package:e_commerce_app/widgets/carousel/carouselDesktop.dart';
import 'package:e_commerce_app/widgets/carousel/carouselTablet.dart';
import 'package:e_commerce_app/widgets/footer.dart';
import 'package:e_commerce_app/widgets/headingbar/HeadingFeturePromotion.dart';
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';
import 'package:e_commerce_app/widgets/navbarHomeTablet.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForMobile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/widgets/Home/bodyHomeMobile.dart';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/database/services/user_service.dart';
import 'package:e_commerce_app/database/services/categories_service.dart';

class ResponsiveHome extends StatefulWidget {
  const ResponsiveHome({super.key});

  @override
  State<ResponsiveHome> createState() => _ResponsiveHomeState();
}

class _ResponsiveHomeState extends State<ResponsiveHome> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _categoriesSectionKey = GlobalKey();
  final GlobalKey _paginatedGridKey = GlobalKey();
  final GlobalKey _footerKey = GlobalKey();
  final GlobalKey _newProductsKey = GlobalKey(debugLabel: 'newProducts');
  final GlobalKey _promoProductsKey = GlobalKey(debugLabel: 'promoProducts');
  final GlobalKey _bestSellerKey = GlobalKey(debugLabel: 'bestSeller');
  bool _showFloatingCategories = false;
  bool _isPanelExpanded = false; // For mobile panel expansion
  int? _selectedCategory;
  final CategoriesService _categoriesService = CategoriesService();
  List<CategoryDTO> _appCategories = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    AppDataService().addListener(_onAppDataChanged);
    _loadCategories();
  }

  void _onAppDataChanged() {
    if (mounted) {
      setState(() {
        _appCategories = AppDataService().categories;
      });
      _autoSelectInitialCategory(); // Auto-select after categories are updated
    }
  }

  void _loadCategories() {
    if (!AppDataService().isInitialized && !AppDataService().isLoading) {
      AppDataService().loadData().then((_) {
        if (mounted) {
          setState(() {
            _appCategories = AppDataService().categories;
          });
          _autoSelectInitialCategory(); // Auto-select after initial load
        }
      }).catchError((error) {
        if (kDebugMode) {
          print("Error loading app data in ResponsiveHome: $error");
        }
      });
    } else if (AppDataService().isInitialized) {
      if (mounted) {
        setState(() {
          _appCategories = AppDataService().categories;
        });
        _autoSelectInitialCategory(); // Auto-select if data was already initialized
      }
    }
  }

  void _autoSelectInitialCategory() {
    // Only run if categories are loaded and no category has been manually selected yet.
    if (_appCategories.isNotEmpty && _selectedCategory == null) {
      final displayedCategories = _appCategories.take(5).toList();
      if (displayedCategories.isNotEmpty) {
        // Find the category with the smallest ID among the displayed ones.
        // Treat null IDs as very large numbers for comparison.
        CategoryDTO smallestIdCategory =
            displayedCategories.reduce((current, next) {
          final currentId =
              current.id ?? 999999999; // A large number for null IDs
          final nextId = next.id ?? 999999999;
          return currentId < nextId ? current : next;
        });

        // Find the index of this category within the displayedCategories list.
        int indexOfSmallest = displayedCategories
            .indexWhere((cat) => cat.id == smallestIdCategory.id);

        if (indexOfSmallest != -1) {
          // Use _handleCategorySelected to update state and UI consistently.
          // This will also trigger the CategoryFilteredProductGrid to update.
          _handleCategorySelected(indexOfSmallest);
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    AppDataService().removeListener(_onAppDataChanged);
    super.dispose();
  }

  void _onScroll() {
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
      final viewportHeight = MediaQuery.of(context).size.height;

      final isCategoryVisible =
          categoryPosition.dy + categoryBox.size.height > 0 &&
              categoryPosition.dy < viewportHeight;
      final isGridVisible = gridPosition.dy < viewportHeight &&
          gridPosition.dy + gridBox.size.height > 0;

      bool isOverlappingFooter = false;
      if (footerRenderObject is RenderBox) {
        final footerBox = footerRenderObject;
        final footerPosition = footerBox.localToGlobal(Offset.zero);
        final floatingMenuBottom = 150 + 200;

        if (footerPosition.dy < viewportHeight &&
            footerPosition.dy < floatingMenuBottom) {
          isOverlappingFooter = true;
        }
      }

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
      _isPanelExpanded = false; // Close mobile panel when category is selected
    });

    if (_showFloatingCategories) {
      final BuildContext? categoriesContext =
          _categoriesSectionKey.currentContext;
      if (categoriesContext != null) {
        Scrollable.ensureVisible(
          categoriesContext,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.0,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        Widget appBar;
        Widget? drawer;
        bool isMobileView = false;

        if (screenWidth < 600) {
          if (isMobile) {
            return Scaffold(
              body: NavbarFormobile(
                body: _buildHomeContent(
                  screenWidth,
                  isMobile: isMobileView,
                  isTablet: screenWidth < 1100 && screenWidth >= 600,
                  isDesktop: screenWidth >= 1100,
                ),
              ),
            );
          }

          // Web mobile-style layout
          appBar = PreferredSize(
            preferredSize: Size.fromHeight(90),
            child: Container(
              color: const Color.fromARGB(255, 234, 29, 7),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Thanh tìm kiếm',
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 15),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        IconButton(
                          icon: Icon(Icons.shopping_cart, color: Colors.white),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/cart'),
                        ),
                        Builder(
                          builder: (context) => IconButton(
                            icon: Icon(Icons.menu, color: Colors.white),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
          drawer = _buildDrawer(context, screenWidth);
          isMobileView = true;
        } else if (screenWidth < 1100) {
          // Tablet layout
          appBar = PreferredSize(
            preferredSize: Size.fromHeight(130),
            child: AppBar(
              automaticallyImplyLeading: false,
              toolbarHeight: 130,
              flexibleSpace: NavbarhomeTablet(context),
            ),
          );
          drawer = _buildDrawer(context, screenWidth);
        } else {
          // Desktop layout
          appBar = PreferredSize(
            preferredSize: Size.fromHeight(130),
            child: Navbarhomedesktop(),
          );
        }

        return Scaffold(
          appBar: appBar as PreferredSize,
          drawer: drawer,
          body: _buildHomeContent(
            screenWidth,
            isMobile: isMobileView,
            isTablet: screenWidth < 1100 && screenWidth >= 600,
            isDesktop: screenWidth >= 1100,
          ),
        );
      },
    );
  }

  Widget _buildHomeContent(double screenWidth,
      {bool isMobile = false, bool isTablet = false, bool isDesktop = false}) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                if (isDesktop)
                  Carouseldesktop(screenWidth)
                else
                  CarouselTablet(screenWidth),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 140 : (isTablet ? 1 : 0),
                    vertical: 0,
                  ),
                  child: Column(
                    children: [
                      Heading(Icons.bolt, Colors.yellowAccent,
                          'Sản phẩm khuyến mãi'),
                      SizedBox(height: 10),
                      Container(
                        height: isMobile ? 400 : 400,
                        child: PromotionalProductsList(
                          productListKey: _promoProductsKey,
                          itemsPerPage: isMobile ? 6 : 7,
                          gridHeight: isMobile ? 400 : 400,
                          gridWidth: screenWidth,
                          childAspectRatio: isMobile ? 1.8 : 1.9,
                          crossAxisCount: 1,
                          mainSpace: 9.7,
                          crossSpace: 10,
                        ),
                      ),
                      SizedBox(height: 10),
                      Heading(Icons.new_releases, Colors.yellowAccent,
                          'Sản phẩm mới nhất'),
                      SizedBox(height: 10),
                      Builder(
                        builder: (context) {
                          int itemsPerPage;
                          double sectionHeight;
                          double listChildAspectRatio;
                          int listCrossAxisCount;
                          double listMainSpace;
                          double listCrossSpace;
                          double listEffectiveGridWidth;

                          double contentAreaWidth = screenWidth -
                              (isDesktop ? 280 : (isTablet ? 2 : 0));

                          if (isDesktop) {
                            sectionHeight = 700;
                            double bannerWidth = contentAreaWidth * 0.27;
                            double spacerWidth = 10;
                            listEffectiveGridWidth =
                                contentAreaWidth - bannerWidth - spacerWidth;

                            itemsPerPage = 10;
                            listCrossAxisCount = 2;
                            listChildAspectRatio = 1.85;
                            listMainSpace = 9.7;
                            listCrossSpace = 10;
                          } else if (isTablet) {
                            sectionHeight = 700;
                            listEffectiveGridWidth = contentAreaWidth;

                            itemsPerPage = 12;
                            listCrossAxisCount = 2;
                            listChildAspectRatio = 1.85;
                            listMainSpace = 9.7;
                            listCrossSpace = 8;
                          } else {
                            sectionHeight = 400;
                            listEffectiveGridWidth = contentAreaWidth;

                            itemsPerPage = 12;
                            listCrossAxisCount = 1;
                            listChildAspectRatio = 1.8;
                            listMainSpace = 10;
                            listCrossSpace = 10;
                          }

                          return Container(
                            height: sectionHeight,
                            child: Row(
                              children: [
                                Offstage(
                                  offstage: !isDesktop,
                                  child: SizedBox(
                                    width: contentAreaWidth * 0.27,
                                    height: sectionHeight,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: AssetImage(
                                              'assets/bannerMain.jpg'),
                                          fit: BoxFit.cover,
                                          alignment: Alignment.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Offstage(
                                  offstage: !isDesktop,
                                  child: SizedBox(width: 10),
                                ),
                                Expanded(
                                  child: PromotionalProductsList(
                                    productListKey: _newProductsKey,
                                    itemsPerPage: itemsPerPage,
                                    gridHeight: sectionHeight,
                                    gridWidth: listEffectiveGridWidth,
                                    childAspectRatio: listChildAspectRatio,
                                    crossAxisCount: listCrossAxisCount,
                                    mainSpace: listMainSpace,
                                    crossSpace: listCrossSpace,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 10),
                      Heading(Icons.local_fire_department, Colors.yellowAccent,
                          'Sản phẩm bán chạy nhất'),
                      SizedBox(height: 10),
                      Container(
                        height: isMobile ? 400 : 700,
                        child: PromotionalProductsList(
                          productListKey: _bestSellerKey,
                          itemsPerPage: isMobile ? 6 : 14,
                          gridHeight: isMobile ? 400 : 700,
                          gridWidth: screenWidth,
                          childAspectRatio: isMobile ? 1.8 : 1.85,
                          crossAxisCount: isMobile ? 1 : 2,
                          mainSpace: isMobile ? 10 : 9.7,
                          crossSpace: isMobile ? 10 : 8,
                        ),
                      ),
                      SizedBox(height: 10),
                      CategoriesSection(
                        key: _categoriesSectionKey,
                        selectedIndex: _selectedCategory,
                        onCategorySelected: _handleCategorySelected,
                        categories:
                            _appCategories, // Pass the dynamic categories here
                      ),
                      SizedBox(height: 10),
                      Column(
                        key: _paginatedGridKey,
                        children: [
                          Builder(
                            builder: (context) {
                              int? categoryIdToPass;
                              if (_selectedCategory != null &&
                                  _appCategories.isNotEmpty) {
                                final displayedCategories =
                                    _appCategories.take(5).toList();
                                if (_selectedCategory! <
                                    displayedCategories.length) {
                                  categoryIdToPass =
                                      displayedCategories[_selectedCategory!]
                                          .id;
                                }
                              }

                              return SizedBox(
                                width: isDesktop
                                    ? screenWidth - 280
                                    : screenWidth - 2,
                                child: CategoryFilteredProductGrid(
                                  categoryId: categoryIdToPass,
                                  itemsToLoadPerPage: isMobile ? 2 : 6,
                                  gridWidth: isDesktop
                                      ? screenWidth - 280
                                      : screenWidth - 2,
                                  childAspectRatio: 0.5,
                                  crossAxisCount:
                                      _getCrossAxisCount(screenWidth),
                                  mainSpace: 10,
                                  crossSpace: 8.0,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 50),
                      SizedBox(height: 50),
                    ],
                  ),
                ),
                if (kIsWeb) Footer(key: _footerKey),
              ],
            ),
          ),
        ),
        if (_showFloatingCategories)
          (isMobile || isTablet)
              ? _buildMobileFloatingCategories(isTablet: isTablet)
              : _buildFloatingCategories(),
      ],
    );
  }

  int _getItemsPerPage(double screenWidth) {
    if (screenWidth < 600) return 6;
    if (screenWidth < 800) return 6;
    if (screenWidth < 1300) return 8;
    if (screenWidth < 1470) return 10;
    return 12;
  }

  int _getCrossAxisCount(double screenWidth) {
    if (screenWidth < 600) return 2;
    if (screenWidth < 800) return 3;
    if (screenWidth < 1300) return 4;
    if (screenWidth < 1470) return 5;
    return 6;
  }

  Widget _buildMobileFloatingCategories({bool isTablet = false}) {
    final List<CategoryDTO> categoriesToShow = _appCategories.take(5).toList();

    return Positioned(
      right: 0,
      top: isTablet
          ? 100 // Higher position for tablets
          : MediaQuery.of(context).size.height / 2 - 50,
      child: AnimatedOpacity(
        opacity: _showFloatingCategories ? 1.0 : 0.0,
        duration: Duration(milliseconds: 100),
        child: Row(
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: _isPanelExpanded ? (isTablet ? 200 : 150) : 0,
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: Offset(-2, 0),
                  ),
                ],
              ),
              child: _isPanelExpanded
                  ? Padding(
                      padding: EdgeInsets.all(isTablet ? 12.0 : 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Danh mục',
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            height: isTablet ? 300 : 200,
                            child: ListView(
                              shrinkWrap: true,
                              children:
                                  categoriesToShow.asMap().entries.map((entry) {
                                int idx = entry.key;
                                CategoryDTO category = entry.value;
                                return _buildVerticalCategoryItem(
                                    category, idx);
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isPanelExpanded = !_isPanelExpanded;
                });
              },
              child: Container(
                width: isTablet ? 30 : 25,
                height: isTablet ? 60 : 50,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isTablet ? 60 : 50),
                    bottomLeft: Radius.circular(isTablet ? 60 : 50),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(-1, 0),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _isPanelExpanded
                        ? Icons.arrow_forward_ios
                        : Icons.arrow_back_ios,
                    color: Colors.white,
                    size: isTablet ? 24 : 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingCategories() {
    final List<CategoryDTO> categoriesToShow = _appCategories.take(5).toList();

    return Positioned(
      right: 0,
      top: 150,
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
              topLeft: Radius.circular(8),
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
                    Icon(Icons.list, size: 24.0),
                    SizedBox(width: 8),
                    Text(
                      'Danh mục',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              ...categoriesToShow.asMap().entries.map((entry) {
                int idx = entry.key;
                CategoryDTO category = entry.value;
                return _buildVerticalCategoryItem(category, idx);
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalCategoryItem(CategoryDTO category, int itemIndex) {
    bool isSelected = _selectedCategory == itemIndex;
    String fullImageUrl = _categoriesService.getImageUrl(category.imageUrl);

    return GestureDetector(
      onTap: () {
        _handleCategorySelected(itemIndex);
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
              child: fullImageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15.0),
                      child: Image.network(
                        fullImageUrl,
                        fit: BoxFit.cover,
                        height: 30,
                        width: 30,
                        errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.category,
                            size: 20,
                            color: Colors.grey[400]),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Colors.grey[400],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Icon(Icons.category, size: 20, color: Colors.grey[400]),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                category.name ?? 'N/A',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, double screenWidth) {
    final bool isMobileView = screenWidth < 600;
    // Check if user is logged in
    final bool isLoggedIn = UserInfo().currentUser != null;

    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.red),
            child: GestureDetector(
              onTap: () {
                if (isWeb) {
                  // For web platform, check login status
                  if (UserInfo().currentUser == null) {
                    Navigator.pushNamed(context, '/login');
                  } else {
                    Navigator.pushNamed(context, '/info');
                  }
                } else {
                  // For non-web platforms (mobile/desktop)
                  Navigator.pushNamed(context, '/info');
                }
              },
              child: Row(
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            color: Colors.white,
                          ),
                          child: ClipOval(
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child: UserInfo().currentUser?.avatar != null
                                  ? FutureBuilder<Uint8List?>(
                                      future: UserService().getAvatarBytes(
                                          UserInfo().currentUser?.avatar),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                                ConnectionState.waiting &&
                                            !snapshot.hasData) {
                                          return Container(
                                            color: Colors.white,
                                            child: const Center(
                                              child: SizedBox(
                                                width: 15,
                                                height: 15,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          );
                                        } else if (snapshot.hasData &&
                                            snapshot.data != null) {
                                          // Use cached image if available
                                          return Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                            width: 60,
                                            height: 60,
                                          );
                                        } else {
                                          // Fall back to network image if cache failed
                                          return Container(
                                            color: Colors.white,
                                            child: Image.network(
                                              UserInfo().currentUser!.avatar!,
                                              fit: BoxFit.cover,
                                              width: 60,
                                              height: 60,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.white,
                                                  child: const Icon(
                                                      Icons.person,
                                                      color: Colors.black,
                                                      size: 30),
                                                );
                                              },
                                            ),
                                          );
                                        }
                                      },
                                    )
                                  : Container(
                                      color: Colors.white,
                                      child: const Icon(Icons.person,
                                          color: Colors.black, size: 30),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          UserInfo().currentUser?.fullName ?? '',
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
          // Only show Home and Product List items on mobile view (width < 600)
          if (isMobileView) ...[
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
          // Only show Register button if not logged in
          if (!isLoggedIn)
            ListTile(
              leading: const Icon(Icons.person_add_alt),
              title: const Text('Đăng ký'),
              onTap: () {
                Navigator.pushNamed(context, '/signup');
              },
            ),
          // Login/Logout button
          ListTile(
            leading: Icon(isLoggedIn ? Icons.logout : Icons.person_3_rounded),
            title: Text(isLoggedIn ? 'Đăng xuất' : 'Đăng nhập'),
            onTap: () {
              if (isLoggedIn) {
                UserInfo().logout(context);
              } else {
                Navigator.pushNamed(context, '/login');
              }
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
    );
  }
}
