package demo.com.example.testserver.chat.dto;

import jakarta.validation.constraints.Size;

public class CreateConversationRequestDTO {

    @Size(max = 255, message = "Title cannot exceed 255 characters")
    private String title;

    @Size(max = 2000, message = "Message content cannot exceed 2000 characters")
    private String messageContent; // Initial message

    private String messageImageUrl; // Optional image for the initial message

    // Getters and Setters
    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getMessageContent() {
        return messageContent;
    }

    public void setMessageContent(String messageContent) {
        this.messageContent = messageContent;
    }

    public String getMessageImageUrl() {
        return messageImageUrl;
    }

    public void setMessageImageUrl(String messageImageUrl) {
        this.messageImageUrl = messageImageUrl;
    }
}
