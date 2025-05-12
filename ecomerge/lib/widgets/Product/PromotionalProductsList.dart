import 'package:e_commerce_app/database/PageResponse.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/database/models/paginated_response.dart';
import 'package:e_commerce_app/database/models/product_dto.dart';
import 'package:e_commerce_app/database/services/product_service.dart';
import 'package:e_commerce_app/Screens/ProductDetail/PageProductDetail.dart';
import 'package:flutter/foundation.dart';
import 'package:e_commerce_app/services/product_cache_service.dart';
import 'package:e_commerce_app/services/shared_preferences_service.dart';
import 'dart:io'; // Import SocketException

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
  // Khởi tạo ngay lập tức với Future.value(null) để tránh LateInitializationError
  Future<dynamic> _imageLoader = Future.value(null);
  bool _imageLoadedFromPrefs = false;

  @override
  void initState() {
    super.initState();
    // _imageLoader đã được khởi tạo. Gọi phương thức này để bắt đầu tải dữ liệu thực tế.
    _initializeAndLoadImage();
  }

  @override
  void didUpdateWidget(PromoProductItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      // Re-initialize image loader if URL changes
      _imageLoadedFromPrefs = false; // Reset flag
      // Gán lại _imageLoader về trạng thái ban đầu (null) ngay lập tức
      // trước khi bắt đầu tải ảnh mới.
      _imageLoader = Future.value(null);
      _initializeAndLoadImage(); // Bắt đầu tải ảnh mới
    }
  }

  Future<void> _initializeAndLoadImage() async {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      if (mounted) {
        setState(() {
          _imageLoader = Future.value(null); // Cập nhật trong setState
          _imageLoadedFromPrefs = false;
        });
      }
      return;
    }

    // For non-web platforms, try to load from SharedPreferences first.
    if (!kIsWeb) {
      Uint8List? imageDataFromPrefs;
      try {
        final prefs = await SharedPreferencesService.getInstance();
        imageDataFromPrefs = prefs.getImageData(widget.imageUrl!);
      } catch (e) {
        if (kDebugMode) {
          print(
              "Error accessing SharedPreferences for image '${widget.imageUrl}': $e");
        }
      }

      if (mounted) {
        if (imageDataFromPrefs != null) {
          // Image found in SharedPreferences
          setState(() {
            _imageLoader =
                Future.value(imageDataFromPrefs); // Cập nhật trong setState
            _imageLoadedFromPrefs = true;
          });
          return; // Exit after loading from SharedPreferences
        } else {
          // Image not in SharedPreferences or error during access, so load from server.
          setState(() {
            _imageLoader = _productService
                .getImageFromServer(widget.imageUrl); // Cập nhật trong setState
            _imageLoadedFromPrefs = false;
          });
        }
      }
    } else {
      // For web platforms, load directly from the server.
      if (mounted) {
        setState(() {
          _imageLoader = _productService
              .getImageFromServer(widget.imageUrl); // Cập nhật trong setState
          _imageLoadedFromPrefs = false;
        });
      }
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
    return '$formatted đ';
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

    return FutureBuilder<dynamic>(
      future: _imageLoader,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          );
        }

        // Handle error or null data that is not Uint8List
        if (snapshot.hasError ||
            snapshot.data == null ||
            !(snapshot.data is Uint8List)) {
          if (snapshot.hasError && kDebugMode) {
            print(
                'Error in FutureBuilder for promo image (${widget.title}): ${snapshot.error}');
          }
          // Also handle the case where _productService.getImageFromServer returned null data on error
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.data == null &&
              !snapshot.hasError) {
            if (kDebugMode) {
              print('Image loading for ${widget.title} returned null data.');
            }
          }
          return const Center(
            child: Icon(
              Icons.image_not_supported,
              size: 50,
              color: Colors.grey,
            ),
          );
        }

        final imageData = snapshot.data as Uint8List;

        // Save image to SharedPreferences if successfully loaded from network (not prefs initially)
        if (!kIsWeb &&
            !_imageLoadedFromPrefs &&
            widget.imageUrl != null &&
            widget.imageUrl!.isNotEmpty) {
          // Do not await here to avoid blocking the build method
          SharedPreferencesService.getInstance().then((prefs) {
            prefs.saveImageData(widget.imageUrl!, imageData);
          }).catchError((e) {
            if (kDebugMode) {
              print(
                  "Error saving image to SharedPreferences from _buildProductImage for ${widget.title}: $e");
            }
          });
        }

        return Image.memory(
          imageData,
          fit: BoxFit.cover,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
  final ProductCacheService _cacheService = ProductCacheService();
  late String _cacheKey;
  SharedPreferencesService? _prefsService; // Added for SharedPreferences

  List<PromoProductItem> _displayedProducts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _nextPageToRequest = 0;
  bool _hasMorePages = true;
  bool _isScrollingToEnd = false;
  bool _isButtonTriggeredLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cacheKey = _cacheService
        .getKeyFromProductListKey(widget.productListKey ?? widget.key);

    if (!kIsWeb) {
      SharedPreferencesService.getInstance().then((instance) {
        if (mounted) {
          setState(() {
            _prefsService = instance;
          });
          _loadInitialProducts(); // Load products after prefs service is available
        }
      }).catchError((error) {
        if (kDebugMode) {
          print("Failed to initialize SharedPreferencesService: $error");
        }
        // Continue loading products even if prefs init fails
        _loadInitialProducts();
      });
    } else {
      _loadInitialProducts(); // For web, load products directly
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  List<PromoProductItem> _mapProductDTOsToItems(List<ProductDTO> products) {
    return products.map((product) {
      double price = 0.0;
      if (product.variants != null &&
          product.variants!.isNotEmpty &&
          product.variants![0].price != null) {
        price = product.variants![0].price!;
      } else {
        price = product.minPrice ?? 0.0;
      }

      return PromoProductItem(
        key: ValueKey('${_cacheKey}_product_${product.id}'),
        productId: product.id ?? 0,
        imageUrl: product.mainImageUrl,
        title: product.name,
        describe: product.description,
        price: price, // Use the determined price
        discount: product.discountPercentage?.toInt(),
        rating: product.averageRating ?? 0.0,
      );
    }).toList();
  }

  // Helper to convert PromoProductItem data to Map for SharedPreferences
  Map<String, dynamic> _promoItemToMap(PromoProductItem item) {
    return {
      'productId': item.productId,
      'imageUrl': item.imageUrl,
      'title': item.title,
      'describe': item.describe,
      'price': item.price,
      'discount': item.discount,
      'rating': item.rating,
    };
  }

  // Helper to convert Map from SharedPreferences back to PromoProductItem
  PromoProductItem _mapToPromoItem(Map<String, dynamic> map) {
    return PromoProductItem(
      key: ValueKey(
          '${_cacheKey}_product_prefs_${map['productId']}'), // Unique key for prefs items
      productId: map['productId'] as int,
      imageUrl: map['imageUrl'] as String?,
      title: map['title'] as String,
      describe: map['describe'] as String?,
      price: (map['price'] as num).toDouble(),
      discount: map['discount'] as int?,
      rating: (map['rating'] as num).toDouble(),
    );
  }

  Future<void> _loadInitialProducts() async {
    // Try loading from in-memory cache first
    final cachedData = _cacheService.getData(_cacheKey);

    if (cachedData != null) {
      if (mounted) {
        setState(() {
          _displayedProducts = List.from(cachedData.products);
          _nextPageToRequest = cachedData.nextPageToRequest;
          _hasMorePages = cachedData.hasMorePages;
          _isLoading = false;
          _errorMessage = null; // Clear error if cache load is successful
        });
      }
      // Save to SharedPreferences if non-web and data loaded from memory cache
      if (!kIsWeb && _prefsService != null) {
        final List<Map<String, dynamic>> productsToSaveForPrefs =
            cachedData.products.map((item) => _promoItemToMap(item)).toList();
        // Note: This is fire-and-forget, not awaited, as it's a background save
        _prefsService!
            .saveProductListData(_cacheKey, productsToSaveForPrefs,
                cachedData.nextPageToRequest, cachedData.hasMorePages)
            .catchError((e) {
          if (kDebugMode) {
            print("Error saving initial cache data to SharedPreferences: $e");
          }
        });
      }
      return; // Exit if data loaded from cache
    }

    // If no data in memory cache, show loading and attempt to fetch from network or prefs
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _nextPageToRequest = 0;
        _displayedProducts =
            []; // Clear displayed products before attempting load
      });
    }

    try {
      PageResponse<ProductDTO> response;

      if (_cacheKey == 'newProducts') {
        response = await _productService.fetchProducts(
          page: _nextPageToRequest,
          size: widget.itemsPerPage,
          sortBy: 'createdDate',
          sortDir: 'desc',
        );
      } else if (_cacheKey == 'bestSeller') {
        response = await _productService.getTopSellingProducts(
          page: _nextPageToRequest,
          size: widget.itemsPerPage,
        );
      } else {
        response = await _productService.getTopDiscountedProducts(
          page: _nextPageToRequest,
          size: widget.itemsPerPage,
        );
      }

      final newItems = _mapProductDTOsToItems(response.content);
      _cacheService.storeData(
          _cacheKey, newItems, response.number + 1, !response.last);

      final freshCacheData = _cacheService.getData(_cacheKey);
      if (freshCacheData != null) {
        if (mounted) {
          setState(() {
            _displayedProducts = List.from(freshCacheData.products);
            _nextPageToRequest = freshCacheData.nextPageToRequest;
            _hasMorePages = freshCacheData.hasMorePages;
            _isLoading = false;
            _errorMessage = null; // Clear error if network load was successful
          });
        }
        // Save to SharedPreferences if non-web (network load was successful)
        if (!kIsWeb && _prefsService != null) {
          final List<Map<String, dynamic>> productsToSaveForPrefs =
              freshCacheData.products
                  .map((item) => _promoItemToMap(item))
                  .toList();
          // Fire-and-forget save
          _prefsService!
              .saveProductListData(_cacheKey, productsToSaveForPrefs,
                  freshCacheData.nextPageToRequest, freshCacheData.hasMorePages)
              .catchError((e) {
            if (kDebugMode) {
              print("Error saving network data to SharedPreferences: $e");
            }
          });
        }
      } else {
        // Should ideally not happen if storeData was successful, but handle defensively
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = "Failed to update cache after network fetch.";
            _displayedProducts =
                []; // Ensure list is empty if cache update failed
          });
        }
      }
    } catch (e) {
      // Network or other error occurred
      if (!kIsWeb && _prefsService != null) {
        // Try loading from SharedPreferences as a fallback
        final prefsData = _prefsService!.getProductListData(_cacheKey);
        if (prefsData != null) {
          final List<dynamic> productMaps =
              prefsData['products'] as List<dynamic>;
          final List<PromoProductItem> prefsProducts = productMaps
              .map((map) => _mapToPromoItem(map as Map<String, dynamic>))
              .toList();
          if (mounted) {
            setState(() {
              _displayedProducts = prefsProducts;
              _nextPageToRequest = prefsData['nextPageToRequest'] as int;
              _hasMorePages = prefsData['hasMorePages'] as bool;
              _isLoading = false;
              // Indicate that it's showing offline data due to a network error
              _errorMessage = 'Có lỗi mạng. Đang hiển thị dữ liệu ngoại tuyến.';
            });
          }
          return; // Exit if loaded from prefs fallback
        }
      }

      // If not loaded from prefs fallback or not applicable
      String displayError;
      if (e is SocketException) {
        // Specific message for network connection issues
        displayError =
            'Không thể kết nối internet. Vui lòng kiểm tra mạng của bạn.';
      } else {
        // Generic error message for other issues
        displayError = 'Không thể tải sản phẩm';
        if (kDebugMode) {
          print("Error loading products: $e"); // Log other errors in debug
        }
      }

      if (mounted) {
        setState(() {
          _errorMessage = displayError;
          _isLoading = false;
          _displayedProducts = []; // Ensure list is empty if no data was loaded
        });
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    if (!_hasMorePages || _isLoadingMore) return;

    if (mounted) {
      setState(() {
        _isLoadingMore = true;
        if (_scrollController.position.pixels > 0) {
          _isScrollingToEnd = true;
        }
      });
    }

    try {
      final int itemsToFetch = widget.itemsPerPage;
      PageResponse<ProductDTO> response;

      if (_cacheKey == 'newProducts') {
        response = await _productService.fetchProducts(
          page: _nextPageToRequest,
          size: itemsToFetch,
          sortBy: 'createdDate',
          sortDir: 'desc',
        );
      } else if (_cacheKey == 'bestSeller') {
        response = await _productService.getTopSellingProducts(
          page: _nextPageToRequest,
          size: widget.itemsPerPage,
        );
      } else {
        response = await _productService.getTopDiscountedProducts(
          page: _nextPageToRequest,
          size: widget.itemsPerPage,
        );
      }

      // Append new items to cache
      final additionalItems = _mapProductDTOsToItems(response.content);
      // Only update cache and state if new items were received or it's the last page
      if (additionalItems.isNotEmpty || response.last) {
        _cacheService.appendData(
            _cacheKey, additionalItems, response.number + 1, !response.last);

        final updatedCacheData = _cacheService.getData(_cacheKey);
        if (updatedCacheData != null) {
          if (mounted) {
            setState(() {
              _displayedProducts = List.from(updatedCacheData.products);
              _nextPageToRequest = updatedCacheData.nextPageToRequest;
              _hasMorePages = updatedCacheData.hasMorePages;
              // Error message is primarily for initial load when list is empty,
              // so don't clear it here unless it was a network error previously
              // cleared by a successful load more. But usually, loading more
              // means initial load was successful.
            });
          }
          // Save the complete updated list to SharedPreferences if non-web
          if (!kIsWeb && _prefsService != null) {
            final List<Map<String, dynamic>> productsToSaveForPrefs =
                updatedCacheData.products
                    .map((item) => _promoItemToMap(item))
                    .toList();
            // Fire-and-forget save
            _prefsService!
                .saveProductListData(
                    _cacheKey,
                    productsToSaveForPrefs,
                    updatedCacheData.nextPageToRequest,
                    updatedCacheData.hasMorePages)
                .catchError((e) {
              if (kDebugMode) {
                print("Error saving append data to SharedPreferences: $e");
              }
            });
          }
        }
      }
    } catch (e) {
      // Error when loading more (e.g., network error while scrolling)
      String snackBarMessage;
      if (e is SocketException) {
        snackBarMessage =
            'Không thể tải thêm sản phẩm: Chưa có kết nối internet.';
      } else {
        snackBarMessage = 'Không thể tải thêm sản phẩm}';
        if (kDebugMode) {
          print("Error loading more products: $e"); // Log other errors in debug
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(snackBarMessage),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      // Ensure loading flags are reset regardless of success or failure
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _isButtonTriggeredLoading = false;
          _isScrollingToEnd = false; // Ensure this is reset
        });
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.position.hasContentDimensions) {
      return; // Avoid errors if scroll controller is not fully initialized
    }

    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double currentScroll = _scrollController.position.pixels;
    final double loadTriggerOffset =
        widget.gridWidth * 0.2; // Load when within 20% of the end

    // Trigger load more if approaching the end and not already loading/no more pages
    if (maxScroll > 0 && currentScroll >= (maxScroll - loadTriggerOffset)) {
      if (!_isLoadingMore && _hasMorePages) {
        // Avoid triggering if the error message is displayed (meaning no items)
        if (_displayedProducts.isNotEmpty || _isLoading) {
          // Only load if we have items or are initially loading
          _loadMoreProducts();
        }
      }
    }

    // Logic for showing/hiding side indicators based on scroll position
    // This part doesn't directly relate to the network error display logic,
    // but keeping it for completeness.
    final double startScrollThreshold =
        widget.gridWidth * 0.1; // Show left arrow after scrolling a bit
    final double endScrollThreshold = maxScroll -
        (widget.gridWidth * 0.1); // Show right arrow until near the end

    // Determine if scrollingToEnd indicator should be shown (adjust threshold)
    // Let's make the scrollToEnd indicator appear when approaching the very end
    // to hint that loading more is happening or possible.
    final double scrollToEndIndicatorThreshold =
        maxScroll - (widget.gridWidth * 0.05); // Show within 5% of end

    if (maxScroll > 0 &&
        currentScroll > scrollToEndIndicatorThreshold &&
        !_isLoadingMore &&
        _hasMorePages) {
      if (!_isScrollingToEnd) {
        setState(() {
          _isScrollingToEnd = true;
        });
      }
    } else if (currentScroll <= scrollToEndIndicatorThreshold &&
        _isScrollingToEnd) {
      // Only hide the indicator if we are *not* currently loading more
      if (!_isLoadingMore && !_isButtonTriggeredLoading) {
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

    // Check if approaching the end and more pages exist
    final bool approachingEnd = maxOffset > 0 &&
        targetOffset >=
            maxOffset -
                (widget.gridWidth *
                    0.3); // Use a threshold to trigger loading slightly before the end

    if (approachingEnd && _hasMorePages && !_isLoadingMore) {
      if (mounted) {
        setState(() {
          _isButtonTriggeredLoading =
              true; // Indicate loading was triggered by button
        });
      }

      // Trigger loading more and then scroll after loading completes
      _loadMoreProducts().then((_) {
        if (mounted) {
          // Recalculate maxOffset as it might have changed after loading more
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
      // Just scroll if not approaching the end or no more pages
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

    // Decide what to show based on state (_isLoading, _errorMessage, _displayedProducts)
    Widget content;

    if (_isLoading && _displayedProducts.isEmpty && _errorMessage == null) {
      // Show initial loading indicator if no data and no error yet
      content = Positioned.fill(
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
      );
    } else if (_errorMessage != null && _displayedProducts.isEmpty) {
      // Show error message if list is empty and there's an error
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    } else if (_displayedProducts.isEmpty && !_isLoading) {
      // Show empty state message if list is empty and not loading
      content = const Center(
        child: Text(
          'Không có sản phẩm khuyến mãi',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    } else {
      // Show the GridView with products
      content = GridView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          childAspectRatio: widget.childAspectRatio,
          mainAxisSpacing: widget.mainSpace,
          crossAxisSpacing: widget.crossSpace,
        ),
        // Add 1 item for indicator loading ifกำลังโหลด thêm and not triggered by button
        itemCount: _displayedProducts.length +
            ((_isLoadingMore && !_isButtonTriggeredLoading)
                ? 1 // Show loading item at the end
                : 0),
        itemBuilder: (context, index) {
          if (index >= _displayedProducts.length) {
            // This is the loading item placeholder
            return _buildLoadingItem();
          }
          return _displayedProducts[index];
        },
      );
    }

    return SizedBox(
      key: widget.productListKey,
      height: widget.gridHeight,
      width: widget.gridWidth,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
              color: Colors.white,
              child: content), // Display determined content
          // Side navigation buttons only shown when there are items to scroll
          if (_displayedProducts.isNotEmpty) ...[
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
          ],

          // Overlay loading indicator when triggered by button
          if (_isLoadingMore && _isButtonTriggeredLoading)
            LayoutBuilder(
              builder: (context, constraints) {
                // Adjusted size calculation slightly
                double spinnerSize =
                    (constraints.maxWidth < constraints.maxHeight
                            ? constraints.maxWidth
                            : constraints.maxHeight) *
                        0.1;
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
                          width: spinnerSize,
                          height: spinnerSize,
                          child: CircularProgressIndicator(
                            strokeWidth: 4.0,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
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

  // Helper widget for the loading indicator item in GridView (when scrolling automatically)
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
