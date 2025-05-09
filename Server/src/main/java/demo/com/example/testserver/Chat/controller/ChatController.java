package demo.com.example.testserver.chat.controller;

import demo.com.example.testserver.chat.model.Conversation;
import demo.com.example.testserver.chat.dto.ConversationDTO;
import demo.com.example.testserver.chat.dto.CreateConversationRequestDTO;
import demo.com.example.testserver.chat.dto.MessageDTO;
import demo.com.example.testserver.chat.dto.SendMessageRequestDTO;
import demo.com.example.testserver.chat.service.ChatService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/chat")
@CrossOrigin(origins = "*")
public class ChatController {

    private static final Logger logger = LoggerFactory.getLogger(ChatController.class);

    @Autowired
    private ChatService chatService;

    // Endpoint for a customer to start a new conversation
    @PostMapping("/conversations/start")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ConversationDTO> startConversation(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody CreateConversationRequestDTO requestDTO) {
        logger.info("User {} attempting to start a new conversation with title: {}", userDetails.getUsername(), requestDTO.getTitle());
        ConversationDTO conversation = chatService.startConversation(userDetails.getUsername(), requestDTO);
        return new ResponseEntity<>(conversation, HttpStatus.CREATED);
    }

    // Endpoint for a user (customer or admin) to get their conversations
    @GetMapping("/conversations/me")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Page<ConversationDTO>> getUserConversations(
            @AuthenticationPrincipal UserDetails userDetails,
            @PageableDefault(size = 15, sort = "updatedDate", direction = Sort.Direction.DESC) Pageable pageable) {
        logger.info("User {} fetching their conversations, page: {}", userDetails.getUsername(), pageable.getPageNumber());
        Page<ConversationDTO> conversations = chatService.getUserConversations(userDetails.getUsername(), pageable);
        return ResponseEntity.ok(conversations);
    }
    
    // Endpoint for an admin to get conversations (all, by status)
    @GetMapping("/conversations/admin")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Page<ConversationDTO>> getAdminConversations(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam(required = false) Conversation.ConversationStatus status,
            @PageableDefault(size = 15, sort = "updatedDate", direction = Sort.Direction.DESC) Pageable pageable) {
        logger.info("Admin {} fetching conversations. Status: {}, Page: {}", 
                    userDetails.getUsername(), status, pageable.getPageNumber());
        Page<ConversationDTO> conversations = chatService.getAdminConversations(userDetails.getUsername(), status, pageable);
        return ResponseEntity.ok(conversations);
    }

    // Endpoint to send a message to a conversation
    @PostMapping("/messages/send")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<MessageDTO> sendMessage(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody SendMessageRequestDTO requestDTO) {
        logger.info("User {} sending message to conversation ID {}", userDetails.getUsername(), requestDTO.getConversationId());
        MessageDTO message = chatService.sendMessage(userDetails.getUsername(), requestDTO);
        return ResponseEntity.ok(message);
    }

    // Endpoint to get messages for a specific conversation
    @GetMapping("/conversations/{conversationId}/messages")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Page<MessageDTO>> getConversationMessages(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Integer conversationId,
            @PageableDefault(size = 20, sort = "sendTime", direction = Sort.Direction.DESC) Pageable pageable) {
        logger.info("User {} fetching messages for conversation ID {}, page: {}", userDetails.getUsername(), conversationId, pageable.getPageNumber());
        Page<MessageDTO> messages = chatService.getMessagesForConversation(userDetails.getUsername(), conversationId, pageable);
        return ResponseEntity.ok(messages);
    }
    
    // Endpoint for an admin to update conversation status
    @PatchMapping("/conversations/{conversationId}/status")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ConversationDTO> updateConversationStatus(
            @AuthenticationPrincipal UserDetails adminUserDetails,
            @PathVariable Integer conversationId,
            @RequestParam Conversation.ConversationStatus newStatus) {
        logger.info("Admin {} updating status of conversation ID {} to {}", adminUserDetails.getUsername(), conversationId, newStatus);
        ConversationDTO updatedConversation = chatService.updateConversationStatus(conversationId, newStatus, adminUserDetails.getUsername());
        return ResponseEntity.ok(updatedConversation);
    }
}
