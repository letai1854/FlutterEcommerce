import 'package:flutter/material.dart';
class BuildThumbnail extends StatefulWidget {
  final String imageUrl;
  final Function(String) onThumbnailSelected;

  const BuildThumbnail({
    Key? key,
    required this.imageUrl,
    required this.onThumbnailSelected,
  }) : super(key: key);

  @override
  State<BuildThumbnail> createState() => _BuildThumbnailState();
}


class _BuildThumbnailState extends State<BuildThumbnail> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => widget.onThumbnailSelected(widget.imageUrl),
      child: Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
        child: Image.network(
          widget.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.error);
          },
        ),
      ),
    );
  }
}


class BuilColorOption extends StatefulWidget {
  final Map<String, dynamic> colorData;
  final Function(int) onColorSelected;
  final List<Map<String, dynamic>> productData; // Thêm productData vào constructor

  const BuilColorOption({
    super.key,
    required this.colorData,
    required this.onColorSelected,
    required this.productData, // Nhận productData từ cha
  });

  @override
  State<BuilColorOption> createState() => _BuilColorOptionState();
}

class _BuilColorOptionState extends State<BuilColorOption> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        int selectedIndex = widget.productData.indexOf(widget.colorData);
        widget.onColorSelected(selectedIndex);
      },
      child: Container(
        width: 40,
        height: 40,
        margin: EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.grey,
          border: Border.all(color: Colors.grey),
          image: DecorationImage(
            image: NetworkImage(widget.colorData['mainImage']),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}class buildReveiwSection extends StatefulWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> displayedReviews;
  final List<Map<String, dynamic>> reviews;
  final VoidCallback loadMoreReviews;
  final VoidCallback submitReview;
  final TextEditingController commentController;
  final int selectedRating;
  final ValueChanged<int> onRatingChanged; // Callback để thay đổi rating

  const buildReveiwSection({
    super.key,
    required this.isLoading,
    required this.displayedReviews,
    required this.reviews,
    required this.loadMoreReviews,
    required this.submitReview,
    required this.commentController,
    required this.selectedRating,
    required this.onRatingChanged, // Truyền hàm callback
  });

  @override
  State<buildReveiwSection> createState() => _buildReivewSectionState();
}

class _buildReivewSectionState extends State<buildReveiwSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mô tả sản phẩm',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('Đây là mô tả chi tiết về sản phẩm. Sản phẩm này có chất lượng tuyệt vời và đáng tin cậy. Hãy mua ngay!'),
        SizedBox(height: 32),
        Text('Đánh giá sản phẩm',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        _buildReviewSection(),
      ],
    );
  }

  Widget _buildReviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (index) {
            return InkWell(
              onTap: () {
                widget.onRatingChanged(index + 1); // Gọi callback để cập nhật rating
              },
              child: Icon(
                Icons.star,
                color: index < widget.selectedRating ? Colors.amber : Colors.grey,
                size: 30,
              ),
            );
          }),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.commentController,
                decoration: InputDecoration(
                  hintText: 'Nhập bình luận của bạn',
                  border: OutlineInputBorder(),
                ),
                onFieldSubmitted: (value) {
                  if (value.isNotEmpty) {
                    widget.submitReview(); // Gọi hàm gửi bình luận khi nhấn Enter
                  }
                },
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              onPressed: widget.submitReview,
              icon: Icon(Icons.send),
            ),
          ],
        ),
        SizedBox(height: 16),
        Text('Các đánh giá khác',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: widget.displayedReviews.length,
          itemBuilder: (context, index) {
            final review = widget.displayedReviews[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage(review['avatar']),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(review['name'],
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Row(
                            children: List.generate(
                              review['rating'],
                              (index) => Icon(Icons.star,
                                  color: Colors.amber, size: 16),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(review['comment']),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (widget.isLoading)
          Center(child: CircularProgressIndicator()), // Hiển thị loading indicator
        if (widget.displayedReviews.length < widget.reviews.length && !widget.isLoading)
          TextButton(
            onPressed: widget.loadMoreReviews,
            child: Text('Tải thêm đánh giá'),
          ),
      ],
    );
  }
}
