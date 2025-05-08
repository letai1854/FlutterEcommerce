import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForTablet.dart';
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForMobile.dart';
import 'package:e_commerce_app/widgets/Product/ProductDetailInfo.dart';
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/database/services/product_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadProductData();
    _loadInitialReviews();
    _scrollController.addListener(_loadMoreReviewsOnScroll);
  }

  Future<void> _loadProductData() async {
    try {
      setState(() => _isLoading = true);
      final product = await _productService.getProductById(widget.productId);

      // Create a list of all images
      List<String> allImages = [];
      if (product.mainImageUrl != null) {
        allImages.add(product.mainImageUrl!);
        
        // Preload the main image to improve user experience
        _productService.getImageFromServer(product.mainImageUrl!);
      }
      if (product.imageUrls != null) {
        allImages.addAll(product.imageUrls!);
        
        // Preload additional images asynchronously
        for (String imageUrl in product.imageUrls!) {
          _productService.getImageFromServer(imageUrl);
        }
      }

      setState(() {
        _productData = {
          'name': product.name,
          'brand': product.brandName ?? "N/A",
          'averageRating': product.averageRating ?? 0.0,
          'ratingCount': product.variantCount ?? 0,
          'shortDescription': product.description,
          'illustrationImages': allImages,
          'variants': product.variants?.map((variant) => {
            'name': variant.name ?? 'Không tên',
            'mainImage': variant.variantImageUrl ?? product.mainImageUrl ?? '',
            'variantThumbnail': variant.variantImageUrl ?? product.mainImageUrl ?? '',
            'stock': variant.stockQuantity ?? 0,
            'price': variant.price ?? product.minPrice ?? 0.0,
          }).toList() ?? [],
          'minPrice': product.minPrice,
          'maxPrice': product.maxPrice,
          'discountPercentage': product.discountPercentage,
        };

        // Set initial displayed image
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
    final variants = _productData['variants'] as List;
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
        const SnackBar(content: Text('Vui lòng chọn sao đánh giá và nhập bình luận.')),
      );
    }
  }

  final List<Map<String, dynamic>> _dummyReviews = [
    {'name': 'Nguyễn Văn A', 'rating': 5, 'comment': 'Sản phẩm tuyệt vời, đáng mua!', 'avatar': 'assets/avatar1.png',},
    {'name': 'Trần Thị B', 'rating': 4, 'comment': 'Chất lượng tốt, giá cả hợp lý.', 'avatar': 'assets/avatar2.png',},
    {'name': 'Lê Văn C', 'rating': 3, 'comment': 'Sản phẩm ổn, nhưng giao hàng hơi chậm.', 'avatar': 'assets/avatar3.png',},
    {'name': 'Phạm Thị D', 'rating': 5, 'comment': 'Rất hài lòng về sản phẩm và dịch vụ.', 'avatar': 'assets/avatar4.png',},
    {'name': 'Hoàng Văn E', 'rating': 4, 'comment': 'Sản phẩm tốt, đóng gói cẩn thận.', 'avatar': 'assets/avatar5.png',},
    {'name': 'Đặng Thị F', 'rating': 3, 'comment': 'Giá hơi cao so với chất lượng.', 'avatar': 'assets/avatar6.png',},
  ];

  bool get _canLoadMoreReviews => _displayedReviews.length < _dummyReviews.length;

  @override
  Widget build(BuildContext context) {
    final List<String> illustrations = (_productData['illustrationImages'] is List)
        ? List<String>.from(_productData['illustrationImages'])
        : [];

    final productVariants = (_productData['variants'] is List)
        ? List<Map<String, dynamic>>.from(_productData['variants'])
        : <Map<String, dynamic>>[];

    // Create a custom back button that we can reuse
    Widget backButton = IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.of(context).pop(),
      tooltip: 'Trở về',
    );

    // Show loading indicator while data is loading
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
            productName: _productData['name'] ?? 'N/A',
            brandName: _productData['brand'] ?? 'N/A',
            averageRating: _productData['averageRating']?.toDouble() ?? 0.0,
            ratingCount: _productData['ratingCount'] ?? 0,
            shortDescription: _productData['shortDescription'] ?? '',
            illustrationImages: illustrations,
            productVariants: productVariants,
            selectedVariantIndex: _selectedVariantIndex,
            currentStock: productVariants.isEmpty ? 0 : 
                         productVariants[_selectedVariantIndex]['stock'] ?? 0,
            onVariantSelected: _onVariantSelected,
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
            onAddToCart: () {
              final variantName = productVariants.isEmpty ? '' : 
                               productVariants[_selectedVariantIndex]['name'] ?? '';
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Đã thêm "${variantName}" vào giỏ hàng!'),
              ));
            },
            onBuyNow: () {
              final variantName = productVariants.isEmpty ? '' : 
                               productVariants[_selectedVariantIndex]['name'] ?? '';
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Chuyển đến thanh toán cho "${variantName}"!'),
              ));
            },
          );

   return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        if (screenWidth < 768) {
          // Mobile layout
          return NavbarFormobile(
            // Pass the back button to mobile layout
            body: Column(
              children: [
                // Add a custom back button row for mobile
                Container(
                  color: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.only(left: 8, top: 8),
                  alignment: Alignment.centerLeft,
                  child: backButton,
                ),
                // Wrap body in Expanded to avoid overflow
                Expanded(child: body),
              ],
            ),
          );
        } else if (screenWidth < 1100) {
          // Tablet layout
          return NavbarForTablet(
            // Pass the back button to tablet layout
            body: Column(
              children: [
                // Add a custom back button row for tablet
                Container(
                  color: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.only(left: 8, top: 8),
                  alignment: Alignment.centerLeft,
                  child: backButton,
                ),
                // Wrap body in Expanded to avoid overflow
                Expanded(child: body),
              ],
            ),
          );
        } else {
          // Desktop layout
          var appBar = PreferredSize(
            preferredSize: Size.fromHeight(130),
            child: Navbarhomedesktop(),
          );
          return Scaffold(
            appBar: appBar as PreferredSize,
            body: Column(
              children: [
                // Add a back button bar below the desktop app bar
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
                // Wrap body in Expanded to avoid overflow
                Expanded(child: body),
              ],
            ),
          );
        }
      },
    );
  }
}
