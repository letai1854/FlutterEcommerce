package demo.com.example.testserver.chat.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public class SendMessageRequestDTO {

    @NotNull(message = "Conversation ID cannot be null")
    private Integer conversationId;

    @Size(max = 2000, message = "Content cannot exceed 2000 characters")
    private String content;

    private String imageUrl;

    // Getters and Setters
    public Integer getConversationId() {
        return conversationId;
    }

    public void setConversationId(Integer conversationId) {
        this.conversationId = conversationId;
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
}
