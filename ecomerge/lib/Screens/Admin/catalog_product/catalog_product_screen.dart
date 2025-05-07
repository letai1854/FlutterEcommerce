import 'package:flutter/material.dart';
import 'dart:math' show max;
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // For File class (used with Image.file on non-web)
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode; // For platform checks and debug prints
import 'package:flutter/scheduler.dart'; // For addPostFrameCallback
import 'dart:typed_data'; // For Uint8List (reading picked image bytes)
import 'package:collection/collection.dart'; // For firstWhereOrNull

// Import necessary DTOs, Services, and the Singleton
import 'package:e_commerce_app/database/Storage/BrandCategoryService.dart'; // Assuming AppDataService is here
import 'package:e_commerce_app/database/models/categories.dart'; // Assuming CategoryDTO is here
import 'package:e_commerce_app/database/services/categories_service.dart'; // Import CategoriesService
// Import the DTOs for Create/Update Category requests (assuming they exist)
import 'package:e_commerce_app/database/models/categores/CreateCategoryRequestDTO.dart'; // Assuming this exists
import 'package:e_commerce_app/database/models/categores/UpdateCategoryRequestDTO.dart'; // Assuming this exists


// Helper class to hold locally picked image data temporarily before upload
// (Assuming this is defined here or imported)
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

// --- Main Screen Widget ---
class CatalogProductScreen extends StatefulWidget {
  const CatalogProductScreen({Key? key}) : super(key: key);

  @override
  _CatalogProductScreenState createState() => _CatalogProductScreenState();
}

class _CatalogProductScreenState extends State<CatalogProductScreen> {

  // --- Removed State for Filtering and Search ---
  // String _selectedFilter = 'Tất cả';
  // final List<String> _filterOptions = [...];
  // DateTimeRange? _customDateRange;
  // Removed _getStartDate() and _showDateRangePicker()
  // Removed _catalogProductData dummy list


  // --- Data Source ---
  // The source of truth is the singleton's categories list
  List<CategoryDTO> get _allCategories => AppDataService().categories;

  // --- Pagination State (Manual for ListView) ---
  int _currentPage = 0;
  final int _rowsPerPage = 10; // Fixed items per page

  // Get the categories for the current page from the singleton's list
  List<CategoryDTO> get _paginatedCategories {
    final startIndex = _currentPage * _rowsPerPage;
    // Ensure startIndex is within bounds
    if (startIndex >= _allCategories.length) return [];
    // Ensure endIndex is within bounds
    final endIndex = (startIndex + _rowsPerPage).clamp(0, _allCategories.length);

    return _allCategories.sublist(startIndex, endIndex);
  }

  // Calculate total pages based on the singleton's list length
  int get _pageCount => _allCategories.isEmpty ? 1 : (_allCategories.length / _rowsPerPage).ceil();


  // --- Image Picking State (for Add/Edit dialog) ---
  // XFile? _selectedImageFile; // Removed - not needed to store the file itself in screen state
  PickedImage? _currentPickedImage; // Holds bytes and upload state for the dialog preview

  final ImagePicker _picker = ImagePicker(); // Image picker instance


  // --- Service Instances ---
  // Use instances of the services
  // These are typically accessed via singleton or provider if they manage state,
  // but okay to instantiate here if stateless or managed externally.
  // Assuming CategoriesService manages its http.Client internally.
  final CategoriesService _categoriesService = CategoriesService();
  // If ProductService is also needed for other things in this screen, include it:
  // final ProductService _productService = ProductService();


  // --- Processing State (for dialog/API calls) ---
  bool _isProcessingDialog = false; // To disable buttons/inputs in the dialog


