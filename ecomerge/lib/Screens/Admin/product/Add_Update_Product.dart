import 'package:e_commerce_app/database/Storage/BrandCategoryService.dart';
import 'package:e_commerce_app/database/models/brand.dart';
import 'package:e_commerce_app/database/models/categories.dart';


import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class AddUpdateProductScreen extends StatefulWidget {

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
  // Discount controller for main product
  final TextEditingController _discountController = TextEditingController();

  // State for image selection (Main Product)
  XFile? _defaultImage; // Holds NEWLY picked default image (XFile)
  final List<XFile> _additionalImages = []; // Holds NEWLY picked additional images (XFile)
  final ImagePicker _picker = ImagePicker();

  // State for dropdowns (Main Product) - Use DTO types
  BrandDTO? _selectedBrand;
  // Lấy danh sách từ AppDataService singleton - Sử dụng getter .brands
  final List<BrandDTO> _brands = AppDataService().brands;

  CategoryDTO? _selectedCategory;
   // Lấy danh sách từ AppDataService singleton - Sử dụng getter .categories
  final List<CategoryDTO> _categories = AppDataService().categories;

  // State for variants
  final List<Variant> _variants = [];

  // Variables to hold initial image paths (String) for display in edit mode
  String? _initialDefaultImagePath;
  final List<String> _initialAdditionalImagePaths = [];


  @override
  void initState() {
    super.initState();
    // Populate fields if editing an existing product
    if (widget.product != null) {
      // --- Load Main Product Data ---
      _nameController.text = widget.product!['name'] ?? '';
      _descriptionController.text = widget.product!['description'] ?? '';
      // Handle discount as potential int or double from JSON
      final dynamic discountValue = widget.product!['discount'];
      _discountController.text = discountValue != null ? discountValue.toString() : '0';

      final int? productBrandId = widget.product!['brandId'] as int?;
      final int? productCategoryId = widget.product!['categoryId'] as int?;

      if (productBrandId != null) {
         // Find the BrandDTO in the list that matches the product's brandId
         try {
            _selectedBrand = _brands.firstWhere(
               (brand) => brand.id == productBrandId,
            );
         } catch (e) {
            if (kDebugMode) print('Warning: Product brand ID $productBrandId not found in loaded brands.');
            _selectedBrand = null; // Or handle appropriately
         }
      }

       if (productCategoryId != null) {
         // Find the CategoryDTO in the list that matches the product's categoryId
         try {
            _selectedCategory = _categories.firstWhere(
               (category) => category.id == productCategoryId,
            );
         } catch (e) {
             if (kDebugMode) print('Warning: Product category ID $productCategoryId not found in loaded categories.');
             _selectedCategory = null; // Or handle appropriately
         }
       }


      // --- Load Main Product Images Paths for initial display ---
      final List<dynamic> productImages = widget.product!['images'] ?? [];
      final List<String> validInitialImagePaths = productImages
          .where((img) => img != null && img is String && (img.startsWith('http') || img.startsWith('/'))) // Basic check for valid paths/URLs
          .cast<String>()
          .toList();

      if (validInitialImagePaths.isNotEmpty) {
        _initialDefaultImagePath = validInitialImagePaths.first;
        if (validInitialImagePaths.length > 1) {
          _initialAdditionalImagePaths.addAll(validInitialImagePaths.sublist(1));
        }
      }

      // --- Load Variant Data ---
      List<Map<String, dynamic>> existingVariantsData = List<Map<String, dynamic>>.from(widget.product!['variants'] ?? []);

      _variants.clear(); // Clear any default variants

      if (existingVariantsData.isNotEmpty) {
        for (var variantData in existingVariantsData) {
           Variant variant = Variant();
           // Populate controllers from existing data
           variant.nameController.text = variantData['name'] ?? '';
           // Ensure price and quantity are handled correctly (could be int/double)
           final dynamic priceValue = variantData['price'];
           variant.priceController.text = priceValue != null ? priceValue.toString() : '';
           final dynamic quantityValue = variantData['quantity'];
           variant.quantityController.text = quantityValue != null ? quantityValue.toString() : '';

           // Store initial variant image path for display
           variant.initialImagePath = variantData['defaultImage']?.toString();

           // If editing, potentially store original variant ID if your backend expects it for updates
           // variant.originalId = variantData['id'];

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
    _nameController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    // Dispose controllers for variants as well
    for (var variant in _variants) {
      variant.disposeControllers();
    }
    super.dispose();
  }

  // Function to pick an image (Main Product)
  Future<void> _pickImage(bool isDefault) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isDefault) {
          _defaultImage = pickedFile;
          _initialDefaultImagePath = null; // Clear initial path when a new one is picked
        } else {
          // Add to additional images, handling potential duplicates by path if needed
          // For simplicity, we just add. A more robust solution might check if a file with the same path already exists in _additionalImages or _initialAdditionalImagePaths.
           _additionalImages.add(pickedFile);
        }
      });
    }
  }

   // Function to remove an additional image source (Handles both XFile and initial path String)
   void _removeAdditionalImageSource(dynamic imageSource) {
       setState(() {
           if (imageSource is XFile) {
               _additionalImages.remove(imageSource);
           } else if (imageSource is String) {
               _initialAdditionalImagePaths.remove(imageSource);
           }

       });
   }


  // Function to add a new variant
  void _addVariant() {
    setState(() {
      _variants.add(Variant()); // Add a new, empty variant object
    });
  }

  // Function to remove a variant
  void _removeVariant(int index) {
    // Dispose variant controllers before removing
    _variants[index].disposeControllers();
    setState(() {
      _variants.removeAt(index);
    });
  }

  // Function to handle form submission
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Basic validation for at least one variant
       if (_variants.isEmpty) {
           ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Vui lòng thêm ít nhất một biến thể')),
           );
           return;
       }

        // Optional: Validate variant fields here as well
       bool areVariantsValid = true;
       for (var variant in _variants) {
           // Example validation: Check if name, price, quantity controllers have text
           if (variant.nameController.text.isEmpty ||
               variant.priceController.text.isEmpty ||
               variant.quantityController.text.isEmpty ||
               double.tryParse(variant.priceController.text) == null || // Check if price is a valid number
               int.tryParse(variant.quantityController.text) == null // Check if quantity is a valid integer
              )
            {
               areVariantsValid = false;
               // You might want to show a specific error message here or highlight the invalid variant
               break; // Stop checking on the first invalid variant
           }
       }

       if (!areVariantsValid) {
            ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Vui lòng điền đầy đủ và chính xác thông tin cho tất cả biến thể.')),
           );
           return;
       }


      // TODO: Process form data (save product)
      print('Form submitted');
      print('Product Name: ${_nameController.text}');
      print('Description: ${_descriptionController.text}');
      // Note: Discount will be converted to double/int when preparing data for backend
      print('Discount: ${_discountController.text}');
      // Print selected Brand/Category names and IDs
      print('Selected Brand: ${_selectedBrand?.name} (ID: ${_selectedBrand?.id})');
      print('Selected Category: ${_selectedCategory?.name} (ID: ${_selectedCategory?.id})');


      // Collecting final image paths for saving (These are paths/URLs, not the actual file data)
      // You will need to handle uploading new files (_defaultImage, _additionalImages)
      // and getting their server-side paths/URLs *before* sending the final product DTO.
      String? finalDefaultImagePath = _defaultImage?.path ?? _initialDefaultImagePath; // Use path of picked XFile or initial String
      List<String> finalAdditionalImagePaths = [
         ..._initialAdditionalImagePaths, // Include initial paths remaining
         ..._additionalImages.map((img) => img.path).toList(), // Add newly picked images' paths
      ];

      print('Default Image Path (Final): $finalDefaultImagePath');
      print('Additional Image Paths (Final): $finalAdditionalImagePaths');


      // Collect variant data including image paths
      List<Map<String, dynamic>> variantsData = _variants.map((v) {
          // For variant image, use the new picked image's path OR the initial path
          String? finalVariantImagePath = v.defaultImage?.path ?? v.initialImagePath;
          return {

              'name': v.nameController.text,
              'price': double.tryParse(v.priceController.text) ?? 0.0, // Convert to double
              'quantity': int.tryParse(v.quantityController.text) ?? 0, // Convert to int
              'defaultImage': finalVariantImagePath, // This will be the path/URL string
               // If editing, carry over original SKU, created_date, updated_date if your data model includes them
               // e.g., 'sku': this.originalSku, 'created_date': this.originalCreatedDate, ...
          };
      }).toList();

      print('Variants Data (Final): $variantsData');


      // Example of how you might structure the data to send to your API (this depends heavily on your backend DTO)
      // This is a simplified example. You would likely have a CreateProductRequestDTO
      // or UpdateProductRequestDTO class in Dart that matches your Java DTO structure.
      Map<String, dynamic> productDataToSend = {
         // Include product ID if updating
         // 'id': widget.product?['id'], // Uncomment if needed for update API

         'name': _nameController.text,
         'description': _descriptionController.text,
         'discount': double.tryParse(_discountController.text) ?? 0.0, // Send as number
         'brandId': _selectedBrand?.id, // Send the ID of the selected brand
         'categoryId': _selectedCategory?.id, // Send the ID of the selected category

         'images': [
             if (finalDefaultImagePath != null) finalDefaultImagePath, // Include default image path
             ...finalAdditionalImagePaths, // Include additional image paths
         ],
         'variants': variantsData, // Send variant data (already includes variant image paths/URLs)
      };

       if (kDebugMode) print('Data to Send to API: $productDataToSend');


      Navigator.pop(context);
    }
  }

  // Helper to build image widget from source (Handles Asset, File, Network, XFile based on platform)
  // This function is versatile and used for displaying both initial paths and picked XFiles.
  Widget _buildImageDisplayWidget(dynamic imageSource, {double size = 40, double iconSize = 40, BoxFit fit = BoxFit.cover}) {
    if (imageSource == null) {
      return Icon(Icons.camera_alt, size: iconSize, color: Colors.grey); // Placeholder if no image source
    }

    // If it's an XFile (newly picked image)
    if (imageSource is XFile) {
        if (kIsWeb) {
             // On Web, XFile.path is typically a blob URL or similar web reference
            return Image.network(
                 imageSource.path,
                 fit: fit,
                 errorBuilder: (context, error, stackTrace) {
                     print('Error loading web picked image: ${imageSource.path}, Error: $error'); // Debugging
                     return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
                 },
             );
        } else {
             // On non-Web, XFile.path is a file path
             try {
                return Image.file(
                    File(imageSource.path),
                    fit: fit,
                     errorBuilder: (context, error, stackTrace) {
                        print('Error loading file picked image: ${imageSource.path}, Error: $error'); // Debugging
                        return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
                    },
                );
             } catch (e) {
               print('Exception creating File from XFile path: ${imageSource.path}, Exception: $e'); // Debugging
               return Icon(Icons.error_outline, size: iconSize, color: Colors.red);
             }
        }
    }

    // If it's a String (initial path from data or potentially a network URL)
    if (imageSource is String && imageSource.isNotEmpty) {
         // Check if it's an asset path (simple check) - Less likely for server data
         if (imageSource.startsWith('assets/')) {
            return Image.asset(
                 imageSource,
                 fit: fit,
                  errorBuilder: (context, error, stackTrace) {
                      // Show placeholder if asset fails to load
                      print('Error loading asset: $imageSource, Error: $error'); // Debugging
                      return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
                  },
            );
         } else if (imageSource.startsWith('http') || imageSource.startsWith('https')) {
             // Assume it's a network URL (most common for images from backend)
              return Image.network(
                  imageSource,
                  fit: fit,
                   errorBuilder: (context, error, stackTrace) {
                      // Show placeholder if network image fails
                      print('Error loading network image: $imageSource, Error: $error'); // Debugging
                      return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
                  },
              );
         }
         else {
           
            if (!kIsWeb) { // Only try File on non-web
                 try {
                   return Image.file(
                       File(imageSource),
                       fit: fit,
                        errorBuilder: (context, error, stackTrace) {
                           print('Error loading file: $imageSource, Error: $error'); // Debugging
                           return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
                       },
                   );
                 } catch (e) {
                   print('Exception creating File from path: $imageSource, Exception: $e'); // Debugging
                   return Icon(Icons.error_outline, size: iconSize, color: Colors.red);
                 }
            } else { // On web, if not asset/http, try network as a fallback (might be blob URL etc)
                 return Image.network(
                    imageSource,
                    fit: fit,
                     errorBuilder: (context, error, stackTrace) {
                        print('Error loading web path (fallback): $imageSource, Error: $error'); // Debugging
                        return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
                    },
                );
            }
         }
      }

      // Fallback for unknown source type
      return Icon(Icons.error_outline, size: iconSize, color: Colors.red); // Indicate error
    }


  @override
  Widget build(BuildContext context) {
    // Check if app data is loaded before building
     if (!AppDataService().isInitialized) {
         return Scaffold(
           appBar: AppBar(title: Text('Loading Data')),
           body: Center(child: CircularProgressIndicator()),
         );
     }


    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Thêm Sản phẩm' : 'Cập nhật Sản phẩm'),
      ),
      body: Padding(
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
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên sản phẩm';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Default Image (Main Product)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ảnh mặc định (Sản phẩm chính):', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickImage(true),
                    child: Container(
                      width: 100,
                      height: 100,
                       decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(8),
                         color: Colors.grey[200],
                       ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildImageDisplayWidget(
                           _defaultImage ?? _initialDefaultImagePath,
                           size: 100,
                           iconSize: 40,
                           fit: BoxFit.cover
                         ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Additional Images (Main Product)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ảnh góc minh họa (Sản phẩm chính, có thể chọn nhiều):', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                   Wrap(
                     spacing: 8,
                     runSpacing: 8,
                     children: [
                       // Display ALL current image sources (initial paths + newly picked XFiles)
                       // Combine initial paths and paths from XFiles for display
                       ...( _initialAdditionalImagePaths + _additionalImages.map((x) => x.path).toList() ).map((imagePath) {

                           return Stack(
                             children: [
                               Container(
                                 width: 80,
                                 height: 80,
                                 decoration: BoxDecoration(
                                   borderRadius: BorderRadius.circular(8),
                                   color: Colors.grey[200],
                                 ),
                                 clipBehavior: Clip.antiAlias,
                                 child: _buildImageDisplayWidget(imagePath, size: 80, iconSize: 30),
                               ),
                               Positioned(
                                 right: 0,
                                 top: 0,
                                 child: GestureDetector(
                                   onTap: () {
                                     setState(() {
                                       // Logic to remove the image source based on the path
                                       // Try removing the imagePath string from initial paths first
                                       bool removedFromInitial = _initialAdditionalImagePaths.remove(imagePath);

                                       // If it wasn't found in initial paths,
                                       // try removing the corresponding XFile from picked images by comparing paths
                                       if (!removedFromInitial) {
                                           _additionalImages.removeWhere((xfile) => xfile.path == imagePath);
                                       }
                                       // setState is already called here implicitly by the state update within this block.
                                     });
                                   },
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
                       }).toList(), // Remember to call .toList() on the map result
                       // Add button to pick more images
                       GestureDetector(
                         onTap: () => _pickImage(false),
                         child: Container(
                           width: 80,
                           height: 80,
                           decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[200],
                           ),
                           child: const Icon(Icons.add, size: 40, color: Colors.grey),
                         ),
                       ),
                     ],
                   ),
                ],
              ),
              const SizedBox(height: 16),

              // Brand Dropdown (Main Product)
              DropdownButtonFormField<BrandDTO>( // Type is now BrandDTO
                value: _selectedBrand,
                decoration: const InputDecoration(labelText: 'Thương hiệu'),
                 items: _brands.map((brand) {
                  return DropdownMenuItem<BrandDTO>( // Item type is BrandDTO
                    value: brand, // Value is the BrandDTO object
                    child: Text(brand.name ?? ''), // Display the name
                  );
                }).toList(),
                onChanged: (BrandDTO? newValue) { // newValue is BrandDTO?
                  setState(() {
                    _selectedBrand = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) { // Check if value is null
                    return 'Vui lòng chọn thương hiệu';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown (Main Product)
              DropdownButtonFormField<CategoryDTO>( // Type is now CategoryDTO
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Danh mục'),
                items: _categories.map((category) {
                  return DropdownMenuItem<CategoryDTO>( // Item type is CategoryDTO
                    value: category, // Value is the CategoryDTO object
                    child: Text(category.name ?? ''), // Display the name
                  );
                }).toList(),
                onChanged: (CategoryDTO? newValue) { // newValue is CategoryDTO?
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) { // Check if value is null
                    return 'Vui lòng chọn danh mục';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description (Main Product)
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả'),
                maxLines: 5,
                minLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mô tả';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Discount (Main Product)
              TextFormField(
                controller: _discountController,
                decoration: const InputDecoration(labelText: 'Giảm giá (%) (Tối đa 50%)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true), // Allow decimal for discount
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null; // Discount is optional
                  }
                  final discount = double.tryParse(value);
                   if (discount == null) {
                    return 'Giảm giá phải là số';
                  }
                  if (discount < 0 || discount > 50) {
                      return 'Giảm giá phải từ 0 đến 50%';
                  }
                  return null;
                },
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
                  return VariantInput(
                    key: ValueKey(_variants[index]), // Use ValueKey for proper state management
                    variant: _variants[index],
                    onRemove: () => _removeVariant(index),
                    isRemovable: _variants.length > 1, // Allow removal if there's more than one variant
                  );
                },
              ),
              const SizedBox(height: 16),

              // Add Variant Button
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: _addVariant,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm biến thể'),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
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
    );
  }
}

// Helper class for Variant data
class Variant {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  XFile? defaultImage; // Holds NEWLY picked image (XFile) for this variant
  String? initialImagePath; // Holds path/URL of EXISTING image (String) when editing

  // Optional: Store original variant ID if editing
  // int? originalId;


  final ImagePicker _picker = ImagePicker();

  // Function to pick the default image for variant
  // Requires a setState callback from the parent widget to rebuild the UI
  Future<void> pickDefaultImage(Function setStateCallback) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setStateCallback(() {
        defaultImage = pickedFile;
        // When a new image is picked, clear the initial path
        initialImagePath = null;
      });
    }
  }

  // Method to dispose controllers
  void disposeControllers() {
    nameController.dispose();
    priceController.dispose();
    quantityController.dispose();
  }

  // Convert variant data to JSON (for saving)
  Map<String, dynamic> toJson() {
    // When saving, prefer the newly picked image's path (defaultImage) if it exists,
    // otherwise use the initial image path/URL if it exists (for edited products).
    String? finalImagePath = defaultImage?.path ?? initialImagePath;

    return {
      // Include necessary data for saving (matching backend/data model)
      // Include originalId if editing
      // if (originalId != null) 'id': originalId,
      'name': nameController.text,
      'price': double.tryParse(priceController.text) ?? 0.0, // Save as double
      'quantity': int.tryParse(quantityController.text) ?? 0, // Save as int
      'defaultImage': finalImagePath, // This will be the path/URL string
       // If editing, carry over original SKU, created_date, updated_date if your data model includes them
       // e.g., 'sku': this.originalSku, 'created_date': this.originalCreatedDate, ...
    };
  }
}

// Widget for Variant Input
class VariantInput extends StatefulWidget {
  final Variant variant;
  final VoidCallback onRemove;
  final bool isRemovable;
  // initialImagePath is now part of the Variant object itself

  const VariantInput({
    Key? key,
    required this.variant,
    required this.onRemove,
    required this.isRemovable,
  }) : super(key: key);

  @override
  _VariantInputState createState() => _VariantInputState();
}

class _VariantInputState extends State<VariantInput> {
  // Dispose controllers is handled by the parent AddUpdateProductScreen
  // when a variant is removed or the screen is disposed.

   // Helper to build image widget from source (Handles Asset, File, Network, XFile based on platform)
  // Duplicate from parent, could be refactored into a shared utility widget.
  Widget _buildImageDisplayWidget(dynamic imageSource, {double size = 40, double iconSize = 30, BoxFit fit = BoxFit.cover}) {
      if (imageSource == null) {
        return Icon(Icons.camera_alt, size: iconSize, color: Colors.grey); // Placeholder if no image source
      }

      // If it's an XFile (newly picked image)
      if (imageSource is XFile) {
          if (kIsWeb) {
               // On Web, XFile.path is typically a blob URL or similar web reference
              return Image.network(
                   imageSource.path,
                   fit: fit,
                   errorBuilder: (context, error, stackTrace) {
                       print('Error loading web picked image: ${imageSource.path}, Error: $error'); // Debugging
                       return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
                   },
               );
          } else {
               // On non-Web, XFile.path is a file path
               try {
                  return Image.file(
                      File(imageSource.path),
                      fit: fit,
                       errorBuilder: (context, error, stackTrace) {
                          print('Error loading file picked image: ${imageSource.path}, Error: $error'); // Debugging
                          return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
                       },
                  );
               } catch (e) {
                 print('Exception creating File from XFile path: ${imageSource.path}, Exception: $e'); // Debugging
                 return Icon(Icons.error_outline, size: iconSize, color: Colors.red);
               }
          }
      }

      // If it's a String (initial path from data or potentially a network URL)
      if (imageSource is String && imageSource.isNotEmpty) {
           // Check if it's an asset path (simple check) - Less likely for server data
           if (imageSource.startsWith('assets/')) {
              return Image.asset(
                   imageSource,
                   fit: fit,
                    errorBuilder: (context, error, stackTrace) {
                        // Show placeholder if asset fails to load
                        print('Error loading asset: $imageSource, Error: $error'); // Debugging
                        return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
                    },
              );
           } else if (imageSource.startsWith('http') || imageSource.startsWith('https')) {
               // Assume it's a network URL (most common for images from backend)
                return Image.network(
                    imageSource,
                    fit: fit,
                     errorBuilder: (context, error, stackTrace) {
                        // Show placeholder if network image fails
                        print('Error loading network image: $imageSource, Error: $error'); // Debugging
                        return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
                    },
                );
           }
           else {
              // Could be a file path on non-web, or a relative server path.
              // If it's a relative server path, it needs the base URL.
               // Assuming this is a file path on non-web, or possibly needs ProductService().getImageUrl(...)
               // For this example, let's assume it's either a network URL or a file path.
               if (!kIsWeb) { // Only try File on non-web
                    try {
                      return Image.file(
                          File(imageSource),
                          fit: fit,
                           errorBuilder: (context, error, stackTrace) {
                              print('Error loading file: $imageSource, Error: $error'); // Debugging
                              return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
                          },
                      );
                    } catch (e) {
                      print('Exception creating File from path: $imageSource, Exception: $e'); // Debugging
                      return Icon(Icons.error_outline, size: iconSize, color: Colors.red);
                    }
               } else { // On web, if not asset/http, try network as a fallback (might be blob URL etc)
                    return Image.network(
                       imageSource,
                       fit: fit,
                        errorBuilder: (context, error, stackTrace) {
                           print('Error loading web path (fallback): $imageSource, Error: $error'); // Debugging
                           return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
                       },
                   );
               }
           }
      }

      // Fallback for unknown source type
      return Icon(Icons.error_outline, size: iconSize, color: Colors.red); // Indicate error
    }


  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Biến thể',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (widget.isRemovable) // Only show remove button if removable
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: widget.onRemove,
                    tooltip: 'Xóa biến thể',
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Variant Name
            TextFormField(
              controller: widget.variant.nameController,
              decoration: const InputDecoration(labelText: 'Tên biến thể'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên biến thể';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Default Image (Variant)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ảnh mặc định (Biến thể):', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => widget.variant.pickDefaultImage(setState), // Use the variant's pick method and pass setState
                  child: Container(
                    width: 80,
                    height: 80,
                     decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                       ),
                      clipBehavior: Clip.antiAlias,
                    // Display logic: Use picked image (XFile) if available, otherwise use initial path (String) if available, otherwise placeholder icon
                    child: _buildImageDisplayWidget(
                         widget.variant.defaultImage ?? widget.variant.initialImagePath,
                         size: 80,
                         iconSize: 30,
                         fit: BoxFit.cover
                       ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Price (Variant)
            TextFormField(
              controller: widget.variant.priceController,
              decoration: const InputDecoration(labelText: 'Giá bán (VNĐ)'),
              keyboardType: TextInputType.numberWithOptions(decimal: true), // Allow decimal
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập giá bán';
                }
                 final price = double.tryParse(value);
                 if (price == null) {
                    return 'Giá bán phải là số';
                  }
                 if (price <= 0) { // Price must be positive
                    return 'Giá bán phải lớn hơn 0';
                  }
                return null;
              },
            ),
            const SizedBox(height: 16),

             // Quantity (Variant)
            TextFormField(
              controller: widget.variant.quantityController,
              decoration: const InputDecoration(labelText: 'Số lượng tồn kho'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số lượng tồn kho';
                }
                 final quantity = int.tryParse(value);
                 if (quantity == null) {
                    return 'Số lượng tồn kho phải là số nguyên';
                  }
                if (quantity < 0) { // Quantity can be 0 but not negative
                     return 'Số lượng tồn kho không thể âm';
                 }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
