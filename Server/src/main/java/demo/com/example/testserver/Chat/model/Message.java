package demo.com.example.testserver.Chat.model;

import jakarta.persistence.*;
import java.util.Date;

import demo.com.example.testserver.user.model.User;

@Entity
@Table(name = "tin_nhan") // Map to correct table name
public class Message {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "cuoc_hoi_thoai_id", nullable = false) // Map to correct column name
    private Conversation conversation;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "nguoi_gui_id", nullable = false) // Map to correct column name
    private User sender; // Changed from senderId to User object

    @Column(name = "noi_dung", columnDefinition = "TEXT") // Map to correct column name and type
    private String content;

    @Column(name = "url_hinh_anh") // Map to correct column name
    private String imageUrl; // Add image URL field

    @Column(name = "thoi_gian_gui") // Map to correct column name
    @Temporal(TemporalType.TIMESTAMP)
    private Date sendTime;

    // --- Lifecycle Callbacks ---
    @PrePersist
    protected void onCreate() {
        sendTime = new Date();
    }

    // --- Constructors ---
    public Message() {}

    // --- Getters and Setters ---
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Conversation getConversation() {
        return conversation;
    }

    public void setConversation(Conversation conversation) {
        this.conversation = conversation;
    }

    public User getSender() {
        return sender;
    }

    public void setSender(User sender) {
        this.sender = sender;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public Date getSendTime() {
        return sendTime;
    }

    public void setSendTime(Date sendTime) {
        this.sendTime = sendTime;
    }
}
