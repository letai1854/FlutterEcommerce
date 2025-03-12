import 'package:flutter/material.dart';

class ProductListView extends StatefulWidget {
  final double width;
  final ScrollController scrollController;

  const ProductListView({
    Key? key,
    required this.width,
    required this.scrollController,
  }) : super(key: key);

  @override
  State<ProductListView> createState() => _ProductListViewState();
}

class _ProductListViewState extends State<ProductListView> {
  final List<Map<String, dynamic>> allProducts = [
    {
      'id': 1,
      'name': 'Laptop Gaming Acer Nitro 5',
      'price': 22990000,
      'oldPrice': 25990000,
      'image': 'https://laptopdell.com.vn/wp-content/uploads/2022/07/laptop_lenovo_legion_s7_8.jpg',
      'description': 'AMD Ryzen 5 5600H, RAM 8GB, SSD 512GB, RTX 3050',
      'rating': 4.5,
      'discount': 15,
      'sold': 120,
    },
    {
      'id': 2,
      'name': 'Bàn phím cơ AKKO 3068B',
      'price': 1890000,
      'oldPrice': 2190000,
      'image': 'https://laptopdell.com.vn/wp-content/uploads/2022/07/laptop_lenovo_legion_s7_8.jpg',
      'description': 'Plus Black & Cyan, Akko CS Switch',
      'rating': 4.8,
      'discount': 10,
      'sold': 250,
    },
        {
      'id': 2,
      'name': 'Bàn phím cơ AKKO 3068B',
      'price': 1890000,
      'oldPrice': 2190000,
      'image': 'https://laptopdell.com.vn/wp-content/uploads/2022/07/laptop_lenovo_legion_s7_8.jpg',
      'description': 'Plus Black & Cyan, Akko CS Switch',
      'rating': 4.8,
      'discount': 10,
      'sold': 250,
    },
        {
      'id': 2,
      'name': 'Bàn phím cơ AKKO 3068B',
      'price': 1890000,
      'oldPrice': 2190000,
      'image': 'https://laptopdell.com.vn/wp-content/uploads/2022/07/laptop_lenovo_legion_s7_8.jpg',
      'description': 'Plus Black & Cyan, Akko CS Switch',
      'rating': 4.8,
      'discount': 10,
      'sold': 250,
    },
        {
      'id': 2,
      'name': 'Bàn phím cơ AKKO 3068B',
      'price': 1890000,
      'oldPrice': 2190000,
      'image': 'assets/products/keyboard1.jpg',
      'description': 'Plus Black & Cyan, Akko CS Switch',
      'rating': 4.8,
      'discount': 10,
      'sold': 250,
    },
        {
      'id': 2,
      'name': 'Bàn phím cơ AKKO 3068B',
      'price': 1890000,
      'oldPrice': 2190000,
      'image': 'assets/products/keyboard1.jpg',
      'description': 'Plus Black & Cyan, Akko CS Switch',
      'rating': 4.8,
      'discount': 10,
      'sold': 250,
    },
        {
      'id': 2,
      'name': 'Bàn phím cơ AKKO 3068B',
      'price': 1890000,
      'oldPrice': 2190000,
      'image': 'assets/products/keyboard1.jpg',
      'description': 'Plus Black & Cyan, Akko CS Switch',
      'rating': 4.8,
      'discount': 10,
      'sold': 250,
    },
        {
      'id': 2,
      'name': 'Bàn phím cơ AKKO 3068B',
      'price': 1890000,
      'oldPrice': 2190000,
      'image': 'assets/products/keyboard1.jpg',
      'description': 'Plus Black & Cyan, Akko CS Switch',
      'rating': 4.8,
      'discount': 10,
      'sold': 250,
    },
        {
      'id': 2,
      'name': 'Bàn phím cơ AKKO 3068B',
      'price': 1890000,
      'oldPrice': 2190000,
      'image': 'assets/products/keyboard1.jpg',
      'description': 'Plus Black & Cyan, Akko CS Switch',
      'rating': 4.8,
      'discount': 10,
      'sold': 250,
    },
        {
      'id': 2,
      'name': 'Bàn phím cơ AKKO 3068B',
      'price': 1890000,
      'oldPrice': 2190000,
      'image': 'assets/products/keyboard1.jpg',
      'description': 'Plus Black & Cyan, Akko CS Switch',
      'rating': 4.8,
      'discount': 10,
      'sold': 250,
    },
        {
      'id': 2,
      'name': 'Bàn phím cơ AKKO 3068B',
      'price': 1890000,
      'oldPrice': 2190000,
      'image': 'assets/products/keyboard1.jpg',
      'description': 'Plus Black & Cyan, Akko CS Switch',
      'rating': 4.8,
      'discount': 10,
      'sold': 250,
    },
        {
      'id': 2,
      'name': 'Bàn phím cơ AKKO 3068B',
      'price': 1890000,
      'oldPrice': 2190000,
      'image': 'assets/products/keyboard1.jpg',
      'description': 'Plus Black & Cyan, Akko CS Switch',
      'rating': 4.8,
      'discount': 10,
      'sold': 250,
    },
        {
      'id': 2,
      'name': 'Bàn phím cơ AKKO 3068B',
      'price': 1890000,
      'oldPrice': 2190000,
      'image': 'assets/products/keyboard1.jpg',
      'description': 'Plus Black & Cyan, Akko CS Switch',
      'rating': 4.8,
      'discount': 10,
      'sold': 250,
    },
        {
      'id': 2,
      'name': 'Bàn phím cơ AKKO 3068B',
      'price': 1890000,
      'oldPrice': 2190000,
      'image': 'assets/products/keyboard1.jpg',
      'description': 'Plus Black & Cyan, Akko CS Switch',
      'rating': 4.8,
      'discount': 10,
      'sold': 250,
    },
        {
      'id': 2,
      'name': 'Bàn phím cơ AKKO 3068B',
      'price': 1890000,
      'oldPrice': 2190000,
      'image': 'assets/products/keyboard1.jpg',
      'description': 'Plus Black & Cyan, Akko CS Switch',
      'rating': 4.8,
      'discount': 10,
      'sold': 250,
    },
        {
      'id': 2,
      'name': 'Bàn phím cơ AKKO 3068B',
      'price': 1890000,
      'oldPrice': 2190000,
      'image': 'assets/products/keyboard1.jpg',
      'description': 'Plus Black & Cyan, Akko CS Switch',
      'rating': 4.8,
      'discount': 10,
      'sold': 250,
    },
        {
      'id': 2,
      'name': 'Bàn phím cơ AKKO 3068B',
      'price': 1890000,
      'oldPrice': 2190000,
      'image': 'assets/products/keyboard1.jpg',
      'description': 'Plus Black & Cyan, Akko CS Switch',
      'rating': 4.8,
      'discount': 10,
      'sold': 250,
    },
        {
      'id': 2,
      'name': 'Bàn phím cơ AKKO 3068B',
      'price': 1890000,
      'oldPrice': 2190000,
      'image': 'assets/products/keyboard1.jpg',
      'description': 'Plus Black & Cyan, Akko CS Switch',
      'rating': 4.8,
      'discount': 10,
      'sold': 250,
    },
    // Add more products...
  ];

