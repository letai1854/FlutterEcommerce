package demo.com.example.testserver.cart.controller;

import demo.com.example.testserver.cart.dto.AddToCartDTO;
import demo.com.example.testserver.cart.dto.CartItemDTO;
import demo.com.example.testserver.cart.dto.UpdateCartItemDTO;
import demo.com.example.testserver.cart.service.CartService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/cart")
@CrossOrigin(origins = "*")
public class CartController {

    private static final Logger logger = LoggerFactory.getLogger(CartController.class);

    @Autowired
    private CartService cartService;

    @GetMapping
    public ResponseEntity<List<CartItemDTO>> getCart(@AuthenticationPrincipal UserDetails userDetails) {
        if (userDetails == null) {
            return ResponseEntity.status(401).build();
        }
        try {
            List<CartItemDTO> cartItems = cartService.getCartItems(userDetails.getUsername());
            return ResponseEntity.ok(cartItems);
        } catch (Exception e) {
            logger.error("Error fetching cart for user {}", userDetails.getUsername(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    @PostMapping
    public ResponseEntity<?> addToCart(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody AddToCartDTO request) {
        if (userDetails == null) {
            return ResponseEntity.status(401).build();
        }
        try {
            CartItemDTO cartItem = cartService.addToCart(userDetails.getUsername(), request);
            return ResponseEntity.ok(cartItem);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            logger.error("Error adding item to cart for user {}", userDetails.getUsername(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    @PutMapping("/{cartItemId}")
    public ResponseEntity<?> updateCartItem(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Integer cartItemId,
            @Valid @RequestBody UpdateCartItemDTO request) {
        if (userDetails == null) {
            return ResponseEntity.status(401).build();
        }
        try {
            CartItemDTO updatedItem = cartService.updateCartItem(userDetails.getUsername(), cartItemId, request);
            return ResponseEntity.ok(updatedItem);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            logger.error("Error updating cart item {} for user {}", cartItemId, userDetails.getUsername(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    @DeleteMapping("/{cartItemId}")
    public ResponseEntity<?> removeFromCart(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Integer cartItemId) {
        if (userDetails == null) {
            return ResponseEntity.status(401).build();
        }
        try {
            cartService.removeFromCart(userDetails.getUsername(), cartItemId);
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            logger.error("Error removing item {} from cart for user {}", cartItemId, userDetails.getUsername(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
}
