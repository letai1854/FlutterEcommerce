import 'package:e_commerce_app/Screens/Admin/product/ConnectVariant.dart';
import 'package:e_commerce_app/database/Storage/BrandCategoryService.dart';
import 'package:e_commerce_app/database/models/brand.dart';
import 'package:e_commerce_app/database/models/categories.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // Required for File class (implicitly used by XFile)
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:flutter/services.dart'; // Required for Uint8List
import 'package:flutter/scheduler.dart'; // Required for SchedulerBinding

// Import ProductService. Assumed to be in this path.
// Ensure ProductService.dart exists and contains the *uploadImage(List<int> imageBytes, String fileName)*,
// createProduct, and dispose methods.
import 'package:e_commerce_app/database/services/product_service.dart'; // Make sure ProductService exposes baseUrl

// Import necessary DTOs for preparing data for the API call (CREATE and UPDATE).
// Ensure these DTO files exist in your project.
import 'package:e_commerce_app/database/models/create_product_request_dto.dart';
import 'package:e_commerce_app/database/models/update_product_request_dto.dart'; // Needed for update data structure concept
import 'package:e_commerce_app/database/models/create_product_variant_dto.dart';
import 'package:e_commerce_app/database/models/update_product_variant_dto.dart'; // Needed for update data structure concept
// import 'package:e_commerce_app/database/models/product_dto.dart'; // Might be needed if product data format matches DTO

// Helper class to hold locally picked image data temporarily before upload
class PickedImage {
  final Uint8List bytes;
  final String fileName;
  // Add a flag to indicate if upload is in progress
  bool isUploading;

  PickedImage({required this.bytes, required this.fileName, this.isUploading = false});

   // Optional: Add toString for easier debugging
   @override
   String toString() {
     return 'PickedImage(fileName: $fileName, bytesLength: ${bytes.length}, isUploading: $isUploading)';
   }
}

// Modified Variant class to hold both server URL and locally picked image data
class Variant {
  // Original ID from server, null for new variants
  int? originalId;
  // Server URL after successful upload - **This will now store the FULL URL or RELATIVE Path depending on your desired state storage**
  // Let's keep it as FULL URL in the state as per the last successful display logic.
  String? defaultImageUrl;
  // Locally picked image data before upload
  PickedImage? pickedImage;

  // Controllers for variant text fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  Variant({this.originalId, this.defaultImageUrl}); // Constructor to initialize from existing data

  void disposeControllers() {
    nameController.dispose();
    priceController.dispose();
    quantityController.dispose();
  }
}


class AddUpdateProductScreen extends StatefulWidget {
  // If product is not null, we are in update mode (data format is Map<String, dynamic>)
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
  // Holds the FINAL server URL for default image (either initial or uploaded) - **This will now store the FULL URL**
  String? _defaultImageUrl;
  // Holds the LOCALLY PICKED image data for default image (while uploading)
  PickedImage? _defaultPickedImage;

  // This list will now hold a mix of String (server URLs - FULL URL) and PickedImage (local data pending upload)
  final List<dynamic> _additionalImages = [];

  final ImagePicker _picker = ImagePicker();

  // State for dropdowns (Main Product) - Use DTO types
  BrandDTO? _selectedBrand;
  // Lấy danh sách từ AppDataService singleton - Sử dụng getter .brands
  // Assuming AppDataService().brands and .categories are populated asynchronously before this screen is shown
  // or handled by the AppDataService().isInitialized check in build.
  final List<BrandDTO> _brands = AppDataService().brands;

  CategoryDTO? _selectedCategory;
   // Lấy danh sách từ AppDataService singleton - Sử dụng getter .categories
  final List<CategoryDTO> _categories = AppDataService().categories;

  // State for variants
  final List<Variant> _variants = [];

  // Processing state for modal and disabling UI
  bool _isProcessing = false;

  // Instance of ProductService
  // We initialize it here, and it should be disposed.
  final ProductService _productService = ProductService();