  List<Map<String, dynamic>> displayedProducts = [];
  bool isLoading = false;
  int currentPage = 0;
  final int itemsPerPage = 10;
int getCrossAxisCount(double width) {
  if (width >= 2000) return 4; // Desktop
  if (width >= 1200) return 3;  // Tablet
  if (width >= 500) return 2;  // Large phone
  return 1; // Small phone
}

  @override
  void initState() {
    super.initState();
    _loadMoreProducts();
    widget.scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (widget.scrollController.position.pixels >=
        widget.scrollController.position.maxScrollExtent - 500) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadMoreProducts() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    // Simulate API call delay
    await Future.delayed(Duration(seconds: 1));

    final start = currentPage * itemsPerPage;
    final end = start + itemsPerPage;
    
    if (start < allProducts.length) {
      setState(() {
        displayedProducts.addAll(
          allProducts.sublist(start, end.clamp(0, allProducts.length))
        );
        currentPage++;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }
// Add these methods to the _ProductListViewState class

Map<String, dynamic> _getResponsiveValues(double width) {
  if (width >= 1400) {
    return {
      'columns': 4,
      'aspectRatio': 0.75,
      'imageHeight': 200.0,
      'titleSize': 16.0,
      'descriptionSize': 13.0,
      'priceSize': 18.0,
      'padding': 16.0,
      'spacing': 20.0,
      'starSize': 16.0,
    };
  } else if (width >= 1000) {
    return {
      'columns': 3,
      'aspectRatio': 0.8,
      'imageHeight': 180.0,
      'titleSize': 15.0,
      'descriptionSize': 12.0,
      'priceSize': 16.0,
      'padding': 12.0,
      'spacing': 16.0,
      'starSize': 14.0,
    };
  } else if (width >= 600) {
    return {
      'columns': 2,
      'aspectRatio': 0.85,
      'imageHeight': 160.0,
      'titleSize': 14.0,
      'descriptionSize': 12.0,
      'priceSize': 15.0,
      'padding': 10.0,
      'spacing': 12.0,
      'starSize': 14.0,
    };
  } else {
    return {
      'columns': 1,
      'aspectRatio': 1.2,
      'imageHeight': 140.0,
      'titleSize': 14.0,
      'descriptionSize': 12.0,
      'priceSize': 14.0,
      'padding': 8.0,
      'spacing': 8.0,
      'starSize': 12.0,
    };
  }
}

Widget _buildLoadingCard(Map<String, dynamic> responsive) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Container(
      padding: EdgeInsets.all(responsive['padding']),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          SizedBox(height: responsive['padding']),
          Container(
            height: 16,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: 8),
          Container(
            height: 12,
            width: double.infinity * 0.7,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildPriceRow(Map<String, dynamic> product, Map<String, dynamic> responsive) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '₫${product['price'].toString().replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]},'
              )}',
              style: TextStyle(
                color: Colors.red,
                fontSize: responsive['priceSize'],
                fontWeight: FontWeight.bold,
              ),
            ),
            if (product['oldPrice'] != null)
              Text(
                '₫${product['oldPrice'].toString().replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                  (Match m) => '${m[1]},'
                )}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: responsive['descriptionSize'],
                  decoration: TextDecoration.lineThrough,
                ),
              ),
          ],
        ),
      ),
      if (product['discount'] != null)
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: responsive['padding'] * 0.5,
            vertical: responsive['padding'] * 0.25,
          ),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '-${product['discount']}%',
            style: TextStyle(
              color: Colors.red,
              fontSize: responsive['descriptionSize'],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
    ],
  );
}

