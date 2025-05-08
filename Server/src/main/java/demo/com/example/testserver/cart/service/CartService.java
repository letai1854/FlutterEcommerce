package demo.com.example.testserver.cart.service;

import demo.com.example.testserver.cart.dto.AddToCartDTO;
import demo.com.example.testserver.cart.dto.CartItemDTO;
import demo.com.example.testserver.cart.dto.UpdateCartItemDTO;

import java.util.List;

public interface CartService {
    List<CartItemDTO> getCartItems(String userEmail);
    CartItemDTO addToCart(String userEmail, AddToCartDTO addToCartDTO);
    CartItemDTO updateCartItem(String userEmail, Integer cartItemId, UpdateCartItemDTO updateCartItemDTO);
    void removeFromCart(String userEmail, Integer cartItemId);
}
