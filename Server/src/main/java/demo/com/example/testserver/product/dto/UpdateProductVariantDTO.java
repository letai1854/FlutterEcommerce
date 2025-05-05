package demo.com.example.testserver.product.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;

public class UpdateProductVariantDTO {

    private Integer id; // ID of the variant to update, null for new variants

    @NotBlank(message = "Variant name cannot be blank")
    private String name;

    private String sku; // Optional

    @NotNull(message = "Variant price cannot be null")
    @Positive(message = "Variant price must be positive")
    private BigDecimal price;

    @NotNull(message = "Variant stock quantity cannot be null")
    @PositiveOrZero(message = "Variant stock quantity must be zero or positive")
    private Integer stockQuantity;

    private String variantImageUrl; // Optional

    // Default Constructor
    public UpdateProductVariantDTO() {}

    // --- Getters ---
    public Integer getId() { return id; }
    public String getName() { return name; }
    public String getSku() { return sku; }
    public BigDecimal getPrice() { return price; }
    public Integer getStockQuantity() { return stockQuantity; }
    public String getVariantImageUrl() { return variantImageUrl; }

    // --- Setters ---
    public void setId(Integer id) { this.id = id; }
    public void setName(String name) { this.name = name; }
    public void setSku(String sku) { this.sku = sku; }
    public void setPrice(BigDecimal price) { this.price = price; }
    public void setStockQuantity(Integer stockQuantity) { this.stockQuantity = stockQuantity; }
    public void setVariantImageUrl(String variantImageUrl) { this.variantImageUrl = variantImageUrl; }
}
