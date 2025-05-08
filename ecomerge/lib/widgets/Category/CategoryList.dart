// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:e_commerce_app/database/services/product_service.dart';
// / Assuming PageResponse is here or adjust path

// class CategoryList extends StatefulWidget {
//   final Key?
//       productListKey; // Renamed from categoryListKey for consistency if copied
//   final int itemsPerPage;
//   final double itemHeight; // Changed from gridHeight
//   final double itemWidth; // Added for clarity
//   final double mainSpace;
//   final double
//       crossSpace; // Though less relevant for horizontal list, kept for consistency

//   const CategoryList({
//     this.productListKey, // Renamed
//     required this.itemsPerPage,
//     required this.itemHeight,
//     this.itemWidth = 150.0, // Default item width
//     this.mainSpace = 10.0,
//     this.crossSpace = 10.0,
//   }) : super(key: productListKey);

//   @override
//   State<CategoryList> createState() => _CategoryListState();
// }

// class _CategoryListState extends State<CategoryList> {
//   final ProductService _productService = ProductService();
//   List<CategoryDTO> _categories = [];
//   bool _isLoading = true;
//   bool _isFetchingMore = false;
//   bool _canLoadMore = true;
//   int _currentPage = 0;
//   String? _errorMessage;

//   final ScrollController _scrollController = ScrollController();
//   Timer? _scrollEndTimer;
//   bool _isScrollingToEnd = false;

//   // Scroll button states
//   bool _showScrollButtons = false;
//   bool _isAtStart = true;
//   bool _isAtEnd = false;

//   @override
//   void initState() {
//     super.initState();
//     _fetchCategories(isInitialLoad: true);
//     _scrollController.addListener(_scrollListener);

