import 'dart:io'; // Required for File class (implicitly used by XFile)
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:flutter/services.dart'; // Required for Uint8List
import 'package:flutter/scheduler.dart'; // Required for SchedulerBinding
import 'package:collection/collection.dart'; // Import for firstWhereOrNull

// Import your ProductService and DTOs
import 'package:e_commerce_app/database/services/product_service.dart';
import 'package:e_commerce_app/database/models/brand.dart'; // Assuming BrandDTO is here
import 'package:e_commerce_app/database/models/categories.dart'; // Assuming CategoryDTO is here
import 'package:e_commerce_app/database/models/create_product_request_dto.dart';
import 'package:e_commerce_app/database/models/update_product_request_dto.dart';
import 'package:e_commerce_app/database/models/create_product_variant_dto.dart';
import 'package:e_commerce_app/database/models/update_product_variant_dto.dart';
import 'package:e_commerce_app/database/models/product_dto.dart'; // Import ProductDTO to work with fetched data
import 'package:e_commerce_app/database/models/product_variant_dto.dart'; // Import ProductVariantDTO
import 'package:e_commerce_app/database/Storage/BrandCategoryService.dart'; // Assuming AppDataService is here


// Helper class to hold locally picked image data temporarily before upload
// (Defining it here as per your provided code structure, assuming it's not in ConnectVariant.dart)
class PickedImage {
  final Uint8List bytes;
  final String fileName;
  bool isUploading;

  PickedImage({required this.bytes, required this.fileName, this.isUploading = false});

   @override
   String toString() {
     return 'PickedImage(fileName: $fileName, bytesLength: ${bytes.length}, isUploading: $isUploading)';
   }
}

// Modified Variant class to hold server URL, locally picked image data, and controllers
// (Defining it here as per your provided code structure, assuming it's the single source of truth for Variant state)
class Variant {
  // Original ID from server, null for new variants added during edit
  int? originalId;
  // Server path after successful upload - **Stores the RELATIVE Path from the server**
  String? defaultImageUrl; // Storing the server's relative path here (e.g., "/uploads/...")
  // Locally picked image data before upload
  PickedImage? pickedImage;

  // Controllers for variant text fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  // Constructor to initialize with original ID and initial Image URL (relative path from API)
  Variant({this.originalId, String? initialImageUrl}) {
      this.defaultImageUrl = initialImageUrl; // Store the initialImageUrl (relative path from DTO)
  }

  // Factory method to create Variant object from ProductVariantDTO (for edit mode)
  factory Variant.fromProductVariantDTO(ProductVariantDTO dto) {
      final variant = Variant(
          originalId: dto.id, // Use ID from DTO for originalId
          initialImageUrl: dto.variantImageUrl, // Use variantImageUrl from DTO (relative path)
      );
      variant.nameController.text = dto.name ?? ''; // Use name from DTO
      // Ensure parsing handles potential nulls or non-numeric data safely
      variant.priceController.text = (dto.price ?? 0.0).toString(); // Use price from DTO
      variant.quantityController.text = (dto.stockQuantity ?? 0).toString(); // Use stockQuantity from DTO
      // No pickedImage initially when loading existing data
      return variant;
  }

  // Method to dispose controllers
  void disposeControllers() {
    nameController.dispose();
    priceController.dispose();
    quantityController.dispose();
  }

   // Helper to check if this variant has a valid image source (either picked or uploaded)
  bool hasImage() {
      return pickedImage != null || (defaultImageUrl != null && defaultImageUrl!.isNotEmpty);
  }
}

// Widget for Variant Input - Used within AddUpdateProductScreen
// (Defining it here as per your provided code structure)
class VariantInput extends StatelessWidget {
  final Variant variant; // Pass the Variant object directly
  final VoidCallback onPickImage;
  final VoidCallback onRemove;
  final bool isRemovable;
  final bool isProcessing; // Receive processing state from parent
  // Receive the builder function for image display from parent
  final Widget Function(dynamic source, {double size, double iconSize, BoxFit fit}) imageDisplayBuilder;

  const VariantInput({
    Key? key, // Use Key for proper list item management
    required this.variant,
    required this.onPickImage,
    required this.onRemove,
    required this.isRemovable,
    required this.isProcessing, // Add to constructor
    required this.imageDisplayBuilder, // Add to constructor
  }) : super(key: key); // Pass key to super

  @override
  Widget build(BuildContext context) {

    // Determine the source for this variant's image display (prioritize PickedImage for review)
    final dynamic variantImageSource = variant.pickedImage ?? variant.defaultImageUrl;

     if (kDebugMode) {
         // print('[VariantInput] Building image for variant ${variant.nameController.text}. Source: $variantImageSource (Type: ${variantImageSource?.runtimeType})');
     }


    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Biến thể', style: TextStyle(fontWeight: FontWeight.bold)), // Added const
                if (isRemovable) // Only show remove button if there's more than 1 variant
                  IconButton(
                    // Disable remove if processing OR if this variant's image is currently uploading
                    onPressed: (isProcessing || (variant.pickedImage != null && variant.pickedImage!.isUploading)) ? null : onRemove,
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red), // Added const
                    tooltip: 'Xóa biến thể',
                  ),
              ],
            ),
            const SizedBox(height: 8), // Added const

            Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                  const Text('Ảnh biến thể:', style: TextStyle(fontSize: 14)), // Added const
                  const SizedBox(height: 4), // Added const
                   Stack( // Use Stack for potential remove button/indicator
                      children: [
                         GestureDetector(
                            // Disable tap if processing OR if this variant's image is currently uploading
                            onTap: (isProcessing || (variant.pickedImage != null && variant.pickedImage!.isUploading)) ? null : onPickImage,
                            child: Container(
                               width: 80,
                               height: 80,
                               decoration: BoxDecoration(
                                 borderRadius: BorderRadius.circular(8),
                                 color: Colors.grey[200],
                                  // Indicate missing image visually if needed for validation clarity
                                  border: !variant.hasImage() ? Border.all(color: Colors.red, width: 1) : null,
                               ),
                               clipBehavior: Clip.antiAlias,
                               // Use the provided imageDisplayBuilder to display the source
                               child: imageDisplayBuilder(variantImageSource, size: 80, iconSize: 30),
                            ),
                         ),
                         // Show remove button for variant image only if a source exists and not processing globaly
                         // Note: Removing variant removes the image with it, this is for clearing the image on the variant.
                         // Decided to NOT add a remove image button per variant for simplicity unless explicitly requested.
                         // If you need a remove button for variant images, similar logic to main images is needed.
                      ]
                   ),
               ],
            ),
             const SizedBox(height: 16), // Added const


            TextFormField(
              controller: variant.nameController,
              decoration: const InputDecoration(labelText: 'Tên biến thể (ví dụ: Xanh, Đỏ, S/M/L)'), // Added const
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên biến thể';
                }
                return null;
              },
               enabled: !isProcessing, // Disable when processing
            ),
            const SizedBox(height: 16), // Added const

            TextFormField(
              controller: variant.priceController,
              decoration: const InputDecoration(labelText: 'Giá'), // Added const
              keyboardType: const TextInputType.numberWithOptions(decimal: true), // Added const
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập giá';
                }
                final price = double.tryParse(value.trim());
                if (price == null || price < 0) {
                  return 'Giá phải là số hợp lệ (>= 0)';
                }
                return null;
              },
               enabled: !isProcessing, // Disable when processing
            ),
            const SizedBox(height: 16), // Added const

            TextFormField(
              controller: variant.quantityController,
              decoration: const InputDecoration(labelText: 'Số lượng tồn kho'), // Added const
              keyboardType: TextInputType.number,
              validator: (value) {
                 if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập số lượng';
                }
                 final quantity = int.tryParse(value.trim());
                 if (quantity == null || quantity < 0) {
                  return 'Số lượng phải là số nguyên hợp lệ (>= 0)';
                }
                return null;
              },
               enabled: !isProcessing, // Disable when processing
            ),
          ],
        ),
      ),
    );
  }
}


