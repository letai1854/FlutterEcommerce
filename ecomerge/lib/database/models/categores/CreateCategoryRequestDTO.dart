// lib/database/models/create_category_request_dto.dart

// No special imports needed for basic types

class CreateCategoryRequestDTO {
    // Fields correspond to Java DTO, required based on @NotBlank
    final String name;
    final String imageUrl; // Required based on @NotBlank

    // Constructor
    CreateCategoryRequestDTO({
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

    // Optional: Factory constructor from JSON (might not be used for a request DTO, but good practice)
     factory CreateCategoryRequestDTO.fromJson(Map<String, dynamic> json) {
        return CreateCategoryRequestDTO(
            name: json['name'] as String,
            imageUrl: json['imageUrl'] as String,
        );
     }

     @override
    String toString() {
      return 'CreateCategoryRequestDTO(name: $name, imageUrl: $imageUrl)';
    }
}