//     // Check initial scroll position for buttons
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) {
//         _updateScrollButtonVisibility();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _scrollController.removeListener(_scrollListener);
//     _scrollController.dispose();
//     _scrollEndTimer?.cancel();
//     super.dispose();
//   }

//   void _scrollListener() {
//     if (!mounted) return;

//     _updateScrollButtonVisibility();

//     // Load more logic
//     if (_scrollController.position.pixels >=
//             _scrollController.position.maxScrollExtent - 200 && // Threshold
//         !_isFetchingMore &&
//         _canLoadMore) {
//       _fetchCategories();
//     }

//     // "Can load more" hint logic
//     if (_scrollController.position.pixels >
//             _scrollController.position.maxScrollExtent *
//                 0.8 && // Start showing hint early
//         _scrollController.position.maxScrollExtent > 0 &&
//         _canLoadMore &&
//         !_isFetchingMore) {
//       if (!_isScrollingToEnd) {
//         setState(() {
//           _isScrollingToEnd = true;
//         });
//       }
//       _scrollEndTimer?.cancel();
//       _scrollEndTimer = Timer(const Duration(milliseconds: 300), () {
//         if (mounted) {
//           setState(() {
//             _isScrollingToEnd = false;
//           });
//         }
//       });
//     } else {
//       if (_isScrollingToEnd) {
//         setState(() {
//           _isScrollingToEnd = false;
//         });
//       }
//     }
//   }

//   void _updateScrollButtonVisibility() {
//     if (!_scrollController.hasClients || !mounted) return;
//     final maxScroll = _scrollController.position.maxScrollExtent;
//     final currentScroll = _scrollController.position.pixels;

//     bool show = maxScroll > 0;
//     bool atStart = currentScroll <= 0;
//     bool atEnd = currentScroll >= maxScroll;

//     if (_showScrollButtons != show ||
//         _isAtStart != atStart ||
//         _isAtEnd != atEnd) {
//       setState(() {
//         _showScrollButtons = show;
//         _isAtStart = atStart;
//         _isAtEnd = atEnd;
//       });
//     }
//   }

//   Future<void> _fetchCategories({bool isInitialLoad = false}) async {
//     if (_isFetchingMore && !isInitialLoad) return;

//     setState(() {
//       if (isInitialLoad) {
//         _isLoading = true;
//         _errorMessage = null;
//       } else {
//         _isFetchingMore = true;
//       }
//     });

//     try {
//       final PageResponse<CategoryDTO> pageResponse =
//           await _productService.fetchCategoriesPaginated(
//         page: _currentPage,
//         size: widget.itemsPerPage,
//         sortBy: 'createdDate',
//         sortDir: 'desc',
//       );

//       if (!mounted) return;

//       setState(() {
//         if (isInitialLoad) {
//           _categories = pageResponse.content;
//         } else {
//           _categories.addAll(pageResponse.content);
//         }
//         _currentPage++;
//         _canLoadMore = !pageResponse.last;
//         _isLoading = false;
//         _isFetchingMore = false;
//         _errorMessage = null;
//       });
//       WidgetsBinding.instance
//           .addPostFrameCallback((_) => _updateScrollButtonVisibility());
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _isLoading = false;
//         _isFetchingMore = false;
//         _errorMessage = "Failed to load categories: ${e.toString()}";
//       });
//     }
//   }

//   void _scrollToLeft() {
//     if (!_scrollController.hasClients) return;
//     _scrollController.animateTo(
//       _scrollController.offset - (widget.itemWidth * 2), // Scroll by two items
//       duration: const Duration(milliseconds: 300),
//       curve: Curves.easeInOut,
//     );
//   }

//   void _scrollToRight() {
//     if (!_scrollController.hasClients) return;
//     _scrollController.animateTo(
//       _scrollController.offset + (widget.itemWidth * 2), // Scroll by two items
//       duration: const Duration(milliseconds: 300),
//       curve: Curves.easeInOut,
//     );
//   }

//   Widget _buildCategoryItem(CategoryDTO category) {
//     return Container(
//       width: widget.itemWidth,
//       height: widget.itemHeight,
//       margin: EdgeInsets.symmetric(horizontal: widget.mainSpace / 2),
//       child: Card(
//         elevation: 2.0,
//         clipBehavior: Clip.antiAlias,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8.0),
//         ),
//         child: InkWell(
//           onTap: () {
//             // TODO: Handle category tap, e.g., navigate to category products page
//             print('Tapped on category: ${category.name}');
//           },
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 // Icon(Icons.category, size: widget.itemHeight * 0.3, color: Theme.of(context).primaryColor),
//                 // const SizedBox(height: 8),
//                 Text(
//                   category.name,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                   ),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 if (category.description != null &&
//                     category.description!.isNotEmpty)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 4.0),
//                     child: Text(
//                       category.description!,
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey[600],
//                       ),
//                       maxLines: 3,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading && _categories.isEmpty) {
//       return SizedBox(
//         height: widget.itemHeight + (widget.crossSpace * 2),
//         child: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     if (_errorMessage != null && _categories.isEmpty) {
//       return SizedBox(
//         height: widget.itemHeight + (widget.crossSpace * 2),
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child:
//                 Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
//           ),
//         ),
//       );
//     }

//     if (_categories.isEmpty) {
//       return SizedBox(
//         height: widget.itemHeight + (widget.crossSpace * 2),
//         child: const Center(child: Text('No categories found.')),
//       );
//     }

//     return SizedBox(
//       height: widget.itemHeight +
//           (widget.crossSpace * 2), // Overall height of the horizontal list
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           Padding(
//             padding: EdgeInsets.symmetric(vertical: widget.crossSpace),
//             child: ListView.builder(
//               key: widget.productListKey, // Use the passed key
//               controller: _scrollController,
//               scrollDirection: Axis.horizontal,
//               padding: EdgeInsets.symmetric(horizontal: widget.mainSpace / 2),
//               itemCount: _categories.length + (_isFetchingMore ? 1 : 0),
//               itemBuilder: (context, index) {
//                 if (index == _categories.length) {
//                   return _isFetchingMore
//                       ? Container(
//                           width: 50,
//                           height: widget.itemHeight,
//                           alignment: Alignment.center,
//                           child: const SizedBox(
//                             width: 24,
//                             height: 24,
//                             child: CircularProgressIndicator(strokeWidth: 2.0),
//                           ),
//                         )
//                       : const SizedBox.shrink();
//                 }
//                 return _buildCategoryItem(_categories[index]);
//               },
//             ),
//           ),
//           if (_isScrollingToEnd && !_isFetchingMore && _canLoadMore)
//             Positioned.fill(
//               child: Container(
//                 alignment: Alignment.center,
//                 child: Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.75),
//                     borderRadius: BorderRadius.circular(12),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.2),
//                         blurRadius: 8,
//                         offset: const Offset(0, 2),
//                       )
//                     ],
//                   ),
//                   child: const Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       SizedBox(
//                         width: 35,
//                         height: 35,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2.5,
//                           valueColor:
//                               AlwaysStoppedAnimation<Color>(Colors.white),
//                         ),
//                       ),
//                       SizedBox(height: 12),
//                       Text(
//                         'Đang tải thêm...',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           if (_showScrollButtons && !_isAtStart)
//             Positioned(
//               left: 0,
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.3),
//                   shape: BoxShape.circle,
//                 ),
//                 child: IconButton(
//                   icon: const Icon(Icons.arrow_back_ios_new,
//                       color: Colors.white, size: 20),
//                   onPressed: _scrollToLeft,
//                   tooltip: 'Scroll Left',
//                 ),
//               ),
//             ),
//           if (_showScrollButtons && !_isAtEnd)
//             Positioned(
//               right: 0,
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.3),
//                   shape: BoxShape.circle,
//                 ),
//                 child: IconButton(
//                   icon: const Icon(Icons.arrow_forward_ios,
//                       color: Colors.white, size: 20),
//                   onPressed: _scrollToRight,
//                   tooltip: 'Scroll Right',
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
