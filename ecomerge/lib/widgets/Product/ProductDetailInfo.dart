import 'dart:typed_data';

import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/database/services/product_service.dart'; // Add this import
import 'package:cached_network_image/cached_network_image.dart';

// --- Main Detail Widget ---
class ProductDetailInfo extends StatelessWidget {
  // Product Info
  final String productName;
  final String brandName;
  final double averageRating;
  final int ratingCount;
  final String shortDescription;
  final List<String> illustrationImages; // Danh sách ảnh minh họa cố định

  // Variant Info
  final List<Map<String, dynamic>> productVariants;
  final int selectedVariantIndex;
  final int currentStock;
  final Function(int) onVariantSelected;

  // Quantity Info & Callbacks
  final int selectedQuantity;
  final Function(int) onQuantityChanged;

  // Image Display Info & Callbacks
  final String displayedMainImageUrl; // URL ảnh chính đang hiển thị
  final Function(String)
      onIllustrationImageSelected; // Callback nhấn ảnh minh họa

  // Review Info & Callbacks
  final ScrollController scrollController;
  final List<Map<String, dynamic>> displayedReviews;
  final int totalReviews;
  final bool isLoadingReviews;
  final bool canLoadMoreReviews;
  final VoidCallback loadMoreReviews;
  final VoidCallback submitReview;
  final TextEditingController commentController;
  final int selectedRating;
  final Function(int) onRatingChanged;

  // Action Callbacks
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  // Product ID
  final int productId; // Add this line

  // Image cache function to prevent flickering
  final Future<Uint8List?> Function(String, ProductService)? imageCache;
  final double? discountPercentage; // Add this parameter

  const ProductDetailInfo({
    Key? key,
    // Product
    required this.productName,
    required this.brandName,
    required this.averageRating,
    required this.ratingCount,
    required this.shortDescription,
    required this.illustrationImages,
    // Variants
    required this.productVariants,
    required this.selectedVariantIndex,
    required this.currentStock,
    required this.onVariantSelected,
    // Quantity
    required this.selectedQuantity,
    required this.onQuantityChanged,
    // Image Display
    required this.displayedMainImageUrl,
    required this.onIllustrationImageSelected,
    // Reviews
    required this.scrollController,
    required this.displayedReviews,
    required this.totalReviews,
    required this.isLoadingReviews,
    required this.canLoadMoreReviews,
    required this.loadMoreReviews,
    required this.submitReview,
    required this.commentController,
    required this.selectedRating,
    required this.onRatingChanged,
    // Actions
    required this.onAddToCart,
    required this.onBuyNow,
    required this.productId, // Add this line
    this.imageCache, // Optional parameter with default fallback
    this.discountPercentage, // Initialize new parameter
  }) : super(key: key);

