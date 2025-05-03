import 'package:e_commerce_app/Constants/productTest.dart';
import 'package:e_commerce_app/widgets/Product/PaginatedProductGrid.dart';
import 'package:e_commerce_app/widgets/SortingBar.dart';
import 'package:e_commerce_app/widgets/footer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class CatalogProduct extends StatefulWidget {
  final List<Map<String, dynamic>> filteredProducts;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final ScrollController scrollController;
  final String currentSortMethod;
  final int selectedCategoryId;
  final List<Map<String, dynamic>> catalog;
  final Function(int) updateSelectedCategory;
  final Function(String) updateSortMethod;

  const CatalogProduct({
    super.key,
    required this.filteredProducts,
    required this.scaffoldKey,
    required this.scrollController,
    required this.currentSortMethod,
    required this.selectedCategoryId,
    required this.catalog,
    required this.updateSelectedCategory,
    required this.updateSortMethod,
  });

  @override
  State<CatalogProduct> createState() => _CatalogProductState();
}

class _CatalogProductState extends State<CatalogProduct> {
  Widget _buildCategoryPanel(double width, bool isMobile) {
    return Container(
      width: width,
      color: Colors.white,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 8),
        itemCount: widget.catalog.length,
        itemBuilder: (context, index) {
          final category = widget.catalog[index];
          final bool isSelected = widget.selectedCategoryId == category['id'];
          
          return Material(
            color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
            child: InkWell(
              onTap: () => widget.updateSelectedCategory(category['id']),
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
    var products = List<Map<String, dynamic>>.from(widget.filteredProducts);
    if (widget.currentSortMethod.isNotEmpty) {
      switch (widget.currentSortMethod) {
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
      key: widget.scaffoldKey,
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
                controller: widget.scrollController,
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
                              onPressed: () => widget.scaffoldKey.currentState?.openDrawer(),
                            ),
                          Expanded(
                            child: SortingBar(
                              width: double.infinity,
                              onSortChanged: widget.updateSortMethod,
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
