package demo.com.example.testserver.cart.dto;

import java.math.BigDecimal;
import java.util.Date;

public class CartItemDTO {
    private Integer cartItemId;
    private CartProductVariantDTO productVariant;
    private Integer quantity;
    private BigDecimal lineTotal; // Calculated: finalPrice * quantity
    private Date addedDate;
    private Date updatedDate;

    // Constructors, Getters, and Setters
    public CartItemDTO() {}

    public CartItemDTO(Integer cartItemId, CartProductVariantDTO productVariant, Integer quantity, BigDecimal lineTotal, Date addedDate, Date updatedDate) {
        this.cartItemId = cartItemId;
        this.productVariant = productVariant;
        this.quantity = quantity;
        this.lineTotal = lineTotal;
        this.addedDate = addedDate;
        this.updatedDate = updatedDate;
    }

    public Integer getCartItemId() {
        return cartItemId;
    }

    public void setCartItemId(Integer cartItemId) {
        this.cartItemId = cartItemId;
    }

    public CartProductVariantDTO getProductVariant() {
        return productVariant;
    }

    public void setProductVariant(CartProductVariantDTO productVariant) {
        this.productVariant = productVariant;
    }

    public Integer getQuantity() {
        return quantity;
    }

    public void setQuantity(Integer quantity) {
        this.quantity = quantity;
    }

    public BigDecimal getLineTotal() {
        return lineTotal;
    }

    public void setLineTotal(BigDecimal lineTotal) {
        this.lineTotal = lineTotal;
    }

    public Date getAddedDate() {
        return addedDate;
    }

    public void setAddedDate(Date addedDate) {
        this.addedDate = addedDate;
    }

    public Date getUpdatedDate() {
        return updatedDate;
    }

    public void setUpdatedDate(Date updatedDate) {
        this.updatedDate = updatedDate;
    }
}
