import 'package:e_commerce_app/database/PageResponse.dart';
import 'package:e_commerce_app/database/models/product_dto.dart';
import 'package:e_commerce_app/database/services/product_service.dart';
import 'package:e_commerce_app/services/shared_preferences_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/services/product_cache_service.dart';
import 'dart:io'; // For SocketException
import 'package:connectivity_plus/connectivity_plus.dart'; // For connectivity checks
import 'dart:typed_data'; // For Uint8List
import 'package:e_commerce_app/Screens/ProductDetail/PageProductDetail.dart'; // For navigation

class CategoryFilteredProductGrid extends StatefulWidget {
  final int? categoryId;
  final double gridWidth;
  final int itemsToLoadPerPage; // Number of items to fetch per APt call
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
  SharedPreferencesService? _prefsService; // For offline mode only
  late String _cacheKey;

  final Map<String?, bool> _loadedImages = {}; // Track loaded images

  List<ProductDTO> _products = [];
  int _currentPage = 0;
  bool _isLoadingFirstLoad = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  ScrollPosition? _scrollPosition;

  @override
  void initState() {
    super.initState();
    _cacheKey = 'category_${widget.categoryId}';

    if (!kIsWeb) {
      SharedPreferencesService.getInstance().then((instance) {
        if (mounted) {
          setState(() {
            _prefsService = instance;
          });
          _fetchProducts(page: 0, isInitialLoad: true);
        }
      }).catchError((e) {
        if (kDebugMode) {
          print(
              "CategoryFilteredProductGrid: Error initializing SharedPreferencesService: $e");
        }
        _fetchProducts(page: 0, isInitialLoad: true);
      });
    } else {
      _fetchProducts(page: 0, isInitialLoad: true);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupScrollListener();
    });
  }

  void _setupScrollListener() {
    _scrollPosition = Scrollable.of(context)?.position;
    _scrollPosition?.addListener(_onScroll);
    if (_scrollPosition?.hasContentDimensions == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
    }
  }

  void _onScroll() {
    if (_scrollPosition != null && _scrollPosition!.hasPixels) {
      final currentScroll = _scrollPosition!.pixels;
      final maxScroll = _scrollPosition!.maxScrollExtent;
      if (maxScroll > 0 &&
          currentScroll >= maxScroll - 150 &&
          !_isLoadingMore &&
          _hasMore &&
          _error == null) {
        _fetchProducts(page: _currentPage + 1, isInitialLoad: false);
      }
    }
  }

  @override
  void didUpdateWidget(CategoryFilteredProductGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categoryId != oldWidget.categoryId) {
      _cacheKey = 'category_${widget.categoryId}';
      _loadedImages.clear();
      _resetAndFetchProducts();
    }
  }

  void _resetAndFetchProducts() {
    setState(() {
      _products = [];
      _currentPage = 0;
      _hasMore = true;
      _error = null;
      _isLoadingFirstLoad = true;
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

      bool isDeviceOnline = true;
      if (!kIsWeb) {
        try {
          final connectivityResult = await Connectivity().checkConnectivity();
          isDeviceOnline = connectivityResult != ConnectivityResult.none;
        } catch (e) {
          if (kDebugMode) {
            print(
                "CategoryFilteredProductGrid: Error checking connectivity: $e");
          }
        }
      }

      if (!kIsWeb && !isDeviceOnline && _prefsService != null) {
        try {
          final prefsCategoryData =
              await _prefsService!.loadCategoryProductData(_cacheKey);
          if (prefsCategoryData != null && mounted) {
            setState(() {
              _products = List.from(prefsCategoryData.products);
              _currentPage = prefsCategoryData.currentPage;
              _hasMore = prefsCategoryData.hasMore;
              _isLoadingFirstLoad = false;
              _error = "Đang hiển thị dữ liệu ngoại tuyến.";
            });
            return;
          } else if (mounted) {
            setState(() {
              _isLoadingFirstLoad = false;
              _error = "Không có kết nối mạng và không có dữ liệu ngoại tuyến.";
              _products = [];
              _hasMore = true;
            });
            return;
          }
        } catch (e) {
          if (kDebugMode) {
            print(
                "CategoryFilteredProductGrid: Error loading from SharedPreferences (offline initial): $e");
          }
          if (mounted) {
            setState(() {
              _isLoadingFirstLoad = false;
              _error = "Lỗi tải dữ liệu ngoại tuyến. Không có kết nối mạng.";
              _products = [];
              _hasMore = true;
            });
            return;
          }
        }
      }
    } else {
      if (_isLoadingMore || !_hasMore) return;
      setState(() {
        _isLoadingMore = true;
        _error = null;
      });

      bool isDeviceOnline = true;
      if (!kIsWeb) {
        try {
          final connectivityResult = await Connectivity().checkConnectivity();
          isDeviceOnline = connectivityResult != ConnectivityResult.none;
        } catch (e) {
          if (kDebugMode) {
            print(
                "CategoryFilteredProductGrid: Error checking connectivity for load more: $e");
          }
        }
      }

      if (!kIsWeb && !isDeviceOnline) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Không có kết nối mạng để tải thêm sản phẩm."),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() {
            _isLoadingMore = false;
          });
        }
        return;
      }
    }

    try {
      PageResponse<ProductDTO> response;

      if (!isInitialLoad) {
        final results = await Future.wait([
          _productService.fetchProducts(
            categoryId: widget.categoryId,
            page: page,
            size: widget.itemsToLoadPerPage,
            sortBy: 'createdDate',
            sortDir: 'desc',
          ),
          Future.delayed(const Duration(milliseconds: 800))
        ]);
        response = results[0] as PageResponse<ProductDTO>;
      } else {
        const minSpinnerDuration = Duration(milliseconds: 300);
        final results = await Future.wait([
          _productService.fetchProducts(
            categoryId: widget.categoryId,
            page: page,
            size: widget.itemsToLoadPerPage,
            sortBy: 'createdDate',
            sortDir: 'desc',
          ),
          Future.delayed(minSpinnerDuration),
        ]);
        response = results[0] as PageResponse<ProductDTO>;
      }

      if (mounted) {
        final newProducts = response.content;
        setState(() {
          if (page == 0) {
            _products = newProducts;
          } else {
            _products.addAll(newProducts);
          }
          _currentPage = response.number;
          _hasMore = !response.last;
          _error = null;
        });

        bool canSaveToPrefs = false;
        if (!kIsWeb && _prefsService != null) {
          try {
            final connectivityResult = await Connectivity().checkConnectivity();
            canSaveToPrefs = connectivityResult != ConnectivityResult.none;
          } catch (e) {
            if (kDebugMode)
              print(
                  "CategoryFilteredProductGrid: Connectivity check before save failed: $e");
          }
        }

        if (canSaveToPrefs) {
          final currentDataToSave = CachedCategoryProductData(
            products: List.from(_products),
            currentPage: _currentPage,
            hasMore: _hasMore,
            lastFetched: DateTime.now(),
          );
          try {
            await _prefsService!
                .saveCategoryProductData(_cacheKey, currentDataToSave);
            if (kDebugMode) {
              print(
                  "CategoryFilteredProductGrid: Saved offline backup to SharedPreferences for $_cacheKey.");
            }
          } catch (e) {
            if (kDebugMode) {
              print(
                  "CategoryFilteredProductGrid: Error saving products to SharedPreferences: $e");
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage =
            "Không thể kết nối internet. Vui lòng kiểm tra mạng của bạn.";
        bool loadedFromPrefsFallback = false;

        if (!kIsWeb &&
            _prefsService != null &&
            (e is SocketException ||
                e.toString().toLowerCase().contains("socketexception"))) {
          try {
            final prefsCategoryData =
                await _prefsService!.loadCategoryProductData(_cacheKey);
            if (prefsCategoryData != null &&
                prefsCategoryData.products.isNotEmpty) {
              setState(() {
                _products = List.from(prefsCategoryData.products);
                _currentPage = prefsCategoryData.currentPage;
                _hasMore = prefsCategoryData.hasMore;
                errorMessage = "Lỗi mạng. Đang hiển thị dữ liệu ngoại tuyến.";
                loadedFromPrefsFallback = true;
              });
            }
          } catch (prefsError) {
            if (kDebugMode) {
              print(
                  "CategoryFilteredProductGrid: Error loading from SharedPreferences during fallback: $prefsError");
            }
          }
        }

        setState(() {
          _error = errorMessage;
          if (isInitialLoad && !loadedFromPrefsFallback) {
            _products = [];
            _hasMore = true;
          }
        });

        if (!isInitialLoad && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }

        if (kDebugMode) {
          print(
              "CategoryFilteredProductGrid: Error fetching products for category ${widget.categoryId} (page $page): $e");
        }
      }
    } finally {
      if (mounted) {
        if (!isInitialLoad) {
          await Future.delayed(Duration(milliseconds: 300));
        }

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

    return ListView(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
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
            if (product.mainImageUrl != null) {
              _loadedImages[product.mainImageUrl] = true;
            }
            return _OfflineAwareProductItem(
              key: ValueKey('product_grid_item_${product.id}'),
              product: product,
              imageAlreadyTracked:
                  _loadedImages.containsKey(product.mainImageUrl),
            );
          },
        ),
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          height: _isLoadingMore ? 80.0 : 0.0,
          curve: Curves.easeInOut,
          child: _isLoadingMore
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                        SizedBox(width: 15),
                        Text(
                          'Đang tải thêm sản phẩm...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SizedBox.shrink(),
        ),
        if (!_hasMore &&
            _products.isNotEmpty &&
            !_isLoadingFirstLoad &&
            !_isLoadingMore)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              "Đã hiển thị tất cả sản phẩm.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_onScroll);
    _productService.dispose();
    super.dispose();
  }
}

class _OfflineAwareProductItem extends StatefulWidget {
  final ProductDTO product;
  final bool imageAlreadyTracked;

  const _OfflineAwareProductItem({
    Key? key,
    required this.product,
    this.imageAlreadyTracked = false,
  }) : super(key: key);

  @override
  _OfflineAwareProductItemState createState() =>
      _OfflineAwareProductItemState();
}

class _OfflineAwareProductItemState extends State<_OfflineAwareProductItem> {
  static final ProductService _productService = ProductService();
  Future<Uint8List?>? _imageLoader;
  bool _imageLoaded = false;
  bool _imageLoadAttempted = false;
  bool _isDisposed = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadImage();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void didUpdateWidget(_OfflineAwareProductItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.mainImageUrl != widget.product.mainImageUrl) {
      _imageLoaded = false;
      _imageLoadAttempted = false;
      _hasError = false;
      _initializeAndLoadImage();
    }
  }

  Future<void> _initializeAndLoadImage() async {
    final imageUrl = widget.product.mainImageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      if (mounted && !_isDisposed) {
        setState(() {
          _imageLoader = Future.value(null);
          _imageLoaded = false;
          _imageLoadAttempted = true;
        });
      }
      return;
    }

    if (!_imageLoadAttempted) {
      // Step 1: Check in-memory cache first
      final cachedImage = _productService.getImageFromCache(imageUrl);
      if (cachedImage != null) {
        if (mounted && !_isDisposed) {
          setState(() {
            _imageLoader = Future.value(cachedImage);
            _imageLoaded = true;
            _imageLoadAttempted = true;
          });
        }
        return;
      }

      // Step 2: Start loading process with retry and proper error logging
      if (mounted && !_isDisposed) {
        setState(() {
          _imageLoadAttempted = true;
          _imageLoader = _loadImageWithRetry(imageUrl);
        });
      }
    }
  }

  // Improved image loading method with better error handling
  Future<Uint8List?> _loadImageWithRetry(String imageUrl,
      {int retries = 2}) async {
    if (_isDisposed) return null;

    try {
      // Use the productService to fetch the image (handles both online and offline cases)
      final imageData = await _productService.getImageFromServer(imageUrl);

      // If we successfully got image data, return it
      if (imageData != null && imageData.isNotEmpty) {
        if (kDebugMode) {
          print(
              'Successfully loaded image for ${widget.product.name} (${imageUrl.split('/').last})');
        }
        return imageData;
      } else {
        throw Exception('Image data is empty or null');
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            'Error loading image for ${widget.product.name} (${imageUrl.split('/').last}): $e');
      }

      // Only retry if we haven't exceeded retry attempts
      if (retries > 0 && !_isDisposed) {
        await Future.delayed(Duration(milliseconds: 800));
        if (kDebugMode) {
          print(
              'Retrying image load for ${widget.product.name} (attempt ${3 - retries}/2)');
        }
        return _loadImageWithRetry(imageUrl, retries: retries - 1);
      }

      // Mark that we had an error if all retries failed
      if (mounted && !_isDisposed) {
        setState(() {
          _hasError = true;
        });
      }

      // Return null to indicate failure
      return null;
    }
  }

  Widget _buildProductImage() {
    final imageUrl = widget.product.mainImageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Center(
        child: Icon(
          Icons.image_not_supported,
          size: 50,
          color: Colors.grey,
        ),
      );
    }

    // Unified image loading approach for better consistency
    return FutureBuilder<Uint8List?>(
      future: _imageLoader,
      builder: (context, snapshot) {
        // Show loading spinner while waiting
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Container(
              color: Colors.grey[100],
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: Colors.blue[300],
                ),
              ),
            ),
          );
        }

        // Handle successful image data load
        if (snapshot.hasData && snapshot.data != null) {
          _imageLoaded = true;
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              if (kDebugMode) {
                print('Error rendering memory image: $error');
              }
              return _buildFallbackImage(imageUrl);
            },
          );
        }

        // Handle errors or no data
        return _buildFallbackImage(imageUrl);
      },
    );
  }

  // New method to build fallback image with better error handling
  Widget _buildFallbackImage(String imageUrl) {
    return FutureBuilder<bool>(
      future: _productService.isOnline(),
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? false;

        // If online, try direct network image as last resort
        if (isOnline && !_hasError) {
          // Generate full URL with cache busting for release builds
          String fullUrl = _productService.getImageUrl(imageUrl);
          if (!kDebugMode) {
            // Add cache busting parameter only in release mode
            fullUrl += '?cb=${DateTime.now().millisecondsSinceEpoch}';
          }

          return Stack(
            children: [
              // Background placeholder
              Container(color: Colors.grey[100]),

              // Network image
              Positioned.fill(
                child: Image.network(
                  fullUrl,
                  fit: BoxFit.cover,
                  cacheWidth: 500, // Add reasonable cache size
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2.0,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    if (kDebugMode) {
                      print('Network image error for $imageUrl: $error');
                    }
                    return Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }

        // If offline or all methods failed, show appropriate placeholder
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOnline ? Icons.broken_image : Icons.signal_wifi_off,
                size: 40,
                color: Colors.grey,
              ),
              if (!isOnline)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Offline",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatPrice(double price) {
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
    return '$formatted đ';
  }

  void _navigateToProductDetail() {
    if (widget.product.id != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              Pageproductdetail(productId: widget.product.id!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    double price = product.minPrice ?? 0.0;
    if (product.variants != null &&
        product.variants!.isNotEmpty &&
        product.variants![0].price != null) {
      price = product.variants![0].price!;
    }

    final discountedPrice =
        product.discountPercentage != null && product.discountPercentage! > 0
            ? price - (price * product.discountPercentage! / 100)
            : price;

    return Hero(
      tag: 'product_grid_item_${product.id}',
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          onTap: _navigateToProductDetail,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(8)),
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
                      if (product.discountPercentage != null &&
                          product.discountPercentage! > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '-${product.discountPercentage!.toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      if (product.description != null &&
                          product.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0, bottom: 4.0),
                          child: Text(
                            product.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 14),
                          SizedBox(width: 2),
                          Text(
                            (product.averageRating ?? 0.0).toStringAsFixed(1),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (product.discountPercentage != null &&
                              product.discountPercentage! > 0)
                            Text(
                              _formatPrice(price),
                              style: TextStyle(
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey[600],
                              ),
                            ),
                          Text(
                            _formatPrice(discountedPrice),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
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
