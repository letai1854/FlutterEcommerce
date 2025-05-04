package demo.com.example.testserver.product.dto;

import demo.com.example.testserver.product.model.Product;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.Date;
// Add other necessary imports, e.g., for variant price info if needed

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProductDTO {
    private Integer id;
    private String name;
    private String description;
    private String categoryName; // Flattened from Category entity
    private String brandName;    // Flattened from Brand entity
    private String mainImageUrl;
    private BigDecimal discountPercentage;
    private Date createdDate;
    private Double averageRating; // Calculated field
    private BigDecimal minPrice; // Calculated min price from variants
    private BigDecimal maxPrice; // Calculated max price from variants

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
        this.createdDate = product.getCreatedDate();
        // averageRating, minPrice, maxPrice would typically be calculated and set in the service layer
    }

    // Add setters if needed, especially for calculated fields
    public void setAverageRating(Double averageRating) {
        this.averageRating = averageRating;
    }

    public void setMinPrice(BigDecimal minPrice) {
        this.minPrice = minPrice;
    }

    public void setMaxPrice(BigDecimal maxPrice) {
        this.maxPrice = maxPrice;
    }
}
