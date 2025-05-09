package demo.com.example.testserver.cart.repository;

import demo.com.example.testserver.cart.model.CartItem;
import demo.com.example.testserver.product.model.ProductVariant;
import demo.com.example.testserver.user.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CartItemRepository extends JpaRepository<CartItem, Integer> {
    List<CartItem> findByUser(User user);
    Optional<CartItem> findByUserAndProductVariant(User user, ProductVariant productVariant);
    Optional<CartItem> findByIdAndUser(Integer cartItemId, User user);
}
