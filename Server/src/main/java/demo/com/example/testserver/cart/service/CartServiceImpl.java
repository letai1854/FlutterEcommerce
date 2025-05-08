package demo.com.example.testserver.cart.service;

import demo.com.example.testserver.cart.dto.AddToCartDTO;
import demo.com.example.testserver.cart.dto.CartItemDTO;
import demo.com.example.testserver.cart.dto.UpdateCartItemDTO;
import demo.com.example.testserver.cart.model.CartItem;
import demo.com.example.testserver.cart.repository.CartItemRepository;
import demo.com.example.testserver.product.model.ProductVariant;
import demo.com.example.testserver.product.repository.ProductVariantRepository;
import demo.com.example.testserver.user.model.User;
import demo.com.example.testserver.user.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class CartServiceImpl implements CartService {

    private static final Logger logger = LoggerFactory.getLogger(CartServiceImpl.class);

    @Autowired
    private CartItemRepository cartItemRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ProductVariantRepository productVariantRepository;

    @Autowired
    private CartMapper cartMapper;

    @Override
    @Transactional(readOnly = true)
    public List<CartItemDTO> getCartItems(String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new EntityNotFoundException("User not found with email: " + userEmail));
        logger.info("Fetching cart items for user: {}", userEmail);
        return cartItemRepository.findByUser(user).stream()
                .map(cartMapper::toCartItemDTO)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public CartItemDTO addToCart(String userEmail, AddToCartDTO addToCartDTO) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new EntityNotFoundException("User not found with email: " + userEmail));
        ProductVariant productVariant = productVariantRepository.findById(addToCartDTO.getProductVariantId().intValue())
                .orElseThrow(() -> new EntityNotFoundException("ProductVariant not found with ID: " + addToCartDTO.getProductVariantId()));

        if (productVariant.getStockQuantity() < addToCartDTO.getQuantity()) {
            throw new IllegalArgumentException("Insufficient stock for product variant ID: " + productVariant.getId() +
                    ". Requested: " + addToCartDTO.getQuantity() + ", Available: " + productVariant.getStockQuantity());
        }

        CartItem cartItem = cartItemRepository.findByUserAndProductVariant(user, productVariant)
                .orElseGet(() -> {
                    CartItem newItem = new CartItem();
                    newItem.setUser(user);
                    newItem.setProductVariant(productVariant);
                    newItem.setQuantity(0); // Initialize quantity, will be updated below
                    return newItem;
                });

        int newQuantity = cartItem.getQuantity() + addToCartDTO.getQuantity();
        if (productVariant.getStockQuantity() < newQuantity) {
            throw new IllegalArgumentException("Adding " + addToCartDTO.getQuantity() +
                    " would exceed stock for product variant ID: " + productVariant.getId() +
                    ". Current in cart: " + cartItem.getQuantity() +
                    ", Requested to add: " + addToCartDTO.getQuantity() +
                    ", Available: " + productVariant.getStockQuantity());
        }

        cartItem.setQuantity(newQuantity);
        CartItem savedCartItem = cartItemRepository.save(cartItem);
        logger.info("Added/Updated product variant ID {} (quantity: {}) to cart for user {}",
                productVariant.getId(), newQuantity, userEmail);
        return cartMapper.toCartItemDTO(savedCartItem);
    }

    @Override
    @Transactional
    public CartItemDTO updateCartItem(String userEmail, Integer cartItemId, UpdateCartItemDTO updateCartItemDTO) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new EntityNotFoundException("User not found with email: " + userEmail));
        CartItem cartItem = cartItemRepository.findByIdAndUser(cartItemId, user)
                .orElseThrow(() -> new EntityNotFoundException("CartItem not found with ID: " + cartItemId + " for user " + userEmail));

        ProductVariant productVariant = cartItem.getProductVariant();
        if (productVariant.getStockQuantity() < updateCartItemDTO.getQuantity()) {
            throw new IllegalArgumentException("Insufficient stock for product variant ID: " + productVariant.getId() +
                    ". Requested: " + updateCartItemDTO.getQuantity() + ", Available: " + productVariant.getStockQuantity());
        }

        cartItem.setQuantity(updateCartItemDTO.getQuantity());
        CartItem updatedCartItem = cartItemRepository.save(cartItem);
        logger.info("Updated quantity of cart item ID {} to {} for user {}",
                cartItemId, updateCartItemDTO.getQuantity(), userEmail);
        return cartMapper.toCartItemDTO(updatedCartItem);
    }

    @Override
    @Transactional
    public void removeFromCart(String userEmail, Integer cartItemId) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new EntityNotFoundException("User not found with email: " + userEmail));
        CartItem cartItem = cartItemRepository.findByIdAndUser(cartItemId, user)
                .orElseThrow(() -> new EntityNotFoundException("CartItem not found with ID: " + cartItemId + " for user " + userEmail));

        cartItemRepository.delete(cartItem);
        logger.info("Removed cart item ID {} for user {}", cartItemId, userEmail);
    }
}
