import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/Constants/ImageCarousel.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Import kIsWeb

class Carouseldesktop extends StatefulWidget {
  final double screeWidth;
  const Carouseldesktop(this.screeWidth, {Key? key}) : super(key: key);

  @override
  State<Carouseldesktop> createState() => _CarouseldesktopState();
}

class _CarouseldesktopState extends State<Carouseldesktop> {
  //late double screenWidth;

  final carouselHeight = 230.0;
  @override
  Widget build(BuildContext context) {
    return Container(
      // banner

      padding: const EdgeInsets.symmetric(horizontal: 140, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: widget.screeWidth * 0.52,
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
                    // _current = index; // Assignment removed
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
                      borderRadius: BorderRadius.circular(3), // Bo tròn góc
                      image: DecorationImage(
                        image: AssetImage(kIsWeb
                            ? 'poster7.png'
                            : 'assets/poster7.png'), // Conditional path
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
                      borderRadius: BorderRadius.circular(3), // Bo tròn góc
                      image: DecorationImage(
                        image: AssetImage(kIsWeb
                            ? 'poster10.png'
                            : 'assets/poster10.png'), // Conditional path
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
    );
  }
}
