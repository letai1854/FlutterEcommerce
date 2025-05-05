package demo.com.example.testserver.product.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.util.List;

public class UpdateProductRequestDTO {

    @NotBlank(message = "Product name cannot be blank")
    private String name;

    @NotBlank(message = "Product description cannot be blank")
    private String description;

    @NotNull(message = "Category ID cannot be null")
    private Integer categoryId; // Use Integer to match Category ID type

    @NotNull(message = "Brand ID cannot be null")
    private Integer brandId; // Use Integer to match Brand ID type

    private String mainImageUrl; // Optional

    @Size(max = 10, message = "Cannot have more than 10 additional images")
    private List<String> imageUrls; // List for additional images (URLs)

    @PositiveOrZero(message = "Discount percentage must be zero or positive")
    private BigDecimal discountPercentage; // Optional

    @NotEmpty(message = "Product must have at least one variant")
    @Size(min = 1, message = "Product must have at least one variant")
    @Valid // Enable validation for nested DTOs
    private List<UpdateProductVariantDTO> variants;

    // Default Constructor
    public UpdateProductRequestDTO() {}

    // --- Getters ---
    public String getName() { return name; }
    public String getDescription() { return description; }
    public Integer getCategoryId() { return categoryId; }
    public Integer getBrandId() { return brandId; }
    public String getMainImageUrl() { return mainImageUrl; }
    public List<String> getImageUrls() { return imageUrls; }
    public BigDecimal getDiscountPercentage() { return discountPercentage; }
    public List<UpdateProductVariantDTO> getVariants() { return variants; }

    // --- Setters ---
    public void setName(String name) { this.name = name; }
    public void setDescription(String description) { this.description = description; }
    public void setCategoryId(Integer categoryId) { this.categoryId = categoryId; }
    public void setBrandId(Integer brandId) { this.brandId = brandId; }
    public void setMainImageUrl(String mainImageUrl) { this.mainImageUrl = mainImageUrl; }
    public void setImageUrls(List<String> imageUrls) { this.imageUrls = imageUrls; }
    public void setDiscountPercentage(BigDecimal discountPercentage) { this.discountPercentage = discountPercentage; }
    public void setVariants(List<UpdateProductVariantDTO> variants) { this.variants = variants; }
}
