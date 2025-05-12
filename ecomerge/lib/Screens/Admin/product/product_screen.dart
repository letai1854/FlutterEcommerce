import 'dart:io';

import 'package:flutter/material.dart';
// Removed unused imports: dart:math, dart:io, flutter/rendering.dart - (These were comments, keeping them)

// Import AddUpdateProductScreen - make sure the path is correct
import 'Add_Update_Product.dart'; // <-- Ensure this path is correct

// Import necessary components for fetching data
import 'package:e_commerce_app/database/services/product_service.dart'; // Assuming ProductService is in this path
import 'package:e_commerce_app/database/models/product_dto.dart'; // Assuming ProductDTO is in this path
import 'package:e_commerce_app/database/PageResponse.dart'; // Assuming PageResponse is in this path
import 'package:e_commerce_app/database/models/product_variant_dto.dart'; // Import ProductVariantDTO for variant details

import 'package:flutter/foundation.dart'; // Import for kIsWeb and kDebugMode


class ProductScreen extends StatefulWidget {
  const ProductScreen({Key? key}) : super(key: key);

  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {

  // --- State for Data Fetching ---
  final ProductService _productService = ProductService(); // Instance of service
  List<ProductDTO> _fetchedProducts = []; // List to hold products for the current page
  int _totalProductsCount = 0; // Total number of products on the backend
  bool _isLoading = false; // Loading state indicator
  String? _error; // Error message state

  // --- State for Pagination ---
  int _currentPage = 0; // Current page number (0-indexed for backend API)
  final int _rowsPerPage = 10; // Items per page

  // Calculated total number of pages
  // Use null check for _totalProductsCount and handle _rowsPerPage = 0
  int get _pageCount => _rowsPerPage > 0 && (_totalProductsCount ?? 0) > 0 ? ((_totalProductsCount ?? 0) / _rowsPerPage).ceil() : 1; // Changed to 1 if total is 0


  // --- State for Processing (e.g., during delete) ---
  bool _isProcessing = false; // To disable UI during async operations like delete


  @override
  void initState() {
    super.initState();
    // Initial data fetch for the first page
    _fetchProductsPage(page: _currentPage);
  }

  @override
  void dispose() {
     // Dispose the service httpClient
    _productService.dispose();
    super.dispose();
  }

  // --- Data Fetching Logic ---
  Future<void> _fetchProductsPage({int page = 0}) async {
      // Calculate total pages needed for validation
      final int totalPages = _pageCount;

      // Prevent fetching if already loading or if page is out of bounds (unless total count is 0)
      // Allow fetching page 0 even if total count is 0 initially.
      if (_isLoading) {
          if (kDebugMode) print('Attempted to fetch page while already loading.');
          return;
      }

       // Adjust page if it's out of bounds after data potentially changed (delete, update)
       // This handles cases where the current page index becomes invalid
       if (totalPages > 0 && page >= totalPages) {
           if (kDebugMode) print('Adjusting page from $page to ${totalPages - 1}');
           return _fetchProductsPage(page: totalPages - 1); // Go to the last valid page
       }
        if (page < 0) {
            if (kDebugMode) print('Adjusting page from $page to 0');
             return _fetchProductsPage(page: 0); // Go to the first page
        }


      setState(() {
          _isLoading = true;
          _error = null; // Clear previous error
          _currentPage = page; // Update current page state immediately
      });

      try {
          // Call the ProductService with pagination parameters only
          final PageResponse<ProductDTO> response = await _productService.fetchProducts(
              page: _currentPage, // Use the updated current page state
              size: _rowsPerPage,
              // Removed search, startDate, endDate parameters as per requirement
              // Ensure your backend API supports fetching without these parameters
          );

          setState(() {
              _fetchedProducts = response.content ?? []; // Use the list of products from the page
              _totalProductsCount = response.totalElements ?? 0; // Use totalElements for total count
              _isLoading = false;
          });

           if (kDebugMode) {
              print('Fetched page $_currentPage with ${_fetchedProducts.length} products. Total products: $_totalProductsCount, Total pages: ${_pageCount}');
           }


      } catch (e) {
          if (kDebugMode) print('Error fetching products: $e');
          setState(() {
              _error = 'Không thể tải dữ liệu sản phẩm: ${e.toString()}';
              _isLoading = false;
              _fetchedProducts = []; // Clear products on error
              _totalProductsCount = 0; // Reset count on error
          });
           // Show error message using Snackbar
            if(mounted) { // Check if widget is still mounted before showing Snackbar
                 ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(
                         content: Text(_error!),
                         backgroundColor: Colors.red,
                     ),
                 );
            }
      }
  }


