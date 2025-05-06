import 'package:e_commerce_app/Constants/productTest.dart';
import 'package:e_commerce_app/database/models/product_dto.dart'; // Import ProductDTO
import 'package:e_commerce_app/widgets/Product/PaginatedProductGrid.dart';
import 'package:e_commerce_app/widgets/SortingBar.dart';
import 'package:e_commerce_app/widgets/footer.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/material.dart';
import 'dart:math';

// Import necessary DTOs and Services
import 'package:e_commerce_app/database/models/categories.dart'; // Import CategoryDTO
import 'package:e_commerce_app/database/services/categories_service.dart'; // Import CategoriesService (for getImageUrl)


class CatalogProduct extends StatefulWidget {
  // Change filteredProducts to accept List<ProductDTO>
  final List<ProductDTO> filteredProducts;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final ScrollController scrollController;
  final String currentSortMethod;
  final int selectedCategoryId;

  // *** THAY ĐỔI: Nhận List<CategoryDTO> thay vì List<Map<String, dynamic>> ***
  final List<CategoryDTO> categories; // <--- NHẬN DANH SÁCH CATEGORIES ĐÚNG KIỂU DỮ LIỆU

  final Function(int) updateSelectedCategory;
  final Function(String) updateSortMethod;

  // *** THÊM: Nhận trạng thái loading/initialized từ PageListProduct ***
  final bool isAppDataLoading;
  final bool isAppDataInitialized;
  // *** THÊM: Nhận trạng thái loading sản phẩm và khả năng load thêm từ PageListProduct ***
  final bool isProductsLoading;
  final bool canLoadMoreProducts;


  const CatalogProduct({
    super.key,
    required this.filteredProducts,
    required this.scaffoldKey,
    required this.scrollController,
    required this.currentSortMethod,
    required this.selectedCategoryId,
    required this.categories, // <-------------------------- NHẬN List<CategoryDTO>
    required this.updateSelectedCategory,
    required this.updateSortMethod,
     required this.isAppDataLoading, // <-- Thêm vào constructor
     required this.isAppDataInitialized, // <-- Thêm vào constructor
     required this.isProductsLoading, // <-- Thêm vào constructor
     required this.canLoadMoreProducts, // <-- Thêm vào constructor
  });

  @override
  State<CatalogProduct> createState() => _CatalogProductState();
}

class _CatalogProductState extends State<CatalogProduct> {

   // --- Service Instance (for getImageUrl) ---
   // Khởi tạo CategoriesService để sử dụng hàm getImageUrl
   final CategoriesService _categoriesService = CategoriesService();


   @override
  void initState() {
    super.initState();
     // Không cần lắng nghe AppDataService ở đây nữa vì PageListProduct đã lắng nghe và truyền data mới
  }

  @override
  void dispose() {
     // Dispose CategoriesService khi widget bị dispose
     _categoriesService.dispose();
    super.dispose();
  }


