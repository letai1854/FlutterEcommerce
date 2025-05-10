import 'dart:typed_data';

import 'package:e_commerce_app/database/models/CartDTO.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForTablet.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForMobile.dart';
import 'package:e_commerce_app/widgets/Product/ProductDetailInfo.dart';
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/database/services/product_service.dart';
import 'package:e_commerce_app/database/models/cart_item_model.dart';
import 'package:e_commerce_app/Screens/Payment/PagePayment.dart';
// Add new imports for cart functionality
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/database/Storage/CartStorage.dart';

// Create an in-memory cache for product images to prevent flickering
class _ProductImageCache {
  static final Map<String, Future<Uint8List?>> _cache = {};
  
  static Future<Uint8List?> getImage(String url, ProductService service) {
    if (!_cache.containsKey(url)) {
      _cache[url] = service.getImageFromServer(url);
    }
    return _cache[url]!;
  }
  
  static void clear() {
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
  List<Map<String, dynamic>> _displayedReviews = [];
  int _reviewsPerPage = 2;
  bool _isLoadingReviews = false;
  int _selectedVariantIndex = 0;
  String _displayedMainImageUrl = '';
  bool _isLoading = true;
  final ProductService _productService = ProductService();
  Map<String, dynamic> _productData = {};
  int _selectedQuantity = 1;

  @override
  void initState() {
    super.initState();
    _loadProductDetails(widget.productId);
    _loadInitialReviews();
    _scrollController.addListener(_loadMoreReviewsOnScroll);
  }

  Future<void> _loadProductDetails(int productId) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _productData = {}; // Clear previous data
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
                        'price': variant.price ?? product.minPrice ?? 0.0,
                      })
                  .toList() ??
              [],
          'minPrice': product.minPrice,
          'maxPrice': product.maxPrice,
          'discountPercentage': product.discountPercentage,
        };

        if (product.mainImageUrl != null) {
          _displayedMainImageUrl = product.mainImageUrl!;
        } else if (allImages.isNotEmpty) {
          _displayedMainImageUrl = allImages.first;
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

  @override
  void dispose() {
    _scrollController.removeListener(_loadMoreReviewsOnScroll);
    _scrollController.dispose();
    _commentController.dispose();
    _productService.dispose();
    super.dispose();
  }

  void _loadInitialReviews() {
    setState(() {
      _displayedReviews = _dummyReviews.take(_reviewsPerPage).toList();
    });
  }

  Future<void> _loadMoreReviews() async {
    if (_isLoadingReviews || !_canLoadMoreReviews) return;
    setState(() => _isLoadingReviews = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final startIndex = _displayedReviews.length;
    final endIndex = (startIndex + _reviewsPerPage > _dummyReviews.length)
        ? _dummyReviews.length
        : startIndex + _reviewsPerPage;
    if (startIndex < endIndex) {
      setState(() {
        _displayedReviews.addAll(_dummyReviews.sublist(startIndex, endIndex));
      });
    }
    setState(() => _isLoadingReviews = false);
  }

  void _loadMoreReviewsOnScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _loadMoreReviews();
    }
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

  void _submitReview() {
    if (_selectedRating > 0 && _commentController.text.trim().isNotEmpty) {
      final newReview = {
        'name': 'Bạn',
        'rating': _selectedRating,
        'comment': _commentController.text.trim(),
        'avatar': 'assets/default_avatar.png',
      };
      setState(() {
        _dummyReviews.insert(0, newReview);
        _displayedReviews.insert(0, newReview);
        _selectedRating = 0;
        _commentController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đánh giá của bạn đã được gửi!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng chọn sao đánh giá và nhập bình luận.')),
      );
    }
  }

  final List<Map<String, dynamic>> _dummyReviews = [
    {
      'name': 'Nguyễn Văn A',
      'rating': 5,
      'comment': 'Sản phẩm tuyệt vời, đáng mua!',
      'avatar': 'assets/avatar1.png',
    },
    {
      'name': 'Trần Thị B',
      'rating': 4,
      'comment': 'Chất lượng tốt, giá cả hợp lý.',
      'avatar': 'assets/avatar2.png',
    },
    {
      'name': 'Lê Văn C',
      'rating': 3,
      'comment': 'Sản phẩm ổn, nhưng giao hàng hơi chậm.',
      'avatar': 'assets/avatar3.png',
    },
    {
      'name': 'Phạm Thị D',
      'rating': 5,
      'comment': 'Rất hài lòng về sản phẩm và dịch vụ.',
      'avatar': 'assets/avatar4.png',
    },
    {
      'name': 'Hoàng Văn E',
      'rating': 4,
      'comment': 'Sản phẩm tốt, đóng gói cẩn thận.',
      'avatar': 'assets/avatar5.png',
    },
    {
      'name': 'Đặng Thị F',
      'rating': 3,
      'comment': 'Giá hơi cao so với chất lượng.',
      'avatar': 'assets/avatar6.png',
    },
  ];

  bool get _canLoadMoreReviews =>
      _displayedReviews.length < _dummyReviews.length;

  void _onQuantityChanged(int newQuantity) {
    // Prevent entire UI rebuild when only quantity changes
    if (newQuantity != _selectedQuantity) {
      setState(() {
        _selectedQuantity = newQuantity;
      });
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
      onPressed: () => Navigator.of(context).pop(),
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

    Widget body = ProductDetialInfo(
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
      displayedReviews: _displayedReviews,
      totalReviews: _dummyReviews.length,
      isLoadingReviews: _isLoadingReviews,
      canLoadMoreReviews: _canLoadMoreReviews,
      loadMoreReviews: _loadMoreReviews,
      submitReview: _submitReview,
      commentController: _commentController,
      selectedRating: _selectedRating,
      onRatingChanged: _onRatingChanged,
      // Pass the image cache to prevent flickering
      imageCache: _ProductImageCache.getImage,
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
        
        // Check if stock quantity is zero
        final selectedVariant = productVariantsList[_selectedVariantIndex];
        print('selectedVariant: $selectedVariant');
        final int stockQuantity = selectedVariant['stock'] as int? ?? 0;
        if (stockQuantity <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sản phẩm đã hết hàng.')),
          );
          return;
        }

        String baseProductName = _productData['name'] ?? 'Sản phẩm';
        final String? variantName = selectedVariant['name'] as String?;
        if (variantName != null && variantName.isNotEmpty) {
          baseProductName = '$baseProductName - $variantName';
        }

        final String variantImageUrl =
            selectedVariant['variantThumbnail'] as String? ??
                selectedVariant['mainImage'] as String? ??
                _productData['illustrationImages']?.firstWhere(
                    (img) => img != null && img.isNotEmpty,
                    orElse: () => '') ??
                '';

        try {
          // Get product name
          final String baseProductName = _productData['name'] ?? 'Sản phẩm';
          
          // Get selected variant name from productVariants list
          final String? variantName = selectedVariant['name'] as String?;
          
          // Create the full product name with variant
          final String fullProductName;
          // if (variantName != null && variantName.isNotEmpty) {
          //   fullProductName = '$baseProductName - $variantName';
          // } else {
          //   fullProductName = baseProductName;
          // }
          fullProductName = baseProductName;

          
          print('Creating cart item with productName: $baseProductName, variantName: $variantName, fullName: $fullProductName');
          
          // Create product variant for CartStorage with combined name
          final cartProductVariant = CartProductVariantDTO(
            id: selectedVariant['id'] as int?,
            productId: widget.productId,
            name: fullProductName, // Use the combined name format
            description: _productData['shortDescription'] ?? '',
            imageUrl: variantImageUrl,
            price: selectedVariant['price'] as double?,
            discountPercentage: _productData['discountPercentage']?.toDouble(),
            finalPrice: selectedVariant['price'] as double?, 
            stockQuantity: selectedVariant['stock'] as int?,
          );
          
          print('Adding to cart: ${cartProductVariant.name}, ID: ${cartProductVariant.id}');
          
          // Get cart storage and add item
          final cartStorage = CartStorage();
          await cartStorage.addItemToCart(cartProductVariant, _selectedQuantity);
          
          // Check if user is logged in for debug info
          final bool isLoggedIn = UserInfo().currentUser != null;
          print('Item added to cart. User logged in: $isLoggedIn');
          
          // Show success message with action to view cart
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã thêm "$baseProductName" vào giỏ hàng!'),
              
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
            const SnackBar(
                content: Text('Thông tin sản phẩm không có sẵn để mua.')),
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

        // Check if stock quantity is zero
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
        if (variantName != null && variantName.isNotEmpty) {
          baseProductName = '$baseProductName - $variantName';
        }

        final String variantImageUrl =
            selectedVariant['variantThumbnail'] as String? ??
                selectedVariant['mainImage'] as String? ??
                _productData['illustrationImages']?.firstWhere(
                    (img) => img != null && img.isNotEmpty,
                    orElse: () => '') ??
                '';

        final buyNowItem = CartItemModel(
          productId: widget.productId,
          productName: baseProductName,
          imageUrl: variantImageUrl,
          quantity: _selectedQuantity,
          price: selectedVariant['price'] as double,
          variantId: selectedVariant['id'] as int,
        );
        
        // Pass the product ID to payment page for navigation back
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
                Expanded(child: body),
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
                Expanded(child: body),
              ],
            ),
          );
        } else {
          var appBar = PreferredSize(
            preferredSize: Size.fromHeight(130),
            child: Navbarhomedesktop(),
          );
          return Scaffold(
            appBar: appBar as PreferredSize,
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
                Expanded(child: body),
              ],
            ),
          );
        }
      },
    );
  }
}
