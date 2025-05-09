package demo.com.example.testserver.chat.repository;

import demo.com.example.testserver.chat.model.Conversation;
import demo.com.example.testserver.user.model.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ConversationRepository extends JpaRepository<Conversation, Integer> {

    Page<Conversation> findByCustomerOrderByUpdatedDateDesc(User customer, Pageable pageable);

    Optional<Conversation> findByIdAndCustomer(Integer id, User customer);

    Page<Conversation> findByStatusOrderByUpdatedDateDesc(Conversation.ConversationStatus status, Pageable pageable);
}
