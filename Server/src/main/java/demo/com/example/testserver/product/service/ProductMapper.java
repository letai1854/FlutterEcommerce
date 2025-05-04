package demo.com.example.testserver.product.service;

import demo.com.example.testserver.product.dto.ProductDTO;
import demo.com.example.testserver.product.model.Product;
import org.springframework.stereotype.Component;

@Component
public class ProductMapper {

    public ProductDTO mapToProductDTO(Product product) {
        if (product == null) {
            return null;
        }
        ProductDTO dto = new ProductDTO(product); // Assuming ProductDTO constructor handles basic mapping
        // Set denormalized fields directly from the entity
        dto.setAverageRating(product.getAverageRating());
        dto.setMinPrice(product.getMinPrice());
        dto.setMaxPrice(product.getMaxPrice());
        // Add any other complex mapping logic here if needed
        return dto;
    }

    // Add mapToProductEntity if needed
}
