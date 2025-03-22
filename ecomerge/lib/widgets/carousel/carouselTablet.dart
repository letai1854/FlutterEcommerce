import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/Constants/ImageCarousel.dart';

class CarouselTablet extends StatefulWidget {
  final double screeWidth;
  const CarouselTablet(this.screeWidth, {Key? key}) : super(key: key);

  @override
  State<CarouselTablet> createState() => _CarouselTabletState();
}

class _CarouselTabletState extends State<CarouselTablet> {
  //late double screenWidth;

  final carouselHeight = 230.0;
  int _current = 0;
  @override
  Widget build(BuildContext context) {
    return Container(
      // banner

      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: widget.screeWidth - 2,
            height: carouselHeight,
            child: CarouselSlider(
              items: ImageAssets.imgList.map((item) {
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
        ],
      ),
    );
  }
}
