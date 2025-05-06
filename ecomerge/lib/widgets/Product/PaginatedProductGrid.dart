import 'package:e_commerce_app/database/models/product_dto.dart'; // Import ProductDTO
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

  void _updateDisplayedProducts() {
    _displayedProducts = widget.productData.map((product) => ProductItem(
          productId: product.id ?? 0, // Pass the product ID
          imageUrl: product.mainImageUrl,
          title: product.name,
          describe: product.description,
          price: product.minPrice ?? 0,
          discount: product.discountPercentage?.toInt(),
          rating: product.averageRating ?? 0,
        )).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.gridWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min, // Use minimum space needed
        children: [
          if (_displayedProducts.isEmpty && !widget.isProductsLoading)
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
              physics: NeverScrollableScrollPhysics(), // Disable GridView scrolling
              shrinkWrap: true, // Make grid only as tall as its content
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.crossAxisCount,
                childAspectRatio: widget.childAspectRatio,
                mainAxisSpacing: widget.mainSpace,
                crossAxisSpacing: widget.crossSpace,
              ),
              itemCount: _displayedProducts.length,
              itemBuilder: (context, index) {
                return _displayedProducts[index];
              },
            ),

          // Only show loading indicator if more products can be loaded and is currently loading
          if (widget.isProductsLoading && widget.canLoadMoreProducts)
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

          // Show "No more products" message when we've reached the end
          if (!widget.canLoadMoreProducts && _displayedProducts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Không còn sản phẩm nào để hiển thị',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
