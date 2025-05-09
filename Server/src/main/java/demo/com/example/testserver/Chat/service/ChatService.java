package demo.com.example.testserver.chat.service;

import demo.com.example.testserver.chat.model.Conversation;
import demo.com.example.testserver.chat.dto.ConversationDTO;
import demo.com.example.testserver.chat.dto.CreateConversationRequestDTO;
import demo.com.example.testserver.chat.dto.MessageDTO;
import demo.com.example.testserver.chat.dto.SendMessageRequestDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface ChatService {

    ConversationDTO startConversation(String customerEmail, CreateConversationRequestDTO requestDTO);

    MessageDTO sendMessage(String senderEmail, SendMessageRequestDTO requestDTO);

    Page<ConversationDTO> getUserConversations(String userEmail, Pageable pageable);

    Page<ConversationDTO> getAdminConversations(String adminEmail, Conversation.ConversationStatus status, Pageable pageable);

    Page<MessageDTO> getMessagesForConversation(String userEmail, Integer conversationId, Pageable pageable);

    ConversationDTO getConversationDetails(String userEmail, Integer conversationId);

    ConversationDTO updateConversationStatus(Integer conversationId, Conversation.ConversationStatus newStatus, String adminEmail);
    
    MessageDTO convertToMessageDTO(demo.com.example.testserver.chat.model.Message message);
    
    ConversationDTO convertToConversationDTO(Conversation conversation);
}