  @override
  void initState() {
    super.initState();
    // Ensure AppDataService is initialized if it's not guaranteed before this screen
    // In a real app, you might show a loading screen until AppDataService().isInitialized is true
    if (!AppDataService().isInitialized) {
       // For this example, we'll rely on the check in the build method,
       // but a more robust solution might fetch data here if it's missing.
       if (kDebugMode) print("AppDataService not initialized in AddUpdateProductScreen initState.");
       // Potentially add a listener or future builder here if data loading isn't handled globally
    }

    // Populate fields if editing an existing product
    if (widget.product != null) {
      // --- Load Main Product Data ---
      _nameController.text = widget.product!['name'] ?? '';
      _descriptionController.text = widget.product!['description'] ?? '';
      final dynamic discountValue = widget.product!['discount'];
      _discountController.text = discountValue != null ? discountValue.toString() : '0';

      final int? productBrandId = widget.product!['brandId'] as int?;
      final int? productCategoryId = widget.product!['categoryId'] as int?;

      // Find and set selected brand/category based on loaded data
      if (productBrandId != null) {
         try {
            _selectedBrand = _brands.firstWhere(
               (brand) => brand.id == productBrandId,
            );
         } catch (e) {
            if (kDebugMode) print('Warning: Product brand ID $productBrandId not found in loaded brands.');
            _selectedBrand = null;
         }
      }

       if (productCategoryId != null) {
         try {
            _selectedCategory = _categories.firstWhere(
               (category) => category.id == productCategoryId,
            );
         } catch (e) {
             if (kDebugMode) print('Warning: Product category ID $productCategoryId not found in loaded categories.');
             _selectedCategory = null;
         }
       }

      // --- Load Main Product Images URLs for initial display and saving ---
      // Assuming server returns paths relative to base URL like "/api/images/..."
      // Store these RELATIVE paths initially. Convert to FULL URL only for display.
      final List<dynamic> productImages = widget.product!['images'] ?? [];
       final List<String> initialImagePaths = productImages
          .where((img) => img != null && img is String) // Basic check
          .cast<String>()
           // Store relative paths as they are received from the server,
           // assuming server product data provides relative paths.
          .toList();


      if (initialImagePaths.isNotEmpty) {
        // Store the initial RELATIVE paths in the current state variables
        _defaultImageUrl = initialImagePaths.first; // Store relative path initially
        if (initialImagePaths.length > 1) {
          // Add remaining RELATIVE paths to the additional images list
          _additionalImages.addAll(initialImagePaths.sublist(1));
        }
      }

      // --- Load Variant Data ---
      List<Map<String, dynamic>> existingVariantsData = List<Map<String, dynamic>>.from(widget.product!['variants'] ?? []);

      _variants.clear(); // Clear any default variants

      if (existingVariantsData.isNotEmpty) {
        for (var variantData in existingVariantsData) {
           // Create Variant object and populate controllers, originalId, and image URL
            String? variantImagePath = variantData['defaultImage']?.toString();
            // Store relative variant image path as received
           Variant variant = Variant(
             originalId: variantData['id'] as int?,
             defaultImageUrl: variantImagePath, // Store initial RELATIVE path
           );
           variant.nameController.text = variantData['name'] ?? '';
           final dynamic priceValue = variantData['price'];
           variant.priceController.text = priceValue != null ? priceValue.toString() : '';
           final dynamic quantityValue = variantData['quantity'];
           variant.quantityController.text = quantityValue != null ? quantityValue.toString() : '';

           _variants.add(variant);
        }
      } else {
        // If editing a product that happens to have no variants, add 2 empty ones as per requirement
        _addVariant();
        _addVariant();
      }

    } else {
      // --- New Product ---
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
    // Dispose ProductService httpClient (Assuming ProductService has a dispose method)
    _productService.dispose();
    super.dispose();
  }

  // Function to pick, read bytes, and initiate upload for main product images
  Future<void> _pickAndUploadImage(bool isDefault) async {
     // Prevent picking if already processing globally
    if (_isProcessing) return;

     // Check if an image is already pending or uploading for this spot
     if (isDefault) {
       if (_defaultPickedImage != null) {
         ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Vui lòng chờ ảnh mặc định tải lên xong.')),
         );
         return;
       }
     } else {
        // Check if any additional image is already pending/uploading
        if (_additionalImages.any((item) => item is PickedImage && item.isUploading)) {
             ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Vui lòng chờ các ảnh khác tải lên xong.')),
             );
             return;
         }
     }


    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
       // Declare 'picked' variable outside the try block
       PickedImage? picked;

