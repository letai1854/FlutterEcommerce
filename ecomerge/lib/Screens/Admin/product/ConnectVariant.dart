import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// Helper class for Variant data
class Variant {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  // Stores the server URL for the variant image
  String? defaultImageUrl;

  // Optional: Store original variant ID if editing
  // This is needed if your backend update API requires variant IDs.
  int? originalId;


  // Constructor to initialize with potential existing URL and ID from edit mode
  Variant({this.defaultImageUrl, this.originalId});

  // Method to dispose controllers
  void disposeControllers() {
    nameController.dispose();
    priceController.dispose();
    quantityController.dispose();
  }

  // Convert variant data to JSON (for saving)
  // This method might be used when preparing DTOs for API calls.
  Map<String, dynamic> toJson() {
    // When saving, use the stored defaultImageUrl directly
    return {
      // Include originalId if editing (used in UpdateProductVariantDTO)
      if (originalId != null) 'id': originalId,
      'name': nameController.text,
      'price': double.tryParse(priceController.text) ?? 0.0, // Save as double
      'quantity': int.tryParse(quantityController.text) ?? 0, // Save as int
      'defaultImage': defaultImageUrl, // Use the stored URL
       // If editing, carry over original SKU, created_date, updated_date etc.
       // based on your DTO structure and backend requirements.
    };
  }
}

// Widget for Variant Input
class VariantInput extends StatefulWidget {
  final Variant variant;
  final VoidCallback onRemove;
  final bool isRemovable;
  // Callback to trigger image picking and uploading for this variant (provided by parent)
  final VoidCallback onPickImage;
  // Pass the processing state from the parent
  final bool isProcessing;


  const VariantInput({
    Key? key,
    required this.variant,
    required this.onRemove,
    required this.isRemovable,
    required this.onPickImage, // Callback from parent to pick/upload image
    required this.isProcessing, // Processing state from parent
  }) : super(key: key);

  @override
  _VariantInputState createState() => _VariantInputState();
}

class _VariantInputState extends State<VariantInput> {

   // Helper to build image widget from source (Handles Network URLs or Placeholder)
   // Simplified to handle only String URLs.
  Widget _buildImageDisplayWidget(String? imageUrl, {double size = 40, double iconSize = 30, BoxFit fit = BoxFit.cover}) {
      if (imageUrl == null || imageUrl.isEmpty) {
        return Icon(Icons.camera_alt, size: iconSize, color: Colors.grey); // Placeholder
      }

      // Assume it's a network URL from the server
      return Image.network(
          imageUrl,
          fit: fit,
          // Add a loading builder for better UX
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: SizedBox( // Use SizedBox to prevent layout changes during loading
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
              if (kDebugMode) print('Error loading network image: $imageUrl, Error: $error');
              return Icon(Icons.broken_image, size: iconSize, color: Colors.red); // Show placeholder/error if network image fails
           },
      );
    }


  @override
  Widget build(BuildContext context) {
    // Accessing the processing state passed from the parent
    final bool isProcessing = widget.isProcessing;

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
                    // Disable remove button when processing
                    onPressed: isProcessing ? null : widget.onRemove,
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
              // Disable input visually when processing
               enabled: !isProcessing,
            ),
            const SizedBox(height: 16),

            // Default Image (Variant) - Now uses uploaded URL
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ảnh mặc định (Biến thể):', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                GestureDetector(
                  // Call the parent's upload callback, disabled when processing
                  onTap: isProcessing ? null : widget.onPickImage,
                  child: Container(
                    width: 80,
                    height: 80,
                     decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                       ),
                      clipBehavior: Clip.antiAlias,
                    // Display the stored URL from the Variant object
                    child: _buildImageDisplayWidget(
                         widget.variant.defaultImageUrl, // Pass the URL state variable from the Variant object
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
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập giá bán';
                }
                 final price = double.tryParse(value);
                 if (price == null) {
                    return 'Giá bán phải là số';
                  }
                 if (price <= 0) {
                    return 'Giá bán phải lớn hơn 0';
                 }
                return null;
              },
              // Disable input visually when processing
              enabled: !isProcessing,
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
                if (quantity < 0) {
                     return 'Số lượng tồn kho không thể âm';
                 }
                return null;
              },
              // Disable input visually when processing
               enabled: !isProcessing,
            ),
          ],
        ),
      ),
    );
  }
}
