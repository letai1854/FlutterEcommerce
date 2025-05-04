import 'package:flutter/material.dart';

class ProductItem extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String describe;
  final double price;
  final int? discount;
  final double rating;

  const ProductItem({
    required this.imageUrl,
    required this.title,
    required this.describe,
    required this.price,
    this.discount,
    required this.rating,
    Key? key,
  }) : super(key: key);

  @override
  State<ProductItem> createState() => _ProductItemState();
}

class _ProductItemState extends State<ProductItem> {
  @override
  Widget build(BuildContext context) {
    double discountedPrice = widget.discount != null
        ? widget.price * (1 - widget.discount! / 100)
        : widget.price;

    // Format description to show only 5 words with ellipsis
    String formattedDescription = _formatDescription(widget.describe);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/product_detail');
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(),
                    child: Image.asset(
                      widget.imageUrl,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (widget.discount != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 255, 85, 0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${widget.discount}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDescription,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${discountedPrice.toStringAsFixed(0)} đ',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.discount != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${widget.price.toStringAsFixed(0)} đ',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < widget.rating.floor()
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 14,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to format description to show only 5 words
  String _formatDescription(String description) {
    final words = description.split(' ');
    if (words.length <= 5) {
      return description;
    } else {
      return '${words.take(5).join(' ')}...';
    }
  }
}

class ProductList extends StatefulWidget {
  final List<Map<String, dynamic>> productData;
  final int itemsPerPage;
  final double gridHeight;
  final double gridWidth;
  final double childAspectRatio;
  final int crossAxisCount;
  final double mainSpace;
  final double crossSpace;
  final Axis scroll;
  final Key? productListKey;

  const ProductList({
    Key? key,
    required this.scroll,
    required this.productData,
    required this.itemsPerPage,
    required this.gridHeight,
    required this.gridWidth,
    required this.childAspectRatio,
    required this.crossAxisCount,
    required this.mainSpace,
    required this.crossSpace,
    this.productListKey,
  }) : super(key: key ?? productListKey);

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList>
    with AutomaticKeepAliveClientMixin {
  int currentIndex = 0;
  List<ProductItem> products = [];
  ScrollController _scrollController = ScrollController();
  bool isLoading = false;
  bool initialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMoreData();
  }

  @override
  void didUpdateWidget(ProductList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productData != widget.productData) {
      _reloadData();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.maxScrollExtent -
                _scrollController.position.pixels <=
            300 &&
        !isLoading) {
      _loadMoreData();
    }
  }

  void _reloadData() {
    setState(() {
      products = [];
      currentIndex = 0;
    });
    _loadMoreData();
  }

  void _scrollLeft() {
    final double scrollAmount = widget.gridWidth * 0.8;
    _scrollController.animateTo(
      (_scrollController.offset - scrollAmount)
          .clamp(0, _scrollController.position.maxScrollExtent),
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    final double scrollAmount = widget.gridWidth * 0.8;
    _scrollController.animateTo(
      (_scrollController.offset + scrollAmount)
          .clamp(0, _scrollController.position.maxScrollExtent),
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadMoreData() async {
    if (currentIndex >= widget.productData.length || isLoading) return;

    setState(() => isLoading = true);

    await Future.delayed(const Duration(milliseconds: 500));

    int nextIndex = currentIndex + widget.itemsPerPage;
    List<ProductItem> newProducts = widget.productData
        .sublist(
            currentIndex,
            nextIndex > widget.productData.length
                ? widget.productData.length
                : nextIndex)
        .map((data) => ProductItem(
              imageUrl: data['image'],
              title: data['title'],
              describe: data['describe'],
              price: data['price'],
              discount: data['discount'],
              rating: data['rating'],
            ))
        .toList();

    setState(() {
      products.addAll(newProducts);
      currentIndex = nextIndex;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SizedBox(
      height: widget.gridHeight,
      width: widget.gridWidth,
      child: Stack(
        children: [
          // Main content container
          Container(
            color: Colors.white,
            child: GridView.builder(
              controller: _scrollController,
              scrollDirection: widget.scroll,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.crossAxisCount,
                childAspectRatio: widget.childAspectRatio,
                mainAxisSpacing: widget.mainSpace,
                crossAxisSpacing: widget.crossSpace,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return products[index];
              },
            ),
          ),

          // Left arrow button - always visible
          Positioned(
            left: 5,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.blue),
                  onPressed: _scrollLeft,
                  iconSize: 20,
                  padding: EdgeInsets.only(left: 8, right: 0),
                ),
              ),
            ),
          ),

          // Right arrow button - always visible
          Positioned(
            right: 5,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: IconButton(
                  icon:
                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.blue),
                  onPressed: _scrollRight,
                  iconSize: 20,
                  padding: EdgeInsets.only(left: 0, right: 0),
                ),
              ),
            ),
          ),

          // Center loading indicator with overlay
          if (isLoading)
            Positioned.fill(
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Đang tải dữ liệu...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