class AddUpdateProductScreen extends StatefulWidget {
  // If product is not null, we are in update mode (data format is Map<String, dynamic>)
  // We expect this Map to contain AT LEAST the product 'id'.
  // Using ProductDTO here would be cleaner, but sticking to Map for now as per existing usage.
  final Map<String, dynamic>? product;

  const AddUpdateProductScreen({Key? key, this.product}) : super(key: key);

  @override
  _AddUpdateProductScreenState createState() => _AddUpdateProductScreenState();
}

class _AddUpdateProductScreenState extends State<AddUpdateProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields (Main Product)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();

  // State for image selection (Main Product)
  // Holds the FINAL server RELATIVE path for default image (either initial or uploaded)
  String? _defaultImageUrl; // Stores the relative path from server response (e.g., "/uploads/...")
  // Holds the LOCALLY PICKED image data for default image (while uploading)
  PickedImage? _defaultPickedImage;

  // This list will hold a mix of String (server RELATIVE Paths) and PickedImage (local data pending upload)
  final List<dynamic> _additionalImages = [];

  final ImagePicker _picker = ImagePicker();

  // State for dropdowns (Main Product) - Use DTO types
  BrandDTO? _selectedBrand;
  // Lấy danh sách từ AppDataService singleton - Sử dụng getter .brands
  // Assuming AppDataService().brands and .categories are populated asynchronously before this screen is shown
  // or handled by the AppDataService().isInitialized check in build.
  final List<BrandDTO> _brands = AppDataService().brands;

  CategoryDTO? _selectedCategory;
  final List<CategoryDTO> _categories = AppDataService().categories;

  // State for variants
  final List<Variant> _variants = [];

  // Processing states
  bool _isProcessing = false; // General processing (e.g., saving/updating)
  bool _isLoadingInitialData = true; // Loading product data in edit mode
  String? _errorLoadingInitialData; // Error message if initial load fails


  // Instance of ProductService
  final ProductService _productService = ProductService();


  @override
  void initState() {
    super.initState();

    // Check if AppDataService is initialized. If not, we might need to wait or show a different loading state.
    // For now, we'll show a basic loading screen in build if not initialized.

    // Load product data if in update mode
    // Check if widget.product is provided AND has an 'id' field
    if (widget.product != null && widget.product!.containsKey('id') && widget.product!['id'] != null) {
       // Safely attempt to cast the id to int
       final dynamic productIdDynamic = widget.product!['id'];
       if (productIdDynamic is int) {
           final int productId = productIdDynamic;
           if (kDebugMode) print('Edit mode: Initializing load for product ID $productId');
           _loadProductDataForEdit(productId); // Call async load function
       } else {
           // Handle case where ID is provided but not an int (shouldn't happen if data is correct)
           _isLoadingInitialData = false; // Not loading initial data, but can't edit
           _errorLoadingInitialData = 'Lỗi: ID sản phẩm không hợp lệ.';
           if (kDebugMode) print('Error: Provided product ID is not an integer: $productIdDynamic');
       }
    } else {
       // Not in edit mode (new product) or no ID provided for edit
       _isLoadingInitialData = false; // Not loading initial data, ready to build form
       if (kDebugMode) print('Add mode: Initializing with default empty state.');
       // Add initial variants for new product (exactly 2 as requested)
       _addVariant();
       _addVariant();
    }
  }

  @override
  void dispose() {
    // Dispose controllers
    _nameController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    for (var variant in _variants) {
      variant.disposeControllers();
    }
    // Dispose ProductService httpClient
    _productService.dispose();
    super.dispose();
  }

  // --- Function to load product data for editing ---
  Future<void> _loadProductDataForEdit(int productId) async {
      if (!mounted) return; // Ensure widget is still mounted before setting state

      setState(() {
         _isLoadingInitialData = true; // Start loading state
         _errorLoadingInitialData = null; // Clear previous errors
      });

      try {
         // Call API to get full product details by ID
         final ProductDTO fetchedProduct = await _productService.getProductById(productId);
         if (kDebugMode) print('Product data fetched successfully for ID $productId');

         if (!mounted) return; // Ensure widget is still mounted after async call


         // --- Populate UI state with fetched data ---
         _nameController.text = fetchedProduct.name;
         _descriptionController.text = fetchedProduct.description;
         // Ensure discount is treated as double, default to 0.0 if null from API
         _discountController.text = (fetchedProduct.discountPercentage ?? 0.0).toString();


         // Set Brand dropdown
         // Find the BrandDTO in the pre-loaded list by matching ID
         if (_brands.isNotEmpty && fetchedProduct.brandName != null) { // Match by ID
              _selectedBrand = _brands.firstWhereOrNull(
                 (brand) => brand.name== fetchedProduct.brandName,
              );
               if (kDebugMode) {
                 print('Attempting to set selected brand. Fetched brandId: ${fetchedProduct.brandName}. Found brand: ${_selectedBrand?.name} (ID: ${_selectedBrand?.id})');
               }
         } else {
              _selectedBrand = null;
              if (kDebugMode) print('Brands list is empty or no brandId in fetched data. Cannot set selected brand.');
         }


         // Set Category dropdown
         // Find the CategoryDTO in the pre-loaded list by matching ID
         if (_categories.isNotEmpty && fetchedProduct.categoryName != null) { // Match by ID
             _selectedCategory = _categories.firstWhereOrNull(
                (category) => category.name == fetchedProduct.categoryName,
             );
             if (kDebugMode) {
                print('Attempting to set selected category. Fetched categoryId: ${fetchedProduct.categoryName}. Found category: ${_selectedCategory?.name} (ID: ${_selectedCategory?.id})');
             }
         } else {
             _selectedCategory = null;
             if (kDebugMode) print('Categories list is empty or no categoryId in fetched data. Cannot set selected category.');
         }


         // Set initial images (assuming API returns RELATIVE paths like "/api/images/...")
         // Store these RELATIVE paths. Conversion to FULL URL is for DISPLAY ONLY in _buildImageDisplayWidget.
         _defaultImageUrl = fetchedProduct.mainImageUrl; // Store relative path from DTO
         _additionalImages.clear(); // Clear any default empty list added initially
         if (fetchedProduct.imageUrls != null && fetchedProduct.imageUrls!.isNotEmpty) {
              // Add additional image RELATIVE paths from DTO
             _additionalImages.addAll(fetchedProduct.imageUrls!);
         }
         if (kDebugMode) print('Initial images loaded. Default: $_defaultImageUrl, Additional: ${_additionalImages.length}');


         // Set initial variants from fetched data (assuming API provides List<ProductVariantDTO>)
         _variants.clear(); // Clear any default variants added initially
         if (fetchedProduct.variants != null && fetchedProduct.variants!.isNotEmpty) {
            // Convert ProductVariantDTOs to Variant objects for the form state
            _variants.addAll(fetchedProduct.variants!.map((dto) => Variant.fromProductVariantDTO(dto)).toList());
             if (kDebugMode) print('Loaded ${_variants.length} variants from fetched data.');
         } else {
             // If no variants returned by API, add default ones for editing (as per requirement)
             _addVariant();
             _addVariant();
              if (kDebugMode) print('No variants in fetched data. Added 2 default empty variants.');
         }

         // Call setState to update the UI with loaded data
         if(mounted) {
             setState(() {
                 _isLoadingInitialData = false; // Loading finished successfully
             });
         }


      } catch (e) {
         if (kDebugMode) print('Error loading product data for ID $productId: $e');
         // Handle error during fetch
         if(mounted) {
             setState(() {
                 _errorLoadingInitialData = 'Không thể tải thông tin sản phẩm: ${e.toString()}';
                 _isLoadingInitialData = false; // Loading finished (with error)
             });
              // Show error message using Snackbar (optional, as error screen is shown)
             ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(
                     content: Text(_errorLoadingInitialData!),
                     backgroundColor: Colors.red,
                     duration: const Duration(seconds: 5), // Show error longer
                 ),
             );
         }
          // Optionally navigate back if loading fails severely
          // if(mounted) Navigator.pop(context, false); // Indicate failure
      }
  }


  // Function to pick, read bytes, and initiate upload for main product images
  Future<void> _pickAndUploadImage(bool isDefault) async {
     // Prevent picking if already processing globally
    if (_isProcessing) return;

     // Check if an image is already pending or uploading for this spot
     if (isDefault) {
       if (_defaultPickedImage != null && _defaultPickedImage!.isUploading) {
         if (kDebugMode) print('Default image upload already in progress.'); return;
       }
     } else {
        // Check if any additional image is already pending/uploading
        if (_additionalImages.any((item) => item is PickedImage && item.isUploading)) {
             if (kDebugMode) print('Additional image upload already in progress.'); return;
         }
     }


    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
       PickedImage? picked; // Declare variable outside try

       try {
          final imageBytes = await pickedFile.readAsBytes();
          final fileName = pickedFile.name;

          if (kDebugMode) print('Picked image: ${fileName}, bytes length: ${imageBytes.length}');
          if (imageBytes.isEmpty) throw Exception('Không đọc được dữ liệu ảnh.');

          // Create PickedImage object and mark it as uploading
          picked = PickedImage(bytes: imageBytes, fileName: fileName, isUploading: true);

          // Use addPostFrameCallback to update the UI AFTER the current build frame finishes
          // This prevents calling setState while the build method is still running.
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) { // Check if the widget is still in the widget tree
               setState(() {
                   if (isDefault) {
                       _defaultPickedImage = picked; // Show the local image preview and indicator
                       _defaultImageUrl = null; // Temporarily clear the previous server URL
                   } else {
                       _additionalImages.add(picked); // Add the local image preview and indicator to the list
                   }
               });
               // Show a transient Snackbar indicating upload started
               ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text('Đang tải ảnh lên: ${picked!.fileName}'), duration: const Duration(seconds: 2)),
               );
            }
          });

          // *** CALL UPLOAD API ***
          // Await the upload Future. This is where the UI thread is blocked if not using async/await properly,
          // but because this function is `async`, the framework handles the blocking.
          final String? imageRelativePath = await _productService.uploadImage(picked.bytes, picked.fileName);
          if (kDebugMode) print('Image RELATIVE path returned from upload: $imageRelativePath');

          // Hide the "Uploading" Snackbar
          if(mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();

          // Use another addPostFrameCallback to update the UI state based on the upload result
          SchedulerBinding.instance.addPostFrameCallback((_) {
             if (mounted) {
                 setState(() {
                     // Find the *current* PickedImage object in the state that corresponds to the 'picked' one
                     // (State might have changed since the first setState)
                     PickedImage? currentPickedState;
                     if (isDefault) {
                        currentPickedState = _defaultPickedImage;
                     } else {
                        // Find the specific PickedImage instance in the additional images list
                        // Use .firstWhereOrNull from collection package
                        currentPickedState = _additionalImages.firstWhereOrNull((item) => item == picked && item is PickedImage) as PickedImage?;
                     }

                     // Ensure we are updating the state for the image that was just picked/uploaded
                     if (currentPickedState != null) {
                          currentPickedState.isUploading = false; // Mark this specific image as no longer uploading

                         if (imageRelativePath != null && imageRelativePath.isNotEmpty) {
                            // UPLOAD SUCCESS:
                            // Replace the local PickedImage object in the state with the server path string
                            if (isDefault) {
                                _defaultImageUrl = imageRelativePath; // <-- Store the returned RELATIVE path here
                                _defaultPickedImage = null; // Clear the local data
                            } else {
                                // Find the index of the specific PickedImage object
                                final index = _additionalImages.indexOf(currentPickedState); // Find by reference
                                if (index != -1) {
                                   _additionalImages[index] = imageRelativePath; // <-- Replace it with the RELATIVE path String
                                } else {
                                    // Fallback - should not happen with correct state management
                                    if (kDebugMode) print('Error: Could not find PickedImage object to replace with URL after upload.');
                                    _additionalImages.add(imageRelativePath); // Just add the path if not found
                                }
                            }
                            if (kDebugMode) print('Upload successful. State updated with RELATIVE path.');
                             ScaffoldMessenger.of(context).showSnackBar(
                                // Added const
                               const SnackBar(content: Text('Tải ảnh lên thành công'), backgroundColor: Colors.green),
                            );
                         } else {
                             // UPLOAD FAILURE (Server didn't return a path or returned empty):
                             if (kDebugMode) print('Upload failed: Server returned empty path for .');
                             // Just clear the local PickedImage object (it's already marked isUploading=false)
                             if (isDefault) { if (_defaultPickedImage == currentPickedState) _defaultPickedImage = null; } // Check if it's still the active default image
                             else _additionalImages.remove(currentPickedState); // Remove local image
                             ScaffoldMessenger.of(context).showSnackBar(
                               // Added const
                               const SnackBar(content: Text('Tải ảnh lên thất bại: Server không trả về đường dẫn ảnh.'), backgroundColor: Colors.red),
                             );
                         }
                     } else {
                         // This case happens if the PickedImage object was removed from state *while* the upload was in progress
                         // (e.g., user pressed remove button very fast).
                         if (kDebugMode) print('Upload finished but PickedImage object ${picked?.fileName} was already removed from state.');
                         // No state update needed here as the state was already handled by the remove action.
                     }
                 });
             }
          });


       } catch (e) {
          // Handle any exceptions during picking, reading, or uploading
          if (kDebugMode) print('Upload failed due to exception: $e');

           // Use addPostFrameCallback to update the UI state on failure
           SchedulerBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                 setState(() {
                     if (picked != null) { // Ensure picked object was created in the try block
                        // Find the PickedImage object corresponding to the failed upload
                        PickedImage? currentPickedState;
                        if (isDefault) {
                           currentPickedState = _defaultPickedImage;
                        } else {
                           currentPickedState = _additionalImages.firstWhereOrNull((item) => item == picked && item is PickedImage) as PickedImage?;
                        }

                        if (currentPickedState != null) {
                           currentPickedState.isUploading = false; // Mark as not uploading
                           // Clear the local PickedImage object from the state on failure
                           if (isDefault) { if (_defaultPickedImage == currentPickedState) _defaultPickedImage = null; } // Check if it's still the active default
                           else _additionalImages.remove(currentPickedState); // Remove from list by reference
                        } else {
                             if (kDebugMode) print('Upload failed due to exception, but PickedImage object ${picked?.fileName} was already removed from state.');
                        }
                     }
                 });
                 // Hide the "Uploading" Snackbar if it's still showing
                 if(mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text('Tải ảnh lên thất bại: ${e.toString()}'), backgroundColor: Colors.red),
                 );
              }
           });
       }
    }
  }

  // Function to pick, read bytes, and initiate upload for a variant image
  Future<void> _pickAndUploadVariantImage(Variant variant) async {
    if (_isProcessing) return;
    if (variant.pickedImage != null && variant.pickedImage!.isUploading) {
        if (kDebugMode) print('Variant image upload already in progress.'); return;
    }

    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
       PickedImage? picked; // Declare variable outside try

       try {
           final imageBytes = await pickedFile.readAsBytes();
           final fileName = pickedFile.name;

           if (kDebugMode) print('Picked variant image: ${fileName}, bytes length: ${imageBytes.length}');
           if (imageBytes.isEmpty) throw Exception('Không đọc được dữ liệu ảnh biến thể.');

           picked = PickedImage(bytes: imageBytes, fileName: fileName, isUploading: true);

           SchedulerBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                  setState(() {
                      variant.pickedImage = picked; // Show local preview and indicator for this variant
                      variant.defaultImageUrl = null; // Clear previous server URL for this variant
                  });
                   ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Đang tải ảnh biến thể lên: ${picked!.fileName}'), duration: const Duration(seconds: 2)),
                   );
              }
           });

           // *** CALL UPLOAD API ***
           final String? imageRelativePath = await _productService.uploadImage(picked.bytes, picked.fileName);
           if (kDebugMode) print('Variant Image RELATIVE path returned from upload: $imageRelativePath');

           if(mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide "Uploading" Snackbar

           SchedulerBinding.instance.addPostFrameCallback((_) {
             if (mounted) {
                 // Find the variant again in case the list changed. Check if the picked image is still associated with it.
                 final currentVariantState = _variants.firstWhereOrNull((v) => v == variant); // Find by reference
                 if (currentVariantState != null && currentVariantState.pickedImage == picked) {
                      currentVariantState.pickedImage!.isUploading = false; // Mark as not uploading


                      if (imageRelativePath != null && imageRelativePath.isNotEmpty) {
                         // SUCCESS: Replace PickedImage with the server path string for this variant
                         currentVariantState.defaultImageUrl = imageRelativePath; // <-- Store the RELATIVE path here
                         currentVariantState.pickedImage = null; // Clear local data
                          if (kDebugMode) print('Variant upload successful. State updated with RELATIVE path.');
                           ScaffoldMessenger.of(context).showSnackBar(
                             // Added const
                           const SnackBar(content: Text('Tải ảnh biến thể lên thành công'), backgroundColor: Colors.green),
                         );
                     } else {
                          // FAILURE: Server returned empty path
                           if (kDebugMode) print('Variant upload failed: Server returned empty path for.');
                          // Clear the local PickedImage object for this variant
                          currentVariantState.pickedImage = null;
                           ScaffoldMessenger.of(context).showSnackBar(
                             // Added const
                             const SnackBar(content: Text('Tải ảnh biến thể lên thất bại: Server không trả về đường dẫn ảnh.'), backgroundColor: Colors.red),
                           );
                     }
                      // Trigger rebuild after state change for this variant
                     setState(() {});
                 } else { // Variant state changed (e.g., variant removed), handle PickedImage cleanup if needed
                     if (picked != null && !picked.isUploading) { // If the specific picked image object is still around and not marked uploading
                          // Log that an upload completed but the state changed, nothing to do with UI
                         if (kDebugMode) print('Variant upload finished for ${picked.fileName} but variant state changed or variant was removed.');
                     }
                 }
             }
           });

       } catch (e) {
            if (kDebugMode) print('Variant upload failed due to exception: $e');
            SchedulerBinding.instance.addPostFrameCallback((_) {
               if (mounted) {
                    // Find the variant again and check if the picked image is still associated
                    final currentVariantState = _variants.firstWhereOrNull((v) => v == variant);
                    if (currentVariantState != null && currentVariantState.pickedImage == picked) {
                        if (picked != null) picked.isUploading = false; // Mark as not uploading
                        currentVariantState.pickedImage = null; // Clear local data on failure
                        // Trigger rebuild
                        setState(() {});
                    } else {
                        if (picked != null && !picked.isUploading) {
                            if (kDebugMode) print('Variant upload failed due to exception for ${picked.fileName}, but variant state changed or variant was removed.');
                        }
                    }
                   if(mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text('Tải ảnh biến thể lên thất bại: ${e.toString()}'), backgroundColor: Colors.red),
                   );
               }
            });
       }
    }
  }


  // Function to remove an additional image (handles both URL String and PickedImage)
  void _removeAdditionalImage(dynamic imageSource) {
    // Prevent removal if processing or if this specific image is uploading
    if (_isProcessing || (imageSource is PickedImage && imageSource.isUploading)) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Không thể xóa ảnh đang tải lên.')), // Added const
       );
       return;
    }
    setState(() {
       if (kDebugMode) print('Removing additional image source: $imageSource');
       // Remove by object reference (for PickedImage) or value equality (for String)
      _additionalImages.remove(imageSource);
    });
  }

   // Function to remove the default image (handles both URL String and PickedImage)
  void _removeDefaultImage() {
    // Prevent removal if processing or if the default image is uploading
    if (_isProcessing || (_defaultPickedImage != null && _defaultPickedImage!.isUploading)) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Không thể xóa ảnh đang tải lên.')), // Added const
       );
       return;
    }
     setState(() {
        if (kDebugMode) print('Removing default image. Current source: ${_defaultPickedImage ?? _defaultImageUrl}');
        _defaultImageUrl = null; // Clear the server path state
        _defaultPickedImage = null; // Clear the local PickedImage state
     });
  }


  // Function to add a new variant
  void _addVariant() {
    if (_isProcessing) return;
    // Prevent adding variant if any variant image is still uploading
    if (_variants.any((v) => v.pickedImage != null && v.pickedImage!.isUploading)) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Vui lòng chờ các ảnh biến thể khác tải lên xong.')), // Added const
       );
       return;
    }
    setState(() {
      // Create a new Variant object, initially with no image URL and no originalId
      _variants.add(Variant());
    });
     // Optional: Scroll to the newly added variant for better UX
     SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && _formKey.currentContext != null) {
            Scrollable.ensureVisible(
               _formKey.currentContext!, // Use the form's context
               alignment: 1.0, // Scroll to the bottom edge of the target
               duration: const Duration(milliseconds: 300),
               curve: Curves.easeOutCubic,
            );
        }
     });
  }

  // Function to remove a variant
  void _removeVariant(int index) {
     // Prevent removal if processing or if this specific variant's image is uploading
     if (_isProcessing || (_variants[index].pickedImage != null && _variants[index].pickedImage!.isUploading)) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Không thể xóa biến thể khi ảnh đang tải lên.')), // Added const
       );
       return;
     }
    _variants[index].disposeControllers(); // Dispose controllers
    setState(() {
      if (kDebugMode) print('Removing variant at index $index');
      _variants.removeAt(index);
    });
  }

  // Function to handle form submission (Calls createProduct or updateProduct API)
  void _submitForm() async {
    // Prevent multiple submissions if already processing globaly
    if (_isProcessing) return;

    // --- Pre-Check: Ensure all images are uploaded ---
    // Check if any PickedImage object still exists anywhere in the state
    final bool anyImageUploading = (_defaultPickedImage != null && _defaultPickedImage!.isUploading) ||
                                    _additionalImages.any((item) => item is PickedImage && item.isUploading) ||
                                    _variants.any((v) => v.pickedImage != null && v.pickedImage!.isUploading);

    if (anyImageUploading) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Vui lòng chờ tất cả ảnh tải lên xong trước khi gửi.')), // Added const
       );
       if (kDebugMode) print('Submission blocked: Images still uploading.');
       return;
    }

    // --- Step 1: Validate main form fields (TextFormFields and Dropdowns) ---
    // This triggers the validator functions on the TextFormFields and DropdownButtonFormFields.
    // Validators in VariantInput are also checked via this form validation.
    if (!_formKey.currentState!.validate()) {
      // Validation messages will appear next to the fields
      if (kDebugMode) print('Main form validation failed.');
      return;
    }

    // --- Step 2: Validate items not covered by _formKey (Images and Variants existence) ---

    // Basic validation for main image URL existence (now stores relative path)
    // This check is redundant if the Default Image GestureDetector has a red border validator logic
    // but keeping it here for final submission check safety.
    if (_defaultImageUrl == null || _defaultImageUrl!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng chọn ảnh mặc định cho sản phẩm chính.')), // Added const
        );
         if (kDebugMode) print('Validation failed: Default image missing.');
        return;
    }

    // Basic validation for at least one variant
     if (_variants.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Vui lòng thêm ít nhất một biến thể')), // Added const
         );
         if (kDebugMode) print('Validation failed: No variants added.');
         return;
     }

      // --- Step 3: Validate individual variant details (including images) ---
      // This repeats validation already in VariantInput's validator, but ensures
      // the *current* state is checked one last time before sending to API.
     bool areVariantsCompletelyValid = true;
     String variantValidationMessage = '';

     for (int i = 0; i < _variants.length; i++) {
         final variant = _variants[i];
         // Check TextFormFields value explicitly, including trimming for 'blank' check
         if (variant.nameController.text.trim().isEmpty) {
             areVariantsCompletelyValid = false;
             variantValidationMessage = 'Biến thể ${i + 1}: Vui lòng nhập tên.';
             break;
         }
         final priceText = variant.priceController.text.trim();
         final quantityText = variant.quantityController.text.trim();

         if (priceText.isEmpty) {
             areVariantsCompletelyValid = false;
             variantValidationMessage = 'Biến thể ${i + 1}: Vui lòng nhập giá.';
             break;
         }
          final price = double.tryParse(priceText);
         if (price == null || price < 0) {
             areVariantsCompletelyValid = false;
             variantValidationMessage = 'Biến thể ${i + 1}: Giá phải là số hợp lệ (>= 0).';
             break;
         }

         if (quantityText.isEmpty) {
            areVariantsCompletelyValid = false;
             variantValidationMessage = 'Biến thể ${i + 1}: Vui lòng nhập số lượng tồn kho.';
             break;
         }
         final quantity = int.tryParse(quantityText);
          if (quantity == null || quantity < 0) {
             areVariantsCompletelyValid = false;
             variantValidationMessage = 'Biến thể ${i + 1}: Số lượng phải là số nguyên hợp lệ (>= 0).';
             break;
         }

          // Validate variant image paths (must be a non-empty string after upload)
          // It's guaranteed to be a String (RELATIVE path) if upload was successful and no PickedImage remains.
         if (variant.defaultImageUrl == null || variant.defaultImageUrl!.isEmpty) {
             areVariantsCompletelyValid = false;
             variantValidationMessage = 'Biến thể ${i + 1}: Vui lòng chọn ảnh.';
             break;
         }
     }

     if (!areVariantsCompletelyValid) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(variantValidationMessage)),
         );
         if (kDebugMode) print('Validation failed: Variant details missing or invalid.');
         return;
     }


    // --- If all validation passes, proceed with processing ---
    if (kDebugMode) print('All validation passed. Proceeding to submission.');
    setState(() {
      _isProcessing = true; // Set state to show loading and block interaction
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0), // Added const
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(), // Added const
                const SizedBox(width: 20), // Added const
                Text(widget.product == null ? "Đang tạo sản phẩm..." : "Đang cập nhật sản phẩm..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Collect all additional image paths (filter out any lingering PickedImage objects, though pre-check should handle this)
      final List<String> additionalImagePaths = _additionalImages.whereType<String>().toList();


      if (widget.product == null) {
          // --- Create Product ---
          List<CreateProductVariantDTO> createVariantDTOs = _variants.map((variant) {
              // defaultImageUrl is guaranteed non-null by validation above
              return CreateProductVariantDTO(
                  name: variant.nameController.text.trim(),
                  price: double.parse(variant.priceController.text.trim()), // Parse after trimming
                  stockQuantity: int.parse(variant.quantityController.text.trim()), // Parse after trimming
                  variantImageUrl: variant.defaultImageUrl!, // RELATIVE path (validated non-null/empty)
              );
          }).toList();

          CreateProductRequestDTO productRequest = CreateProductRequestDTO(
             name: _nameController.text.trim(),
             description: _descriptionController.text.trim(),
             categoryId: _selectedCategory!.id!, // Guaranteed non-null by _formKey validation
             brandId: _selectedBrand!.id!,     // Guaranteed non-null by _formKey validation
             mainImageUrl: _defaultImageUrl!, // RELATIVE path, guaranteed non-null by manual validation
             imageUrls: additionalImagePaths, // List of RELATIVE paths
             discountPercentage: double.tryParse(_discountController.text.trim()),
             variants: createVariantDTOs,
          );

           if (kDebugMode) print('Calling createProduct with data: ${productRequest.toJson()}');
           await _productService.createProduct(productRequest); // Call the actual API

       } else {
          // --- Update Product ---
          final dynamic productIdDynamic = widget.product!['id'];
          final int? productId = productIdDynamic is int ? productIdDynamic : null;

          if (productId == null) {
               if(mounted) Navigator.of(context).pop(); // Dismiss loading dialog
               throw Exception('Product ID is missing or invalid for update.');
          }

          List<UpdateProductVariantDTO> updateVariantDTOs = _variants.map((variant) {
               // defaultImageUrl is guaranteed non-null by validation above
               return UpdateProductVariantDTO(
                  id: variant.originalId, // Include original ID (null for newly added variants during edit)
                  name: variant.nameController.text.trim(),
                  price: double.parse(variant.priceController.text.trim()), // Parse after trimming
                  stockQuantity: int.parse(variant.quantityController.text.trim()), // Parse after trimming
                  variantImageUrl: variant.defaultImageUrl!, // RELATIVE path (validated non-null/empty)
               );
          }).toList();

          // Use the id from the selected DTO objects for brand/category (guaranteed non-null by _formKey validator)
          UpdateProductRequestDTO productRequest = UpdateProductRequestDTO(
             name: _nameController.text.trim(),
             description: _descriptionController.text.trim(),
             categoryId: _selectedCategory!.id!,
             brandId: _selectedBrand!.id!,
             mainImageUrl: _defaultImageUrl!, // RELATIVE path (validated non-null/empty)
             imageUrls: additionalImagePaths, // List of RELATIVE paths
             discountPercentage: double.tryParse(_discountController.text.trim()),
             variants: updateVariantDTOs,
          );

          if (kDebugMode) print('Calling updateProduct for ID $productId with data: ${productRequest.toJson()}');
          await _productService.updateProduct(productId, productRequest); // Call the actual API
       }

      // --- Handle Success ---
      if(mounted) Navigator.of(context).pop(); // Dismiss loading dialog
      if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.product == null ? 'Tạo sản phẩm thành công!' : 'Cập nhật sản phẩm thành công!'),
              backgroundColor: Colors.green,
            ),
          );
      }
       // Navigate back, indicating success to the previous screen (ProductScreen)
       if(mounted) Navigator.pop(context, true);


    } catch (e) {
      // --- Handle Error ---
      if(mounted) Navigator.of(context).pop(); // Dismiss loading dialog
      if (kDebugMode) print('Error during product submission: $e');
       if(mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('Có lỗi xảy ra: ${e.toString()}'),
               backgroundColor: Colors.red,
             ),
           );
       }
    } finally {
       // Reset Processing State regardless of success/failure
       if(mounted) {
            setState(() {
              _isProcessing = false;
            });
       }
       // Ensure any isUploading flags on PickedImage objects are reset in case
       // the state update logic somehow missed one or hit an exception *before*
       // the state could be fully updated. This is a defensive cleanup.
       if (_defaultPickedImage != null) _defaultPickedImage!.isUploading = false;
       for (var item in List.from(_additionalImages.whereType<PickedImage>())) { // Iterate over a copy
          item.isUploading = false;
       }
       for (var variant in _variants) {
         if (variant.pickedImage != null) variant.pickedImage!.isUploading = false;
       }
    }
  }

  // Helper to build image widget from source (Handles PickedImage, server RELATIVE path String, or Placeholder)
  // This function is passed down to VariantInput as imageDisplayBuilder
  // This function is defined once in the _AddUpdateProductScreenState class.
  Widget _buildImageDisplayWidget(dynamic source, {double size = 40, double iconSize = 40, BoxFit fit = BoxFit.cover}) {
    // Check if ProductService instance is available before calling getImageUrl
    // This check is mainly defensive, _productService should be initialized in initState
    if (_productService == null) {
        if (kDebugMode) print('[_buildImageDisplayWidget] Error: ProductService is null.');
        return const Icon(Icons.error, size: 40, color: Colors.purple); // Added const
    }

    if (kDebugMode) {
       // print('[_buildImageDisplayWidget] Received source: $source (Type: ${source?.runtimeType})');
    }

    if (source == null || (source is String && source.isEmpty)) {
      return Icon(Icons.camera_alt, size: iconSize, color: Colors.grey); // Placeholder
    }

    if (source is PickedImage) {
      // Display locally picked image bytes with potential upload indicator
      return Stack(
         fit: StackFit.expand,
         children: [
            Image.memory(
               source.bytes,
               fit: fit,
               // Add errorBuilder to log issues with Image.memory
               errorBuilder: (context, error, stackTrace) {
                  if (kDebugMode) print('[_buildImageDisplayWidget] Image.memory failed for ${source.fileName}: $error');
                  return Container(color: Colors.orangeAccent.withOpacity(0.5), child: Icon(Icons.warning_amber, size: iconSize * 0.8, color: Colors.deepOrange));
               },
            ),
            // Show circular progress indicator centered over the image while uploading
            if (source.isUploading)
               Positioned.fill( // Make the overlay fill the entire image area
                   child: Container(
                      color: Colors.black54, // Semi-transparent overlay
                      child: Center( // Center the indicator
                         child: SizedBox( // Give the indicator a fixed size
                            width: size * 0.5, // Make indicator size relative to image size
                            height: size * 0.5,
                            child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2), // Added const
                         ),
                      ),
                   ),
               ),
         ],
      );
    } else if (source is String) { // It's a server relative path (e.g., "/uploads/...")
       // Use the helper function from ProductService to get the guaranteed FULL URL for network loading
       final fullImageUrl = _productService.getImageUrl(source);

       if (kDebugMode) {
         // print('[_buildImageDisplayWidget] Using FULL URL for Image.network: $fullImageUrl (Original relative path: $source)');
       }

      return Image.network(
        fullImageUrl,
        fit: fit,
        // Add loading builder for network images
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox( // Use SizedBox to prevent layout changes during loading
              width: size * 0.5, // Make indicator size relative to image size
              height: size * 0.5,
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2, // Thinner stroke for smaller indicator
              ),
            ),
          );
        },
        // Add error builder for network images
        errorBuilder: (context, error, stackTrace) {
          if (kDebugMode) {
            print('[_buildImageDisplayWidget] Image.network failed for $fullImageUrl (Original: $source): $error');
          }
          // Show broken image icon if network image fails
          return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
        },
      );

    } else {
        // Fallback for unexpected types
        if (kDebugMode) print('[_buildImageDisplayWidget] Unexpected source type: ${source?.runtimeType}');
         return const Icon(Icons.error, size: 40, color: Colors.purple); // Added const
    }
  }


  // --- State.build method ---
  @override
  Widget build(BuildContext context) {
    // Check if AppDataService (containing brands/categories) is initialized
     if (!AppDataService().isInitialized) {
         // Show a simple loading indicator while data loads
         return Scaffold(
           appBar: AppBar(title: const Text('Đang tải dữ liệu...')), // Added const
           body: const Center(child: CircularProgressIndicator()), // Added const
         );
     }

    // If we are in edit mode and still loading product data, show loading indicator
    // Or if there was an error loading initial data
    if (widget.product != null && (_isLoadingInitialData || _errorLoadingInitialData != null)) {
       return Scaffold(
           appBar: AppBar(title: Text(widget.product == null ? 'Thêm Sản phẩm' : 'Cập nhật Sản phẩm')),
           body: Center(
               child: Padding(
                   padding: const EdgeInsets.all(16.0), // Added const
                   child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                           if (_isLoadingInitialData) const CircularProgressIndicator(), // Added const
                           if (_isLoadingInitialData) const SizedBox(height: 16), // Added const
                           // Show error message if available during loading
                           Text(_errorLoadingInitialData ?? 'Vui lòng chờ...'),
                            if (_errorLoadingInitialData != null) const SizedBox(height: 16), // Added const
                           if (_errorLoadingInitialData != null)
                              ElevatedButton(
                                onPressed: () {
                                  // Optionally add a retry mechanism, or just navigate back
                                  Navigator.pop(context, false); // Indicate failure/cancel
                                },
                                child: const Text('Quay lại'), // Added const
                              ),
                       ],
                   ),
               )
           ),
       );
    }

    // Determine the source for the default image display (prioritize PickedImage for review)
    final dynamic defaultImageSource = _defaultPickedImage ?? _defaultImageUrl;


    // Main UI is built only after data is initialized and product data is loaded (if in edit mode)
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Thêm Sản phẩm' : 'Cập nhật Sản phẩm'),
      ),
      // Use AbsorbPointer to block interaction when processing (saving/updating)
      body: AbsorbPointer(
        absorbing: _isProcessing, // Absorb events when _isProcessing is true
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Added const
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // Main Product Info Title
                const Text(
                  'Thông tin Sản phẩm chính:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16), // Added const

                // Product Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Tên sản phẩm'), // Added const
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên sản phẩm';
                    }
                    return null;
                  },
                   enabled: !_isProcessing, // Disable when processing
                ),
                const SizedBox(height: 16), // Added const

                // Default Image (Main Product)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ảnh mặc định (Sản phẩm chính):', style: TextStyle(fontSize: 16)), // Added const
                    const SizedBox(height: 8), // Added const
                    Stack( // Use Stack for potential remove button/indicator
                       children: [
                         GestureDetector(
                            // Disable tap if processing or if an image is already picked/uploading for this slot
                            onTap: (_isProcessing || (defaultImageSource is PickedImage && defaultImageSource.isUploading)) ? null : () => _pickAndUploadImage(true),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[200],
                                // Add red border if default image is required and missing
                                border: (!_isProcessing && (defaultImageSource == null)) // No source means missing
                                    ? Border.all(color: Colors.red, width: 1)
                                    : null,
                              ),
                              clipBehavior: Clip.antiAlias,
                              // Display the stored local or server image source using the helper
                              child: _buildImageDisplayWidget(
                                  defaultImageSource, // Pass the combined source
                                  size: 100,
                                  iconSize: 40,
                                  fit: BoxFit.cover
                                ),
                            ),
                         ),
                         // Show remove button only if an image source exists and not processing globaly AND not currently uploading
                         if (!_isProcessing && defaultImageSource != null && !(defaultImageSource is PickedImage && defaultImageSource.isUploading))
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: _removeDefaultImage, // Call the remove function
                                child: Container(
                                  padding: const EdgeInsets.all(2), // Added const
                                  decoration: const BoxDecoration( // Added const
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.only(
                                          topRight: Radius.circular(8),
                                          bottomLeft: Radius.circular(8),
                                      )
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 14), // Added const
                                ),
                              ),
                            ),
                       ],
                    ),
                     // Display validation error if default image is missing (triggered by _submitForm validator)
                    // Need to check form state *after* validate call for this to work reliably outside build
                    // For simplicity, relying on the snackbar from _submitForm validator might be sufficient UX
                    // if (_formKey.currentState != null && !_formKey.currentState!.validate() && (defaultImageSource == null))
                    //   const Padding( // Added const
                    //     padding: EdgeInsets.only(top: 4.0), // Added const
                    //     child: Text(
                    //       'Vui lòng chọn ảnh mặc định',
                    //       style: TextStyle(color: Colors.red, fontSize: 12), // Added const
                    //     ),
                    //   ),
                  ],
                ),
                const SizedBox(height: 16), // Added const

                // Additional Images (Main Product) - Mix of URLs and PickedImages
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ảnh góc minh họa (Sản phẩm chính, có thể chọn nhiều):', style: TextStyle(fontSize: 16)), // Added const
                    const SizedBox(height: 8), // Added const
                     Wrap(
                       spacing: 8,
                       runSpacing: 8,
                       children: [
                         // Display stored images (mix of String RELATIVE Paths and PickedImage objects)
                         ..._additionalImages.map((imageSource) {
                             return Stack(
                                // Use a unique key for each item in the list to help Flutter manage state
                                // This is useful when adding/removing items dynamically
                                key: imageSource is PickedImage ? ValueKey(imageSource) : ValueKey(imageSource.toString()),
                               children: [
                                 Container(
                                   width: 80,
                                   height: 80,
                                   decoration: BoxDecoration(
                                     borderRadius: BorderRadius.circular(8),
                                     color: Colors.grey[200],
                                   ),
                                   clipBehavior: Clip.antiAlias,
                                   // Display the stored source (RELATIVE Path or PickedImage) using the helper
                                   child: _buildImageDisplayWidget(imageSource, size: 80, iconSize: 30),
                                 ),
                                 // Only show remove button if not processing globally AND this specific image is NOT uploading
                                 if (!_isProcessing && !(imageSource is PickedImage && imageSource.isUploading))
                                   Positioned(
                                     right: 0,
                                     top: 0,
                                     child: GestureDetector(
                                       // Pass the image source object (String or PickedImage) to remove
                                       onTap: () => _removeAdditionalImage(imageSource),
                                       child: Container(
                                         padding: const EdgeInsets.all(2), // Added const
                                         decoration: const BoxDecoration( // Added const
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.only(
                                                topRight: Radius.circular(8),
                                                bottomLeft: Radius.circular(8),
                                            )
                                         ),
                                         child: const Icon(Icons.close, color: Colors.white, size: 14), // Added const
                                       ),
                                     ),
                                   ),
                               ],
                             );
                         }).toList(),
                         // Add button to pick more images
                         GestureDetector(
                           // Disable tap when processing globally or if ANY additional image is currently uploading
                           onTap: (_isProcessing || _additionalImages.any((item) => item is PickedImage && item.isUploading)) ? null : () => _pickAndUploadImage(false),
                           child: Container(
                             width: 80,
                             height: 80,
                             decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[200],
                             ),
                             child: Icon(
                                Icons.add,
                                size: 40,
                                // Grey out icon if disabled
                                color: (_isProcessing || _additionalImages.any((item) => item is PickedImage && item.isUploading)) ? Colors.grey[400] : Colors.grey,
                              ),
                           ),
                         ),
                       ],
                     ),
                  ],
                ),
                const SizedBox(height: 16), // Added const

                // Brand Dropdown (Main Product)
                DropdownButtonFormField<BrandDTO>(
                  value: _selectedBrand,
                  decoration: const InputDecoration(labelText: 'Thương hiệu'), // Added const
                   items: _brands.map((brand) {
                    return DropdownMenuItem<BrandDTO>(
                      value: brand,
                      child: Text(brand.name ?? ''),
                    );
                  }).toList(),
                  onChanged: _isProcessing ? null : (BrandDTO? newValue) {
                    setState(() {
                      _selectedBrand = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Vui lòng chọn thương hiệu';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16), // Added const

                // Category Dropdown (Main Product)
                DropdownButtonFormField<CategoryDTO>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Danh mục'), // Added const
                  items: _categories.map((category) {
                    return DropdownMenuItem<CategoryDTO>(
                      value: category,
                      child: Text(category.name ?? ''),
                    );
                  }).toList(),
                  onChanged: _isProcessing ? null : (CategoryDTO? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Vui lòng chọn danh mục';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16), // Added const

                // Description (Main Product)
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Mô tả'), // Added const
                  maxLines: 5,
                  minLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập mô tả';
                    }
                    return null;
                  },
                   enabled: !_isProcessing,
                ),
                const SizedBox(height: 16), // Added const

                // Discount (Main Product)
                TextFormField(
                  controller: _discountController,
                  decoration: const InputDecoration(labelText: 'Giảm giá (%) (Tối đa 50%)'), // Added const
                  keyboardType: const TextInputType.numberWithOptions(decimal: true), // Added const
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return null; // Discount is optional
                    }
                    final discount = double.tryParse(value.trim());
                     if (discount == null) {
                      return 'Giảm giá phải là số';
                    }
                    if (discount < 0 || discount > 50) {
                        return 'Giảm giá phải từ 0 đến 50%';
                    }
                    return null;
                  },
                   enabled: !_isProcessing,
                ),
                const SizedBox(height: 24), // Added const

                // Variants Section Title
                const Text( // Added const
                  'Biến thể sản phẩm:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16), // Added const

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(), // Added const
                  itemCount: _variants.length,
                  itemBuilder: (context, index) {
                    final variant = _variants[index];
                    return VariantInput(
                      key: ValueKey(variant), // Use ValueKey for proper state management
                      variant: variant, // Pass the actual variant object
                      onPickImage: () => _pickAndUploadVariantImage(variant),
                      onRemove: () => _removeVariant(index),
                      isRemovable: _variants.length > 1,
                       isProcessing: _isProcessing, // Pass global processing state
                       imageDisplayBuilder: _buildImageDisplayWidget, // Pass the screen's builder
                    );
                  },
                ),
                const SizedBox(height: 16), // Added const

                // Add Variant Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    // Disable button when processing globaly OR if any variant image is currently uploading
                    onPressed: (_isProcessing || _variants.any((v) => v.pickedImage != null && v.pickedImage!.isUploading)) ? null : _addVariant,
                    icon: const Icon(Icons.add), // Added const
                    label: const Text('Thêm biến thể'), // Added const
                  ),
                ),
                const SizedBox(height: 24), // Added const

                // Submit Button
                ElevatedButton(
                  // Disable button when processing globaly OR if any image (main or variant) is currently uploading
                  onPressed: (_isProcessing || (_defaultPickedImage != null && _defaultPickedImage!.isUploading) || _additionalImages.any((item) => item is PickedImage && item.isUploading) || _variants.any((v) => v.pickedImage != null && v.pickedImage!.isUploading)) ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16), // Added const
                    textStyle: const TextStyle(fontSize: 18), // Added const
                  ),
                  child: Text(widget.product == null ? 'Thêm Sản phẩm' : 'Cập nhật Sản phẩm'),
                ),
                 const SizedBox(height: 24), // Add some space at the bottom
              ],
            ),
          ),
        ),
      ),
    );
  }
}
