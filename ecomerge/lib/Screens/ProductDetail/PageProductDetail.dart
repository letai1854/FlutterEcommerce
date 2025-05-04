import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForTablet.dart'; // Đảm bảo đường dẫn chính xác
import 'package:e_commerce_app/widgets/NavbarMobile/NavbarForMobile.dart';   // Đảm bảo đường dẫn chính xác
import 'package:e_commerce_app/widgets/Product/ProductDetailInfo.dart';   // Đảm bảo đường dẫn chính xác
import 'package:e_commerce_app/widgets/navbarHomeDesktop.dart';        // Đảm bảo đường dẫn chính xác
import 'package:flutter/material.dart';

class Pageproductdetail extends StatefulWidget {
  const Pageproductdetail({super.key});

  @override
  State<Pageproductdetail> createState() => _PageproductdetailState();
}

class _PageproductdetailState extends State<Pageproductdetail> {
  // --- State Variables ---
  final ScrollController _scrollController = ScrollController();
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _displayedReviews = [];
  int _reviewsPerPage = 2;
  bool _isLoadingReviews = false;
  int _selectedVariantIndex = 0; // Index của biến thể đang được chọn

  // --- State Variable: Lưu URL ảnh đang hiển thị ở khu vực chính ---
  String _displayedMainImageUrl = '';

  // --- Product Level Data ---
  final Map<String, dynamic> productData = {
    'name': "Tai nghe Bluetooth Air31",
    'brand': "Hãng ABC",
    'averageRating': 4.8,
    'ratingCount': 123,
    'shortDescription': """
Trải nghiệm âm thanh không dây đỉnh cao với Tai nghe Bluetooth Air31.
Thiết kế công thái học, vừa vặn hoàn hảo cho cảm giác thoải mái suốt ngày dài.
Chất lượng âm thanh sống động, bass mạnh mẽ, treble trong trẻo.
Kết nối Bluetooth 5.3 ổn định, phạm vi kết nối rộng, độ trễ thấp.
Thời lượng pin ấn tượng, kèm hộp sạc tiện lợi cho nhiều lần sạc lại.
""",
    // Danh sách ảnh minh họa cố định (không đổi theo biến thể)
    'illustrationImages': [
      'https://spencil.vn/wp-content/uploads/2024/11/chup-anh-san-pham-SPencil-Agency-1.jpg', // Ảnh minh họa 1
      'https://cdn.tgdd.vn/Files/2022/07/24/1450033/laptop-man-hinh-full-hd-la-gi-kinh-nghiem-chon-mu-2.jpg', // Ảnh minh họa 2
      'https://images.unsplash.com/photo-1523275335684-37898b6baf30?q=80&w=1000&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8cHJvZHVjdHxlbnwwfHwwfHx8MA%3D%3D', // Ảnh minh họa 3
      // Có thể thêm nhiều ảnh minh họa hơn ở đây
       'https://via.placeholder.com/150/0000FF/FFFFFF?Text=Illustration+4', // Ví dụ ảnh minh họa 4
    ],
  };

  // --- Variant Specific Data ---
  final List<Map<String, dynamic>> productVariants = [
    {
      'name': 'Đen',
      'mainImage':'https://spencil.vn/wp-content/uploads/2024/11/chup-anh-san-pham-SPencil-Agency-1.jpg', // Ảnh chính mặc định cho biến thể Đen
      'variantThumbnail': 'https://spencil.vn/wp-content/uploads/2024/11/chup-anh-san-pham-SPencil-Agency-1.jpg', // Ảnh nhỏ đại diện biến thể Đen
      'stock': 3000,
    },
    {
      'name': 'Trắng',
      'mainImage': 'https://cdn.tgdd.vn/Files/2022/07/24/1450033/laptop-man-hinh-full-hd-la-gi-kinh-nghiem-chon-mu-2.jpg', // Ảnh chính mặc định cho biến thể Trắng
       'variantThumbnail': 'https://cdn.tgdd.vn/Files/2022/07/24/1450033/laptop-man-hinh-full-hd-la-gi-kinh-nghiem-chon-mu-2.jpg', // Ảnh nhỏ đại diện biến thể Trắng
       'stock': 1500,
    },
    {
      'name': 'Xanh',
      'mainImage': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?q=80&w=1000&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8cHJvZHVjdHxlbnwwfHwwfHx8MA%3D%3D', // Ảnh chính mặc định cho biến thể Xanh
      'variantThumbnail': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?q=80&w=1000&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8cHJvZHVjdHxlbnwwfHwwfHx8MA%3D%3D', // Ảnh nhỏ đại diện biến thể Xanh
      'stock': 500,
    },
  ];

