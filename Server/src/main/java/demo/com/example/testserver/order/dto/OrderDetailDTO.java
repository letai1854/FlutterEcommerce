package demo.com.example.testserver.order.dto;

import java.math.BigDecimal;

public class OrderDetailDTO {
    private Integer productVariantId;
    private String productName;
    private String variantName;
    private String imageUrl; // Main image of the product
    private Integer quantity;
    private BigDecimal priceAtPurchase;
    private BigDecimal productDiscountPercentage;
    private BigDecimal lineTotal;

    // Constructors, Getters, and Setters
    public OrderDetailDTO() {}

    public OrderDetailDTO(Integer productVariantId, String productName, String variantName, String imageUrl, Integer quantity, BigDecimal priceAtPurchase, BigDecimal productDiscountPercentage, BigDecimal lineTotal) {
        this.productVariantId = productVariantId;
        this.productName = productName;
        this.variantName = variantName;
        this.imageUrl = imageUrl;
        this.quantity = quantity;
        this.priceAtPurchase = priceAtPurchase;
        this.productDiscountPercentage = productDiscountPercentage;
        this.lineTotal = lineTotal;
    }

    public Integer getProductVariantId() {
        return productVariantId;
    }

    public void setProductVariantId(Integer productVariantId) {
        this.productVariantId = productVariantId;
    }

    public String getProductName() {
        return productName;
    }

    public void setProductName(String productName) {
        this.productName = productName;
    }

    public String getVariantName() {
        return variantName;
    }

    public void setVariantName(String variantName) {
        this.variantName = variantName;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public Integer getQuantity() {
        return quantity;
    }

    public void setQuantity(Integer quantity) {
        this.quantity = quantity;
    }

    public BigDecimal getPriceAtPurchase() {
        return priceAtPurchase;
    }

    public void setPriceAtPurchase(BigDecimal priceAtPurchase) {
        this.priceAtPurchase = priceAtPurchase;
    }

    public BigDecimal getProductDiscountPercentage() {
        return productDiscountPercentage;
    }

    public void setProductDiscountPercentage(BigDecimal productDiscountPercentage) {
        this.productDiscountPercentage = productDiscountPercentage;
    }

    public BigDecimal getLineTotal() {
        return lineTotal;
    }

    public void setLineTotal(BigDecimal lineTotal) {
        this.lineTotal = lineTotal;
    }
}
