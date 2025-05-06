import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import XFile

// Helper để build widget hiển thị ảnh từ nhiều nguồn (Asset, File, Network, XFile)
Widget buildImageDisplayWidget(dynamic imageSource, {double size = 40, double iconSize = 40, BoxFit fit = BoxFit.cover}) {
  if (imageSource == null) {
    return Icon(Icons.camera_alt, size: iconSize, color: Colors.grey); // Placeholder nếu không có nguồn ảnh
  }

  // Nếu là XFile (ảnh mới chọn từ picker)
  if (imageSource is XFile) {
      if (kIsWeb) {
           // Trên Web, XFile.path thường là blob URL hoặc tương tự
         return Image.network(
              imageSource.path,
              fit: fit,
              errorBuilder: (context, error, stackTrace) {
                 if (kDebugMode) print('Error loading web picked image: ${imageSource.path}, Error: $error');
                 return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
              },
           );
      } else {
          // Trên non-Web, XFile.path là đường dẫn file thực tế
          try {
             return Image.file(
                 File(imageSource.path),
                 fit: fit,
                  errorBuilder: (context, error, stackTrace) {
                     if (kDebugMode) print('Error loading file picked image: ${imageSource.path}, Error: $error');
                     return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
                  },
              );
          } catch (e) {
             if (kDebugMode) print('Exception creating File from XFile path: ${imageSource.path}, Exception: $e');
             return Icon(Icons.error_outline, size: iconSize, color: Colors.red);
          }
      }
  }

  // Nếu là String (đường dẫn/URL ban đầu từ dữ liệu sản phẩm hoặc URL mạng)
  if (imageSource is String && imageSource.isNotEmpty) {
      // Kiểm tra xem có phải đường dẫn asset không (kiểm tra đơn giản)
      if (imageSource.startsWith('assets/')) {
         return Image.asset(
               imageSource,
               fit: fit,
                errorBuilder: (context, error, stackTrace) {
                    // Hiển thị placeholder nếu tải asset lỗi
                    if (kDebugMode) print('Error loading asset: $imageSource, Error: $error');
                    return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
                },
           );
       } else if (imageSource.startsWith('http') || imageSource.startsWith('https')) {
           // Giả định đây là URL mạng
           return Image.network(
               imageSource,
               fit: fit,
                errorBuilder: (context, error, stackTrace) {
                    // Hiển thị placeholder nếu tải ảnh mạng lỗi
                    if (kDebugMode) print('Error loading network image: $imageSource, Error: $error');
                    return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
                },
             );
       }
       else {
          // Có thể là đường dẫn file trên non-web, hoặc đường dẫn web khác.
          // Cần xử lý dựa trên nền tảng.
          if (!kIsWeb) { // Chỉ thử File trên non-web
              try {
                 return Image.file(
                     File(imageSource),
                     fit: fit,
                      errorBuilder: (context, error, stackTrace) {
                         if (kDebugMode) print('Error loading file: $imageSource, Error: $error');
                         return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
                      },
                 );
              } catch (e) {
                 if (kDebugMode) print('Exception creating File from path: $imageSource, Exception: $e');
                 return Icon(Icons.error_outline, size: iconSize, color: Colors.red);
              }
          } else { // On web, if not asset/http, try network như fallback (có thể là blob URL)
               return Image.network(
                  imageSource,
                  fit: fit,
                   errorBuilder: (context, error, stackTrace) {
                       if (kDebugMode) print('Error loading web path (fallback): $imageSource, Error: $error');
                       return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
                   },
               );
          }
       }
     }

     // Fallback cho loại nguồn không xác định
     return Icon(Icons.error_outline, size: iconSize, color: Colors.red); // Báo lỗi
   }