  // --- Reviews Data ---
  final List<Map<String, dynamic>> allReviews = [
    {'name': 'Nguyễn Văn A', 'rating': 5, 'comment': 'Sản phẩm tuyệt vời, đáng mua!', 'avatar': 'assets/avatar1.png',},
    {'name': 'Trần Thị B', 'rating': 4, 'comment': 'Chất lượng tốt, giá cả hợp lý.', 'avatar': 'assets/avatar2.png',},
    {'name': 'Lê Văn C', 'rating': 3, 'comment': 'Sản phẩm ổn, nhưng giao hàng hơi chậm.', 'avatar': 'assets/avatar3.png',},
    {'name': 'Phạm Thị D', 'rating': 5, 'comment': 'Rất hài lòng về sản phẩm và dịch vụ.', 'avatar': 'assets/avatar4.png',},
    {'name': 'Hoàng Văn E', 'rating': 4, 'comment': 'Sản phẩm tốt, đóng gói cẩn thận.', 'avatar': 'assets/avatar5.png', },
    {'name': 'Đặng Thị F', 'rating': 3, 'comment': 'Giá hơi cao so với chất lượng.', 'avatar': 'assets/avatar6.png', },
  ];

  // --- Derived State ---
  int get _currentStock => productVariants[_selectedVariantIndex]['stock'];
  bool get _canLoadMoreReviews => _displayedReviews.length < allReviews.length;

  @override
  void initState() {
    super.initState();
    _loadInitialReviews();
    _scrollController.addListener(_loadMoreReviewsOnScroll);

    // Khởi tạo ảnh hiển thị chính bằng ảnh của biến thể đầu tiên
    if (productVariants.isNotEmpty && productVariants[0]['mainImage'] != null) {
      _displayedMainImageUrl = productVariants[0]['mainImage'];
    } else if (productData['illustrationImages'] != null &&
               (productData['illustrationImages'] as List).isNotEmpty) {
      // Hoặc fallback về ảnh minh họa đầu tiên nếu không có ảnh biến thể
      _displayedMainImageUrl = (productData['illustrationImages'] as List)[0];
    }
    // Else: _displayedMainImageUrl sẽ là chuỗi rỗng, cần xử lý ở Image.network
  }

  @override
  void dispose() {
    _scrollController.removeListener(_loadMoreReviewsOnScroll);
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // --- Methods ---
  void _loadInitialReviews() {
    setState(() {
      _displayedReviews = allReviews.take(_reviewsPerPage).toList();
    });
  }

  Future<void> _loadMoreReviews() async {
    if (_isLoadingReviews || !_canLoadMoreReviews) return;
    setState(() => _isLoadingReviews = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final startIndex = _displayedReviews.length;
    final endIndex = (startIndex + _reviewsPerPage > allReviews.length)
        ? allReviews.length
        : startIndex + _reviewsPerPage;
    if (startIndex < endIndex) {
      setState(() {
        _displayedReviews.addAll(allReviews.sublist(startIndex, endIndex));
      });
    }
    setState(() => _isLoadingReviews = false);
  }

  void _loadMoreReviewsOnScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _loadMoreReviews();
    }
  }

  // Callback khi chọn một BIẾN THỂ
  void _onVariantSelected(int index) {
    if (index >= 0 && index < productVariants.length) {
      setState(() {
        _selectedVariantIndex = index;
        _displayedMainImageUrl = productVariants[index]['mainImage']; // Cập nhật ảnh chính
      });
    }
  }

