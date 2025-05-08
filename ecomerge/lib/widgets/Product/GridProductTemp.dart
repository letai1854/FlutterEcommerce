import 'package:e_commerce_app/database/models/product_dto.dart';
import 'package:e_commerce_app/widgets/Product/ProductItem.dart';
import 'package:flutter/material.dart';

class PaginatedProductGrid extends StatefulWidget {
  final List<ProductDTO> productData;
  final int itemsPerPage;
  final double gridWidth;
  final double childAspectRatio;
  final int crossAxisCount;
  final double mainSpace;
  final double crossSpace;
  // Add loading state parameters
  final bool isProductsLoading;
  final bool canLoadMoreProducts;

  const PaginatedProductGrid({
    Key? key,
    required this.productData,
    required this.itemsPerPage,
    required this.gridWidth,
    required this.childAspectRatio,
    required this.crossAxisCount,
    required this.mainSpace,
    required this.crossSpace,
    required this.isProductsLoading,
    required this.canLoadMoreProducts,
  }) : super(key: key);

  @override
  _PaginatedProductGridState createState() => _PaginatedProductGridState();
}

class _PaginatedProductGridState extends State<PaginatedProductGrid> {
  List<Widget> _displayedProducts = [];
  bool _isNearBottom = false;

  @override
  void initState() {
    super.initState();
    _updateDisplayedProducts(); // Update displayed products when widget initializes
  }

  @override
  void didUpdateWidget(PaginatedProductGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If product data changes, update displayed products
    if (widget.productData != oldWidget.productData) {
      _updateDisplayedProducts();
    }
  }

  // Get responsive grid parameters based on screen width
  Map<String, dynamic> _getResponsiveValues(double width) {
    // Default to provided values initially
    int columns = widget.crossAxisCount;
    double aspectRatio = widget.childAspectRatio;
    double spacing = widget.crossSpace;

    // Adjust based on screen width
    if (width >= 1400) {
      columns = 5; // 5 products per row on large screens
      aspectRatio = 0.75;
      spacing = 16;
    } else if (width >= 1100) {
      columns = 4; // 4 products per row on medium-large screens
      aspectRatio = 0.8;
      spacing = 14;
    } else if (width >= 800) {
      columns = 3; // 3 products per row on medium screens
      aspectRatio = 0.85;
      spacing = 12;
    } else if (width >= 600) {
      columns = 2; // 2 products per row on small screens
      aspectRatio = 0.9;
      spacing = 10;
    } else {
      columns = 1; // 1 product per row on very small screens
      aspectRatio = 1.0;
      spacing = 8;
    }

    return {
      'columns': columns,
      'aspectRatio': aspectRatio,
      'spacing': spacing,
      'imageHeight': width / columns * 0.65, // Adaptive image height
      'titleSize': width > 600 ? 16.0 : 14.0,
      'descriptionSize': width > 600 ? 14.0 : 12.0,
      'priceSize': width > 600 ? 16.0 : 14.0,
      'padding': width > 600 ? 16.0 : 12.0,
      'starSize': width > 600 ? 16.0 : 14.0,
    };
  }

  // Build loading indicator card
  Widget _buildLoadingCard(Map<String, dynamic> responsive) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(responsive['padding']),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 16,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: double.infinity * 0.7,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateDisplayedProducts() {
    _displayedProducts = widget.productData
        .map((product) => ProductItem(
              productId: product.id ?? 0, // Pass the product ID
              imageUrl: product.mainImageUrl,
              title: product.name,
              describe: product.description,
              price: product.minPrice ?? 0,
              discount: product.discountPercentage?.toInt(),
              rating: product.averageRating ?? 0,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.gridWidth,
      child: LayoutBuilder(builder: (context, constraints) {
        final responsive = _getResponsiveValues(constraints.maxWidth);
        final columns = responsive['columns'] as int;

        return Column(
          mainAxisSize: MainAxisSize.min, // Use minimum space needed
          children: [
            if (widget.productData.isEmpty && !widget.isProductsLoading)
              // Show message when no products are available
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Text(
                    'Không có sản phẩm nào trong danh mục này',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              // Show product grid if we have products
              GridView.builder(
                physics:
                    NeverScrollableScrollPhysics(), // Disable GridView scrolling
                shrinkWrap: true, // Make grid only as tall as its content
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns, // Use responsive columns
                  childAspectRatio: responsive['aspectRatio'],
                  mainAxisSpacing: widget.mainSpace,
                  crossAxisSpacing: responsive['spacing'],
                ),
                itemCount: widget.productData.length +
                    (widget.isProductsLoading && widget.canLoadMoreProducts
                        ? columns
                        : 0),
                itemBuilder: (context, index) {
                  // Show loading indicators at the end
                  if (index >= widget.productData.length) {
                    return _buildLoadingCard(responsive);
                  }

                  // Show product item
                  final product = widget.productData[index];
                  return ProductItem(
                    productId: product.id ?? 0,
                    imageUrl: product.mainImageUrl,
                    title: product.name,
                    describe: product.description,
                    price: product.minPrice ?? 0.0,
                    discount: product.discountPercentage?.toInt(),
                    rating: product.averageRating ?? 0.0,
                  );
                },
              ),

            // Show loading indicators below the grid if needed
            if (widget.isProductsLoading &&
                widget.canLoadMoreProducts &&
                widget.productData.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        );
      }),
    );
  }
}
