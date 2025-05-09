package demo.com.example.testserver.chat.repository;

import demo.com.example.testserver.chat.model.Conversation;
import demo.com.example.testserver.chat.model.Message;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MessageRepository extends JpaRepository<Message, Integer> {
    Page<Message> findByConversationOrderBySendTimeDesc(Conversation conversation, Pageable pageable);
    List<Message> findByConversationIdOrderBySendTimeAsc(Integer conversationId);
    // For fetching the last message efficiently
    Message findTopByConversationOrderBySendTimeDesc(Conversation conversation);
}
