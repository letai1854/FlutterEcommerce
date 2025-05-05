package demo.com.example.testserver.product.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List; // Import List
import java.util.stream.Collectors; // Import Collectors

import demo.com.example.testserver.product.model.Product;
import demo.com.example.testserver.product.model.ProductVariant; // Import ProductVariant

public class ProductDTO {
    private Long id; // Changed from Integer to Long
    private String name;
    private String description;
    private String categoryName; // Flattened from Category entity
    private String brandName;    // Flattened from Brand entity
    private String mainImageUrl;
    private BigDecimal discountPercentage;
    private LocalDateTime createdDate; // Changed from Date to LocalDateTime
    private LocalDateTime updatedDate; // Added field
    private Double averageRating; // Calculated field
    private BigDecimal minPrice; // Calculated min price from variants
    private BigDecimal maxPrice; // Calculated max price from variants
    private Integer variantCount; // Added: Number of variants
    private List<ProductVariantDTO> variants; // Added: List of variants

    // Explicit No-Argument Constructor
    public ProductDTO() {}

    // Constructor to map from Product entity (basic example)
    // You might need a more sophisticated mapping logic, potentially in the service layer
    public ProductDTO(Product product) {
        this.id = product.getId();
        this.name = product.getName();
        this.description = product.getDescription();
        this.categoryName = product.getCategory() != null ? product.getCategory().getName() : null;
        this.brandName = product.getBrand() != null ? product.getBrand().getName() : null;
        this.mainImageUrl = product.getMainImageUrl();
        this.discountPercentage = product.getDiscountPercentage();
        this.createdDate = product.getCreatedDate() != null ?
                new java.sql.Timestamp(product.getCreatedDate().getTime()).toLocalDateTime() : null;
        this.updatedDate = product.getUpdatedDate() != null ?
                new java.sql.Timestamp(product.getUpdatedDate().getTime()).toLocalDateTime() : null;
        // Note: Denormalized fields (averageRating, minPrice, maxPrice) are set in the Mapper
        this.variantCount = product.getVariants() != null ? product.getVariants().size() : 0; // Calculate variant count
        // Map variants to DTOs if needed for detail view
        if (product.getVariants() != null) {
            this.variants = product.getVariants().stream()
                                  .map(ProductVariantDTO::new) // Assuming ProductVariantDTO has a constructor accepting ProductVariant
                                  .collect(Collectors.toList());
        }
    }

    // All-Args Constructor (manually added to replace Lombok's @AllArgsConstructor)
    public ProductDTO(Long id, String name, String description, String categoryName, String brandName, String mainImageUrl, BigDecimal discountPercentage, LocalDateTime createdDate, LocalDateTime updatedDate, Double averageRating, BigDecimal minPrice, BigDecimal maxPrice, Integer variantCount, List<ProductVariantDTO> variants) {
        this.id = id;
        this.name = name;
        this.description = description;
        this.categoryName = categoryName;
        this.brandName = brandName;
        this.mainImageUrl = mainImageUrl;
        this.discountPercentage = discountPercentage;
        this.createdDate = createdDate;
        this.updatedDate = updatedDate;
        this.averageRating = averageRating;
        this.minPrice = minPrice;
        this.maxPrice = maxPrice;
        this.variantCount = variantCount; // Set variantCount
        this.variants = variants; // Set variants
    }

    // --- Getters ---
    public Long getId() { return id; }
    public String getName() { return name; }
    public String getDescription() { return description; }
    public String getCategoryName() { return categoryName; }
    public String getBrandName() { return brandName; }
    public String getMainImageUrl() { return mainImageUrl; }
    public BigDecimal getDiscountPercentage() { return discountPercentage; }
    public LocalDateTime getCreatedDate() { return createdDate; }
    public LocalDateTime getUpdatedDate() { return updatedDate; }
    public Double getAverageRating() { return averageRating; }
    public BigDecimal getMinPrice() { return minPrice; }
    public BigDecimal getMaxPrice() { return maxPrice; }
    public Integer getVariantCount() { return variantCount; } // Getter for variantCount
    public List<ProductVariantDTO> getVariants() { return variants; } // Getter for variants

    // --- Setters ---
    public void setId(Long id) { this.id = id; }
    public void setName(String name) { this.name = name; }
    public void setDescription(String description) { this.description = description; }
    public void setCategoryName(String categoryName) { this.categoryName = categoryName; }
    public void setBrandName(String brandName) { this.brandName = brandName; }
    public void setMainImageUrl(String mainImageUrl) { this.mainImageUrl = mainImageUrl; }
    public void setDiscountPercentage(BigDecimal discountPercentage) { this.discountPercentage = discountPercentage; }
    public void setCreatedDate(LocalDateTime createdDate) { this.createdDate = createdDate; }
    public void setUpdatedDate(LocalDateTime updatedDate) { this.updatedDate = updatedDate; }
    public void setAverageRating(Double averageRating) { this.averageRating = averageRating; }
    public void setMinPrice(BigDecimal minPrice) { this.minPrice = minPrice; }
    public void setMaxPrice(BigDecimal maxPrice) { this.maxPrice = maxPrice; }
    public void setVariantCount(Integer variantCount) { this.variantCount = variantCount; } // Setter for variantCount
    public void setVariants(List<ProductVariantDTO> variants) { this.variants = variants; } // Setter for variants
}
