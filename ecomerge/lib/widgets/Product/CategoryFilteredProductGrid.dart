import 'package:e_commerce_app/database/PageResponse.dart';
import 'package:e_commerce_app/database/models/product_dto.dart';
import 'package:e_commerce_app/database/services/product_service.dart';
import 'package:e_commerce_app/widgets/Product/ProductItem.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CategoryFilteredProductGrid extends StatefulWidget {
  final int? categoryId;
  final double gridWidth;
  final int itemsToLoadPerPage; // Number of items to fetch per API call
  final int crossAxisCount; // Number of columns in the grid
  final double childAspectRatio;
  final double mainSpace;
  final double crossSpace;

  const CategoryFilteredProductGrid({
    Key? key,
    this.categoryId,
    required this.gridWidth,
    required this.itemsToLoadPerPage,
    required this.crossAxisCount,
    required this.childAspectRatio,
    required this.mainSpace,
    required this.crossSpace,
  }) : super(key: key);

  @override
  _CategoryFilteredProductGridState createState() =>
      _CategoryFilteredProductGridState();
}

class _CategoryFilteredProductGridState
    extends State<CategoryFilteredProductGrid> {
  final ProductService _productService = ProductService();
  List<ProductDTO> _products = [];
  int _currentPage = 0;
  bool _isLoadingFirstLoad = true; // For initial loading state
  bool _isLoadingMore = false; // For loading more items
  bool _hasMore = true;
  String? _error;
  ScrollPosition? _scrollPosition; // To listen to parent scroll

  @override
  void initState() {
    super.initState();
    _fetchProducts(page: 0, isInitialLoad: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupScrollListener();
    });
  }

  void _setupScrollListener() {
    // Find the ancestor Scrollable's position
    _scrollPosition = Scrollable.of(context)?.position;
    _scrollPosition?.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollPosition != null) {
      final maxScroll = _scrollPosition!.maxScrollExtent;
      final currentScroll = _scrollPosition!.pixels;
      // Load more when user is near the bottom, e.g., 300 pixels from the end
      if (currentScroll >= maxScroll - 300 &&
          _hasMore &&
          !_isLoadingMore &&
          !_isLoadingFirstLoad) {
        _loadMoreProducts();
      }
    }
  }

  @override
  void didUpdateWidget(CategoryFilteredProductGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categoryId != oldWidget.categoryId) {
      _resetAndFetchProducts();
    }
  }

  void _resetAndFetchProducts() {
    setState(() {
      _products = [];
      _currentPage = 0;
      _hasMore = true;
      _error = null;
      _isLoadingFirstLoad = true; // Show initial loader again
    });
    _fetchProducts(page: 0, isInitialLoad: true);
  }

  Future<void> _fetchProducts(
      {required int page, bool isInitialLoad = false}) async {
    if (isInitialLoad) {
      setState(() {
        _isLoadingFirstLoad = true;
        _error = null;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
        _error = null;
      });
    }

    try {
      final PageResponse<ProductDTO> response =
          await _productService.fetchProducts(
        categoryId: widget.categoryId,
        page: page,
        size: widget.itemsToLoadPerPage,
        sortBy: 'createdDate',
        sortDir: 'desc',
      );

      if (mounted) {
        setState(() {
          if (page == 0) {
            _products = response.content;
          } else {
            _products.addAll(response.content);
          }
          _currentPage = response.number;
          _hasMore = !response.last;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Không thể tải sản phẩm: ${e.toString()}";
          if (kDebugMode) {
            print(
                "Error fetching products for category ${widget.categoryId}: $e");
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          if (isInitialLoad) {
            _isLoadingFirstLoad = false;
          } else {
            _isLoadingMore = false;
          }
        });
      }
    }
  }

  void _loadMoreProducts() {
    if (_hasMore && !_isLoadingMore && !_isLoadingFirstLoad) {
      _fetchProducts(page: _currentPage + 1);
    }
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 16,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 12,
              width: double.infinity * 0.7,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingFirstLoad && _products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null && _products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              Text(_error!, style: TextStyle(color: Colors.red, fontSize: 16)),
        ),
      );
    }

    if (_products.isEmpty && !_isLoadingFirstLoad && !_isLoadingMore) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Không có sản phẩm nào trong danh mục này.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.crossAxisCount,
            childAspectRatio: widget.childAspectRatio,
            mainAxisSpacing: widget.mainSpace,
            crossAxisSpacing: widget.crossSpace,
          ),
          itemCount: _products.length,
          itemBuilder: (context, index) {
            final product = _products[index];
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
        if (_isLoadingMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('Đang tải thêm sản phẩm...'),
                ],
              ),
            ),
          ),
        if (!_hasMore &&
            _products.isNotEmpty &&
            !_isLoadingFirstLoad &&
            !_isLoadingMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text("Đã hiển thị tất cả sản phẩm.",
                style: TextStyle(color: Colors.grey)),
          )
      ],
    );
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_onScroll); // Remove listener
    _productService.dispose();
    super.dispose();
  }
}
