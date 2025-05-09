import 'package:e_commerce_app/database/Storage/BrandCategoryService.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/database/models/categories.dart'; // Import CategoryDTO
import 'package:e_commerce_app/database/services/categories_service.dart'; // Import CategoriesService
import 'package:flutter/foundation.dart'; // For kDebugMode

class CategoriesSection extends StatefulWidget {
  final int? selectedIndex;
  final Function(int)? onCategorySelected;
  final List<CategoryDTO> categories; // Add this parameter

  const CategoriesSection({
    Key? key,
    this.selectedIndex,
    this.onCategorySelected,
    required this.categories, // Make it required
  }) : super(key: key);

  @override
  _CategoriesSectionState createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<CategoriesSection> {
  final CategoriesService _categoriesService =
      CategoriesService(); // Instance of CategoriesService

  Widget _buildCategoryItem(CategoryDTO category, int index) {
    bool isSelected = widget.selectedIndex == index;
    String fullImageUrl = _categoriesService.getImageUrl(category.imageUrl);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (widget.onCategorySelected != null) {
            widget.onCategorySelected!(index);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blue.withOpacity(0.1)
                : Colors.transparent, // Use transparent for non-selected
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    top: 10.0, bottom: 5.0), // Adjusted padding
                child: Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, // Make it circular for consistency
                  ),
                  child: ClipOval(
                    child: fullImageUrl.isNotEmpty
                        ? Image.network(
                            fullImageUrl,
                            fit: BoxFit.cover,
                            height: 60,
                            width: 60,
                            errorBuilder: (context, error, stackTrace) {
                              if (kDebugMode)
                                print(
                                    'Error loading category image: $fullImageUrl, $error');
                              return Icon(Icons.category,
                                  size: 30, color: Colors.grey[400]);
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                          )
                        : Icon(Icons.category,
                            size: 30, color: Colors.grey[400]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 4.0, vertical: 4.0), // Adjusted padding
                child: Text(
                  category.name ?? 'N/A',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12, // Adjusted font size for better fit
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
  }

  @override
  Widget build(BuildContext context) {
    // Take the first 5 categories, or fewer if the list is shorter.
    final List<CategoryDTO> categoriesToDisplay =
        widget.categories.take(5).toList();

    return Container(
      color: Colors.white,
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 28.0),
            child: Row(children: [
              Icon(
                Icons.list,
                size: 35.0,
              ),
              SizedBox(
                  width:
                      1), // Corrected from width: 1 to SizedBox(width: 8) or similar
              Text(
                'Danh mục',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ]),
          ),
          if (categoriesToDisplay.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  AppDataService().isLoading
                      ? 'Đang tải danh mục...'
                      : 'Không có danh mục nào.',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment
                  .start, // Align items to the start vertically
              children: categoriesToDisplay.asMap().entries.map((entry) {
                int idx = entry.key;
                CategoryDTO category = entry.value;
                return _buildCategoryItem(category, idx);
              }).toList(),
            ),
        ],
      ),
    );
  }
}
