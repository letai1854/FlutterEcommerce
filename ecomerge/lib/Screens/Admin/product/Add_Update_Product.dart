import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddUpdateProductScreen extends StatefulWidget {
  // Optional product data for editing
  final Map<String, dynamic>? product;

  const AddUpdateProductScreen({Key? key, this.product}) : super(key: key);

  @override
  _AddUpdateProductScreenState createState() => _AddUpdateProductScreenState();
}

class _AddUpdateProductScreenState extends State<AddUpdateProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();

  // State for image selection
  XFile? _defaultImage;
  final List<XFile> _additionalImages = [];
  final ImagePicker _picker = ImagePicker();

  // State for dropdowns (dummy data)
  String? _selectedBrand;
  final List<String> _brands = ['Brand A', 'Brand B', 'Brand C'];

  String? _selectedCategory;
  final List<String> _categories = ['Category X', 'Category Y', 'Category Z'];

  // State for variants
  final List<Variant> _variants = [];

  @override
  void initState() {
    super.initState();
    // Populate fields if editing an existing product
    if (widget.product != null) {
      _nameController.text = widget.product!['name'] ?? '';
      _descriptionController.text = widget.product!['description'] ?? '';
      _priceController.text = widget.product!['price']?.toString() ?? '';
      _discountController.text = widget.product!['discount']?.toString() ?? '0';
      _selectedBrand = widget.product!['brand'];
      _selectedCategory = widget.product!['category'];
      // TODO: Load existing images and variants
    } else {
      // Add initial variants for new product
      _addVariant();
      _addVariant();
      _addVariant();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  // Function to pick an image
  Future<void> _pickImage(bool isDefault) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isDefault) {
          _defaultImage = pickedFile;
        } else {
          _additionalImages.add(pickedFile);
        }
      });
    }
  }

  // Function to add a new variant
  void _addVariant() {
    setState(() {
      _variants.add(Variant());
    });
  }

  // Function to remove a variant
  void _removeVariant(int index) {
    setState(() {
      _variants.removeAt(index);
    });
  }

  // Function to handle form submission
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // TODO: Process form data (save product)
      print('Form submitted');
      print('Product Name: ${_nameController.text}');
      print('Description: ${_descriptionController.text}');
      print('Price: ${_priceController.text}');
      print('Discount: ${_discountController.text}');
      print('Brand: $_selectedBrand');
      print('Category: $_selectedCategory');
      print('Default Image: ${_defaultImage?.path}');
      print('Additional Images: ${_additionalImages.map((img) => img.path).toList()}');
      print('Variants: ${_variants.map((v) => v.toJson()).toList()}');

      // Navigate back after saving
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 768;

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
              // Main Product Info
              Text(
                'Nhập sản phẩm chính:',
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

              // Default Image
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ảnh mặc định:', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickImage(true),
                    child: Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[200],
                  child: _defaultImage != null
                          ? Image.file(File(_defaultImage!.path), fit: BoxFit.cover)
                          : const Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                    ),
                  ),
                  // Removed validation check from here
                ],
              ),
              const SizedBox(height: 16),

              // Additional Images
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ảnh góc khác:', style: TextStyle(fontSize: 16)), // Removed minimum requirement text
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._additionalImages.map((image) => Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: FileImage(File(image.path)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _additionalImages.remove(image);
                                    });
                                  },
                                  child: Container(
                                    color: Colors.black54,
                                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          )),
                      GestureDetector(
                        onTap: () => _pickImage(false),
                        child: Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(Icons.add, size: 40, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                   // Removed validation check from here
                ],
              ),
              const SizedBox(height: 16),

              // Brand Dropdown
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

              // Category Dropdown
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

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả'),
                maxLines: 5,
                minLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mô tả';
                  }
                  // Removed minimum line requirement
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Giá bán'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập giá bán';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Giá bán phải là số';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Discount
              TextFormField(
                controller: _discountController,
                decoration: const InputDecoration(labelText: 'Giảm giá (%)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null; // Discount is optional
                  }
                   if (double.tryParse(value) == null) {
                    return 'Giảm giá phải là số';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Variants Section
              Text(
                'Nhập biến thể:', // Removed minimum requirement text
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
                    isRemovable: _variants.length > 0, // Allow removal if there's at least one variant
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
  final TextEditingController discountController = TextEditingController();
  XFile? defaultImage;
  final List<XFile> additionalImages = [];
  String? selectedBrand;
  String? selectedCategory;
  final ImagePicker _picker = ImagePicker();

  // Function to pick an image for variant
  Future<void> pickImage(bool isDefault, Function setStateCallback) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setStateCallback(() {
        if (isDefault) {
          defaultImage = pickedFile;
        } else {
          additionalImages.add(pickedFile);
        }
      });
    }
  }

  // Function to remove additional image for variant
  void removeAdditionalImage(XFile image, Function setStateCallback) {
     setStateCallback(() {
        additionalImages.remove(image);
     });
  }

  // Dummy data for variant dropdowns (can be shared or separate)
  final List<String> brands = ['Variant Brand A', 'Variant Brand B', 'Variant Brand C'];
  final List<String> categories = ['Variant Category X', 'Variant Category Y', 'Variant Category Z'];


  Map<String, dynamic> toJson() {
    return {
      'name': nameController.text,
      'price': priceController.text,
      'quantity': quantityController.text,
      'discount': discountController.text,
      'defaultImage': defaultImage?.path,
      'additionalImages': additionalImages.map((img) => img.path).toList(),
      'brand': selectedBrand,
      'category': selectedCategory,
    };
  }
}

