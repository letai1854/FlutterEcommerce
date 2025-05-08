import 'dart:convert'; // Needed for jsonDecode

// Represents the pagination response structure from Spring Boot Page<T>
class PageResponse<T> {
  final List<T> content; // The list of items for the current page
  final int totalElements; // Total number of elements across all pages
  final int totalPages; // Total number of available pages
  final int number; // The zero-based number of the current page
  final int size; // The size of the page
  final int numberOfElements; // Number of elements on the current page
  final bool first; // Is this the first page?
  final bool last; // Is this the last page?
  final bool empty; // Is the content list empty?

  // You might also include sort information if needed
  // final dynamic sort; // Or a dedicated Sort object

  PageResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.size,
    required this.numberOfElements,
    required this.first,
    required this.last,
    required this.empty,
    // this.sort,
  });

  // Factory constructor to create a PageResponse from a JSON map
  // It requires a function to parse the generic type T from JSON
  // THIS IS CRUCIAL: It uses fromJsonT to parse items in the content list
  factory PageResponse.fromJson(Map<String, dynamic> json,
      T Function(Map<String, dynamic> json) fromJsonT) {
    List<T> contentList;
    if (json['content'] != null) {
      // Map each item in the 'content' list using the provided fromJsonT function
      contentList = List<T>.from(json['content']
          .map((itemJson) => fromJsonT(itemJson as Map<String, dynamic>)));
    } else {
      contentList = [];
    }

    // Use null-aware operators (??) and safe casting for robustness
    return PageResponse<T>(
      content: contentList,
      totalElements: json['totalElements'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      number: json['number'] as int? ?? 0,
      size: json['size'] as int? ?? 0,
      numberOfElements: json['numberOfElements'] as int? ?? 0,
      first: json['first'] as bool? ?? false,
      last: json['last'] as bool? ?? false,
      empty: json['empty'] as bool? ?? true,
      // sort: json['sort'],
    );
  }

  // Optional: A factory constructor for creating an empty response
  factory PageResponse.empty() {
    return PageResponse(
      content: [],
      totalElements: 0,
      totalPages: 0,
      number: 0,
      size: 0,
      numberOfElements: 0,
      first: true,
      last: true,
      empty: true,
    );
  }

  // Optional: Add a toString or other helper methods for debugging
  @override
  String toString() {
    return 'PageResponse(totalElements: $totalElements, totalPages: $totalPages, number: $number, size: $size, numberOfElements: $numberOfElements, first: $first, last: $last, empty: $empty, content.length: ${content.length})';
  }
}
