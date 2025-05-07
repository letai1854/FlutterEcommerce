import 'package:flutter/material.dart';
import 'package:e_commerce_app/database/models/paginated_response.dart';
import 'package:e_commerce_app/database/models/product_dto.dart';
import 'package:e_commerce_app/database/services/product_service.dart';
import 'package:e_commerce_app/Screens/ProductDetail/PageProductDetail.dart';
import 'package:flutter/foundation.dart';

// PromoProductItem displays a single promotional product
class PromoProductItem extends StatefulWidget {
  final int productId;
  final String? imageUrl;
  final String title;
  final String? describe;
  final double price;
  final int? discount;
  final double rating;

  const PromoProductItem({
    Key? key,
    required this.productId,
    required this.imageUrl,
    required this.title,
    this.describe,
    required this.price,
    this.discount,
    required this.rating,
  }) : super(key: key);

  @override
  State<PromoProductItem> createState() => _PromoProductItemState();
}

class _PromoProductItemState extends State<PromoProductItem> {
  static final ProductService _productService = ProductService();
  late Future<dynamic> _imageLoader;

  @override
  void initState() {
    super.initState();
    _initializeImageLoader();
  }

  @override
  void didUpdateWidget(PromoProductItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _initializeImageLoader();
    }
  }

  void _initializeImageLoader() {
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      _imageLoader = _productService.getImageFromServer(widget.imageUrl);
    }
  }

  void _navigateToProductDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Pageproductdetail(productId: widget.productId),
      ),
    );
  }

  String _formatDescription(String? description) {
    if (description == null || description.isEmpty) return "";
    final words = description.split(' ');
    if (words.length <= 5) {
      return description;
    } else {
      return '${words.take(5).join(' ')}...';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate discounted price
    double discountedPrice = widget.discount != null
        ? widget.price * (1 - widget.discount! / 100)
        : widget.price;

    // Format description
    String formattedDescription = _formatDescription(widget.describe);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _navigateToProductDetail,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  // Product image
                  FutureBuilder(
                    future: _imageLoader,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          width: double.infinity,
                          height: 120,
                          color: Colors.grey[200],
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      } else if (snapshot.hasData && snapshot.data != null) {
                        return Image.memory(
                          snapshot.data as dynamic,
                          width: double.infinity,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, error, stackTrace) => Container(
                            width: double.infinity,
                            height: 120,
                            color: Colors.grey[200],
                            child:
                                const Icon(Icons.image_not_supported, size: 40),
                          ),
                        );
                      } else {
                        return Container(
                          width: double.infinity,
                          height: 120,
                          color: Colors.grey[200],
                          child:
                              const Icon(Icons.image_not_supported, size: 40),
                        );
                      }
                    },
                  ),
                  // Discount badge
                  if (widget.discount != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 85, 0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${widget.discount}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Product details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Description
                      Text(
                        formattedDescription,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Price information
                      Row(
                        children: [
                          Text(
                            '${discountedPrice.toStringAsFixed(0)} đ',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.discount != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${widget.price.toStringAsFixed(0)} đ',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Rating stars
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < widget.rating.floor()
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 14,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Main PromotionalProductsList widget
class PromotionalProductsList extends StatefulWidget {
  final Key? productListKey;
  final int itemsPerPage;
  final double gridHeight;
  final double gridWidth;
  final double childAspectRatio;
  final int crossAxisCount;
  final double mainSpace;
  final double crossSpace;

  const PromotionalProductsList({
    Key? key,
    this.productListKey,
    required this.itemsPerPage,
    required this.gridHeight,
    required this.gridWidth,
    required this.childAspectRatio,
    required this.crossAxisCount,
    required this.mainSpace,
    required this.crossSpace,
  }) : super(key: key);

  @override
  State<PromotionalProductsList> createState() =>
      _PromotionalProductsListState();
}

class _PromotionalProductsListState extends State<PromotionalProductsList>
    with AutomaticKeepAliveClientMixin {
  final ProductService _productService = ProductService();
  final ScrollController _scrollController = ScrollController();

  List<PromoProductItem> _displayedProducts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _nextPageToRequest = 0;
  bool _hasMorePages = true;
  int _totalPagesFromAPI = 0;
  bool _isScrollingToEnd = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadInitialProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _productService.dispose();
    super.dispose();
  }

  Future<void> _loadInitialProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _nextPageToRequest = 0;
      _displayedProducts.clear();
    });

    try {
      final response = await _productService.getTopSellingProducts(
        page: _nextPageToRequest,
        size: widget.itemsPerPage,
      );

      if (kDebugMode) {
        print(
            'Loaded initial products. Page: ${response.number}, Total: ${response.content.length}, Is Last: ${response.last}, Total Pages: ${response.totalPages}');
      }

      _createProductItems(response.content);

      setState(() {
        _hasMorePages = !response.last;
        _totalPagesFromAPI = response.totalPages;
        _nextPageToRequest = response.number + 1;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading promotional products: $e');
      }
      setState(() {
        _errorMessage = 'Không thể tải sản phẩm khuyến mãi: $e';
        _isLoading = false;
      });
    }
  }

  void _createProductItems(List<ProductDTO> products) {
    final items = products
        .map((product) => PromoProductItem(
              productId: product.id ?? 0,
              imageUrl: product.mainImageUrl,
              title: product.name,
              describe: product.description,
              price: product.minPrice ?? 0.0,
              discount: product.discountPercentage?.toInt(),
              rating: product.averageRating ?? 0.0,
            ))
        .toList();
    if (_nextPageToRequest == 0 || _displayedProducts.isEmpty) {
      setState(() {
        _displayedProducts = items;
      });
    }
  }

  Future<void> _loadMoreProducts() async {
    if (!_hasMorePages || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
      if (_scrollController.position.pixels > 0) {
        _isScrollingToEnd = true;
      }
    });

    try {
      final int itemsToFetch = widget.itemsPerPage;

      if (kDebugMode) {
        print(
            'Loading promotional products page $_nextPageToRequest with $itemsToFetch items per page');
      }

      final response = await _productService.getTopSellingProducts(
        page: _nextPageToRequest,
        size: itemsToFetch,
      );

      if (kDebugMode) {
        print(
            'Loaded page ${response.number}. Total items: ${response.content.length}, Is Last: ${response.last}, Total Pages: ${response.totalPages}');
      }

      if (response.content.isEmpty && !response.last) {
        setState(() {
          _hasMorePages = false;
          _isLoadingMore = false;
          _isScrollingToEnd = false;
        });
        return;
      }

      final newItems = response.content
          .map((product) => PromoProductItem(
                productId: product.id ?? 0,
                imageUrl: product.mainImageUrl,
                title: product.name,
                describe: product.description,
                price: product.minPrice ?? 0.0,
                discount: product.discountPercentage?.toInt(),
                rating: product.averageRating ?? 0.0,
              ))
          .toList();

      setState(() {
        _displayedProducts.addAll(newItems);
        _hasMorePages = !response.last;
        _totalPagesFromAPI = response.totalPages;
        _nextPageToRequest = response.number + 1;
        _isLoadingMore = false;
        _isScrollingToEnd = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading more promotional products: $e');
      }
      setState(() {
        _isLoadingMore = false;
        _isScrollingToEnd = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Không thể tải thêm sản phẩm khuyến mãi: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _onScroll() {
    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double currentScroll = _scrollController.position.pixels;
    final double loadTriggerOffset = widget.gridWidth * 0.2;

    if (maxScroll > 0 && currentScroll >= (maxScroll - loadTriggerOffset)) {
      if (!_isLoadingMore && _hasMorePages) {
        if (kDebugMode) {
          print(
              "PromotionalProductsList: Scroll near end detected. Attempting to load more. Next Page: $_nextPageToRequest");
        }
        _loadMoreProducts();
      }
    }

    final double sideIndicatorActivationThreshold =
        maxScroll - (widget.gridWidth * 0.8);
    if (maxScroll > 0 &&
        currentScroll > sideIndicatorActivationThreshold &&
        !_isLoadingMore &&
        _hasMorePages) {
      if (!_isScrollingToEnd) {
        setState(() {
          _isScrollingToEnd = true;
        });
      }
    } else if (currentScroll <= sideIndicatorActivationThreshold &&
        _isScrollingToEnd) {
      if (!_isLoadingMore) {
        setState(() {
          _isScrollingToEnd = false;
        });
      }
    }
  }

  void _scrollLeft() {
    final double scrollAmount = widget.gridWidth * 0.8;
    _scrollController.animateTo(
      (_scrollController.offset - scrollAmount)
          .clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    final double scrollAmount = widget.gridWidth * 0.8;
    final double currentOffset = _scrollController.offset;
    final double maxOffset = _scrollController.position.maxScrollExtent;

    final double targetOffset =
        (currentOffset + scrollAmount).clamp(0.0, maxOffset);

    final bool approachingEnd =
        maxOffset > 0 && targetOffset >= maxOffset - (widget.gridWidth * 0.3);

    if (approachingEnd && _hasMorePages && !_isLoadingMore) {
      if (kDebugMode) {
        print(
            'Approaching end while scrolling right. Loading more data from page $_nextPageToRequest');
      }

      setState(() {
        _isScrollingToEnd = true;
      });

      _loadMoreProducts().then((_) {
        if (mounted) {
          final newMaxOffset = _scrollController.position.maxScrollExtent;
          final adjustedTargetOffset =
              (currentOffset + scrollAmount).clamp(0.0, newMaxOffset);
          _scrollController.animateTo(
            adjustedTargetOffset,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    } else {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SizedBox(
      key: widget.productListKey,
      height: widget.gridHeight,
      width: widget.gridWidth,
      child: _errorMessage != null && _displayedProducts.isEmpty
          ? Center(
              child: Text(_errorMessage!,
                  style: const TextStyle(color: Colors.red)))
          : _displayedProducts.isEmpty && !_isLoading
              ? const Center(child: Text('Không có sản phẩm khuyến mãi'))
              : Stack(
                  children: [
                    Container(
                      color: Colors.white,
                      child: GridView.builder(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: widget.crossAxisCount,
                          childAspectRatio: widget.childAspectRatio,
                          mainAxisSpacing: widget.mainSpace,
                          crossAxisSpacing: widget.crossSpace,
                        ),
                        itemCount: _displayedProducts.length +
                            ((_hasMorePages || _isLoadingMore) ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _displayedProducts.length) {
                            return _buildLoadingItem();
                          }
                          return _displayedProducts[index];
                        },
                      ),
                    ),
                    Positioned(
                      left: 5,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_rounded,
                                color: Colors.blue),
                            onPressed: _scrollLeft,
                            iconSize: 20,
                            padding: const EdgeInsets.only(left: 8, right: 0),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 5,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios_rounded,
                                color: Colors.blue),
                            onPressed: _scrollRight,
                            iconSize: 20,
                            padding: const EdgeInsets.only(left: 0, right: 0),
                          ),
                        ),
                      ),
                    ),
                    if (_isLoading && _displayedProducts.isEmpty)
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Đang tải dữ liệu...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (_isScrollingToEnd && !_isLoading)
                      Positioned(
                        right: 50,
                        top: 0,
                        bottom: 0,
                        width: 40,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Đang tải',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildLoadingItem() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: widget.crossSpace / 2,
        vertical: widget.mainSpace / 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.blue.shade400,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Đang tải thêm...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
