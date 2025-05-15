import 'dart:convert';
import 'dart:typed_data';

import 'package:e_commerce_app/database/models/CartDTO.dart';
import 'package:e_commerce_app/database/models/create_product_review_request_dto.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForTablet.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForMobile.dart';
import 'package:e_commerce_app/widgets/Product/ProductDetailInfo.dart';
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/database/services/product_service.dart';
import 'package:e_commerce_app/database/models/cart_item_model.dart';
import 'package:e_commerce_app/Screens/Payment/PagePayment.dart';
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/database/Storage/CartStorage.dart';
import 'package:e_commerce_app/database/models/product_dto.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:flutter/foundation.dart';
import 'package:e_commerce_app/database/database_helper.dart';

class _ProductImageCache {
  static final Map<String, Future<Uint8List?>> _cache = {};

  static Future<Uint8List?> getImage(String url, ProductService service) {
    if (url.isEmpty) {
      return Future.value(null);
    }

    if (!_cache.containsKey(url)) {
      _cache[url] = service.getImageFromServer(url).then((imageData) {
        if (imageData == null || imageData.isEmpty) {
          return null;
        }
        return imageData;
      }).catchError((error) {
        if (kDebugMode) {
          print('Error fetching image $url: $error');
        }
        _cache.remove(url); // Remove failed entries from cache
        return null;
      });
    }

    return _cache[url]!.catchError((error) {
      if (kDebugMode) {
        print('Error retrieving cached image $url: $error');
      }
      _cache.remove(url);
      return null;
    });
  }
  
  // New method to clear the entire cache
  static void clearCache() {
    if (kDebugMode) {
      print('Clearing image cache, ${_cache.length} items removed');
    }
    _cache.clear();
  }
}

class Pageproductdetail extends StatefulWidget {
  final int productId;

  const Pageproductdetail({
    super.key,
    required this.productId,
  });

  @override
  State<Pageproductdetail> createState() => _PageproductdetailState();
}

class _PageproductdetailState extends State<Pageproductdetail> {
  final ScrollController _scrollController = ScrollController();
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  List<ProductReviewDTO> _displayedReviews = [];
  int _selectedVariantIndex = 0;
  String _displayedMainImageUrl = '';
  bool _isLoading = true;
  final ProductService _productService = ProductService();
  Map<String, dynamic> _productData = {};
  int _selectedQuantity = 1;

  bool _isLoadingReviews = false;
  bool _canLoadMoreReviews = false;

  StompClient? _stompClient;
  StompUnsubscribe? _reviewSubscription;
  final UserInfo _userInfo = UserInfo();

  @override
  void initState() {
    super.initState();
    _loadProductDetails(widget.productId);
    _connectToReviewWebSocket();
  }

