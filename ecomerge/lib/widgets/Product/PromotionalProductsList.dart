import 'package:e_commerce_app/constants.dart';
import 'package:e_commerce_app/database/PageResponse.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/database/models/paginated_response.dart';
import 'package:e_commerce_app/database/models/product_dto.dart';
import 'package:e_commerce_app/database/services/product_service.dart';
import 'package:e_commerce_app/Screens/ProductDetail/PageProductDetail.dart';
import 'package:flutter/foundation.dart';
import 'package:e_commerce_app/services/shared_preferences_service.dart';
import 'dart:io'; // Import SocketException
import 'package:connectivity_plus/connectivity_plus.dart'; // Added for connectivity check

// In-memory cache for image data
class ImageCache {
  static final Map<String, Uint8List> _cache = {};

  static Uint8List? get(String url) {
    return _cache[url];
  }

  static void set(String url, Uint8List data) {
    _cache[url] = data;
  }

  static bool has(String url) {
    return _cache.containsKey(url);
  }

  static void remove(String url) {
    _cache.remove(url);
  }

  static void clear() {
    _cache.clear();
  }
}

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
  Future<dynamic> _imageLoader = Future.value(null);
  bool _imageInitiallyLoadedFromCache =
      false; // Renamed from _imageLoadedFromPrefs
  SharedPreferencesService? _prefsService; // Added for SharedPreferences

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      SharedPreferencesService.getInstance().then((instance) {
        if (mounted) {
          _prefsService = instance;
          _initializeAndLoadImage();
        }
      }).catchError((e) {
        if (kDebugMode) {
          print(
              "PromoProductItem: Error initializing SharedPreferencesService: $e");
        }
        _initializeAndLoadImage(); // Proceed even if prefs init fails
      });
    } else {
      _initializeAndLoadImage();
    }
  }

  @override
  void didUpdateWidget(PromoProductItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageInitiallyLoadedFromCache = false; // Reset flag
      _imageLoader = Future.value(null); // Reset loader
      if (!kIsWeb && _prefsService == null) {
        SharedPreferencesService.getInstance().then((instance) {
          if (mounted) {
            _prefsService = instance;
            _initializeAndLoadImage();
          }
        }).catchError((e) {
          if (kDebugMode) {
            print(
                "PromoProductItem: Error re-initializing SharedPreferencesService: $e");
          }
          _initializeAndLoadImage();
        });
      } else {
        _initializeAndLoadImage();
      }
    }
  }

  Future<void> _initializeAndLoadImage() async {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      if (mounted) {
        setState(() {
          _imageLoader = Future.value(null);
          _imageInitiallyLoadedFromCache = false;
        });
      }
      return;
    }

    // 1. Check in-memory cache
    final cachedImageData = ImageCache.get(widget.imageUrl!);
    if (cachedImageData != null) {
      if (mounted) {
        setState(() {
          _imageLoader = Future.value(cachedImageData);
          _imageInitiallyLoadedFromCache = true;
        });
      }
      return;
    }

    // Not in memory cache, proceed with network/prefs logic
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;

    if (isOnline) {
      if (mounted) {
        setState(() {
          _imageLoader = _productService.getImageFromServer(widget.imageUrl);
          _imageInitiallyLoadedFromCache = false; // Will be loaded from server
        });
      }
    } else {
      // Offline
      if (!kIsWeb && _prefsService != null) {
        Uint8List? imageDataFromPrefs;
        try {
          imageDataFromPrefs = _prefsService!.getImageData(widget.imageUrl!);
        } catch (e) {
          if (kDebugMode) {
            print(
                "Error accessing SharedPreferences for image '${widget.imageUrl}': $e");
          }
        }

        if (mounted) {
          if (imageDataFromPrefs != null) {
            ImageCache.set(
                widget.imageUrl!, imageDataFromPrefs); // Cache in memory
            setState(() {
              _imageLoader = Future.value(imageDataFromPrefs);
              _imageInitiallyLoadedFromCache = true;
            });
          } else {
            setState(() {
              _imageLoader = Future.value(null);
              _imageInitiallyLoadedFromCache = false;
            });
          }
        }
      } else {
        // Offline and (kIsWeb or _prefsService is null)
        if (mounted) {
          setState(() {
            _imageLoader = Future.value(null);
            _imageInitiallyLoadedFromCache = false;
          });
        }
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
        if (snapshot.connectionState == ConnectionState.waiting &&
            !_imageInitiallyLoadedFromCache) {
          // Use renamed flag
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          );
        }

        if (snapshot.hasError ||
            snapshot.data == null ||
            !(snapshot.data is Uint8List)) {
          if (snapshot.hasError && kDebugMode) {
            print(
                'Error in FutureBuilder for promo image (${widget.title}): ${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.data == null &&
              !snapshot.hasError) {
            if (kDebugMode) {
              print(
                  'Image loading for ${widget.title} returned null data (offline or fetch error).');
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

        // Ensure it's in the memory cache
        if (widget.imageUrl != null && !ImageCache.has(widget.imageUrl!)) {
          ImageCache.set(widget.imageUrl!, imageData);
        }

        if (!kIsWeb &&
            !_imageInitiallyLoadedFromCache && // Use renamed flag
            widget.imageUrl != null &&
            widget.imageUrl!.isNotEmpty &&
            _prefsService != null) {
          _prefsService!
              .saveImageData(widget.imageUrl!, imageData)
              .catchError((e) {
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
  late String _cacheKey;
  SharedPreferencesService? _prefsService;

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
    if (widget.productListKey is ValueKey<String>) {
      _cacheKey = (widget.productListKey as ValueKey<String>).value;
    } else {
      _cacheKey = widget.key?.toString() ?? 'default_promo_list';
      if (kDebugMode) {
        print(
            "Warning: PromotionalProductsList using fallback _cacheKey: $_cacheKey. Consider providing a unique ValueKey<String> as productListKey.");
      }
    }

    if (!kIsWeb) {
      SharedPreferencesService.getInstance().then((instance) {
        if (mounted) {
          setState(() {
            _prefsService = instance;
          });
          _loadInitialProducts();
        }
      }).catchError((error) {
        if (kDebugMode) {
          print("Failed to initialize SharedPreferencesService: $error");
        }
        _loadInitialProducts();
      });
    } else {
      _loadInitialProducts();
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
    try {
      debugPrint('Mapping ${products.length} ProductDTOs to UI items');

      return products.map((product) {
        try {
          double price = 0.0;
          if (product.variants != null &&
              product.variants!.isNotEmpty &&
              product.variants![0].price != null) {
            price = product.variants![0].price!;
          } else {
            price = product.minPrice ?? 0.0;
          }

          // Check for required product ID to prevent errors
          if (product.id == null) {
            debugPrint('Warning: Product has null ID: ${product.name}');
          }

          return PromoProductItem(
            key: ValueKey('${_cacheKey}_product_${product.id ?? "unknown"}'),
            productId: product.id ?? 0,
            imageUrl: product.mainImageUrl,
            title: product.name,
            describe: product.description,
            price: price,
            discount: product.discountPercentage?.toInt(),
            rating: product.averageRating ?? 0.0,
          );
        } catch (e) {
          debugPrint('Error creating PromoProductItem: $e');
          // Return a placeholder item instead of crashing
          return PromoProductItem(
            key: ValueKey(
                '${_cacheKey}_error_${DateTime.now().millisecondsSinceEpoch}'),
            productId: 0,
            imageUrl: null,
            title: "Error loading product",
            describe: "There was an error loading this product.",
            price: 0.0,
            discount: null,
            rating: 0.0,
          );
        }
      }).toList();
    } catch (e) {
      debugPrint('Error in _mapProductDTOsToItems: $e');
      return []; // Return empty list on error
    }
  }

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

  PromoProductItem _mapToPromoItem(Map<String, dynamic> map) {
    return PromoProductItem(
      key: ValueKey('${_cacheKey}_product_prefs_${map['productId']}'),
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
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;

    if (isOnline) {
      try {
        PageResponse<ProductDTO> response;
        if (_cacheKey == 'newProducts') {
          response = await _productService.fetchProducts(
            page: 0,
            size: widget.itemsPerPage,
            sortBy: 'createdDate',
            sortDir: 'desc',
          );
        } else if (_cacheKey == 'bestSeller') {
          response = await _productService.getTopSellingProducts(
            page: 0,
            size: widget.itemsPerPage,
          );
        } else {
          response = await _productService.getTopDiscountedProducts(
            page: 0,
            size: widget.itemsPerPage,
          );
        }

        final newItems = _mapProductDTOsToItems(response.content);
        if (mounted) {
          setState(() {
            _displayedProducts = newItems;
            _nextPageToRequest = response.last ? -1 : response.number + 1;
            _hasMorePages = !response.last;
            _isLoading = false;
            _errorMessage = null;
          });
        }

        if (!kIsWeb && _prefsService != null) {
          final List<Map<String, dynamic>> productsToSaveForPrefs =
              newItems.map((item) => _promoItemToMap(item)).toList();
          _prefsService!
              .saveProductListData(_cacheKey, productsToSaveForPrefs,
                  _nextPageToRequest, _hasMorePages)
              .catchError((e) {
            if (kDebugMode) {
              print(
                  "Error saving initial network data to SharedPreferences: $e");
            }
          });
        }
      } catch (e) {
        if (kDebugMode) print("Error loading initial products from server: $e");
        String displayError;
        if (e is SocketException) {
          displayError =
              'Không thể kết nối internet. Vui lòng kiểm tra mạng của bạn.';
        } else {
          displayError = 'Lỗi tải dữ liệu. Vui lòng thử lại.';
        }
        if (mounted) {
          setState(() {
            _errorMessage = displayError;
            _isLoading = false;
            _displayedProducts = [];
          });
        }
      }
    } else {
      if (!kIsWeb && _prefsService != null) {
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
              _errorMessage = 'Đang hiển thị dữ liệu ngoại tuyến.';
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _errorMessage =
                  'Bạn đang ngoại tuyến và không có dữ liệu nào được lưu trữ.';
              _isLoading = false;
              _displayedProducts = [];
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Không có kết nối mạng và không thể tải dữ liệu trên web.';
            _isLoading = false;
            _displayedProducts = [];
          });
        }
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    // Use a local variable instead of trying to modify the widget property
    final effectiveItemsPerPage = widget.itemsPerPage;

    if (!_hasMorePages || _isLoadingMore || _nextPageToRequest == -1) return;

    if (mounted) {
      setState(() {
        _isLoadingMore = true;
        if (_scrollController.position.pixels > 0) {
          _isScrollingToEnd = true;
        }
      });
    }

    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;

    if (isOnline) {
      try {
        PageResponse<ProductDTO> response;
        if (_cacheKey == 'newProducts') {
          response = await _productService.fetchProducts(
            page: _nextPageToRequest,
            size: effectiveItemsPerPage, // Use the local variable here
            sortBy: 'createdDate',
            sortDir: 'desc',
          );
        } else if (_cacheKey == 'bestSeller') {
          response = await _productService.getTopSellingProducts(
            page: _nextPageToRequest,
            size: effectiveItemsPerPage, // Use the local variable here
          );
        } else {
          response = await _productService.getTopDiscountedProducts(
            page: _nextPageToRequest,
            size: effectiveItemsPerPage, // Use the local variable here
          );
        }

        final additionalItems = _mapProductDTOsToItems(response.content);
        if (mounted) {
          setState(() {
            _displayedProducts.addAll(additionalItems);
            _nextPageToRequest = response.last ? -1 : response.number + 1;
            _hasMorePages = !response.last;
          });
        }

        if (!kIsWeb && _prefsService != null) {
          final List<Map<String, dynamic>> productsToSaveForPrefs =
              _displayedProducts.map((item) => _promoItemToMap(item)).toList();
          _prefsService!
              .saveProductListData(_cacheKey, productsToSaveForPrefs,
                  _nextPageToRequest, _hasMorePages)
              .catchError((e) {
            if (kDebugMode) {
              print("Error saving appended data to SharedPreferences: $e");
            }
          });
        }
      } catch (e) {
        if (kDebugMode) print("Error loading more products from server: $e");
        String snackBarMessage;
        if (e is SocketException) {
          snackBarMessage = 'Không thể tải thêm: Lỗi kết nối mạng.';
        } else {
          snackBarMessage = 'Lỗi tải thêm sản phẩm.';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(snackBarMessage),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
            _isButtonTriggeredLoading = false;
            _isScrollingToEnd = false;
          });
        }
      }
    } else {
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: const Text(
        //         'Bạn đang ngoại tuyến. Không thể tải thêm sản phẩm.'),
        //     backgroundColor: Colors.orange.shade700,
        //     duration: const Duration(seconds: 2),
        //   ),
        // );
        setState(() {
          _isLoadingMore = false;
          _isButtonTriggeredLoading = false;
          _isScrollingToEnd = false;
        });
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.position.hasContentDimensions) {
      return;
    }

    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double currentScroll = _scrollController.position.pixels;
    final double loadTriggerOffset = widget.gridWidth * 0.2;

    if (maxScroll > 0 && currentScroll >= (maxScroll - loadTriggerOffset)) {
      if (!_isLoadingMore && _hasMorePages) {
        if (_displayedProducts.isNotEmpty || _isLoading) {
          _loadMoreProducts();
        }
      }
    }

    final double startScrollThreshold = widget.gridWidth * 0.1;
    final double endScrollThreshold = maxScroll - (widget.gridWidth * 0.1);

    final double scrollToEndIndicatorThreshold =
        maxScroll - (widget.gridWidth * 0.05);

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

    final bool approachingEnd =
        maxOffset > 0 && targetOffset >= maxOffset - (widget.gridWidth * 0.3);

    if (approachingEnd && _hasMorePages && !_isLoadingMore) {
      if (mounted) {
        setState(() {
          _isButtonTriggeredLoading = true;
        });
      }

      _loadMoreProducts().then((_) {
        if (mounted) {
          final newMaxOffset = _scrollController.position.maxScrollExtent;
          final adjustedTargetOffset =
              (currentOffset + scrollAmount).clamp(0.0, newMaxOffset);
          _scrollController.animateTo(
            adjustedTargetOffset,
            duration: const Duration(milliseconds: 0),
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

    // Add debug logging
    debugPrint('PromotionalProductsList build method called');
    debugPrint('_displayedProducts length: ${_displayedProducts.length}');
    debugPrint('_isLoading: $_isLoading, _errorMessage: $_errorMessage');

    Widget content;

    if (_isLoading && _displayedProducts.isEmpty && _errorMessage == null) {
      content = Center(
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
      );
    } else if (_errorMessage != null && _displayedProducts.isEmpty) {
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
      content = const Center(
        child: Text(
          'Không có sản phẩm nào để hiển thị.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    } else {
      content = GridView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          childAspectRatio: widget.childAspectRatio,
          mainAxisSpacing: widget.mainSpace,
          crossAxisSpacing: widget.crossSpace,
        ),
        itemCount: _displayedProducts.length +
            ((_isLoadingMore && !_isButtonTriggeredLoading) ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _displayedProducts.length) {
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
          Container(color: Colors.white, child: content),
          if (_displayedProducts.isNotEmpty)
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
          if (_displayedProducts.isNotEmpty)
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
          if (_isLoadingMore && _isButtonTriggeredLoading)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
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
