// Import các DTO bạn sẽ sử dụng trong PageResponse (tuỳ chọn, chỉ để rõ ràng)
// import 'package:e_commerce_app/database/models/category_dto.dart';
// import 'package:e_commerce_app/database/models/brand_dto.dart';
// import 'package:e_commerce_app/database/models/product_dto.dart';


/// Represents a paginated response from a server API,
/// typically mirroring Spring Data's Page object structure.
class PageResponsive<T> {
  /// The list of elements for the current page.
  final List<T> content;

  /// The total number of pages available.
  final int totalPages;

  /// The total number of elements across all pages.
  final int totalElements;

  /// The requested size of the page.
  final int size;

  /// The current page number (0-based).
  final int number;

  /// Indicates if the current page is the first one.
  final bool first;

  /// Indicates if the current page is the last one.
  final bool last;

  /// Indicates if the content of the current page is empty.
  final bool empty;

  // The sort field and direction are often included but less critical for the PageResponse structure itself,
  // focusing here on the core pagination metadata and content.
  // You could add them if needed:
  // final Sort sort; // You might need a custom Sort class or use Map/dynamic

  /// Constructor for creating a PageResponse object.
  PageResponsive({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.size,
    required this.number,
    required this.first,
    required this.last,
    required this.empty,
    // Add sort field if needed
  });

  /// Factory constructor to create a PageResponse object from a JSON map.
  ///
  /// Requires a [fromJsonT] function to parse each individual item in the
  /// 'content' list from a JSON map into an object of type [T].
  factory PageResponsive.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromJsonT, // Hàm để parse từng item T
      ) {
    // Lấy danh sách 'content' từ JSON, mặc định là rỗng nếu null
    List<dynamic> contentList = json['content'] ?? [];

    // Ánh xạ danh sách động sang danh sách kiểu T bằng cách sử dụng fromJsonT
    List<T> typedContentList = contentList
        .map((itemJson) => fromJsonT(itemJson as Map<String, dynamic>)) // Ép kiểu item sang Map và parse
        .toList(); // Chuyển đổi Iterable sang List

    return PageResponsive<T>(
      content: typedContentList,
      // Lấy các trường meta data khác từ JSON, cung cấp giá trị mặc định nếu null
      totalPages: json['totalPages'] as int? ?? 0,
      totalElements: json['totalElements'] as int? ?? 0,
      size: json['size'] as int? ?? 0,
      number: json['number'] as int? ?? 0,
      first: json['first'] as bool? ?? true, // Mặc định true nếu không có nội dung
      last: json['last'] as bool? ?? true,  // Mặc định true nếu không có nội dung
      empty: json['empty'] as bool? ?? true, // Mặc định true nếu không có nội dung
      // Parse sort field if added
      // sort: json['sort'] != null ? Sort.fromJson(json['sort']) : null,
    );
  }

  /// Factory constructor to create an empty PageResponse.
  /// Useful for representing an empty response (like status 204,
  /// although Spring Page often returns 200 with empty content).
  factory PageResponsive.empty() {
    return PageResponsive(
      content: [],
      totalPages: 0,
      totalElements: 0,
      size: 0,
      number: 0,
      first: true,
      last: true,
      empty: true,
    );
  }

  @override
  String toString() {
    return 'PageResponse(content.length: ${content.length}, totalElements: $totalElements, totalPages: $totalPages, number: $number, size: $size, first: $first, last: $last, empty: $empty)';
  }
}

// Optional: If your backend returns a Sort object, you might need a similar class
/*
class Sort {
  final bool sorted;
  final bool unsorted;
  final bool empty;

  Sort({required this.sorted, required this.unsorted, required this.empty});

  factory Sort.fromJson(Map<String, dynamic> json) {
    return Sort(
      sorted: json['sorted'] as bool? ?? false,
      unsorted: json['unsorted'] as bool? ?? true,
      empty: json['empty'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sorted': sorted,
      'unsorted': unsorted,
      'empty': empty,
    };
  }
}
*/
