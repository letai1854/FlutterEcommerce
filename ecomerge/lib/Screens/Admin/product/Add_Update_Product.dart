import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // Keep dart:io for File on non-web platforms
import 'package:flutter/foundation.dart'; // Import for kIsWeb

class AddUpdateProductScreen extends StatefulWidget {
  // Optional product data for editing
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

  // State for dropdowns (Main Product - dummy data)
  String? _selectedBrand;
  final List<String> _brands = ['Apple', 'Dell','HP','Lenovo', 'Asus','Acer','MSI','Razer','Intel','AMD','NVIDIA','ASRock','Corsair','Crucial','Seagate','Samsung','Kingston','Noctua','DeepCool','NZXT','Corsair','Thermaltake'];

  String? _selectedCategory;
  final List<String> _categories = ['Máy tính', 'CPU', 'GPU',''];

  // State for variants
  final List<Variant> _variants = [];

  // Variables to hold initial image paths (String) for display in edit mode
  // These are loaded from existing product data and are NOT XFiles.
  // They are used for display until a new image is picked for that slot.
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
      _discountController.text = widget.product!['discount']?.toString() ?? '0';
      // Set dropdown values if they exist in the product data and are in the dummy lists
      if (_brands.contains(widget.product!['brand'])) {
         _selectedBrand = widget.product!['brand'];
      }
      if (_categories.contains(widget.product!['category'])) {
         _selectedCategory = widget.product!['category'];
      }


      // --- Load Main Product Images Paths for initial display ---
      // We assume 'images' in product data is a List<String> or List<dynamic> containing paths/URLs
      final List<dynamic> productImages = widget.product!['images'] ?? [];
      // Ensure paths are strings and filter out nulls
      final List<String> validInitialImagePaths = productImages.where((img) => img != null && img is String).cast<String>().toList();

      if (validInitialImagePaths.isNotEmpty) {
        // Assuming the first image in the list is the default one
        _initialDefaultImagePath = validInitialImagePaths.first;
        if (validInitialImagePaths.length > 1) {
          _initialAdditionalImagePaths.addAll(validInitialImagePaths.sublist(1));
        }
      }
       // Note: _defaultImage and _additionalImages state variables remain null/empty here initially.
       // They will only be populated if the user picks a *new* image using the picker.


      // --- Load Variant Data ---
      // We assume 'variants' in product data is a List<Map<String, dynamic>>
      List<Map<String, dynamic>> existingVariantsData = List<Map<String, dynamic>>.from(widget.product!['variants'] ?? []);

      // Clear any default variants added previously if editing
      _variants.clear();