Widget _buildRatingRow(Map<String, dynamic> product, Map<String, dynamic> responsive) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: List.generate(5, (index) {
          return Icon(
            index < (product['rating'] ?? 0).floor()
                ? Icons.star
                : Icons.star_border,
            color: Colors.amber,
            size: responsive['starSize'],
          );
        }),
      ),
      Text(
        'Đã bán ${product['sold']}',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: responsive['descriptionSize'],
        ),
      ),
    ],
  );
}

@override
void dispose() {
  widget.scrollController.removeListener(_onScroll);
  super.dispose();
}
@override
Widget build(BuildContext context) {
  final responsive = _getResponsiveValues(widget.width);

  return Container(
    width: widget.width,
    padding: EdgeInsets.all(responsive['padding']),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final columns = responsive['columns'] as int; // Explicitly cast to int
        return Column(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                childAspectRatio: responsive['aspectRatio'],
                crossAxisSpacing: responsive['spacing'],
                mainAxisSpacing: responsive['spacing'],
              ),
              itemCount: displayedProducts.length + (isLoading ? columns : 0), // Use the local int variable
              itemBuilder: (context, index) {
                if (index >= displayedProducts.length) {
                  return _buildLoadingCard(responsive);
                }
                return _buildProductCard(
                  displayedProducts[index], 
                  responsive, 
                  constraints.maxWidth / columns
                );
              },
            ),
          ],
        );
      },
    ),
  );
}


Widget _buildProductCard(Map<String, dynamic> product, Map<String, dynamic> responsive, double cardWidth) {
  return SizedBox(
    width: cardWidth,
    child: Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Handle product selection
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image container with fixed height
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    product['image'],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Product details
            Padding(
              padding: EdgeInsets.all(responsive['padding']),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: responsive['titleSize'],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    product['description'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: responsive['descriptionSize'],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  _buildPriceRow(product, responsive),
                  SizedBox(height: 4),
                  _buildRatingRow(product, responsive),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
