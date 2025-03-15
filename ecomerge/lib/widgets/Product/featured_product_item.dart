import 'package:e_commerce_app/widgets/Product/ProductItem.dart';
import 'package:flutter/material.dart';

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
  }) : super(key: key);

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  int currentIndex = 0;
  List<ProductItem> products = [];
  ScrollController _scrollController = ScrollController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMoreData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !isLoading) {
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    if (currentIndex >= widget.productData.length) return;

    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

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
    return SizedBox(
      height: widget.gridHeight,
      width: widget.gridWidth,
      child: Container(
        color: Colors.white, // Thêm màu nền trắng
        child: GridView.builder(
          controller: _scrollController,
          scrollDirection: widget.scroll,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.crossAxisCount,
            childAspectRatio: widget.childAspectRatio,
            mainAxisSpacing: widget.mainSpace,
            crossAxisSpacing: widget.crossSpace,
          ),
          itemCount: products.length + (isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == products.length) {
              return const Center(child: CircularProgressIndicator());
            }
            return products[index];
          },
        ),
      ),
    );
  }
}