  // Callback khi nhấn vào một ẢNH MINH HỌA
  void _onIllustrationImageSelected(String imageUrl) {
     print("Illustration image selected: $imageUrl");
     setState(() {
       _displayedMainImageUrl = imageUrl; // Cập nhật ảnh chính
     });
  }

   void _onRatingChanged(int newRating) {
    setState(() {
      _selectedRating = newRating;
    });
  }

  void _submitReview() {
    if (_selectedRating > 0 && _commentController.text.trim().isNotEmpty) {
      final newReview = { 'name': 'Bạn', 'rating': _selectedRating, 'comment': _commentController.text.trim(), 'avatar': 'assets/default_avatar.png', };
      setState(() {
        allReviews.insert(0, newReview);
        _displayedReviews.insert(0, newReview);
        _selectedRating = 0; _commentController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đánh giá của bạn đã được gửi!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn sao đánh giá và nhập bình luận.')));
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    // Lấy danh sách ảnh minh họa, đảm bảo là List<String>
    final List<String> illustrations = (productData['illustrationImages'] is List)
      ? List<String>.from(productData['illustrationImages'])
      : [];

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        // Widget body chính
        Widget body = ProductDetialInfo(
          // Product Data
          productName: productData['name'] ?? 'N/A',
          brandName: productData['brand'] ?? 'N/A',
          averageRating: productData['averageRating']?.toDouble() ?? 0.0,
          ratingCount: productData['ratingCount'] ?? 0,
          shortDescription: productData['shortDescription'] ?? '',
          illustrationImages: illustrations,

          // Variant Data
          productVariants: productVariants,
          selectedVariantIndex: _selectedVariantIndex,
          currentStock: _currentStock,
          onVariantSelected: _onVariantSelected,

          // Image Display Data & Callbacks
          displayedMainImageUrl: _displayedMainImageUrl, // URL ảnh chính đang hiển thị
          onIllustrationImageSelected: _onIllustrationImageSelected, // Callback nhấn ảnh minh họa

          // Review Data & Callbacks
          scrollController: _scrollController,
          displayedReviews: _displayedReviews,
          totalReviews: allReviews.length,
          isLoadingReviews: _isLoadingReviews,
          canLoadMoreReviews: _canLoadMoreReviews,
          loadMoreReviews: _loadMoreReviews,
          submitReview: _submitReview,
          commentController: _commentController,
          selectedRating: _selectedRating,
          onRatingChanged: _onRatingChanged,

          // Action Callbacks
          onAddToCart: () {
             print("Add to Cart pressed for variant: ${productVariants[_selectedVariantIndex]['name']}");
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã thêm "${productVariants[_selectedVariantIndex]['name']}" vào giỏ hàng!')));
          },
          onBuyNow: () {
            print("Buy Now pressed for variant: ${productVariants[_selectedVariantIndex]['name']}");
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chuyển đến thanh toán cho "${productVariants[_selectedVariantIndex]['name']}"!')));
          },
        );

        // --- Responsive Scaffold/Navbar logic ---
        if (screenWidth < 768) {
           // Cần đảm bảo NavbarFixmobile trả về một widget phù hợp (ví dụ: AppBar)
           return NavbarFormobile(
             body: body,
           );
          //  return Scaffold(
          //    appBar: PreferredSize(
          //       preferredSize: Size.fromHeight(kToolbarHeight), // Hoặc kích thước phù hợp của Navbar
          //       child: NavbarFormobile(),
          //    ),
          //    body: body,
          //  );
        } else if (screenWidth < 1100) {
          return NavbarForTablet(
            body: body,
          );
          //  // Cần đảm bảo NavbarFixTablet trả về một widget phù hợp
          //   return Scaffold(
          //    appBar: PreferredSize(
          //      preferredSize: Size.fromHeight(kToolbarHeight), // Hoặc kích thước phù hợp của Navbar
          //      child: NavbarForTablet(),
          //    ),
          //    body: body,
          //  );
        } else {
          // Desktop
          return Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(130), // Kích thước Navbar Desktop
              child: Navbarhomedesktop(),
            ),
            body: body,
          );
        }
      },
    );
  }
}
