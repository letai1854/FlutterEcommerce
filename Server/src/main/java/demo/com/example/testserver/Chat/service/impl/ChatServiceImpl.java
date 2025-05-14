package demo.com.example.testserver.chat.service.impl;

import demo.com.example.testserver.chat.model.Conversation;
import demo.com.example.testserver.chat.model.Message;
import demo.com.example.testserver.chat.dto.ConversationDTO;
import demo.com.example.testserver.chat.dto.CreateConversationRequestDTO;
import demo.com.example.testserver.chat.dto.MessageDTO;
import demo.com.example.testserver.chat.dto.SendMessageRequestDTO;
import demo.com.example.testserver.chat.repository.ConversationRepository;
import demo.com.example.testserver.chat.repository.MessageRepository;
import demo.com.example.testserver.chat.service.ChatService;
import demo.com.example.testserver.user.model.User;
import demo.com.example.testserver.user.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.ArrayList;
import java.util.Date;
import java.util.Optional;

@Service
public class ChatServiceImpl implements ChatService {

    private static final Logger logger = LoggerFactory.getLogger(ChatServiceImpl.class);

    @Autowired
    private ConversationRepository conversationRepository;

    @Autowired
    private MessageRepository messageRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @Override
    @Transactional
    public ConversationDTO startConversation(String customerEmail, CreateConversationRequestDTO requestDTO) {
        User customer = userRepository.findByEmail(customerEmail)
                .orElseThrow(() -> new EntityNotFoundException("Customer not found with email: " + customerEmail));

        Conversation conversation = new Conversation();
        conversation.setCustomer(customer);
        conversation.setTitle(requestDTO.getTitle());
        conversation.setStatus(Conversation.ConversationStatus.moi);

        Conversation savedConversation = conversationRepository.save(conversation);
        logger.info("Started new conversation ID {} for customer {}", savedConversation.getId(), customerEmail);

        if (StringUtils.hasText(requestDTO.getMessageContent()) || StringUtils.hasText(requestDTO.getMessageImageUrl())) {
            Message initialMessage = new Message();
            initialMessage.setConversation(savedConversation);
            initialMessage.setSender(customer);
            initialMessage.setContent(requestDTO.getMessageContent());
            initialMessage.setImageUrl(requestDTO.getMessageImageUrl());
            messageRepository.save(initialMessage);
            if (savedConversation.getMessages() == null) {
                savedConversation.setMessages(new ArrayList<>());
            }
            savedConversation.getMessages().add(initialMessage);
            savedConversation.setUpdatedDate(new Date());
            conversationRepository.save(savedConversation);
        }

        ConversationDTO conversationDTO = convertToConversationDTO(savedConversation);

        // Notify admin clients about the new conversation
        messagingTemplate.convertAndSend("/topic/admin/conversations/new", conversationDTO);
        logger.info("Broadcasted new conversation ID {} to /topic/admin/conversations/new", conversationDTO.getId());

        return conversationDTO;
    }

    @Override
    @Transactional
    public MessageDTO sendMessage(String senderEmail, SendMessageRequestDTO requestDTO) {
        User sender = userRepository.findByEmail(senderEmail)
                .orElseThrow(() -> new EntityNotFoundException("Sender not found with email: " + senderEmail));

        Conversation conversation = conversationRepository.findById(requestDTO.getConversationId())
                .orElseThrow(() -> new EntityNotFoundException("Conversation not found with ID: " + requestDTO.getConversationId()));

        boolean isCustomer = conversation.getCustomer().equals(sender);
        boolean isAdmin = sender.getRole() == User.UserRole.quan_tri;
        if (!isCustomer && !isAdmin) {
            throw new AccessDeniedException("User not authorized to send message to this conversation.");
        }

        if (!StringUtils.hasText(requestDTO.getContent()) && !StringUtils.hasText(requestDTO.getImageUrl())) {
            throw new IllegalArgumentException("Message content or image URL must be provided.");
        }

        Message message = new Message();
        message.setConversation(conversation);
        message.setSender(sender);
        message.setContent(requestDTO.getContent());
        message.setImageUrl(requestDTO.getImageUrl());

        Message savedMessage = messageRepository.save(message);

        conversation.setUpdatedDate(new Date());
        conversationRepository.save(conversation);

        logger.info("Message ID {} sent by {} to conversation ID {}", savedMessage.getId(), senderEmail, conversation.getId());
        return convertToMessageDTO(savedMessage);
    }
    
