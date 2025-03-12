import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:e_commerce_app/constants.dart';
import 'package:e_commerce_app/widgets/footer.dart';
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HomeDesktop extends StatefulWidget {
  const HomeDesktop({super.key});

  @override
  State<HomeDesktop> createState() => _HomeDesktopState();
}

class _HomeDesktopState extends State<HomeDesktop> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(130),
        child: Navbarhomedesktop(),
      ),
      body: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _current = 0;
  final List<String> imgList = [
    'assets/bannerMain.jpg',
    'assets/banner2.jpg',
    'assets/banner6.jpg', // Thay thế bằng đường dẫn ảnh thực tế// Thay thế bằng đường dẫn ảnh thực tế
  ];

  List<Map<String, dynamic>> productData = [
    // Dữ liệu mẫu, bạn sẽ thay thế bằng dữ liệu thực tế
    {
      'image': 'assets/banner2.jpg',
      'title': 'Laptop ASUS Vivobook 14 OLED A1405ZA KM264W',
      'describe': 'Hỗ trợ trả góp MPOS (Thẻ tín dụng), HDSAISON.',
      'price': 1200000,
      'discount': 13,
      'rating': 4
    },
    {
      'image': 'assets/banner3.jpg',
      'title': 'Laptop ASUS Vivobook 14 OLED A1405ZA KM264W',
      'describe': 'Hỗ trợ trả góp MPOS (Thẻ tín dụng), HDSAISON.',
      'price': 1200000,
      'discount': 13,
      'rating': 4
    },
    {
      'image': 'assets/banner7.jpg',
      'title': 'Laptop ASUS Vivobook 14 OLED A1405ZA KM264W',
      'describe': 'Hỗ trợ trả góp MPOS (Thẻ tín dụng), HDSAISON.',
      'price': 1200000,
      'discount': 13,
      'rating': 4
    },
    {
      'image': 'assets/banner6.jpg',
      'title': 'Laptop ASUS Vivobook 14 OLED A1405ZA KM264W',
      'describe': 'Hỗ trợ trả góp MPOS (Thẻ tín dụng), HDSAISON.',
      'price': 1200000,
      'discount': 13,
      'rating': 4
    },
    {
      'image': 'assets/banner5.jpg',
      'title': 'Laptop ASUS Vivobook 14 OLED A1405ZA KM264W',
      'describe': 'Hỗ trợ trả góp MPOS (Thẻ tín dụng), HDSAISON.',
      'price': 1200000,
      'discount': 13,
      'rating': 4
    },
    {
      'image': 'assets/banner4.jpg',
      'title': 'Laptop ASUS Vivobook 14 OLED A1405ZA KM264W',
      'describe': 'Hỗ trợ trả góp MPOS (Thẻ tín dụng), HDSAISON.',
      'price': 1200000,
      'discount': 13,
      'rating': 4
    },
    {
      'image': 'assets/banner7.jpg',
      'title': 'Laptop ASUS Vivobook 14 OLED A1405ZA KM264W',
      'describe': 'Hỗ trợ trả góp MPOS (Thẻ tín dụng), HDSAISON.',
      'price': 1200000,
      'discount': 13,
      'rating': 4
    },
    {
      'image': 'assets/banner3.jpg',
      'title': 'Laptop ASUS Vivobook 14 OLED A1405ZA KM264W',
      'describe': 'Hỗ trợ trả góp MPOS (Thẻ tín dụng), HDSAISON.',
      'price': 1200000,
      'discount': 13,
      'rating': 4
    },
  ];

  List<ProductItem> products = [];

  ScrollController _scrollController = ScrollController();
  bool isLoading = false;
  int itemsPerPage = 3; // Chỉ load 3 sản phẩm mỗi lần
  int currentIndex = 0;
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    _loadMoreData();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !isLoading) {
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    if (currentIndex >= productData.length)
      return; // Nếu đã load hết dữ liệu, không làm gì nữa

    setState(() => isLoading = true);
    await Future.delayed(Duration(seconds: 1)); // Giả lập độ trễ tải dữ liệu

    int nextIndex = currentIndex + itemsPerPage;
    List<ProductItem> newProducts = productData
        .sublist(currentIndex,
            nextIndex > productData.length ? productData.length : nextIndex)
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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final carouselHeight = 230.0;

    return Container(
      decoration: BoxDecoration(),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              // banner

              padding:
                  const EdgeInsets.symmetric(horizontal: 140, vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: screenWidth * 0.52,
                    height: carouselHeight,
                    child: CarouselSlider(
                      items: imgList.map((item) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(3.0),
                          child: Image.asset(
                            item,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: carouselHeight,
                            alignment: Alignment.center,
                          ),
                        );
                      }).toList(),
                      options: CarouselOptions(
                        autoPlay: true,
                        aspectRatio: 5, // Điều chỉnh nếu cần
                        enlargeCenterPage: true,
                        viewportFraction: 1.0,
                        height: carouselHeight,
                        onPageChanged: (index, reason) {
                          setState(() {
                            _current = index;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: carouselHeight / 2.08,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(3), // Bo tròn góc
                              image: DecorationImage(
                                image: AssetImage('assets/banner6.jpg'),
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        SizedBox(
                          width: double.infinity,
                          height: carouselHeight / 2.08,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(3), // Bo tròn góc
                              image: DecorationImage(
                                image: AssetImage('assets/banner7.jpg'),
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 140, vertical: 0),
              child: Column(children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Container(
                      decoration: BoxDecoration(
                        // Bo tròn góc
                        borderRadius: BorderRadius.circular(3),
                        gradient: LinearGradient(
                          colors: [
                            Color.fromARGB(255, 234, 29, 7), // Đỏ
                            Color.fromARGB(255, 255, 85, 0), // Cam
                          ],
                          begin: Alignment.topLeft, // Hướng bắt đầu gradient
                          end: Alignment.bottomRight, // Hướng kết thúc gradient
                        ),
                      ),
                      padding: EdgeInsets.only(left: 30),
                      alignment: Alignment.centerLeft, // Căn giữa văn bản
                      child: Row(
                        children: [
                          Icon(
                            Icons.bolt, // Biểu tượng sấm sét
                            color: Colors.yellow, // Màu vàng nổi bật
                            size: 40,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Sản phẩm khuyến mãi',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              // Để chữ dễ đọc hơn
                            ),
                          ),
                        ],
                      )),
                ),
                SizedBox(height: 10),
                SizedBox(
                  height: 300, // Chiều cao cố định cho PageView

                  child: PageView.builder(
                    itemCount: (productData.length / 6).ceil(),
                    itemBuilder: (context, pageIndex) {
                      final startIndex = pageIndex * 6;
                      final endIndex = min(startIndex + 6, productData.length);

                      return GridView.builder(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          childAspectRatio: 0.7,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                        itemCount: products.length + (isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == products.length) {
                            return Center(
                                child:
                                    CircularProgressIndicator()); // Loading indicator
                          }
                          return ProductItem(
                            imageUrl: productData[index]['image'],
                            title: productData[index]['title'],
                            describe: productData[index]['describe'],
                            price: productData[index]['price'],
                            discount: productData[index]['discount'],
                            rating: productData[index]['rating'],
                          );
                        },
                      );
                    },
                  ),
                ),
              ]),
            ),
            if (kIsWeb) const Footer(),
          ],
        ),
      ),
    );
  }
}

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

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hình ảnh sản phẩm
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8.0),
                  topRight: Radius.circular(8.0),
                ),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red,
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

          // Nội dung sản phẩm
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

                  // Mô tả sản phẩm
                  Text(
                    widget.describe,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Giá sản phẩm
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

                  // Đánh giá sao
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
    );
  }
}
