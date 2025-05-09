package demo.com.example.testserver.chat.dto;

import java.util.Date;

public class MessageDTO {
    private Integer id;
    private Integer conversationId;
    private Integer senderId;
    private String senderEmail;
    private String senderFullName;
    private String content;
    private String imageUrl;
    private Date sendTime;

    public MessageDTO() {
    }

    public MessageDTO(Integer id, Integer conversationId, Integer senderId, String senderEmail, String senderFullName, String content, String imageUrl, Date sendTime) {
        this.id = id;
        this.conversationId = conversationId;
        this.senderId = senderId;
        this.senderEmail = senderEmail;
        this.senderFullName = senderFullName;
        this.content = content;
        this.imageUrl = imageUrl;
        this.sendTime = sendTime;
    }

    // Getters and Setters
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Integer getConversationId() {
        return conversationId;
    }

    public void setConversationId(Integer conversationId) {
        this.conversationId = conversationId;
    }

    public Integer getSenderId() {
        return senderId;
    }

    public void setSenderId(Integer senderId) {
        this.senderId = senderId;
    }

    public String getSenderEmail() {
        return senderEmail;
    }

    public void setSenderEmail(String senderEmail) {
        this.senderEmail = senderEmail;
    }

    public String getSenderFullName() {
        return senderFullName;
    }

    public void setSenderFullName(String senderFullName) {
        this.senderFullName = senderFullName;
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
