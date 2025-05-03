package demo.com.example.testserver.Chat.model;

import jakarta.persistence.*;
import java.util.Date;
import java.util.List;

import demo.com.example.testserver.user.model.User;

@Entity
@Table(name = "cuoc_hoi_thoai") // Map to correct table name
public class Conversation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY) // Relationship to User (customer)
    @JoinColumn(name = "nguoi_dung_id", nullable = false) // Map to correct column name
    private User customer;

    @ManyToOne(fetch = FetchType.LAZY) // Relationship to User (admin)
    @JoinColumn(name = "admin_id") // Map to correct column name
    private User admin;

    @Column(name = "tieu_de") // Map to correct column name
    private String title;

    @Column(name = "trang_thai", nullable = false) // Map to correct column name
    @Enumerated(EnumType.STRING)
    private ConversationStatus status = ConversationStatus.moi; // Default value from DB

    @Column(name = "ngay_tao", updatable = false) // Map to correct column name
    @Temporal(TemporalType.TIMESTAMP)
    private Date createdDate;

    @Column(name = "ngay_cap_nhat") // Map to correct column name
    @Temporal(TemporalType.TIMESTAMP)
    private Date updatedDate; // Add updated date field

    @OneToMany(mappedBy = "conversation", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Message> messages;

    // --- Enum ---
    public enum ConversationStatus {
        moi, dang_xu_ly, da_dong
    }

    // --- Lifecycle Callbacks ---
    @PrePersist
    protected void onCreate() {
        createdDate = new Date();
        updatedDate = new Date();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedDate = new Date();
    }

    // --- Constructors ---
    public Conversation() {}

    // --- Getters and Setters ---
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public User getCustomer() {
        return customer;
    }

    public void setCustomer(User customer) {
        this.customer = customer;
    }

    public User getAdmin() {
        return admin;
    }

    public void setAdmin(User admin) {
        this.admin = admin;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public ConversationStatus getStatus() {
        return status;
    }

    public void setStatus(ConversationStatus status) {
        this.status = status;
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

    public List<Message> getMessages() {
        return messages;
    }

    public void setMessages(List<Message> messages) {
        this.messages = messages;
    }
}
