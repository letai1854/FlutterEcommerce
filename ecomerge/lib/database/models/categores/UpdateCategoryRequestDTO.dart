// lib/database/models/update_category_request_dto.dart

// No special imports needed for basic types

class UpdateCategoryRequestDTO {
    // Fields correspond to Java DTO, required based on @NotBlank
    final String name;
    final String imageUrl; // Required based on @NotBlank

    // Constructor
    UpdateCategoryRequestDTO({
        required this.name,
        required this.imageUrl,
    });

    // Method to convert the object to a JSON map for API calls
    Map<String, dynamic> toJson() {
        return {
            'name': name,
            'imageUrl': imageUrl,
        };
    }

    // Optional: Factory constructor from JSON (might not be used for a request DTO)
     factory UpdateCategoryRequestDTO.fromJson(Map<String, dynamic> json) {
        return UpdateCategoryRequestDTO(
            name: json['name'] as String,
            imageUrl: json['imageUrl'] as String,
        );
     }

    @override
    String toString() {
      return 'UpdateCategoryRequestDTO(name: $name, imageUrl: $imageUrl)';
    }
}