      if (existingVariantsData.isNotEmpty) {
        for (var variantData in existingVariantsData) {
           Variant variant = Variant();
           // Populate controllers from existing data
           variant.nameController.text = variantData['name'] ?? '';
           // Ensure price and quantity are strings before setting controllers
           variant.priceController.text = variantData['price']?.toString() ?? '';
           variant.quantityController.text = variantData['quantity']?.toString() ?? '';

           // Store initial variant image path for display
           // We assume 'defaultImage' in variantData is a String path/URL
           variant.initialImagePath = variantData['defaultImage']?.toString(); // Use the new field in Variant, ensure string

           _variants.add(variant); // Add the populated variant object to the list
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
           // When a new default image is picked, clear the initial path
          _initialDefaultImagePath = null;
        } else {
          _additionalImages.add(pickedFile);
           // Note: This simple logic adds new images. It doesn't remove initial ones
           // from the _initialAdditionalImagePaths list automatically. The UI remove button
           // handles removing from both lists.
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
           return; // Stop submission if no variants
       }

       // You might want to add a check here to ensure variant fields (name, price, quantity)
       // are also valid before submitting the entire form.
       // e.g., for (var variant in _variants) { if (!variant.isValid()) { ... } }
       // This requires adding validation logic inside the Variant class or VariantInput.


      // TODO: Process form data (save product)
      // When saving, you need to determine the final image sources.
      // For default image: use _defaultImage?.path if picked, otherwise use _initialDefaultImagePath.
      // For additional images: combine _initialAdditionalImagePaths and paths from _additionalImages.

      print('Form submitted');
      print('Product Name: ${_nameController.text}');
      print('Description: ${_descriptionController.text}');
      print('Discount: ${_discountController.text}');
      print('Brand: $_selectedBrand');
      print('Category: $_selectedCategory');

      // Collecting final image paths for saving
      String? finalDefaultImagePath = _defaultImage?.path ?? _initialDefaultImagePath;
      // Combine initial paths and newly picked paths for additional images
      List<String> finalAdditionalImagePaths = [
         ..._initialAdditionalImagePaths, // Include initial paths remaining
         ..._additionalImages.map((img) => img.path).toList(), // Add newly picked images
      ];

      print('Default Image Path (Final): $finalDefaultImagePath');
      print('Additional Image Paths (Final): $finalAdditionalImagePaths');


      // Collect variant data including image paths
      List<Map<String, dynamic>> variantsData = _variants.map((v) {
          // For variant image, use the new picked image's path OR the initial path
          String? finalVariantImagePath = v.defaultImage?.path ?? v.initialImagePath;
          return {
              // Include necessary data for saving (matching backend/data model)
              // Note: If editing, you might need to include the variant ID to update the correct variant.
              'name': v.nameController.text,
              'price': double.tryParse(v.priceController.text) ?? 0.0, // Save as double
              'quantity': int.tryParse(v.quantityController.text) ?? 0, // Save as int
              'defaultImage': finalVariantImagePath, // This will be the path/URL string (of XFile or initial)
               // If editing, carry over original SKU, created_date, updated_date if your data model includes them
               // e.g., 'sku': this.originalSku, 'created_date': this.originalCreatedDate, ...
          };
      }).toList();

      print('Variants Data (Final): $variantsData');

      // In a real application, you would send this collected data
      // (including final image paths/URLs after uploading images if needed)
      // to your backend API to save or update the product.

      // Navigate back after saving
      // This will pop the AddUpdateProductScreen and return to the previous screen (ProductScreen)
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
         // Check if it's an asset path (simple check)
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
             // Assume it's a network URL
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
           // Could be a file path on non-web, or a different web path.
           // For robustness, might need more sophisticated checks.
           // Assuming it's a file path on non-web, or a non-http web path that might work with network image.
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
                      // Removed direct color property
                      clipBehavior: Clip.antiAlias, // Apply border radius if any parent container has it
                       decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(8), // Optional: Add rounded corners
                         color: Colors.grey[200], // Moved color inside BoxDecoration
                       ),
                      // Display logic: Use picked image (XFile) if available, otherwise use initial path (String) if available, otherwise placeholder icon
                      child: _buildImageDisplayWidget(
                           _defaultImage ?? _initialDefaultImagePath, // Pass either XFile or String path
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
                       // Create a combined list of sources for display
                       ...( _initialAdditionalImagePaths + _additionalImages.map((x) => x.path).toList() ).map((imagePath) {
                           // This logic is to find the *original object* (String or XFile) that has this imagePath
                           dynamic originalSource;
                           // First, check if this path exists in the initial paths list
                           try {
                               originalSource = _initialAdditionalImagePaths.firstWhere((path) => path == imagePath);
                           } catch (e) {
                               // If not found in initial paths, check in the list of picked XFiles
                               try {
                                   originalSource = _additionalImages.firstWhere((xfile) => xfile.path == imagePath);
                               } catch (e) {
                                   // If not found in either, sourceToRemove remains null
                                    originalSource = null;
                               }
                           }


                           return Stack(
                             children: [
                               Container(
                                 width: 80,
                                 height: 80,
                                 // Removed direct color property
                                 decoration: BoxDecoration( // Moved color inside BoxDecoration
                                   borderRadius: BorderRadius.circular(8),
                                   color: Colors.grey[200], // Background if image fails
                                 ),
                                 clipBehavior: Clip.antiAlias,
                                 child: _buildImageDisplayWidget(imagePath, size: 80, iconSize: 30), // Use helper to display by path
                               ),
                               Positioned(
                                 right: 0,
                                 top: 0,
                                 child: GestureDetector(
                                   onTap: () {
                                     setState(() {
                                       // Try removing the imagePath string from initial paths first
                                       bool removedFromInitial = _initialAdditionalImagePaths.remove(imagePath);

                                       // If it wasn't found in initial paths,
                                       // try removing the corresponding XFile from picked images
                                       if (!removedFromInitial) {
                                           _additionalImages.removeWhere((xfile) => xfile.path == imagePath);
                                       }
                                       // setState is already called here implicitly by the state update within this block.
                                     });
                                   },
                                   child: Container(
                                     // Removed direct color property
                                     padding: const EdgeInsets.all(2),
                                     decoration: BoxDecoration( // Moved color inside BoxDecoration
                                        color: Colors.black54, // Semi-transparent background for icon
                                        borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(8), // Match container radius
                                            bottomLeft: Radius.circular(8),
                                        )
                                     ),
                                     child: const Icon(Icons.close, color: Colors.white, size: 14), // Smaller icon
                                   ),
                                 ),
                               ),
                             ],
                           );
                       }),
                       // Add button to pick more images
                       GestureDetector(
                         onTap: () => _pickImage(false),
                         child: Container(
                           width: 80,
                           height: 80,
                           // Removed direct color property
                           decoration: BoxDecoration( // Moved color inside BoxDecoration
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
              DropdownButtonFormField<String>(
                value: _selectedBrand,
                decoration: const InputDecoration(labelText: 'Thương hiệu'),
                items: _brands.map((brand) {
                  return DropdownMenuItem(
                    value: brand,
                    child: Text(brand),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedBrand = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng chọn thương hiệu';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown (Main Product)
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Danh mục'),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
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
                keyboardType: TextInputType.number,
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

  final ImagePicker _picker = ImagePicker();

  // Function to pick the default image for variant
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
      // Note: If editing, you might need to include the variant ID to update the correct variant.
      'name': nameController.text,
      'price': double.tryParse(priceController.text) ?? 0.0, // Save as double
      'quantity': int.tryParse(quantityController.text) ?? 0, // Save as int
      'defaultImage': finalImagePath, // This will be the path/URL string (of XFile or initial)
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
           // Check if it's an asset path (simple check)
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
               // Assume it's a network URL
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
             // Could be a file path on non-web, or a different web path.
             // For robustness, might need more sophisticated checks.
             // Assuming it's a file path on non-web, or a non-http web path that might work with network image.
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
                  onTap: () => widget.variant.pickDefaultImage(setState), // Use the variant's pick method
                  child: Container(
                    width: 80,
                    height: 80,
                    // Removed direct color property
                     decoration: BoxDecoration( // Moved color inside BoxDecoration
                         borderRadius: BorderRadius.circular(8), // Optional: Add rounded corners
                          color: Colors.grey[200],
                       ),
                      clipBehavior: Clip.antiAlias,
                    // Display logic: Use picked image (XFile) if available, otherwise use initial path (String) if available, otherwise placeholder icon
                    child: _buildImageDisplayWidget(
                         widget.variant.defaultImage ?? widget.variant.initialImagePath, // Pass either XFile or String path
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
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập giá bán';
                }
                 if (double.tryParse(value) == null) {
                    return 'Giá bán phải là số';
                  }
                // You might want to add a check for price > 0
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
                // You might want to add a check for quantity >= 0
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