  Future<void> _loadProductDetails(int productId) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _productData = {};
    });

    try {
      final product = await _productService.getProductById(productId);
      if (!mounted) return;

      List<String> allImages = [];
      if (product.mainImageUrl != null && product.mainImageUrl!.isNotEmpty) {
        allImages.add(product.mainImageUrl!);
      }
      if (product.imageUrls != null) {
        allImages.addAll(product.imageUrls!
            .where((img) => img.isNotEmpty && !allImages.contains(img)));
      }

      setState(() {
        _productData = {
          'id': product.id,
          'name': product.name,
          'brand': product.brandName ?? "N/A",
          'averageRating': product.averageRating ?? 0.0,
          'ratingCount': product.variantCount ?? 0,
          'shortDescription': product.description,
          'illustrationImages': allImages,
          'productVariants': product.variants
                  ?.map((variant) => {
                        'id': variant.id,
                        'name': variant.name ?? 'Không tên',
                        'mainImage': variant.variantImageUrl ??
                            product.mainImageUrl ??
                            '',
                        'variantThumbnail': variant.variantImageUrl ??
                            product.mainImageUrl ??
                            '',
                        'stock': variant.stockQuantity ?? 0,
                        'price': variant.price ?? 0.0,
                      })
                  .toList() ??
              [],
          'minPrice': product.minPrice,
          'maxPrice': product.maxPrice,
          'discountPercentage': product.discountPercentage,
        };

        if (_productData['productVariants'] != null &&
            (_productData['productVariants'] as List).isNotEmpty) {
          final firstVariant = (_productData['productVariants'] as List).first;
          if (firstVariant['mainImage'] != null &&
              (firstVariant['mainImage'] as String).isNotEmpty) {
            _displayedMainImageUrl = firstVariant['mainImage'] as String;
          } else if (product.mainImageUrl != null &&
              product.mainImageUrl!.isNotEmpty) {
            _displayedMainImageUrl = product.mainImageUrl!;
          } else if (allImages.isNotEmpty) {
            _displayedMainImageUrl = allImages.first;
          }
        } else if (product.mainImageUrl != null &&
            product.mainImageUrl!.isNotEmpty) {
          _displayedMainImageUrl = product.mainImageUrl!;
        } else if (allImages.isNotEmpty) {
          _displayedMainImageUrl = allImages.first;
        }

        if (product.reviews != null) {
          _displayedReviews = product.reviews!;
        } else {
          _displayedReviews = [];
        }

        _isLoading = false;
      });
    } catch (e) {
      print('Error loading product data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading product: $e')),
        );
      }
    }
  }

  void _connectToReviewWebSocket() {
    final String webSocketUrl = '${baseurl.replaceFirst("http", "ws")}/ws/websocket';
    final token = _userInfo.authToken;
    final Map<String, String> connectHeaders = token != null ? {'Authorization': 'Bearer $token'} : {};

    _stompClient = StompClient(
      config: StompConfig(
        url: webSocketUrl,
        onConnect: _onStompConnect,
        onWebSocketError: (dynamic error) {
          if (kDebugMode) print('WebSocket Error: $error');
        },
        stompConnectHeaders: connectHeaders,
        webSocketConnectHeaders: connectHeaders,
        onDebugMessage: kDebugMode ? (String message) => print("STOMP_DEBUG: $message") : (String message) {},
      ),
    );
    _stompClient?.activate();
  }

  void _onStompConnect(StompFrame connectFrame) {
    if (kDebugMode) print('Connected to WebSocket for reviews.');
    _reviewSubscription = _stompClient?.subscribe(
      destination: '/topic/product/${widget.productId}/reviews',
      callback: _onReviewReceived,
    );
  }

  void _onReviewReceived(StompFrame frame) {
    if (frame.body != null) {
      try {
        final newReviewJson = jsonDecode(frame.body!);
        final newReview = ProductReviewDTO.fromJson(newReviewJson);

        if (mounted) {
          setState(() {
            if (!_displayedReviews.any((r) => r.id == newReview.id)) {
              _displayedReviews.insert(0, newReview);
              _displayedReviews.sort((a, b) => (b.reviewTime ?? DateTime(0)).compareTo(a.reviewTime ?? DateTime(0)));
            } else {
              final index = _displayedReviews.indexWhere((r) => r.id == newReview.id);
              if (index != -1) {
                _displayedReviews[index] = newReview;
              }
            }
          });
        }
      } catch (e) {
        if (kDebugMode) print('Error processing review message: $e. Body: ${frame.body}');
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    _productService.dispose();
    _reviewSubscription?.call();
    _stompClient?.deactivate();
    
    // Clear the image cache when leaving the screen
    _ProductImageCache.clearCache();
    
    super.dispose();
  }

  void _onVariantSelected(int index) {
    final variants = _productData['productVariants'] as List;
    if (index >= 0 && index < variants.length) {
      setState(() {
        _selectedVariantIndex = index;
        final variantImage = variants[index]['mainImage'] as String?;
        if (variantImage != null && variantImage.isNotEmpty) {
          _displayedMainImageUrl = variantImage;
        }
      });
    }
  }

  void _onIllustrationImageSelected(String imageUrl) {
    setState(() {
      _displayedMainImageUrl = imageUrl;
    });
  }

  void _onRatingChanged(int newRating) {
    setState(() {
      _selectedRating = newRating;
    });
  }

  void _submitReview() async {
    final bool isLoggedIn = _userInfo.currentUser != null;
    final String commentText = _commentController.text.trim();

    if (isLoggedIn) {
      if (_selectedRating < 1 || _selectedRating > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged-in users must provide a rating between 1 and 5.')),
        );
        return;
      }
    } else {
      if ((_selectedRating == 0) && commentText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anonymous users must provide a rating or a comment.')),
        );
        return;
      }
      if (_selectedRating != 0 && (_selectedRating < 1 || _selectedRating > 5)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('If providing a rating, it must be between 1 and 5.')),
        );
        return;
      }
    }

    CreateProductReviewRequestDTO reviewRequest;
    if (isLoggedIn) {
      reviewRequest = CreateProductReviewRequestDTO(
        rating: _selectedRating,
        comment: commentText.isNotEmpty ? commentText : null,
      );
    } else {
      reviewRequest = CreateProductReviewRequestDTO(
        reviewerName: "Anonymous",
        rating: _selectedRating > 0 ? _selectedRating : null,
        comment: commentText.isNotEmpty ? commentText : null,
      );
    }

    try {
      await _productService.submitReview(widget.productId, reviewRequest);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully!')),
      );
      setState(() {
        _selectedRating = 0;
        _commentController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: ${e.toString()}')),
      );
    }
  }

  void _onQuantityChanged(int newQuantity) {
    if (newQuantity != _selectedQuantity) {
      setState(() {
        _selectedQuantity = newQuantity;
      });
    }
  }

  void _loadMoreReviews() {
    if (kDebugMode) {
      print("Load more reviews triggered");
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> illustrations =
        (_productData['illustrationImages'] is List)
            ? List<String>.from(_productData['illustrationImages'])
            : [];

    final productVariants = (_productData['productVariants'] is List)
        ? List<Map<String, dynamic>>.from(_productData['productVariants'])
        : <Map<String, dynamic>>[];

    Widget backButton = IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        // Clear the image cache when back button is pressed
        _ProductImageCache.clearCache();
        Navigator.of(context).pop();
      },
      tooltip: 'Trở về',
    );

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: backButton,
          title: const Text('Đang tải sản phẩm...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    Widget productInfoSection = ProductDetailInfo(
      productId: widget.productId,
      productName: _productData['name'] ?? 'N/A',
      brandName: _productData['brand'] ?? 'N/A',
      averageRating: _productData['averageRating']?.toDouble() ?? 0.0,
      ratingCount: _productData['ratingCount'] ?? 0,
      shortDescription: _productData['shortDescription'] ?? '',
      illustrationImages: illustrations,
      productVariants: productVariants,
      selectedVariantIndex: _selectedVariantIndex,
      currentStock: productVariants.isEmpty
          ? 0
          : productVariants[_selectedVariantIndex]['stock'] ?? 0,
      onVariantSelected: _onVariantSelected,
      selectedQuantity: _selectedQuantity,
      onQuantityChanged: _onQuantityChanged,
      displayedMainImageUrl: _displayedMainImageUrl,
      onIllustrationImageSelected: _onIllustrationImageSelected,
      scrollController: _scrollController,
      displayedReviews: _displayedReviews.map((review) {
        return {
          'id': review.id,
          'avatar': review.reviewerAvatarUrl ?? 'assets/default_avatar.png',
          'name': review.reviewerName ?? 'Ẩn danh',
          'rating': review.rating ?? 0,
          'comment': review.comment ?? '',
          'reviewTime': review.reviewTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
        };
      }).toList(),
      totalReviews: _displayedReviews.length,
      isLoadingReviews: _isLoadingReviews,
      canLoadMoreReviews: _canLoadMoreReviews,
      loadMoreReviews: _loadMoreReviews,
      submitReview: _submitReview,
      commentController: _commentController,
      selectedRating: _selectedRating,
      onRatingChanged: _onRatingChanged,
      imageCache: _ProductImageCache.getImage,
      discountPercentage:
          (_productData['discountPercentage'] as num?)?.toDouble(),
      onAddToCart: () async {
        if (_productData.isEmpty ||
            _productData['productVariants'] == null ||
            (_productData['productVariants'] as List).isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Thông tin sản phẩm không có sẵn để thêm vào giỏ hàng.')),
          );
          return;
        }

        final productVariantsList = _productData['productVariants'] as List;
        if (_selectedVariantIndex < 0 ||
            _selectedVariantIndex >= productVariantsList.length) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng chọn một biến thể hợp lệ.')),
          );
          return;
        }

        final selectedVariant = productVariantsList[_selectedVariantIndex];
        final int stockQuantity = selectedVariant['stock'] as int? ?? 0;
        if (stockQuantity <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sản phẩm đã hết hàng.')),
          );
          return;
        }

        String baseProductName = _productData['name'] ?? 'Sản phẩm';
        final String? variantName = selectedVariant['name'] as String?;
        
        final String fullProductName;
        if (variantName != null && variantName.isNotEmpty && variantName != 'Không tên') {
          fullProductName = '$baseProductName - $variantName';
        } else {
          fullProductName = baseProductName;
        }

        final String variantImageUrl =
            selectedVariant['variantThumbnail'] as String? ??
                selectedVariant['mainImage'] as String? ??
                _productData['illustrationImages']?.firstWhere(
                    (img) => img != null && img.isNotEmpty,
                    orElse: () => '') ??
                '';

        try {
          final cartProductVariant = CartProductVariantDTO(
            id: selectedVariant['id'] as int?,
            productId: widget.productId,
            name: fullProductName,
            description: _productData['shortDescription'] ?? '',
            imageUrl: variantImageUrl,
            price: selectedVariant['price'] as double?,
            discountPercentage: _productData['discountPercentage']?.toDouble(),
            finalPrice: selectedVariant['price'] as double?,
            stockQuantity: selectedVariant['stock'] as int?,
          );

          final cartStorage = CartStorage();
          await cartStorage.addItemToCart(
              cartProductVariant, _selectedQuantity);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã thêm "$fullProductName" vào giỏ hàng!'),
            ),
          );
        } catch (e) {
          print('Error adding item to cart: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể thêm vào giỏ hàng: $e')),
          );
        }
      },
      onBuyNow: () {
        if (_productData.isEmpty ||
            _productData['productVariants'] == null ||
            (_productData['productVariants'] as List).isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thông tin sản phẩm không có sẵn để mua.')),
          );
          return;
        }

        final productVariantsList = _productData['productVariants'] as List;
        if (_selectedVariantIndex < 0 ||
            _selectedVariantIndex >= productVariantsList.length) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng chọn một biến thể hợp lệ.')),
          );
          return;
        }

        final selectedVariant = productVariantsList[_selectedVariantIndex];
        final int stockQuantity = selectedVariant['stock'] as int? ?? 0;
        if (stockQuantity <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sản phẩm đã hết hàng.')),
          );
          return;
        }

        String baseProductName = _productData['name'] ?? 'Sản phẩm';
        final String? variantName = selectedVariant['name'] as String?;
        
        final String fullProductName;
        if (variantName != null && variantName.isNotEmpty && variantName != 'Không tên') {
          fullProductName = '$baseProductName - $variantName';
        } else {
          fullProductName = baseProductName;
        }

        final String variantImageUrl =
            selectedVariant['variantThumbnail'] as String? ??
                selectedVariant['mainImage'] as String? ??
                _productData['illustrationImages']?.firstWhere(
                    (img) => img != null && img.isNotEmpty,
                    orElse: () => '') ??
                '';

        double originalPrice = (selectedVariant['price'] as num?)?.toDouble() ?? 0.0;
        double discountPercentageValue = (_productData['discountPercentage'] as num?)?.toDouble() ?? 0.0;
        double finalPrice = originalPrice;
        if (discountPercentageValue > 0) {
          finalPrice = originalPrice * (1 - (discountPercentageValue / 100));
        }

        final buyNowItem = CartItemModel(
          productId: widget.productId,
          productName: fullProductName,
          imageUrl: variantImageUrl,
          quantity: _selectedQuantity,
          price: finalPrice,
          variantId: selectedVariant['id'] as int,
          discountPercentage: discountPercentageValue,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PagePayment(
              cartItems: [buyNowItem],
              sourceProductId: widget.productId,
            ),
          ),
        );
      },
    );

    Widget bodyScaffoldContent = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          productInfoSection,
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        if (screenWidth < 768) {
          return NavbarFormobile(
            body: Column(
              children: [
                Container(
                  color: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.only(left: 8, top: 8),
                  alignment: Alignment.centerLeft,
                  child: backButton,
                ),
                Expanded(child: bodyScaffoldContent),
              ],
            ),
          );
        } else if (screenWidth < 1100) {
          return NavbarForTablet(
            body: Column(
              children: [
                Container(
                  color: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.only(left: 8, top: 8),
                  alignment: Alignment.centerLeft,
                  child: backButton,
                ),
                Expanded(child: bodyScaffoldContent),
              ],
            ),
          );
        } else {
          var appBar = PreferredSize(
            preferredSize: Size.fromHeight(130),
            child: Navbarhomedesktop(),
          );
          return Scaffold(
            appBar: appBar,
            body: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      backButton,
                      const SizedBox(width: 8),
                      Text(
                        _productData['name'] ?? 'Chi tiết sản phẩm',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: bodyScaffoldContent),
              ],
            ),
          );
        }
      },
    );
  }
}
