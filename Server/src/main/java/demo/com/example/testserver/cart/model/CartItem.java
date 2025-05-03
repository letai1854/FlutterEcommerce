package demo.com.example.testserver.cart.model;

import jakarta.persistence.*;
import java.util.Date;

import demo.com.example.testserver.product.model.ProductVariant;
import demo.com.example.testserver.user.model.User;

@Entity
@Table(name = "gio_hang", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"nguoi_dung_id", "bien_the_san_pham_id"}, name = "unique_user_cart_item"),
    @UniqueConstraint(columnNames = {"session_id", "bien_the_san_pham_id"}, name = "unique_session_cart_item")
})
public class CartItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "nguoi_dung_id") // Nullable for guest users
    private User user;

    @Column(name = "session_id") // For guest users
    private String sessionId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "bien_the_san_pham_id", nullable = false)
    private ProductVariant productVariant;

    @Column(name = "so_luong", nullable = false)
    private Integer quantity = 1;

    @Column(name = "ngay_them_vao", updatable = false)
    @Temporal(TemporalType.TIMESTAMP)
    private Date addedDate;

    @Column(name = "ngay_cap_nhat")
    @Temporal(TemporalType.TIMESTAMP)
    private Date updatedDate;

    // Lifecycle Callbacks
    @PrePersist
    protected void onCreate() {
        addedDate = new Date();
        updatedDate = new Date();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedDate = new Date();
    }

    // Constructors
    public CartItem() {}

    // Getters and Setters
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public String getSessionId() {
        return sessionId;
    }

    public void setSessionId(String sessionId) {
        this.sessionId = sessionId;
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