// Widget for Variant Input
class VariantInput extends StatefulWidget {
  final Variant variant;
  final VoidCallback onRemove;
  final bool isRemovable;

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
  @override
  void dispose() {
    widget.variant.nameController.dispose();
    widget.variant.priceController.dispose();
    widget.variant.quantityController.dispose();
    widget.variant.discountController.dispose();
    super.dispose();
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
                if (widget.isRemovable)
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

            // Default Image
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ảnh mặc định:', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => widget.variant.pickImage(true, setState),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: widget.variant.defaultImage != null
                        ? Image.file(File(widget.variant.defaultImage!.path), fit: BoxFit.cover)
                        : const Icon(Icons.camera_alt, size: 30, color: Colors.grey),
                  ),
                ),
                 // Removed validation check from here
              ],
            ),
            const SizedBox(height: 16),

            // Additional Images
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ảnh góc khác:', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...widget.variant.additionalImages.map((image) => Stack(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(File(image.path)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () => widget.variant.removeAdditionalImage(image, setState),
                                child: Container(
                                  color: Colors.black54,
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        )),
                    GestureDetector(
                      onTap: () => widget.variant.pickImage(false, setState),
                      child: Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(Icons.add, size: 30, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Brand Dropdown
            DropdownButtonFormField<String>(
              value: widget.variant.selectedBrand,
              decoration: const InputDecoration(labelText: 'Thương hiệu'),
              items: widget.variant.brands.map((brand) {
                return DropdownMenuItem(
                  value: brand,
                  child: Text(brand),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  widget.variant.selectedBrand = newValue;
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

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: widget.variant.selectedCategory,
              decoration: const InputDecoration(labelText: 'Danh mục'),
              items: widget.variant.categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  widget.variant.selectedCategory = newValue;
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

            // Price
            TextFormField(
              controller: widget.variant.priceController,
              decoration: const InputDecoration(labelText: 'Giá bán'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập giá bán';
                }
                 if (double.tryParse(value) == null) {
                    return 'Giá bán phải là số';
                  }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Discount
            TextFormField(
              controller: widget.variant.discountController,
              decoration: const InputDecoration(labelText: 'Giảm giá (%)'),
              keyboardType: TextInputType.number,
               validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null; // Discount is optional
                  }
                   if (double.tryParse(value) == null) {
                    return 'Giảm giá phải là số';
                  }
                  return null;
                },
            ),
             const SizedBox(height: 16),

             // Quantity
            TextFormField(
              controller: widget.variant.quantityController,
              decoration: const InputDecoration(labelText: 'Số lượng tồn kho'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số lượng tồn kho';
                }
                 if (int.tryParse(value) == null) {
                    return 'Số lượng tồn kho phải là số nguyên';
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
