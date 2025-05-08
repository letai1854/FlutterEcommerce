import 'package:e_commerce_app/database/models/user_model.dart'; // Import User model

// Enum for UserRole - match with values in user_model.dart
enum UserRole {
  quan_tri,  // admin
  khach_hang // user
}

// Enum for UserStatus - match with values in user_model.dart
enum UserStatus {
  kich_hoat,  // active
  khoa        // locked/banned
}

// DTO for User responses - excludes sensitive info like password
class UserDTO {
  int? id;
  String? email;
  String? fullName;
  String? avatar;
  String? role;  // Using string to match User model
  String? status; // Using string to match User model
  double? customerPoints;
  DateTime? createdDate;
  DateTime? updatedDate;

  // Constructor to map from User entity
  UserDTO.fromUser(User user) {
    id = user.id;
    email = user.email;
    fullName = user.fullName;
    avatar = user.avatar;
    role = user.role;
    status = user.status;
    customerPoints = user.customerPoints;
    createdDate = user.createdDate;
    updatedDate = user.updatedDate;
  }

  // Default constructor
  UserDTO({
    this.id,
    this.email,
    this.fullName,
    this.avatar,
    this.role,
    this.status,
    this.customerPoints,
    this.createdDate,
    this.updatedDate,
  });

  // Factory constructor to create from JSON
  factory UserDTO.fromJson(Map<String, dynamic> json) {
    return UserDTO(
      id: json['id'],
      email: json['email'],
      fullName: json['fullName'],
      avatar: json['avatar'],
      role: json['role'],
      status: json['status'],
      customerPoints: json['customerPoints'] != null 
          ? double.parse(json['customerPoints'].toString()) 
          : null,
      createdDate: json['createdDate'] != null 
          ? DateTime.parse(json['createdDate']) 
          : null,
      updatedDate: json['updatedDate'] != null 
          ? DateTime.parse(json['updatedDate']) 
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'avatar': avatar,
      'role': role,
      'status': status,
      'customerPoints': customerPoints,
      'createdDate': createdDate?.toIso8601String(),
      'updatedDate': updatedDate?.toIso8601String(),
    };
  }
  
  // Helper method to get role as enum
  UserRole getRoleEnum() {
    if (role == 'quan_tri') {
      return UserRole.quan_tri;
    } else {
      return UserRole.khach_hang;
    }
  }
  
  // Helper method to get status as enum
  UserStatus getStatusEnum() {
    if (status == 'kich_hoat') {
      return UserStatus.kich_hoat;
    } else {
      return UserStatus.khoa;
    }
  }
}
