package demo.com.example.testserver.order.model;

import jakarta.persistence.*;
import java.math.BigDecimal;

import demo.com.example.testserver.product.model.ProductVariant;

@Entity
@Table(name = "chi_tiet_don_hang", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"don_hang_id", "bien_the_san_pham_id"}, name = "unique_order_variant")
})
public class OrderDetail {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "don_hang_id", nullable = false)
    private Order order;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "bien_the_san_pham_id", nullable = false)
    private ProductVariant productVariant;

    @Column(name = "so_luong", nullable = false)
    private Integer quantity;

    @Column(name = "gia_tai_thoi_diem_mua", nullable = false, precision = 12, scale = 2)
    private BigDecimal priceAtPurchase; // Price per unit

    @Column(name = "phan_tram_giam_gia_san_pham", precision = 5, scale = 2)
    private BigDecimal productDiscountPercentage; // Discount % at purchase time

    @Column(name = "thanh_tien", nullable = false, precision = 12, scale = 2)
    private BigDecimal lineTotal; // Total for this line item (price * quantity * (1 - discount/100))

    // Constructors
    public OrderDetail() {}

    // Getters and Setters
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Order getOrder() {
        return order;
    }

    public void setOrder(Order order) {
        this.order = order;
    }

    public ProductVariant getProductVariant() {
        return productVariant;
    }

    public void setProductVariant(ProductVariant productVariant) {
        this.productVariant = productVariant;
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
