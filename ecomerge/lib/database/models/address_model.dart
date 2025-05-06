class Address {
  final int? id;
  final String recipientName;
  final String phoneNumber;
  final String specificAddress;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Address({
    this.id,
    required this.recipientName,
    required this.phoneNumber,
    required this.specificAddress,
    required this.isDefault,
    this.createdAt,
    this.updatedAt,
  });

  // For backward compatibility
  String get name => recipientName;
  String get phone => phoneNumber;
  String get address => specificAddress;

  // Legacy properties needed for UI until it's updated
  String get province => '';
  String get district => '';
  String get ward => '';

  // Getter for backward compatibility
  String get fullAddress => specificAddress;

  // Create Address from JSON
  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      recipientName: json['recipientName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      specificAddress: json['specificAddress'] ?? '',
      isDefault: json['isDefault'] ?? false,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  // Convert Address to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'specificAddress': specificAddress,
      'isDefault': isDefault,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  // Create a copy of Address with some fields updated
  Address copyWith({
    int? id,
    String? recipientName,
    String? phoneNumber,
    String? specificAddress,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Address(
      id: id ?? this.id,
      recipientName: recipientName ?? this.recipientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      specificAddress: specificAddress ?? this.specificAddress,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Class representing the request object for creating/updating an address
class AddressRequest {
  final String recipientName;
  final String phoneNumber;
  final String specificAddress;
  final bool? isDefault;

  AddressRequest({
    required this.recipientName,
    required this.phoneNumber,
    required this.specificAddress,
    this.isDefault,
  });

  // Convert AddressRequest to JSON
  Map<String, dynamic> toJson() {
    return {
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'specificAddress': specificAddress,
      if (isDefault != null) 'isDefault': isDefault,
    };
  }

  // Create AddressRequest from Address
  factory AddressRequest.fromAddress(Address address) {
    return AddressRequest(
      recipientName: address.recipientName,
      phoneNumber: address.phoneNumber,
      specificAddress: address.specificAddress,
      isDefault: address.isDefault,
    );
  }
}
