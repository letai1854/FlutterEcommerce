package demo.com.example.testserver.cart.service;

import demo.com.example.testserver.cart.dto.CartItemDTO;
import demo.com.example.testserver.cart.dto.CartProductVariantDTO;
import demo.com.example.testserver.cart.model.CartItem;
import demo.com.example.testserver.product.model.Product;
import demo.com.example.testserver.product.model.ProductVariant;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;

@Component
public class CartMapper {

    public CartItemDTO toCartItemDTO(CartItem cartItem) {
        if (cartItem == null) {
            return null;
        }

        CartProductVariantDTO variantDTO = toCartProductVariantDTO(cartItem.getProductVariant());
        BigDecimal lineTotal = BigDecimal.ZERO;
        if (variantDTO != null && variantDTO.getFinalPrice() != null && cartItem.getQuantity() != null) {
            lineTotal = variantDTO.getFinalPrice().multiply(new BigDecimal(cartItem.getQuantity()));
        }

        return new CartItemDTO(
                cartItem.getId(),
                variantDTO,
                cartItem.getQuantity(),
                lineTotal,
                cartItem.getAddedDate(),
                cartItem.getUpdatedDate()
        );
    }

    public CartProductVariantDTO toCartProductVariantDTO(ProductVariant variant) {
        if (variant == null) {
            return null;
        }
        Product product = variant.getProduct();
        BigDecimal finalPrice = variant.getPrice();
        if (variant.getDiscountPercentage() != null && variant.getDiscountPercentage().compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal discount = variant.getPrice().multiply(variant.getDiscountPercentage().divide(new BigDecimal("100"), 2, RoundingMode.HALF_UP));
            finalPrice = variant.getPrice().subtract(discount);
        }

        String imageUrl = null;
        if (product != null && product.getImages() != null && !product.getImages().isEmpty()) {
            imageUrl = product.getImages().get(0).getImageUrl(); // Get the first image as a default
        }
        // You might want to get a specific variant image if available
        // if (variant.getVariantImages() != null && !variant.getVariantImages().isEmpty()) {
        //     imageUrl = variant.getVariantImages().get(0).getImageUrl();
        // }

        CartProductVariantDTO dto = new CartProductVariantDTO();
        dto.setVariantId(variant.getId().longValue());
        dto.setProductId(product != null ? product.getId() : null);
        dto.setProductName(product != null ? product.getName() : "N/A");
        dto.setVariantDescription(variant.getName());
        dto.setImageUrl(imageUrl);
        dto.setPrice(variant.getPrice());
        dto.setDiscountPercentage(variant.getDiscountPercentage());
        dto.setFinalPrice(finalPrice);
        dto.setStockQuantity(variant.getStockQuantity());
        return dto;
    }
}
