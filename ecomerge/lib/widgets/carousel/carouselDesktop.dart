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
  int _current = 0;

  // Helper method to create an image widget with error handling
  Widget _buildImageContainer(String assetPath, double height) {
    // Fix the path construction for web
    String webPath =
        assetPath.startsWith('assets/') ? assetPath : 'assets/$assetPath';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: Colors.grey[200], // Fallback color if image fails to load
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: kIsWeb
            ? Image.network(
                // Use the corrected path
                webPath,
                fit: BoxFit.cover,
                width: double.infinity,
                height: height,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading web image: $assetPath - $error');
                  return Center(
                    child: Icon(Icons.broken_image,
                        size: 36, color: Colors.grey[400]),
                  );
                },
              )
            : Image.asset(
                assetPath,
                fit: BoxFit.cover,
                width: double.infinity,
                height: height,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(Icons.broken_image,
                        size: 36, color: Colors.grey[400]),
                  );
                },
              ),
      ),
    );
  }

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
                  child: kIsWeb
                      ? Image.network(
                          item.startsWith('assets/')
                              ? item
                              : 'assets/$item', // Fix here too
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: carouselHeight,
                          alignment: Alignment.center,
                          errorBuilder: (context, error, stackTrace) {
                            print(
                                'Error loading carousel image: $item - $error');
                            return Center(
                              child: Icon(Icons.broken_image,
                                  size: 36, color: Colors.grey[400]),
                            );
                          },
                        )
                      : Image.asset(
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
                  child: _buildImageContainer(
                      'assets/poster7.png', carouselHeight / 2.08),
                ),
                const SizedBox(height: 7),
                SizedBox(
                  width: double.infinity,
                  height: carouselHeight / 2.08,
                  child: _buildImageContainer(
                      'assets/poster10.png', carouselHeight / 2.08),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
