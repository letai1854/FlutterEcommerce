class BrandDTO {
  final int? id; // Maps to Integer id
  final String? name; // Maps to String name
  final DateTime? createdDate; // Maps to Date createdDate
  final DateTime? updatedDate; // Maps to Date updatedDate

  BrandDTO({
    this.id,
    this.name,
    this.createdDate,
    this.updatedDate,
  });

  // Factory constructor for parsing JSON
  factory BrandDTO.fromJson(Map<String, dynamic> json) {
     // Giả định các key trong JSON trùng với tên trường trong DTO Java
    return BrandDTO(
      id: json['id'] as int?,
      name: json['name'] as String?,
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'] as String)
          : null,
      updatedDate: json['updatedDate'] != null
          ? DateTime.parse(json['updatedDate'] as String)
          : null,
    );
  }

  // Method for converting to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdDate': createdDate?.toIso8601String(),
      'updatedDate': updatedDate?.toIso8601String(),
    };
  }

  // Optional: copyWith method
   BrandDTO copyWith({
    int? id,
    String? name,
    DateTime? createdDate,
    DateTime? updatedDate,
  }) {
    return BrandDTO(
      id: id ?? this.id,
      name: name ?? this.name,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }

   @override
  String toString() {
    return 'BrandDTO(id: $id, name: $name, createdDate: $createdDate, updatedDate: $updatedDate)';
  }
}
