package demo.com.example.testserver.user.model;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import demo.com.example.testserver.Chat.model.Conversation;
import demo.com.example.testserver.Chat.model.Message;
import demo.com.example.testserver.cart.model.CartItem; // Assuming CartItem is in this package
import demo.com.example.testserver.order.model.Order; // Assuming Order is in this package
import demo.com.example.testserver.product.model.ProductReview; // Assuming ProductReview is in this package
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.Temporal;
import jakarta.persistence.TemporalType;

@Entity
@Table(name = "nguoi_dung") // Map to the correct table name
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(unique = true, nullable = false)
    private String email;

    @Column(name = "ho_ten", nullable = false) // Map to correct column name
    private String fullName;

    @Column(name = "mat_khau", nullable = false) // Map to correct column name
    private String password;

    @Column(name = "avatar_url") // Map to correct column name
    private String avatar; // Renamed from avatar_url for consistency

    @Column(name = "vai_tro", nullable = false) // Map to correct column name
    @Enumerated(EnumType.STRING)
    private UserRole role = UserRole.khach_hang; // Default value from DB

    @Column(name = "trang_thai", nullable = false) // Map to correct column name
    @Enumerated(EnumType.STRING)
    private UserStatus status = UserStatus.kich_hoat; // Default value from DB

    @Column(name = "diem_khach_hang_than_thiet", nullable = false, precision = 10, scale = 2) // Map to correct column name and type
    private BigDecimal customerPoints = BigDecimal.ZERO; // Use BigDecimal for decimal

    @Column(name = "password_reset_token")
    private String passwordResetToken;

    @Column(name = "password_reset_token_expiry")
    @Temporal(TemporalType.TIMESTAMP)
    private Date passwordResetTokenExpiry;

    @Column(name = "ngay_tao", updatable = false) // Map to correct column name
    @Temporal(TemporalType.TIMESTAMP)
    private Date createdDate;

    @Column(name = "ngay_cap_nhat") // Map to correct column name
    @Temporal(TemporalType.TIMESTAMP)
    private Date updatedDate; // Add updated date field

    // --- Relationships ---

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Address> addresses = new ArrayList<>(); // Initialize the list

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<CartItem> cartItems = new ArrayList<>(); // Initialize the list

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL)
    private List<Order> orders;

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL)
    private List<ProductReview> reviews;

    @OneToMany(mappedBy = "customer", cascade = CascadeType.ALL)
    private List<Conversation> customerConversations;

    @OneToMany(mappedBy = "admin", cascade = CascadeType.ALL)
    private List<Conversation> adminConversations;

    @OneToMany(mappedBy = "sender", cascade = CascadeType.ALL)
    private List<Message> sentMessages;

    // --- Enums ---

    public enum UserRole {
        khach_hang, quan_tri
    }

    public enum UserStatus {
        kich_hoat, khoa
    }

    // --- Lifecycle Callbacks ---
    @PrePersist
    protected void onCreate() {
        createdDate = new Date();
        updatedDate = new Date(); // Set updatedDate on creation as well
    }

    @PreUpdate
    protected void onUpdate() {
        updatedDate = new Date();
    }

    // --- Constructors ---
    public User() {}

    // --- Getters and Setters ---
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getAvatar() {
        return avatar;
    }

    public void setAvatar(String avatar) {
        this.avatar = avatar;
    }

    public UserRole getRole() {
        return role;
    }

    public void setRole(UserRole role) {
        this.role = role;
    }

    public UserStatus getStatus() {
        return status;
    }

    public void setStatus(UserStatus status) {
        this.status = status;
    }

    public BigDecimal getCustomerPoints() {
        return customerPoints;
    }

    public void setCustomerPoints(BigDecimal customerPoints) {
        this.customerPoints = customerPoints;
    }

    public String getPasswordResetToken() {
        return passwordResetToken;
    }

    public void setPasswordResetToken(String passwordResetToken) {
        this.passwordResetToken = passwordResetToken;
    }

    public Date getPasswordResetTokenExpiry() {
        return passwordResetTokenExpiry;
    }

    public void setPasswordResetTokenExpiry(Date passwordResetTokenExpiry) {
        this.passwordResetTokenExpiry = passwordResetTokenExpiry;
    }

    public Date getCreatedDate() {
        return createdDate;
    }

    public void setCreatedDate(Date createdDate) {
        this.createdDate = createdDate;
    }

    public Date getUpdatedDate() {
        return updatedDate;
    }

    public void setUpdatedDate(Date updatedDate) {
        this.updatedDate = updatedDate;
    }

    public List<Address> getAddresses() {
        return addresses;
    }

    public void setAddresses(List<Address> addresses) {
        this.addresses = addresses;
    }

    public void addAddress(Address address) { // Convenience method to add address
        addresses.add(address);
        address.setUser(this);
    }

    public void removeAddress(Address address) { // Convenience method to remove address
        addresses.remove(address);
        address.setUser(null);
    }

    public List<CartItem> getCartItems() {
        return cartItems;
    }

    public void setCartItems(List<CartItem> cartItems) {
        this.cartItems = cartItems;
    }

    public List<Order> getOrders() {
        return orders;
    }

    public void setOrders(List<Order> orders) {
        this.orders = orders;
    }

    public List<ProductReview> getReviews() {
        return reviews;
    }

    public void setReviews(List<ProductReview> reviews) {
        this.reviews = reviews;
    }

    public List<Conversation> getCustomerConversations() {
        return customerConversations;
    }

    public void setCustomerConversations(List<Conversation> customerConversations) {
        this.customerConversations = customerConversations;
    }

    public List<Conversation> getAdminConversations() {
        return adminConversations;
    }

    public void setAdminConversations(List<Conversation> adminConversations) {
        this.adminConversations = adminConversations;
    }

    public List<Message> getSentMessages() {
        return sentMessages;
    }

    public void setSentMessages(List<Message> sentMessages) {
        this.sentMessages = sentMessages;
    }
}
