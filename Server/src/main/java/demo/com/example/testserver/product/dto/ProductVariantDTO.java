package demo.com.example.testserver.product.dto;

import demo.com.example.testserver.product.model.ProductVariant;
import java.math.BigDecimal;

public class ProductVariantDTO {
    private Integer id; // Changed from Long to Integer
    private String name;
    private String sku;
    private BigDecimal price;
    private Integer stockQuantity;
    private String variantImageUrl;

    // No-arg constructor
    public ProductVariantDTO() {}

    // Constructor from Entity
    public ProductVariantDTO(ProductVariant variant) {
        this.id = variant.getId(); // getId() returns Integer
        this.name = variant.getName();
        this.sku = variant.getSku();
        this.price = variant.getPrice();
        this.stockQuantity = variant.getStockQuantity();
        this.variantImageUrl = variant.getVariantImageUrl();
    }

    // Getters and Setters
    public Integer getId() { return id; } // Return type changed to Integer
    public void setId(Integer id) { this.id = id; } // Parameter type changed to Integer
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getSku() { return sku; }
    public void setSku(String sku) { this.sku = sku; }
    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }
    public Integer getStockQuantity() { return stockQuantity; }
    public void setStockQuantity(Integer stockQuantity) { this.stockQuantity = stockQuantity; }
    public String getVariantImageUrl() { return variantImageUrl; }
    public void setVariantImageUrl(String variantImageUrl) { this.variantImageUrl = variantImageUrl; }
}
