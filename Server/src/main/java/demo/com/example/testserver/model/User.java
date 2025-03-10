package demo.com.example.testserver.model;

import jakarta.persistence.*;
import java.util.Date;

@Entity
@Table(name = "users")  
public class User {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;
    
    @Column(unique = true)
    private String email;
    
    @Column(name = "full_name", columnDefinition = "NVARCHAR(255)")
    private String fullName;
    
    @Column(name = "password")
    private String password;
    
    @Column(name = "address", columnDefinition = "NVARCHAR(255)")
    private String address;
    
    @Column(name = "role")
    @Enumerated(EnumType.STRING)
    private UserRole role = UserRole.customer;
    
    @Column(name = "created_date")
    @Temporal(TemporalType.TIMESTAMP)
    private Date createdDate;
    
    @Column(name = "status")
    private Boolean status = true;
    
    @Column(name = "customer_points")
    private Integer customerPoints = 0;
    
    private String avatar;
    
    @Column(name = "chat_id")
    private int chatId;

    // Enum for role
    public enum UserRole {
        customer, admin
    }

    // Constructors
    public User() {}

    // Getters and Setters
    public int getId() {
        return id;
    }

    public void setId(int id) {
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

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public UserRole getRole() {
        return role;
    }

    public void setRole(UserRole role) {
        this.role = role;
    }

    public Date getCreatedDate() {
        return createdDate;
    }

    public void setCreatedDate(Date createdDate) {
        this.createdDate = createdDate;
    }

    public Boolean getStatus() {
        return status;
    }

    public void setStatus(Boolean status) {
        this.status = status;
    }

    public Integer getCustomerPoints() {
        return customerPoints;
    }

    public void setCustomerPoints(Integer customerPoints) {
        this.customerPoints = customerPoints;
    }

    public String getAvatar() {
        return avatar;
    }

    public void setAvatar(String avatar) {
        this.avatar = avatar;
    }

    public int getChatId() {
        return chatId;
    }

    public void setChatId(int idchat) {
        this.chatId = idchat;
    }
}
