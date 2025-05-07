package demo.com.example.testserver.order.repository;

import demo.com.example.testserver.order.model.Order;
import demo.com.example.testserver.user.model.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface OrderRepository extends JpaRepository<Order, Integer> {

    Page<Order> findByUserAndOrderStatus(User user, Order.OrderStatus status, Pageable pageable);

    Page<Order> findByUser(User user, Pageable pageable);

    Optional<Order> findByIdAndUser(Integer orderId, User user);
}
