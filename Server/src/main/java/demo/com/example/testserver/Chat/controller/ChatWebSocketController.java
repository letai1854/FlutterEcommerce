package demo.com.example.testserver.chat.controller;

import demo.com.example.testserver.chat.dto.MessageDTO;
import demo.com.example.testserver.chat.dto.SendMessageRequestDTO;
import demo.com.example.testserver.chat.service.ChatService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

import java.security.Principal;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

@Controller
public class ChatWebSocketController {

    private static final Logger logger = LoggerFactory.getLogger(ChatWebSocketController.class);

    @Autowired
    private ChatService chatService;

    @Autowired
    private SimpMessagingTemplate messagingTemplate; // For sending messages to specific users or topics

    @MessageMapping("/chat.sendMessage/{conversationId}")
    // No @SendTo here, we will manually send to ensure it's processed by service first
    public void sendMessage(@DestinationVariable Integer conversationId,
                            @Payload SendMessageRequestDTO messageRequestDTO,
                            Principal principal, // Spring Security Principal
                            SimpMessageHeaderAccessor headerAccessor) {
        if (principal == null) {
            logger.warn("Attempt to send message without authentication to conversation {}", conversationId);
            // Send an error message back to the sender
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Authentication required");
            errorResponse.put("timestamp", new Date());
            messagingTemplate.convertAndSend("/topic/errors", errorResponse);
            return;
        }
        String senderEmail = principal.getName();
        logger.info("WebSocket: User {} sending message to conversation ID {}: Content='{}', ImageURL='{}'",
                senderEmail, conversationId, messageRequestDTO.getContent(), messageRequestDTO.getImageUrl());

        // Ensure the DTO has the correct conversationId from the path
        messageRequestDTO.setConversationId(conversationId);

        try {
            MessageDTO savedMessageDTO = chatService.sendMessage(senderEmail, messageRequestDTO);
            
            // Broadcast the saved message to all subscribers of this conversation topic
            String destination = "/topic/conversation/" + conversationId;
            messagingTemplate.convertAndSend(destination, savedMessageDTO);
            logger.info("Message broadcasted to {}", destination);

            // Potentially send notifications to involved users (customer/admin) if they are not on this topic
            // e.g., if admin is not actively viewing this chat, send a general new message notification
            // This requires more complex logic for user presence and notification channels.

        } catch (Exception e) {
            logger.error("Error processing WebSocket message for conversation {}: {}", conversationId, e.getMessage(), e);
            // Send error back to the sender if possible
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to process message: " + e.getMessage());
            errorResponse.put("timestamp", new Date());
            messagingTemplate.convertAndSend("/topic/errors", errorResponse);
        }
    }

    // Example: User joining a conversation (could be used for presence, typing indicators)
    @MessageMapping("/chat.joinConversation/{conversationId}")
    public void joinConversation(@DestinationVariable Integer conversationId,
                                 Principal principal,
                                 SimpMessageHeaderAccessor headerAccessor) {
        if (principal == null) {
            logger.warn("Unauthenticated user tried to join conversation {}", conversationId);
            // Send an error message back
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Authentication required to join conversation");
            errorResponse.put("timestamp", new Date());
            messagingTemplate.convertAndSend("/topic/errors", errorResponse);
            return;
        }
        String username = principal.getName();
        logger.info("User {} joined conversation topic: /topic/conversation/{}", username, conversationId);
        
        // Send a system message to notify others that user has joined
        Map<String, Object> joinNotification = new HashMap<>();
        joinNotification.put("type", "JOIN");
        joinNotification.put("user", username);
        joinNotification.put("timestamp", new Date());
        messagingTemplate.convertAndSend("/topic/conversation/" + conversationId, joinNotification);
    }
}
