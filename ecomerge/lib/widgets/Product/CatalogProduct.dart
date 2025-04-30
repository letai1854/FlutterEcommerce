import 'package:e_commerce_app/Constants/productTest.dart';
import 'package:e_commerce_app/widgets/Product/PaginatedProductGrid.dart';
import 'package:e_commerce_app/widgets/SortingBar.dart';
import 'package:e_commerce_app/widgets/footer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class CatalogProduct extends StatefulWidget {
  const CatalogProduct({super.key});

  @override
  State<CatalogProduct> createState() => _CatalogProductState();
}

class _CatalogProductState extends State<CatalogProduct> {
  List<Map<String, dynamic>> productData = Productest.productData;
  List<Map<String, dynamic>> filteredProducts = [];
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String currentSortMethod = '';
  int selectedCategoryId = 1;

  final List<Map<String, dynamic>> catalog = [
    {'name': 'Laptop', 'id': 1, 'image': 'https://dlcdnwebimgs.asus.com/gain/28BC0310-AD69-4C0D-9DE7-C27974A50B96'},
    {'name': 'Bàn phím', 'id': 2, 'image': 'https://bizweb.dktcdn.net/100/438/322/products/k1-black-1.jpg?v=1702469045657'},
    {'name': 'Chuột', 'id': 3, 'image': 'https://lh3.googleusercontent.com/NP_cA_KiUpZi0D1QAiu8s5k3PiEWqO0SOgyLH99MPgR1VhsUPyVKL737pqRjq_yXjHaEjEK9pbVI2V0quyiAE2NhVg'},
    {'name': 'Hub', 'id': 4, 'image': 'https://vn.canon/media/image/2021/07/12/fe2cb6c6e86145899db11898c8492482_EOS+R5_FrontSlantLeft_RF24-105mmF4LISUSM.png'},
    {'name': 'Tai nghe', 'id': 5, 'image': 'https://researchstore.vn/uploads/2023/10/hinh-anh-thuong-hieu-logitech.jpg'},
    {'name': 'Bàn', 'id': 6, 'image': 'https://tinhocngoisao.cdn.vccloud.vn/wp-content/uploads/2021/09/asus-gaming-rog.jpg'},
  ];

  @override
  void initState() {
    super.initState();
    filteredProducts = List.from(productData);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildCategoryPanel(double width, bool isMobile) {
    return Container(
      width: width,
      color: Colors.white,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 8),
        itemCount: catalog.length,
        itemBuilder: (context, index) {
          final category = catalog[index];
          final bool isSelected = selectedCategoryId == category['id'];
          
          return Material(
            color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => selectedCategoryId = category['id']),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                        image: DecorationImage(
                          image: NetworkImage(category['image']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        category['name'],
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? Colors.blue : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> getSortedProducts() {
    var products = List<Map<String, dynamic>>.from(filteredProducts);
    if (currentSortMethod.isNotEmpty) {
      switch (currentSortMethod) {
        case 'name':
          products.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
          break;
        case 'price':
          products.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
          break;
        case 'new':
          products.sort((a, b) => (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString()));
          break;
        case 'rating':
          products.sort((a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0));
          break;
      }
    }
    return products;
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isWideScreen = size.width >= 1100;
    final bool isMobile = size.width < 600;
    
    // Base spacing calculations
    final double minSpacing = 16.0;
    final double maxSpacing = 24.0;
    final double spacing = (size.width * 0.02).clamp(minSpacing, maxSpacing);
    
    // Calculate category panel width based on screen size
    final double categoryWidth = isWideScreen 
        ? min(size.width * 0.2, 280.0) 
        : min(size.width * 0.25, 220.0);

    // Calculate main content width
    final double mainContentWidth = isWideScreen 
        ? size.width - categoryWidth - (spacing * 3)
        : size.width - categoryWidth - (spacing * 2);
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[100],
      // Drawer for mobile view
      drawer: isMobile ? Drawer(
        child: _buildCategoryPanel(min(size.width * 0.6, 280.0), isMobile),
      ) : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Panel - visible on tablet and desktop
          if (!isMobile)
            _buildCategoryPanel(categoryWidth, isMobile),
          
          // Main Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(spacing),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    // Sorting Bar Section with mobile menu button
                    Container(
                      width: isMobile ? double.infinity : mainContentWidth,
                      padding: EdgeInsets.all(spacing/2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          if (isMobile) 
                            IconButton(
                              icon: Icon(Icons.menu),
                              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                            ),
                          Expanded(
                            child: SortingBar(
                              width: double.infinity,
                              onSortChanged: (sortType) => setState(() => currentSortMethod = sortType),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: spacing),

                    // Product Grid Section
                    SizedBox(
                      width: isMobile ? double.infinity : mainContentWidth,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double minItemWidth = isMobile ? 160.0 : 200.0;
                          final int maxColumns = (constraints.maxWidth / minItemWidth).floor();
                          final int columns = max(2, min(maxColumns, isMobile ? 2 : 4));
                          
                          return PaginatedProductGrid(
                            productData: getSortedProducts(),
                            itemsPerPage: columns * 2,
                            gridWidth: constraints.maxWidth,
                            childAspectRatio: 0.6,
                            crossAxisCount: columns,
                            mainSpace: spacing,
                            crossSpace: spacing,
                          );
                        },
                      ),
                    ),

                    if (kIsWeb) ...[
                      SizedBox(height: spacing),
                      const Footer(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
