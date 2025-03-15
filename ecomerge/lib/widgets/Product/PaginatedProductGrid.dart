import 'package:e_commerce_app/widgets/Product/ProductItem.dart';
import 'package:flutter/material.dart';

class PaginatedProductGrid extends StatefulWidget {
  final List<Map<String, dynamic>> productData;
  final int itemsPerPage;
  final double gridWidth;
  final double childAspectRatio;
  final int crossAxisCount;
  final double mainSpace;
  final double crossSpace;

  const PaginatedProductGrid({
    Key? key,
    required this.productData,
    required this.itemsPerPage,
    required this.gridWidth,
    required this.childAspectRatio,
    required this.crossAxisCount,
    required this.mainSpace,
    required this.crossSpace,
  }) : super(key: key);

  @override
  _PaginatedProductGridState createState() => _PaginatedProductGridState();
}

class _PaginatedProductGridState extends State<PaginatedProductGrid> {
  List<Widget> _displayedProducts = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  bool _isNearBottom = false;

  @override
  void initState() {
    super.initState();
    _loadMoreItems(); // Tải dữ liệu ban đầu

    // Attach scroll listener to parent SingleChildScrollView
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupScrollListener();
    });
  }

  void _setupScrollListener() {
    // Find the ancestor ScrollController
    ScrollPosition? scrollPosition = Scrollable.of(context)?.position;
    if (scrollPosition != null) {
      scrollPosition.addListener(() {
        // If we're near the bottom of the scroll view, load more items
        final maxScroll = scrollPosition.maxScrollExtent;
        final currentScroll = scrollPosition.pixels;
        if (currentScroll > maxScroll - 800 && !_isLoading && !_isNearBottom) {
          setState(() {
            _isNearBottom = true;
          });
          _loadMoreItems().then((_) {
            setState(() {
              _isNearBottom = false;
            });
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMoreItems() async {
    if (_isLoading || _displayedProducts.length >= widget.productData.length) {
      return; // Không tải thêm nếu đang tải hoặc hết dữ liệu
    }

    setState(() {
      _isLoading = true;
    });

    // Giả lập độ trễ mạng
    await Future.delayed(Duration(seconds: 2));

    final int startIndex = _displayedProducts.length;
    final int endIndex =
        (startIndex + widget.itemsPerPage) > widget.productData.length
            ? widget.productData.length
            : startIndex + widget.itemsPerPage;

    List<Widget> newProducts = widget.productData
        .sublist(startIndex, endIndex)
        .map((data) => ProductItem(
              imageUrl: data['image'],
              title: data['title'],
              describe: data['describe'],
              price: data['price'],
              discount: data['discount'],
              rating: data['rating'],
            ))
        .toList();

    if (mounted) {
      setState(() {
        _displayedProducts.addAll(newProducts);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate how many rows we need based on items and column count
    int totalRows = (_displayedProducts.length / widget.crossAxisCount).ceil();
    // Estimate height of grid based on item aspect ratio and spacing
    // This allows for dynamic height calculation
    double estimatedItemHeight = 180; // Base height estimate for a product item
    double estimatedGridHeight =
        totalRows * (estimatedItemHeight + widget.mainSpace);

    return Container(
      width: widget.gridWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min, // Use minimum space needed
        children: [
          GridView.builder(
            physics:
                NeverScrollableScrollPhysics(), // Disable GridView scrolling
            shrinkWrap: true, // Make grid only as tall as its content
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.crossAxisCount,
              childAspectRatio: widget.childAspectRatio,
              mainAxisSpacing: widget.mainSpace,
              crossAxisSpacing: widget.crossSpace,
            ),
            itemCount: _displayedProducts.length,
            itemBuilder: (context, index) {
              return _displayedProducts[index];
            },
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Đang tải thêm sản phẩm...'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
