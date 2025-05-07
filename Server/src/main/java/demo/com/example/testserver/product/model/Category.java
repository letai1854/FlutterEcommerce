package demo.com.example.testserver.product.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank; // Import NotBlank
import java.util.Date;
import java.util.List;

@Entity
@Table(name = "danh_muc")
public class Category {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "ten_danh_muc", nullable = false, unique = true)
    @NotBlank(message = "Category name cannot be blank") // Add validation
    private String name;

    @Column(name = "hinh_anh")
    @NotBlank(message = "Category image URL cannot be blank") // Add validation
    private String imageUrl;

    @Column(name = "ngay_tao", updatable = false)
    @Temporal(TemporalType.TIMESTAMP)
    private Date createdDate;

    @Column(name = "ngay_cap_nhat")
    @Temporal(TemporalType.TIMESTAMP)
    private Date updatedDate;

    @OneToMany(mappedBy = "category", fetch = FetchType.LAZY)
    @JsonIgnore // Add this to break the loop: Product -> Category -> List<Product>
    private List<Product> products;

    // Lifecycle Callbacks
    @PrePersist
    protected void onCreate() {
        createdDate = new Date();
        updatedDate = new Date();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedDate = new Date();
    }

    // Constructors
    public Category() {}

    // Getters and Setters
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
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

    public List<Product> getProducts() {
        return products;
    }

    public void setProducts(List<Product> products) {
        this.products = products;
    }
}