       try {
          // *** READ BYTES AND GET FILE NAME HERE ***
          final imageBytes = await pickedFile.readAsBytes();
          final fileName = pickedFile.name; // Use the file name from XFile

          if (kDebugMode) print('Picked image: ${fileName}, bytes length: ${imageBytes.length}'); // Log byte length

          if (imageBytes.isEmpty) {
             if (kDebugMode) print('Error: Picked image bytes are empty.');
             throw Exception('Không đọc được dữ liệu ảnh.');
          }

          // *** CREATE LOCAL PickedImage OBJECT AND UPDATE STATE FOR REVIEW ***
          // Set isUploading to true immediately to show indicator
          picked = PickedImage(bytes: imageBytes, fileName: fileName, isUploading: true);

          // Use addPostFrameCallback to schedule the setState AFTER the current frame builds
          // This updates the UI to show the local image review
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) { // Check if the widget is still mounted before calling setState
               setState(() {
                   if (isDefault) {
                       _defaultPickedImage = picked; // Store local data for immediate display
                       _defaultImageUrl = null; // Clear previous server URL for the default image slot
                   } else {
                       _additionalImages.add(picked); // Add local data for immediate display
                       // For additional images, we don't clear the previous URL, we just add the new one.
                   }
               });
            }
          });


          // *** CALL ProductService().uploadImage WITH BYTES AND FILENAME ***
          if (kDebugMode) print('Starting upload for: ${picked.fileName}');
          // This returns the RELATIVE path from the server
          final String? imageRelativePath = await _productService.uploadImage(picked.bytes, picked.fileName);
          if (kDebugMode) print('Image RELATIVE path returned from upload: $imageRelativePath');

          // --- Update State AFTER Upload ---
          // We now store the RELATIVE path returned by the server directly in the state.
          // The conversion to FULL URL for display happens only in _buildImageDisplayWidget.

          // Use addPostFrameCallback again to schedule the next setState
          // This updates the UI to show the image from the server URL or handle failure
          SchedulerBinding.instance.addPostFrameCallback((_) {
             if (mounted) {
                 setState(() {
                     if (imageRelativePath != null && imageRelativePath.isNotEmpty) {
                        if (isDefault) {
                            _defaultImageUrl = imageRelativePath; // Update state with RELATIVE path
                            _defaultPickedImage = null; // Clear local data as upload is done
                        } else {
                            // Find the PickedImage object in the list and replace it with the RELATIVE path
                            final index = _additionalImages.indexWhere((item) => item == picked); // Find by reference
                            if (index != -1) {
                                _additionalImages[index] = imageRelativePath; // Replace with RELATIVE path
                            } else {
                                // Fallback - should not be reached if state management is correct
                                if (kDebugMode) print('Error: Could not find PickedImage object to replace with URL after upload.');
                                _additionalImages.add(imageRelativePath); // Just add the path if not found
                            }
                        }
                        if (kDebugMode) print('Upload successful. State updated with RELATIVE path.');
                         ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tải ảnh lên thành công'),
                              backgroundColor: Colors.green,
                            ),
                         );
                     } else {
                         // If uploadImage returns null or empty relative path
                         if (kDebugMode) print('Upload failed: Server returned empty relative path.');
                         // Revert state on failure: clear local image
                         if (isDefault) {
                              // Only clear if the picked image is still the one being displayed
                             if (_defaultPickedImage == picked) {
                               _defaultPickedImage = null;
                             }
                         } else {
                              // Find and remove the PickedImage object from the list
                               final index = _additionalImages.indexWhere((item) => item == picked);
                               if (index != -1) {
                                 _additionalImages.removeAt(index);
                               }
                         }
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(
                             content: Text('Tải ảnh lên thất bại: Server không trả về đường dẫn ảnh.'),
                             backgroundColor: Colors.red,
                           ),
                         );
                     }
                 });
             }
          });


       } catch (e) {
          // Handle any exceptions thrown during reading bytes or upload
          if (kDebugMode) print('Upload failed: $e');

           // --- Revert State on Failure ---
           // Schedule state update for failure as well
           SchedulerBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                 setState(() {
                     if (picked != null) { // Check if 'picked' was successfully created in the try block
                        if (isDefault) {
                            // Only clear if the picked image is still the one being displayed
                           if (_defaultPickedImage == picked) {
                             _defaultPickedImage = null; // Clear local data on failure
                           }
                        } else {
                            // Find and remove the PickedImage object from the list
                            final index = _additionalImages.indexWhere((item) => item == picked);
                            if (index != -1) {
                               _additionalImages.removeAt(index); // Remove by reference
                            }
                        }
                     }
                     if (kDebugMode) print('Upload failed. State reverted.');
                 });
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text('Tải ảnh lên thất bại: ${e.toString()}'),
                     backgroundColor: Colors.red,
                   ),
                 );
              }
           });
       }
    }
  }

  // Function to pick, read bytes, and initiate upload for a variant image
  Future<void> _pickAndUploadVariantImage(Variant variant) async {
     // Prevent picking if already processing globally or if this variant already has a pending/uploading image
    if (_isProcessing || (variant.pickedImage != null && variant.pickedImage!.isUploading)) return;

    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
       // Declare 'picked' variable outside the try block
       PickedImage? picked;

       try {
           // *** READ BYTES AND GET FILE NAME HERE ***
           final imageBytes = await pickedFile.readAsBytes();
           final fileName = pickedFile.name; // Use the file name from XFile

           if (kDebugMode) print('Picked variant image: ${fileName}, bytes length: ${imageBytes.length}'); // Log byte length

            if (imageBytes.isEmpty) {
             if (kDebugMode) print('Error: Picked variant image bytes are empty.');
             throw Exception('Không đọc được dữ liệu ảnh biến thể.');
           }


           // *** CREATE LOCAL PickedImage OBJECT AND UPDATE STATE FOR REVIEW ***
           // Set isUploading to true immediately to show indicator
           picked = PickedImage(bytes: imageBytes, fileName: fileName, isUploading: true);

            // Use addPostFrameCallback to schedule the setState AFTER the current frame builds
           SchedulerBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                  setState(() {
                      variant.pickedImage = picked; // Store local data for immediate display
                      variant.defaultImageUrl = null; // Clear previous server URL for this variant
                  });
              }
           });


           // *** CALL ProductService().uploadImage WITH BYTES AND FILENAME ***
           if (kDebugMode) print('Starting variant upload for: ${picked.fileName}');
           // This returns the RELATIVE path from the server
           final String? imageRelativePath = await _productService.uploadImage(picked.bytes, picked.fileName);
           if (kDebugMode) print('Variant Image RELATIVE path returned from upload: $imageRelativePath');

           // --- Update State AFTER Upload ---
            // Store the RELATIVE path returned by the server directly in the state.

           // Use addPostFrameCallback again to schedule the next setState
           SchedulerBinding.instance.addPostFrameCallback((_) {
             if (mounted) {
                 setState(() {
                     if (imageRelativePath != null && imageRelativePath.isNotEmpty) {
                         variant.defaultImageUrl = imageRelativePath; // Update state with RELATIVE path
                         variant.pickedImage = null; // Clear local data as upload is done
                         if (kDebugMode) print('Variant upload successful. State updated with RELATIVE path.');
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(
                             content: Text('Tải ảnh biến thể lên thành công'),
                             backgroundColor: Colors.green,
                           ),
                         );
                     } else {
                          if (kDebugMode) print('Variant upload failed: Server returned empty relative path.');
                          // Revert state on failure: clear local image
                           if (variant.pickedImage == picked) { // Check if picked is still the current image
                              variant.pickedImage = null;
                           }
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(
                               content: Text('Tải ảnh biến thể lên thất bại: Server không trả về đường dẫn ảnh.'),
                               backgroundColor: Colors.red,
                             ),
                           );
                     }
                 });
             }
           });

       } catch (e) {
            // Handle any exceptions thrown during reading bytes or upload
            if (kDebugMode) print('Variant upload failed: $e');
            // --- Revert State on Failure ---
            // Schedule state update for failure as well
            SchedulerBinding.instance.addPostFrameCallback((_) {
               if (mounted) {
                   setState(() {
                        // Check if 'picked' was created and is still the active one for this variant
                       if (picked != null && variant.pickedImage == picked) {
                          variant.pickedImage = null; // Clear local data on failure
                       }
                        if (kDebugMode) print('Variant upload failed. State reverted.');
                   });
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(
                       content: Text('Tải ảnh biến thể lên thất bại: ${e.toString()}'),
                       backgroundColor: Colors.red,
                     ),
                   );
               }
            });
       }
    }
  }


  // Function to remove an additional image (handles both URL String and PickedImage)
  void _removeAdditionalImage(dynamic imageSource) {
    // Prevent removal if processing or if this specific image is uploading
    if (_isProcessing || (imageSource is PickedImage && imageSource.isUploading)) return;
    setState(() {
       if (kDebugMode) print('Removing additional image source: $imageSource');
      _additionalImages.remove(imageSource); // Remove by object reference
    });
  }

   // Function to remove the default image (handles both URL String and PickedImage)
  void _removeDefaultImage() {
     // Prevent removal if processing or if the default image is uploading
    if (_isProcessing || (_defaultPickedImage != null && _defaultPickedImage!.isUploading)) return;
     setState(() {
        if (kDebugMode) print('Removing default image. Current source: ${_defaultPickedImage ?? _defaultImageUrl}');
        _defaultImageUrl = null;
        _defaultPickedImage = null;
     });
  }


  // Function to add a new variant
  void _addVariant() {
    // Prevent adding if processing
    if (_isProcessing) return;
    setState(() {
      // Create a new Variant object, initially with no image URL and no originalId
      _variants.add(Variant());
    });
  }

  // Function to remove a variant
  void _removeVariant(int index) {
    // Prevent removal if processing or if this variant's image is uploading
     if (_isProcessing || (_variants[index].pickedImage != null && _variants[index].pickedImage!.isUploading)) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Không thể xóa biến thể khi ảnh đang tải lên.')),
       );
       return;
     }
    // Dispose variant controllers before removing
    _variants[index].disposeControllers();
    setState(() {
      if (kDebugMode) print('Removing variant at index $index');
      _variants.removeAt(index);
    });
  }

  // Function to handle form submission (ONLY calls createProduct or SIMULATES updateProduct)
  void _submitForm() async {
    // Prevent multiple submissions if already processing
    if (_isProcessing) return;

    // --- Pre-Check: Ensure all images are uploaded ---
    // Check if any PickedImage object still exists in state (indicating pending upload)
    if (_defaultPickedImage != null || _additionalImages.any((item) => item is PickedImage) || _variants.any((v) => v.pickedImage != null)) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Vui lòng chờ tất cả ảnh tải lên xong trước khi gửi.')),
       );
       // Optionally, you could iterate and show a more specific message if needed
       // for (var variant in _variants) { if (variant.pickedImage != null) { /* show variant-specific message */ break; } }
       return;
    }


    // --- Step 1: Validate main form fields (TextFormFields and Dropdowns) ---
    // This triggers the validator functions on the TextFormFields and DropdownButtonFormFields
    // for product name, description, discount, brand, and category.
    // The validators in the TextFormFields of VariantInput should also be triggered if
    // they are correctly set up and included in the form's subtree.
    if (!_formKey.currentState!.validate()) {
      // If form validation fails, errors will be shown next to the fields.
      // No need for an extra Snackbar here, as field errors are visible.
      if (kDebugMode) print('Main form validation failed.');
      return;
    }

    // --- Step 2: Validate items not covered by _formKey (Images and Variants existence) ---

    // Basic validation for main image URL existence (now stores relative path, check if it exists)
    if (_defaultImageUrl == null || _defaultImageUrl!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng chọn ảnh mặc định cho sản phẩm chính.')),
        );
         if (kDebugMode) print('Validation failed: Default image missing.');
        return;
    }

    // Basic validation for at least one variant
     if (_variants.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Vui lòng thêm ít nhất một biến thể')),
         );
         if (kDebugMode) print('Validation failed: No variants added.');
         return;
     }

      // --- Step 3: Validate individual variant details (including images) ---
     bool areVariantsCompletelyValid = true;
     String variantValidationMessage = '';

     for (var variant in _variants) {
         // Check TextFormFields value explicitly, including trimming for 'blank' check
         if (variant.nameController.text.trim().isEmpty) {
             areVariantsCompletelyValid = false;
             variantValidationMessage = 'Vui lòng nhập tên cho tất cả biến thể.';
             break; // Stop checking variants once one invalid is found
         }
         final price = double.tryParse(variant.priceController.text.trim());
         final quantity = int.tryParse(variant.quantityController.text.trim());

         if (price == null || price < 0) {
             areVariantsCompletelyValid = false;
             variantValidationMessage = 'Vui lòng nhập giá hợp lệ (số >= 0) cho tất cả biến thể.';
             break;
         }
          if (quantity == null || quantity < 0) {
             areVariantsCompletelyValid = false;
             variantValidationMessage = 'Vui lòng nhập số lượng tồn kho hợp lệ (số nguyên >= 0) cho tất cả biến thể.';
             break;
         }


          // Validate variant image paths (must be a non-empty string after upload)
         if (variant.defaultImageUrl == null || variant.defaultImageUrl!.isEmpty) {
             areVariantsCompletelyValid = false;
             variantValidationMessage = 'Vui lòng chọn ảnh cho tất cả biến thể.';
             break; // Stop checking variants once one invalid is found
         }
     }

     if (!areVariantsCompletelyValid) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(variantValidationMessage)), // Show combined message
         );
         if (kDebugMode) print('Validation failed: Variant details missing or invalid.');
         return;
     }


    // --- If all validation passes, proceed with processing ---
    if (kDebugMode) print('All validation passed. Proceeding to submission.');
    // --- Show Processing Modal ---
    setState(() {
      _isProcessing = true; // Set state to show loading and block interaction
    });
    // Show a dialog that blocks user interaction
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text(widget.product == null ? "Đang tạo sản phẩm..." : "Đang cập nhật sản phẩm..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      // --- Prepare Data for API Call (using stored RELATIVE Paths) ---
      // This part prepares the data structure that would be sent to your API.

      if (widget.product == null) {
          // --- Create Product ---
          // Prepare list of CreateProductVariantDTOs using the stored RELATIVE paths
          List<CreateProductVariantDTO> createVariantDTOs = _variants.map((variant) {
              return CreateProductVariantDTO(
                  name: variant.nameController.text.trim(), // Apply trim() here for API data
                  // sku: variant.skuController.text, // if you had sku input
                  price: double.tryParse(variant.priceController.text.trim()) ?? 0.0, // Apply trim() here for API data
                  stockQuantity: int.tryParse(variant.quantityController.text.trim()) ?? 0, // Apply trim() here for API data
                  variantImageUrl: variant.defaultImageUrl, // Use the stored RELATIVE path
              );
          }).toList();

          // Construct the CreateProductRequestDTO using the stored RELATIVE paths
          CreateProductRequestDTO productRequest = CreateProductRequestDTO(
             name: _nameController.text.trim(), // Apply trim() here for API data
             description: _descriptionController.text.trim(), // Apply trim() here for API data
             // Ensure these are not null based on dropdown validation (_formKey handles this)
             categoryId: _selectedCategory!.id!,
             brandId: _selectedBrand!.id!,
             mainImageUrl: _defaultImageUrl, // Use the stored RELATIVE path
             // Filter _additionalImages to get only Strings (the RELATIVE paths)
             imageUrls: _additionalImages.whereType<String>().toList(),
             discountPercentage: double.tryParse(_discountController.text.trim()), // Apply trim() here for API data
             variants: createVariantDTOs, // Pass the list of variant DTOs
          );

           if (kDebugMode) print('Calling createProduct with data: ${productRequest.toJson()}');

           // *** CALL THE ACTUAL CREATE API ***
           await _productService.createProduct(productRequest);

       } else {
          // --- Update Product ---
          // User requested to NOT implement updateProduct API call yet.
          // Only simulate the process after collecting data.

          // Combine main and additional image paths for logging (or for a potential update DTO)
          // Ensure these are RELATIVE paths
          List<String> allImagePathsForLogging = [];
          if (_defaultImageUrl != null) {
             allImagePathsForLogging.add(_defaultImageUrl!); // Already RELATIVE path
          }
          // Add only the String RELATIVE paths from the mixed additionalImages list
          allImagePathsForLogging.addAll(_additionalImages.whereType<String>());


           Map<String, dynamic> productDataForLogging = {
               'id': widget.product!['id'], // Product ID
               'name': _nameController.text.trim(), // Apply trim() here for API data
               'description': _descriptionController.text.trim(), // Apply trim() here for API data
               'categoryId': _selectedCategory?.id,
               'brandId': _selectedBrand?.id,
               'images': allImagePathsForLogging, // Use final RELATIVE paths
               'discountPercentage': double.tryParse(_discountController.text.trim()), // Apply trim() here for API data
               'variants': _variants.map((v) => {
                   'id': v.originalId, // Include original ID if exists
                   'name': v.nameController.text.trim(), // Apply trim() here for API data
                   'price': double.tryParse(v.priceController.text.trim()), // Apply trim() here for API data
                   'quantity': int.tryParse(v.quantityController.text.trim()), // Apply trim() here for API data
                   'variantImageUrl': v.defaultImageUrl, // Use final RELATIVE path
               }).toList(),
            };

          if (kDebugMode) print('Simulating updateProduct call for ID: ${widget.product!['id']} with data: ${productDataForLogging}');

          // *** SIMULATE THE API CALL ***
          await Future.delayed(const Duration(seconds: 3)); // Simulate network delay
       }


      // --- Handle Success ---
      // Dismiss the loading dialog FIRST
      Navigator.of(context).pop();
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.product == null ? 'Tạo sản phẩm thành công!' : 'Cập nhật sản phẩm thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      // Optionally navigate back after success
       Navigator.pop(context, true); // Pass true to indicate success

    } catch (e) {
      // --- Handle Error ---
      // Dismiss the loading dialog FIRST
      Navigator.of(context).pop();
      // Handle any exceptions thrown during API calls (createProduct or simulation)
      if (kDebugMode) print('Error during product submission: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // --- Reset Processing State ---
      // This will happen after the dialog is popped in the try/catch blocks
      setState(() {
        _isProcessing = false;
      });
       // Also clear any isUploading flags just in case (though they should be null by now after success/failure handling)
       // This part is defensive; the nulling logic in try/catch is the primary mechanism.
       if (_defaultPickedImage != null) _defaultPickedImage!.isUploading = false;
       for (var item in List.from(_additionalImages.whereType<PickedImage>())) { // Iterate over a copy
          item.isUploading = false;
       }
       for (var variant in _variants) {
         if (variant.pickedImage != null) variant.pickedImage!.isUploading = false;
       }
    }
  }

  // Helper to build image widget from source (Handles PickedImage, Network URLs, or Placeholder)
  // Helper to build image widget from source (Handles PickedImage, Network URLs, or Placeholder)
