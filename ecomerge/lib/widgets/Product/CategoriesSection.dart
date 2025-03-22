import 'package:flutter/material.dart';

class CategoriesSection extends StatefulWidget {
  final int? selectedIndex;
  final Function(int)? onCategorySelected;

  const CategoriesSection({
    Key? key,
    this.selectedIndex,
    this.onCategorySelected,
  }) : super(key: key);

  @override
  _CategoriesSectionState createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<CategoriesSection> {
  Widget _buildCategoryItem(String title, String imageUrl, int index) {
    bool isSelected = widget.selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (widget.onCategorySelected != null) {
            widget.onCategorySelected!(index);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
              SizedBox(width: 1),
              Text(
                'Danh mục',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ]),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCategoryItem('Laptop', 'assets/banner6.jpg', 0),
              _buildCategoryItem('Ram', 'assets/banner6.jpg', 1),
              _buildCategoryItem('Card đồ họa', 'assets/banner6.jpg', 2),
              _buildCategoryItem('Màn hình', 'assets/banner6.jpg', 3),
              _buildCategoryItem('Ổ cứng', 'assets/banner6.jpg', 4),
            ],
          ),
        ],
      ),
    );
  }
}
