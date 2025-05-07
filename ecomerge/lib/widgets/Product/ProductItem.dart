import 'dart:async'; // Import for Future.delayed
import 'package:flutter/material.dart';
import 'package:e_commerce_app/database/services/product_service.dart';
import 'dart:typed_data';
import 'package:e_commerce_app/Screens/ProductDetail/PageProductDetail.dart';

class ProductItem extends StatelessWidget {
  final int productId;
  final String? imageUrl;
  final String title;
  final String? describe;
  final double price;
  final int? discount;
  final double rating;
  final bool isFromCache; // Add this flag to indicate if from cache

  const ProductItem({
    Key? key,
    required this.productId,
    required this.imageUrl,
    required this.title,
    this.describe,
    required this.price,
    this.discount,
    required this.rating,
    this.isFromCache = false, // Default to false
  }) : super(key: key);

  void _navigateToProductDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Pageproductdetail(productId: productId),
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

  Widget _buildProductImage(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return const Center(
        child: Icon(
          Icons.image_not_supported,
          size: 50,
          color: Colors.grey,
        ),
      );
    }

    // Create a single instance of ProductService for this widget
    final productService =  ProductService();
    
    // For cached products, we should never show a loading spinner
    if (isFromCache) {
      // Try to get image directly from cache first
      final cachedImage = productService.getImageFromCache(imageUrl);
      
      if (cachedImage != null) {
        // If image is in cache, show it immediately without any spinner
        return Image.memory(
          cachedImage,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(
                Icons.broken_image,
                size: 50,
                color: Colors.grey,
              ),
            );
          },
        );
      }
      
      // If claimed to be from cache but not found in cache, 
      // load without ANY loading spinner - just show a placeholder until loaded
      return Stack(
        children: [
          // Background placeholder
          Container(
            color: Colors.grey[200],
            child: Center(
              child: Icon(
                Icons.image,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
          ),
          
          // Load the image without a loading indicator
          Positioned.fill(
            child: Image.network(
              productService.getImageUrl(imageUrl!),
              fit: BoxFit.cover,
              // Remove the loadingBuilder to prevent showing a loading spinner
              errorBuilder: (context, error, stackTrace) {
                print('Error loading image: $error');
                return const Center(
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

    // For non-cached products, use the existing loading with delay approach
    final Future<List<dynamic>> combinedFuture = Future.wait([
      productService.getImageFromServer(imageUrl!).catchError((e) {
        print('Error in getImageFromServer: $e');
        return null; 
      }),
      Future.delayed(const Duration(milliseconds: 1500)),
    ]);

    return FutureBuilder<List<dynamic>>(
      future: combinedFuture,
      builder: (context, snapshot) {
        // The FutureBuilder remains in 'waiting' state until both futures complete.
        // So, the CircularProgressIndicator will be shown for at least 1 second.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          );
        }

        // After waiting, check the result of getImageFromServer
        final imageData = snapshot.data?[0]; // Data from getImageFromServer future

        if (snapshot.hasError || (imageData == null && !(snapshot.data?[0] is Uint8List) ) ) {
          // This handles errors from Future.wait or if getImageFromServer returned null/error marker
          // Fallback to Image.network if getImageFromServer failed
          print('FutureBuilder error or getImageFromServer failed, falling back to Image.network for: $imageUrl');
          return Image.network(
            ProductService().getImageUrl(imageUrl!), // imageUrl is not null here due to earlier check
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Image.network Error: $error');
              return const Center(
                child: Icon(
                  Icons.broken_image,
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
        }
        
        if (imageData is Uint8List) {
          return Image.memory(
            imageData,
            fit: BoxFit.cover,
          );
        }
        
        // Should ideally not be reached if error handling is correct, but as a final fallback:
        return const Center(
            child: Icon(
              Icons.broken_image, // Fallback for unexpected state
              size: 50,
              color: Colors.grey,
            ),
          );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final discountedPrice = discount != null && discount! > 0
        ? price - (price * discount! / 100)
        : price;

    return RepaintBoundary(
      child: Hero(
        tag: 'product_$productId',
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: InkWell(
            onTap: () => _navigateToProductDetail(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                            child: _buildProductImage(context),
                          ),
                        ),
                        if (discount != null && discount! > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '-$discount%',
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
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (describe != null && describe!.isNotEmpty)
                        Text(
                          describe!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                            rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (discount != null && discount! > 0) ...[
                        Text(
                          _formatPrice(price),
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
      ),
    );
  }
}