  // Method to navigate to Add/Update screen using Navigator
  void _navigateToAddUpdateScreen({ProductDTO? product}) { // Accept ProductDTO
    // Disable navigation if already processing or loading
    if (_isProcessing || _isLoading) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        // If product is not null, pass its DTO to AddUpdateProductScreen
        // Convert ProductDTO back to Map<String, dynamic> for the AddUpdateProductScreen's current product parameter
        // Note: AddUpdateProductScreen currently expects Map, so we do the conversion.
        // Ideally, AddUpdateProductScreen should work directly with ProductDTO.
        // This is a temporary bridge based on your existing AddUpdateProductScreen structure.
        builder: (context) => AddUpdateProductScreen(
           product: product?.toJson(), // Pass the product DTO as a Map
         ),
      ),
      // The .then() block is called when the pushed screen (AddUpdateProductScreen)
      // is popped (when Navigator.pop() is called in AddUpdateProductScreen).
      // This is the correct place to refresh the UI if needed after adding/editing.
      // In a real app, you would likely refetch the data here.
    ).then((result) {
       // Check the result if AddUpdateProductScreen passes back a success indicator
       if (result == true) { // Assuming true is passed on success
           if (kDebugMode) print('Returned from Add/Update Screen successfully. Refreshing Product List.');
           // Refresh the current page after adding/editing
           // Delay the fetch slightly to allow Navigator pop animation/Snackbar to finish
           Future.delayed(const Duration(milliseconds: 100), () {
              // If adding a new product, might want to go to the last page?
              // For simplicity, just refresh the current page.
              _fetchProductsPage(page: _currentPage);
           });

       } else {
           if (kDebugMode) print('Returned from Add/Update Screen (Cancelled or Failed).');
       }
    });
  }

  // --- Delete Product Logic ---
  Future<void> _deleteProduct(ProductDTO product) async { // Accept ProductDTO
      // Disable deletion if already processing or loading, or if product has no ID
      if (_isProcessing || _isLoading || product.id == null) return;

      // Show confirmation dialog
      final bool? confirmed = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
              title: const Text('Xác nhận xóa'), // Added const
              content: Text('Bạn có chắc chắn muốn xóa sản phẩm "${product.name}" không?'),
              actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(false), // Cancel
                      child: const Text('Hủy'), // Added const
                  ),
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(true), // Confirm
                      child: const Text('Xóa'), // Added const
                  ),
              ],
          ),
      );

      if (confirmed == true && product.id != null) { // Proceed only if confirmed and product has an ID
         setState(() {
             _isProcessing = true; // Use the existing processing state
         });

          // Show a loading indicator (optional, dialog might be enough)
          if(mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text('Đang xóa sản phẩm "${product.name}"...'), duration: Duration(seconds: 2)), // Short duration
               );
          }


          try {
             // Call the delete API
             await _productService.deleteProduct(product.id!);

             // Hide loading SnackBar
             if(mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();

             // Show success message
              if(mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Đã xóa sản phẩm "${product.name}"'),
                          backgroundColor: Colors.green,
                      ),
                  );
              }


             // Refresh the current page after deletion
             // Recalculate the page to fetch in case the deletion empties the last page
             int pageToFetch = _currentPage;
              // If this was the only item on the page (_fetchedProducts.length == 1)
              // AND we are not on page 0 (_currentPage > 0)
              // AND the total count of products will be > 0 after this deletion (implies previous page exists)
              // Note: _totalProductsCount is the count *before* deletion.
              if (_fetchedProducts.length == 1 && _currentPage > 0 && (_totalProductsCount ?? 0) > 1) {
                 pageToFetch = _currentPage - 1; // Go back one page
              } else if ((_totalProductsCount ?? 0) == 1) {
                 // If the very last item is deleted (total count was 1), stay on page 0 (which will be empty)
                 pageToFetch = 0;
              }
             // In other cases (deleting from a non-last page, or deleting the last item on the last page where total > 1), stay on the same page.


             // We don't wait for fetch here to quickly exit the processing state
             // Delay the fetch slightly to allow Snackbar to be visible briefly
             Future.delayed(const Duration(milliseconds: 100), () {
                  _fetchProductsPage(page: pageToFetch).then((_) {
                     // Ensure processing state is turned off after fetch completes
                     if(mounted) { // Check if widget is still mounted
                         setState(() {
                             _isProcessing = false;
                         });
                     }
                 }).catchError((err) {
                     // Also turn off processing if the subsequent fetch fails
                      if(mounted) {
                         setState(() {
                             _isProcessing = false;
                         });
                     }
                     if (kDebugMode) print('Error refreshing list after delete: $err');
                 });
             });


          } catch (e) {
             // Handle error
             if (kDebugMode) print('Error deleting product: $e');
             // Hide loading SnackBar
             if(mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
             // Show error message
              if(mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(
                         content: Text('Lỗi xóa sản phẩm "${product.name}": ${e.toString()}'),
                         backgroundColor: Colors.red,
                     ),
                 );
              }
             setState(() {
                 _isProcessing = false; // Turn off processing state on error
             });
          }
      } else {
         // Deletion cancelled or product ID is null
         if (kDebugMode) print('Deletion cancelled or product ID is null.');
         // Ensure processing state is off if it was somehow turned on before confirmation (unlikely with this flow)
         setState(() {
             _isProcessing = false;
         });
      }
  }

  // Helper to build a row for displaying key-value info
  Widget _buildInfoRow(String label, String value, {int maxLength = 80}) {
    String displayValue = value;
    // Apply maxLength only if value is not null
    if (value.isNotEmpty && value.length > maxLength) {
      displayValue = value.substring(0, maxLength) + '...';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100, // Increased width for labels
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build image widget from path (Handles Asset, File, and Network based on platform)
  // Modified to get the source string
  // This helper is used for displaying images within the ProductScreen list.
  Widget _buildImageWidget(String? imageSource, {double size = 40, double iconSize = 40, BoxFit fit = BoxFit.cover}) {
    if (imageSource == null || imageSource.isEmpty) {
      return Icon(Icons.image, size: iconSize, color: Colors.grey); // Placeholder icon
    }

     // Prefix baseUrl if the imageSource looks like a relative path
    String finalImageSource = imageSource;
    // Simple check if it doesn't look like a full URL or asset path
    if (!imageSource.startsWith('http://') && !imageSource.startsWith('https://') && !imageSource.startsWith('assets/')) {
       // Use the helper from ProductService to get the full URL for relative paths
       // Assuming your ProductService has a getImageUrl method
       try {
            // Check if _productService is null before calling getImageUrl
            if (_productService == null) {
                 if (kDebugMode) print('[_buildImageWidget] Error: ProductService is null when getting URL.');
                 return Icon(Icons.error_outline, size: iconSize, color: Colors.red); // Show error placeholder
            }
            finalImageSource = _productService.getImageUrl(imageSource);
       } catch (e) {
            // Handle case where ProductService or getImageUrl is not accessible/throws
            if (kDebugMode) print('Error getting image URL from ProductService: $e');
            return Icon(Icons.error_outline, size: iconSize, color: Colors.red); // Show error placeholder
       }

    }


    // Check if it's an asset path (simple check)
    if (finalImageSource.startsWith('assets/')) {
       return Image.asset(
            finalImageSource,
            fit: fit,
             errorBuilder: (context, error, stackTrace) {
                 // Show placeholder if asset fails to load
                 if (kDebugMode) print('Error loading asset: $finalImageSource, Error: $error'); // Debugging
                 return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
             },
       );
    } else if (finalImageSource.startsWith('http') || finalImageSource.startsWith('https')) {
        // Assume it's a network URL
         return Image.network(
             finalImageSource,
             fit: fit,
              // Add loading builder for network images
             loadingBuilder: (context, child, loadingProgress) {
               if (loadingProgress == null) return child;
               return Center(
                 child: SizedBox( // Use SizedBox to prevent layout changes during loading
                    width: size * 0.8, // Make indicator slightly smaller than container
                    height: size * 0.8,
                   child: CircularProgressIndicator(
                     value: loadingProgress.expectedTotalBytes != null
                         ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                         : null,
                     strokeWidth: 2,
                   ),
                 ),
               );
             },
              errorBuilder: (context, error, stackTrace) {
                 // Show placeholder if network image fails
                 if (kDebugMode) print('Error loading network image: $finalImageSource, Error: $error'); // Debugging
                 return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
             },
         );
    }
    else if (!kIsWeb) {
      // On non-web, if not asset or http, assume it's a file path
       try {
         final file = File(finalImageSource); // Use the potential file path
         // Check if file exists before trying to load, prevents crashes on invalid paths
         if (file.existsSync()) {
            return Image.file(
                file,
                fit: fit,
                 errorBuilder: (context, error, stackTrace) {
                    // Show placeholder if file fails to load
                    if (kDebugMode) print('Error loading file: $finalImageSource, Error: $error'); // Debugging
                    return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
                },
            );
         } else {
             // File does not exist, show placeholder
             if (kDebugMode) print('File does not exist: $finalImageSource');
             return Icon(Icons.insert_drive_file, size: iconSize, color: Colors.grey); // File placeholder
         }

       } catch (e) {
         // Handle potential errors during file creation or checking existence
         if (kDebugMode) print('Exception handling file path: $finalImageSource, Exception: $e'); // Debugging
         return Icon(Icons.error_outline, size: iconSize, color: Colors.red); // Error placeholder
       }
    }
     else {
        // On web, if not asset or http, and not File path (because File doesn't exist on web),
        // it might be a temporary blob URL or something else. Treat as network for web.
        // Use network image with error handling for any other path type on web
         return Image.network( // Treat potential web-specific paths like network images
             finalImageSource,
             fit: fit,
             // Add loading builder for web network images
             loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                   child: SizedBox(
                      width: size * 0.8, height: size * 0.8,
                      child: CircularProgressIndicator(
                         value: loadingProgress.expectedTotalBytes != null
                             ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                             : null,
                         strokeWidth: 2,
                      ),
                   ),
                );
             },
              errorBuilder: (context, error, stackTrace) {
                 // Show placeholder if web path fails
                 if (kDebugMode) print('Error loading web path: $finalImageSource, Error: $error'); // Debugging
                 return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
             },
         );
    }
  }


  // Displays full variant details in a dialog
  void _showVariantsDialog(ProductDTO product) { // Accept ProductDTO
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Ensure variants list is not null
        final List<ProductVariantDTO> variants = product.variants ?? [];

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            width: double.maxFinite,
             constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6, // Limit dialog height
                  ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Biến thể của ${product.name}', // Use product.name
                        style: const TextStyle( // Added const
                            fontSize: 16, fontWeight: FontWeight.bold),
                        softWrap: true,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close), // Added const
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  ],
                ),
                const Divider(), // Added const
                Expanded( // Use Expanded for the ListView
                   // Show a message if there are no variants
                   child: variants.isEmpty
                       ? const Center(child: Text('Không có biến thể nào.')) // Added const
                       : ListView.builder(
                            shrinkWrap: true,
                            itemCount: variants.length,
                            itemBuilder: (context, index) {
                              final variant = variants[index];
                              // Determine the image widget for the variant
                              final String? imagePath = variant.variantImageUrl; // Use variant.variantImageUrl

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4), // Added const
                                child: ListTile(
                                  leading: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        clipBehavior: Clip.antiAlias, // Apply border radius to the image
                                        child: _buildImageWidget(imagePath, size: 50, iconSize: 30), // Use helper
                                      ),
                                  title: Text(variant.name ?? 'Biến thể [Không tên]', // Use variant.name
                                      style: const TextStyle(fontWeight: FontWeight.w500)), // Added const
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Display variant details from DTO
                                       if (variant.sku != null && variant.sku!.isNotEmpty)
                                          Text('Mã SKU: ${variant.sku}'), // Changed label from 'Mã sự kiện' to 'Mã SKU'
                                       // Display price, handling potential null/non-numeric
                                      Text(
                                          'Giá: ${variant.price != null ? (variant.price!).toStringAsFixed(0) : 'N/A'} VNĐ'), // Use variant.price
                                        // Display quantity, handling potential null/non-numeric
                                      Text('Tồn kho: ${variant.stockQuantity != null ? (variant.stockQuantity!).toString() : 'N/A'}'), // Use variant.stockQuantity
                                      // Note: createdDate/updatedDate are not present in your ProductVariantDTO
                                      // if (variant.createdDate != null)
                                      //   Text('Ngày tạo: ${variant.createdDate!.toLocal().toString().split(' ')[0]}'),
                                      // if (variant.updatedDate != null)
                                      //   Text('Cập nhật: ${variant.updatedDate!.toLocal().toString().split(' ')[0]}'),
                                    ],
                                  ),
                                  isThreeLine: false, // Changed to false if removing date lines
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

   // Handles displaying main product images (assets or files/network)
   // MODIFIED: This function is no longer used for the main product image in the list.
   // The main image is now displayed directly using _buildImageWidget(product.mainImageUrl).
   // This function is kept in case you need to display a gallery of *additional* images elsewhere.
   Widget _buildImageGallery(List<String>? images) { // Accept List<String>?
    // Filter out nulls and empty strings
    final validImages = images?.where((img) => img.isNotEmpty).toList() ?? [];

    if (validImages.isEmpty) {
      return Container(
        width: 80,
        height: 120,
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey), // Added const
      );
    }
    // If only one image, just display it directly without PageView
    if (validImages.length == 1) {
        return Container(
             width: 80,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildImageWidget(validImages.first, size: 80, iconSize: 40),
        );
    }

    // If more than one image, use PageView
    return Container(
      height: 120,
      width: 80, // Fixed width for the gallery container
      child: PageView.builder(
        itemCount: validImages.length,
        itemBuilder: (context, i) {
           final imagePath = validImages[i];

          return Container(
            width: 80, // Width of each page in PageView
            height: 120, // Height of each page
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias, // Apply border radius to the image
            child: _buildImageWidget(imagePath, size: 80, iconSize: 40), // Use helper
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Calculate available width considering padding
    // Not strictly needed for this simplified layout, but kept for consistency
    // final double availableWidth = MediaQuery.of(context).size.width - 2 * 16.0; // Removed as it's unused

    return Scaffold(
      appBar: AppBar( // Added AppBar for title
        title: const Text('Quản lý sản phẩm'), // Added const
      ),
      body: AbsorbPointer( // Use AbsorbPointer to block interaction when processing (e.g., deleting or loading)
        absorbing: _isProcessing || _isLoading, // Absorb when deleting or loading
        child: SingleChildScrollView( // Use SingleChildScrollView to handle overflow
              child: Padding(
                padding: const EdgeInsets.all(16.0), // Added const
                child: _buildLayout(), // Use the simplified layout function without width param
              ),
            ),
      ),
    );
  }

  // Builds the main layout
  Widget _buildLayout() {
    // Calculate total page count
    final int totalPages = _pageCount;

     // Adjust current page state if total pages changes (e.g., becomes 0 or current page is out of bounds)
     // Use WidgetsBinding.instance.addPostFrameCallback to avoid setState during build
     WidgetsBinding.instance.addPostFrameCallback((_) {
         if (!_isLoading && !_isProcessing) { // Only adjust if not currently processing async operations
             if (totalPages == 0 && _currentPage != 0) {
                 // If total products become 0, reset to page 0
                 setState(() { _currentPage = 0; });
                 // No need to refetch here, as the list will already be empty.
             } else if (totalPages > 0 && _currentPage >= totalPages) {
                 // If current page is beyond the new total pages, go to the last valid page
                 setState(() { _currentPage = totalPages - 1; });
                 // Refetch the data for the adjusted page
                 _fetchProductsPage(page: totalPages - 1);
             } else if (totalPages > 0 && _currentPage < 0) { // Handle negative page case
                  setState(() { _currentPage = 0; });
                  _fetchProductsPage(page: 0);
             }
         }
     });


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // "Thêm sản phẩm" Button
        Align( // Align the button to the left
           alignment: Alignment.centerLeft,
           child: ElevatedButton(
             // Disable add button if currently processing a delete or fetching
             onPressed: _isProcessing || _isLoading ? null : () {
               // Use Navigator.push to go to the Add screen
               _navigateToAddUpdateScreen();
             },
             style: ElevatedButton.styleFrom(
               padding:
                   const EdgeInsets.symmetric(vertical: 15, horizontal: 16), // Added const
               textStyle: const TextStyle(fontSize: 14), // Added const
               minimumSize: const Size(0, 48), // Added const
             ),
             child: const Text('Thêm sản phẩm'), // Added const
           ),
        ),

        const SizedBox(height: 20), // Added const
        const Text( // Added const
          'Danh sách sản phẩm',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10), // Added const

        // --- Display Area (Loading, Error, or List) ---
        _isLoading && _fetchedProducts.isEmpty && _error == null // Show initial loading only if list is empty and no error yet
            ? const Center(child: CircularProgressIndicator()) // Added const
            : _error != null // Show error message if there's an error
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red))) // Added const
                : _fetchedProducts.isEmpty // Show message if the fetched list is empty
                    ? const Center(child: Text('Không tìm thấy sản phẩm nào.')) // Added const
                    : ListView.builder( // Display the list if data is available
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(), // Disable scrolling for this list inside SingleChildScrollView
                        itemCount: _fetchedProducts.length, // Use fetched products list length
                        itemBuilder: (context, index) {
                          final product = _fetchedProducts[index]; // Get ProductDTO object

                          return Column(
                            children: [
                               // const SizedBox(height: 8), // Space between items - Optional, Card has margin
                              Card(
                                margin: const EdgeInsets.symmetric(vertical: 4), // Added const
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0), // Added const
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // *** MODIFIED LINE HERE ***
                                      // Use a fixed-size container for the image area
                                      Container(
                                        width: 80, // Match the old gallery width
                                        height: 120, // Match the old gallery height
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            color: Colors.grey[200], // Placeholder background
                                        ),
                                        clipBehavior: Clip.antiAlias, // Apply border radius
                                        // Use _buildImageWidget with the MAIN image URL
                                        child: _buildImageWidget(product.mainImageUrl, size: 80, iconSize: 40, fit: BoxFit.cover), // Use mainImageUrl
                                      ),
                                      // *** END MODIFIED LINE ***
                                      const SizedBox(width: 10), // Added const
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              product.name, // Use product.name
                                              style: const TextStyle( // Added const
                                                  fontWeight: FontWeight.bold, fontSize: 14),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4), // Added const
                                            _buildInfoRow('ID:', product.id?.toString() ?? 'N/A'), // Display ID
                                            _buildInfoRow('Thương hiệu:', product.brandName ?? 'N/A'), // Use product.brandName
                                            _buildInfoRow('Danh mục:', product.categoryName ?? 'N/A'), // Use product.categoryName
                                            _buildInfoRow('Mô tả:', product.description, // Use product.description
                                                maxLength: 80),
                                            _buildInfoRow('Ngày tạo:',
                                                '${product.createdDate?.toLocal().toString().split(' ')[0] ?? 'N/A'}'), // Use product.createdDate
                                            _buildInfoRow('Ngày cập nhật:',
                                                '${product.updatedDate?.toLocal().toString().split(' ')[0] ?? 'N/A'}'), // Use product.updatedDate
                                            _buildInfoRow(
                                                'Giảm giá:', '${product.discountPercentage ?? 0}%'), // Use product.discountPercentage
                                             _buildInfoRow('Số biến thể:',
                                                  '${product.variantCount ?? (product.variants?.length ?? 0)}'), // Use variantCount if available, else variants list size

                                          ],
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Only show "Xem biến thể" button if variants exist (check count or list)
                                          // Checking product.variants is more reliable if variantCount is not always included or accurate
                                          if ((product.variants ?? []).isNotEmpty) // Use product.variants
                                          TextButton(
                                            onPressed: _isProcessing || _isLoading ? null : () { // Disable when processing/loading
                                              _showVariantsDialog(product); // Pass the ProductDTO
                                            },
                                            style: TextButton.styleFrom( // Added const
                                              padding: const EdgeInsets.symmetric( // Added const
                                                  horizontal: 8, vertical: 4),
                                              minimumSize: const Size(0, 30), // Added const
                                            ),
                                            child: const Text('Xem biến thể'), // Added const
                                          ),
                                          // Edit button
                                          IconButton(
                                            // Disable when processing delete or fetching
                                            onPressed: _isProcessing || _isLoading ? null : () {
                                              // Use Navigator.push to go to the Edit screen
                                              // Pass the specific product DTO
                                              _navigateToAddUpdateScreen(product: product);
                                            },
                                            icon: const Icon(Icons.edit, size: 18), // Added const
                                            tooltip: 'Chỉnh sửa',
                                            constraints: const BoxConstraints( // Added const
                                                minWidth: 36, minHeight: 36),
                                            padding: EdgeInsets.zero, // Added const
                                          ),
                                          // Delete button
                                          // IconButton(
                                          //   // Disable when processing delete or fetching
                                          //   onPressed: _isProcessing || _isLoading ? null : () {
                                          //      _deleteProduct(product); // Pass the ProductDTO to delete
                                          //   },
                                          //   icon: const Icon(Icons.delete, size: 18), // Added const
                                          //   tooltip: 'Xóa',
                                          //   constraints: const BoxConstraints( // Added const
                                          //       minWidth: 36, minHeight: 36),
                                          //   padding: EdgeInsets.zero, // Added const
                                          // ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                               // Optional: Show loading indicator below the last item if fetching the next page (less common with fixed pagination size)
                               // if (_isLoading && index == _fetchedProducts.length -1)
                               //    const Padding(
                               //       padding: EdgeInsets.only(top: 8.0),
                               //       child: Center(child: CircularProgressIndicator()),
                               //    ),
                            ],
                          );
                        },
                      ),
         const SizedBox(height: 20), // Added const

        // Pagination controls - Only show if there are products or loading (to avoid sudden disappearance)
         if ((_totalProductsCount ?? 0) > 0 || _isLoading) // Show pagination controls if total > 0 or loading
         Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), // Added const
          margin: const EdgeInsets.only(top: 8), // Added const
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                // Display current range and total count
                // Handle cases where list is empty but total count is > 0 (e.g., loading error on subsequent pages)
                // or list is empty and total count is 0.
                'Hiển thị ${_fetchedProducts.isEmpty ? 0 : (_currentPage * _rowsPerPage) + 1} - ${(_currentPage * _rowsPerPage) + _fetchedProducts.length} trên ${(_totalProductsCount ?? 0)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8), // Added const
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Previous Page Button
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_left), // Added const
                    // Disable if on the first page (page 0) or loading/processing
                    onPressed: _currentPage > 0 && !_isLoading && !_isProcessing
                        ? () {
                             // Fetch the previous page
                             _fetchProductsPage(page: _currentPage - 1);
                          }
                        : null,
                    tooltip: 'Trang trước',
                  ),
                  // Page Number Display
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0), // Added const
                    child: Text(
                      // Display current page (1-indexed) / total pages
                      '${_currentPage + 1} / ${totalPages > 0 ? totalPages : 1}', // Ensure denominator is at least 1
                      style: const TextStyle(fontWeight: FontWeight.bold), // Added const
                    ),
                  ),
                  // Next Page Button
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_right), // Added const
                    // Disable if on the last page or loading/processing
                    onPressed: _currentPage < totalPages - 1 && !_isLoading && !_isProcessing
                        ? () {
                             // Fetch the next page
                             _fetchProductsPage(page: _currentPage + 1);
                          }
                        : null,
                    tooltip: 'Trang tiếp',
                  ),
                ],
              ),
            ],
          ),
        ),
         const SizedBox(height: 24), // Added const
      ],
    );
  }
}
