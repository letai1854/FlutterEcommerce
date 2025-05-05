import 'package:flutter/foundation.dart';

enum UserRole { quan_tri, khach_hang }

// DTO for User responses - excludes sensitive info like password
class User {
  final int? id;
  final String email;
  final String fullName;
  String? avatar; // Remove 'final' to make avatar mutable
  final String role; // 'khach_hang' or 'quan_tri'
  final String status; // 'kich_hoat' or 'khoa'
  final double customerPoints;
  final DateTime? createdDate;
  final DateTime? updatedDate;
  // Add other fields as needed, e.g., addresses if you want to include them

  User({
    this.id,
    required this.email,
    required this.fullName,
    this.avatar,
    required this.role,
    required this.status,
    required this.customerPoints,
    this.createdDate,
    this.updatedDate,
  });

  // Factory constructor to create a User from a Map (e.g., from API response)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      fullName: map['fullName'],
      avatar: map['avatar'],
      role: map['role'],
      status: map['status'],
      customerPoints: map['customerPoints'] is int
          ? (map['customerPoints'] as int).toDouble()
          : map['customerPoints'],
      createdDate: map['createdDate'] != null
          ? DateTime.parse(map['createdDate'])
          : null,
      updatedDate: map['updatedDate'] != null
          ? DateTime.parse(map['updatedDate'])
          : null,
    );
  }

  // Method to convert a User object to a Map (e.g., for sending to backend)
  Map<String, dynamic> toMap() {
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
}
