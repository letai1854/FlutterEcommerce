import 'package:e_commerce_app/database/PageResponse.dart';
import 'package:e_commerce_app/widgets/Product/ProductItem.dart';
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

  String _formatPrice(double price) {
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
    return '$formatted VNĐ';
  }

  Widget _buildProductImage() {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      return const Center(
        child: Icon(
          Icons.image_not_supported,
          size: 50,
          color: Colors.grey,
        ),
      );
    }

    return FutureBuilder(
      future: _imageLoader,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          );
        }

        if (snapshot.hasError) {
          if (kDebugMode) {
            print('Error loading promo image: ${snapshot.error}');
          }
          return const Center(
            child: Icon(
              Icons.broken_image,
              size: 50,
              color: Colors.grey,
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          if (snapshot.data is Uint8List) {
            return Image.memory(
              snapshot.data as Uint8List,
              fit: BoxFit.cover,
            );
          }
        }
        return Image.network(
          _productService.getImageUrl(widget.imageUrl),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            if (kDebugMode) {
              print('Error loading promo image network: $error');
            }
            return const Center(
              child: Icon(
                Icons.image_not_supported,
                size: 50,
                color: Colors.grey,
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
              ),
            );
          },
        );
      },
    );
  }

  String _formatDescription(String? description) {
    if (description == null || description.isEmpty) {
      return '';
    }
    List<String> words = description.split(' ');
    if (words.length > 6) {
      return '${words.sublist(0, 6).join(' ')}...';
    }
    return description;
  }

  @override
  Widget build(BuildContext context) {
    final discountedPrice = widget.discount != null && widget.discount! > 0
        ? widget.price - (widget.price * widget.discount! / 100)
        : widget.price;

    final String displayDescription = _formatDescription(widget.describe);

    return Hero(
      tag: 'promo_product_${widget.productId}',
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          onTap: _navigateToProductDetail,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8)),
                          child: _buildProductImage(),
                        ),
                      ),
                      if (widget.discount != null && widget.discount! > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '-${widget.discount}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (displayDescription.isNotEmpty)
                      Text(
                        displayDescription,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(
                          widget.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (widget.discount != null && widget.discount! > 0) ...[
                      Text(
                        _formatPrice(widget.price),
                        style: TextStyle(
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      _formatPrice(discountedPrice),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
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

  List<ProductItem> _displayedProducts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _nextPageToRequest = 0;
  bool _hasMorePages = true;
  int _totalPagesFromAPI = 0;
  bool _isScrollingToEnd = false;
  bool _isButtonTriggeredLoading = false;

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
      PageResponse<ProductDTO> response;
      final String keyString = widget.productListKey.toString();

      if (keyString.contains('newProducts')) {
        if (kDebugMode) {
          print(
              'PromotionalProductsList (Newest): Fetching newest products page $_nextPageToRequest, size ${widget.itemsPerPage}');
        }
        response = await _productService.fetchProducts(
          page: _nextPageToRequest,
          size: widget.itemsPerPage,
          sortBy: 'createdDate',
          sortDir: 'desc',
        );
      } else if (keyString.contains('bestSeller')) {
        if (kDebugMode) {
          print(
              'PromotionalProductsList (Top Selling): Fetching top selling products page $_nextPageToRequest, size ${widget.itemsPerPage}');
        }
        response = await _productService.getTopSellingProducts(
          page: _nextPageToRequest,
          size: widget.itemsPerPage,
        );
      } else {
        if (kDebugMode) {
          print(
              'PromotionalProductsList (Top Selling): Fetching top selling products page $_nextPageToRequest, size ${widget.itemsPerPage}');
        }
        response = await _productService.getTopDiscountedProducts(
          page: _nextPageToRequest,
          size: widget.itemsPerPage,
        );
      }

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
        print('Error loading initial products: $e');
      }
      setState(() {
        _errorMessage = 'Không thể tải sản phẩm: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _createProductItems(List<ProductDTO> products) {
    final items = products
        .map((product) => ProductItem(
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
      _displayedProducts = items;
    });
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
      PageResponse<ProductDTO> response;
      final String keyString = widget.productListKey.toString();

      if (keyString.contains('newProducts')) {
        if (kDebugMode) {
          print(
              'PromotionalProductsList (Newest): Loading more newest products page $_nextPageToRequest with $itemsToFetch items per page');
        }
        response = await _productService.fetchProducts(
          page: _nextPageToRequest,
          size: itemsToFetch,
          sortBy: 'createdDate',
          sortDir: 'desc',
        );
      } else if (keyString.contains('bestSeller')) {
        if (kDebugMode) {
          print(
              'PromotionalProductsList (Top Selling): Fetching top selling products page $_nextPageToRequest, size ${widget.itemsPerPage}');
        }
        response = await _productService.getTopSellingProducts(
          page: _nextPageToRequest,
          size: widget.itemsPerPage,
        );
      } else {
        if (kDebugMode) {
          print(
              'PromotionalProductsList (Top Selling): Loading more top selling products page $_nextPageToRequest with $itemsToFetch items per page');
        }
        response = await _productService.getTopDiscountedProducts(
          page: _nextPageToRequest,
          size: widget.itemsPerPage,
        );
      }

      if (kDebugMode) {
        print(
            'Loaded more products page ${response.number}. Total items: ${response.content.length}, Is Last: ${response.last}, Total Pages: ${response.totalPages}');
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
          .map((product) => ProductItem(
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
            content: Text('Không thể tải thêm sản phẩm: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted && _isButtonTriggeredLoading) {
        setState(() {
          _isButtonTriggeredLoading = false;
        });
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
        _isButtonTriggeredLoading = true;
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
                  alignment: Alignment.center,
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
                            ((_isLoadingMore && !_isButtonTriggeredLoading)
                                ? 1
                                : 0),
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
                    if (_isLoadingMore && _isButtonTriggeredLoading)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          double spinnerSize = constraints.maxWidth * 0.1;
                          if (spinnerSize < 40) spinnerSize = 40;
                          if (spinnerSize > 60) spinnerSize = 60;

                          return Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 20),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 1),
                                  )
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: constraints.maxWidth <= 600
                                        ? constraints.maxWidth * 0.1
                                        : 48,
                                    height: constraints.maxWidth <= 600
                                        ? constraints.maxWidth * 0.1
                                        : 48,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 4.0,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    'Đang tải sản phẩm...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