  Widget _buildPriceDisplay(BuildContext context) {
    if (productVariants.isEmpty ||
        selectedVariantIndex < 0 ||
        selectedVariantIndex >= productVariants.length) {
      return const SizedBox.shrink(); // No variants or invalid selection
    }

    final selectedVariant = productVariants[selectedVariantIndex];
    final dynamic currentPriceDynamic = selectedVariant['price'];

    final double currentPrice = (currentPriceDynamic is int)
        ? currentPriceDynamic.toDouble()
        : (currentPriceDynamic is double ? currentPriceDynamic : 0.0);

    bool hasDiscount = discountPercentage != null && discountPercentage! > 0;
    double finalPrice = currentPrice;

    if (hasDiscount) {
      finalPrice = currentPrice * (1 - (discountPercentage! / 100));
    }

    String formatCurrency(double amount) {
      final format = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
      return '$format đ';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 24.0), // Add padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start, // Align to start
        crossAxisAlignment: CrossAxisAlignment.baseline, // Align text baselines
        textBaseline: TextBaseline.alphabetic, // Specify baseline for alignment
        children: [
          if (hasDiscount)
            Text(
              formatCurrency(currentPrice),
              style: TextStyle(
                fontSize: 18, // Slightly smaller for original price
                color: Colors.grey[600],
                decoration: TextDecoration.lineThrough,
              ),
            ),
          if (hasDiscount) const SizedBox(width: 10), // Space between prices
          Text(
            formatCurrency(finalPrice),
            style: TextStyle(
              fontSize: 26, // Larger font for final price
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor, // Use theme color
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Create ProductService instance for image loading
    final productService = ProductService();

    // Round the rating to 1 decimal place for display
    final displayRating = (averageRating * 10).round() / 10;

    // Function to get image with caching
    Future<Uint8List?> getImage(String imageUrl) {
      if (imageCache != null) {
        return imageCache!(imageUrl, productService);
      }
      return productService.getImageFromServer(imageUrl);
    }

    return Container(
      color: Colors.grey[200],
      child: SingleChildScrollView(
        controller: scrollController,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Product Info Section ---
                LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isWideScreen = constraints.maxWidth > 700;

                    // --- Image Section ---
                    final imageSection = Flexible(
                      flex: isWideScreen ? 1 : 0,
                      fit: FlexFit.loose,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Main Image Area ---
                          AspectRatio(
                            aspectRatio: 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                color: Colors.white,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(7.0),
                                child: displayedMainImageUrl.isEmpty
                                    ? Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                            child: Icon(
                                                Icons.image_not_supported,
                                                color: Colors.grey,
                                                size: 50)),
                                      )
                                    // Use FutureBuilder for better image loading and caching
                                    : FutureBuilder<Uint8List?>(
                                        future: getImage(displayedMainImageUrl),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                                  ConnectionState.done &&
                                              snapshot.hasData &&
                                              snapshot.data != null) {
                                            // Display cached image data with high quality
                                            return GestureDetector(
                                              onTap: () {
                                                // Show full-screen image dialog when tapped
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => Dialog(
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    insetPadding:
                                                        EdgeInsets.zero,
                                                    child: Stack(
                                                      alignment:
                                                          Alignment.center,
                                                      children: [
                                                        // Interactive image with pinch-zoom gesture support
                                                        InteractiveViewer(
                                                          panEnabled: true,
                                                          boundaryMargin:
                                                              const EdgeInsets
                                                                  .all(20),
                                                          minScale: 0.5,
                                                          maxScale: 4.0,
                                                          child: Hero(
                                                            tag:
                                                                'product_image_fullscreen',
                                                            child: Image.memory(
                                                              snapshot.data!,
                                                              fit: BoxFit
                                                                  .contain,
                                                              filterQuality:
                                                                  FilterQuality
                                                                      .high,
                                                            ),
                                                          ),
                                                        ),
                                                        // Close button
                                                        Positioned(
                                                          top: 40,
                                                          right: 20,
                                                          child: CircleAvatar(
                                                            backgroundColor:
                                                                Colors.black54,
                                                            radius: 18,
                                                            child: IconButton(
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              icon: const Icon(
                                                                  Icons.close,
                                                                  color: Colors
                                                                      .white),
                                                              onPressed: () =>
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop(),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Hero(
                                                tag:
                                                    'product_image_${displayedMainImageUrl.hashCode}',
                                                child: Container(
                                                  color: Colors.white,
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  child: Stack(
                                                    fit: StackFit.expand,
                                                    children: [
                                                      Image.memory(
                                                        snapshot.data!,
                                                        key: ValueKey(
                                                            displayedMainImageUrl),
                                                        fit: BoxFit.contain,
                                                        filterQuality:
                                                            FilterQuality.high,
                                                      ),
                                                      // Add subtle zoom indicator
                                                      Positioned(
                                                        right: 8,
                                                        bottom: 8,
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(4),
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                Colors.black38,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        4),
                                                          ),
                                                          child: const Icon(
                                                            Icons.zoom_in,
                                                            color: Colors.white,
                                                            size: 16,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }

                                          // Fall back to CachedNetworkImage for better caching
                                          return GestureDetector(
                                            onTap: () {
                                              // Show network image in full screen when tapped
                                              showDialog(
                                                context: context,
                                                builder: (context) => Dialog(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  insetPadding: EdgeInsets.zero,
                                                  child: Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      InteractiveViewer(
                                                        panEnabled: true,
                                                        boundaryMargin:
                                                            const EdgeInsets
                                                                .all(20),
                                                        minScale: 0.5,
                                                        maxScale: 4.0,
                                                        child:
                                                            CachedNetworkImage(
                                                          imageUrl: productService
                                                              .getImageUrl(
                                                                  displayedMainImageUrl),
                                                          fit: BoxFit.contain,
                                                          filterQuality:
                                                              FilterQuality
                                                                  .high,
                                                          placeholder:
                                                              (context, url) =>
                                                                  Center(
                                                            child:
                                                                CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              valueColor:
                                                                  AlwaysStoppedAnimation<
                                                                      Color>(
                                                                Theme.of(
                                                                        context)
                                                                    .primaryColor,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        top: 40,
                                                        right: 20,
                                                        child: CircleAvatar(
                                                          backgroundColor:
                                                              Colors.black54,
                                                          radius: 18,
                                                          child: IconButton(
                                                            padding:
                                                                EdgeInsets.zero,
                                                            icon: const Icon(
                                                                Icons.close,
                                                                color: Colors
                                                                    .white),
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                        context)
                                                                    .pop(),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Container(
                                                  color: Colors.white,
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  child: CachedNetworkImage(
                                                    imageUrl: productService
                                                        .getImageUrl(
                                                            displayedMainImageUrl),
                                                    key: ValueKey(
                                                        displayedMainImageUrl),
                                                    fit: BoxFit.contain,
                                                    filterQuality:
                                                        FilterQuality.high,
                                                    fadeInDuration:
                                                        const Duration(
                                                            milliseconds: 200),
                                                    placeholder:
                                                        (context, url) =>
                                                            Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                                Color>(
                                                          Theme.of(context)
                                                              .primaryColor,
                                                        ),
                                                      ),
                                                    ),
                                                    errorWidget:
                                                        (context, url, error) {
                                                      print(
                                                          "Error loading main image: $url, Error: $error");
                                                      return Container(
                                                        color: Colors.grey[200],
                                                        child: const Center(
                                                          child: Icon(
                                                            Icons.broken_image,
                                                            color: Colors.grey,
                                                            size: 50,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                                // Add a subtle zoom icon to indicate the image is zoomable
                                                Positioned(
                                                  right: 8,
                                                  bottom: 8,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black38,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: const Icon(
                                                      Icons.zoom_in,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // --- Illustration Images (Thumbnails) ---
                          if (illustrationImages
                              .isNotEmpty) // Chỉ hiển thị nếu có ảnh minh họa
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: illustrationImages.map((imageUrl) {
                                  final bool isSelectedThumbnail =
                                      (imageUrl == displayedMainImageUrl);
                                  return BuildThumbnail(
                                    imageUrl: imageUrl,
                                    isSelected:
                                        isSelectedThumbnail, // Highlight nếu ảnh này đang hiển thị chính
                                    onTap: () => onIllustrationImageSelected(
                                        imageUrl), // Callback khi nhấn
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    );

                    // --- Details Section ---
                    final detailsSection = Flexible(
                      flex: isWideScreen ? 1 : 0,
                      fit: FlexFit.loose,
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: isWideScreen ? 16.0 : 0.0,
                            top: !isWideScreen ? 16.0 : 0.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Name, Rating, Brand
                            Text(productName,
                                style: textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.star,
                                      color: Colors.amber, size: 18),
                                  const SizedBox(width: 4),
                                  Text('$displayRating',
                                      style: textTheme.bodyMedium)
                                ]),
                                Text('Thương hiệu: $brandName',
                                    style: textTheme.bodyMedium),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Short Description
                            if (shortDescription.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Text(
                                  shortDescription,
                                  style: textTheme.bodyMedium
                                      ?.copyWith(color: Colors.grey[700]),
                                ),
                              ),
                            // Variant Selection Options
                            Text('Chọn biến thể:',
                                style: textTheme.titleMedium),
                            const SizedBox(height: 8),
                            if (productVariants
                                .isNotEmpty) // Chỉ hiển thị nếu có biến thể
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: List.generate(
                                      productVariants.length, (index) {
                                    final variant = productVariants[index];
                                    return BuildVariantOption(
                                      variantName: variant['name'] ?? 'N/A',
                                      imageUrl: variant['variantThumbnail'] ??
                                          '', // Ảnh nhỏ của biến thể
                                      isSelected: index ==
                                          selectedVariantIndex, // Trạng thái chọn
                                      onTap: () => onVariantSelected(
                                          index), // Callback chọn
                                    );
                                  }),
                                ),
                              )
                            else // Thông báo nếu không có biến thể
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text("Sản phẩm hiện chưa có biến thể.",
                                    style: textTheme.bodySmall?.copyWith(
                                        fontStyle: FontStyle.italic)),
                              ),
                            const SizedBox(height: 16),
                            // Stock Display
                            Row(
                              children: [
                                Text('Kho: $currentStock',
                                    style: textTheme.titleMedium),
                                if (currentStock <= 0)
                                  Container(
                                    margin: const EdgeInsets.only(left: 10),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: Colors.red.shade300),
                                    ),
                                    child: const Text(
                                      'Hết hàng',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(
                                height:
                                    16), // Added space before quantity selector

                            // --- Quantity Selector ---
                            BuildQuantitySelector(
                              currentQuantity: selectedQuantity,
                              maxQuantity: currentStock,
                              onChanged: onQuantityChanged,
                            ),
                            // --- Price Display ---
                            _buildPriceDisplay(
                                context), // Add price display here
                            // Action Buttons
                            Wrap(
                              spacing: 12,
                              runSpacing: 10,
                              children: [
                                ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: currentStock > 0
                                            ? Colors.orange.shade100
                                            : Colors.grey.shade200,
                                        foregroundColor: currentStock > 0
                                            ? Colors.orange.shade800
                                            : Colors.grey,
                                        side: BorderSide(
                                            color: currentStock > 0
                                                ? Colors.orange.shade300
                                                : Colors.grey.shade300),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8))),
                                    onPressed:
                                        currentStock > 0 ? onAddToCart : null,
                                    icon: const Icon(
                                        Icons.add_shopping_cart_outlined,
                                        size: 18),
                                    label: const Text('Thêm vào giỏ hàng')),
                                ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: currentStock > 0
                                            ? Colors.red.shade700
                                            : Colors.grey.shade400,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        elevation: currentStock > 0 ? 2 : 0),
                                    onPressed:
                                        currentStock > 0 ? onBuyNow : null,
                                    icon: const Icon(Icons.flash_on_outlined,
                                        size: 18),
                                    label: const Text('Mua ngay')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );

                    // Responsive Layout
                    return isWideScreen
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [imageSection, detailsSection])
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [imageSection, detailsSection]);
                  },
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // --- Review Section ---
                BuildReviewSection(
                  context: context,
                  isLoading: isLoadingReviews,
                  displayedReviews: displayedReviews,
                  totalReviews: totalReviews,
                  canLoadMore: canLoadMoreReviews,
                  loadMoreReviews: loadMoreReviews,
                  submitReview: submitReview,
                  commentController: commentController,
                  selectedRating: selectedRating,
                  onRatingChanged: onRatingChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Helper Widgets ---

// BuildThumbnail: Hiển thị ảnh minh họa nhỏ.
class BuildThumbnail extends StatelessWidget {
  final String imageUrl;
  final bool isSelected; // True nếu ảnh này đang hiển thị chính
  final VoidCallback onTap;

  const BuildThumbnail({
    Key? key,
    required this.imageUrl,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create ProductService instance for image loading
    final productService = ProductService();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? Colors.red
                : Colors.grey.shade300, // Viền đỏ nếu được chọn
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Container(
            width: 60, // Slightly larger thumbnails
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FutureBuilder<Uint8List?>(
              key: ValueKey(
                  'thumb_$imageUrl'), // Add stable key to prevent rebuilds
              future: productService.getImageFromServer(imageUrl),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Image.memory(
                    snapshot.data!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  );
                }

                return CachedNetworkImage(
                  imageUrl: productService.getImageUrl(imageUrl),
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  placeholder: (context, url) => Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isSelected ? Colors.red : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child:
                        Icon(Icons.error_outline, size: 22, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// BuildVariantOption: Hiển thị các tùy chọn biến thể.
class BuildVariantOption extends StatelessWidget {
  final String variantName;
  final String imageUrl; // Ảnh đại diện biến thể
  final bool isSelected; // True nếu biến thể này đang được chọn
  final VoidCallback onTap; // Callback chọn biến thể

  const BuildVariantOption({
    Key? key,
    required this.variantName,
    required this.imageUrl,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create ProductService instance for image loading
    final productService = ProductService();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.withOpacity(0.05) : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.red : Colors.grey.shade400,
            width: isSelected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: 45, // Slightly larger variant images
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: imageUrl.isEmpty
                    ? Container(
                        width: 45,
                        height: 45,
                        color: Colors.grey[200],
                        child: Icon(Icons.hide_image_outlined,
                            size: 20, color: Colors.grey),
                      )
                    : FutureBuilder<Uint8List?>(
                        key: ValueKey('variant_$imageUrl'), // Add stable key
                        future: productService.getImageFromServer(imageUrl),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return Image.memory(
                              snapshot.data!,
                              width: 45,
                              height: 45,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            );
                          }

                          return CachedNetworkImage(
                            imageUrl: productService.getImageUrl(imageUrl),
                            width: 45,
                            height: 45,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            placeholder: (context, url) => Center(
                              child: SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isSelected ? Colors.red : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (c, url, e) => Container(
                              width: 45,
                              height: 45,
                              color: Colors.grey[200],
                              child: Icon(Icons.image_not_supported,
                                  size: 18, color: Colors.grey),
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                variantName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.red.shade700 : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// BuildQuantitySelector: Widget for selecting product quantity.
class BuildQuantitySelector extends StatelessWidget {
  final int currentQuantity;
  final int maxQuantity;
  final Function(int) onChanged;

  const BuildQuantitySelector({
    Key? key,
    required this.currentQuantity,
    required this.maxQuantity,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If out of stock, show disabled quantity selector
    if (maxQuantity <= 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Số lượng:', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade100,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 20, color: Colors.grey),
                  onPressed: null,
                  splashRadius: 20,
                  constraints: const BoxConstraints(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  constraints: const BoxConstraints(minWidth: 40),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      vertical: BorderSide(color: Colors.grey.shade300),
                    ),
                    color: Colors.grey.shade200,
                  ),
                  child: const Text(
                    '0',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20, color: Colors.grey),
                  onPressed: null,
                  splashRadius: 20,
                  constraints: const BoxConstraints(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Số lượng:', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(width: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 20),
                onPressed: currentQuantity > 1
                    ? () => onChanged(currentQuantity - 1)
                    : null, // Disable if quantity is 1
                splashRadius: 20,
                constraints: const BoxConstraints(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8), // Increased padding for quantity text
                constraints: const BoxConstraints(
                    minWidth: 40), // Minimum width for quantity display
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    vertical: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Text(
                  '$currentQuantity',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: currentQuantity < maxQuantity
                    ? () => onChanged(currentQuantity + 1)
                    : null, // Disable if quantity reaches max stock
                splashRadius: 20,
                constraints: const BoxConstraints(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// BuildReviewSection: Widget để hiển thị và nhập đánh giá.
Widget BuildReviewSection({
  required BuildContext context,
  required bool isLoading,
  required List<Map<String, dynamic>> displayedReviews,
  required int totalReviews,
  required bool canLoadMore,
  required VoidCallback loadMoreReviews,
  required VoidCallback submitReview,
  required TextEditingController commentController,
  required int selectedRating,
  required Function(int) onRatingChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Đánh giá sản phẩm (${displayedReviews.length}/$totalReviews)',
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 16),
      Card(
        elevation: 1,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Viết đánh giá của bạn:',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              
              // Properly formatted conditional star picker for logged-in users
              if (UserInfo().isLoggedIn) 
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: List.generate(
                    5,
                    (index) => IconButton(
                      icon: Icon(
                        index < selectedRating
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () => onRatingChanged(index + 1),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  )
                ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Nhập bình luận của bạn...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Gửi đánh giá'),
                ),
              ),
            ],
          ),
        ),
      ),
      if (displayedReviews.isEmpty && !isLoading)
        const Center(
            child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('Chưa có đánh giá nào.')))
      else
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount:
              displayedReviews.length + (isLoading || canLoadMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == displayedReviews.length) {
              if (isLoading)
                return const Center(
                    child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: CircularProgressIndicator()));
              if (canLoadMore)
                return Center(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: OutlinedButton(
                            onPressed: loadMoreReviews,
                            child: const Text('Xem thêm đánh giá'))));
              return const SizedBox.shrink();
            }
            final review = displayedReviews[index];
            final String avatarAsset = review['avatar'] is String
                ? review['avatar']
                : 'assets/default_avatar.png';
            final String name = review['name'] ?? 'Ẩn danh';
            final int rating = review['rating'] is int ? review['rating'] : 0;
            final String comment = review['comment'] ?? '';
            return ListTile(
              leading: CircleAvatar(
                  backgroundImage: AssetImage(avatarAsset),
                  onBackgroundImageError: (_, __) {},
                  backgroundColor: Colors.grey[300],
                  child: const Icon(Icons.person, color: Colors.white)),
              title: Text(name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Only show star rating if rating is greater than 0
                  if (rating > 0)
                    Row(
                      children: List.generate(
                        5,
                        (starIndex) => Icon(
                          starIndex < rating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        )
                      )
                    ),
                  // Always show the SizedBox if there's a rating to display
                  if (rating > 0) const SizedBox(height: 4),
                  // Always show the comment text
                  Text(comment),
                ],
              ),
            );
          },
          separatorBuilder: (context, index) => const Divider(height: 1),
        ),
    ],
  );
}
