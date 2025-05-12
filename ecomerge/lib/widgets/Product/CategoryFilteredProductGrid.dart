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
  final ProductCacheService _cacheService =
      ProductCacheService(); // Instantiate cache service
  SharedPreferencesService? _prefsService; // Added for SharedPreferences
  late String _cacheKey;

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
    _cacheKey = _cacheService.getCategoryCacheKey(widget.categoryId);

    if (!kIsWeb) {
      SharedPreferencesService.getInstance().then((instance) {
        if (mounted) {
          setState(() {
            _prefsService = instance;
          });
          // Fetch products after prefs service is initialized
          _fetchProducts(page: 0, isInitialLoad: true);
        }
      }).catchError((e) {
        if (kDebugMode) {
          print(
              "CategoryFilteredProductGrid: Error initializing SharedPreferencesService: $e");
        }
        // Still attempt to fetch products even if prefs init fails
        _fetchProducts(page: 0, isInitialLoad: true);
      });
    } else {
      // For web, fetch products directly
      _fetchProducts(page: 0, isInitialLoad: true);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupScrollListener();
    });
  }

  void _setupScrollListener() {
    // Find the ancestor Scrollable's position
    _scrollPosition = Scrollable.of(context)?.position;
    _scrollPosition?.addListener(_onScroll);
    // Initial check in case the content is already scrollable and near the end
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    if (_scrollPosition != null && _scrollPosition!.hasPixels) {
      final currentScroll = _scrollPosition!.pixels;
      final maxScroll = _scrollPosition!.maxScrollExtent;
      // Load more when user is near the bottom, e.g., 300 pixels from the end
      // and not currently loading, and there are more pages, and no critical error preventing load.
      if (maxScroll > 0 && // Ensure there is scrollable content
          currentScroll >= maxScroll - 300 &&
          !_isLoadingMore &&
          _hasMore &&
          _error == null) {
        // Avoid loading more if there's a persistent error
        _fetchProducts(page: _currentPage + 1, isInitialLoad: false);
      }
    }
  }

  @override
  void didUpdateWidget(CategoryFilteredProductGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categoryId != oldWidget.categoryId) {
      _cacheKey = _cacheService
          .getCategoryCacheKey(widget.categoryId); // Update cache key
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

      // 1. Try to load from in-memory cache first
      final cachedData = _cacheService.getCategoryProducts(_cacheKey);
      if (cachedData != null) {
        if (mounted) {
          setState(() {
            _products = List.from(cachedData.products); // Use a copy
            _currentPage = cachedData.currentPage;
            _hasMore = cachedData.hasMore;
            _isLoadingFirstLoad = false;
            _error = null;
          });
        }
        return;
      }

      // 2. Determine network status (only for non-web)
      bool isDeviceOnline = true; // Assume online for web or if check fails
      if (!kIsWeb) {
        try {
          final connectivityResult = await Connectivity().checkConnectivity();
          isDeviceOnline = connectivityResult != ConnectivityResult.none;
        } catch (e) {
          if (kDebugMode) {
            print(
                "CategoryFilteredProductGrid: Error checking connectivity: $e");
          }
          // Default to true if connectivity check fails, to attempt network.
        }
      }

      // 3. Initial Load Logic
      // 3a. Non-Web & Offline: Try SharedPreferences first
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
            // Update in-memory cache with data from SharedPreferences
            _cacheService.storeCategoryProducts(
                _cacheKey, _products, _currentPage, _hasMore);
            return;
          } else if (mounted) {
            // SharedPreferences empty or error, and offline
            setState(() {
              _isLoadingFirstLoad = false;
              _error = "Không có kết nối mạng và không có dữ liệu ngoại tuyến.";
              _products = [];
              _hasMore = true; // Allow retry
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
              _hasMore = true; // Allow retry
            });
            return;
          }
        }
      }
      // 3b. Web OR (Non-Web & Online) OR (Non-Web & Offline but Prefs failed/empty): Fetch from Network
      // This block is reached if:
      // - It's web.
      // - It's non-web and online.
      // - It's non-web and offline, but SharedPreferences attempt above didn't return (e.g., no data or error).
      //   In this case, the network call will likely fail with SocketException if truly offline.
    } else {
      // Load More Logic
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
      // Proceed to network fetch if online or web for load more
    }

    // Common Network Fetch Logic (for both initial load and load more if applicable)
    try {
      PageResponse<ProductDTO> response;
      const minSpinnerDuration = Duration(milliseconds: 300); // For smoother UI

      if (isInitialLoad) {
        final results = await Future.wait([
          _productService.fetchProducts(
            categoryId: widget.categoryId,
            page: page, // page is 0 for initial load
            size: widget.itemsToLoadPerPage,
            sortBy: 'createdDate',
            sortDir: 'desc',
          ),
          Future.delayed(minSpinnerDuration),
        ]);
        response = results[0] as PageResponse<ProductDTO>;
      } else {
        response = await _productService.fetchProducts(
          categoryId: widget.categoryId,
          page: page,
          size: widget.itemsToLoadPerPage,
          sortBy: 'createdDate',
          sortDir: 'desc',
        );
      }

      if (mounted) {
        final newProducts = response.content;
        setState(() {
          if (page == 0) {
            // Initial fetch from network (after cache misses or if web/online)
            _products = newProducts;
          } else {
            // Loading more
            _products.addAll(newProducts);
          }
          _currentPage = response.number;
          _hasMore = !response.last;
          _error = null; // Clear error on successful fetch
        });

        // Update in-memory cache
        if (page == 0) {
          _cacheService.storeCategoryProducts(
              _cacheKey, _products, _currentPage, _hasMore);
        } else {
          // For append, newProducts are the ones just fetched for the current page
          _cacheService.appendCategoryProducts(
              _cacheKey, newProducts, _currentPage, _hasMore);
        }

        // Save/Update SharedPreferences if not on web and service is available AND online
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
            products: List.from(_products), // Save the full, updated list
            currentPage: _currentPage,
            hasMore: _hasMore,
            lastFetched: DateTime.now(),
          );
          try {
            await _prefsService!
                .saveCategoryProductData(_cacheKey, currentDataToSave);
            if (kDebugMode) {
              print(
                  "CategoryFilteredProductGrid: Saved/Updated products to SharedPreferences for $_cacheKey.");
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

        // Fallback to SharedPreferences on network error for non-web platforms
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
                // Update in-memory cache with this fallback data
                _cacheService.storeCategoryProducts(
                    _cacheKey, _products, _currentPage, _hasMore);
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
          // If initial load failed completely (no network, no cache, no prefs fallback)
          if (isInitialLoad && !loadedFromPrefsFallback) {
            _products = []; // Clear products
            _hasMore = true; // Reset to allow potential retry
          }
          // For load more errors, _isLoadingMore will be set to false in finally.
          // A Snackbar might be more appropriate for load more errors if some data is already visible.
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
            return _OfflineAwareProductItem(
              key: ValueKey('product_grid_item_${product.id}'),
              product: product,
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

class _OfflineAwareProductItem extends StatefulWidget {
  final ProductDTO product;

  const _OfflineAwareProductItem({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  _OfflineAwareProductItemState createState() =>
      _OfflineAwareProductItemState();
}

class _OfflineAwareProductItemState extends State<_OfflineAwareProductItem> {
  static final ProductService _productService = ProductService();
  Future<dynamic> _imageLoader = Future.value(null);
  bool _imageLoadedFromPrefs = false;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadImage();
  }

  @override
  void didUpdateWidget(_OfflineAwareProductItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.mainImageUrl != widget.product.mainImageUrl ||
        oldWidget.product.id != widget.product.id) {
      _imageLoadedFromPrefs = false;
      _imageLoader = Future.value(null); // Reset
      _initializeAndLoadImage();
    }
  }

  Future<void> _initializeAndLoadImage() async {
    final imageUrl = widget.product.mainImageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      if (mounted) {
        setState(() {
          _imageLoader = Future.value(null);
          _imageLoadedFromPrefs = false;
        });
      }
      return;
    }

    if (!kIsWeb) {
      Uint8List? imageDataFromPrefs;
      try {
        final prefs = await SharedPreferencesService.getInstance();
        imageDataFromPrefs = prefs.getImageData(imageUrl);
      } catch (e) {
        if (kDebugMode) {
          print(
              "Error accessing SharedPreferences for image '${imageUrl}': $e");
        }
      }

      if (mounted) {
        if (imageDataFromPrefs != null) {
          setState(() {
            _imageLoader = Future.value(imageDataFromPrefs);
            _imageLoadedFromPrefs = true;
          });
          return;
        } else {
          // Image not in SharedPreferences, load from server.
          setState(() {
            _imageLoader = _productService.getImageFromServer(imageUrl);
            _imageLoadedFromPrefs = false;
          });
        }
      }
    } else {
      // For web platforms, load directly from the server.
      if (mounted) {
        setState(() {
          _imageLoader = _productService.getImageFromServer(imageUrl);
          _imageLoadedFromPrefs = false;
        });
      }
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

    return FutureBuilder<dynamic>(
      future: _imageLoader,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        if (snapshot.hasError ||
            snapshot.data == null ||
            !(snapshot.data is Uint8List)) {
          if (kDebugMode) {
            print(
                'Error in FutureBuilder for product image (${widget.product.name}): ${snapshot.error}');
          }
          return const Center(
            child: Icon(
              Icons.broken_image,
              size: 50,
              color: Colors.grey,
            ),
          );
        }

        final imageData = snapshot.data as Uint8List;

        if (!kIsWeb && !_imageLoadedFromPrefs && imageUrl.isNotEmpty) {
          // Save to SharedPreferences if loaded from network
          SharedPreferencesService.getInstance().then((prefs) {
            prefs.saveImageData(imageUrl, imageData);
          }).catchError((e) {
            if (kDebugMode) {
              print(
                  "Error saving image to SharedPreferences for ${widget.product.name}: $e");
            }
          });
        }

        return Image.memory(
          imageData,
          fit: BoxFit.cover,
          width: double.infinity, // Ensure image fills its allocated space
          height: double.infinity,
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
      tag: 'product_grid_item_${product.id}', // Unique tag for Hero animation
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias, // Ensures content respects border radius
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          onTap: _navigateToProductDetail,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                // Image container
                flex: 3, // Adjust flex factor as needed for image height
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
                // Text content container
                flex: 2, // Adjust flex factor as needed
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween, // Distribute space
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
                      // SizedBox(height: 2),
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
                      // SizedBox(height: 2),
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
