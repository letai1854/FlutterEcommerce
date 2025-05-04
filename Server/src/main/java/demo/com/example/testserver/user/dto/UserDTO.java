package demo.com.example.testserver.user.dto;

import java.math.BigDecimal;
import java.util.Date;
import demo.com.example.testserver.user.model.User; // Import User model

// DTO for User responses - excludes sensitive info like password
public class UserDTO {
    private Integer id;
    private String email;
    private String fullName;
    private String avatar;
    private User.UserRole role;
    private User.UserStatus status;
    private BigDecimal customerPoints;
    private Date createdDate;
    private Date updatedDate;
    // Add other fields as needed, e.g., addresses if you want to include them

    // Constructor to map from User entity
    public UserDTO(User user) {
        this.id = user.getId();
        this.email = user.getEmail();
        this.fullName = user.getFullName();
        this.avatar = user.getAvatar();
        this.role = user.getRole();
        this.status = user.getStatus();
        this.customerPoints = user.getCustomerPoints();
        this.createdDate = user.getCreatedDate();
        this.updatedDate = user.getUpdatedDate();
        // Map other fields if added
    }

    // Default constructor (optional, but good practice)
    public UserDTO() {}

    // Getters (required for JSON serialization)
    public Integer getId() { return id; }
    public String getEmail() { return email; }
    public String getFullName() { return fullName; }
    public String getAvatar() { return avatar; }
    public User.UserRole getRole() { return role; }
    public User.UserStatus getStatus() { return status; }
    public BigDecimal getCustomerPoints() { return customerPoints; }
    public Date getCreatedDate() { return createdDate; }
    public Date getUpdatedDate() { return updatedDate; }

    // Setters (optional, useful for testing or manual creation)
    public void setId(Integer id) { this.id = id; }
    public void setEmail(String email) { this.email = email; }
    public void setFullName(String fullName) { this.fullName = fullName; }
    public void setAvatar(String avatar) { this.avatar = avatar; }
    public void setRole(User.UserRole role) { this.role = role; }
    public void setStatus(User.UserStatus status) { this.status = status; }
    public void setCustomerPoints(BigDecimal customerPoints) { this.customerPoints = customerPoints; }
    public void setCreatedDate(Date createdDate) { this.createdDate = createdDate; }
    public void setUpdatedDate(Date updatedDate) { this.updatedDate = updatedDate; }
}