  // Helper function để hiển thị ảnh danh mục
  // Sử dụng _categoriesService.getImageUrl để lấy URL đầy đủ
  Widget _buildImageWidget(String? imageSource, {double size = 40, BoxFit fit = BoxFit.cover}) {
     // Hiển thị icon placeholder nếu không có đường dẫn ảnh hoặc service bị null (khả năng thấp)
    if (imageSource == null || imageSource.isEmpty) {
      return Icon(Icons.image, size: size * 0.7, color: Colors.grey); // Placeholder icon
    }

    // Sử dụng helper từ CategoriesService để lấy URL đầy đủ cho NetworkImage
    String fullImageUrl = _categoriesService.getImageUrl(imageSource);

     if (kDebugMode) {
         // print('[_buildImageWidget] Using FULL URL for Image.network: $fullImageUrl (Original source: $imageSource)');
     }

    // Hiển thị ảnh từ Network
    return Image.network(
      fullImageUrl,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            width: size * 0.5,
            height: size * 0.5,
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
        if (kDebugMode) print('[_buildImageWidget] Image.network failed for $fullImageUrl (Original: $imageSource): $error');
        return Icon(Icons.broken_image, size: size * 0.7, color: Colors.red); // Error icon
      },
    );
  }


  // --- Build Category Panel (using data from widget.categories) ---
  Widget _buildCategoryPanel(double width, bool isMobile) {
     // Lấy danh sách danh mục từ widget
     final List<CategoryDTO> categories = widget.categories;

    // Hiển thị trạng thái loading hoặc không có dữ liệu dựa trên cờ từ PageListProduct
    if (widget.isAppDataLoading && !widget.isAppDataInitialized) {
        // Hiển thị loading indicator nếu đang tải và chưa khởi tạo lần đầu
        return Container(
            width: width,
            color: Colors.white,
            child: const Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang tải danh mục...', style: TextStyle(color: Colors.grey)),
                 ],
               ),
            ),
        );
    }

    // Kiểm tra nếu danh sách category rỗng sau khi đã load (hoặc thất bại)
     if (categories.isEmpty && widget.isAppDataInitialized && !widget.isAppDataLoading) {
         return Container(
            width: width,
            color: Colors.white,
            child: const Center(
               child: Text('Không có danh mục nào.', style: TextStyle(color: Colors.grey)),
            ),
         );
     }

     // Nếu danh sách category có dữ liệu (categories.isNotEmpty) hoặc đang tải nhưng đã có dữ liệu cũ (_isAppDataInitialized && _isAppDataLoading)
     // Hiển thị danh sách
    return Container(
      width: width,
      color: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        // *** Sử dụng danh sách được truyền qua widget ***
        itemCount: categories.length,
        itemBuilder: (context, index) {
          // *** Lấy CategoryDTO object ***
          final CategoryDTO category = categories[index];
          // *** So sánh ID, xử lý trường hợp category.id là null ***
          final bool isSelected = category.id != null && widget.selectedCategoryId == category.id!;

          return Material(
            color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
            child: InkWell(
              // Vô hiệu hóa chạm nếu ID danh mục là null
              onTap: category.id == null ? null : () => widget.updateSelectedCategory(category.id!), // Truyền category ID, xử lý null
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Image Container
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                       clipBehavior: Clip.antiAlias, // Cắt ảnh theo bo góc
                       // *** Sử dụng helper để hiển thị ảnh từ category.imageUrl ***
                       child: _buildImageWidget(category.imageUrl, size: 40, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    // Category Name
                    Expanded(
                      child: Text(
                        // *** Sử dụng category.name, xử lý null ***
                        category.name ?? 'Danh mục [Không tên]',
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? Colors.blue : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    print('Building CatalogProduct...');
    print('Categories count received: ${widget.categories.length}');
    print('Loading state received: isAppDataLoading=${widget.isAppDataLoading}, isAppDataInitialized=${widget.isAppDataInitialized}');
    print('Product Loading State: isProductsLoading=${widget.isProductsLoading}, canLoadMoreProducts=${widget.canLoadMoreProducts}');


    final Size size = MediaQuery.of(context).size;
    final bool isWideScreen = size.width >= 1100;
    final bool isMobile = size.width < 600;

    final double minSpacing = 16.0;
    final double maxSpacing = 24.0;
    final double spacing = (size.width * 0.02).clamp(minSpacing, maxSpacing);

    final double categoryWidth = isWideScreen
        ? min(size.width * 0.2, 280.0)
        : min(size.width * 0.25, 220.0);

    // mainContentWidth is actually controlled by Expanded
    // final double mainContentWidth = isWideScreen
    //     ? size.width - categoryWidth - (spacing * 3)
    //     : size.width - categoryWidth - (spacing * 2);

    return Scaffold(
      key: widget.scaffoldKey,
      backgroundColor: Colors.grey[100],
      // Drawer for mobile view
      drawer: isMobile ? Drawer(
        child: _buildCategoryPanel(min(size.width * 0.6, 280.0), isMobile), // Truyền chiều rộng cho panel trong drawer
      ) : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Panel - hiển thị trên tablet và desktop
          if (!isMobile)
            // Panel danh mục được đặt trực tiếp trong Row với chiều rộng cố định
            _buildCategoryPanel(categoryWidth, isMobile),

          // Khu vực Nội dung chính (Lưới sản phẩm + Thanh sắp xếp)
          Expanded( // Cho phép khu vực nội dung chính chiếm hết không gian còn lại
            child: Padding(
              padding: EdgeInsets.all(spacing),
              child: SingleChildScrollView(
                controller: widget.scrollController,
                child: Column(
                  children: [
                    // Thanh sắp xếp với nút menu trên mobile
                    Container(
                       // Sử dụng double.infinity để nó lấp đầy chiều rộng của Expanded
                      width: double.infinity,
                      padding: EdgeInsets.all(spacing/2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          if (isMobile)
                            IconButton(
                              icon: const Icon(Icons.menu),
                              onPressed: () => widget.scaffoldKey.currentState?.openDrawer(), // Mở drawer trên mobile
                            ),
                          Expanded( // Cho phép SortingBar chiếm không gian còn lại
                            child: SortingBar(
                              width: double.infinity, // Sử dụng double.infinity bên trong Expanded
                              onSortChanged: widget.updateSortMethod,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: spacing),

                    // Khu vực lưới sản phẩm
                     // Sử dụng SizedBox với double.infinity bên trong SingleChildScrollView
                    SizedBox(
                      width: double.infinity,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double minItemWidth = isMobile ? 160.0 : 200.0;
                          final int maxColumns = (constraints.maxWidth / minItemWidth).floor();
                          final int columns = max(2, min(maxColumns, isMobile ? 2 : 4));

                          // Thêm Key cho PaginatedProductGrid để giải quyết lỗi rebuild không mong muốn
                           final gridKey = ValueKey('${widget.selectedCategoryId}_${widget.currentSortMethod}_${widget.filteredProducts.length}_${widget.categories.length}');


                          return PaginatedProductGrid(
                            key: gridKey, // <--- THÊM KEY VÀO ĐÂY
                            productData: widget.filteredProducts, // Pass the ProductDTO list directly
                            itemsPerPage: columns * 2, // Ví dụ phân trang: 2 hàng mỗi trang
                            gridWidth: constraints.maxWidth, // Truyền chiều rộng có sẵn
                            childAspectRatio: 0.6, // Điều chỉnh tỷ lệ khung hình nếu cần
                            crossAxisCount: columns, // Số cột đã tính
                            mainSpace: spacing, // Sử dụng khoảng cách đã tính
                            crossSpace: spacing, // Sử dụng khoảng cách đã tính
                             // Pass product loading state and can load more state
                            isProductsLoading: widget.isProductsLoading,
                            canLoadMoreProducts: widget.canLoadMoreProducts,
                          );
                        },
                      ),
                    ),

                    // Loading indicator at the bottom of the product list
                    if (widget.isProductsLoading && widget.filteredProducts.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),

                    // Footer (tùy chọn, thường hiển thị trên web)
                    if (kIsWeb) ...[
                      SizedBox(height: spacing),
                      const Footer(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
