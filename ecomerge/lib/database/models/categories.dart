class CategoryDTO {
  // Sử dụng final fields cho tính bất biến (immutable)
  final int? id; // Maps to Integer id
  final String? name; // Maps to String name
  final String? imageUrl; // Maps to String imageUrl
  final DateTime? createdDate; // Maps to Date createdDate (using DateTime in Dart)
  final DateTime? updatedDate; // Maps to Date updatedDate

  // Constructor với named parameters (khuyến khích trong Dart)
  CategoryDTO({
    this.id,
    this.name,
    this.imageUrl,
    this.createdDate,
    this.updatedDate,
  });

  // Factory constructor để tạo một CategoryDTO object từ một JSON map
  // Đây là phần quan trọng để parse dữ liệu nhận từ API
  factory CategoryDTO.fromJson(Map<String, dynamic> json) {
    // Giả định các key trong JSON trùng với tên trường trong DTO Java
    // (id, name, imageUrl, createdDate, updatedDate)
    // Nếu API của bạn trả về tên key khác (ví dụ: snake_case như ten_danh_muc),
    // bạn cần điều chỉnh tên key ở đây.
    return CategoryDTO(
      id: json['id'] as int?, // Ép kiểu an toàn sang int?
      name: json['name'] as String?, // Ép kiểu an toàn sang String?
      imageUrl: json['imageUrl'] as String?, // Ép kiểu an toàn sang String?
      // Ngày tháng thường được gửi dưới dạng chuỗi ISO 8601 từ server
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'] as String)
          : null, // Parse chuỗi ngày tháng
      updatedDate: json['updatedDate'] != null
          ? DateTime.parse(json['updatedDate'] as String)
          : null,
    );
  }

  // Phương thức để chuyển đổi một CategoryDTO object sang một JSON map
  // Hữu ích khi cần gửi dữ liệu lên server (ví dụ: PUT/POST)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'createdDate': createdDate?.toIso8601String(), // Chuyển DateTime sang chuỗi ISO 8601
      'updatedDate': updatedDate?.toIso8601String(),
    };
  }

  // Optional: Thêm phương thức copyWith để dễ dàng tạo instance mới với vài trường thay đổi
  CategoryDTO copyWith({
    int? id,
    String? name,
    String? imageUrl,
    DateTime? createdDate,
    DateTime? updatedDate,
  }) {
    return CategoryDTO(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }

  @override
  String toString() {
    return 'CategoryDTO(id: $id, name: $name, imageUrl: $imageUrl, createdDate: $createdDate, updatedDate: $updatedDate)';
  }
}