    @Override
    @Transactional(readOnly = true)
    public ConversationDTO getUserConversations(String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new EntityNotFoundException("User not found with email: " + userEmail));
        if (user.getRole() == User.UserRole.quan_tri) {
            logger.warn("Admin {} attempting to use getUserConversations. This method is for customers.", userEmail);
            // Admins should use getAdminConversations or getConversationDetails
            return null; 
        }
        Optional<Conversation> conversationOptional = conversationRepository.findTopByCustomerOrderByUpdatedDateDesc(user);
        return conversationOptional.map(this::convertToConversationDTO).orElse(null);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<ConversationDTO> getAdminConversations(String adminEmail, Conversation.ConversationStatus status, Pageable pageable) {
        User admin = userRepository.findByEmail(adminEmail)
                .orElseThrow(() -> new EntityNotFoundException("Admin not found with email: " + adminEmail));
        if (admin.getRole() != User.UserRole.quan_tri) {
            throw new AccessDeniedException("User is not an admin.");
        }
        Page<Conversation> conversations;
        if (status != null) {
            conversations = conversationRepository.findByStatusOrderByUpdatedDateDesc(status, pageable);
        } else {
            conversations = conversationRepository.findAll(pageable);
        }
        return conversations.map(this::convertToConversationDTO);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<MessageDTO> getMessagesForConversation(String userEmail, Integer conversationId, Pageable pageable) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new EntityNotFoundException("User not found with email: " + userEmail));
        Conversation conversation = conversationRepository.findById(conversationId)
                .orElseThrow(() -> new EntityNotFoundException("Conversation not found with ID: " + conversationId));

        boolean isCustomer = conversation.getCustomer().equals(user);
        boolean isAdmin = user.getRole() == User.UserRole.quan_tri;
        if (!isCustomer && !isAdmin) {
            throw new AccessDeniedException("User not authorized to view this conversation.");
        }

        Page<Message> messages = messageRepository.findByConversationOrderBySendTimeDesc(conversation, pageable);
        return messages.map(this::convertToMessageDTO);
    }

    @Override
    @Transactional(readOnly = true)
    public ConversationDTO getConversationDetails(String userEmail, Integer conversationId) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new EntityNotFoundException("User not found with email: " + userEmail));

        Conversation conversation;
        if (user.getRole() == User.UserRole.quan_tri) {
            conversation = conversationRepository.findById(conversationId)
                    .orElseThrow(() -> new EntityNotFoundException("Conversation not found with ID: " + conversationId));
        } else {
            conversation = conversationRepository.findByIdAndCustomer(conversationId, user)
                    .orElseThrow(() -> new EntityNotFoundException("Conversation not found with ID: " + conversationId + " for user " + userEmail));
        }
        return convertToConversationDTO(conversation);
    }

    @Override
    @Transactional
    public ConversationDTO updateConversationStatus(Integer conversationId, Conversation.ConversationStatus newStatus, String adminEmail) {
        User admin = userRepository.findByEmail(adminEmail)
                .orElseThrow(() -> new EntityNotFoundException("Admin not found: " + adminEmail));

        Conversation conversation = conversationRepository.findById(conversationId)
                .orElseThrow(() -> new EntityNotFoundException("Conversation not found: " + conversationId));

        if (admin.getRole() != User.UserRole.quan_tri) {
            throw new AccessDeniedException("User " + adminEmail + " is not authorized to update conversation status.");
        }

        conversation.setStatus(newStatus);
        conversation.setUpdatedDate(new Date());
        Conversation updatedConversation = conversationRepository.save(conversation);
        logger.info("Conversation ID {} status updated to {} by admin {}", conversationId, newStatus, adminEmail);
        return convertToConversationDTO(updatedConversation);
    }

    @Override
    public MessageDTO convertToMessageDTO(Message message) {
        if (message == null) return null;
        User sender = message.getSender();
        Integer finalSenderId = sender.getId();

        if (sender.getRole() == User.UserRole.quan_tri && finalSenderId == null) {
            finalSenderId = 1; // Default admin ID if sender is admin and ID is null
        }

        return new MessageDTO(
                message.getId(),
                message.getConversation().getId(),
                finalSenderId, // Use the potentially defaulted ID
                sender.getEmail(),
                sender.getFullName(),
                message.getContent(),
                message.getImageUrl(),
                message.getSendTime()
        );
    }

    @Override
    public ConversationDTO convertToConversationDTO(Conversation conversation) {
        if (conversation == null) return null;
        ConversationDTO dto = new ConversationDTO();
        dto.setId(conversation.getId());
        if (conversation.getCustomer() != null) {
            dto.setCustomerId(conversation.getCustomer().getId());
            dto.setCustomerEmail(conversation.getCustomer().getEmail());
            dto.setCustomerFullName(conversation.getCustomer().getFullName());
        }
        dto.setTitle(conversation.getTitle());
        dto.setStatus(conversation.getStatus());
        dto.setCreatedDate(conversation.getCreatedDate());
        dto.setUpdatedDate(conversation.getUpdatedDate());

        Message lastMessage = messageRepository.findTopByConversationOrderBySendTimeDesc(conversation);
        if (lastMessage != null) {
            dto.setLastMessage(convertToMessageDTO(lastMessage)); // This will use the updated convertToMessageDTO

            Integer adminId = 1;
            dto.setAdminId(adminId);
            dto.setAdminEmail(null);
            dto.setAdminFullName("Admin");
        }
        // TODO: Implement actual unread messages count logic if needed
        dto.setUnreadMessagesCount(0); 
        return dto;
    }
}
