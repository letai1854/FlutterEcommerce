import 'package:e_commerce_app/constants.dart';
import 'package:e_commerce_app/widgets/ProductDetail/ProductDetialWidget.dart';
import 'package:e_commerce_app/widgets/footer.dart';
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';
import 'package:e_commerce_app/widgets/navbarHomeTablet.dart';
import 'package:flutter/material.dart';

class ProductdetailTablet extends StatefulWidget {
  const ProductdetailTablet({Key? key}) : super(key: key);

  @override
  State<ProductdetailTablet> createState() => _ProductdetailTabletState();
}

class _ProductdetailTabletState extends State<ProductdetailTablet> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(130),
        child: NavbarhomeTablet(context),
      ),
      body: ProductDetialDesktop(),
    );
  }
}

class ProductDetialDesktop extends StatefulWidget {
  const ProductDetialDesktop({Key? key}) : super(key: key);

  @override
  State<ProductDetialDesktop> createState() => _ProductDetialDesktopState();
}

class _ProductDetialDesktopState extends State<ProductDetialDesktop> {
  int _current = 0;
  final ScrollController _scrollController = ScrollController();
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _displayedReviews = []; // Danh sách đánh giá hiển thị
  int _reviewsPerPage = 2; // Số lượng đánh giá hiển thị ban đầu
  bool _isLoading = false;

  // Dữ liệu giả
  final List<Map<String, dynamic>> productData = [
    {
      'color': 'Đen',
      'mainImage':
          'https://spencil.vn/wp-content/uploads/2024/11/chup-anh-san-pham-SPencil-Agency-1.jpg',
      'thumbnails': [
        'https://spencil.vn/wp-content/uploads/2024/11/chup-anh-san-pham-SPencil-Agency-1.jpg',
        'https://spencil.vn/wp-content/uploads/2024/11/chup-anh-san-pham-SPencil-Agency-1.jpg',
        'https://cdn.tgdd.vn/Files/2022/07/24/1450033/laptop-man-hinh-full-hd-la-gi-kinh-nghiem-chon-mu-2.jpg',
      ],
    },
    {
      'color': 'Trắng',
      'mainImage':
          'https://cdn.tgdd.vn/Files/2022/07/24/1450033/laptop-man-hinh-full-hd-la-gi-kinh-nghiem-chon-mu-2.jpg',
      'thumbnails': [
        'https://cdn.tgdd.vn/Files/2022/07/24/1450033/laptop-man-hinh-full-hd-la-gi-kinh-nghiem-chon-mu-2.jpg',
        'https://spencil.vn/wp-content/uploads/2024/11/chup-anh-san-pham-SPencil-Agency-1.jpg',
        'https://cdn.tgdd.vn/Files/2022/07/24/1450033/laptop-man-hinh-full-hd-la-gi-kinh-nghiem-chon-mu-2.jpg',
      ],
    },
    {
      'color': 'Xanh',
      'mainImage':
          'https://spencil.vn/wp-content/uploads/2024/11/chup-anh-san-pham-SPencil-Agency-1.jpg',
      'thumbnails': [
        'https://spencil.vn/wp-content/uploads/2024/11/chup-anh-san-pham-SPencil-Agency-1.jpg',
        'https://cdn.tgdd.vn/Files/2022/07/24/1450033/laptop-man-hinh-full-hd-la-gi-kinh-nghiem-chon-mu-2.jpg',
        'https://spencil.vn/wp-content/uploads/2024/11/chup-anh-san-pham-SPencil-Agency-1.jpg',
      ],
    },
  ];

  final List<Map<String, dynamic>> reviews = [
    {
      'name': 'Nguyễn Văn A',
      'rating': 5,
      'comment': 'Sản phẩm tuyệt vời, đáng mua!',
      'avatar': 'assets/avatar1.png',
    },
    {
      'name': 'Trần Thị B',
      'rating': 4,
      'comment': 'Chất lượng tốt, giá cả hợp lý.',
      'avatar': 'assets/avatar2.png',
    },
    {
      'name': 'Lê Văn C',
      'rating': 3,
      'comment': 'Sản phẩm ổn, nhưng giao hàng hơi chậm.',
      'avatar': 'assets/avatar3.png',
    },
    {
      'name': 'Phạm Thị D',
      'rating': 5,
      'comment': 'Rất hài lòng về sản phẩm và dịch vụ.',
      'avatar': 'assets/avatar4.png',
    },
    {
      'name': 'Hoàng Văn E',
      'rating': 4,
      'comment': 'Sản phẩm tốt, đóng gói cẩn thận.',
      'avatar': 'assets/avatar5.png',
    },
    {
      'name': 'Đặng Thị F',
      'rating': 3,
      'comment': 'Giá hơi cao so với chất lượng.',
      'avatar': 'assets/avatar6.png',
    },
  ];

