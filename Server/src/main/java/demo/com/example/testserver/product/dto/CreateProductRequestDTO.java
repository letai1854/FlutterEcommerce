package demo.com.example.testserver.product.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
// Removed Lombok imports
import jakarta.validation.Valid; // Import for nested validation
import jakarta.validation.constraints.NotEmpty; // Import for list validation
import jakarta.validation.constraints.Size; // Import for list size validation

import java.math.BigDecimal;
import java.util.List; // Import List

// Removed Lombok annotations
public class CreateProductRequestDTO {

    @NotBlank(message = "Product name cannot be blank")
    private String name;

    @NotBlank(message = "Product description cannot be blank")
    private String description;

    @NotNull(message = "Category ID cannot be null")
    private Long categoryId;

    @NotNull(message = "Brand ID cannot be null")
    private Long brandId;

    private String mainImageUrl; // Optional

    @Size(max = 10, message = "Cannot upload more than 10 additional images")
    private List<String> imageUrls; // List for additional images

    @PositiveOrZero(message = "Discount percentage must be zero or positive")
    private BigDecimal discountPercentage; // Optional, defaults to 0 if null

    @NotEmpty(message = "Product must have at least one variant")
    @Size(min = 1, message = "Product must have at least one variant")
    @Valid // Enable validation for nested DTOs
    private List<CreateProductVariantDTO> variants;

    // Default Constructor
    public CreateProductRequestDTO() {}

    // --- Getters ---
    public String getName() { return name; }
    public String getDescription() { return description; }
    public Long getCategoryId() { return categoryId; }
    public Long getBrandId() { return brandId; }
    public String getMainImageUrl() { return mainImageUrl; }
    public List<String> getImageUrls() { return imageUrls; } // Getter for imageUrls
    public BigDecimal getDiscountPercentage() { return discountPercentage; }
    public List<CreateProductVariantDTO> getVariants() { return variants; } // Getter for variants

    // --- Setters ---
    public void setName(String name) { this.name = name; }
    public void setDescription(String description) { this.description = description; }
    public void setCategoryId(Long categoryId) { this.categoryId = categoryId; }
    public void setBrandId(Long brandId) { this.brandId = brandId; }
    public void setMainImageUrl(String mainImageUrl) { this.mainImageUrl = mainImageUrl; }
    public void setImageUrls(List<String> imageUrls) { this.imageUrls = imageUrls; } // Setter for imageUrls
    public void setDiscountPercentage(BigDecimal discountPercentage) { this.discountPercentage = discountPercentage; }
    public void setVariants(List<CreateProductVariantDTO> variants) { this.variants = variants; } // Setter for variants
}