  // --- Image Display Helper ---
  // Helper to build image widget from source (Handles PickedImage, server RELATIVE path String, or Placeholder)
  // This helper is used for displaying images in the list and in the dialog preview.
  Widget _buildImageWidget(dynamic imageSource, {double size = 40, double iconSize = 40, BoxFit fit = BoxFit.cover}) {
    // Check if CategoriesService instance is available before calling getImageUrl
    if (_categoriesService == null) {
        if (kDebugMode) print('[_buildImageWidget] Error: CategoriesService is null.');
        return const Icon(Icons.error, size: 40, color: Colors.purple);
    }

    if (imageSource == null || (imageSource is String && imageSource.isEmpty)) {
      return Icon(Icons.image, size: iconSize, color: Colors.grey); // Placeholder icon
    }

     if (imageSource is PickedImage) {
        // Display locally picked image bytes with potential upload indicator
        return Stack(
           fit: StackFit.expand,
           children: [
              Image.memory(
                 imageSource.bytes,
                 fit: fit,
                  errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Icon(Icons.warning_amber));
                  },
              ),
              if (imageSource.isUploading) // Show loading indicator if uploading
                 const Positioned.fill(
                    child: Center(child: CircularProgressIndicator()),
                 ),
           ],
        );
     }


    // Assume imageSource is a server relative path (e.g., "/uploads/...")
    // Use the helper from CategoriesService to get the full URL for network loading
    String fullImageUrl = _categoriesService.getImageUrl(imageSource.toString()); // Ensure it's treated as string

     if (kDebugMode) {
         // print('[_buildImageWidget] Using FULL URL for Image.network: $fullImageUrl (Original source: $imageSource)');
     }

     // Use Image.network for all non-empty string paths, as they are assumed to be URLs or paths resolvable by the service's getImageUrl
    return Image.network(
      fullImageUrl,
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
       // Add error builder for network images
      errorBuilder: (context, error, stackTrace) {
         if (kDebugMode) print('[_buildImageWidget] Image.network failed for $fullImageUrl (Original: $imageSource): $error');
         // Show placeholder if network image fails
        return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
      },
    );
  }


  // --- Image Picking and Upload Logic for Dialog ---
  // Pass setStateDialog to update the state of the dialog itself
  Future<void> _pickAndUploadImageForDialog(StateSetter setStateDialog) async {
      // Prevent picking if already processing upload in dialog
      if (_currentPickedImage != null && _currentPickedImage!.isUploading) {
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Vui lòng chờ ảnh đang tải lên.'), duration: const Duration(seconds: 2)),
          );
          return;
      }
       // Prevent picking if the whole dialog is submitting
      if (_isProcessingDialog) return;


      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
          PickedImage? picked;
           try {
              // Read image bytes and get file name
              final imageBytes = await pickedFile.readAsBytes();
              final fileName = pickedFile.name;

               if (imageBytes.isEmpty) throw Exception('Không đọc được dữ liệu ảnh.');

              // Create PickedImage object and mark it as uploading
              picked = PickedImage(bytes: imageBytes, fileName: fileName, isUploading: true);

              // Use addPostFrameCallback to update the dialog UI immediately after the current build frame
              SchedulerBinding.instance.addPostFrameCallback((_) {
                 if (mounted) { // Ensure the screen widget is still mounted
                     setStateDialog(() { // Use setStateDialog to update the dialog's state
                         _currentPickedImage = picked; // Show the local image preview and indicator
                         // Don't clear the _dialogImageUrlForSubmission yet, only update it on successful upload
                     });
                      // Show a transient Snackbar indicating upload started
                     ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text('Đang tải ảnh lên: ${picked}'), duration: const Duration(seconds: 2)),
                     );
                 }
             });


              // *** CALL UPLOAD API ***
              final String? imageRelativePath = await _categoriesService.uploadImage(picked.bytes, picked.fileName);

              // Hide "Uploading" Snackbar
               if(mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();


              // Use another addPostFrameCallback to update the dialog UI after upload result
               SchedulerBinding.instance.addPostFrameCallback((_) {
                  if (mounted) { // Ensure the screen widget is still mounted
                      setStateDialog(() { // Use setStateDialog to update the dialog's state
                          // Check if the PickedImage object that initiated the upload is still the one being displayed
                          if (_currentPickedImage != null && _currentPickedImage == picked) {
                              _currentPickedImage!.isUploading = false; // Mark as not uploading

                              if (imageRelativePath != null && imageRelativePath.isNotEmpty) {
                                  // UPLOAD SUCCESS: Store the server path, clear local data
                                  _currentPickedImage = null; // Clear local PickedImage
                                  _dialogImageUrlForSubmission = imageRelativePath; // Store the RELATIVE path for submission
                                   if (kDebugMode) print('Upload successful. Storing RELATIVE path for submission: $_dialogImageUrlForSubmission');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                     const SnackBar(content: Text('Tải ảnh lên thành công'), backgroundColor: Colors.green),
                                  );
                              } else {
                                  // UPLOAD FAILURE: Server didn't return a path. Clear local data.
                                  if (kDebugMode) print('Upload failed: Server returned empty path.');
                                  _currentPickedImage = null; // Clear local PickedImage
                                  // _dialogImageUrlForSubmission remains the old one or null
                                  ScaffoldMessenger.of(context).showSnackBar(
                                     const SnackBar(content: Text('Tải ảnh lên thất bại: Server không trả về đường dẫn ảnh.'), backgroundColor: Colors.red),
                                  );
                              }
                          } else {
                              // State changed during upload (e.g., dialog closed or image removed), nothing to do with UI for this PickedImage
                               if (kDebugMode) print('Upload finished but picked image state changed or dialog closed.');
                          }
                      });
                  }
              });


           } catch (e) {
              // Handle exceptions during pick, read, or upload
              if (kDebugMode) print('Upload failed due to exception: $e');
               // Hide "Uploading" Snackbar
               if(mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
              // Update dialog state on failure
               SchedulerBinding.instance.addPostFrameCallback((_) {
                  if (mounted) { // Ensure the screen widget is still mounted
                      setStateDialog(() { // Use setStateDialog to update the dialog's state
                          // Check if the PickedImage object that initiated the upload is still the one being displayed
                          if (_currentPickedImage != null && _currentPickedImage == picked) {
                               if (_currentPickedImage != null) _currentPickedImage!.isUploading = false; // Mark as not uploading
                              _currentPickedImage = null; // Clear local data on failure
                          } else {
                               if (kDebugMode) print('Upload failed due to exception, but picked image state changed or dialog closed.');
                          }
                      });
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text('Tải ảnh lên thất bại: ${e.toString()}'), backgroundColor: Colors.red),
                       );
                  }
              });
           }
      }
  }

  // State variable to hold the final image URL/path for the category DTO within the dialog scope
  // This will be set from initial data or after a successful upload
  String? _dialogImageUrlForSubmission;


  // --- Dialogs (Add/Edit) ---

  // Now takes CategoryDTO? for editing, null for adding
  void _showCategoryDialog([CategoryDTO? categoryToEdit]) {
    final bool isEditing = categoryToEdit != null;
    final TextEditingController nameController = TextEditingController(
      text: isEditing ? categoryToEdit!.name : '', // Use DTO properties
    );
    // Reset image states for the dialog when it opens
    _currentPickedImage = null;
    // Set the initial image URL for submission based on the existing category or null for new
    _dialogImageUrlForSubmission = isEditing ? categoryToEdit!.imageUrl : null;

    showDialog(
      context: context,
      // StatefulBuilder allows calling setState within the dialog to update its UI
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(isEditing ? 'Chỉnh sửa danh mục' : 'Thêm danh mục mới'),
          // Use AbsorbPointer to disable dialog UI during internal processing (like image upload or saving)
          content: AbsorbPointer(
             // Absorb if a picked image is uploading OR the dialog is saving/updating
             absorbing: (_currentPickedImage != null && _currentPickedImage!.isUploading) || _isProcessingDialog,
             child: SingleChildScrollView( // Allows content to scroll if it overflows
                 child: Column(
                   mainAxisSize: MainAxisSize.min, // Makes column take minimum vertical space
                   crossAxisAlignment: CrossAxisAlignment.start, // Align content to the start
                   children: [
                     TextField(
                       controller: nameController,
                       decoration: const InputDecoration(
                         labelText: 'Tên danh mục',
                         border: OutlineInputBorder(),
                       ),
                       // Disable field if dialog is processing (uploading or saving)
                       enabled: !_isProcessingDialog,
                     ),
                     const SizedBox(height: 16),
                     ElevatedButton.icon(
                       // Disable button if a picked image is uploading OR dialog is saving/updating
                       onPressed: (_currentPickedImage != null && _currentPickedImage!.isUploading) || _isProcessingDialog ? null : () {
                         // Call the image picking/upload logic, passing setStateDialog to update the dialog UI
                         _pickAndUploadImageForDialog(setStateDialog);
                       },
                       icon: const Icon(Icons.image),
                       // Show relevant text based on upload state
                       label: Text((_currentPickedImage != null && _currentPickedImage!.isUploading) ? 'Đang tải ảnh...' : 'Chọn ảnh'),
                     ),
                     const SizedBox(height: 16),

                     // Display image preview area (using the screen's helper)
                     // Prioritize the local PickedImage, then the final URL for submission
                     if (_currentPickedImage != null || (_dialogImageUrlForSubmission != null && _dialogImageUrlForSubmission!.isNotEmpty)) ...[
                       Container(
                         height: 100,
                         width: 100,
                         decoration: BoxDecoration(
                           border: Border.all(color: Colors.grey),
                           borderRadius: BorderRadius.circular(4),
                         ),
                         clipBehavior: Clip.antiAlias,
                          // Use the screen's _buildImageWidget helper for displaying the image source
                          // Pass _currentPickedImage (local data) or _dialogImageUrlForSubmission (server path)
                          child: _buildImageWidget(_currentPickedImage ?? _dialogImageUrlForSubmission, size: 100, iconSize: 40, fit: BoxFit.cover), // <-- Use the combined source here
                       ),
                        // Optional: Add a small remove image button if there's an image to remove
                       if ((_currentPickedImage != null || (_dialogImageUrlForSubmission != null && _dialogImageUrlForSubmission!.isNotEmpty)) && !(_currentPickedImage != null && _currentPickedImage!.isUploading) && !_isProcessingDialog)
                          Align(
                             alignment: Alignment.topRight, // Position the button
                             child: IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () {
                                   setStateDialog(() { // Update dialog state
                                       _currentPickedImage = null; // Clear local preview
                                       _dialogImageUrlForSubmission = null; // Clear the stored path
                                   });
                                },
                                tooltip: 'Xóa ảnh',
                             ),
                          ),
                     ],
                   ],
               ),
             ),
          ),
          actions: [
            TextButton(
              // Disable button if dialog is processing
              onPressed: _isProcessingDialog ? null : () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              // Disable button if dialog is processing OR image is currently uploading
              onPressed: (_isProcessingDialog || (_currentPickedImage != null && _currentPickedImage!.isUploading)) ? null : () async {
                // --- Validation ---
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tên danh mục')),
                  );
                  return; // Stop if validation fails
                }
                // Image is now mandatory for both add and edit (unless keeping old one)
                 if (_dialogImageUrlForSubmission == null || _dialogImageUrlForSubmission!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng chọn hình ảnh cho danh mục')),
                     );
                     return; // Stop if validation fails
                 }


                // --- Call API (Create or Update) ---
                 setStateDialog(() { _isProcessingDialog = true; }); // Show dialog processing state (e.g., CircularProgressIndicator in actions area)
                 // Optionally, you could show a separate loading dialog over the whole screen here instead.

                 try {
                    CategoryDTO resultCategory; // DTO to hold the result from the API call

                    if (isEditing) {
                       // *** UPDATE CATEGORY ***
                       // categoryToEdit!.id is guaranteed non-null because isEditing is true
                       if (categoryToEdit!.id == null) { // Extra safety check
                            throw Exception('Category ID is missing for update operation.');
                       }
                       final updateDTO = UpdateCategoryRequestDTO(
                          name: nameController.text.trim(), // Use trimmed text from controller
                          imageUrl: _dialogImageUrlForSubmission!, // Use the final stored RELATIVE path (guaranteed non-null by validation)
                       );
                       if (kDebugMode) print('Calling updateCategory for ID ${categoryToEdit.id} with data: ${updateDTO.toJson()}');
                       resultCategory = await _categoriesService.updateCategory(categoryToEdit.id!, updateDTO);
                       if (kDebugMode) print('Update successful. Received DTO: ${resultCategory.toJson()}');

                       // *** Update Singleton Data Source ***
                       // Pass the DTO received from the API (it might contain updated dates, etc.)
                       AppDataService().updateCategory(resultCategory);

                    } else {
                       // *** CREATE NEW CATEGORY ***
                       final createDTO = CreateCategoryRequestDTO(
                          name: nameController.text.trim(), // Use trimmed text from controller
                          imageUrl: _dialogImageUrlForSubmission!, // Use the final stored RELATIVE path (guaranteed non-null by validation)
                       );
                       if (kDebugMode) print('Calling createCategory with data: ${createDTO.toJson()}');
                       resultCategory = await _categoriesService.createCategory(createDTO);
                       if (kDebugMode) print('Create successful. Received DTO: ${resultCategory.toJson()}');

                       // *** Update Singleton Data Source ***
                       // Pass the DTO received from the API (it contains the new ID, dates, etc.)
                       AppDataService().addCategory(resultCategory);
                    }

                     // --- Handle Success ---
                     // Ensure the screen widget is still mounted before interacting with context
                     if(mounted) {
                         // Dismiss the dialog after successful save
                         Navigator.pop(context);
                         // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEditing ? 'Cập nhật danh mục thành công!' : 'Thêm danh mục thành công!'),
                              backgroundColor: Colors.green,
                            ),
                         );
                     }

                 } catch (e) {
                    // --- Handle API Error ---
                     if (kDebugMode) print('API Error during category save: $e');
                      // Ensure the screen widget is still mounted before interacting with context
                      if(mounted) {
                         // Show error message
                         ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(
                             content: Text('Lỗi lưu danh mục: ${e.toString()}'), // Show error message from exception
                             backgroundColor: Colors.red,
                           ),
                        );
                     }
                 } finally {
                     // Ensure dialog processing state is off regardless of success/failure
                     setStateDialog(() { _isProcessingDialog = false; });
                     // Also clear any lingering picked image state/flags just in case (defensive)
                     if (_currentPickedImage != null) _currentPickedImage!.isUploading = false;
                 }
              },
              // Show "Lưu" or "Đang lưu..." based on dialog processing state
              child: _isProcessingDialog ? const SizedBox(
                 width: 20, // Fixed size for indicator
                 height: 20,
                 child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                 ),
              ) : Text(isEditing ? 'Cập nhật' : 'Thêm'),
            ),
          ],
        ),
      ),
    );
     // Return null or a placeholder widget from showDialog builder if context is invalid,
     // though mounted check should handle this.
  }


  // --- Removed Delete Confirmation Dialog ---
  // void _showDeleteConfirmation(...) { ... }


  // --- DataTableSource for Large Screen ---
  // This is NOT needed anymore as we are using a single ListView layout
  // late CatalogProductDataSource _catalogProductDataSource;


  // --- Listener for AppDataService changes ---
  // This listener is crucial for updating the UI when singleton data changes
   void _onAppDataServiceChange() {
       // Check if the widget is still in the widget tree before calling setState
       if(mounted) {
           setState(() {
               // Calling setState here triggers a rebuild of the whole screen widget.
               // When the build method runs again, it will read the updated list
               // from AppDataService().categories via the getters (_allCategories, _paginatedCategories, _pageCount).
               // The UI (ListView.builder) will then render with the new data.

               // Adjust current page if needed after data changes (add/delete can affect total pages)
               final int totalPages = _pageCount;
               if (_currentPage >= totalPages) {
                   // If the current page index is now out of bounds, go to the last valid page
                   _currentPage = totalPages > 0 ? totalPages - 1 : 0; // Ensure page is >= 0
               }
               // If we reset the page, setState handles the rebuild.
               // If data changed but the current page index is still valid, setState will also rebuild.
           });
           if (kDebugMode) print('AppDataService changed. UI updated.');
       }
   }


  @override
  void initState() {
    super.initState();
    // Initialize DataTableSource - REMOVED as it's not used anymore

     // Start listening to AppDataService for changes
     // This ensures the UI updates when categories are added/updated in the singleton
    AppDataService().addListener(_onAppDataServiceChange);

    // If AppDataService is not already initialized and not currently loading, load the data
    // The listener will handle updating the UI once loadData completes (or fails)
    if (!AppDataService().isInitialized && !AppDataService().isLoading) {
       // Call loadData without awaiting, as it's async and the UI will react via the listener
       AppDataService().loadData().catchError((error) {
          // Handle potential error if loadData throws (e.g., network issues during initial fetch)
          // The build method's logic for checking AppDataService().isInitialized and .isLoading
          // should display a loading/error state even if there's an exception.
          // You could add specific error handling here if needed, e.g., show a Snackbar
          if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Lỗi tải dữ liệu ban đầu: ${error.toString()}')),
              );
          }
       });
    }
     // If data is loading or already initialized, the build method will handle the initial display,
     // and the listener will handle subsequent updates from other parts of the app or background loading.
  }

  @override
  void dispose() {
    // Remove the listener when the widget is disposed to prevent memory leaks
    AppDataService().removeListener(_onAppDataServiceChange);

    // Dispose the DataTableSource - REMOVED as it's not used anymore
    // _catalogProductDataSource.dispose();

    // Dispose the CategoriesService if you instantiated it directly here
    // If Services are singletons managed by AppDataService or another Provider,
    // dispose AppDataService or the Provider instead (usually done higher up in the app lifecycle)
    _categoriesService.dispose();

    super.dispose();
  }


  // --- Build Method (Single Layout) ---
  @override
  Widget build(BuildContext context) {
    // Determine screen size for responsive layout (optional, but good practice)
    // final double screenWidth = MediaQuery.of(context).size.width;
    // final double availableWidth = screenWidth - 2 * 16.0; // Subtract padding


     // *** CHECK APP DATA SERVICE STATE FIRST ***
     // Show a loading indicator if AppDataService is currently loading data for the first time
     if (AppDataService().isLoading && !AppDataService().isInitialized) {
         return Scaffold(
           appBar: AppBar(title: const Text('Đang tải dữ liệu...')),
           body: const Center(child: CircularProgressIndicator()),
         );
     }

     // Show an error message if AppDataService failed to initialize and is not currently loading
     // (This state would be reached if loadData threw an exception and finished loading=false, initialized=false)
      if (!AppDataService().isInitialized && !AppDataService().isLoading) {
         // You might want a more sophisticated error display and retry button here
         return Scaffold(
            appBar: AppBar(title: const Text('Lỗi tải dữ liệu')),
            body: Center(
               child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     mainAxisSize: MainAxisSize.min, // Use min size for column
                     children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 50),
                        const SizedBox(height: 16),
                        const Text(
                           'Không thể tải dữ liệu danh mục.\nVui lòng thử lại.',
                            textAlign: TextAlign.center,
                           style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                           onPressed: () {
                              // Attempt to reload data when retry button is pressed
                              AppDataService().loadData().catchError((error) {
                                  // Handle error from reload attempt if needed
                                   if (mounted) {
                                       ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Lỗi tải lại dữ liệu: ${error.toString()}')),
                                       );
                                   }
                              });
                           },
                           child: const Text('Tải lại'),
                        )
                     ],
                  ),
               ),
            ),
         );
      }


    // If AppDataService is initialized (and not loading), proceed to build the main UI
    return Scaffold(
       appBar: AppBar(
         title: const Text('Quản lý danh mục sản phẩm'),
       ),
      // AbsorbPointer can wrap the main content if you need to block interaction during *any* async operation (e.g., dialog API call)
      // For simplicity, we are managing dialog processing state (_isProcessingDialog) separately.
      // If you need a global processing overlay for the whole screen, add AbsorbPointer here.
      // body: AbsorbPointer( absorbing: _isProcessingGlobal, ... )
      body: SingleChildScrollView( // Use SingleChildScrollView for the whole body to handle overflow
          padding: const EdgeInsets.all(16.0), // Add padding around the content
          child: Column( // Use Column to arrange the "Add" button, title, list, and pagination
             crossAxisAlignment: CrossAxisAlignment.start, // Align items to the start horizontally
             children: [

               // "Thêm danh mục sản phẩm" Button
               Align( // Align button to the left
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    // Disable button if the dialog is currently processing (e.g., uploading or saving)
                    onPressed: _isProcessingDialog ? null : () {
                      _showCategoryDialog(); // Show add dialog
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                      textStyle: const TextStyle(fontSize: 14),
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text('Thêm danh mục sản phẩm'),
                  ),
               ),

               const SizedBox(height: 20), // Space below the button

               const Text(
                 'Danh sách danh mục sản phẩm',
                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
               ),
               const SizedBox(height: 10), // Space below the title

               // --- Category List (using ListView.builder with manual pagination) ---
                // Check if the list is empty after loading
                if (_allCategories.isEmpty)
                   const Center( // Show message if no categories found
                      child: Padding(
                         padding: EdgeInsets.all(20.0),
                         child: Text('Không tìm thấy danh mục nào.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ),
                   )
                else
                   ListView.builder(
                     shrinkWrap: true, // Make ListView take minimum space needed
                     physics: const NeverScrollableScrollPhysics(), // Disable ListView's own scrolling
                     itemCount: _paginatedCategories.length, // Number of items on the current page
                     itemBuilder: (context, index) {
                       final category = _paginatedCategories[index]; // Get CategoryDTO for this index

                       return Card( // Use Card for visual separation of each item
                         margin: const EdgeInsets.symmetric(vertical: 4), // Vertical space between cards
                         child: Padding(
                           padding: const EdgeInsets.all(12.0), // Padding inside the card
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start, // Align content to the start
                             children: [
                               // Category Name (Bold)
                               Text(
                                 category.name ?? 'Danh mục [Không tên]', // Use category.name, handle null
                                 style: const TextStyle(
                                     fontWeight: FontWeight.bold, fontSize: 16),
                                 maxLines: 2,
                                 overflow: TextOverflow.ellipsis, // Handle long names
                               ),
                               const SizedBox(height: 8), // Space below name

                               // Image and Actions Row
                               Row(
                                   crossAxisAlignment: CrossAxisAlignment.center, // Vertically center items in this row
                                   children: [
                                       // Image Display Area (Fixed size)
                                       Container( // <-- The image container
                                         width: 60, // Adjusted size for a smaller, compact image
                                         height: 60, // Adjusted size
                                         decoration: BoxDecoration(
                                           border: Border.all(color: Colors.grey.shade300),
                                           borderRadius: BorderRadius.circular(4),
                                         ),
                                         clipBehavior: Clip.antiAlias, // Clip image to border radius
                                         // Use the _buildImageWidget helper
                                         child: _buildImageWidget(category.imageUrl, size: 60, iconSize: 30, fit: BoxFit.cover), // Use category.imageUrl and size 60
                                       ),
                                       const SizedBox(width: 12), // Space between image and name/actions

                                       // Name and Actions Column (Takes remaining space)
                                       Expanded( // Let this column take the remaining horizontal space
                                         child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start
                                            mainAxisSize: MainAxisSize.min, // Take minimum vertical space
                                            children: [
                                                // You could optionally repeat the name here if you prefer it next to the image
                                                // Text(category.name ?? '...', style: ...),
                                                // const SizedBox(height: 4),

                                                // Actions (Edit button)
                                                Row(
                                                    mainAxisAlignment: MainAxisAlignment.end, // Align actions to the end of the Expanded space
                                                    children: [
                                                       IconButton(
                                                         onPressed: _isProcessingDialog ? null : () { // Disable button if dialog is processing
                                                           _showCategoryDialog(category); // Show edit dialog with CategoryDTO
                                                         },
                                                         icon: const Icon(Icons.edit, size: 18),
                                                         tooltip: 'Chỉnh sửa',
                                                         padding: EdgeInsets.zero,
                                                         constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                                       ),
                                                    ],
                                                ),
                                            ],
                                         ),
                                       ),
                                   ],
                               ),
                               // You could add other properties here if needed, each in a new Row or Text widget
                               // Example: Text('ID: ${category.id ?? 'N/A'}'),
                               // const SizedBox(height: 4),
                               // Text('Ngày tạo: ${category.createdDate?.toLocal().toString().split(' ')[0] ?? 'N/A'}'),
                             ],
                           ),
                         ),
                       );
                     },
                   ),


               const SizedBox(height: 20), // Space below the list

               // --- Pagination Controls ---
                if (_allCategories.isNotEmpty) // Only show pagination if there is data
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          // Display current range and total count
                          'Hiển thị ${_paginatedCategories.isEmpty ? 0 : (_currentPage * _rowsPerPage) + 1} - ${(_currentPage * _rowsPerPage) + _paginatedCategories.length} trên ${_allCategories.length}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Previous Page Button
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_left),
                              onPressed: _currentPage > 0 && !_isProcessingDialog // Disable if dialog is processing
                                  ? () {
                                      setState(() {
                                        _currentPage--; // Decrease page index
                                      });
                                    }
                                  : null, // Disable button if on first page or dialog is processing
                              tooltip: 'Trang trước',
                            ),
                            // Page Number Display
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                // Display current page (1-indexed) / total pages
                                '${_currentPage + 1} / $_pageCount', // Use _pageCount based on total items
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            // Next Page Button
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_right),
                              onPressed: _currentPage < _pageCount - 1 && !_isProcessingDialog // Disable if dialog is processing
                                  ? () {
                                      setState(() {
                                        _currentPage++; // Increase page index
                                      });
                                    }
                                  : null, // Disable button if on last page or dialog is processing
                              tooltip: 'Trang tiếp',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16), // Add space at bottom
             ],
          ),
      ),
    );
  }
}


// --- DataTableSource for PaginatedDataTable ---
// This is NOT needed anymore as we are using a single ListView layout
// class CatalogProductDataSource extends DataTableSource { ... }
