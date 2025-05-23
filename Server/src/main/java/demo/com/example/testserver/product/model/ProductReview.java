package demo.com.example.testserver.product.model;

import java.util.Date;

import com.fasterxml.jackson.annotation.JsonIgnore; // Import JsonIgnore
import demo.com.example.testserver.user.model.User;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import jakarta.persistence.Temporal;
import jakarta.persistence.TemporalType;

@Entity
@Table(name = "danh_gia_san_pham")
public class ProductReview {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "san_pham_id", nullable = false)
    @JsonIgnore // Add this to break potential cycles
    private Product product;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "nguoi_dung_id") // Nullable for anonymous reviews
    private User user;

    @Column(name = "ten_nguoi_danh_gia_an_danh", length = 100)
    private String reviewerName;

    @Column(name = "diem_sao") // Nullable if only comment
    private Byte rating; // Use Byte for TINYINT (1-5)

    @Column(name = "binh_luan", columnDefinition = "TEXT") // Nullable if only rating
    private String comment;

    @Column(name = "thoi_gian_danh_gia", updatable = false)
    @Temporal(TemporalType.TIMESTAMP)
    private Date reviewTime;

    @Column(name = "nguoi_danh_gia_avatar_url")
    private String reviewerAvatarUrl;

    // Lifecycle Callbacks
    @PrePersist
    protected void onCreate() {
        reviewTime = new Date();
    }

    // Constructors
    public ProductReview() {}

    // Getters and Setters
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Product getProduct() {
        return product;
    }

    public void setProduct(Product product) {
        this.product = product;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public String getReviewerName() {
        return reviewerName;
    }

    public void setReviewerName(String anonymousReviewerName) {
        this.reviewerName = anonymousReviewerName;
    }

    public Byte getRating() {
        return rating;
    }

    public void setRating(Byte rating) {
        this.rating = rating;
    }

    public String getComment() {
        return comment;
    }

    public void setComment(String comment) {
        this.comment = comment;
    }

    public Date getReviewTime() {
        return reviewTime;
    }

    public void setReviewTime(Date reviewTime) {
        this.reviewTime = reviewTime;
    }

    public String getReviewerAvatarUrl() {
        return reviewerAvatarUrl;
    }

    public void setReviewerAvatarUrl(String reviewerAvatarUrl) {
        this.reviewerAvatarUrl = reviewerAvatarUrl;
    }
}