  String mainImageUrl =
      'https://cdn.tgdd.vn/Files/2022/07/24/1450033/laptop-man-hinh-full-hd-la-gi-kinh-nghiem-chon-mu-2.jpg';
  List<String> thumbnails = [
    'https://spencil.vn/wp-content/uploads/2024/11/chup-anh-san-pham-SPencil-Agency-1.jpg',
    'https://cdn.tgdd.vn/Files/2022/07/24/1450033/laptop-man-hinh-full-hd-la-gi-kinh-nghiem-chon-mu-2.jpg',
    'https://spencil.vn/wp-content/uploads/2024/11/chup-anh-san-pham-SPencil-Agency-1.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialReviews();
    _scrollController.addListener(_loadMoreReviewsOnScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_loadMoreReviewsOnScroll);
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _loadInitialReviews() {
    setState(() {
      _displayedReviews = reviews.take(_reviewsPerPage).toList();
    });
  }

  Future<void> _loadMoreReviews() async {
    if (_isLoading) return; // Không tải thêm nếu đang tải
    _isLoading = true;

    // Giả lập thời gian tải dữ liệu từ server
    await Future.delayed(Duration(milliseconds: 500));

    setState(() {
      // Tính toán số lượng đánh giá cần tải thêm
      int startIndex = _displayedReviews.length;
      int endIndex = startIndex + _reviewsPerPage;

      // Nếu endIndex vượt quá tổng số đánh giá, giới hạn lại
      if (endIndex > reviews.length) {
        endIndex = reviews.length;
      }

      // Nếu startIndex vẫn còn nhỏ hơn tổng số đánh giá
      if (startIndex < reviews.length) {
        _displayedReviews.addAll(reviews.sublist(startIndex, endIndex));
      }
      _isLoading = false;
    });
  }


  void _loadMoreReviewsOnScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreReviews();
    }
  }

  void _onColorSelected(int index) {
    setState(() {
      mainImageUrl = productData[index]['mainImage'];
      thumbnails = List<String>.from(productData[index]['thumbnails']);
    });
  }

  void _onThumbnailSelected(String imageUrl) {
    setState(() {
      mainImageUrl = imageUrl;
    });
  }

  void _submitReview() {
    if ( _commentController.text.isNotEmpty) {

      setState(() {
        _commentController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng cung cấp đánh giá và bình luận.')),
      );
    }
  }
  
@override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    return Container(
      color: Colors.grey[300],
      padding: EdgeInsets.only(top: 16),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 1200),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: screenwidth * 1.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sử dụng Image.network để hiển thị ảnh từ URL
                      Image.network(
                        mainImageUrl,
                        errorBuilder: (context, error, stackTrace) {
                          return Text('Không thể tải ảnh'); // Xử lý lỗi nếu ảnh không tải được
                        },
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: thumbnails
                            .map((imageUrl) => BuildThumbnail(
                                  imageUrl: imageUrl,
                                  onThumbnailSelected: _onThumbnailSelected, // Truyền callback từ widget cha
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ), // <-- Missing comma added here
                SizedBox(
                  width: screenwidth * 1.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tai nghe Bluetooth Air31',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber),
                          Text('4.8 (123 đánh giá)'),
                          SizedBox(width: 16),
                          Text('Thương hiệu: Hãng ABC'),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: productData.map((data) {
                          return BuilColorOption(
                            colorData: data,
                            onColorSelected: _onColorSelected,
                            productData: productData, // Truyền productData vào widget con
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 16),
                      Text('Kho: 3000', style: TextStyle(fontSize: 16)),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              side: BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            onPressed: () {},
                            icon: Icon(Icons.shopping_cart, color: Colors.black),
                            label: Text('Thêm vào giỏ hàng', style: TextStyle(color: Colors.black)),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            onPressed: () {},
                            icon: Icon(Icons.payment, color: Colors.white),
                            label: Text('Mua ngay', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: screenwidth * 1.0,
                  child: Column(
                    children: [ 
                      buildReveiwSection(
                        isLoading: _isLoading,
                        displayedReviews: _displayedReviews,
                        reviews: reviews,
                        loadMoreReviews: _loadMoreReviews,
                        submitReview: _submitReview,
                        commentController: _commentController,
                        selectedRating: _selectedRating,
                        onRatingChanged: (int newRating) { 
                          setState(() {
                            _selectedRating = newRating; 
                          });
                        },
                      ),
                    ],
                  ),
                ),

              ],
            ),

          ),
        ),
      ),
    );
  }


}