Widget _buildImageDisplayWidget(dynamic source, {double size = 40, double iconSize = 40, BoxFit fit = BoxFit.cover}) {
  // Source can be PickedImage (local data) or String (server path/URL)

  if (kDebugMode) {
     // Log what source is received for display
     print('[_buildImageDisplayWidget] Received source: $source (Type: ${source?.runtimeType})');
     if (source is PickedImage) {
       print('[_buildImageDisplayWidget] PickedImage bytes length: ${source.bytes.length}');
     } else if (source is String) {
        print('[_buildImageDisplayWidget] String source (path/URL): $source');
     }
  }


  if (source == null || (source is String && source.isEmpty)) {
    // Display placeholder icon if source is null or empty string
    return Icon(Icons.camera_alt, size: iconSize, color: Colors.grey);
  }

  if (source is PickedImage) {
    // Display locally picked image bytes
    return Stack(
       fit: StackFit.expand,
       children: [
          Image.memory(
             source.bytes,
             fit: fit,
             // Add errorBuilder to log issues with Image.memory
             errorBuilder: (context, error, stackTrace) {
                if (kDebugMode) print('[_buildImageDisplayWidget] Image.memory failed for ${source.fileName}: $error');
                // Returning a simple colored box or container can help distinguish
                // between a failed memory load and a network load error.
                return Container(color: Colors.orangeAccent.withOpacity(0.5), child: Icon(Icons.warning_amber, size: iconSize * 0.8, color: Colors.deepOrange));
             },
          ),
           // Optional: Add an upload indicator overlay
          if (source.isUploading) // Assuming PickedImage has an isUploading flag
             Container(
                color: Colors.black54,
                child: Center(
                   child: CircularProgressIndicator(color: Colors.white),
                ),
             ),
       ],
    );
  } else if (source is String) { // Now we know it's a non-empty String (a server path or potentially a full URL)
     // Use the helper function from ProductService to get the guaranteed FULL URL
     final fullImageUrl = _productService.getImageUrl(source);

     if (kDebugMode) {
        print('[_buildImageDisplayWidget] Using FULL URL for Image.network: $fullImageUrl');
     }

     // Basic validation *after* constructing full URL
     // We expect getImageUrl to always return a full URL if the input is non-empty,
     // but this check is defensive.
     if (!fullImageUrl.startsWith('http://') && !fullImageUrl.startsWith('https://')) {
        if (kDebugMode) print('[_buildImageDisplayWidget] Invalid constructed URL format (missing http/https): $fullImageUrl');
        // Don't return error icon immediately, let Image.network try. Its errorBuilder handles it.
         // Instead, perhaps check if _productService.getImageUrl returned something unexpected.
         // This check might be redundant if getImageUrl is guaranteed to return a valid format string.
         // Let's rely on Image.network's errorBuilder for network issues.
     }

     // Display network image from FULL URL
    return Image.network(
  fullImageUrl,
  fit: fit,
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
              : null,
        ),
      ),
    );
  },
  errorBuilder: (context, error, stackTrace) {
    if (kDebugMode) {
      print('[_buildImageDisplayWidget] Image.network failed for $fullImageUrl: $error');
    }
    return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
  },
);

  } else {
      // Fallback - should not be reached with current logic, but safe to have
      if (kDebugMode) print('[_buildImageDisplayWidget] Unexpected source type: ${source?.runtimeType}');
       return Icon(Icons.error, size: iconSize, color: Colors.purple); // Indicate an unexpected situation
  }
}


  @override
  Widget build(BuildContext context) {
    // Check if app data (brands, categories) is loaded before building complex UI that needs it
     if (!AppDataService().isInitialized) {
         // Show a simple loading indicator while data loads
         return Scaffold(
           appBar: AppBar(title: const Text('Loading Data')),
           body: const Center(child: CircularProgressIndicator()),
         );
     }

    // Determine the source for the default image display (prioritize PickedImage for review)
    final dynamic defaultImageSource = _defaultPickedImage ?? _defaultImageUrl;

    // Main UI is built only after data is initialized
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Thêm Sản phẩm' : 'Cập nhật Sản phẩm'),
      ),
      // Use AbsorbPointer to block interaction when processing
      body: AbsorbPointer(
        absorbing: _isProcessing, // Absorb events when _isProcessing is true
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // Main Product Info Title
                Text(
                  'Thông tin Sản phẩm chính:',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Product Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
                  validator: (value) {
                    // Add validation check, including trimming
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên sản phẩm';
                    }
                    return null;
                  },
                   // Disable input visually when processing
                   enabled: !_isProcessing,
                ),
                const SizedBox(height: 16),

                // Default Image (Main Product)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ảnh mặc định (Sản phẩm chính):', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Stack( // Use Stack to potentially place a remove button or indicator
                       children: [
                         GestureDetector(
                            // Disable tap if processing or if an image is already picked/uploading for this slot
                            onTap: (_isProcessing || (_defaultPickedImage != null && _defaultPickedImage!.isUploading)) ? null : () => _pickAndUploadImage(true),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[200],
                                // Optional: add border if image is missing/error
                                // Check if both _defaultPickedImage and _defaultImageUrl are null/empty
                                border: (_defaultPickedImage == null && (_defaultImageUrl == null || _defaultImageUrl!.isEmpty))
                                    ? Border.all(color: Colors.red, width: 1) // Indicate required field missing
                                    : null,
                              ),
                              clipBehavior: Clip.antiAlias,
                              // Display the stored local or server image source
                              child: _buildImageDisplayWidget(
                                  defaultImageSource, // Pass the combined source
                                  size: 100,
                                  iconSize: 40,
                                  fit: BoxFit.cover
                                ),
                            ),
                         ),
                         // Show remove button only if an image source exists and not processing AND not currently uploading
                         // Check if there is *any* source to remove
                         if (!_isProcessing && defaultImageSource != null && !(defaultImageSource is PickedImage && defaultImageSource.isUploading))
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: _removeDefaultImage,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.only(
                                          topRight: Radius.circular(8),
                                          bottomLeft: Radius.circular(8),
                                      )
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                       ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Additional Images (Main Product) - Mix of URLs and PickedImages
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ảnh góc minh họa (Sản phẩm chính, có thể chọn nhiều):', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                     Wrap(
                       spacing: 8,
                       runSpacing: 8,
                       children: [
                         // Display stored images (mix of String RELATIVE Paths and PickedImage objects)
                         ..._additionalImages.map((imageSource) {
                             return Stack(
                               children: [
                                 Container(
                                   width: 80,
                                   height: 80,
                                   decoration: BoxDecoration(
                                     borderRadius: BorderRadius.circular(8),
                                     color: Colors.grey[200],
                                      // Optional: add border if needed
                                   ),
                                   clipBehavior: Clip.antiAlias,
                                   // Display the stored source (RELATIVE Path or PickedImage)
                                   child: _buildImageDisplayWidget(imageSource, size: 80, iconSize: 30),
                                 ),
                                 // Only show remove button if not processing AND not currently uploading
                                 if (!_isProcessing && !(imageSource is PickedImage && imageSource.isUploading))
                                   Positioned(
                                     right: 0,
                                     top: 0,
                                     child: GestureDetector(
                                       // Pass the image source object to remove
                                       onTap: () => _removeAdditionalImage(imageSource),
                                       child: Container(
                                         padding: const EdgeInsets.all(2),
                                         decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.only(
                                                topRight: Radius.circular(8),
                                                bottomLeft: Radius.circular(8),
                                            )
                                         ),
                                         child: const Icon(Icons.close, color: Colors.white, size: 14),
                                       ),
                                     ),
                                   ),
                               ],
                             );
                         }).toList(),
                         // Add button to pick more images
                         GestureDetector(
                           // Disable tap when processing or if any additional image is already uploading
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
                                // Grey out icon if disabled (processing or upload in progress)
                                color: (_isProcessing || _additionalImages.any((item) => item is PickedImage && item.isUploading)) ? Colors.grey[400] : Colors.grey,
                              ),
                           ),
                         ),
                       ],
                     ),
                  ],
                ),
                const SizedBox(height: 16),

                // Brand Dropdown (Main Product)
                DropdownButtonFormField<BrandDTO>(
                  value: _selectedBrand,
                  decoration: const InputDecoration(labelText: 'Thương hiệu'),
                   items: _brands.map((brand) {
                    return DropdownMenuItem<BrandDTO>(
                      value: brand,
                      child: Text(brand.name ?? ''),
                    );
                  }).toList(),
                  // Disable interaction when processing
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
                   // Set enabled state for visual feedback
                   // Note: enabled property on DropdownButtonFormField affects the whole widget,
                   // including the text field part. onTap: null on the parent handles the dropdown opening.
                ),
                const SizedBox(height: 16),

                // Category Dropdown (Main Product)
                DropdownButtonFormField<CategoryDTO>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Danh mục'),
                  items: _categories.map((category) {
                    return DropdownMenuItem<CategoryDTO>(
                      value: category,
                      child: Text(category.name ?? ''),
                    );
                  }).toList(),
                  // Disable interaction when processing
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
                  // isEnabled: !_isProcessing, // Handled by AbsorbPointer and onTap: null
                ),
                const SizedBox(height: 16),

                // Description (Main Product)
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                  maxLines: 5,
                  minLines: 5,
                  validator: (value) {
                    // Add validation check, including trimming
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập mô tả';
                    }
                    return null;
                  },
                   // Disable input visually when processing
                   enabled: !_isProcessing,
                ),
                const SizedBox(height: 16),

                // Discount (Main Product)
                TextFormField(
                  controller: _discountController,
                  decoration: const InputDecoration(labelText: 'Giảm giá (%) (Tối đa 50%)'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return null; // Discount is optional
                    }
                    final discount = double.tryParse(value.trim()); // Apply trim()
                     if (discount == null) {
                      return 'Giảm giá phải là số';
                    }
                    if (discount < 0 || discount > 50) {
                        return 'Giảm giá phải từ 0 đến 50%';
                    }
                    return null;
                  },
                   // Disable input visually when processing
                   enabled: !_isProcessing,
                ),
                const SizedBox(height: 24),

                // Variants Section Title
                Text(
                  'Biến thể sản phẩm:',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _variants.length,
                  itemBuilder: (context, index) {
                    final variant = _variants[index];
                    // Pass the variant object and the processing state down
                    // VariantInput uses its own internal validation logic for text fields
                    return VariantInput(
                      key: ValueKey(variant), // Use ValueKey for proper state management
                      variant: variant, // Pass the actual variant object
                      // Pass the upload function specific to this variant
                      onPickImage: () => _pickAndUploadVariantImage(variant),
                       // Pass the remove function specific to this variant index
                      onRemove: () => _removeVariant(index),
                      isRemovable: _variants.length > 1,
                       // Explicitly pass the processing state down
                       isProcessing: _isProcessing,
                       // Pass the image display builder down to VariantInput
                       // This way VariantInput uses the screen's logic for display
                       imageDisplayBuilder: _buildImageDisplayWidget,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Add Variant Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    // Disable button when processing
                    onPressed: _isProcessing ? null : _addVariant,
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm biến thể'),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  // Disable button when processing
                  onPressed: _isProcessing ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
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


class VariantInput extends StatelessWidget {
  final Variant variant;
  final VoidCallback onPickImage;
  final VoidCallback onRemove;
  final bool isRemovable;
  final bool isProcessing; // Receive processing state from parent
  // Receive the builder function
  final Widget Function(dynamic source, {double size, double iconSize, BoxFit fit}) imageDisplayBuilder;

  const VariantInput({
    Key? key,
    required this.variant,
    required this.onPickImage,
    required this.onRemove,
    required this.isRemovable,
    required this.isProcessing, // Add to constructor
    required this.imageDisplayBuilder, // Add to constructor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final dynamic variantImageSource = variant.pickedImage ?? variant.defaultImageUrl;

     if (kDebugMode) {
         print('[VariantInput] Building image for variant ${variant.nameController.text}. Source: $variantImageSource (Type: ${variantImageSource?.runtimeType})');
         if (variantImageSource is PickedImage) {
            print('[VariantInput] PickedImage bytes length: ${variantImageSource.bytes.length}');
         } else if (variantImageSource is String) {
            print('[VariantInput] String source (URL): $variantImageSource');
         }
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
                const Text('Biến thể', style: TextStyle(fontWeight: FontWeight.bold)),
                if (isRemovable)
                  IconButton(
                    onPressed: (isProcessing || (variant.pickedImage != null && variant.pickedImage!.isUploading)) ? null : onRemove,
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    tooltip: 'Xóa biến thể',
                  ),
              ],
            ),
            const SizedBox(height: 8),

            Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                  const Text('Ảnh biến thể:', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                   Stack( // Use Stack for potential remove button/indicator
                      children: [
                         GestureDetector(
                            onTap: (isProcessing || (variant.pickedImage != null && variant.pickedImage!.isUploading)) ? null : onPickImage,
                            child: Container(
                               width: 80,
                               height: 80,
                               decoration: BoxDecoration(
                                 borderRadius: BorderRadius.circular(8),
                                 color: Colors.grey[200],
                                  // Check if both pickedImage and defaultImageUrl are null/empty
                                  border: (variant.pickedImage == null && (variant.defaultImageUrl == null || variant.defaultImageUrl!.isEmpty))
                                    ? Border.all(color: Colors.red, width: 1) // Indicate required field missing
                                    : null,
                               ),
                               clipBehavior: Clip.antiAlias,
                               child: imageDisplayBuilder(variantImageSource, size: 80, iconSize: 30),
                            ),
                         ),

                      ]
                   ),
               ],
            ),
             const SizedBox(height: 16),


            TextFormField(
              controller: variant.nameController,
              decoration: const InputDecoration(labelText: 'Tên biến thể (ví dụ: Xanh, Đỏ, S/M/L)'),
              validator: (value) {
                // Add validation check, including trimming
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên biến thể';
                }
                return null;
              },
               enabled: !isProcessing,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: variant.priceController,
              decoration: const InputDecoration(labelText: 'Giá'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                // Add validation check, including trimming and number parsing
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập giá';
                }
                final price = double.tryParse(value.trim());
                if (price == null || price < 0) {
                  return 'Giá phải là số hợp lệ (>= 0)';
                }
                return null;
              },
               enabled: !isProcessing,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: variant.quantityController,
              decoration: const InputDecoration(labelText: 'Số lượng tồn kho'),
              keyboardType: TextInputType.number,
              validator: (value) {
                 // Add validation check, including trimming and integer parsing
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập số lượng';
                }
                 final quantity = int.tryParse(value.trim());
                 if (quantity == null || quantity < 0) {
                  return 'Số lượng phải là số nguyên hợp lệ (>= 0)';
                }
                return null;
              },
               enabled: !isProcessing,
            ),
          ],
        ),
      ),
    );
  }
}
