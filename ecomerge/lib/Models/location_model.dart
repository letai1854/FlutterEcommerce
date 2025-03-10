class Location {
  final String code;
  final String name;
  final String? parentCode;

  Location({
    required this.code,
    required this.name,
    this.parentCode,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      code: json['code'] as String,
      name: json['name'] as String,
      parentCode: json['parent_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'parent_code': parentCode,
    };
  }
}
