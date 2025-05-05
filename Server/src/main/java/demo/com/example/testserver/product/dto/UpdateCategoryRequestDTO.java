package demo.com.example.testserver.product.dto;

import jakarta.validation.constraints.NotBlank;

public class UpdateCategoryRequestDTO {

    @NotBlank(message = "Category name cannot be blank")
    private String name;

    @NotBlank(message = "Category image URL cannot be blank")
    private String imageUrl;

    // Getters and Setters
    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }
}
